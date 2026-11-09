--!strict
-- Estado da tela do Ranking (UI 6): aba escolhida, a última resposta de cada
-- aba e o status. Pede ao servidor (Net.RequestRanking) ao abrir a tela e ao
-- trocar de aba; resposta de uma aba que já não é a atual fica guardada, mas
-- não troca a tela. Também tem os textos de valor e o avatar de cada jogador.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local ProfileFormat = require(Shared:WaitForChild("UIFlow"):WaitForChild("ProfileFormat"))
local RankConfig = require(Shared:WaitForChild("Data"):WaitForChild("RankConfig"))
local Strings = require(Shared:WaitForChild("Strings"))
local Net = require(script.Parent.Parent.Parent:WaitForChild("Net"))

export type Entry = { UserId: number, Name: string, Value: number }
export type Data = {
	Category: number,
	Ok: boolean,
	EndsAt: number,
	Entries: { Entry },
	MyValue: number,
	MyPosition: number,
}
export type Status = "loading" | "ok" | "error"

local RankingState = {}

-- Aba atual: índice em RankConfig.CATEGORIES (1 = Pontos).
RankingState.category = vide.source(1)
-- Resposta da aba atual (nil enquanto não chegou nenhuma).
RankingState.data = vide.source(nil :: Data?)
RankingState.status = vide.source("loading" :: Status)

local responses: { [number]: Data } = {}
local listening = false

local function listen()
	if listening then
		return
	end
	listening = true
	Net.RankingData.On(function(data: Data)
		responses[data.Category] = data
		if data.Category == vide.untrack(RankingState.category) then
			RankingState.data(data)
			RankingState.status(if data.Ok then "ok" else "error")
		end
	end)
end

-- Mostra a aba `index` (com a resposta guardada, se houver) e pede a atual.
function RankingState.select(index: number)
	listen()
	RankingState.category(index)
	local cached = responses[index]
	RankingState.data(cached)
	RankingState.status(if cached == nil then "loading" elseif cached.Ok then "ok" else "error")
	Net.RequestRanking.Fire(index)
end

function RankingState.categoryId(index: number): string
	return RankConfig.CATEGORIES[index] or RankConfig.CATEGORIES[1]
end

-- "12.345 pts", "3 dias"... na unidade da aba.
function RankingState.valueText(index: number, value: number): string
	return Strings.format("rank.value." .. RankingState.categoryId(index), { value = ProfileFormat.thousands(value) })
end

function RankingState.headshot(userId: number): string
	return `rbxthumb://type=AvatarHeadShot&id={userId}&w=150&h=150`
end

function RankingState.localUserId(): number
	return Players.LocalPlayer.UserId
end

return RankingState
