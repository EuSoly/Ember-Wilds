--!strict
-- Tela de morte (molde Death). Aparece no estado "dead" com o resumo da vida
-- (Net.LifeEnded, em ScreenState.lastSummary). Ao abrir, o mundo perde a cor
-- (saturação até −1 em 1 s) e os pontos da vida descem até 0 enquanto a Golden
-- Ember sobe até o ganho (CountUp, 2 s). No mesmo tempo, a barra de XP enche
-- do XP de antes até o de agora (recomeça do zero a cada nível que passa) e,
-- se subiu de nível, aparece "Subiu para o nível N!". Ao sair da morte (nascer
-- ou ir ao menu), a cor volta.
--
-- Nomes combinados: CauseLabel, DaysLabel, PointsLabel, CurrencyLabel, XpLabel,
-- LevelUpLabel (TextLabel), XpBar com XpFill (Frame), KitList, KitPointsLabel,
-- PlayAgainButton e MenuButton (GuiButton).
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local CountUp = require(Shared:WaitForChild("UIFlow"):WaitForChild("CountUp"))
local LevelRules = require(Shared:WaitForChild("Data"):WaitForChild("LevelRules"))
local ProfileFormat = require(Shared:WaitForChild("UIFlow"):WaitForChild("ProfileFormat"))
local Strings = require(Shared:WaitForChild("Strings"))
local Client = script.Parent.Parent
local Net = require(Client:WaitForChild("Net"))
local ScreenState = require(Client:WaitForChild("ScreenState"))
local Template = require(Client:WaitForChild("UITemplates"):WaitForChild("Template"))
local KitList = require(script.Parent:WaitForChild("KitList"))

local COUNT_DURATION = 2 -- segundos (pontos → Golden Ember)
local DESATURATE_INFO = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local RESTORE_INFO = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local EFFECT_NAME = "DeathDesaturate"

local DeathScreen = {}

-- Efeito local (criado pelo cliente, não replica) que tira a cor do mundo.
local function desaturateEffect(): ColorCorrectionEffect
	local existing = Lighting:FindFirstChild(EFFECT_NAME)
	if existing and existing:IsA("ColorCorrectionEffect") then
		return existing
	end
	local effect = Instance.new("ColorCorrectionEffect")
	effect.Name = EFFECT_NAME
	effect.Saturation = 0
	effect.Parent = Lighting
	return effect
end

function DeathScreen.mount(playerGui: Instance): ScreenGui?
	local gui = Template.clone("Death")
	if gui == nil or not gui:IsA("ScreenGui") then
		return nil
	end
	gui.ResetOnSpawn = false
	gui.Enabled = false
	Template.bind(gui)

	local causeLabel = Template.find(gui, "CauseLabel", "TextLabel")
	local daysLabel = Template.find(gui, "DaysLabel", "TextLabel")
	local pointsLabel = Template.find(gui, "PointsLabel", "TextLabel")
	local currencyLabel = Template.find(gui, "CurrencyLabel", "TextLabel")
	local xpLabel = Template.find(gui, "XpLabel", "TextLabel")
	local levelUpLabel = Template.find(gui, "LevelUpLabel", "TextLabel") :: TextLabel?
	local xpFill = Template.find(gui, "XpFill", "Frame") :: Frame?

	-- Barra com o XP total `xp`: fração dentro do nível atual.
	local function showXp(xp: number)
		if xpFill then
			local p = LevelRules.progress(xp)
			xpFill.Size = UDim2.fromScale(math.clamp(p.into / p.need, 0, 1), 1)
		end
	end

	local function showCount(points: number, currency: number)
		Template.setText(pointsLabel, Strings.format("death.points", { points = points }))
		Template.setText(currencyLabel, Strings.format("death.currency", { amount = currency }))
	end

	local playAgain = Template.find(gui, "PlayAgainButton", "GuiButton") :: GuiButton?
	if playAgain then
		playAgain.Activated:Connect(function()
			Net.RequestSpawn.Fire({ KitId = vide.untrack(KitList.selected) })
		end)
	end
	local menu = Template.find(gui, "MenuButton", "GuiButton") :: GuiButton?
	if menu then
		menu.Activated:Connect(function()
			ScreenState.send("toMenu")
		end)
	end

	KitList.mount(gui)

	local effect = desaturateEffect()
	local counting: RBXScriptConnection? = nil

	local function stopCounting()
		if counting then
			counting:Disconnect()
			counting = nil
		end
	end

	vide.effect(function()
		local screen = ScreenState.current()
		if screen == "dead" then
			local summary = vide.untrack(ScreenState.lastSummary)
			local causeKey = if summary then summary.CauseKey else "death.cause.unknown"
			local days = if summary then summary.Days else 0
			local points = if summary then summary.Points else 0
			local currency = if summary then summary.Currency else 0
			local xpGained = if summary then summary.Xp else 0
			local xpAfter = if summary then summary.XpTotal else 0
			local xpBefore = math.max(xpAfter - xpGained, 0)
			local levelAfter = LevelRules.progress(xpAfter).level
			Template.setText(xpLabel, Strings.format("death.xp", { xp = ProfileFormat.thousands(xpGained) }))
			if levelUpLabel then
				levelUpLabel.Visible = false
				levelUpLabel.Text = Strings.format("death.levelup", { level = levelAfter })
			end
			local leveledUp = levelAfter > LevelRules.progress(xpBefore).level
			showXp(xpBefore)
			-- Morte por jogador: o nome de quem matou no lugar da causa.
			local killerName = if summary then summary.KillerName else nil
			local cause = if killerName then killerName else Strings.get(causeKey)
			Template.setText(causeLabel, Strings.format("death.cause", { cause = cause }))
			Template.setText(daysLabel, Strings.format("death.days", { days = days }))
			TweenService:Create(effect, DESATURATE_INFO, { Saturation = -1 }):Play()

			stopCounting()
			showCount(points, 0)
			local started = os.clock()
			counting = RunService.RenderStepped:Connect(function()
				local elapsed = os.clock() - started
				showCount(CountUp.at(elapsed, COUNT_DURATION, points, currency))
				local t = math.clamp(elapsed / COUNT_DURATION, 0, 1)
				showXp(xpBefore + (xpAfter - xpBefore) * t)
				if elapsed >= COUNT_DURATION then
					stopCounting()
					if levelUpLabel and leveledUp then
						levelUpLabel.Visible = true
					end
				end
			end)
		else
			-- Saiu da morte (nasceu ou foi ao menu): a cor volta.
			stopCounting()
			if effect.Saturation ~= 0 then
				TweenService:Create(effect, RESTORE_INFO, { Saturation = 0 }):Play()
			end
		end
	end)

	gui.Parent = playerGui
	return gui
end

return DeathScreen
