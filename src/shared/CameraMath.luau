--!strict
-- Contas da câmera top-down (só números: testável no Lune).

local CameraMath = {}

-- Para uma câmera inclinada `pitchDeg` graus (90 = olhando reto para baixo) a
-- `distance` studs do alvo, devolve (altura, recuo): a câmera fica em
-- alvo + (0, altura, recuo), olhando para o alvo.
function CameraMath.offset(pitchDeg: number, distance: number): (number, number)
	local pitch = math.rad(pitchDeg)
	return distance * math.sin(pitch), distance * math.cos(pitch)
end

-- Fator de suavização exponencial independente do FPS: a câmera anda essa
-- fração da distância até o alvo neste frame. `k` maior = segue mais "colada".
function CameraMath.smoothAlpha(k: number, dt: number): number
	return 1 - math.exp(-k * dt)
end

return CameraMath
