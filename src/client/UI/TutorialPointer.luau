--!strict
-- Seta do tutorial: uma seta dourada balançando ao lado do botão que é para
-- clicar agora (o que tem o destaque aceso, UI/TutorialGlow): a receita na
-- coluna, o botão do livro, a aba, o item da grade. Pedido do Elizeu depois de
-- um teste (10/11/2026): só o brilho não chamava a atenção. Onde a seta fica e
-- como balança vem de Tutorial/PointerRules (testado).
--
-- Fica num ScreenGui próprio, acima do HUD e do livro, para não ser cortada
-- pela coluna de receitas (ScrollingFrame) e aparecer por cima da janela.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local HudImages = require(Shared:WaitForChild("HudImages"))
local PointerRules = require(Shared:WaitForChild("Tutorial"):WaitForChild("PointerRules"))
local Theme = require(Shared:WaitForChild("Theme"))
local TutorialState = require(script.Parent.Parent:WaitForChild("TutorialState"))
local TutorialGlow = require(script.Parent:WaitForChild("TutorialGlow"))

local create = vide.create

local function TutorialPointer(): ScreenGui
	local rect = HudImages.TUTORIAL_ARROW_RECT
	local width = PointerRules.SIZE * rect.width / rect.height
	local arrow = create("ImageLabel")({
		Name = "Arrow",
		Visible = false,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(width, PointerRules.SIZE),
		BackgroundTransparency = 1,
		Image = HudImages.TUTORIAL_ARROW,
		ImageRectOffset = Vector2.new(rect.x, rect.y),
		ImageRectSize = Vector2.new(rect.width, rect.height),
		ImageColor3 = Color3.new(1, 1, 1),
		ScaleType = Enum.ScaleType.Fit,
	}) :: ImageLabel
	-- Sem a arte: um triângulo de texto na cor do destaque.
	if not HudImages.has(HudImages.TUTORIAL_ARROW) then
		arrow.Image = ""
		local fallback = create("TextLabel")({
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = "▼",
			TextScaled = true,
			TextColor3 = Theme.rustic.emberLight,
		})
		fallback.Parent = arrow
	end

	local gui = create("ScreenGui")({
		Name = "TutorialPointer",
		ResetOnSpawn = false,
		AutoLocalize = false, -- os textos já vêm traduzidos do Strings
		DisplayOrder = 20, -- acima do HUD e do livro de receitas (5)
		IgnoreGuiInset = false,
		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
		arrow,
	}) :: ScreenGui

	local connection = RunService.RenderStepped:Connect(function()
		local target: GuiObject?, side: PointerRules.Side = nil, "below"
		if TutorialState.step() > 0 then
			target, side = TutorialGlow.activeTarget()
		end
		if target == nil then
			arrow.Visible = false
			return
		end
		local origin = gui.AbsolutePosition
		local position = target.AbsolutePosition - origin
		local size = target.AbsoluteSize
		local placement = PointerRules.place(position.X, position.Y, size.X, size.Y, side)
		local dx, dy = PointerRules.bob(placement, os.clock())
		arrow.Position = UDim2.fromOffset(placement.x + dx, placement.y + dy)
		arrow.Rotation = placement.rotation
		arrow.Visible = true
	end)
	vide.cleanup(function()
		connection:Disconnect()
	end)
	return gui
end

return TutorialPointer
