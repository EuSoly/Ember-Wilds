--!strict
-- Códigos de resgate (puro; spec 2026-11-18-codigos-design). Os códigos ficam
-- em Shop/Codes; aqui: como o texto digitado vira o código, se ele vale agora
-- para o jogador e a validação do arquivo (o boot para com a lista de erros).
--   "unknown" não existe
--   "notYet"  ainda não começou (startsAt)
--   "expired" venceu (endsAt; vale até o instante anterior)
--   "used"    o jogador já usou
local Rewards = require("./Rewards")
local ShopDates = require("./ShopDates")
local ShopTypes = require("./Types")
local DefsTypes = require("../Defs/Types")

export type CodeDef = {
	code: string, -- A–Z e 0–9, de 3 a 24 letras (como o jogador digita, sem espaço)
	rewards: { ShopTypes.Reward },
	startsAt: string?, -- "AAAA-MM-DD HH:MM", horário de Brasília; sem = já vale
	endsAt: string?, -- idem; sem = não vence
}
export type Refusal = "unknown" | "notYet" | "expired" | "used"

local CodeRules = {}

-- Texto digitado → código: sem espaços e em maiúsculas.
function CodeRules.normalize(text: string): string
	return string.upper((string.gsub(text, "%s+", "")))
end

function CodeRules.find(list: { CodeDef }, typed: string): CodeDef?
	local code = CodeRules.normalize(typed)
	for _, def in list do
		if def.code == code then
			return def
		end
	end
	return nil
end

-- Pode resgatar agora? `used` = códigos que o jogador já usou (perfil).
function CodeRules.check(def: CodeDef?, used: { [string]: boolean }, now: number): Refusal?
	if def == nil then
		return "unknown"
	end
	local startsAt = if def.startsAt then ShopDates.parse(def.startsAt) else nil
	local endsAt = if def.endsAt then ShopDates.parse(def.endsAt) else nil
	if startsAt ~= nil and now < startsAt then
		return "notYet"
	end
	if endsAt ~= nil and now >= endsAt then
		return "expired"
	end
	if used[def.code] == true then
		return "used"
	end
	return nil
end

-- Erros do arquivo de códigos (vazio = tudo certo).
function CodeRules.validate(list: { CodeDef }, defs: DefsTypes.DefsTables): { string }
	local errors: { string } = {}
	local seen: { [string]: boolean } = {}
	for i, def in list do
		local label = `código "{def.code}" (#{i})`
		local function fail(message: string)
			table.insert(errors, `{label}: {message}`)
		end
		if
			type(def.code) ~= "string"
			or not string.match(def.code, "^[A-Z0-9]+$")
			or #def.code < 3
			or #def.code > 24
		then
			fail("só A–Z e 0–9, de 3 a 24 letras")
		elseif seen[def.code] then
			fail("repetido")
		end
		seen[def.code] = true
		if type(def.rewards) ~= "table" or #def.rewards == 0 then
			fail("sem prêmio")
		else
			for _, reward in def.rewards do
				local problem = Rewards.validate(reward, defs)
				if problem then
					fail(problem)
				end
			end
		end
		local startsAt = if def.startsAt ~= nil then ShopDates.parse(def.startsAt) else nil
		local endsAt = if def.endsAt ~= nil then ShopDates.parse(def.endsAt) else nil
		if def.startsAt ~= nil and startsAt == nil then
			fail(`startsAt "{def.startsAt}" fora do formato "AAAA-MM-DD HH:MM"`)
		end
		if def.endsAt ~= nil and endsAt == nil then
			fail(`endsAt "{def.endsAt}" fora do formato "AAAA-MM-DD HH:MM"`)
		end
		if startsAt ~= nil and endsAt ~= nil and endsAt <= startsAt then
			fail("endsAt precisa ser depois de startsAt")
		end
	end
	return errors
end

return CodeRules
