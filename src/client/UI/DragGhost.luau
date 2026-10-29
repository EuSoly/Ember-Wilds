--!strict
-- O item "fantasma" que segue o dedo/ponteiro enquanto um item é arrastado.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Theme = require(Shared:WaitForChild("Theme"))
local DragState = require(script.Parent.Parent:WaitForChild("DragState"))
local ItemIcon = require(script.Parent:WaitForChild("ItemIcon"))

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
		BackgroundTransparency = 0.3,
		BorderSizePixel = 0,
		ZIndex = 50,
		create("UICorner")({ CornerRadius = Theme.slotCorner }),
		vide.show(item, function(current)
			return ItemIcon({ item = current })
		end),
	}) :: Frame
	return ghost
end

return DragGhost
