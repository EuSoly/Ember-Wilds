--!strict
local Defs = require("../src/shared/Defs")
local MockStore = require("../src/shared/UIFlow/MockStore")
local Strings = require("../src/shared/Strings")
local CosmeticCatalog = require("../src/shared/UIFlow/CosmeticCatalog")

local function checkKey(key: string)
	assert(Strings.has(key), `chave de texto faltando: {key}`)
end

return {
	["tem os 5 pacotes de moeda com os valores da referência"] = function()
		local expected = { { 300, 80 }, { 600, 150 }, { 2600, 600 }, { 7000, 1500 }, { 20000, 3500 } }
		assert(#MockStore.PACKS == 5, `veio {#MockStore.PACKS}`)
		for i, pack in MockStore.PACKS do
			assert(pack.amount == expected[i][1], `pacote {i}: quantidade {pack.amount}`)
			assert(pack.robux == expected[i][2], `pacote {i}: robux {pack.robux}`)
		end
		assert(MockStore.PACKS[3].tag == "popular", "pacote 3 deveria ser popular")
		assert(MockStore.PACKS[4].tag == "off30", "pacote 4 deveria ser off30")
		assert(MockStore.PACKS[5].tag == "best", "pacote 5 deveria ser best")
	end,

	["chances dos giros têm 5 raridades e somam 100"] = function()
		for name, odds in
			{
				normal = MockStore.SPIN_ODDS.normal,
				paid = MockStore.SPIN_ODDS.paid,
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
		assert(table.concat(MockStore.SPIN_ODDS.normal, ",") == "30,40,23,6,1", "chances do giro normal")
		assert(table.concat(MockStore.SPIN_ODDS.paid, ",") == "5,25,40,25,5", "chances do giro especial")
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
		assert(#byId.book.items == 1 and byId.book.items[1].id == "book_default", "livro = só book_default")
		local seen = {}
		for _, item in byId.body.items do
			seen[item.rarity] = true
		end
		for r = 1, 5 do
			assert(seen[r], `body: sem item de raridade {r}`)
		end
	end,

	["preços dos giros"] = function()
		local function flat(list)
			local out = {}
			for _, e in list do
				table.insert(out, `{e.qty}:{e.price}`)
			end
			return table.concat(out, ",")
		end
		assert(flat(MockStore.SPIN_PRICES.normal) == "1:100,3:280,10:850", flat(MockStore.SPIN_PRICES.normal))
		assert(flat(MockStore.SPIN_PRICES.paid) == "1:49,3:129,10:399", flat(MockStore.SPIN_PRICES.paid))
	end,

	["pacotes em destaque"] = function()
		assert(#MockStore.BUNDLES == 3, `veio {#MockStore.BUNDLES}`)
		for _, b in MockStore.BUNDLES do
			assert(#b.items == 4 and b.robux > 0 and b.endsIn > 0, `{b.id} incompleto`)
		end
	end,

	["gamepasses: kits para sempre e VIP"] = function()
		local byId = {}
		for _, pass in MockStore.PASSES do
			byId[pass.id] = pass
			if pass.kitId then
				assert(pass.robux == MockStore.KIT_ROBUX[pass.kitId].forever, `{pass.id}: preço diferente do kit`)
			end
		end
		for id in Defs.Kits do
			local found = false
			for _, pass in MockStore.PASSES do
				found = found or pass.kitId == id
			end
			assert(found, `kit {id} sem gamepass`)
		end
		assert(byId.vip ~= nil and byId.vip.robux == 149, "VIP de 149")
	end,

	["kit robux prices"] = function()
		local expected = {
			kit_starter = { 15, 99 },
			kit_explorer = { 25, 199 },
			kit_survivor = { 49, 399 },
			kit_veteran = { 99, 799 },
		}
		for id, prices in expected do
			local entry = MockStore.KIT_ROBUX[id]
			assert(entry ~= nil, `{id} sem preço em Robux`)
			assert(entry.once == prices[1] and entry.forever == prices[2], `{id}: {entry.once}/{entry.forever}`)
		end
	end,

	["every kit has robux prices"] = function()
		for id in Defs.Kits do
			assert(MockStore.KIT_ROBUX[id] ~= nil, `{id} sem preço em Robux`)
		end
	end,

	["starts owned exists"] = function()
		assert(#MockStore.KIT_STARTS_OWNED > 0, "nenhum kit começa permanente")
		for _, id in MockStore.KIT_STARTS_OWNED do
			assert(Defs.Kits[id] ~= nil, `{id} não existe em Defs.Kits`)
		end
	end,

	["kit panel strings exist"] = function()
		for _, key in
			{
				"menu.nav.settings",
				"menu.kits.button",
				"menu.kits.none",
				"menu.kits.simulated",
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
				"shop.provisional",
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

	["ranking tem 10 linhas em ordem decrescente"] = function()
		assert(#MockStore.RANKING == 10, `veio {#MockStore.RANKING}`)
		for i = 2, #MockStore.RANKING do
			assert(MockStore.RANKING[i - 1].points >= MockStore.RANKING[i].points, `linha {i} fora de ordem`)
		end
	end,

	["toda nameKey do mockup existe em Strings"] = function()
		for _, t in MockStore.SPIN_TYPES do
			checkKey(t.nameKey)
			for _, item in t.items do
				checkKey(item.nameKey)
			end
		end
		for _, bundle in MockStore.BUNDLES do
			checkKey(bundle.nameKey)
			for _, item in bundle.items do
				checkKey(item.nameKey)
			end
		end
		for _, pass in MockStore.PASSES do
			checkKey(pass.nameKey)
			checkKey(pass.descKey)
		end
	end,
}
