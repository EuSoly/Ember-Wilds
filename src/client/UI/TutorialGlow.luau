--!strict
-- Destaque do tutorial: anel âmbar pulsando por cima de um botão (receita na
-- coluna, botão do livro, aba, item da grade), visível só quando `active()`.
-- É o mesmo em todo lugar, para o jogador reconhecer o "clique aqui". Vai como
-- filho do botão: TutorialGlow(function() return ... end).
--
-- O anel é desenhado POR DENTRO do botão (o traço da UIStroke sai para fora da
-- borda, então a moldura fica recuada a espessura do traço): a coluna de
-- receitas é um ScrollingFrame que corta o que passa da borda, e um anel por
-- fora aparecia cortado em cima e à esquerda (visto no Studio em 10/11/2026).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local PointerRules =
	require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Tutorial"):WaitForChild("PointerRules"))

local create = vide.create

local COLOR = Color3.fromRGB(255, 178, 28) -- âmbar forte (lê bem sobre madeira e couro)
local THICKNESS = 3 -- px do anel
local PULSE_SPEED = 5 -- rad/s
local CORNER = UDim.new(0.14, 0) -- cantos do slot de couro (~16 de 126 px na arte)

-- Um relógio só para todos os destaques (uma conexão, não uma por botão).
local clock = vide.source(0)
RunService.RenderStepped:Connect(function()
	clock(os.clock())
end)

-- 0 → 1 → 0 no ritmo do pulso.
local function pulse(): number
	return 0.5 + 0.5 * math.sin(clock() * PULSE_SPEED)
end

-- Destaques montados agora e de que lado a seta fica (UI/TutorialPointer
-- aponta para o que estiver aceso).
local glows: { [Frame]: PointerRules.Side } = {}

-- true se `gui` está mesmo na tela: ele e todos acima visíveis, e o ScreenGui ligado.
local function onScreen(gui: GuiObject): boolean
	local node: Instance? = gui
	while node do
		if node:IsA("GuiObject") then
			if not node.Visible then
				return false
			end
		elseif node:IsA("LayerCollector") then
			return node.Enabled
		end
		node = node.Parent
	end
	return false
end

-- `corner` = arredondado do anel (padrão: o do slot; UDim.new(1, 0) = redondo).
-- `side` = de que lado a seta fica (padrão: embaixo; ver PointerRules).
local function TutorialGlow(active: () -> boolean, corner: UDim?, side: PointerRules.Side?): Frame
	local frame = create("Frame")({
		Name = "TutorialGlow",
		Visible = active,
		Position = UDim2.fromOffset(THICKNESS, THICKNESS),
		Size = UDim2.new(1, -2 * THICKNESS, 1, -2 * THICKNESS),
		BackgroundColor3 = COLOR,
		-- Um brilho leve no miolo, que acende junto com o anel.
		BackgroundTransparency = function()
			return 0.92 - 0.12 * pulse()
		end,
		BorderSizePixel = 0,
		ZIndex = 10,
		create("UICorner")({ CornerRadius = corner or CORNER }),
		create("UIStroke")({
			Color = COLOR,
			Thickness = THICKNESS,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Transparency = function()
				return 0.35 * (1 - pulse())
			end,
		}),
	}) :: Frame
	glows[frame] = side or "below"
	frame.Destroying:Connect(function()
		glows[frame] = nil
	end)
	return frame
end

-- O botão destacado que está na tela agora (o pai do destaque aceso) e o lado
-- da seta, ou nil.
local function activeTarget(): (GuiObject?, PointerRules.Side)
	for frame, side in glows do
		local parent = frame.Parent
		if parent and parent:IsA("GuiObject") and onScreen(frame) then
			return parent, side :: PointerRules.Side
		end
	end
	return nil, "below" :: PointerRules.Side
end

return setmetatable({ activeTarget = activeTarget }, {
	__call = function(_, active: () -> boolean, corner: UDim?, side: PointerRules.Side?): Frame
		return TutorialGlow(active, corner, side)
	end,
}) :: any
