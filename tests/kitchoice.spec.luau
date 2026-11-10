--!strict
local Defs = require("../src/shared/Defs")
local KitChoice = require("../src/shared/UIFlow/KitChoice")

type State = KitChoice.State

local function state(changes: { [string]: any }?): State
	local base: { [string]: any } = { points = 0, balance = {}, owned = {}, active = nil }
	for key, value in changes or {} do
		base[key] = value
	end
	return base :: any
end

local EXPLORER_PRICE = Defs.Kits.kit_explorer.price

return {
	["points kit with enough points"] = function()
		local kit, source = KitChoice.resolve(
			{ kitId = "kit_explorer", source = "points" },
			state({ points = EXPLORER_PRICE }),
			Defs.Kits
		)
		assert(kit == "kit_explorer" and source == "points", `{kit} {source}`)
	end,

	["points kit without points falls back to the active kit, not the balance"] = function()
		local kit, source = KitChoice.resolve(
			{ kitId = "kit_explorer", source = "points" },
			state({
				points = EXPLORER_PRICE - 1,
				balance = { kit_explorer = 2 },
				owned = { kit_veteran = true },
				active = "kit_veteran",
			}),
			Defs.Kits
		)
		assert(kit == "kit_veteran" and source == "permanent", `{kit} {source}`)
	end,

	["balance kit with balance"] = function()
		local kit, source = KitChoice.resolve(
			{ kitId = "kit_survivor", source = "balance" },
			state({ balance = { kit_survivor = 2 } }),
			Defs.Kits
		)
		assert(kit == "kit_survivor" and source == "balance", `{kit} {source}`)
	end,

	["balance kit without balance falls back to the active kit"] = function()
		local kit, source = KitChoice.resolve(
			{ kitId = "kit_survivor", source = "balance" },
			state({ owned = { kit_starter = true }, active = "kit_starter" }),
			Defs.Kits
		)
		assert(kit == "kit_starter" and source == "permanent", `{kit} {source}`)
	end,

	["no choice uses the active permanent kit"] = function()
		local kit, source =
			KitChoice.resolve({}, state({ owned = { kit_veteran = true }, active = "kit_veteran" }), Defs.Kits)
		assert(kit == "kit_veteran" and source == "permanent", `{kit} {source}`)
	end,

	["active kit not owned gives nothing"] = function()
		local kit, source = KitChoice.resolve({}, state({ active = "kit_veteran" }), Defs.Kits)
		assert(kit == nil and source == nil, `{kit} {source}`)
	end,

	["unknown kit in the request is ignored"] = function()
		local kit, source = KitChoice.resolve(
			{ kitId = "kit_nada", source = "balance" },
			state({ balance = { kit_nada = 5 } }),
			Defs.Kits
		)
		assert(kit == nil and source == nil, `{kit} {source}`)
	end,

	["auto prefers points, then balance"] = function()
		assert(KitChoice.auto("kit_explorer", EXPLORER_PRICE, {}, Defs.Kits) == "points", "pontos primeiro")
		assert(
			KitChoice.auto("kit_explorer", EXPLORER_PRICE, { kit_explorer = 1 }, Defs.Kits) == "points",
			"com pontos, não gasta o saldo"
		)
		assert(KitChoice.auto("kit_explorer", 0, { kit_explorer = 1 }, Defs.Kits) == "balance", "sem pontos, saldo")
		assert(KitChoice.auto("kit_explorer", 0, {}, Defs.Kits) == nil, "sem pontos nem saldo")
	end,
}
