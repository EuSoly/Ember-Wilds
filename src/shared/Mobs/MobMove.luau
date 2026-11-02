--!strict
-- Movimento puro dos mobs: anda e escorrega em volta de círculos (sem API do Roblox).
local BuildRules = require("../Build/BuildRules")

export type Circle = { x: number, z: number, radius: number }

local PUSH_PASSES = 4 -- rodadas de empurrão (vários círculos juntos)
local EPSILON = 1e-6 -- folga para o arredondamento não virar sobreposição

local MobMove = {}

-- Empurra (x, z) para fora dos círculos, ao longo da linha do centro (escorrega).
-- nil se depois das rodadas ainda sobrepõe algum (espremido entre dois).
local function pushOut(x: number, z: number, radius: number, circles: { Circle }): (number?, number?)
	for _ = 1, PUSH_PASSES do
		local moved = false
		for _, c in circles do
			if BuildRules.circlesOverlap(x, z, radius, c.x, c.z, c.radius) then
				local dx, dz = x - c.x, z - c.z
				local dist = math.sqrt(dx * dx + dz * dz)
				local nx, nz = 1, 0 -- no centro exato, sai pelo +X
				if dist > 0 then
					nx, nz = dx / dist, dz / dist
				end
				local want = c.radius + radius + EPSILON
				x, z = c.x + nx * want, c.z + nz * want
				moved = true
			end
		end
		if not moved then
			return x, z
		end
	end
	for _, c in circles do
		if BuildRules.circlesOverlap(x, z, radius, c.x, c.z, c.radius) then
			return nil, nil
		end
	end
	return x, z
end

-- Um passo para (tx, tz): sem sobrepor círculos e sem cair em `blocked`.
local function tryAt(
	tx: number,
	tz: number,
	radius: number,
	circles: { Circle },
	blocked: ((number, number) -> boolean)?
): (number?, number?)
	local px, pz = pushOut(tx, tz, radius, circles)
	if px == nil or pz == nil then
		return nil, nil
	end
	if blocked and blocked(px, pz) then
		return nil, nil
	end
	return px, pz
end

-- Um passo curto (menor que o raio, para não atravessar círculo): tenta o passo
-- inteiro, depois só X, depois só Z.
local function stepOnce(
	x: number,
	z: number,
	mx: number,
	mz: number,
	radius: number,
	circles: { Circle },
	blocked: ((number, number) -> boolean)?
): (number?, number?)
	local rx, rz = tryAt(x + mx, z + mz, radius, circles, blocked)
	if rx and rz then
		return rx, rz
	end
	rx, rz = tryAt(x + mx, z, radius, circles, blocked)
	if rx and rz then
		return rx, rz
	end
	return tryAt(x, z + mz, radius, circles, blocked)
end

-- Anda `distance` na direção (dirX, dirZ) e escorrega para fora dos círculos
-- (encostar pode; sobrepor não). `blocked(x, z)` (água, borda do bioma) recusa o
-- passo inteiro; aí tenta só X e só Z. Sem saída, fica parado.
function MobMove.step(
	x: number,
	z: number,
	dirX: number,
	dirZ: number,
	distance: number,
	radius: number,
	circles: { Circle },
	blocked: ((number, number) -> boolean)?
): (number, number)
	local len = math.sqrt(dirX * dirX + dirZ * dirZ)
	if distance <= 0 or len == 0 then
		return x, z
	end
	-- Passos de no máximo `radius`: um passo longo não pula um círculo fino.
	local count = math.max(1, math.ceil(distance / math.max(radius, 0.1)))
	local mx, mz = dirX / len * distance / count, dirZ / len * distance / count
	for _ = 1, count do
		local rx, rz = stepOnce(x, z, mx, mz, radius, circles, blocked)
		if rx == nil or rz == nil then
			break
		end
		x, z = rx, rz
	end
	return x, z
end

return MobMove
