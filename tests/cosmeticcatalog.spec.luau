--!strict
local Bundles = require("../src/shared/Shop/Bundles")
local BundleSkins = require("../src/shared/UIFlow/BundleSkins")
local CosmeticCatalog = require("../src/shared/UIFlow/CosmeticCatalog")
local Defs = require("../src/shared/Defs")

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
		-- 47 liberadas + 2 de pacote `unreleased` (body_lula, body_toco).
		assert(#items == 49, `esperava 49 skins de corpo na grade, veio {#items}`)
		assert(items[1].id == "body_default", "primeiro deve ser body_default")
		for i = 2, #items do
			assert(items[i].rarity >= items[i - 1].rarity, "raridade decresceu")
			assert(
				items[i].unreleased ~= true or BundleSkins.has(items[i].id),
				`{items[i].id} não devia aparecer sem posse`
			)
		end
	end,

	["bundle skins show locked even when unreleased; other unreleased stay hidden"] = function()
		-- Toda skin de pacote da loja aparece na grade (trancada) sem posse,
		-- em qualquer slot; `unreleased` fora de pacote continua escondida.
		local inBundle = BundleSkins.fromBundles(Bundles)
		for _, slot in { "body", "bag", "book", "crate", "accessory" } do
			local seen: { [string]: boolean } = {}
			for _, def in CosmeticCatalog.items(slot) do
				seen[def.id] = true
				assert(def.unreleased ~= true or inBundle[def.id], `{def.id} unreleased sem pacote apareceu`)
			end
			for id in inBundle do
				local def = Defs.Cosmetics[id]
				if def and def.slot == slot then
					assert(seen[id], `{id} (de pacote) devia aparecer na grade de {slot}`)
				end
			end
		end
		assert(not BundleSkins.has("body_dragao"), "dragão não é de pacote")
		local visible = CosmeticCatalog.items("body")
		for _, def in visible do
			assert(def.id ~= "body_dragao", "body_dragao (unreleased, sem pacote) continua escondida")
		end
	end,

	["bundle skins never enter spins through unreleased"] = function()
		-- As de pacote `unreleased` agora estão em items(), mas não nas roletas.
		for _, slot in { "body", "bag", "book", "crate" } do
			for _, item in CosmeticCatalog.spinItems(slot) do
				local def = Defs.Cosmetics[item.id]
				assert(def.unreleased ~= true, `{item.id} unreleased entrou no giro`)
			end
		end
	end,

	["fromBundles ignores drafts, unpriced bundles and non-cosmetic rewards"] = function()
		local set = BundleSkins.fromBundles({
			{
				id = "a",
				nameKey = "x",
				theme = "#000000",
				rarity = 1,
				robux = 99,
				rewards = {
					{ kind = "cosmetic", id = "body_a" },
					{ kind = "ember", amount = 10 },
					{ kind = "kit", id = "kit_x" },
				},
			},
			{
				id = "b",
				nameKey = "x",
				theme = "#000000",
				rarity = 1,
				robux = 99,
				rascunho = true,
				rewards = { { kind = "cosmetic", id = "body_b" } },
			},
			{
				id = "c",
				nameKey = "x",
				theme = "#000000",
				rarity = 1,
				rewards = { { kind = "cosmetic", id = "body_c" } },
			},
		})
		assert(set.body_a == true, "skin do pacote à venda entra")
		assert(set.body_b == nil and set.body_c == nil, "rascunho/sem preço não contam")
		assert(set.kit_x == nil, "kit não é skin")
	end,

	["items includes unreleased skins only when owned"] = function()
		local all = CosmeticCatalog.items("body", function(_id: string)
			return true
		end)
		assert(#all == 181, `com todas possuídas, esperava as 181 skins de corpo, veio {#all}`)
		local withOne = CosmeticCatalog.items("body", function(id: string)
			return id == "body_dragao"
		end)
		assert(#withOne == 50, `esperava 50 skins com body_dragao possuído, veio {#withOne}`)
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
