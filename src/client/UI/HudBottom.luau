--!strict
-- Faixa de baixo do HUD, reativa (12/11/2026): onde ficam a hotbar, os anéis
-- de status, a trava da arma e os painéis que sobem acima dos anéis (baú,
-- caixa, peça de usar). A conta do toque é de Shared/UIFlow/HudLayout
-- (testada); no PC, o layout por escala de sempre.
--
-- Os painéis e a trava são filhos da hotbar (Hotbar.above), então as posições
-- abaixo são relativas a ela: X 0,5 = centro da hotbar, Y 0 = topo dela.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local HudLayout = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("UIFlow"):WaitForChild("HudLayout"))

local HudBottom = {}

-- No PC: anéis com 1,25 da altura da hotbar, 8 px acima dela (StatusRings).
local DESKTOP_RING_HEIGHT = 1.25
local DESKTOP_RING_WIDTH = 0.5

local touch = vide.source(UserInputService.PreferredInput == Enum.PreferredInput.Touch)
UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(function()
	touch(UserInputService.PreferredInput == Enum.PreferredInput.Touch)
end)

-- Área do HUD em px lógicos (já dividida pelo "Tamanho da interface").
local canvas = vide.source(Vector2.new(1280, 720))

-- Mede o ScreenGui do HUD (chamado pelo App depois do UIScale existir).
function HudBottom.bind(gui: ScreenGui)
	local scale = gui:FindFirstChildWhichIsA("UIScale")
	local function update()
		local s = if scale and scale.Scale > 0 then scale.Scale else 1
		canvas(gui.AbsoluteSize / s)
	end
	update()
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(update)
	if scale then
		scale:GetPropertyChangedSignal("Scale"):Connect(update)
	end
end

-- Topo da coluna de receitas (px lógicos), abaixo do selo de pontos.
function HudBottom.craftTop(): number
	local size = canvas()
	return HudLayout.craftTop(size.X, size.Y)
end

function HudBottom.touch(): boolean
	return touch()
end

-- Layout da hotbar no toque; nil no PC.
function HudBottom.hotbar(): HudLayout.Hotbar?
	if not touch() then
		return nil
	end
	local size = canvas()
	return HudLayout.touchHotbar(size.X, size.Y)
end

-- Bloco dos anéis (filho da hotbar).
function HudBottom.ringsSize(): UDim2
	if not touch() then
		return UDim2.fromScale(DESKTOP_RING_WIDTH, DESKTOP_RING_HEIGHT)
	end
	local w, h = HudLayout.ringsSize()
	return UDim2.fromOffset(w, h)
end

function HudBottom.ringsPosition(): UDim2
	return UDim2.new(0.5, 0, 0, -HudLayout.RINGS_LIFT)
end

-- Ponto (borda de baixo, centro) de um painel acima dos anéis, subindo mais
-- `offset` px (para empilhar painéis).
function HudBottom.above(offset: number): UDim2
	if not touch() then
		return UDim2.new(0.5, 0, -DESKTOP_RING_HEIGHT, -(HudLayout.RINGS_LIFT + HudLayout.PANEL_GAP + offset))
	end
	return UDim2.new(0.5, 0, 0, -(HudLayout.panelLift() + offset))
end

-- Ponto (borda direita, meio) logo à esquerda dos anéis: trava da arma.
function HudBottom.besideRings(): UDim2
	if not touch() then
		return UDim2.new(
			0.5 - DESKTOP_RING_WIDTH / 2,
			-HudLayout.PANEL_GAP,
			-DESKTOP_RING_HEIGHT / 2,
			-HudLayout.RINGS_LIFT
		)
	end
	local w, h = HudLayout.ringsSize()
	return UDim2.new(0.5, -(w / 2 + HudLayout.PANEL_GAP), 0, -(HudLayout.RINGS_LIFT + h / 2))
end

-- Ponto (borda esquerda, meio) logo à direita dos anéis, no toque: botão da
-- mochila (só existe no toque).
function HudBottom.rightOfRings(): UDim2
	local w, h = HudLayout.ringsSize()
	return UDim2.new(0.5, w / 2 + HudLayout.PANEL_GAP, 0, -(HudLayout.RINGS_LIFT + h / 2))
end

-- Lado do joystick de mirar (px), para quem precisa desviar dele.
function HudBottom.aimSize(): number
	return HudLayout.aimSize(canvas().Y)
end

HudBottom.MARGIN = HudLayout.MARGIN

return HudBottom
