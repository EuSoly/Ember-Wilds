--!strict
-- Painel do baú: aparece acima da hotbar só enquanto há um baú perto e mostra
-- o item guardado (ícone com a quantidade). Clicar/tocar tira tudo que couber
-- no inventário. Baú vazio: moldura vazia, sem ícone.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Theme = require(Shared:WaitForChild("Theme"))
local ChestState = require(script.Parent.Parent:WaitForChild("ChestState"))
local HudArt = require(script.Parent:WaitForChild("HudArt"))
local ItemIcon = require(script.Parent:WaitForChild("ItemIcon"))

local create = vide.create

local SIZE = 64 -- px (acima do mínimo de toque)

local function ChestPanel(): TextButton
	return create("TextButton")({
		Name = "ChestPanel",
		AnchorPoint = Vector2.new(0.5, 1),
		-- Logo acima dos anéis de status, que ficam presos à hotbar.
		Position = UDim2.fromScale(0.5, 0.77),
		Size = UDim2.fromOffset(SIZE, SIZE),
		Visible = function()
			return ChestState.near() ~= nil
		end,
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Theme.ui.panel,
		-- Com a arte, o couro do slot é o fundo e a borda.
		BackgroundTransparency = if HudArt.HAS_SLOT then 1 else Theme.panelTransparency,
		BorderSizePixel = 0,
		create("UICorner")({ CornerRadius = Theme.slotCorner }),
		create("UIStroke")({
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = Theme.ui.border,
			Thickness = Theme.strokeThickness,
			Enabled = not HudArt.HAS_SLOT,
		}),
		if HudArt.HAS_SLOT then { HudArt.slotBack() } else {},
		Activated = function()
			ChestState.take()
		end,
		vide.show(ChestState.contents, function(current)
			return if HudArt.HAS_SLOT
				then HudArt.inSlot(ItemIcon({ item = current, bare = true }))
				else ItemIcon({ item = current })
		end),
	}) :: TextButton
end

return ChestPanel
