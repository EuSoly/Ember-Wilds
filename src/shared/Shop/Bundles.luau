--!strict
-- PACOTES EM DESTAQUE da loja. Este é o arquivo para criar e mudar pacotes:
-- uma entrada por pacote, na ordem em que aparecem no carrossel.
--
-- Exemplo para copiar (veja docs/guia/loja.md):
--   {
--   	id = "outono",                     -- único; vira o produto "bundle_outono"
--   	nameKey = "shop.bundle.outono",    -- texto em Strings/ptBR.luau
--   	theme = "#C8641E",                 -- cor do card
--   	rarity = 4,                        -- moldura: 1 Comum … 5 Mítico
--   	robux = 299,                       -- preço (ainda não é cobrado)
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

local Bundles: { Types.BundleDef } = {
	{
		id = "brasa",
		nameKey = "shop.bundle.brasa",
		theme = "#B8361A",
		rarity = 5,
		robux = 399,
		startsAt = "2026-11-09 00:00",
		endsAt = "2026-11-11 10:00",
		rewards = {
			{ kind = "cosmetic", id = "body_chama" },
			{ kind = "cosmetic", id = "book_lava" },
			{ kind = "cosmetic", id = "bag_chamas_fogo" },
			{ kind = "cosmetic", id = "crate_magma" },
			{ kind = "ember", amount = 500 },
		},
	},
	{
		id = "geada",
		nameKey = "shop.bundle.geada",
		theme = "#2F7FD8",
		rarity = 4,
		robux = 349,
		startsAt = "2026-11-09 00:00",
		endsAt = "2026-11-14 02:40",
		rewards = {
			{ kind = "cosmetic", id = "body_espirito_gelo" },
			{ kind = "cosmetic", id = "book_gelo" },
			{ kind = "cosmetic", id = "bag_cristais_gelo" },
			{ kind = "cosmetic", id = "crate_gelo" },
			{ kind = "spins", spin = "paid", count = 3 },
		},
	},
	{
		id = "musgo",
		nameKey = "shop.bundle.musgo",
		theme = "#4E9A2E",
		rarity = 2,
		robux = 299,
		startsAt = "2026-11-09 00:00",
		endsAt = "2026-11-10 12:05",
		rewards = {
			{ kind = "cosmetic", id = "body_arbusto_florido" },
			{ kind = "cosmetic", id = "book_floresta" },
			{ kind = "cosmetic", id = "bag_tronco_florido" },
			{ kind = "cosmetic", id = "crate_jardim" },
			{ kind = "kit", id = "kit_explorer" },
		},
	},
}

return Bundles
