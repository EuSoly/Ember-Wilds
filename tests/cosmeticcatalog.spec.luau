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
		assert(#items == 47, `esperava 47 skins de corpo liberadas, veio {#items}`)
		assert(items[1].id == "body_default", "primeiro deve ser body_default")
		for i = 2, #items do
			assert(items[i].rarity >= items[i - 1].rarity, "raridade decresceu")
			assert(items[i].unreleased ~= true, `{items[i].id} não devia aparecer sem posse`)
		end
	end,

	["items includes unreleased skins only when owned"] = function()
		local all = CosmeticCatalog.items("body", function(_id: string)
			return true
		end)
		assert(#all == 181, `com todas possuídas, esperava as 181 skins de corpo, veio {#all}`)
		local withOne = CosmeticCatalog.items("body", function(id: string)
			return id == "body_dragao"
		end)
		assert(#withOne == 48, `esperava 48 skins com body_dragao possuído, veio {#withOne}`)
	end,

	["owned skins come first, then rarity"] = function()
		-- Pedido do Elizeu (18/11/2026): as liberadas na frente, cada grupo por raridade.
		local all = CosmeticCatalog.items("body")
		local mine: { [string]: boolean } = {}
		-- Possui uma Mítica e uma Comum (as duas últimas e a segunda da lista).
		mine[all[#all].id] = true
		mine[all[2].id] = true
		local items = CosmeticCatalog.items("body", function(id: string): boolean
			return mine[id] == true
		end)
		assert(items[1].id == "body_default", "a padrão continua primeiro")
		assert(mine[items[2].id] and mine[items[3].id], "as liberadas logo depois")
		assert(items[2].rarity <= items[3].rarity, "liberadas por raridade")
		for i = 5, #items do
			assert(not mine[items[i].id], "trancada no meio das liberadas")
			assert(items[i].rarity >= items[i - 1].rarity, "trancadas por raridade")
		end
	end,

	["spinItems body has no default and no bundle or unreleased skins"] = function()
		for _, item in CosmeticCatalog.spinItems("body") do
			assert(item.id ~= "body_default", "padrão não entra no giro")
		end
		assert(#CosmeticCatalog.spinItems("body") == 43, "43 skins liberadas no giro do corpo")
	end,

	["spinItems book includes released non-bundle book skins"] = function()
		local list = CosmeticCatalog.spinItems("book")
		assert(
			#list == 8 and list[1].id == "book_default",
			`esperava 8 livros no giro começando em book_default, veio {#list}`
		)
	end,

	["spinItems bag has no default"] = function()
		-- A Bolsa Clássica (bag_padrao) é a padrão: fica fora do giro. As
		-- raridades das mochilas 3D (todas Comum por enquanto) voltam a ser
		-- conferidas quando o Elizeu definir (como as de corpo).
		local items = CosmeticCatalog.spinItems("bag")
		assert(#items > 0, "mochila tem skins no giro")
		for _, item in items do
			assert(item.id ~= "bag_padrao", "a padrão não entra no giro")
		end
	end,

	["colorOf per slot"] = function()
		local Cosmetics = require("../src/shared/Defs/Cosmetics")
		assert(CosmeticCatalog.colorOf(Cosmetics.body_default) == "#DDF3F8", "body usa bodyColor")
		assert(CosmeticCatalog.colorOf(Cosmetics.bag_padrao) == "#842C08", "bag usa color")
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
		-- Acessórios fora da tela até terem skins (decisão do Elizeu, 10/11/2026).
		local expected = {
			{ "body", "left" },
			{ "crate", "left" },
			{ "bag", "right" },
			{ "book", "right" },
		}
		assert(#CosmeticCatalog.CATEGORIES == 4, "4 categorias")
		for i, pair in expected do
			local category = CosmeticCatalog.CATEGORIES[i]
			assert(category.id == pair[1] and category.side == pair[2], `categoria {i} errada`)
			assert(category.slot ~= nil, `{category.id} com slot`)
		end
	end,
	["pageOf finds the page of an id"] = function()
		local items = CosmeticCatalog.items("body")
		assert(CosmeticCatalog.pageOf(items, items[1].id, 9) == 1, "primeira skin na página 1")
		assert(CosmeticCatalog.pageOf(items, items[9].id, 9) == 1, "nona skin na página 1")
		assert(CosmeticCatalog.pageOf(items, items[10].id, 9) == 2, "décima skin na página 2")
		assert(CosmeticCatalog.pageOf(items, "nao_existe", 9) == 1, "id desconhecido cai na página 1")
	end,
}
