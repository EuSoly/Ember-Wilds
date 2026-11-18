--!strict
-- Tamanho da tela para as janelas do menu: `short()` é true em tela baixa
-- (celular deitado). As janelas (Perfil, Cosméticos, Configurações) usam quase
-- toda a altura e trocam o Fechar de baixo por um X no canto (10/11/2026). O
-- limite é o mesmo do CosmeticsLayout.SHORT_HEIGHT.
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local CosmeticsLayout =
	require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("UIFlow"):WaitForChild("CosmeticsLayout"))

local ScreenMetrics = {}

-- Fração da altura da tela que a janela usa (tela baixa usa mais).
ScreenMetrics.WINDOW_SHARE = 0.86
ScreenMetrics.SHORT_WINDOW_SHARE = 0.95

local size = vide.source(Vector2.new(1280, 720))

local function watch(camera: Camera?)
	if camera == nil then
		return
	end
	size(camera.ViewportSize)
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		size(camera.ViewportSize)
	end)
end
watch(Workspace.CurrentCamera)
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	watch(Workspace.CurrentCamera)
end)

function ScreenMetrics.size(): Vector2
	return size()
end

-- Altura da área das telas com ScreenInsets = CoreUISafeInsets (HUD, livro):
-- a tela sem a barra do Roblox em cima.
local topbar = vide.source(GuiService.TopbarInset.Height)
GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(function()
	topbar(GuiService.TopbarInset.Height)
end)

function ScreenMetrics.guiHeight(): number
	return math.max(size().Y - topbar(), 1)
end

function ScreenMetrics.short(): boolean
	return size().Y < CosmeticsLayout.SHORT_HEIGHT
end

-- Janelas por cima do menu (check-in, Presentear, presente recebido). No
-- celular baixo ficam entre a fileira de cima do menu (perfil e saldo, até
-- SHORT_MODAL_TOP px) e a borda de baixo: antes cobriam o perfil e o Fechar
-- encostava embaixo (teste de 18/11/2026). `titleHalf` = quanto a placa do
-- título passa da janela para cima. No PC: o centro e a fração de sempre.
ScreenMetrics.SHORT_MODAL_TOP = 54
ScreenMetrics.SHORT_MODAL_BOTTOM = 8

local function shortModal(titleHalf: number): (number, number)
	local top = ScreenMetrics.SHORT_MODAL_TOP + titleHalf
	local bottom = ScreenMetrics.guiHeight() - ScreenMetrics.SHORT_MODAL_BOTTOM
	return top, bottom
end

function ScreenMetrics.modalPosition(titleHalf: number): UDim2
	if ScreenMetrics.short() then
		local top, bottom = shortModal(titleHalf)
		return UDim2.new(0.5, 0, 0, (top + bottom) / 2)
	end
	return UDim2.new(0.5, 0, 0.5, titleHalf / 2)
end

function ScreenMetrics.modalSize(widthShare: number, titleHalf: number): UDim2
	if ScreenMetrics.short() then
		local top, bottom = shortModal(titleHalf)
		return UDim2.new(widthShare, 0, 0, bottom - top)
	end
	return UDim2.new(widthShare, 0, ScreenMetrics.windowShare(), -titleHalf)
end

-- Altura da janela (escala da tela) para o padrão das janelas do menu.
function ScreenMetrics.windowShare(): number
	return if ScreenMetrics.short() then ScreenMetrics.SHORT_WINDOW_SHARE else ScreenMetrics.WINDOW_SHARE
end

return ScreenMetrics
