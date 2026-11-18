--!strict
local CodeRules = require("../src/shared/Shop/CodeRules")
local Codes = require("../src/shared/Shop/Codes")
local Defs = require("../src/shared/Defs")
local ShopDates = require("../src/shared/Shop/ShopDates")

local function has(errors: { string }, fragment: string): boolean
	for _, message in errors do
		if string.find(message, fragment, 1, true) then
			return true
		end
	end
	return false
end

local SAMPLE: { CodeRules.CodeDef } = {
	{ code = "LANCAMENTO", rewards = { { kind = "ember", amount = 500 } } },
	{
		code = "NATAL",
		rewards = { { kind = "spins", spin = "paid", count = 3 } },
		startsAt = "2026-12-20 00:00",
		endsAt = "2026-12-26 00:00",
	},
}

return {
	["typing ignores spaces and case"] = function()
		assert(CodeRules.normalize("  lan camento ") == "LANCAMENTO", CodeRules.normalize("  lan camento "))
		assert(CodeRules.find(SAMPLE, "lancamento") ~= nil, "acha sem diferenciar maiúscula")
		assert(CodeRules.find(SAMPLE, "nada") == nil, "não existe")
	end,

	["check: unknown, not yet, expired, used, ok"] = function()
		local natal = CodeRules.find(SAMPLE, "natal")
		local starts = ShopDates.parse("2026-12-20 00:00") :: number
		local ends = ShopDates.parse("2026-12-26 00:00") :: number
		assert(CodeRules.check(nil, {}, 0) == "unknown", "sem código")
		assert(CodeRules.check(natal, {}, starts - 1) == "notYet", "antes do começo")
		assert(CodeRules.check(natal, {}, ends) == "expired", "no fim já venceu")
		assert(CodeRules.check(natal, { NATAL = true }, starts) == "used", "já usado")
		assert(CodeRules.check(natal, {}, starts) == nil, "vale")
		assert(CodeRules.check(CodeRules.find(SAMPLE, "LANCAMENTO"), {}, 0) == nil, "sem datas vale sempre")
	end,

	["validate catches mistakes"] = function()
		local bad: { any } = {
			{ code = "ab", rewards = { { kind = "ember", amount = 1 } } },
			{ code = "DUPLO", rewards = { { kind = "ember", amount = 1 } } },
			{ code = "DUPLO", rewards = { { kind = "ember", amount = 1 } } },
			{ code = "VAZIO", rewards = {} },
			{ code = "RUIM", rewards = { { kind = "nada" } } },
			{ code = "DATA", rewards = { { kind = "ember", amount = 1 } }, endsAt = "amanhã" },
			{
				code = "INVERTIDO",
				rewards = { { kind = "ember", amount = 1 } },
				startsAt = "2026-12-02 00:00",
				endsAt = "2026-12-01 00:00",
			},
		}
		local errors = CodeRules.validate(bad, Defs)
		assert(has(errors, `"ab"`), "código curto/minúsculo")
		assert(has(errors, "repetido"), "repetido")
		assert(has(errors, "VAZIO"), "sem prêmio")
		assert(has(errors, "RUIM"), "prêmio inválido")
		assert(has(errors, "DATA"), "data mal escrita")
		assert(has(errors, "INVERTIDO"), "fim antes do começo")
		assert(#CodeRules.validate(SAMPLE, Defs) == 0, "exemplo válido")
	end,

	["the real codes file is valid"] = function()
		local errors = CodeRules.validate(Codes, Defs)
		assert(#errors == 0, table.concat(errors, "\n"))
	end,
}
