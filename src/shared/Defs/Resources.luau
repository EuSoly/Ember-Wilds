--!strict
-- Recursos do mundo, espalhados pelo mapa (World/Scatter) e montados pelo
-- MapService com o ResourceModels. Recurso novo = uma entrada aqui + o texto
-- "resource.<id>" em Strings/ptBR.luau + o modelo no Studio
-- (ServerStorage.Assets.Resources/<id>_1).
-- radius: espaço que ocupa (nenhum outro recurso nasce dentro dele).
-- collisionRadius: raio da única peça sólida (tronco/base); o espalhador deixa
-- WorldConfig.MIN_PASSAGE studs livres entre duas peças sólidas.
-- gather: o que o golpe dá, a ferramenta (dureza), a reserva e a regeneração
-- (G2; números do Starve.io, veja docs/guia/coleta.md).
local Types = require("./Types")

type ResourceDef = Types.ResourceDef

type Options = {
	size: number?,
	sizeAxis: ("width" | "height")?,
	sizeJitter: number?,
	sink: number?,
	decorative: boolean?,
	gather: Types.GatherDef?,
}

local function resource(
	id: string,
	radius: number,
	collisionRadius: number,
	variants: number,
	options: Options?
): ResourceDef
	local o: Options = options or {}
	return table.freeze({
		id = id,
		nameKey = "resource." .. id,
		radius = radius,
		collisionRadius = collisionRadius,
		variants = variants,
		size = o.size,
		sizeAxis = o.sizeAxis,
		sizeJitter = o.sizeJitter,
		sink = o.sink,
		decorative = o.decorative,
		gather = o.gather,
	})
end

-- Bloco de coleta (congelado, com as tabelas de dentro).
local function gather(g: Types.GatherDef): Types.GatherDef
	table.freeze(g.amount)
	table.freeze(g.regen)
	return table.freeze(g)
end

-- Os modelos ficam no Studio, em ServerStorage.Assets.Resources, com o nome
-- "<id>_<variação>" (ex. tree_2); sem modelo, entra o provisório feito por
-- código (Models/ResourceModels). Ver docs/guia/mapa.md.
local Resources: { [string]: ResourceDef } = {
	-- Árvores medidas pela altura (~14): a câmera fica a ~30 studs, mais alto
	-- que isso as copas cobrem a tela.
	-- Reserva de 20 (a menor) a 80 (a maior), como os carvalhos do Starve.
	tree = resource("tree", 5, 1.4, 3, {
		size = 14,
		sizeAxis = "height",
		sizeJitter = 0.15,
		gather = gather({
			item = "wood",
			points = 1,
			material = "wood",
			hardness = 0,
			amount = { min = 20, max = 80 },
			regen = { amount = 2, every = 10 },
		}),
	}),
	rock = resource("rock", 5, 3.8, 1, {
		size = 9,
		sizeJitter = 0.15,
		gather = gather({
			item = "stone",
			points = 2,
			material = "stone",
			hardness = 1,
			amount = { min = 40, max = 40 },
			regen = { amount = 2, every = 10 },
		}),
	}),
	gold_vein = resource("gold_vein", 5, 3.8, 1, {
		size = 9,
		sizeJitter = 0.15,
		gather = gather({
			item = "gold",
			points = 3,
			material = "gold",
			hardness = 2,
			amount = { min = 20, max = 20 },
			regen = { amount = 1, every = 10 },
		}),
	}),
	-- 7 frutinhas: uma por bolinha Berry do modelo (o arbusto mostra quantas tem).
	berry_bush = resource("berry_bush", 4, 2.8, 1, {
		size = 7,
		sizeJitter = 0.15,
		gather = gather({
			item = "berry",
			points = 2,
			material = "leaves",
			fixedYield = 1,
			amount = { min = 7, max = 7 },
			regen = { amount = 1, every = 10 },
		}),
	}),
	-- Pedras do chão: só enfeite, metade enterradas, espalhadas junto com os recursos.
	pebble = resource("pebble", 1.5, 0.4, 10, { size = 1.8, sizeJitter = 0.4, sink = 0.5, decorative = true }),
	-- Flores e folhas caídas: só enfeite (vida no chão), sem colisão.
	flower = resource("flower", 1.2, 0.3, 4, { size = 1.6, sizeJitter = 0.3, decorative = true }),
	leaves = resource("leaves", 2, 0.3, 3, { size = 3, sizeJitter = 0.3, decorative = true }),
}

return table.freeze(Resources)
