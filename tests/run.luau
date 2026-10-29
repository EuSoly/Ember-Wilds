--!strict
-- Runner de testes para o Lune: encontra todo `*.spec.luau` dentro de tests/,
-- roda cada função com pcall e sai com código 1 se algo falhar.
-- Uso (na raiz do repo): lune run tests/run
local fs = require("@lune/fs")
local process = require("@lune/process")

type Spec = { [string]: () -> () }

-- Lista os specs relativos à pasta tests/, em ordem alfabética.
local function collectSpecs(dir: string, prefix: string, out: { string })
	local entries = fs.readDir(dir)
	table.sort(entries)
	for _, name in entries do
		local full = dir .. "/" .. name
		if fs.isDir(full) then
			collectSpecs(full, prefix .. name .. "/", out)
		elseif string.match(name, "%.spec%.luau$") then
			table.insert(out, prefix .. string.gsub(name, "%.luau$", ""))
		end
	end
end

local specs: { string } = {}
collectSpecs("tests", "", specs)

local passed, failed = 0, 0
for _, specPath in specs do
	local ok, specOrErr = pcall(require, "./" .. specPath)
	if not ok then
		failed += 1
		print(`FAIL {specPath}: não carregou: {specOrErr}`)
		continue
	end

	local spec = specOrErr :: Spec
	local names = {}
	for name in spec do
		table.insert(names, name)
	end
	table.sort(names)

	for _, name in names do
		local testOk, err = pcall(spec[name])
		if testOk then
			passed += 1
			print(`PASS {specPath} > {name}`)
		else
			failed += 1
			print(`FAIL {specPath} > {name}: {err}`)
		end
	end
end

print(`{passed} passed, {failed} failed`)
process.exit(if failed > 0 then 1 else 0)
