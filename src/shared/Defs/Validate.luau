--!strict
-- Validação das definições. Roda no boot (Defs/init.luau): um erro de digitação
-- nas tabelas de conteúdo derruba o jogo com mensagem clara, em vez de virar
-- um bug silencioso no meio da partida.
local InventoryConfig = require("../InventoryConfig")
local Types = require("./Types")

local ID_PATTERN = "^[a-z0-9_]+$"
local HEX_PATTERN = "^#%x%x%x%x%x%x$"
-- Strings de atributo têm no máximo 50 caracteres no Server Authority, e o id
-- do cosmético vai num atributo (Cosmetic_<slot>).
local MAX_COSMETIC_ID_LENGTH = 50

local Validate = {}

-- Lista única de estilos de olho: usada aqui e pelo boneco visual (que monta
-- uma variação de olho para cada um).
local EYE_STYLES: { Types.EyeStyle } = { "open", "closed", "squeeze" }
Validate.EYE_STYLES = table.freeze(EYE_STYLES)

local TRIGGERS = table.freeze({ "always", "periodic", "event", "condition" })

local function isHex(value: any): boolean
	return type(value) == "string" and string.match(value, HEX_PATTERN) ~= nil
end

local function isPositive(value: any): boolean
	return type(value) == "number" and value > 0
end

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

local function validateCosmetics(errors: { string }, defs: Types.DefsTables, hasString: (string) -> boolean)
	-- Tabelas ausentes (testes antigos) contam como vazias.
	local slots: { [string]: Types.CosmeticSlotDef } = (defs :: any).CosmeticSlots or {}
	local cosmetics: { [string]: Types.CosmeticDef } = (defs :: any).Cosmetics or {}

	for key, cosmetic in cosmetics do
		checkId(errors, "Cosmetic", key, cosmetic.id)
		if #key > MAX_COSMETIC_ID_LENGTH then
			table.insert(errors, `Cosmetic "{key}": id com mais de {MAX_COSMETIC_ID_LENGTH} caracteres`)
		end
		checkString(errors, "Cosmetic", key, "nameKey", cosmetic.nameKey, hasString)
		if slots[cosmetic.slot] == nil then
			table.insert(errors, `Cosmetic "{key}": slot "{cosmetic.slot}" não existe em CosmeticSlots`)
		end
		if cosmetic.slot == "body" then
			local body = cosmetic.body
			if body == nil then
				table.insert(errors, `Cosmetic "{key}": slot "body" precisa de body`)
			else
				for _, field in { "bodyColor", "outlineColor" } do
					if not isHex((body :: any)[field]) then
						table.insert(errors, `Cosmetic "{key}": {field} inválida (use #RRGGBB)`)
					end
				end
				for _, field in { "handColor", "eyeColor" } do
					local value = (body :: any)[field]
					if value ~= nil and not isHex(value) then
						table.insert(errors, `Cosmetic "{key}": {field} inválida (use #RRGGBB)`)
					end
				end
			end
		end
	end

	for key, slot in slots do
		checkId(errors, "CosmeticSlot", key, slot.id)
		checkString(errors, "CosmeticSlot", key, "nameKey", slot.nameKey, hasString)
		local default = cosmetics[slot.default]
		if default == nil then
			table.insert(errors, `CosmeticSlot "{key}": default "{slot.default}" não existe em Cosmetics`)
		elseif default.slot ~= key then
			table.insert(errors, `CosmeticSlot "{key}": default "{slot.default}" é do slot "{default.slot}"`)
		end
	end
end

local function validateExpressions(errors: { string }, defs: Types.DefsTables)
	local expressions: { [string]: Types.ExpressionDef }? = (defs :: any).Expressions
	if expressions == nil then
		return
	end

	local alwaysCount = 0
	for key, expression in expressions do
		checkId(errors, "Expression", key, expression.id)
		if type(expression.priority) ~= "number" then
			table.insert(errors, `Expression "{key}": priority deve ser número`)
		end
		if not table.find(Validate.EYE_STYLES, expression.eyes) then
			table.insert(errors, `Expression "{key}": eyes "{expression.eyes}" não existe`)
		end

		local trigger = expression.trigger
		if not table.find(TRIGGERS, trigger) then
			table.insert(errors, `Expression "{key}": trigger "{trigger}" não existe`)
		elseif trigger == "always" then
			alwaysCount += 1
		elseif trigger == "event" then
			if type(expression.event) ~= "string" then
				table.insert(errors, `Expression "{key}": trigger "event" precisa de event`)
			end
			if not isPositive(expression.duration) then
				table.insert(errors, `Expression "{key}": duration deve ser maior que 0`)
			end
		elseif trigger == "periodic" then
			if not isPositive(expression.duration) then
				table.insert(errors, `Expression "{key}": duration deve ser maior que 0`)
			end
			local min, max = expression.intervalMin, expression.intervalMax
			if not isPositive(min) then
				table.insert(errors, `Expression "{key}": intervalMin deve ser maior que 0`)
			end
			if type(max) ~= "number" or type(min) ~= "number" or max < min then
				table.insert(errors, `Expression "{key}": intervalMax deve ser maior ou igual a intervalMin`)
			end
		elseif trigger == "condition" then
			local condition = expression.condition
			if condition == nil or type(condition.attribute) ~= "string" then
				table.insert(errors, `Expression "{key}": trigger "condition" precisa de condition.attribute`)
			elseif type(condition.below) ~= "number" and type(condition.above) ~= "number" then
				table.insert(errors, `Expression "{key}": condition precisa de below ou above`)
			end
		end

		local flash = expression.flash
		if flash ~= nil then
			if not isHex(flash.color) then
				table.insert(errors, `Expression "{key}": flash.color inválida (use #RRGGBB)`)
			end
			if not isPositive(flash.duration) then
				table.insert(errors, `Expression "{key}": flash.duration deve ser maior que 0`)
			end
		end
	end

	-- A expressão "always" é a base (olhos normais): sem ela o boneco ficaria sem
	-- olhos; com duas, a escolha dependeria da ordem da tabela.
	if alwaysCount ~= 1 then
		table.insert(errors, `Expressions: deve haver exatamente uma com trigger "always" (há {alwaysCount})`)
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
		if #key > InventoryConfig.MAX_ITEM_ID_LENGTH then
			table.insert(errors, `Item "{key}": id com mais de {InventoryConfig.MAX_ITEM_ID_LENGTH} caracteres`)
		end
		if
			type(item.maxStack) ~= "number"
			or item.maxStack < 1
			or item.maxStack % 1 ~= 0
			or item.maxStack > InventoryConfig.MAX_STACK
		then
			table.insert(errors, `Item "{key}": maxStack deve ser inteiro entre 1 e {InventoryConfig.MAX_STACK}`)
		end
		-- Mochilas: precisam de bagSlots, e só elas podem ter.
		local maxBagSlots = InventoryConfig.MAX_SLOTS - InventoryConfig.BASE_SLOTS
		if item.category == "bag" then
			local slots = item.bagSlots
			if type(slots) ~= "number" or slots < 1 or slots % 1 ~= 0 or slots > maxBagSlots then
				table.insert(errors, `Item "{key}": mochila precisa de bagSlots inteiro entre 1 e {maxBagSlots}`)
			end
		elseif item.bagSlots ~= nil then
			table.insert(errors, `Item "{key}": bagSlots só vale para category "bag"`)
		end
	end

	validateCosmetics(errors, defs, hasString)
	validateExpressions(errors, defs)

	table.sort(errors)
	return errors
end

return Validate
