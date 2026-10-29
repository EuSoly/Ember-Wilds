--!strict
-- Migrações do perfil salvo (puras, testadas no Lune). Rodam antes do
-- Reconcile() do ProfileStore. Para mudar o formato do perfil: suba
-- DataConfig.SCHEMA_VERSION e adicione STEPS[versãoAntiga] aqui.
-- Estatística ou configuração nova NÃO precisa de migração (o Reconcile e o
-- StatsRules criam o campo sozinhos).

export type Step = (data: { [string]: any }) -> ()

local Migrations = {}

-- STEPS[n] leva da versão n para n+1. Vazio na v1.
-- Exemplo (v1 → v2):
--   [1] = function(data) data.Pets = { Owned = {} } end,
Migrations.STEPS = table.freeze({}) :: { [number]: Step }

local function deepCopy(value: any): any
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for key, inner in value do
		copy[key] = deepCopy(inner)
	end
	return copy
end

-- Leva `data` até `target`. Em qualquer falha devolve (false, motivo) e os
-- dados ficam como estavam: os passos rodam numa cópia, que só é copiada de
-- volta no fim. "newer" = perfil salvo por uma versão mais nova do jogo.
function Migrations.run(data: { [string]: any }, steps: { [number]: Step }, target: number): (boolean, string?)
	local version = data.SchemaVersion
	if version == nil then
		-- Perfil novo: já nasce no formato atual (template).
		data.SchemaVersion = target
		return true, nil
	end
	if type(version) ~= "number" then
		return false, "SchemaVersion inválida"
	end
	if version > target then
		return false, "newer"
	end
	if version == target then
		return true, nil
	end

	local work = deepCopy(data)
	for v = version, target - 1 do
		local step = steps[v]
		if step == nil then
			return false, `sem migração de v{v}`
		end
		step(work)
		work.SchemaVersion = v + 1
	end

	-- Copia o resultado de volta na mesma tabela (o ProfileStore guarda a referência).
	for key in data do
		if work[key] == nil then
			data[key] = nil
		end
	end
	for key, value in work do
		data[key] = value
	end
	return true, nil
end

return Migrations
