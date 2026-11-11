--!strict
-- Onde fica cada peça da coluna da direita do HUD agora (quadrinho do tutorial,
-- receita fixada e avisos), para nenhuma cobrir a outra. A conta é de
-- Shared/UIFlow/HudColumn (testada); aqui só se lê o que está aparecendo.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local HudColumn = require(Shared:WaitForChild("UIFlow"):WaitForChild("HudColumn"))
local TutorialRules = require(Shared:WaitForChild("Tutorial"):WaitForChild("TutorialRules"))
local PinState = require(script.Parent.Parent:WaitForChild("PinState"))
local CornerLayout = require(script.Parent:WaitForChild("CornerLayout"))
local ScreenMetrics = require(script.Parent:WaitForChild("ScreenMetrics"))
local TutorialState = require(script.Parent.Parent:WaitForChild("TutorialState"))

local HudColumnState = {}

-- Itens que faltam pegar na etapa atual do tutorial (linha do quadrinho).
function HudColumnState.tutorialNeeds(): { TutorialRules.NeedProgress }
	local step = TutorialState.current()
	return if step then TutorialRules.needsProgress(step, TutorialState.counts()) else {}
end

-- Altura do quadrinho do tutorial (0 = não aparece).
function HudColumnState.tutorialHeight(): number
	if TutorialState.step() <= 0 then
		return 0
	end
	return HudColumn.tutorialHeight(#HudColumnState.tutorialNeeds() > 0, ScreenMetrics.guiHeight())
end

-- Altura do painel da receita fixada (0 = nenhuma fixada).
function HudColumnState.pinnedHeight(): number
	return HudColumn.pinnedHeight(#PinState.lines(), ScreenMetrics.guiHeight())
end

-- Função comum (não derive): pode ser lida fora de um escopo do Vide; a conta é barata.
-- Topo da coluna: logo abaixo do livro e da engrenagem (CornerLayout, em px).
local BELOW_BUTTONS = 10 -- px

function HudColumnState.column(): HudColumn.Column
	local layout = CornerLayout.get()
	local top = (layout.buttonTop + layout.buttonSize + BELOW_BUTTONS) / ScreenMetrics.guiHeight()
	return HudColumn.compute(HudColumnState.tutorialHeight(), HudColumnState.pinnedHeight(), top)
end

return HudColumnState
