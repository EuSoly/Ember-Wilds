--!strict
-- Brilhos na água (puro, testado no Lune): traços brancos que aparecem e somem
-- devagar em pontos soltos da água perto da câmera, para a água pintada não
-- parecer parada. O efeito em si é do cliente (World/WaterGlints).
local GlintRules = {}

GlintRules.EVERY = 0.09 -- s entre tentativas de soltar um brilho
GlintRules.RADIUS = 75 -- studs em volta da câmera onde nascem
GlintRules.LIFE = 1.6 -- s de vida de um brilho
GlintRules.PEAK = 0.75 -- o quão visível fica no auge (0 = nada, 1 = branco cheio)
GlintRules.MIN_LENGTH = 1.1 -- studs de comprimento (sorteado entre os dois)
GlintRules.MAX_LENGTH = 2.4
GlintRules.WIDTH = 0.28 -- studs de largura
GlintRules.ANGLE = math.rad(-18) -- todos quase na mesma direção, como reflexo do sol
GlintRules.ANGLE_JITTER = math.rad(12)

-- Transparência do brilho em `progress` (0 = nasceu, 1 = fim): começa e termina
-- invisível (1) e passa por 1 - PEAK no meio.
function GlintRules.transparency(progress: number): number
	local p = math.clamp(progress, 0, 1)
	return 1 - math.sin(p * math.pi) * GlintRules.PEAK
end

-- Fator de comprimento em `progress`: estica um pouco enquanto vive.
function GlintRules.stretch(progress: number): number
	local p = math.clamp(progress, 0, 1)
	return 0.6 + 0.4 * math.sin(p * math.pi * 0.5)
end

-- Ponto sorteado no disco de raio RADIUS em volta de (cx, cz). `u` e `v` são
-- números de 0 a 1 (o sorteio fica de fora, para dar para testar).
function GlintRules.spot(cx: number, cz: number, u: number, v: number): (number, number)
	local r = GlintRules.RADIUS * math.sqrt(u)
	local a = v * math.pi * 2
	return cx + math.cos(a) * r, cz + math.sin(a) * r
end

return GlintRules
