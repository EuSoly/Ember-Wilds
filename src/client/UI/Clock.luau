--!strict
-- Relógio do ciclo (topo, centro): sol de dia, lua de noite, "Dia N · mm:ss"
-- com o tempo que falta até a próxima troca. Fica laranja nos 30 s antes da
-- noite e dispara o aviso "A noite está chegando".
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local DayCycle = require(Shared:WaitForChild("DayCycle"))
local Palette = require(Shared:WaitForChild("Palette"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local Notifications = require(script.Parent:WaitForChild("Notifications"))
local Sources = require(script.Parent:WaitForChild("Sources"))

local create = vide.create

local SUN = Theme.color(Palette.ui.warning)
local MOON = Theme.color(Palette.biome.nightFire[2])

local function Clock(): Frame
	local cycle = Sources.cycle()
	local nightSoon = vide.derive(function()
		return cycle().nightSoon
	end)

	-- Avisa uma vez quando a noite começa a chegar. O aviso é disparado fora do
	-- efeito (task.defer) para não mexer em outra fonte reativa no meio dele.
	local warned = false
	vide.effect(function()
		local soon = nightSoon()
		if soon and not warned then
			warned = true
			task.defer(Notifications.push, "hud.nightComing")
		elseif not soon then
			warned = false
		end
	end)

	return Kit.panel({
		Name = "Clock",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.02),
		Size = UDim2.fromScale(0.22, 0.065),
		CornerRadius = UDim.new(1, 0),
		BackgroundColor3 = function()
			return if nightSoon() then Theme.ui.action else Theme.ui.panel
		end,
		create("UIAspectRatioConstraint")({ AspectRatio = 4.5 }),
		-- Sol ou lua
		create("Frame")({
			Name = "Icon",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromScale(0.06, 0.5),
			Size = UDim2.fromScale(0.6, 0.6),
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
			BorderSizePixel = 0,
			BackgroundColor3 = function()
				return if cycle().isNight then MOON else SUN
			end,
			create("UICorner")({ CornerRadius = UDim.new(1, 0) }),
		}),
		Kit.text({
			Name = "Label",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromScale(0.26, 0.5),
			Size = UDim2.fromScale(0.68, 0.62),
			FontFace = Theme.font.number,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = function()
				local state = cycle()
				return `{Strings.format("hud.day", { day = state.day })} · {DayCycle.formatTime(state.secondsLeft)}`
			end,
		}),
	})
end

return Clock
