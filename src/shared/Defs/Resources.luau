--!strict
-- Recursos do mundo, espalhados pelo mapa (World/Scatter) e montados pelo
-- MapService com o ResourceModels. Recurso novo = uma entrada aqui + o texto
-- "resource.<id>" em Strings/ptBR.luau + o modelo em Models/ResourceModels.
-- radius: espaço que ocupa (nenhum outro recurso nasce dentro dele).
-- collisionRadius: raio da única peça sólida (tronco/base); o espalhador deixa
-- WorldConfig.MIN_PASSAGE studs livres entre duas peças sólidas.
-- Os campos de coleta (item, quantidade, ferramenta, renascer) entram na fase
-- de coleta. Valores provisórios: o Elizeu ajusta.
local Types = require("./Types")

type ResourceDef = Types.ResourceDef

local function resource(id: string, radius: number, collisionRadius: number, variants: number): ResourceDef
	return table.freeze({
		id = id,
		nameKey = "resource." .. id,
		radius = radius,
		collisionRadius = collisionRadius,
		variants = variants,
	})
end

local Resources: { [string]: ResourceDef } = {
	tree = resource("tree", 5, 1.2, 3),
	rock = resource("rock", 4, 2.6, 3),
	gold_vein = resource("gold_vein", 4, 2.6, 2),
	berry_bush = resource("berry_bush", 3, 1.8, 2),
}

return table.freeze(Resources)
