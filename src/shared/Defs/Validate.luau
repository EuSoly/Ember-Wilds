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
-- Ids de estatística e configuração: o de configuração viaja no evento Blink
-- SetSetting (Id string(1..32)); o de estatística usa o mesmo limite por coerência.
local MAX_DATA_ID_LENGTH = 32
-- Opções de configuração "choice" viajam no SetSetting (Choice string(1..16)).
local MAX_SETTING_OPTION_LENGTH = 16

local Validate = {}

-- Lista única de estilos de olho: usada aqui e pelo boneco visual (que monta
-- uma variação de olho para cada um).
local EYE_STYLES: { Types.EyeStyle } = { "open", "closed", "squeeze" }
table.freeze(EYE_STYLES)
Validate.EYE_STYLES = EYE_STYLES

-- Eventos que o boneco visual sabe disparar (BonecoRenderer). Uma expressão de
-- evento com outro nome nunca apareceria, então é erro: evento novo precisa de
-- código no renderer e de entrar nesta lista.
Validate.HURT_EVENT = "hurt" -- dano (atributo HurtAt)
Validate.KNOWN_EVENTS = table.freeze({ Validate.HURT_EVENT })

local TRIGGERS = table.freeze({ "always", "periodic", "event", "condition" })
local STAT_KINDS = table.freeze({ "counter", "max", "keyed" })
local STAT_KEY_KINDS = table.freeze({ "mob", "item" })
local SETTING_KINDS = table.freeze({ "number", "boolean", "choice" })

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
			elseif not table.find(Validate.KNOWN_EVENTS, expression.event) then
				table.insert(
					errors,
					`Expression "{key}": event "{expression.event}" não existe (conhecidos: {table.concat(
						Validate.KNOWN_EVENTS,
						", "
					)})`
				)
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

		-- O flash é medido a partir do disparo do evento: fora de "event" nunca apareceria.
		local flash = expression.flash
		if flash ~= nil and trigger ~= "event" then
			table.insert(errors, `Expression "{key}": flash só vale para trigger "event"`)
		end
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

local function checkDataId(errors: { string }, kind: string, key: string, id: string)
	checkId(errors, kind, key, id)
	if #key > MAX_DATA_ID_LENGTH then
		table.insert(errors, `{kind} "{key}": id com mais de {MAX_DATA_ID_LENGTH} caracteres`)
	end
end

local function validateStats(errors: { string }, defs: Types.DefsTables, hasString: (string) -> boolean)
	local stats: { [string]: Types.StatDef }? = (defs :: any).Stats
	if stats == nil then
		return
	end

	for key, stat in stats do
		checkDataId(errors, "Stat", key, stat.id)
		checkString(errors, "Stat", key, "nameKey", stat.nameKey, hasString)
		if not table.find(STAT_KINDS, stat.kind) then
			table.insert(errors, `Stat "{key}": kind "{stat.kind}" não existe`)
		elseif stat.kind == "keyed" then
			-- A chave precisa dizer o que é (mob, item) para validar e para as telas.
			local keyKind = stat.keyKind
			if keyKind == nil or not table.find(STAT_KEY_KINDS, keyKind :: string) then
				table.insert(errors, `Stat "{key}": kind "keyed" precisa de keyKind "mob" ou "item"`)
			end
		elseif stat.keyKind ~= nil then
			table.insert(errors, `Stat "{key}": keyKind só vale para kind "keyed"`)
		end
	end
end

local function isFiniteNumber(value: any): boolean
	return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function isWholeNumber(value: any, min: number): boolean
	return isFiniteNumber(value) and value % 1 == 0 and value >= min
end

-- order: inteiro ≥ 1 e sem repetir. A ordem decide a posição na tela, e
-- repetida deixaria a lista instável (depende da ordem da tabela).
local function checkOrder(errors: { string }, kind: string, key: string, order: any, seen: { [number]: string })
	if not isWholeNumber(order, 1) then
		table.insert(errors, `{kind} "{key}": order deve ser inteiro maior ou igual a 1`)
	elseif seen[order] ~= nil then
		table.insert(errors, `{kind} "{key}": order {order} repetida (também em "{seen[order]}")`)
	else
		seen[order] = key
	end
end

