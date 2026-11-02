--!strict
-- Mobs (animais e monstros). Mob novo = uma entrada aqui + o texto "mob.<id>"
-- em Strings/ptBR.luau + o modelo com juntas em ReplicatedStorage.Assets.Mobs
-- + a animação em Mobs/MobAnimConfig (veja docs/guia/mobs-modelos.md).
-- behavior: wiki de fãs do Starve.io (starveiopro.fandom.com/wiki/Mobs),
-- pesquisado em 01/11. As aves douradas não estão lá: passivas (decisão do
-- Elizeu).
local Types = require("./Types")

type MobDef = Types.MobDef

-- extra: stats, population e mountFlies (só os mobs que já têm IA).
local function mob(id: string, behavior: Types.MobBehavior, extra: { [string]: any }?): MobDef
	local def: any = { id = id, nameKey = "mob." .. id, behavior = behavior }
	if extra then
		for key, value in extra do
			def[key] = value
		end
	end
	return table.freeze(def)
end

return table.freeze({
	rabbit = mob("rabbit", "passive", {
		stats = { health = 60, speed = 15, radius = 1.8, points = 20 },
		population = { forest = { day = 40, night = 15 } },
	}),
	penguin = mob("penguin", "passive"),
	golden_hen = mob("golden_hen", "passive"),
	golden_chick = mob("golden_chick", "passive"),
	hawk = mob("hawk", "neutral", {
		stats = { health = 300, bite = 24, speed = 18, radius = 2.2, points = 60, flies = true },
		population = { forest = { day = 6, night = 6 } },
		mountFlies = true,
	}),
	boar = mob("boar", "neutral", {
		stats = { health = 400, bite = 25, speed = 15, radius = 2.2, points = 80 },
		population = { forest = { day = 8, night = 8 } },
		mountFlies = true,
	}),
	crab = mob("crab", "neutral"),
	king_crab = mob("king_crab", "neutral"),
	baby_mammoth = mob("baby_mammoth", "neutral"),
	baby_dragon = mob("baby_dragon", "neutral", { mountFlies = true }),
	baby_lava_dragon = mob("baby_lava_dragon", "neutral", { mountFlies = true }),
	wolf = mob("wolf", "aggressive", {
		stats = { health = 300, bite = 24, speed = 14, radius = 2, points = 60 },
		population = { forest = { day = 10, night = 20 } },
	}),
	spider = mob("spider", "aggressive", {
		stats = {
			health = 120,
			bite = 16,
			speed = 20,
			radius = 2.2,
			points = 40,
			web = { duration = 2, cooldown = 6 },
		},
		population = { forest = { day = 8, night = 16 } },
	}),
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
