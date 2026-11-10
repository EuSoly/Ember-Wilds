--!strict
-- Onde fica cada peça da coluna da direita do HUD agora (quadrinho do tutorial,
-- receita fixada e avisos), para nenhuma cobrir a outra. A conta é de
-- Shared/UIFlow/HudColumn (testada); aqui só se lê o que está aparecendo.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local HudColumn = require(Shared:WaitForChild("UIFlow"):WaitForChild("HudColumn"))
local TutorialRules = require(Shared:WaitForChild("Tutorial"):WaitForChild("TutorialRules"))
local PinState = require(script.Parent.Parent:WaitForChild("PinState"))
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
	return if #HudColumnState.tutorialNeeds() > 0 then HudColumn.TUTORIAL_HEIGHT_NEEDS else HudColumn.TUTORIAL_HEIGHT
end

-- Altura do painel da receita fixada (0 = nenhuma fixada).
function HudColumnState.pinnedHeight(): number
	return HudColumn.pinnedHeight(#PinState.lines())
end

-- Função comum (não derive): pode ser lida fora de um escopo do Vide; a conta é barata.
function HudColumnState.column(): HudColumn.Column
	return HudColumn.compute(HudColumnState.tutorialHeight(), HudColumnState.pinnedHeight())
end

return HudColumnState
