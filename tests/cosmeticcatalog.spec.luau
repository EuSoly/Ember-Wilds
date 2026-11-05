--!strict
local CosmeticCatalog = require("../src/shared/UIFlow/CosmeticCatalog")

local function numbers(n: number): { number }
	local list = {}
	for i = 1, n do
		table.insert(list, i)
	end
	return list
end

return {
	["items body starts at default and rarity never decreases"] = function()
		local items = CosmeticCatalog.items("body")
		assert(#items == 110, `esperava 110 skins de corpo, veio {#items}`)
		assert(items[1].id == "body_default", "primeiro deve ser body_default")
		for i = 2, #items do
			assert(items[i].rarity >= items[i - 1].rarity, "raridade decresceu")
		end
	end,

	["spinItems body has no default"] = function()
		for _, item in CosmeticCatalog.spinItems("body") do
			assert(item.id ~= "body_default", "padrão não entra no giro")
		end
		assert(#CosmeticCatalog.spinItems("body") == 109, "109 skins no giro do corpo")
	end,

	["spinItems book includes all book skins"] = function()
		local list = CosmeticCatalog.spinItems("book")
		assert(
			#list == 21 and list[1].id == "book_default",
			`esperava 21 livros começando em book_default, veio {#list}`
		)
	end,

	["spinItems bag covers rarities 1 to 5"] = function()
		local seen: { [number]: boolean } = {}
		for _, item in CosmeticCatalog.spinItems("bag") do
			seen[item.rarity] = true
		end
		for r = 1, 5 do
			assert(seen[r] == true, `faltou raridade {r} na mochila`)
		end
	end,

	["colorOf per slot"] = function()
		local Cosmetics = require("../src/shared/Defs/Cosmetics")
		assert(CosmeticCatalog.colorOf(Cosmetics.body_default) == "#DDF3F8", "body usa bodyColor")
		assert(CosmeticCatalog.colorOf(Cosmetics.bag_default) == "#95603D", "bag usa color")
		assert(CosmeticCatalog.colorOf(Cosmetics.crate_default) == "#F2B632", "crate usa bandColor")
		assert(CosmeticCatalog.colorOf(Cosmetics.book_default) == "#8B5A2B", "outros usam madeira")
	end,

	["pageCount"] = function()
		assert(CosmeticCatalog.pageCount(0, 9) == 1, "0 -> 1")
		assert(CosmeticCatalog.pageCount(9, 9) == 1, "9 -> 1")
		assert(CosmeticCatalog.pageCount(10, 9) == 2, "10 -> 2")
	end,

	["page slices and clamps"] = function()
		local list = numbers(10)
		assert(#CosmeticCatalog.page(list, 2, 9) == 1, "página 2 tem 1 item")
		local clamped = CosmeticCatalog.page(list, 5, 9)
		assert(#clamped == 1 and clamped[1] == 10, "página fora da faixa vira a última")
		assert(#CosmeticCatalog.page(list, 1, 9) == 9, "página 1 tem 9")
	end,

	["CATEGORIES order and sides"] = function()
		local expected = {
			{ "body", "left" },
			{ "accessory", "left" },
			{ "crate", "left" },
			{ "bag", "right" },
			{ "book", "right" },
		}
		assert(#CosmeticCatalog.CATEGORIES == 5, "5 categorias")
		for i, pair in expected do
			local category = CosmeticCatalog.CATEGORIES[i]
			assert(category.id == pair[1] and category.side == pair[2], `categoria {i} errada`)
		end
		assert(CosmeticCatalog.CATEGORIES[2].slot == nil, "accessory sem slot")
		assert(CosmeticCatalog.CATEGORIES[1].slot == "body", "body com slot")
	end,
	["pageOf finds the page of an id"] = function()
		local items = CosmeticCatalog.items("body")
		assert(CosmeticCatalog.pageOf(items, items[1].id, 9) == 1, "primeira skin na página 1")
		assert(CosmeticCatalog.pageOf(items, items[9].id, 9) == 1, "nona skin na página 1")
		assert(CosmeticCatalog.pageOf(items, items[10].id, 9) == 2, "décima skin na página 2")
		assert(CosmeticCatalog.pageOf(items, "nao_existe", 9) == 1, "id desconhecido cai na página 1")
	end,
}