local function validateSettings(errors: { string }, defs: Types.DefsTables, hasString: (string) -> boolean)
	local settings: { [string]: Types.SettingDef }? = (defs :: any).Settings
	if settings == nil then
		return
	end

	local orders: { [number]: string } = {}
	for key, setting in settings do
		checkDataId(errors, "Setting", key, setting.id)
		checkString(errors, "Setting", key, "nameKey", setting.nameKey, hasString)
		checkOrder(errors, "Setting", key, setting.order, orders)
		local kind = setting.kind
		if not table.find(SETTING_KINDS, kind) then
			table.insert(errors, `Setting "{key}": kind "{kind}" não existe`)
			continue
		end

		-- Campos de faixa/opções só no kind que os usa (senão seriam ignorados em silêncio).
		if kind ~= "number" and (setting.min ~= nil or setting.max ~= nil) then
			table.insert(errors, `Setting "{key}": min/max só valem para kind "number"`)
		end
		if kind ~= "choice" and setting.options ~= nil then
			table.insert(errors, `Setting "{key}": options só vale para kind "choice"`)
		end

		local default = setting.default
		if kind == "number" then
			local min, max = setting.min, setting.max
			if not isFiniteNumber(min) or not isFiniteNumber(max) or (min :: number) >= (max :: number) then
				table.insert(errors, `Setting "{key}": kind "number" precisa de min < max`)
			else
				local low, high = min :: number, max :: number
				if not isFiniteNumber(default) or (default :: number) < low or (default :: number) > high then
					table.insert(errors, `Setting "{key}": default deve ser número entre {low} e {high}`)
				end
			end
		elseif kind == "boolean" then
			if type(default) ~= "boolean" then
				table.insert(errors, `Setting "{key}": default deve ser true ou false`)
			end
		else
			local options = setting.options
			if type(options) ~= "table" or #options == 0 then
				table.insert(errors, `Setting "{key}": kind "choice" precisa de options`)
			else
				local seen: { [string]: boolean } = {}
				for _, option in options do
					if seen[option] then
						table.insert(errors, `Setting "{key}": opção "{option}" repetida`)
					end
					-- Senão o cliente nunca conseguiria pedir essa opção pela rede.
					if type(option) ~= "string" or #option < 1 or #option > MAX_SETTING_OPTION_LENGTH then
						table.insert(
							errors,
							`Setting "{key}": opção "{option}" deve ter de 1 a {MAX_SETTING_OPTION_LENGTH} caracteres`
						)
					end
					seen[option] = true
				end
				if type(default) ~= "string" or not seen[default] then
					table.insert(errors, `Setting "{key}": default "{tostring(default)}" não está em options`)
				end
			end
		end
	end
end

local function validateKits(errors: { string }, defs: Types.DefsTables, hasString: (string) -> boolean)
	local kits: { [string]: Types.KitDef }? = (defs :: any).Kits
	if kits == nil then
		return
	end

	local orders: { [number]: string } = {}
	for key, kit in kits do
		checkId(errors, "Kit", key, kit.id)
		checkString(errors, "Kit", key, "nameKey", kit.nameKey, hasString)
		checkOrder(errors, "Kit", key, kit.order, orders)

		if not isWholeNumber(kit.price, 0) then
			table.insert(errors, `Kit "{key}": price deve ser inteiro maior ou igual a 0`)
		end

		local items = kit.items
		if type(items) ~= "table" or #items == 0 then
			table.insert(errors, `Kit "{key}": items não pode ser vazio`)
			continue
		end

		local bags = 0
		local bagSlots = 0
		-- Quantidade total por item (o mesmo item pode aparecer mais de uma vez).
		local totals: { [string]: number } = {}
		local allValid = true
		for _, entry in items do
			local item = defs.Items[entry.id]
			if item == nil then
				table.insert(errors, `Kit "{key}": item "{tostring(entry.id)}" não existe em Items`)
				allValid = false
				continue
			end
			if not isWholeNumber(entry.count, 1) then
				table.insert(errors, `Kit "{key}": count de "{entry.id}" deve ser inteiro maior ou igual a 1`)
				allValid = false
				continue
			end
			if item.category == "bag" then
				bags += 1
				bagSlots = item.bagSlots or 0
				-- A mochila é vestida, e só se veste uma.
				if entry.count ~= 1 then
					table.insert(errors, `Kit "{key}": mochila "{entry.id}" deve ter count 1`)
				end
			else
				totals[entry.id] = (totals[entry.id] or 0) + entry.count
			end
		end
		if bags > 1 then
			table.insert(errors, `Kit "{key}": no máximo uma mochila por kit (há {bags})`)
		end

		-- O kit é dado logo depois de nascer, num inventário novo e vazio: tem
		-- que caber nos slots base + os da mochila do próprio kit (sem contar o
		-- gamepass, que nem todo jogador tem). Senão os itens sobrariam e sumiriam.
		if allValid and bags <= 1 then
			local slotsNeeded = 0
			for id, total in totals do
				slotsNeeded += math.ceil(total / defs.Items[id].maxStack)
			end
			local capacity = InventoryConfig.BASE_SLOTS + bagSlots
			if slotsNeeded > capacity then
				table.insert(
					errors,
					`Kit "{key}": não cabe num inventário novo (precisa de {slotsNeeded} slots, há {capacity})`
				)
			end
		end
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
	validateStats(errors, defs, hasString)
	validateSettings(errors, defs, hasString)
	validateKits(errors, defs, hasString)

	table.sort(errors)
	return errors
end

return Validate
