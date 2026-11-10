--!strict
-- Ondinhas na água (puro, testado no Lune): quando soltar um anel e como ele
-- cresce e some. Quem anda pela água solta um anel a cada STEP studs (nunca
-- mais rápido que MIN_GAP); parado na água, um anel lento a cada IDLE_EVERY.
-- O efeito em si é do cliente (World/WaterRipples).
local RippleRules = {}

RippleRules.STEP = 3 -- studs andados entre dois anéis
RippleRules.MIN_GAP = 0.18 -- s no mínimo entre dois anéis
RippleRules.IDLE_EVERY = 1.4 -- s entre anéis de quem está parado na água
RippleRules.LIFE = 1.1 -- s de vida de um anel
RippleRules.START_SIZE = 1.6 -- studs de diâmetro ao nascer
RippleRules.END_SIZE = 7 -- studs de diâmetro ao sumir
RippleRules.START_ALPHA = 0.15 -- transparência ao nascer (0 = opaco)

export type State = { x: number, z: number, t: number }

-- Um passo de quem está na água em (x, z) no instante `now`. Devolve se solta
-- um anel agora e o estado a guardar (o mesmo, se não soltou).
function RippleRules.step(state: State?, x: number, z: number, now: number): (boolean, State)
	if state == nil then
		return true, { x = x, z = z, t = now }
	end
	local elapsed = now - state.t
	if elapsed < RippleRules.MIN_GAP then
		return false, state
	end
	local dx, dz = x - state.x, z - state.z
	local moved = math.sqrt(dx * dx + dz * dz)
	if moved >= RippleRules.STEP or elapsed >= RippleRules.IDLE_EVERY then
		return true, { x = x, z = z, t = now }
	end
	return false, state
end

-- Diâmetro (studs) e transparência do anel em `progress` (0 = nasceu, 1 = fim).
-- Cresce rápido no começo e desacelera; some até a transparência 1.
function RippleRules.ring(progress: number): (number, number)
	local p = math.clamp(progress, 0, 1)
	local eased = 1 - (1 - p) * (1 - p)
	local size = RippleRules.START_SIZE + (RippleRules.END_SIZE - RippleRules.START_SIZE) * eased
	local alpha = RippleRules.START_ALPHA + (1 - RippleRules.START_ALPHA) * p
	return size, alpha
end

return RippleRules
