--!strict
-- Iluminação de dia e de noite no cliente. A hora vem da mesma fórmula do
-- relógio da HUD (DayCycle + atributo CycleStart): sem tráfego de rede. Na
-- troca dia ↔ noite faz uma transição de LightingConfig.TRANSITION_SECONDS;
-- ao entrar no jogo aplica o clima atual na hora.
-- Usa a sua própria correção de cor ("DayNight"); a da tela de morte
-- ("DeathDesaturate") é outra e não é mexida aqui.
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local DayCycle = require(Shared:WaitForChild("DayCycle"))
local LightingConfig = require(Shared:WaitForChild("LightingConfig"))
local StatNames = require(Shared:WaitForChild("StatNames"))

local CHECK_EVERY = 0.25 -- segundos

local DayNightController = {}

local function hex(value: string): Color3
	return Color3.fromHex(value)
end

local function ensure<T>(className: string, name: string): T
	local existing = Lighting:FindFirstChild(name)
	if existing and existing.ClassName == className then
		return existing :: any
	end
	local created = Instance.new(className)
	created.Name = name
	created.Parent = Lighting
	return created :: any
end

local colorCorrection: ColorCorrectionEffect
local atmosphere: Atmosphere?

local function apply(mood: LightingConfig.Mood, seconds: number)
	local info = TweenInfo.new(seconds, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	local function go(instance: Instance, goal: { [string]: any })
		if seconds <= 0 then
			for property, value in goal do
				(instance :: any)[property] = value
			end
		else
			TweenService:Create(instance, info, goal):Play()
		end
	end
	go(Lighting, {
		Brightness = mood.Brightness,
		Ambient = hex(mood.Ambient),
		OutdoorAmbient = hex(mood.OutdoorAmbient),
		ExposureCompensation = mood.ExposureCompensation,
	})
	go(colorCorrection, {
		TintColor = hex(mood.TintColor),
		Brightness = mood.ColorBrightness,
		Contrast = mood.Contrast,
		Saturation = mood.Saturation,
	})
	if atmosphere then
		go(atmosphere, { Density = mood.AtmosphereDensity, Color = hex(mood.AtmosphereColor) })
	end
end

local function isNightNow(): boolean?
	local start = Workspace:GetAttribute(StatNames.CycleStart)
	if type(start) ~= "number" then
		return nil
	end
	return DayCycle.at(Workspace:GetServerTimeNow() - start).isNight
end

function DayNightController.Start(_self)
	Lighting.ClockTime = LightingConfig.CLOCK_TIME
	colorCorrection = ensure("ColorCorrectionEffect", "DayNight")
	-- Usa a Atmosphere do place; sem nenhuma, cria uma (senão os valores de
	-- névoa do LightingConfig não fariam nada).
	atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or ensure("Atmosphere", "Atmosphere")

	task.spawn(function()
		local current: boolean? = nil
		while true do
			local night = isNightNow()
			if night ~= nil and night ~= current then
				-- Primeira vez: aplica na hora; depois, com transição.
				local seconds = if current == nil then 0 else LightingConfig.TRANSITION_SECONDS
				apply(if night then LightingConfig.night else LightingConfig.day, seconds)
				current = night
			end
			task.wait(CHECK_EVERY)
		end
	end)
end

return DayNightController
