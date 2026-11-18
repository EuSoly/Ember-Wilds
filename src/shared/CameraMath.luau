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

-- Distância da câmera para a opção "Zoom da câmera": 1 (100%) = mais perto,
-- 0 = mais longe (quem joga lê "mais zoom" como mais perto); linear entre
-- `max` e `min`, com a fração presa em [0, 1].
function CameraMath.zoomDistance(fraction: number, min: number, max: number): number
	return max - math.clamp(fraction, 0, 1) * (max - min)
end

return CameraMath
