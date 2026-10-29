--!strict
-- Regras das estatísticas permanentes (puras, testadas no Lune). O
-- StatsService chama daqui e avisa as conquistas quando um valor muda.
local DataConfig = require("./DataConfig")
local Types = require("../Defs/Types")

type StatDef = Types.StatDef

local KEY_PATTERN = "^[a-z0-9_]+$"

local StatsRules = {}

local function isFinite(value: any): boolean
	return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

-- Chave de estatística keyed (id de mob/item): snake_case, até STAT_KEY_MAX_LENGTH.
function StatsRules.isValidKey(key: string): boolean
	return type(key) == "string" and #key <= DataConfig.STAT_KEY_MAX_LENGTH and string.match(key, KEY_PATTERN) ~= nil
end

-- Soma em counter/keyed. Devolve o novo valor (o da chave, no keyed) ou nil se
-- inválido (nesse caso nada muda).
function StatsRules.add(stats: { [string]: any }, def: StatDef, amount: number, key: string?): number?
	-- amount pode ser fracionário (ex. segundos de jogo), mas sempre > 0.
	if not isFinite(amount) or amount <= 0 then
		return nil
	end
	if def.kind == "counter" then
		if key ~= nil then
			return nil
		end
		local value = (if type(stats[def.id]) == "number" then stats[def.id] else 0) + amount
		stats[def.id] = value
		return value
	elseif def.kind == "keyed" then
		if key == nil or not StatsRules.isValidKey(key) then
			return nil
		end
		-- A tabela nasce na primeira soma: é isso que deixa estatística nova
		-- dispensar migração do perfil.
		local perKey = stats[def.id]
		if type(perKey) ~= "table" then
			perKey = {}
			stats[def.id] = perKey
		end
		local value = (if type(perKey[key]) == "number" then perKey[key] else 0) + amount
		perKey[key] = value
		return value
	end
	return nil
end

-- Registra em "max": guarda o maior valor. Devolve (valor guardado, mudou?) ou
-- (nil, false) se inválido.
function StatsRules.record(stats: { [string]: any }, def: StatDef, value: number): (number?, boolean)
	if def.kind ~= "max" or not isFinite(value) or value < 0 then
		return nil, false
	end
	local current = if type(stats[def.id]) == "number" then stats[def.id] else 0
	if value > current then
		stats[def.id] = value
		return value, true
	end
	return current, false
end

-- Valor atual (0 se ainda não existe).
function StatsRules.get(stats: { [string]: any }, def: StatDef, key: string?): number
	local stored = stats[def.id]
	if def.kind == "keyed" then
		if key == nil or type(stored) ~= "table" then
			return 0
		end
		local value = stored[key]
		return if type(value) == "number" then value else 0
	end
	return if type(stored) == "number" then stored else 0
end

return StatsRules
