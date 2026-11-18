--!strict
-- Onde fica cada peça da coluna da direita do HUD agora (quadrinho do tutorial,
-- receita fixada e avisos), para nenhuma cobrir a outra. A conta é de
-- Shared/UIFlow/HudColumn (testada); aqui só se lê o que está aparecendo.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local HudColumn = require(Shared:WaitForChild("UIFlow"):WaitForChild("HudColumn"))
local TutorialRules = require(Shared:WaitForChild("Tutorial"):WaitForChild("TutorialRules"))
local CrateState = require(script.Parent.Parent:WaitForChild("CrateState"))
local InteractState = require(script.Parent.Parent:WaitForChild("InteractState"))
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

-- Tela baixa com um painel alto aberto (peça de usar ou caixa, que sobem acima
-- dos anéis até o topo central): o tutorial e a receita fixada saem do caminho
-- até o jogador se afastar; os avisos passam por cima (12/11/2026).
function HudColumnState.yieldsToPanel(): boolean
	return ScreenMetrics.short() and (InteractState.near() ~= nil or CrateState.near() ~= nil)
end

-- Altura do quadrinho do tutorial (0 = não aparece).
function HudColumnState.tutorialHeight(): number
	if TutorialState.step() <= 0 or HudColumnState.yieldsToPanel() then
		return 0
	end
	return HudColumn.tutorialHeight(#HudColumnState.tutorialNeeds() > 0, ScreenMetrics.guiHeight())
end

-- Altura do painel da receita fixada (0 = nenhuma fixada).
function HudColumnState.pinnedHeight(): number
	if HudColumnState.yieldsToPanel() then
		return 0
	end
	return HudColumn.pinnedHeight(#PinState.lines(), ScreenMetrics.guiHeight())
end

-- Função comum (não derive): pode ser lida fora de um escopo do Vide; a conta é barata.
-- Topo da coluna: abaixo do livro, da engrenagem e das Missões (CornerLayout, em px).
local BELOW_BUTTONS = 10 -- px
-- Relógio (Clock.luau): 2% do topo, altura de 7,5% da tela ou o mínimo de 38 px.
local CLOCK_TOP = 0.02
local CLOCK_HEIGHT = 0.075
local CLOCK_MIN_PX = 38
local BELOW_CLOCK = 8 -- px

-- Tela baixa (celular deitado): a coluna vai para o topo central, embaixo do
-- relógio (12/11/2026). Na direita ela batia no botão das Missões e no
-- joystick de mirar, e o quadrinho do tutorial ficava cortado.
function HudColumnState.centered(): boolean
	return ScreenMetrics.short()
end

-- X e âncora das peças da coluna (direita no PC, centro na tela baixa).
function HudColumnState.x(): number
	return if HudColumnState.centered() then 0.5 else 0.98
end

function HudColumnState.anchor(): Vector2
	return if HudColumnState.centered() then Vector2.new(0.5, 0) else Vector2.new(1, 0)
end

function HudColumnState.column(): HudColumn.Column
	local height = ScreenMetrics.guiHeight()
	local top
	if HudColumnState.centered() then
		local clockBottom = CLOCK_TOP * height + math.max(CLOCK_HEIGHT * height, CLOCK_MIN_PX)
		top = (clockBottom + BELOW_CLOCK) / height
	else
		-- Abaixo da segunda fileira (o botão das Missões, embaixo da engrenagem,
		-- CornerLayout.secondRowPosition): antes o quadrinho cobria esse botão.
		local layout = CornerLayout.get()
		local gap = math.max(math.round(layout.buttonSize * 0.15), 4)
		top = (layout.buttonTop + 2 * layout.buttonSize + gap + BELOW_BUTTONS) / height
	end
	return HudColumn.compute(HudColumnState.tutorialHeight(), HudColumnState.pinnedHeight(), top)
end

return HudColumnState
