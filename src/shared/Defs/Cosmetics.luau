--!strict
-- Cosméticos (skins). TUDO sobre uma skin mora aqui: a tela de Cosméticos e o
-- carrossel da loja leem esta tabela. Para criar uma skin, copie uma entrada
-- parecida e troque os campos:
--
--   id        nome único, só a-z, 0-9 e _ (a chave da tabela é igual ao id).
--             Convenção: "<slot>_<nome>", ex. body_musgo.
--   nameKey   "cosmetic.<id>"; o texto em pt-BR vai em Strings/ptBR.luau,
--             ex. ["cosmetic.body_musgo"] = "Musgo".
--   slot      onde a skin se aplica: "body" (corpo), "bag" (mochila),
--             "crate" (caixa de itens) ou "book" (livro).
--   rarity    1 Comum, 2 Raro, 3 Épico, 4 Lendário, 5 Mítico (define a cor da
--             moldura e a ordem na lista).
--   inSpins   (opcional) entra no giro da loja? Por padrão sim; false tira.
--             A skin padrão de cada slot fica fora do giro, a não ser que
--             tenha inSpins = true (o livro, que só tem uma, precisa).
--   cores     um bloco por slot, todas no formato "#RRGGBB":
--               body  = { bodyColor, outlineColor, handColor?, eyeColor? }
--               bag   = { color, strapColor }    (mochila e alça)
--               crate = { bodyColor, bandColor } (corpo e faixas)
--             O livro não tem cores: é sempre o modelo book de Assets.Tools.
--
-- Depois de editar, rode "bash scripts/check.sh": ele avisa se faltar texto,
-- cor inválida ou rarity fora de 1..5. Veja também docs/guia/boneco.md.
local Types = require("./Types")

type CosmeticDef = Types.CosmeticDef

