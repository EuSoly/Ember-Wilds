--!strict
-- Os bootstraps precisam carregar as Defs antes de iniciar os sistemas, para que
-- um erro nas definições derrube o jogo no boot (e não no meio da partida).
-- O teste lê o código-fonte porque os bootstraps só rodam dentro do Roblox.
local fs = require("@lune/fs")

local function assertLoadsDefsBeforeLifecycle(path: string)
	local source = fs.readFile(path)
	local defsAt = string.find(source, 'require%(.-Defs"?%)?%)')
	local runAt = string.find(source, "Lifecycle.run", 1, true)
	assert(defsAt ~= nil, `{path} não carrega Shared.Defs`)
	assert(runAt ~= nil, `{path} não chama Lifecycle.run`)
	assert((defsAt :: number) < (runAt :: number), `{path} carrega Defs depois de Lifecycle.run`)
end

return {
	["server bootstrap loads Defs before systems"] = function()
		assertLoadsDefsBeforeLifecycle("src/server/init.server.luau")
	end,

	["client bootstrap loads Defs before systems"] = function()
		assertLoadsDefsBeforeLifecycle("src/client/init.client.luau")
	end,
}
