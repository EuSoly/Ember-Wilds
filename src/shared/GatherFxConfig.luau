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
	-- Cavar com a pá (DigRules): terra da floresta e areia das margens.
	ground = table.freeze({ color = Palette.biome.forest[3] }),
	sand = table.freeze({ color = Palette.biome.ocean[1] }),
	-- Regar com o regador (FarmService): gotas da cor da sede.
	water = table.freeze({ color = Palette.status.thirst }),
}) :: { [string]: MaterialFx }
