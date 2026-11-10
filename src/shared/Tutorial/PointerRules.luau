--!strict
-- Seta do tutorial (puro, testado no Lune): onde a seta fica em volta do botão
-- que é para clicar e como ela balança. Quem pede o destaque diz de que lado a
-- seta fica (`side`): "right" (à direita do alvo, apontando para a esquerda; ex.
-- a coluna de receitas na beira esquerda), "left" (à esquerda, apontando para a
-- direita; ex. o botão do livro na beira direita) ou "below" (embaixo,
-- apontando para cima; abas e itens dentro de janelas). O desenho é do cliente
-- (UI/TutorialPointer). Rotação em graus, como no Roblox (0 = a arte da seta,
-- que aponta para baixo; positivo = horário).
local PointerRules = {}

PointerRules.SIZE = 38 -- px do comprimento da seta
PointerRules.GAP = 6 -- px entre a ponta da seta e o alvo
PointerRules.BOB = 10 -- px que a seta vai e volta
PointerRules.BOB_SPEED = 6 -- rad/s

export type Side = "right" | "left" | "below"
export type Placement = { x: number, y: number, rotation: number }

-- Centro da seta e rotação, para o alvo em (tx, ty) de tamanho (tw, th).
function PointerRules.place(tx: number, ty: number, tw: number, th: number, side: Side): Placement
	local cx, cy = tx + tw / 2, ty + th / 2
	local half = PointerRules.SIZE / 2
	if side == "right" then
		return { x = tx + tw + PointerRules.GAP + half, y = cy, rotation = 90 }
	elseif side == "left" then
		return { x = tx - PointerRules.GAP - half, y = cy, rotation = -90 }
	end
	return { x = cx, y = ty + th + PointerRules.GAP + half, rotation = 180 }
end

-- Deslocamento do balanço no instante `t` (s): vai para longe do alvo e volta.
function PointerRules.bob(placement: Placement, t: number): (number, number)
	local amount = PointerRules.BOB * (0.5 + 0.5 * math.sin(t * PointerRules.BOB_SPEED - math.pi / 2))
	if placement.rotation == 90 then
		return amount, 0
	elseif placement.rotation == -90 then
		return -amount, 0
	end
	return 0, amount
end

return PointerRules
