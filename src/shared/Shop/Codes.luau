--!strict
-- CÓDIGOS DE RESGATE (o jogador digita no menu, botão embaixo do calendário).
-- Uma entrada por código. Cada jogador usa cada código uma vez. Maiúsculas,
-- minúsculas e espaços não importam para quem digita; aqui o código vai em
-- MAIÚSCULAS, só letras e números (3 a 24). Guia: docs/guia/codigos.md.
--
-- Exemplo para copiar:
--   {
--   	code = "LANCAMENTO",
--   	rewards = {
--   		{ kind = "ember", amount = 500 },                 -- Golden Ember
--   		{ kind = "spins", spin = "paid", count = 3 },     -- "normal" ou "paid" (especial)
--   		{ kind = "cosmetic", id = "body_tubarao" },       -- skin
--   		{ kind = "kitOnce", id = "kit_explorer", count = 2 }, -- kit de 1 vida
--   		{ kind = "kit", id = "kit_survivor" },            -- kit para sempre
--   		{ kind = "xpBoost", count = 3600 },               -- boost de XP (segundos)
--   		{ kind = "reviveCredit", count = 1 },             -- revive guardado
--   	},
--   	startsAt = "2026-11-20 18:00", -- horário de Brasília; sem = já vale
--   	endsAt = "2026-11-27 18:00",   -- sem = não vence
--   },
--
-- Depois de editar: bash scripts/check.sh (avisa código repetido, prêmio que
-- não existe, data mal escrita...) e publicar o jogo.
local CodeRules = require("./CodeRules")

local Codes: { CodeRules.CodeDef } = {
	-- Teste do sistema (18/11/2026): tirar antes do lançamento.
	{
		code = "TESTE",
		rewards = { { kind = "ember", amount = 100 } },
		endsAt = "2026-11-30 23:59",
	},
}

return Codes
