--!strict
-- Rastro do tutorial (puro, testado no Lune): os pontos no chão, em linha reta,
-- do jogador até o alvo. Começa um pouco depois do jogador e para um pouco
-- antes do alvo; longe demais, corta no máximo de pontos (o rastro só aponta
-- a direção). O desenho é do cliente (World/TutorialTrail).
local TrailRules = {}

TrailRules.SPACING = 2.5 -- studs entre dois pontos
TrailRules.START_GAP = 2 -- studs do jogador até o primeiro ponto
TrailRules.END_GAP = 3 -- studs do último ponto até o alvo
TrailRules.MAX_DOTS = 24

export type Dot = { x: number, z: number }

function TrailRules.dots(fx: number, fz: number, tx: number, tz: number): { Dot }
	local dx, dz = tx - fx, tz - fz
	local length = math.sqrt(dx * dx + dz * dz)
	local dots: { Dot } = {}
	if length <= 0 then
		return dots
	end
	local ux, uz = dx / length, dz / length
	local along = TrailRules.START_GAP
	while along <= length - TrailRules.END_GAP and #dots < TrailRules.MAX_DOTS do
		table.insert(dots, { x = fx + ux * along, z = fz + uz * along })
		along += TrailRules.SPACING
	end
	return dots
end

return TrailRules
