--!strict
-- Como o kit chega ao jogador sem pagar (KitRules.access): comprado, liberado
-- pelo VIP/Premium, trancado (só VIP) ou comum.
local Defs = require("../src/shared/Defs")
local KitChoice = require("../src/shared/UIFlow/KitChoice")
local KitRules = require("../src/shared/UIFlow/KitRules")
local Perks = require("../src/shared/Shop/Perks")

local function perks(vip: boolean, premium: boolean): Perks.PerkSet
	return { vip = vip, ember2x = false, book = false, premium = premium }
end

local function access(kitId: string, owned: boolean, set: Perks.PerkSet): KitRules.Access
	return KitRules.access(Defs.Kits[kitId], owned, Perks.unlockedKits(set, Defs.Kits))
end

return {
	["kit vip is locked for non-vip"] = function()
		assert(access("kit_vip", false, perks(false, false)) == "locked", "falhou")
		assert(access("kit_vip", false, perks(false, true)) == "locked", "Premium não libera o Kit VIP")
	end,

	["kit vip is usable by vip"] = function()
		assert(access("kit_vip", false, perks(true, false)) == "vip", "falhou")
	end,

	["kit starter is premium-unlocked"] = function()
		assert(access("kit_starter", false, perks(false, true)) == "premium", "falhou")
		assert(access("kit_starter", false, perks(false, false)) == "none", "falhou")
	end,

	["owned wins over perks"] = function()
		assert(access("kit_vip", true, perks(true, false)) == "owned", "falhou")
		assert(access("kit_starter", true, perks(false, true)) == "owned", "falhou")
	end,

	["plain kits are none"] = function()
		assert(access("kit_explorer", false, perks(true, true)) == "none", "falhou")
	end,

	["vip kit is shown to everyone, other exclusives only when owned"] = function()
		assert(KitRules.shows(Defs.Kits.kit_vip, false), "falhou")
		assert(not KitRules.shows(Defs.Kits.kit_hunter, false), "falhou")
		assert(KitRules.shows(Defs.Kits.kit_hunter, true), "falhou")
	end,

	["perk kit resolves as permanent once unlocked, not otherwise"] = function()
		local unlocked = Perks.unlockedKits(perks(true, false), Defs.Kits)
		local state = { points = 0, balance = {}, owned = unlocked, active = nil }
		local kit, source = KitChoice.resolve({ kitId = "kit_vip", source = "permanent" }, state, Defs.Kits)
		assert(kit == "kit_vip" and source == "permanent", "kit == kit_vip and source == permanent")
		state.owned = {}
		kit, source = KitChoice.resolve({ kitId = "kit_vip", source = "permanent" }, state, Defs.Kits)
		assert(kit == nil and source == nil, "kit == nil and source == nil")
	end,
}
