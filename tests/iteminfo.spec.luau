--!strict
local Defs = require("../src/shared/Defs")
local ItemInfo = require("../src/shared/UIFlow/ItemInfo")
local Strings = require("../src/shared/Strings")

-- Linhas da dica já como texto (como a tela mostra).
local function lines(id: string): { string }
	local out = {}
	for _, line in ItemInfo.lines(Defs.Items[id]) do
		table.insert(out, Strings.format(line.key, line.vars))
	end
	return out
end

local function has(list: { string }, text: string): boolean
	return table.find(list, text) ~= nil
end

return {
	["food tells what it refills"] = function()
		local l = lines("berry")
		assert(has(l, "Repõe 10 de fome"), table.concat(l, " | "))
	end,

	["weapon shows damage and that it slows you"] = function()
		local l = lines("gold_sword")
		assert(has(l, "Dano: 22"), table.concat(l, " | "))
		assert(has(l, "Anda 75% da velocidade"), table.concat(l, " | "))
	end,

	["pickaxe shows its level"] = function()
		local l = lines("gold_pickaxe")
		assert(has(l, "Picareta nível 3"), table.concat(l, " | "))
	end,

	["armor shows defense in percent"] = function()
		local l = lines("wood_helmet")
		assert(has(l, "Defesa: 10%"), table.concat(l, " | "))
	end,

	["bag shows extra slots"] = function()
		local l = lines("leather_bag")
		assert(has(l, "+6 espaços na mochila"), table.concat(l, " | "))
	end,

	["structure shows its health"] = function()
		local l = lines("gold_wall")
		assert(has(l, "Vida: 2000"), table.concat(l, " | "))
	end,

	["at most three lines, plain resources have none"] = function()
		for _, def in Defs.Items do
			assert(#ItemInfo.lines(def) <= 3, `{def.id}: mais de 3 linhas`)
		end
		assert(#lines("wood") == 0, "madeira não tem linha extra")
	end,

	["subtitle is the tier name in its color"] = function()
		local key, color = ItemInfo.tier(Defs.Items.gold_sword)
		assert(key == "tier.gold" and color == Defs.Tiers.gold.color, `{key} {color}`)
		local none = ItemInfo.tier(Defs.Items.berry)
		assert(none == nil, "comida sem tier")
	end,

	["every info text exists"] = function()
		for _, def in Defs.Items do
			for _, line in ItemInfo.lines(def) do
				assert(Strings.has(line.key), `falta o texto {line.key}`)
			end
		end
	end,
}
