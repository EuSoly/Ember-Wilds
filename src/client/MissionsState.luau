--!strict
-- Estado das Missões no cliente: o último retrato do servidor (Net.MissionsData),
-- se a janela está aberta, a aba escolhida e a fila de avisos (faixa no topo).
-- Quem desenha: Screens/MissionsScreen (janela) e UI/MissionBanner (faixa).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local MissionView = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("UIFlow"):WaitForChild("MissionView"))
local Net = require(script.Parent:WaitForChild("Net"))

type Source<T> = (() -> T) & ((T) -> T)

export type Notice = { Kind: number, Id: string, Done: boolean }

local KIND_OF_TAB: { [MissionView.Tab]: number } = { match = 1, daily = 2, weekly = 3, achievements = 4 }

local MissionsState = {}

MissionsState.data = vide.source(nil :: any) :: Source<any>
MissionsState.open = vide.source(false) :: Source<boolean>
MissionsState.tab = vide.source("match" :: MissionView.Tab) :: Source<MissionView.Tab>
-- Último aviso chegado (a faixa mostra um de cada vez, na ordem).
MissionsState.notice = vide.source(nil :: Notice?) :: Source<Notice?>

local queue: { Notice } = {}
local started = false

function MissionsState.toggle()
	MissionsState.open(not vide.untrack(MissionsState.open))
end

function MissionsState.badges(): MissionView.Badges
	return MissionView.badges(MissionsState.data())
end

-- Pede o resgate (o servidor confere e responde com um retrato novo).
function MissionsState.claim(tab: MissionView.Tab, id: string)
	Net.ClaimMission.Fire({ Kind = KIND_OF_TAB[tab], Id = id })
end

-- Próximo aviso da fila (a faixa chama quando termina o anterior).
function MissionsState.nextNotice()
	MissionsState.notice(table.remove(queue, 1))
end

function MissionsState.start()
	if started then
		return
	end
	started = true
	-- Liga os ouvintes antes de pedir, para a resposta não se perder.
	Net.MissionsData.On(function(snapshot)
		MissionsState.data(snapshot)
	end)
	Net.MissionNotice.On(function(notice)
		table.insert(queue, notice)
		if vide.untrack(MissionsState.notice) == nil then
			MissionsState.nextNotice()
		end
	end)
	Net.RequestMissions.Fire()
end

return MissionsState
