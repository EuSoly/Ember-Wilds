--!strict
-- Formas do mapa vistas de cima (X/Z), só números: testáveis no Lune.
-- O MapShapes converte as peças do Studio (Workspace.Map) nestas formas.
--   box:  caixa de tamanho total sx × sz, girada `yaw` radianos em volta de Y
--         (mesma convenção do CFrame.Angles(0, yaw, 0) do Roblox).
--   disc: disco de raio r.
-- "Dentro" ignora a altura.

export type Shape =
	{ kind: "box", cx: number, cz: number, sx: number, sz: number, yaw: number }
	| { kind: "disc", cx: number, cz: number, r: number }

local Shapes = {}

-- Ponto (x, z) nas coordenadas locais da caixa (eixo X e Z da peça girada).
-- Com CFrame.Angles(0, yaw, 0), o eixo X local aponta para (cos, -sin) e o
-- eixo Z local para (sin, cos), em (X, Z) do mundo.
local function toLocal(cx: number, cz: number, yaw: number, x: number, z: number): (number, number)
	local dx, dz = x - cx, z - cz
	local c, s = math.cos(yaw), math.sin(yaw)
	return dx * c - dz * s, dx * s + dz * c
end

function Shapes.contains(shape: Shape, x: number, z: number): boolean
	if shape.kind == "box" then
		local lx, lz = toLocal(shape.cx, shape.cz, shape.yaw, x, z)
		return math.abs(lx) <= shape.sx / 2 and math.abs(lz) <= shape.sz / 2
	else
		local dx, dz = x - shape.cx, z - shape.cz
		return dx * dx + dz * dz <= shape.r * shape.r
	end
end

-- Distância do ponto até a forma (0 se está dentro).
function Shapes.distanceOutside(shape: Shape, x: number, z: number): number
	if shape.kind == "box" then
		local lx, lz = toLocal(shape.cx, shape.cz, shape.yaw, x, z)
		local qx = math.max(math.abs(lx) - shape.sx / 2, 0)
		local qz = math.max(math.abs(lz) - shape.sz / 2, 0)
		return math.sqrt(qx * qx + qz * qz)
	else
		local dx, dz = x - shape.cx, z - shape.cz
		return math.max(math.sqrt(dx * dx + dz * dz) - shape.r, 0)
	end
end

function Shapes.area(shape: Shape): number
	if shape.kind == "box" then
		return shape.sx * shape.sz
	else
		return math.pi * shape.r * shape.r
	end
end

-- Caixa alinhada aos eixos que envolve a forma: minX, minZ, maxX, maxZ.
function Shapes.bounds(shape: Shape): (number, number, number, number)
	if shape.kind == "box" then
		local c, s = math.abs(math.cos(shape.yaw)), math.abs(math.sin(shape.yaw))
		local ex = c * shape.sx / 2 + s * shape.sz / 2
		local ez = s * shape.sx / 2 + c * shape.sz / 2
		return shape.cx - ex, shape.cz - ez, shape.cx + ex, shape.cz + ez
	else
		return shape.cx - shape.r, shape.cz - shape.r, shape.cx + shape.r, shape.cz + shape.r
	end
end

function Shapes.anyContains(shapes: { Shape }, x: number, z: number): boolean
	for _, shape in shapes do
		if Shapes.contains(shape, x, z) then
			return true
		end
	end
	return false
end

return Shapes
