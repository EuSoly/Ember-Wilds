--!strict
-- Joystick direito (só no celular): mira e bate.
-- Enquanto o dedo arrasta além da zona morta, manda a direção para a ação de
-- mira (AimBinding) e segura a ação de bater (UseBinding). Ao soltar — em
-- qualquer lugar da tela — solta o bater e zera a mira (o personagem volta a
-- olhar para onde anda).
-- Só o toque que COMEÇOU no joystick conta: outros dedos (o do joystick de
-- movimento, por exemplo) são ignorados.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local InputNames = require(Shared:WaitForChild("InputNames"))
local Theme = require(Shared:WaitForChild("Theme"))
local UIMath = require(Shared:WaitForChild("UIMath"))
local Sources = require(script.Parent:WaitForChild("Sources"))

local create = vide.create

local DEADZONE = 12 -- pixels
local KNOB_SIZE = 0.42 -- fração da base

-- Bindings scriptable criados pelo servidor (InputContextService).
local function findBindings(): (InputBinding?, InputBinding?)
	local context = Players.LocalPlayer:FindFirstChild(InputNames.Context)
	local aim = context and context:FindFirstChild(InputNames.Aim)
	local use = context and context:FindFirstChild(InputNames.Use)
	local aimBinding = aim and aim:FindFirstChild(InputNames.AimBinding)
	local useBinding = use and use:FindFirstChild(InputNames.UseBinding)
	return aimBinding :: InputBinding?, useBinding :: InputBinding?
end

local function AimStick(): Frame
	local isTouch = Sources.isTouch()
	local knobOffset = vide.source(Vector2.zero) -- deslocamento do pino em pixels
	local trackedTouch: InputObject? = nil
	local using = false

	local base: Frame

	local function release()
		trackedTouch = nil
		knobOffset(Vector2.zero)
		local aimBinding, useBinding = findBindings()
		if useBinding and using then
			useBinding:Fire(false)
		end
		if aimBinding then
			aimBinding:Fire(Vector2.zero)
		end
		using = false
	end

	local function update(position: Vector3)
		local center = base.AbsolutePosition + base.AbsoluteSize / 2
		local radius = base.AbsoluteSize.X / 2
		local delta = Vector2.new(position.X, position.Y) - center
		-- O pino acompanha o dedo, mas não sai da base.
		knobOffset(if delta.Magnitude > radius then delta.Unit * radius else delta)

		local x, y, active = UIMath.stick(delta.X, delta.Y, radius, DEADZONE)
		local aimBinding, useBinding = findBindings()
		if active then
			if aimBinding then
				aimBinding:Fire(Vector2.new(x, y))
			end
			if useBinding and not using then
				useBinding:Fire(true)
			end
			using = true
		elseif using then
			if useBinding then
				useBinding:Fire(false)
			end
			using = false
		end
	end

	vide.cleanup(UserInputService.TouchMoved:Connect(function(touch: InputObject)
		if touch == trackedTouch then
			update(touch.Position)
		end
	end))
	vide.cleanup(UserInputService.TouchEnded:Connect(function(touch: InputObject)
		if touch == trackedTouch then
			release()
		end
	end))
	-- Trocou de dispositivo no meio: solta tudo.
	vide.effect(function()
		if not isTouch() and trackedTouch then
			release()
		end
	end)

	base = create("Frame")({
		Name = "AimStick",
		Visible = isTouch,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.88, 0.72),
		Size = UDim2.fromScale(0.22, 0.22),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		BackgroundColor3 = Theme.ui.panel,
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
		create("UICorner")({ CornerRadius = UDim.new(1, 0) }),
		create("UIStroke")({ Color = Theme.ui.border, Thickness = 2 }),
		InputBegan = function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.Touch and trackedTouch == nil then
				trackedTouch = input
				update(input.Position)
			end
		end,
		create("Frame")({
			Name = "Knob",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = function()
				local offset = knobOffset()
				return UDim2.new(0.5, offset.X, 0.5, offset.Y)
			end,
			Size = UDim2.fromScale(KNOB_SIZE, KNOB_SIZE),
			BackgroundColor3 = Theme.ui.action,
			BorderSizePixel = 0,
			create("UICorner")({ CornerRadius = UDim.new(1, 0) }),
		}),
	}) :: Frame
	return base
end

return AimStick
