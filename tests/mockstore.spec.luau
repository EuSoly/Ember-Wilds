--!strict
local MockStore = require("../src/shared/UIFlow/MockStore")
local Strings = require("../src/shared/Strings")
local CosmeticCatalog = require("../src/shared/UIFlow/CosmeticCatalog")

local function checkKey(key: string)
	assert(Strings.has(key), `chave de texto faltando: {key}`)
end

return {
	["pesos da vitrine têm 5 raridades e somam 100"] = function()
		for name, odds in
			{
				vitrine = MockStore.SHOWCASE_WEIGHTS,
			}
		do
			assert(#odds == 5, `{name}: {#odds} valores`)
			local total = 0
			for _, v in odds do
				assert(v > 0, `{name}: chance não positiva`)
				total += v
			end
			assert(math.abs(total - 100) <= 1e-6, `{name}: soma {total}`)
		end
	end,

	["raridades da tabela do Elizeu"] = function()
		local ids, colors = {}, {}
		for _, rarity in MockStore.RARITIES do
			table.insert(ids, rarity.id)
			table.insert(colors, rarity.color)
			checkKey(rarity.nameKey)
		end
		assert(table.concat(ids, ",") == "common,rare,epic,legendary,mythic", table.concat(ids, ","))
		assert(table.concat(colors, ",") == "#9CA3AF,#3B9DFF,#A855F7,#FFBD38,#FF4545", table.concat(colors, ","))
	end,

	["tipos de giro na ordem, com as skins reais do catálogo"] = function()
		local ids = {}
		for _, t in MockStore.SPIN_TYPES do
			table.insert(ids, t.id)
			local expected = CosmeticCatalog.spinItems(t.id)
			assert(#t.items == #expected, `{t.id}: {#t.items} itens, catálogo tem {#expected}`)
			for i, item in t.items do
				assert(item.id == expected[i].id, `{t.id}[{i}]: {item.id} ~= {expected[i].id}`)
				assert(item.rarity >= 1 and item.rarity <= 5, `{item.id}: raridade {item.rarity}`)
				assert(string.match(item.color, "^#%x%x%x%x%x%x$"), `{item.id}: cor {item.color}`)
			end
			-- Só o acessório (sem slot ainda) fica vazio.
			assert((#t.items == 0) == (t.id == "accessory"), `{t.id}: {#t.items} itens`)
		end
		assert(table.concat(ids, ",") == "body,accessory,bag,book,crate", table.concat(ids, ","))
	end,

	["giro do corpo, do livro e do acessório"] = function()
		local byId = {}
		for _, t in MockStore.SPIN_TYPES do
			byId[t.id] = t
		end
		local bodyIds = {}
		for _, item in CosmeticCatalog.spinItems("body") do
			table.insert(bodyIds, item.id)
		end
		local got = {}
		for _, item in byId.body.items do
			table.insert(got, item.id)
		end
		assert(table.concat(got, ",") == table.concat(bodyIds, ","), table.concat(got, ","))
		assert(#byId.accessory.items == 0, "acessório deveria estar vazio")
		assert(
			#byId.book.items == 21 and byId.book.items[1].id == "book_default",
			"21 livros começando por book_default"
		)
		-- Raridades do corpo desligadas até o Elizeu definir as das skins 3D
		-- (todas estão Comum; ver docs/pendencias.md, "Skins 3D"). Religar depois.
	end,

	["kit panel strings exist"] = function()
		for _, key in
			{
				"menu.nav.settings",
				"menu.kits.button",
				"menu.kits.none",
				"menu.play.big",
				"kit.panel.title",
				"kit.yourPoints",
				"kit.once",
				"kit.forever",
				"kit.missing",
				"kit.robux",
				"kit.use",
				"kit.active",
			}
		do
			checkKey(key)
		end
		assert(
			Strings.format("kit.robux", { price = 25 }) == "\u{E002} 25",
			Strings.format("kit.robux", { price = 25 })
		)
	end,

	["shop UI strings exist"] = function()
		for _, key in
			{
				"shop.title",
				"shop.back",
				"shop.tab.packs",
				"shop.tab.passes",
				"shop.tab.spins",
				"shop.tab.ember",
				"shop.section.packs",
				"shop.section.passes",
				"shop.section.spins",
				"shop.section.ember",
				"shop.choose",
				"shop.spin.title",
				"shop.spin.normal",
				"shop.spin.paid",
				"shop.spin.have",
				"shop.spin.go",
				"shop.spin.won",
				"shop.spin.take",
				"shop.spin.chance",
				"shop.spin.buy",
				"shop.missing",
				"shop.ember.amount",
				"shop.ember.instant",
				"shop.owned",
				"shop.timer",
			}
		do
			checkKey(key)
		end
		assert(
			Strings.format("shop.timer", { d = 2, h = 10, m = 7 }) == "2D 10H 7M",
			Strings.format("shop.timer", { d = 2, h = 10, m = 7 })
		)
	end,

	["toda nameKey do mockup existe em Strings"] = function()
		for _, t in MockStore.SPIN_TYPES do
			checkKey(t.nameKey)
			for _, item in t.items do
				checkKey(item.nameKey)
			end
		end
	end,
}
