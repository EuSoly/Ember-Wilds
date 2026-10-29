--!strict
local Lifecycle = require("../src/shared/Lifecycle")

return {
	["init all before start"] = function()
		local log = {}
		local function system(name: string)
			return {
				Name = name,
				Init = function()
					table.insert(log, name .. ".Init")
				end,
				Start = function()
					table.insert(log, name .. ".Start")
				end,
			}
		end

		Lifecycle.run({ system("A"), system("B") })

		local expected = { "A.Init", "B.Init", "A.Start", "B.Start" }
		assert(#log == #expected, `esperava {#expected} chamadas, veio {#log}`)
		for i, entry in expected do
			assert(log[i] == entry, `posição {i}: esperava {entry}, veio {log[i]}`)
		end
	end,

	["optional phases"] = function()
		local started = false
		Lifecycle.run({
			{
				Name = "OnlyStart",
				Start = function()
					started = true
				end,
			},
			{ Name = "OnlyInit", Init = function() end },
		})
		assert(started, "Start do sistema sem Init não rodou")
	end,

	["error names the system"] = function()
		local ok, err = pcall(Lifecycle.run, {
			{
				Name = "Bad",
				Init = function()
					error("boom")
				end,
			},
		})
		assert(not ok, "deveria ter falhado")
		local message = tostring(err)
		assert(string.find(message, "Init falhou em Bad", 1, true), `mensagem sem o nome do sistema: {message}`)
		assert(string.find(message, "boom", 1, true), `mensagem sem o erro original: {message}`)
	end,
}
