--!strict
-- Se o painel da mochila está aberto. Fica num módulo próprio porque a mochila,
-- a hotbar e a grade precisam saber disso (com a mochila aberta, tocar num slot
-- serve para mover itens; fechada, tocar na hotbar seleciona).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local InventoryState = require(script.Parent:WaitForChild("InventoryState"))

local BackpackState = {}

BackpackState.open = vide.source(false)

function BackpackState.toggle()
	BackpackState.open(not vide.untrack(BackpackState.open))
	-- Fechou no meio de um "mover": cancela a origem escolhida.
	InventoryState.pick(nil)
end

return BackpackState
