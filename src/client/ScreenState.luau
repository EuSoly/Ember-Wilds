--!strict
-- Estado de tela do cliente (loading / menu / playing / dead), uma fonte Vide
-- que as telas e a HUD leem. As transições são as de Shared/UIFlow/ScreenFlow:
-- - ready: o perfil carregou (atributo DataReady do Player);
-- - spawned: o jogador ganhou personagem (CharacterAdded);
-- - died: chegou o resumo da vida (Net.LifeEnded, guardado em lastSummary);
-- - toMenu: botão Menu da tela de morte.
-- Evento que não vale no estado atual é ignorado (ScreenFlow.next).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local ScreenFlow = require(Shared:WaitForChild("UIFlow"):WaitForChild("ScreenFlow"))
local StatNames = require(Shared:WaitForChild("StatNames"))
local Net = require(script.Parent:WaitForChild("Net"))

export type Screen = ScreenFlow.Screen
export type Event = ScreenFlow.Event
export type LifeSummary = {
	CauseKey: string,
	Days: number,
	Points: number,
	Currency: number,
	Xp: number,
	XpTotal: number,
	KillerName: string?,
	Revive: ReviveOffer?,
	EmberBonus: number,
}
-- Oferta de revive que veio com o LifeEnded (preço em Robux ou grátis).
export type ReviveOffer = { Robux: number, Free: boolean }

local ScreenState = {}

-- Fonte Vide: chamar sem argumento lê, com argumento escreve. Tipo escrito
-- aqui porque sem ele o vide.source alarga "loading" para string.
type Source<T> = (() -> T) & ((T) -> T)

local current: Source<Screen> = vide.source("loading" :: Screen) :: any
ScreenState.current = current
-- Resumo da última vida (para a tela de morte); nil antes da primeira morte.
local lastSummary: Source<LifeSummary?> = vide.source(nil :: LifeSummary?) :: any
ScreenState.lastSummary = lastSummary
-- Oferta de revive pendente (nil = nenhuma) e se a resposta já foi enviada
-- (os botões ficam desligados até o ReviveClosed).
local reviveOffer: Source<ReviveOffer?> = vide.source(nil :: ReviveOffer?) :: any
ScreenState.reviveOffer = reviveOffer
local reviveSending: Source<boolean> = vide.source(false) :: any
ScreenState.reviveSending = reviveSending

function ScreenState.send(event: Event)
	local before: Screen = vide.untrack(current) :: any
	local after: Screen = ScreenFlow.next(before, event)
	if after ~= before then
		current(after)
		-- Saiu da morte (nasceu ou foi ao menu): a oferta não vale mais.
		if after ~= "dead" then
			reviveOffer(nil)
			reviveSending(false)
		end
	end
end

-- Liga os eventos (chamado uma vez pelo ScreenController).
function ScreenState.start()
	local player = Players.LocalPlayer

	-- Único ouvinte do LifeEnded (eventos Blink SingleAsync têm um só).
	Net.LifeEnded.On(function(summary: LifeSummary)
		ScreenState.lastSummary(summary)
		reviveSending(false)
		reviveOffer(summary.Revive)
		ScreenState.send("died")
	end)

	-- Fim da janela do revive. Pode chegar depois de o jogador já ter nascido
	-- pelo menu: fora da morte, é ignorado.
	Net.ReviveClosed.On(function(data: { Revived: boolean })
		if vide.untrack(current) ~= "dead" then
			return
		end
		if data.Revived then
			-- O personagem novo fecha a tela (CharacterAdded → spawned); até lá a
			-- oferta fica desligada. Rede de segurança se o sinal já tinha passado.
			reviveSending(true)
			task.delay(3, function()
				local character = player.Character
				if character and character.Parent ~= nil then
					ScreenState.send("spawned")
				end
			end)
		else
			reviveOffer(nil)
			reviveSending(false)
		end
	end)

	player.CharacterAdded:Connect(function(character: Model)
		-- Morreu antes de o sinal chegar (o servidor já destruiu o corpo): não
		-- entra em "playing" sem personagem; o LifeEnded leva para a morte.
		if character.Parent == nil then
			return
		end
		ScreenState.send("spawned")
	end)

	local function checkReady()
		if player:GetAttribute(StatNames.DataReady) == true then
			ScreenState.send("ready")
			-- Personagem que nasceu antes de o cliente ver o DataReady.
			if player.Character then
				ScreenState.send("spawned")
			end
		end
	end
	player:GetAttributeChangedSignal(StatNames.DataReady):Connect(checkReady)
	checkReady()
end

return ScreenState
