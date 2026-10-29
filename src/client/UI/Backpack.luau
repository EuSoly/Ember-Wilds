--!strict
-- Mochila: o botão (só no celular) e o painel que ele abre.
-- No PC a tecla B (InputAction Backpack) abre e fecha o mesmo painel.
-- O painel mostra a grade 4×4 do inventário (InventoryGrid). Aberto/fechado
-- fica em BackpackState, porque os slots também precisam saber.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local InputNames = require(Shared:WaitForChild("InputNames"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local BackpackState = require(script.Parent.Parent:WaitForChild("BackpackState"))
local InventoryGrid = require(script.Parent:WaitForChild("InventoryGrid"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local Sources = require(script.Parent:WaitForChild("Sources"))

local create = vide.create

local Backpack = {}

-- Tecla B no PC.
local function bindKey()
	task.spawn(function()
		local context = Players.LocalPlayer:WaitForChild(InputNames.Context)
		local action = context:WaitForChild(InputNames.Backpack) :: InputAction
		action.Pressed:Connect(BackpackState.toggle)
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
		create("UISizeConstraint")({
			MinSize = Theme.touchMinSize + Vector2.new(12, 12),
			MaxSize = Vector2.new(72, 72),
		}),
		create("UICorner")({ CornerRadius = UDim.new(1, 0) }),
		create("UIStroke")({ Color = Theme.ui.border, Thickness = Theme.strokeThickness }),
		Activated = BackpackState.toggle,
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
		Visible = BackpackState.open,
		-- Captura o clique: clicar no painel não pode "bater" no mundo atrás dele.
		Active = true,
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
		InventoryGrid(),
	})
end

return Backpack
