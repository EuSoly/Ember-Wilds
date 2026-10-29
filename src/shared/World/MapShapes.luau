--!strict
-- Converte as peças desenhadas no Studio (Workspace.Map/Water, NoSpawn, Zones)
-- nas formas puras do Shapes. Formas aceitas, vistas de cima:
-- - Part com Shape = Block, girada só em volta do eixo vertical → caixa;
-- - Part com Shape = Cylinder deitado com o eixo na vertical (moeda) → disco,
--   com diâmetro = o menor entre Size.Y e Size.Z.
-- Qualquer outra coisa (inclinada, cunha, bola, união, MeshPart) devolve
-- (nil, motivo) para o MapService avisar no Output e ignorar a peça.
-- (Só roda no Roblox: lê instâncias.)
local Shapes = require("./Shapes")

local MapShapes = {}

-- Tolerância para "em pé": cosseno de ~2,5°, para um giro feito à mão no
-- Studio com um erro mínimo não ser recusado.
local VERTICAL_DOT = 0.999

-- Giro em volta de Y (radianos) de um CFrame, na convenção do Shapes
-- (a mesma do CFrame.Angles(0, yaw, 0)): o eixo X local aponta para (cos, -sin).
function MapShapes.yawOf(cframe: CFrame): number
	local right = cframe.RightVector
	return math.atan2(-right.Z, right.X)
end

function MapShapes.fromPart(part: BasePart): (Shapes.Shape?, string?)
	if part.ClassName ~= "Part" then
		return nil, `classe {part.ClassName} não aceita (use Part bloco ou cilindro)`
	end
	local shape = (part :: Part).Shape
	local cframe = part.CFrame
	local position = cframe.Position

	if shape == Enum.PartType.Block then
		if math.abs(cframe.UpVector.Y) < VERTICAL_DOT then
			return nil, "bloco inclinado (gire só em volta do eixo vertical)"
		end
		return {
			kind = "box",
			cx = position.X,
			cz = position.Z,
			sx = part.Size.X,
			sz = part.Size.Z,
			yaw = MapShapes.yawOf(cframe),
		},
			nil
	elseif shape == Enum.PartType.Cylinder then
		-- O eixo do cilindro do Roblox é o X local da peça.
		if math.abs(cframe.RightVector.Y) < VERTICAL_DOT then
			return nil, "cilindro fora da vertical (deite como uma moeda: eixo para cima)"
		end
		return { kind = "disc", cx = position.X, cz = position.Z, r = math.min(part.Size.Y, part.Size.Z) / 2 }, nil
	end
	return nil, `forma {shape.Name} não aceita (use Block ou Cylinder)`
end

return MapShapes
