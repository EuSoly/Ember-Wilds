--!strict
-- Matemática da orientação do personagem (só números: testável no Lune).
--
-- Yaw = rotação em torno do eixo Y, em radianos. No Roblox, CFrame.Angles(0, yaw, 0)
-- com yaw = 0 olha para -Z. Por isso a direção (x, z) corresponde a atan2(-x, -z).

local Facing = {}

-- Abaixo deste comprimento a direção é considerada "sem mira".
local MIN_LENGTH = 0.01

-- Normaliza um ângulo para o intervalo (-π, π].
local function wrap(angle: number): number
	local wrapped = (angle + math.pi) % (2 * math.pi) - math.pi
	if wrapped <= -math.pi then
		wrapped += 2 * math.pi
	end
	return wrapped
end

-- Yaw para olhar na direção (x, z) do mundo. nil se a direção for ~zero
-- (aí quem chama mantém o yaw atual, sem "pular").
function Facing.yawFromDirection(x: number, z: number): number?
	if math.sqrt(x * x + z * z) < MIN_LENGTH then
		return nil
	end
	return math.atan2(-x, -z)
end

-- Para onde o personagem deve virar (regra da seção 5 do spec):
-- morto não vira; com mira, vira para a mira; sem mira, para onde anda;
-- parado e sem mira devolve nil (mantém a direção atual).
function Facing.desiredYaw(isAlive: boolean, aimX: number, aimZ: number, moveX: number, moveZ: number): number?
	if not isAlive then
		return nil
	end
	return Facing.yawFromDirection(aimX, aimZ) or Facing.yawFromDirection(moveX, moveZ)
end

-- Gira de `current` até `target` pelo caminho mais curto, no máximo `maxDelta`.
function Facing.stepYaw(current: number, target: number, maxDelta: number): number
	local diff = wrap(target - current)
	if math.abs(diff) <= maxDelta then
		return wrap(target)
	end
	return wrap(current + math.sign(diff) * maxDelta)
end

return Facing
