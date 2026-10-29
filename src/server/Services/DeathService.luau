--!strict
-- A função única de morte (kill). Toda morte de jogador passa por aqui: as
-- fases G chamam ao matar; o comando de dev DevEndLife também; qualquer morte
-- do Humanoid que não veio daqui é trazida para cá com a causa
-- "death.cause.unknown"; e a queda do mapa vira "death.cause.fall" (abaixo) —
-- nunca fica um corpo parado sem tela.
--
-- A morte: fim de vida da F4 (pontos → Golden Ember, estatísticas), guarda os
-- pontos para comprar kit (KitPoints), zera o inventário e tira a mochila (no
-- Starve a morte perde tudo), remove o personagem e manda ao jogador o resumo
-- (Net.LifeEnded) para a tela de morte. Quem renasce é o SpawnService, a pedido.
--
-- Queda do mapa: ao passar de Workspace.FallenPartsDestroyHeight, o Roblox
-- apaga o HumanoidRootPart SEM matar o Humanoid e sem disparar Died (visto no
-- Studio: vida 100, estado Freefall, sem raiz). O Died sozinho deixaria o
-- jogador preso sem corpo e sem tela de morte. Por isso um laço único confere
-- os personagens a cada FALL_CHECK_INTERVAL e mata quem está sem raiz ou
-- abaixo de WorldConfig.KILL_Y (antes de o Roblox apagar a raiz).
--
-- Futuro (spec F5, não-objetivos): revive por Robux — pagar para voltar com os
-- mesmos itens. Para caber, a morte poderia guardar o inventário da morte por
-- alguns segundos antes do reset; os pontos zeram e viram moeda normalmente.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StatNames = require(ReplicatedStorage.Shared.StatNames)
local WorldConfig = require(ReplicatedStorage.Shared.WorldConfig)
local InventoryService = require(script.Parent.InventoryService)
local LifeService = require(script.Parent.LifeService)
local Net = require(script.Parent.Parent.Net)

local UNKNOWN_CAUSE = "death.cause.unknown"
local FALL_CAUSE = "death.cause.fall"
local FALL_CHECK_INTERVAL = 0.25 -- segundos
-- Limites do contrato LifeEnded (net/game.blink): Days u16, Points u32, Currency u16.
local MAX_U16 = 65535
local MAX_U32 = 4294967295

local DeathService = {}

-- Inteiro dentro de [0, max] (o Blink não aceita fora da faixa do tipo).
local function clampInt(value: number, max: number): number
	if value ~= value then
		return 0
	end
	return math.clamp(math.floor(value), 0, max)
end

function DeathService.kill(player: Player, causeKey: string)
	if player.Parent ~= Players then
		return
	end
	-- nil = sem vida ativa ou sem perfil: a tela de morte mostra zeros.
	local summary = LifeService.endLife(player) or { points = 0, days = 0, currency = 0 }

	-- Pontos da vida que acabou ficam para comprar um kit antes de renascer.
	player:SetAttribute(StatNames.KitPoints, summary.points)
	InventoryService.reset(player)

	-- Remove o personagem antes de avisar: o Humanoid.Died de um personagem
	-- que já não é o atual é ignorado abaixo, então não conta duas vezes.
	local character = player.Character
	player.Character = nil
	if character then
		character:Destroy()
	end

	Net.LifeEnded.Fire(player, {
		CauseKey = causeKey,
		Days = clampInt(summary.days, MAX_U16),
		Points = clampInt(summary.points, MAX_U32),
		Currency = clampInt(summary.currency, MAX_U16),
	})
end

local function setupCharacter(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
	if humanoid == nil then
		return
	end
	humanoid.Died:Connect(function()
		-- Só se ainda é o personagem atual: a morte por kill já o removeu.
		if player.Character == character then
			DeathService.kill(player, UNKNOWN_CAUSE)
		end
	end)
end

local function setupPlayer(player: Player)
	player.CharacterAdded:Connect(function(character)
		setupCharacter(player, character)
	end)
	if player.Character then
		task.spawn(setupCharacter, player, player.Character)
	end
end

-- true se o personagem atual caiu do mapa: sem raiz (o Roblox já a apagou) ou
-- com a raiz abaixo de KILL_Y.
local function hasFallen(character: Model): boolean
	local root = character:FindFirstChild("HumanoidRootPart")
	if root == nil or not root:IsA("BasePart") then
		return true
	end
	return root.Position.Y < WorldConfig.KILL_Y
end

local function checkFalls()
	for _, player in Players:GetPlayers() do
		local character = player.Character
		-- Só personagens já montados: logo depois do CharacterAdded a raiz pode
		-- ainda não estar dentro do modelo (Humanoid é o sinal de que montou).
		if character and character.Parent and character:FindFirstChildOfClass("Humanoid") then
			if hasFallen(character) then
				DeathService.kill(player, FALL_CAUSE)
			end
		end
	end
end

function DeathService.Start(_self)
	Players.PlayerAdded:Connect(setupPlayer)
	for _, player in Players:GetPlayers() do
		setupPlayer(player)
	end

	-- Uma thread só para todos os jogadores.
	task.spawn(function()
		while true do
			task.wait(FALL_CHECK_INTERVAL)
			checkFalls()
		end
	end)
end

return DeathService
