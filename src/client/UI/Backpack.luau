--!strict
-- Mochila: o botão (só no celular) e o painel que ele abre.
-- No PC a tecla B (InputAction Backpack) abre e fecha o mesmo painel.
-- POR ENQUANTO o painel é vazio; a grade 4×4 do inventário entra na Fase 3.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local InputNames = require(Shared:WaitForChild("InputNames"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local Sources = require(script.Parent:WaitForChild("Sources"))

local create = vide.create

local Backpack = {}

-- Painel aberto ou fechado.
Backpack.open = vide.source(false)

function Backpack.toggle()
	Backpack.open(not Backpack.open())
end

-- Tecla B no PC.
local function bindKey()
	task.spawn(function()
		local context = Players.LocalPlayer:WaitForChild(InputNames.Context)
		local action = context:WaitForChild(InputNames.Backpack) :: InputAction
		action.Pressed:Connect(Backpack.toggle)
	end)
end

function Backpack.Button(): TextButton
	local isTouch = Sources.isTouch()
	return create("TextButton")({
		Name = "BackpackButton",
		Visible = isTouch,
		Text = "",
		AutoButtonColor = true,
		AnchorPoint = Vector2.new(0.5, 0.5),
		-- Acima do joystick direito.
		Position = UDim2.fromScale(0.78, 0.5),
		Size = UDim2.fromScale(0.09, 0.09),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		BackgroundColor3 = Theme.ui.panel,
		BackgroundTransparency = Theme.panelTransparency,
		BorderSizePixel = 0,
		create("UICorner")({ CornerRadius = UDim.new(1, 0) }),
		create("UIStroke")({ Color = Theme.ui.border, Thickness = Theme.strokeThickness }),
		Activated = Backpack.toggle,
		Kit.text({
			Size = UDim2.fromScale(0.8, 0.4),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Text = Strings.get("hud.backpack"),
			maxSize = 14,
		}),
	}) :: TextButton
end

function Backpack.Panel(): Frame
	bindKey()
	return Kit.panel({
		Name = "BackpackPanel",
		Visible = Backpack.open,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.45),
		Size = UDim2.fromScale(0.4, 0.5),
		create("UIAspectRatioConstraint")({ AspectRatio = 1 }),
		Kit.text({
			Name = "Title",
			Size = UDim2.fromScale(0.9, 0.12),
			Position = UDim2.fromScale(0.5, 0.06),
			AnchorPoint = Vector2.new(0.5, 0),
			FontFace = Theme.font.title,
			Text = Strings.get("hud.backpack"),
			maxSize = 32,
		}),
	})
end

return Backpack
