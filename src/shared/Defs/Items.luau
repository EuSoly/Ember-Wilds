--!strict
-- Itens do jogo. Para adicionar um item: uma entrada aqui + o texto
-- "item.<id>" em Strings/ptBR.luau. Veja docs/guia/adicionar-item.md.
local Types = require("./Types")

type ItemDef = Types.ItemDef

local Items: { [string]: ItemDef } = {
	-- Recursos (sem tier: moldura neutra)
	wood = { id = "wood", nameKey = "item.wood", category = "resource", maxStack = 255 },
	stone = { id = "stone", nameKey = "item.stone", category = "resource", maxStack = 255 },
	gold = { id = "gold", nameKey = "item.gold", category = "resource", maxStack = 255 },

	-- Comida
	berry = { id = "berry", nameKey = "item.berry", category = "food", maxStack = 255, food = { hunger = 10 } },

	-- Mochilas (vestidas, não ocupam slot; dão bagSlots slots a mais).
	-- Para uma mochila maior num update, é só adicionar outra entrada aqui.
	leather_bag = {
		id = "leather_bag",
		nameKey = "item.leather_bag",
		category = "bag",
		maxStack = 1,
		bagSlots = 6,
	},

	-- Ferramentas
	wood_pickaxe = {
		id = "wood_pickaxe",
		nameKey = "item.wood_pickaxe",
		category = "tool",
		tier = "wood",
		maxStack = 1,
		pickaxe = { level = 1 },
	},
	stone_pickaxe = {
		id = "stone_pickaxe",
		nameKey = "item.stone_pickaxe",
		category = "tool",
		tier = "stone",
		maxStack = 1,
		pickaxe = { level = 2 },
	},
	gold_pickaxe = {
		id = "gold_pickaxe",
		nameKey = "item.gold_pickaxe",
		category = "tool",
		tier = "gold",
		maxStack = 1,
		pickaxe = { level = 3 },
	},
}

for _, item in Items do
	if item.food ~= nil then
		table.freeze(item.food)
	end
	if item.armor ~= nil then
		table.freeze(item.armor)
	end
	if item.pickaxe ~= nil then
		table.freeze(item.pickaxe)
	end
	table.freeze(item)
end

return table.freeze(Items)
