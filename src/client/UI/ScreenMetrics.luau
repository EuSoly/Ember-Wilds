--!strict
-- Tamanho da tela para as janelas do menu: `short()` é true em tela baixa
-- (celular deitado). As janelas (Perfil, Cosméticos, Configurações) usam quase
-- toda a altura e trocam o Fechar de baixo por um X no canto (10/11/2026). O
-- limite é o mesmo do CosmeticsLayout.SHORT_HEIGHT.
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

function ScreenMetrics.short(): boolean
	return size().Y < CosmeticsLayout.SHORT_HEIGHT
end

-- Altura da janela (escala da tela) para o padrão das janelas do menu.
function ScreenMetrics.windowShare(): number
	return if ScreenMetrics.short() then ScreenMetrics.SHORT_WINDOW_SHARE else ScreenMetrics.WINDOW_SHARE
end

return ScreenMetrics
