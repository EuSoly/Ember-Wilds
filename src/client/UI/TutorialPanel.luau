--!strict
-- Quadrinho da missão do tutorial, embaixo do minimapa e dos botões redondos:
-- "Tutorial N/6" e o que fazer agora, com o contador ("3/10") quando a etapa
-- conta itens. Na etapa de construir (Fogueira), uma linha com os itens que
-- faltam pegar, com ícone e "Madeira 12/25" (verde quando completa). Pisca dourado
-- quando muda de etapa. No fim, o aviso de parabéns com os giros ganhos
-- (Net.TutorialDone).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Defs = require(Shared:WaitForChild("Defs"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local HudColumn = require(Shared:WaitForChild("UIFlow"):WaitForChild("HudColumn"))
local TutorialRules = require(Shared:WaitForChild("Tutorial"):WaitForChild("TutorialRules"))
local TutorialSteps = require(Shared:WaitForChild("Tutorial"):WaitForChild("TutorialSteps"))
local Net = require(script.Parent.Parent:WaitForChild("Net"))
local TutorialState = require(script.Parent.Parent:WaitForChild("TutorialState"))
local Notifications = require(script.Parent:WaitForChild("Notifications"))
local HudColumnState = require(script.Parent:WaitForChild("HudColumnState"))
local ItemIcon = require(script.Parent:WaitForChild("ItemIcon"))
local Rustic = require(script.Parent:WaitForChild("Rustic"))

local create = vide.create
local R = Theme.rustic

-- Na coluna da direita (UI/HudColumnState): logo abaixo dos botões redondos.
local FLASH_TIME = 0.6
local DONE_COLOR = Color3.fromRGB(46, 140, 52) -- verde do "já tem tudo"

-- Um item da linha "o que pegar": ícone e "tem/precisa".
local function NeedEntry(entry: () -> TutorialRules.NeedProgress, index: number): Frame
	return create("Frame")({
		Name = "Need",
		LayoutOrder = index,
		Size = UDim2.fromScale(0.48, 1),
		BackgroundTransparency = 1,
		create("Frame")({
			Name = "IconBox",
			Size = UDim2.fromScale(1, 1),
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
			BackgroundTransparency = 1,
			ItemIcon({
				item = function()
					return { id = entry().item, count = 1 }
				end,
				bare = true,
			}),
		}),
		Rustic.label({
			Name = "Count",
			dark = true,
			maxSize = 14, -- teto igual para os itens (nome curto não fica maior)
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.fromScale(1, 0.12),
			Size = UDim2.fromScale(0.74, 0.76),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = function()
				return if entry().done then DONE_COLOR else R.charcoal
			end,
			Text = function()
				local e = entry()
				local def = Defs.Items[e.item]
				local name = if def then Strings.get(def.nameKey) else e.item
				return `{name} {e.have}/{e.need}`
			end,
		}),
	}) :: Frame
end

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

	local needs = vide.derive(HudColumnState.tutorialNeeds)
	local hasNeeds = function()
		return #needs() > 0
	end

	return Rustic.paper({
		Name = "TutorialPanel",
		AnchorPoint = Vector2.new(1, 0),
		Position = function()
			return UDim2.fromScale(0.98, HudColumnState.column().tutorialY)
		end,
		Size = function()
			return UDim2.fromScale(HudColumn.WIDTH, HudColumnState.tutorialHeight())
		end,
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
			Size = function()
				return UDim2.fromScale(1, if hasNeeds() then 0.26 else 0.38)
			end,
			TextColor3 = R.emberShadow,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = function()
				return Strings.format("tutorial.header", { step = TutorialState.step(), total = #TutorialSteps.LIST })
			end,
		}),
		Rustic.label({
			Name = "Step",
			dark = true,
			Position = function()
				return UDim2.fromScale(0, if hasNeeds() then 0.29 else 0.42)
			end,
			Size = function()
				return UDim2.fromScale(1, if hasNeeds() then 0.33 else 0.58)
			end,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = stepText,
		}),
		create("Frame")({
			Name = "Needs",
			Visible = hasNeeds,
			Position = UDim2.fromScale(0, 0.66),
			Size = UDim2.fromScale(1, 0.34),
			BackgroundTransparency = 1,
			create("UIListLayout")({
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0.04, 0),
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),
			vide.indexes(needs, NeedEntry),
		}),
	}) :: Frame
end

return TutorialPanel
