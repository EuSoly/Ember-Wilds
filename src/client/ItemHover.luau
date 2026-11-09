--!strict
-- Qual slot do inventário está sob o mouse (ou sob o dedo, no celular), para a
-- dica do item (UI/ItemTooltip). O slot avisa ao entrar e ao sair; no toque,
-- a dica fica TOUCH_SECONDS depois de soltar o dedo.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))

export type Hover = { index: number, anchor: GuiObject }

local ItemHover = {}

local TOUCH_SECONDS = 1.5

ItemHover.current = vide.source(nil :: Hover?)

-- Contador para o "esconder depois" do toque não apagar uma dica mais nova.
local version = 0

function ItemHover.enter(index: number, anchor: GuiObject)
	version += 1
	ItemHover.current({ index = index, anchor = anchor })
end

function ItemHover.leave(index: number)
	local hover = vide.untrack(ItemHover.current)
	if hover and hover.index == index then
		ItemHover.current(nil)
	end
end

-- Toque: mostra agora e esconde sozinho depois de um tempo.
function ItemHover.touch(index: number, anchor: GuiObject)
	ItemHover.enter(index, anchor)
	local mine = version
	task.delay(TOUCH_SECONDS, function()
		if version == mine then
			ItemHover.leave(index)
		end
	end)
end

return ItemHover
