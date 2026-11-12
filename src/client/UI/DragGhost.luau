--!strict
-- O item "fantasma" que segue o dedo/ponteiro enquanto um item é arrastado.
-- No mundo (fora da interface), aparece "Largar" embaixo: soltar ali larga.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Theme = require(Shared:WaitForChild("Theme"))
local DragState = require(script.Parent.Parent:WaitForChild("DragState"))
local Strings = require(Shared:WaitForChild("Strings"))
local HudArt = require(script.Parent:WaitForChild("HudArt"))
local ItemIcon = require(script.Parent:WaitForChild("ItemIcon"))
local Rustic = require(script.Parent:WaitForChild("Rustic"))

local create = vide.create

local GHOST_SIZE = 52 -- pixels

local function DragGhost(): Frame
	local ghost: Frame

	local item = vide.derive(function()
		local drag = DragState.current()
		return if drag then drag.item else nil
	end)

	ghost = create("Frame")({
		Name = "DragGhost",
		Visible = function()
			return DragState.current() ~= nil
		end,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(GHOST_SIZE, GHOST_SIZE),
		Position = function()
			local drag = DragState.current()
			if drag == nil then
				return UDim2.new()
			end
			-- O ponteiro vem em coordenadas de tela; o fantasma é posicionado
			-- relativo ao ScreenGui, que pode estar deslocado pela área segura.
			local parent = ghost and ghost.Parent
			local origin = if parent and parent:IsA("GuiBase2d") then parent.AbsolutePosition else Vector2.zero
			return UDim2.fromOffset(drag.position.X - origin.X, drag.position.Y - origin.Y)
		end,
		BackgroundColor3 = Theme.ui.panelRaised,
		BackgroundTransparency = if HudArt.HAS_SLOT then 1 else 0.3,
		BorderSizePixel = 0,
		ZIndex = 50,
		create("UICorner")({ CornerRadius = Theme.slotCorner }),
		if HudArt.HAS_SLOT then { HudArt.slotBack() } else {},
		vide.show(item, function(current)
			return if HudArt.HAS_SLOT
				then HudArt.inSlot(ItemIcon({ item = current, bare = true }))
				else ItemIcon({ item = current })
		end),
		Rustic.label({
			Name = "DropHint",
			Visible = DragState.outside,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 1, 2),
			Size = UDim2.fromOffset(90, 20),
			Text = Strings.get("inventory.drop"),
			maxSize = 16,
			ZIndex = 51,
			-- Contorno escuro: o texto creme fica legível em cima da grama e da areia.
			create("UIStroke")({ Thickness = 1.5, Color = Color3.fromRGB(45, 28, 16) }),
		}),
	}) :: Frame
	return ghost
end

return DragGhost
