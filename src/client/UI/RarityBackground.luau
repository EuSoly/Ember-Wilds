--!strict
-- Fundo de raridade de um quadradinho (arte do Elizeu, RarityImages): uma
-- ImageLabel que cobre o pai, em 9 partes, com os cantos na mesma fração do
-- lado em qualquer tamanho (do quadradinho pequeno da amostra ao prêmio
-- grande do giro). Sem a arte (id vazio), build devolve nil e quem chama
-- mantém a cor lisa da raridade.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local RarityImages = require(Shared:WaitForChild("RarityImages"))

local RarityBackground = {}

local SLICE = Rect.new(RarityImages.SLICE[1], RarityImages.SLICE[2], RarityImages.SLICE[3], RarityImages.SLICE[4])

-- true se a raridade tem a arte (quem chama deixa o próprio fundo transparente).
function RarityBackground.has(rarity: number): boolean
	return RarityImages.has(RarityImages.background(rarity))
end

-- A imagem de fundo (ZIndex 0, atrás do conteúdo), ou nil sem a arte.
function RarityBackground.build(rarity: number): ImageLabel?
	local id = RarityImages.background(rarity)
	if not RarityImages.has(id) then
		return nil
	end
	local image = Instance.new("ImageLabel")
	image.Name = "RarityBackground"
	image.Size = UDim2.fromScale(1, 1)
	image.BackgroundTransparency = 1
	image.Image = id
	image.ScaleType = Enum.ScaleType.Slice
	image.SliceCenter = SLICE
	image.ZIndex = 0
	-- Os cantos acompanham o tamanho (AbsoluteSize já inclui o UIScale da tela,
	-- e o SliceScale também é multiplicado por ele: desconta).
	local function fit()
		local size = image.AbsoluteSize
		local side = math.min(size.X, size.Y)
		if side <= 0 then
			return
		end
		local gui = image:FindFirstAncestorOfClass("ScreenGui")
		local uiScale = gui and gui:FindFirstChildOfClass("UIScale")
		local factor = if uiScale and uiScale.Scale > 0 then uiScale.Scale else 1
		image.SliceScale = RarityImages.sliceScale(side / factor)
	end
	image:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	fit()
	return image
end

return RarityBackground
