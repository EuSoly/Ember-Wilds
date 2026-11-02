--!strict
-- Os quatro anéis de status (vida, fome, temperatura, sede), lado a lado acima da hotbar.
-- Lê os atributos do jogador; enquanto um atributo não existe, mostra o anel cheio.
-- Temperatura: mostra o frio (azul); com calor (atributo Heat > 0) mostra o
-- calor em laranja, pulsando com o calor alto e piscando com ele cheio.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local StatNames = require(Shared:WaitForChild("StatNames"))
local Theme = require(Shared:WaitForChild("Theme"))
local UIMath = require(Shared:WaitForChild("UIMath"))
local Sources = require(script.Parent:WaitForChild("Sources"))
local StatusRing = require(script.Parent:WaitForChild("StatusRing"))

local create = vide.create

-- Ordem e cor de cada anel (cores das barras na identidade visual).
local RINGS = {
	{ stat = StatNames.Health, color = Theme.status.health, max = StatNames.HealthMax },
	{ stat = StatNames.Hunger, color = Theme.status.hunger, max = StatNames.StatusMax },
	{ stat = StatNames.Cold, color = Theme.status.cold, max = StatNames.StatusMax },
	{ stat = StatNames.Thirst, color = Theme.status.thirst, max = StatNames.StatusMax },
}

-- O anel do frio vira anel de temperatura (frio + calor por cima).
local function temperatureProps(player: Player): { [string]: any }
	local cold = Sources.attribute(player, StatNames.Cold, StatNames.StatusMax)
	local heat = Sources.attribute(player, StatNames.Heat, 0)
	local hot = vide.derive(function()
		local _, isHot = UIMath.temperatureRing(cold(), heat())
		return isHot
	end)
	local hotWarning = (1 - StatNames.WarningFraction) * StatNames.StatusMax
	return {
		value = function()
			local value = UIMath.temperatureRing(cold(), heat())
			return value
		end,
		color = function()
			return if hot() then Theme.status.heat else Theme.status.cold
		end,
		warning = function()
			return if hot() then heat() >= hotWarning else cold() < StatNames.WarningFraction * StatNames.StatusMax
		end,
		critical = function()
			return if hot() then heat() >= StatNames.StatusMax else cold() <= 0
		end,
	}
end

local function StatusRings(): Frame
	local player = Players.LocalPlayer
	local rings = {}
	for order, ring in RINGS do
		local props: { [string]: any } = if ring.stat == StatNames.Cold
			then temperatureProps(player)
			else {
				value = Sources.attribute(player, ring.stat, ring.max),
				max = ring.max,
				color = ring.color,
			}
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
					value = props.value,
					max = props.max,
					color = props.color,
					warning = props.warning,
					critical = props.critical,
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
