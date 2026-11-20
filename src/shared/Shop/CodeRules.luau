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
	-- Código em destaque: a janela mostra "NOVO CÓDIGO: X" e o botão acende o
	-- aviso vermelho para quem ainda não usou. Vale o último marcado que estiver
	-- valendo agora (CodeRules.news).
	news: boolean?,
}
export type Refusal = "unknown" | "notYet" | "expired" | "used"

local CodeRules = {}

-- Só A–Z e 0–9, de 3 a 24 letras (o formato de um código no arquivo).
function CodeRules.isCodeShape(code: any): boolean
	return type(code) == "string" and string.match(code, "^[A-Z0-9]+$") ~= nil and #code >= 3 and #code <= 24
end

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

-- O código em destaque agora: o último da lista com `news = true` que já
-- começou e não venceu (nil = nenhum).
function CodeRules.news(list: { CodeDef }, now: number): CodeDef?
	local found: CodeDef? = nil
	for _, def in list do
		if def.news == true then
			local refusal = CodeRules.check(def, {}, now)
			if refusal == nil then
				found = def
			end
		end
	end
	return found
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
		if not CodeRules.isCodeShape(def.code) then
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
		if def.news ~= nil and type(def.news) ~= "boolean" then
			fail("news precisa ser true ou false")
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
