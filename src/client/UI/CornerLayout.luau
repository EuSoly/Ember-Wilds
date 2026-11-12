--!strict
-- Medidas do canto superior direito (minimapa, livro e engrenagem) para a tela
-- atual, reativas: MinimapRules.layout com o tamanho da tela (ScreenMetrics).
-- O livro fica na borda esquerda de baixo do mapa e a engrenagem na direita.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MinimapRules =
	require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("World"):WaitForChild("MinimapRules"))
local ScreenMetrics = require(script.Parent:WaitForChild("ScreenMetrics"))

local CornerLayout = {}

function CornerLayout.get(): MinimapRules.Layout
	-- Altura da área do HUD (sem a barra do Roblox): as posições são dentro dela.
	local size = ScreenMetrics.size()
	return MinimapRules.layout(size.X, ScreenMetrics.guiHeight(), ScreenMetrics.short())
end

-- Posição do botão: `left` = livro (borda esquerda da fileira), senão a engrenagem.
function CornerLayout.buttonPosition(left: boolean): UDim2
	local layout = CornerLayout.get()
	local right = layout.margin + (if left then layout.rowWidth - layout.buttonSize else 0)
	return UDim2.new(1, -right, 0, layout.buttonTop)
end

-- Embaixo da engrenagem (segunda fileira, borda direita): botão das Missões.
function CornerLayout.secondRowPosition(): UDim2
	local layout = CornerLayout.get()
	local gap = math.max(math.round(layout.buttonSize * 0.15), 4)
	return UDim2.new(1, -layout.margin, 0, layout.buttonTop + layout.buttonSize + gap)
end

function CornerLayout.buttonSize(): UDim2
	local side = CornerLayout.get().buttonSize
	return UDim2.fromOffset(side, side)
end

return CornerLayout
