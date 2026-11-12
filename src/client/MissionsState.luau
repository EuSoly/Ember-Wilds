--!strict
-- Estado das Missões no cliente: o último retrato do servidor (Net.MissionsData),
-- se a janela está aberta, a aba escolhida e a fila de avisos (faixa no topo).
-- Quem desenha: Screens/MissionsScreen (janela) e UI/MissionBanner (faixa).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local MissionView = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("UIFlow"):WaitForChild("MissionView"))
local Net = require(script.Parent:WaitForChild("Net"))
local SoundPlayer = require(script.Parent:WaitForChild("Audio"):WaitForChild("SoundPlayer"))

type Source<T> = (() -> T) & ((T) -> T)

export type Notice = { Kind: number, Id: string, Done: boolean }

local KIND_OF_TAB: { [MissionView.Tab]: number } = { match = 1, daily = 2, weekly = 3, achievements = 4 }

local MissionsState = {}

MissionsState.data = vide.source(nil :: any) :: Source<any>
MissionsState.open = vide.source(false) :: Source<boolean>
MissionsState.tab = vide.source("match" :: MissionView.Tab) :: Source<MissionView.Tab>
local queue: { Notice } = {}
local started = false
local claimedBefore: number? = nil

-- Quantos resgates o retrato mostra (cartões resgatados + níveis de conquista).
local function claimedCount(snapshot: any): number
	local n = 0
	for _, list in { snapshot.Chrono, snapshot.Daily, snapshot.Weekly, { snapshot.DailyFinal, snapshot.WeeklyFinal } } do
		for _, card in list do
			if card.State == 2 then
				n += 1
			end
		end
	end
	for _, card in snapshot.Achievements do
		n += card.Claimed
	end
	return n
end

function MissionsState.toggle()
	MissionsState.open(not vide.untrack(MissionsState.open))
end

-- Avisa o servidor se a janela está aberta (chamado pela tela quando muda).
function MissionsState.watch(open: boolean)
	Net.WatchMissions.Fire(open)
end

function MissionsState.badges(): MissionView.Badges
	return MissionView.badges(MissionsState.data())
end

-- Pede o resgate (o servidor confere e responde com um retrato novo).
function MissionsState.claim(tab: MissionView.Tab, id: string)
	Net.ClaimMission.Fire({ Kind = KIND_OF_TAB[tab], Id = id })
end

-- Tira o próximo aviso da fila (a faixa mostra um de cada vez, na ordem).
function MissionsState.takeNotice(): Notice?
	return table.remove(queue, 1)
end

function MissionsState.start()
	if started then
		return
	end
	started = true
	-- Liga os ouvintes antes de pedir, para a resposta não se perder.
	Net.MissionsData.On(function(snapshot)
		-- Resgate confirmado pelo servidor: o som toca aqui, não no clique.
		local claimed = claimedCount(snapshot)
		if claimedBefore ~= nil and claimed > claimedBefore then
			SoundPlayer.play("level_up")
		end
		claimedBefore = claimed
		MissionsState.data(snapshot)
	end)
	Net.MissionNotice.On(function(notice)
		table.insert(queue, notice)
	end)
	Net.RequestMissions.Fire()
end

return MissionsState
