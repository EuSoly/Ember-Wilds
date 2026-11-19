--!strict
local Strings = require("../src/shared/Strings")
local ptBR = require("../src/shared/Strings/ptBR") :: { [string]: string }
local en = require("../src/shared/Strings/en") :: { [string]: string }

-- As variáveis {x} de um texto, em ordem alfabética e sem repetição ("day,n").
local function variables(text: string): string
	local seen: { [string]: boolean } = {}
	local names = {}
	for name in string.gmatch(text, "{(%w+)}") do
		if not seen[name] then
			seen[name] = true
			table.insert(names, name)
		end
	end
	table.sort(names)
	return table.concat(names, ",")
end

return {
	["returns pt-BR text"] = function()
		assert(Strings.get("tier.gold") == "Ouro", `veio {Strings.get("tier.gold")}`)
		assert(Strings.get("rarity.legendary") == "Lendário", `veio {Strings.get("rarity.legendary")}`)
	end,

	["missing key is visible"] = function()
		assert(Strings.get("nao.existe") == "[nao.existe]", `veio {Strings.get("nao.existe")}`)
	end,

	["format fills variables"] = function()
		assert(Strings.format("hud.day", { day = 3 }) == "Dia 3", Strings.format("hud.day", { day = 3 }))
	end,

	["format keeps unknown variables"] = function()
		assert(Strings.format("hud.day", {}) == "Dia {day}", Strings.format("hud.day", {}))
	end,

	["has reports presence"] = function()
		assert(Strings.has("rarity.legendary") == true, "rarity.legendary deveria existir")
		assert(Strings.has("nao.existe") == false, "nao.existe não deveria existir")
	end,

	-- Texto novo entra nas duas línguas: este teste cobra o en.
	["every ptBR key exists in en"] = function()
		local missing = {}
		for key in ptBR do
			if en[key] == nil then
				table.insert(missing, key)
			end
		end
		table.sort(missing)
		assert(#missing == 0, `faltam {#missing} chave(s) no en.luau: {table.concat(missing, ", ")}`)
	end,

	-- Chave só no en é erro de digitação (ou sobra de texto apagado do ptBR).
	["en has no extra keys"] = function()
		local extra = {}
		for key in en do
			if ptBR[key] == nil then
				table.insert(extra, key)
			end
		end
		table.sort(extra)
		assert(#extra == 0, `chave(s) no en.luau que não existem no ptBR: {table.concat(extra, ", ")}`)
	end,

	-- As variáveis {x} são preenchidas pelo código: se mudar o nome numa
	-- língua, aquele idioma mostra "{x}" na tela.
	["same {variables} in both languages"] = function()
		local wrong = {}
		for key, text in ptBR do
			local other = en[key]
			if other ~= nil and variables(text) ~= variables(other) then
				table.insert(wrong, `{key} (ptBR: {variables(text)} / en: {variables(other)})`)
			end
		end
		table.sort(wrong)
		assert(#wrong == 0, `variáveis diferentes: {table.concat(wrong, "; ")}`)
	end,

	["language by roblox locale"] = function()
		assert(Strings.languageOf("pt-br") == "ptBR", "pt-br")
		assert(Strings.languageOf("pt-pt") == "ptBR", "pt-pt também é português")
		assert(Strings.languageOf("PT") == "ptBR", "maiúscula")
		assert(Strings.languageOf("en-us") == "en", "en-us")
		assert(Strings.languageOf("es-es") == "en", "outra língua cai no inglês")
		assert(Strings.languageOf(nil) == "ptBR" and Strings.languageOf("") == "ptBR", "sem locale: português")
	end,

	["english text with fallback to ptBR"] = function()
		Strings.setLanguage("en")
		local gold = Strings.get("tier.gold")
		local day = Strings.format("hud.day", { day = 3 })
		local missing = Strings.get("nao.existe")
		Strings.setLanguage("ptBR")
		assert(gold == en["tier.gold"] and gold ~= "Ouro", `veio {gold}`)
		assert(day == "Day 3", `veio {day}`)
		assert(missing == "[nao.existe]", `veio {missing}`)
		-- O servidor escolhe pelo jogador; sem jogador, português.
		assert(Strings.getFor(nil, "tier.gold") == "Ouro", "getFor sem jogador = ptBR")
	end,
}
