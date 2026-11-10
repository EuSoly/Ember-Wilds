--!strict
-- Quadrinho da missão do tutorial, embaixo do minimapa e dos botões redondos:
-- "Tutorial N/6" e o que fazer agora, com o contador ("3/10") quando a etapa
-- conta itens. Pisca dourado quando muda de etapa. No fim, o aviso de
-- parabéns com os giros ganhos (Net.TutorialDone).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local TutorialRules = require(Shared:WaitForChild("Tutorial"):WaitForChild("TutorialRules"))
local TutorialSteps = require(Shared:WaitForChild("Tutorial"):WaitForChild("TutorialSteps"))
local Net = require(script.Parent.Parent:WaitForChild("Net"))
local TutorialState = require(script.Parent.Parent:WaitForChild("TutorialState"))
local Notifications = require(script.Parent:WaitForChild("Notifications"))
local Rustic = require(script.Parent:WaitForChild("Rustic"))

local create = vide.create
local R = Theme.rustic

-- Logo abaixo dos botões redondos (livro e configurações vão até ~0,34).
local POSITION = UDim2.fromScale(0.98, 0.355)
local SIZE = UDim2.fromScale(0.24, 0.1)
local FLASH_TIME = 0.6

local function stepText(): string
	local step = TutorialState.current()
	if step == nil then
		return ""
	end
	local have, need = TutorialRules.progress(step, {
		counts = TutorialState.counts(),
		placed = {},
		viewed = {},
		wetSeconds = 0,
	})
	return Strings.format(step.textKey, { have = have, need = need })
end

local function TutorialPanel(): Frame
	Net.TutorialDone.On(function(data)
		local vars: { [string]: string | number } = { spins = data.Spins }
		Notifications.push("tutorial.done", vars, "success")
	end)

	-- Ao mudar de etapa, a borda acende e apaga devagar.
	local glow = vide.source(1)
	local glowSpring = vide.spring(glow, FLASH_TIME)
	vide.effect(function()
		TutorialState.step()
		glow(0)
		task.delay(0.05, function()
			glow(1)
		end)
	end)

	return Rustic.paper({
		Name = "TutorialPanel",
		AnchorPoint = Vector2.new(1, 0),
		Position = POSITION,
		Size = SIZE,
		Visible = function()
			return TutorialState.step() > 0
		end,
		create("UIStroke")({
			Name = "Glow",
			Color = R.emberLight,
			Thickness = 4,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Transparency = glowSpring,
		}),
		create("UIPadding")({
			PaddingLeft = UDim.new(0.05, 0),
			PaddingRight = UDim.new(0.05, 0),
			PaddingTop = UDim.new(0.1, 0),
			PaddingBottom = UDim.new(0.1, 0),
		}),
		Rustic.label({
			Name = "Header",
			Size = UDim2.fromScale(1, 0.38),
			TextColor3 = R.emberShadow,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = function()
				return Strings.format("tutorial.header", { step = TutorialState.step(), total = #TutorialSteps.LIST })
			end,
		}),
		Rustic.label({
			Name = "Step",
			dark = true,
			Position = UDim2.fromScale(0, 0.42),
			Size = UDim2.fromScale(1, 0.58),
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = stepText,
		}),
	}) :: Frame
end

return TutorialPanel
