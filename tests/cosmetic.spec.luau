--!strict
local Cosmetic = require("../src/shared/Cosmetic")
local Defs = require("../src/shared/Defs")

return {
	["known id returns that cosmetic"] = function()
		local def = Cosmetic.resolve(Defs, "body", "body_ember")
		assert(def.id == "body_ember", `esperava body_ember, veio {def.id}`)
	end,

	["nil id returns the slot default"] = function()
		local def = Cosmetic.resolve(Defs, "body", nil)
		assert(def.id == "body_default", `esperava body_default, veio {def.id}`)
	end,

	["unknown id falls back to the default"] = function()
		-- O warn aparece no output; é esperado.
		local def = Cosmetic.resolve(Defs, "body", "removed_skin")
		assert(def.id == "body_default", `esperava body_default, veio {def.id}`)
	end,

	["unknown slot errors"] = function()
		local ok = pcall(Cosmetic.resolve, Defs, "hat", nil)
		assert(not ok, "slot inexistente deveria dar erro")
	end,
}
