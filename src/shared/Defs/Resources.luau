--!strict
-- Recursos do mundo, espalhados pelo mapa (World/Scatter) e montados pelo
-- MapService com o ResourceModels. Recurso novo = uma entrada aqui + o texto
-- "resource.<id>" em Strings/ptBR.luau + o modelo no Studio
-- (ServerStorage.Assets.Resources/<id>_1).
-- radius: espaço que ocupa (nenhum outro recurso nasce dentro dele).
-- collisionRadius: raio da única peça sólida (tronco/base); o espalhador deixa
-- WorldConfig.MIN_PASSAGE studs livres entre duas peças sólidas.
-- Os campos de coleta (item, quantidade, ferramenta, renascer) entram na fase
-- de coleta. Valores provisórios: o Elizeu ajusta.
local Types = require("./Types")

type ResourceDef = Types.ResourceDef

type Options = {
	size: number?,
	sizeAxis: ("width" | "height")?,
	sizeJitter: number?,
	sink: number?,
	decorative: boolean?,
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
	})
end

-- Os modelos ficam no Studio, em ServerStorage.Assets.Resources, com o nome
-- "<id>_<variação>" (ex. tree_2); sem modelo, entra o provisório feito por
-- código (Models/ResourceModels). Ver docs/guia/mapa.md.
local Resources: { [string]: ResourceDef } = {
	-- Árvores medidas pela altura (~14): a câmera fica a ~30 studs, mais alto
	-- que isso as copas cobrem a tela.
	tree = resource("tree", 5, 1.4, 3, { size = 14, sizeAxis = "height", sizeJitter = 0.15 }),
	rock = resource("rock", 5, 3.8, 3, { size = 9, sizeJitter = 0.15 }),
	gold_vein = resource("gold_vein", 5, 3.8, 1, { size = 9, sizeJitter = 0.15 }),
	berry_bush = resource("berry_bush", 4, 2.8, 1, { size = 7, sizeJitter = 0.15 }),
	-- Pedras do chão: só enfeite, metade enterradas, espalhadas junto com os recursos.
	pebble = resource("pebble", 1.5, 0.4, 10, { size = 1.8, sizeJitter = 0.4, sink = 0.5, decorative = true }),
}

return table.freeze(Resources)
