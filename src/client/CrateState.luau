--!strict
-- Caixa de itens perto do jogador, no cliente. A cada 0,25 s procura a caixa
-- (modelo com a tag CrateTag) mais perto, a até CrateRules.OPEN_RANGE studs
-- (XZ; o servidor usa o mesmo número), e avisa o servidor quando ela muda
-- (CrateWatch). O conteúdo chega por evento (CrateContents) só para a caixa
-- olhada. Só lê e pede: quem decide é o servidor (CrateService). Os atributos do
-- personagem previsto não avisam mudança (Server Authority): tudo por polling.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local CrateRules = require(Shared:WaitForChild("Crate"):WaitForChild("CrateRules"))
local StatNames = require(Shared:WaitForChild("StatNames"))
local Net = require(script.Parent:WaitForChild("Net"))

local REFRESH = 0.25 -- segundos entre conferências

export type Item = { id: string, count: number }

local CrateState = {
	-- Caixa mais perto dentro do alcance, ou nil.
	near = vide.source(nil :: Model?),
	-- Slots da caixa perto, na ordem do servidor (vazio até o primeiro envio).
	contents = vide.source({} :: { Item }),
}

local function findNearest(): Model?
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root == nil or not root:IsA("BasePart") then
		return nil
	end
	local best: Model? = nil
	local bestDistance = CrateRules.OPEN_RANGE * CrateRules.OPEN_RANGE
	for _, tagged in CollectionService:GetTagged(StatNames.CrateTag) do
		if tagged:IsA("Model") and tagged:IsDescendantOf(Workspace) then
			local point = tagged:GetPivot().Position
			local dx, dz = point.X - root.Position.X, point.Z - root.Position.Z
			local distance = dx * dx + dz * dz
			if distance <= bestDistance then
				best, bestDistance = tagged, distance
			end
		end
	end
	return best
end

local function refresh()
	local crate = findNearest()
	if vide.untrack(CrateState.near) ~= crate then
		-- Zera antes: não mostra o conteúdo da caixa anterior enquanto o novo não chega.
		CrateState.contents({})
		CrateState.near(crate)
		Net.CrateWatch.Fire(crate)
	end
end

-- Pede ao servidor o slot `slot` (posição na lista mostrada). Manda o item que o
-- painel mostra nele: se a lista mudou, o servidor recusa e reenvia o conteúdo.
function CrateState.take(slot: number)
	local crate = vide.untrack(CrateState.near)
	local item = vide.untrack(CrateState.contents)[slot]
	if crate and item then
		Net.CrateTake.Fire({ Crate = crate, Slot = slot, ItemId = item.id })
	end
end

function CrateState.Start(_self)
	Net.CrateContents.On(function(data)
		-- Crate nil = caixa fora do cliente (streaming); só vale a caixa perto.
		if data.Crate == nil or data.Crate ~= vide.untrack(CrateState.near) then
			return
		end
		local items: { Item } = {}
		for _, slot in data.Slots do
			table.insert(items, { id = slot.Id, count = slot.Count })
		end
		CrateState.contents(items)
	end)
	task.spawn(function()
		while true do
			refresh()
			task.wait(REFRESH)
		end
	end)
end

return CrateState
