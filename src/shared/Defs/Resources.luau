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

type Options = { size: number?, sizeJitter: number?, decorative: boolean? }

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
		sizeJitter = o.sizeJitter,
		decorative = o.decorative,
	})
end

-- Os modelos ficam no Studio, em ServerStorage.Assets.Resources, com o nome
-- "<id>_<variação>" (ex. tree_2); sem modelo, entra o provisório feito por
-- código (Models/ResourceModels). Ver docs/guia/mapa.md.
local Resources: { [string]: ResourceDef } = {
	tree = resource("tree", 5, 1.2, 3, { size = 9, sizeJitter = 0.15 }),
	rock = resource("rock", 4, 2.6, 3, { size = 7, sizeJitter = 0.15 }),
	gold_vein = resource("gold_vein", 4, 2.6, 1, { size = 7, sizeJitter = 0.15 }),
	berry_bush = resource("berry_bush", 3, 1.8, 1, { size = 5, sizeJitter = 0.15 }),
	-- Pedras do chão: só enfeite, espalhadas junto com os recursos.
	pebble = resource("pebble", 1.5, 0.4, 10, { size = 1.8, sizeJitter = 0.4, decorative = true }),
}

return table.freeze(Resources)
