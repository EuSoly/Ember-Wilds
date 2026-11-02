--!strict
-- Slots de cosmético (onde uma skin se aplica). Por enquanto só o corpo;
-- depois entram "tool", "armor"... Cada slot diz qual cosmético é o padrão.
local Types = require("./Types")

type CosmeticSlotDef = Types.CosmeticSlotDef

local CosmeticSlots: { [string]: CosmeticSlotDef } = {
	body = { id = "body", nameKey = "cosmeticSlot.body", default = "body_default" },
	crate = { id = "crate", nameKey = "cosmeticSlot.crate", default = "crate_default" },
}

for _, slot in CosmeticSlots do
	table.freeze(slot)
end

return table.freeze(CosmeticSlots)
