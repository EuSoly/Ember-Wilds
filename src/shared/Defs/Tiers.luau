--!strict
-- Tiers de material (madeira → reidite, esmeralda como ramo lateral).
-- A cor vem da Palette, para existir um lugar só para trocar cores.
local Palette = require("../Palette")
local Types = require("./Types")

type TierDef = Types.TierDef

local function tier(id: string, order: number, rarityKey: string): TierDef
	return table.freeze({
		id = id,
		order = order,
		color = (Palette.tier :: any)[id],
		rarityKey = rarityKey,
		nameKey = "tier." .. id,
	})
end

local Tiers: { [string]: TierDef } = {
	wood = tier("wood", 1, "rarity.common"),
	stone = tier("stone", 2, "rarity.uncommon"),
	gold = tier("gold", 3, "rarity.rare"),
	diamond = tier("diamond", 4, "rarity.epic"),
	amethyst = tier("amethyst", 5, "rarity.mythic"),
	reidite = tier("reidite", 6, "rarity.legendary"),
	emerald = tier("emerald", 0, "rarity.legendary"),
}

return table.freeze(Tiers)
