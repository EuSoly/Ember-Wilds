--!strict
-- Efeitos visuais de cada material da coleta (GatherDef.material): a cor das
-- lasquinhas. O som do golpe de cada material fica com os outros sons, em
-- Audio/SoundConfig (hit_wood, hit_stone, hit_gold, hit_leaves...).
local Palette = require("./Palette")

export type MaterialFx = { color: string }

return table.freeze({
	wood = table.freeze({ color = Palette.tier.wood }),
	stone = table.freeze({ color = Palette.tier.stone }),
	gold = table.freeze({ color = Palette.tier.gold }),
	leaves = table.freeze({ color = Palette.biome.forest[1] }),
}) :: { [string]: MaterialFx }
