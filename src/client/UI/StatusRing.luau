--!strict
-- Um anel de status (vida, fome, frio ou sede): 20 segmentos em círculo, acesos
-- na cor da barra conforme o valor. Abaixo de 35% o anel pulsa; zerado, os
-- segmentos ficam cinza piscando.
-- (Feito só com Frames, sem imagens, para não depender de upload de assets.)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local StatNames = require(Shared:WaitForChild("StatNames"))
local Theme = require(Shared:WaitForChild("Theme"))
local UIMath = require(Shared:WaitForChild("UIMath"))

local create = vide.create

local SEGMENTS = 20
local SEGMENT_SIZE = 0.15 -- fração do anel
local RADIUS = 0.42 -- distância do centro até os segmentos, fração do anel
local PULSE_PERIOD = 0.8 -- segundos (identidade visual: pulso a cada 0,8 s)

export type Props = {
	value: () -> number, -- 0 a StatNames.StatusMax
	color: Color3,
	name: string,
}

local function StatusRing(props: Props): Frame
	local filled = vide.derive(function()
		return UIMath.filledCount(props.value(), StatNames.StatusMax, SEGMENTS)
	end)
	local warning = vide.derive(function()
		return props.value() < StatNames.StatusMax * StatNames.WarningFraction
	end)
	local empty = vide.derive(function()
		return props.value() <= 0
	end)

	-- Relógio do pulso/pisca: alterna enquanto o anel está em alerta.
	local beat = vide.source(false)
	vide.cleanup(task.spawn(function()
		while true do
			task.wait(PULSE_PERIOD / 2)
			beat(not beat())
		end
	end))

	local targetScale = vide.derive(function()
		return if warning() and beat() then 1.1 else 1
	end)
	local scale = vide.spring(targetScale, 0.25)

	local segments = {}
	for index = 1, SEGMENTS do
		local angle = UIMath.segmentAngle(index, SEGMENTS)
		table.insert(
			segments,
			create("Frame")({
				Name = `Segment{index}`,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5 + RADIUS * math.cos(angle), 0.5 + RADIUS * math.sin(angle)),
				Size = UDim2.fromScale(SEGMENT_SIZE, SEGMENT_SIZE),
				BorderSizePixel = 0,
				BackgroundColor3 = function()
					return if index <= filled() then props.color else Theme.ui.border
				end,
				BackgroundTransparency = function()
					return if empty() and beat() then 0.6 else 0
				end,
				create("UICorner")({ CornerRadius = UDim.new(1, 0) }),
			})
		)
	end

	return create("Frame")({
		Name = props.name,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		create("UIAspectRatioConstraint")({ AspectRatio = 1 }),
		create("UIScale")({ Scale = scale }),
		-- Miolo escuro do anel
		create("Frame")({
			Name = "Core",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.56, 0.56),
			BackgroundColor3 = Theme.ui.panel,
			BackgroundTransparency = Theme.panelTransparency,
			BorderSizePixel = 0,
			create("UICorner")({ CornerRadius = UDim.new(1, 0) }),
			create("UIStroke")({ Color = props.color, Thickness = 2, Transparency = 0.4 }),
		}),
		segments,
	}) :: Frame
end

return StatusRing
