--!strict
-- Os quatro anéis de status (vida, fome, frio, sede), lado a lado acima da hotbar.
-- Lê os atributos do jogador; enquanto um atributo não existe, mostra o anel cheio.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local StatNames = require(Shared:WaitForChild("StatNames"))
local Theme = require(Shared:WaitForChild("Theme"))
local Sources = require(script.Parent:WaitForChild("Sources"))
local StatusRing = require(script.Parent:WaitForChild("StatusRing"))

local create = vide.create

-- Ordem e cor de cada anel (cores das barras na identidade visual).
local RINGS = {
	{ stat = StatNames.Health, color = Theme.status.health },
	{ stat = StatNames.Hunger, color = Theme.status.hunger },
	{ stat = StatNames.Cold, color = Theme.status.cold },
	{ stat = StatNames.Thirst, color = Theme.status.thirst },
}

local function StatusRings(): Frame
	local player = Players.LocalPlayer
	local rings = {}
	for order, ring in RINGS do
		table.insert(
			rings,
			create("Frame")({
				Name = ring.stat,
				LayoutOrder = order,
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(0.25, 1),
				create("UIAspectRatioConstraint")({ AspectRatio = 1 }),
				create("UISizeConstraint")({ MinSize = Vector2.new(40, 40), MaxSize = Vector2.new(72, 72) }),
				StatusRing({
					name = "Ring",
					value = Sources.attribute(player, ring.stat, StatNames.StatusMax),
					color = ring.color,
				}),
			})
		)
	end

	return create("Frame")({
		Name = "StatusRings",
		-- Vai dentro da hotbar (ver Hotbar.above): preso 8 px acima do topo dela.
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 0, -8),
		Size = UDim2.fromScale(0.5, 1.25),
		BackgroundTransparency = 1,
		create("UIListLayout")({
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0.02, 0),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		rings,
	}) :: Frame
end

return StatusRings
