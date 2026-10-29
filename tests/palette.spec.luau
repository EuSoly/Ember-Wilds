--!strict
local Palette = require("../src/shared/Palette")

local HEX = "^#%x%x%x%x%x%x$"

local function assertAllHex(group: { [any]: any }, label: string)
	for key, value in group do
		if type(value) == "table" then
			assertAllHex(value, `{label}.{key}`)
		else
			assert(type(value) == "string" and string.match(value, HEX), `{label}.{key} não é hex: {value}`)
		end
	end
end

return {
	["every color is #RRGGBB"] = function()
		assertAllHex(Palette.ui, "ui")
		assertAllHex(Palette.tier, "tier")
		assertAllHex(Palette.status, "status")
		assertAllHex(Palette.biome, "biome")
		assert(string.match(Palette.neutralFrame, HEX), "neutralFrame não é hex")
	end,

	["tier colors match the identity"] = function()
		assert(Palette.tier.gold == "#F2B632", `ouro: {Palette.tier.gold}`)
		assert(Palette.tier.wood == "#8B5A2B", `madeira: {Palette.tier.wood}`)
		assert(Palette.biome.forest[1] == "#6FBF4A", `floresta: {Palette.biome.forest[1]}`)
		assert(#Palette.biome.nightFire == 4, "noite e fogo deveria ter 4 cores")
	end,

	["palette is frozen"] = function()
		local ok = pcall(function()
			(Palette.ui :: any).text = "#000000"
		end)
		assert(not ok, "Palette.ui deveria estar congelada")
	end,
}
