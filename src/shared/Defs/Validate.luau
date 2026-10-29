--!strict
-- Validação das definições. Roda no boot (Defs/init.luau): um erro de digitação
-- nas tabelas de conteúdo derruba o jogo com mensagem clara, em vez de virar
-- um bug silencioso no meio da partida.
local Types = require("./Types")

local ID_PATTERN = "^[a-z0-9_]+$"

local Validate = {}

local function checkId(errors: { string }, kind: string, key: string, id: string)
	if id ~= key then
		table.insert(errors, `{kind} "{key}": id "{id}" diferente da chave`)
	end
	if not string.match(key, ID_PATTERN) then
		table.insert(errors, `{kind} "{key}": id deve usar só a-z, 0-9 e _`)
	end
end

local function checkString(
	errors: { string },
	kind: string,
	key: string,
	field: string,
	value: string,
	hasString: (string) -> boolean
)
	if not hasString(value) then
		table.insert(errors, `{kind} "{key}": {field} "{value}" sem texto em Strings`)
	end
end

-- Devolve a lista de erros encontrados (vazia = tudo certo).
function Validate.all(defs: Types.DefsTables, hasString: (string) -> boolean): { string }
	local errors: { string } = {}

	for key, tier in defs.Tiers do
		checkId(errors, "Tier", key, tier.id)
		checkString(errors, "Tier", key, "nameKey", tier.nameKey, hasString)
		checkString(errors, "Tier", key, "rarityKey", tier.rarityKey, hasString)
		if type(tier.color) ~= "string" or not string.match(tier.color, "^#%x%x%x%x%x%x$") then
			table.insert(errors, `Tier "{key}": cor inválida`)
		end
	end

	for key, item in defs.Items do
		checkId(errors, "Item", key, item.id)
		checkString(errors, "Item", key, "nameKey", item.nameKey, hasString)
		if item.tier ~= nil and defs.Tiers[item.tier] == nil then
			table.insert(errors, `Item "{key}": tier "{item.tier}" não existe em Tiers`)
		end
		if type(item.maxStack) ~= "number" or item.maxStack < 1 or item.maxStack % 1 ~= 0 then
			table.insert(errors, `Item "{key}": maxStack deve ser inteiro >= 1`)
		end
	end

	table.sort(errors)
	return errors
end

return Validate
