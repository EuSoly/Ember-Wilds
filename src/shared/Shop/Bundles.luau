--!strict
-- PACOTES EM DESTAQUE da loja. Este é o arquivo para criar e mudar pacotes:
-- uma entrada por pacote, na ordem em que aparecem no carrossel.
--
-- Exemplo para copiar (veja docs/guia/loja.md):
--   {
--   	id = "outono",                     -- único; vira o produto "bundle_outono"
--   	nameKey = "shop.bundle.outono",    -- texto em Strings/ptBR.luau
--   	theme = "#C8641E",                 -- cor do card
--   	rarity = 4,                        -- moldura: 1 Comum … 6 Mítico
--   	robux = 299,                       -- preço em Robux
--   	startsAt = "2026-11-20 18:00",     -- horário de Brasília; sem = já começou
--   	endsAt = "2026-11-27 18:00",       -- sem = não acaba
--   	rewards = {
--   		{ kind = "cosmetic", id = "body_cervo" },
--   		{ kind = "ember", amount = 500 },
--   		{ kind = "spins", spin = "paid", count = 2 }, -- "normal" ou "paid" (especial)
--   		{ kind = "kit", id = "kit_explorer" },        -- kit para sempre
--   		{ kind = "kitOnce", id = "kit_survivor", count = 3 }, -- saldo de 1 vida
--   	},
--   },
--
-- Cada jogador compra um pacote uma vez só. Skin que ele já tem é pulada e o
-- resto entra. Os tipos de recompensa ficam em Shop/Rewards.luau.
-- Depois de editar: bash scripts/check.sh (ele avisa skin/kit que não existe,
-- data mal escrita, fim antes do começo, texto faltando...).
local Types = require("./Types")

-- Os IDs históricos mar, floresta e gelo preservam recibos, presentes e posses.
local Bundles: { Types.BundleDef } = {
	{
		id = "mar",
		nameKey = "shop.bundle.mar",
		theme = "#126684",
		rarity = 6,
		robux = 499,

		rewards = {
			{ kind = "cosmetic", id = "body_lula" },
			{ kind = "cosmetic", id = "crate_kraken" },
			{ kind = "cosmetic", id = "bag_caranguejo" },
			{ kind = "cosmetic", id = "book_tentaculo" },
		},
	},
	{
		id = "floresta",
		nameKey = "shop.bundle.floresta",
		theme = "#497632",
		rarity = 5,
		robux = 399,

		rewards = {
			{ kind = "cosmetic", id = "body_toco" },
			{ kind = "cosmetic", id = "crate_jardim" },
			{ kind = "cosmetic", id = "bag_cubos_esmeralda" },
			{ kind = "cosmetic", id = "book_trepadeira" },
		},
	},
	{
		id = "gelo",
		nameKey = "shop.bundle.gelo",
		theme = "#966337",
		rarity = 4,
		robux = 299,

		rewards = {
			{ kind = "cosmetic", id = "body_explorador" },
			{ kind = "cosmetic", id = "crate_aventureiro" },
			{ kind = "cosmetic", id = "bag_cartografo" },
			{ kind = "cosmetic", id = "book_bussola" },
		},
	},
}

return Bundles
