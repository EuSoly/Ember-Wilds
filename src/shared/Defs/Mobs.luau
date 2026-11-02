--!strict
-- Mobs (animais e monstros). Mob novo = uma entrada aqui + o texto "mob.<id>"
-- em Strings/ptBR.luau + o modelo com juntas em ReplicatedStorage.Assets.Mobs
-- + a animação em Mobs/MobAnimConfig (veja docs/guia/mobs-modelos.md).
-- behavior: wiki de fãs do Starve.io (starveiopro.fandom.com/wiki/Mobs),
-- pesquisado em 01/11. As aves douradas não estão lá: passivas (decisão do
-- Elizeu).
local Types = require("./Types")

type MobDef = Types.MobDef

local function mob(id: string, behavior: Types.MobBehavior): MobDef
	return table.freeze({ id = id, nameKey = "mob." .. id, behavior = behavior })
end

return table.freeze({
	rabbit = mob("rabbit", "passive"),
	penguin = mob("penguin", "passive"),
	golden_hen = mob("golden_hen", "passive"),
	golden_chick = mob("golden_chick", "passive"),
	hawk = mob("hawk", "neutral"),
	boar = mob("boar", "neutral"),
	crab = mob("crab", "neutral"),
	king_crab = mob("king_crab", "neutral"),
	baby_mammoth = mob("baby_mammoth", "neutral"),
	baby_dragon = mob("baby_dragon", "neutral"),
	baby_lava_dragon = mob("baby_lava_dragon", "neutral"),
	wolf = mob("wolf", "aggressive"),
	spider = mob("spider", "aggressive"),
	arctic_fox = mob("arctic_fox", "aggressive"),
	polar_bear = mob("polar_bear", "aggressive"),
	mammoth = mob("mammoth", "aggressive"),
	dragon = mob("dragon", "aggressive"),
	gmo_piranha = mob("gmo_piranha", "aggressive"),
	kraken = mob("kraken", "aggressive"),
	lava_monster = mob("lava_monster", "aggressive"),
	lava_dragon = mob("lava_dragon", "aggressive"),
	vulture = mob("vulture", "aggressive"),
	sandworm = mob("sandworm", "aggressive"),
}) :: { [string]: MobDef }
