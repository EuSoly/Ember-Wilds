--!strict
local Defs = require("../src/shared/Defs")
local Migrations = require("../src/shared/Data/Migrations")
local ProfileTemplate = require("../src/shared/Data/ProfileTemplate")

-- Passos falsos: v1→v2 adiciona Pets, v2→v3 adiciona Titles.
local function fakeSteps(): { [number]: Migrations.Step }
	return {
		[1] = function(data)
			data.Pets = { Owned = {} }
		end,
		[2] = function(data)
			data.Titles = {}
		end,
	}
end

-- Comparação profunda simples (só tabelas de dados).
local function deepEqual(a: any, b: any): boolean
	if type(a) ~= "table" or type(b) ~= "table" then
		return a == b
	end
	for key, value in a do
		if not deepEqual(value, b[key]) then
			return false
		end
	end
	for key in b do
		if a[key] == nil then
			return false
		end
	end
	return true
end

return {
	["old data migrates to the target"] = function()
		local data: { [string]: any } = { SchemaVersion = 1, Currency = { Balance = 7 } }
		local ok, err = Migrations.run(data, fakeSteps(), 3)
		assert(ok == true, `falhou: {err}`)
		assert(data.SchemaVersion == 3, `versão {data.SchemaVersion}`)
		assert(type(data.Pets) == "table" and type(data.Titles) == "table", "campos novos")
		assert(data.Currency.Balance == 7, "dados antigos preservados")
	end,

	["current data is unchanged"] = function()
		local data: { [string]: any } = { SchemaVersion = 3, Currency = { Balance = 7 } }
		local ok = Migrations.run(data, fakeSteps(), 3)
		assert(ok == true, "deveria passar")
		assert(deepEqual(data, { SchemaVersion = 3, Currency = { Balance = 7 } }), "dados mudaram")
	end,

	["newer data is refused and untouched"] = function()
		local data: { [string]: any } = { SchemaVersion = 5, Currency = { Balance = 7 } }
		local ok, err = Migrations.run(data, fakeSteps(), 3)
		assert(ok == false and err == "newer", `esperava newer, veio {err}`)
		assert(deepEqual(data, { SchemaVersion = 5, Currency = { Balance = 7 } }), "dados mudaram")
	end,

	["missing step fails and keeps data"] = function()
		local steps = fakeSteps()
		steps[2] = nil
		local data: { [string]: any } = { SchemaVersion = 1, Currency = { Balance = 7 } }
		local ok, err = Migrations.run(data, steps, 3)
		assert(ok == false, "deveria falhar")
		assert(err == "sem migração de v2", `mensagem {err}`)
		assert(deepEqual(data, { SchemaVersion = 1, Currency = { Balance = 7 } }), "dados mudaram")
	end,

	["new profile without version is ok"] = function()
		local data: { [string]: any } = {}
		local ok = Migrations.run(data, fakeSteps(), 3)
		assert(ok == true, "perfil novo deveria passar")
		assert(data.Pets == nil, "perfil novo não roda migrações")
	end,

	["real steps are empty on v1"] = function()
		assert(next(Migrations.STEPS) == nil, "v1 não tem migração")
	end,

	["template has the v1 schema"] = function()
		local template = ProfileTemplate.build(Defs)
		assert(template.SchemaVersion == 1, `versão {template.SchemaVersion}`)
		assert(template.Settings.music_volume == 0.8, "música padrão")
		assert(template.Currency.Balance == 0, "saldo inicial")
		assert(type(template.Cosmetics.Owned) == "table", "cosméticos possuídos")
		assert(type(template.Stats) == "table", "estatísticas")
		assert(type(template.PurchaseIdCache) == "table", "cache de compras")
	end,

	["template is a new table each call"] = function()
		local a = ProfileTemplate.build(Defs)
		local b = ProfileTemplate.build(Defs)
		assert(a ~= b, "tabelas iguais")
		assert(a.Currency ~= b.Currency and a.Settings ~= b.Settings, "subtabelas compartilhadas")
	end,
}
