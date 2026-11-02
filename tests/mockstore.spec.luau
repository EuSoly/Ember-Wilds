--!strict
local MockStore = require("../src/shared/UIFlow/MockStore")
local Strings = require("../src/shared/Strings")

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

	["spins têm os preços da referência"] = function()
		local prices = { skin = { 100, 300, 600 }, custom = { 50, 150, 300 } }
		local seen = { skin = 0, custom = 0 }
		for _, spin in MockStore.SPINS do
			seen[spin.kind] += 1
			local expected = prices[spin.kind][seen[spin.kind]]
			assert(spin.price == expected, `{spin.id}: preço {spin.price}, esperava {expected}`)
		end
		assert(seen.skin == 3 and seen.custom == 3, "esperava 3 spins de cada tipo")
	end,

	["as chances de cada spin somam 1"] = function()
		for _, spin in MockStore.SPINS do
			local total = 0
			for _, odd in spin.odds do
				assert(odd.chance > 0, `{spin.id}: chance não positiva`)
				total += odd.chance
			end
			assert(math.abs(total - 1) <= 1e-6, `{spin.id}: soma {total}`)
		end
	end,

	["roll devolve o índice certo nas bordas"] = function()
		local odds = { { chance = 0.5 }, { chance = 0.3 }, { chance = 0.2 } }
		assert(MockStore.roll(odds, 0) == 1, "r=0")
		assert(MockStore.roll(odds, 0.4999) == 1, "r logo abaixo de 0.5")
		assert(MockStore.roll(odds, 0.5) == 2, "r=0.5")
		assert(MockStore.roll(odds, 0.7999) == 2, "r logo abaixo de 0.8")
		assert(MockStore.roll(odds, 0.8) == 3, "r=0.8")
		assert(MockStore.roll(odds, 0.999999) == 3, "r=0.999999")
	end,

	["roll nunca passa do último índice com soma levemente menor que 1"] = function()
		local odds = { { chance = 0.5 }, { chance = 0.4999999 } }
		assert(MockStore.roll(odds, 0.9999999) == 2, "caiu fora da lista")
	end,

	["kit tem livro e mochila e as duas ofertas"] = function()
		assert(#MockStore.KIT.items == 2, "esperava 2 itens")
		assert(#MockStore.KIT.offers == 2, "esperava 2 ofertas")
		assert(MockStore.KIT.offers[1].hours == 1 and MockStore.KIT.offers[1].price == 300, "oferta de 1 h")
		assert(MockStore.KIT.offers[2].hours == 24 and MockStore.KIT.offers[2].price == 600, "oferta de 24 h")
	end,

	["categorias: skins vazia e as outras com 3 ou 4 itens"] = function()
		local ids = {}
		for _, cat in MockStore.CATEGORIES do
			table.insert(ids, cat.id)
			if cat.id == "skins" then
				assert(#cat.items == 0, "skins usa as skins reais")
			else
				assert(#cat.items >= 3 and #cat.items <= 4, `{cat.id}: {#cat.items} itens`)
			end
		end
		assert(table.concat(ids, ",") == "skins,accessories,bag,book,crate", table.concat(ids, ","))
	end,

	["ranking tem 10 linhas em ordem decrescente"] = function()
		assert(#MockStore.RANKING == 10, `veio {#MockStore.RANKING}`)
		for i = 2, #MockStore.RANKING do
			assert(MockStore.RANKING[i - 1].points >= MockStore.RANKING[i].points, `linha {i} fora de ordem`)
		end
	end,

	["perfil tem xp dentro do máximo"] = function()
		local profile = MockStore.PROFILE
		assert(profile.level >= 1 and profile.xp >= 0 and profile.xp <= profile.xpMax, "xp inválido")
		assert(#profile.stats > 0, "sem estatísticas")
	end,

	["toda nameKey do mockup existe em Strings"] = function()
		for _, spin in MockStore.SPINS do
			checkKey(spin.nameKey)
			for _, odd in spin.odds do
				checkKey(odd.nameKey)
			end
		end
		for _, key in MockStore.KIT.items do
			checkKey(key)
		end
		for _, cat in MockStore.CATEGORIES do
			checkKey(cat.nameKey)
			for _, item in cat.items do
				checkKey(item.nameKey)
			end
		end
		for _, stat in MockStore.PROFILE.stats do
			checkKey(stat.nameKey)
		end
		assert(#MockStore.TUTORIAL > 0, "tutorial vazio")
		for _, key in MockStore.TUTORIAL do
			checkKey(key)
		end
	end,
}