local Cosmetics: { [string]: CosmeticDef } = {
	----------------------------------------------------------------- Corpo
	-- Cores do spike aprovado: o padrão de quem não equipou nada.
	body_default = {
		id = "body_default",
		nameKey = "cosmetic.body_default",
		slot = "body",
		rarity = 1,
		body = { bodyColor = "#DDF3F8", outlineColor = "#1F6F7A" },
	},
	body_musgo = {
		id = "body_musgo",
		nameKey = "cosmetic.body_musgo",
		slot = "body",
		rarity = 1,
		body = { bodyColor = "#A9C98B", outlineColor = "#3F5F2A" },
	},
	body_areia = {
		id = "body_areia",
		nameKey = "cosmetic.body_areia",
		slot = "body",
		rarity = 2,
		body = { bodyColor = "#E8D3A2", outlineColor = "#7A5F2B" },
	},
	body_cobalto = {
		id = "body_cobalto",
		nameKey = "cosmetic.body_cobalto",
		slot = "body",
		rarity = 2,
		body = { bodyColor = "#5B8FE0", outlineColor = "#1B3A73" },
	},
	body_ember = {
		id = "body_ember",
		nameKey = "cosmetic.body_ember",
		slot = "body",
		rarity = 3,
		body = { bodyColor = "#D8250D", outlineColor = "#5F1802" },
	},
	body_orquidea = {
		id = "body_orquidea",
		nameKey = "cosmetic.body_orquidea",
		slot = "body",
		rarity = 3,
		body = { bodyColor = "#C58BE8", outlineColor = "#58267A" },
	},
	body_ambar = {
		id = "body_ambar",
		nameKey = "cosmetic.body_ambar",
		slot = "body",
		rarity = 3,
		body = { bodyColor = "#F0A92E", outlineColor = "#7A4A07" },
	},
	body_aurora = {
		id = "body_aurora",
		nameKey = "cosmetic.body_aurora",
		slot = "body",
		rarity = 4,
		body = { bodyColor = "#6EE7B7", outlineColor = "#116149" },
	},
	body_solar = {
		id = "body_solar",
		nameKey = "cosmetic.body_solar",
		slot = "body",
		rarity = 4,
		body = { bodyColor = "#FFE066", outlineColor = "#9A6A00" },
	},
	body_eclipse = {
		id = "body_eclipse",
		nameKey = "cosmetic.body_eclipse",
		slot = "body",
		rarity = 5,
		body = { bodyColor = "#2A2540", outlineColor = "#FF4545" },
	},

	---------------------------------------------------------------- Mochila
	bag_default = {
		id = "bag_default",
		nameKey = "cosmetic.bag_default",
		slot = "bag",
		rarity = 1,
		bag = { color = "#95603D", strapColor = "#59402D" },
	},
	bag_trilha = {
		id = "bag_trilha",
		nameKey = "cosmetic.bag_trilha",
		slot = "bag",
		rarity = 1,
		bag = { color = "#7A8B4A", strapColor = "#434F25" },
	},
	bag_lona = {
		id = "bag_lona",
		nameKey = "cosmetic.bag_lona",
		slot = "bag",
		rarity = 2,
		bag = { color = "#4A78B8", strapColor = "#26416B" },
	},
	bag_veludo = {
		id = "bag_veludo",
		nameKey = "cosmetic.bag_veludo",
		slot = "bag",
		rarity = 3,
		bag = { color = "#8A3FC4", strapColor = "#4B1F70" },
	},
	bag_dourada = {
		id = "bag_dourada",
		nameKey = "cosmetic.bag_dourada",
		slot = "bag",
		rarity = 4,
		bag = { color = "#E9B13A", strapColor = "#8A5F12" },
	},
	bag_estelar = {
		id = "bag_estelar",
		nameKey = "cosmetic.bag_estelar",
		slot = "bag",
		rarity = 5,
		bag = { color = "#2B2250", strapColor = "#FF4545" },
	},

	----------------------------------------------------------------- Caixa
	-- Cores do placeholder atual da caixa: madeira e faixas douradas.
	crate_default = {
		id = "crate_default",
		nameKey = "cosmetic.crate_default",
		slot = "crate",
		rarity = 1,
		crate = { bodyColor = "#8B5A2B", bandColor = "#F2B632" },
	},
	crate_pinho = {
		id = "crate_pinho",
		nameKey = "cosmetic.crate_pinho",
		slot = "crate",
		rarity = 1,
		crate = { bodyColor = "#B98B55", bandColor = "#6B4A26" },
	},
	crate_ferro = {
		id = "crate_ferro",
		nameKey = "cosmetic.crate_ferro",
		slot = "crate",
		rarity = 2,
		crate = { bodyColor = "#6B7280", bandColor = "#C9CED6" },
	},
	crate_runica = {
		id = "crate_runica",
		nameKey = "cosmetic.crate_runica",
		slot = "crate",
		rarity = 3,
		crate = { bodyColor = "#4B2E83", bandColor = "#C58BE8" },
	},
	crate_ouro = {
		id = "crate_ouro",
		nameKey = "cosmetic.crate_ouro",
		slot = "crate",
		rarity = 4,
		crate = { bodyColor = "#B8861B", bandColor = "#FFE066" },
	},
	crate_cosmica = {
		id = "crate_cosmica",
		nameKey = "cosmetic.crate_cosmica",
		slot = "crate",
		rarity = 5,
		crate = { bodyColor = "#1E1B3A", bandColor = "#FF4545" },
	},

	------------------------------------------------------------------ Livro
	-- Só uma skin: o modelo book de Assets.Tools, sem cores.
	book_default = {
		id = "book_default",
		nameKey = "cosmetic.book_default",
		slot = "book",
		rarity = 1,
		inSpins = true,
	},
}

for _, cosmetic in Cosmetics do
	if cosmetic.body ~= nil then
		table.freeze(cosmetic.body)
	end
	if cosmetic.bag ~= nil then
		table.freeze(cosmetic.bag)
	end
	if cosmetic.crate ~= nil then
		table.freeze(cosmetic.crate)
	end
	table.freeze(cosmetic)
end

return table.freeze(Cosmetics)
