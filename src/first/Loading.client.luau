--!strict
-- Tela de carregamento (LocalScript em ReplicatedFirst: roda antes de tudo).
-- Tira o carregamento padrão do Roblox, mostra o molde LoadingScreen (irmão
-- deste script) e espera o jogo carregar E o servidor marcar o perfil como
-- pronto (atributo DataReady do Player). Então some com fade e se destrói.
--
-- Os textos ficam fixos no molde: aqui o Strings ainda não chegou ao cliente.
-- Elementos usados (opcionais): "Fill" (barra de progresso) e o CanvasGroup "Root" (fade).
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- A barra anda sozinha até ~90% enquanto espera (não sabemos o progresso real)
-- e completa quando tudo estiver pronto.
local WAITING_TARGET = 0.9
local FILL_SPEED = 1.5
local FINISH_PAUSE = 0.2
local FADE_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

ReplicatedFirst:RemoveDefaultLoadingScreen()

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local gui = script.Parent:WaitForChild("LoadingScreen"):Clone() :: ScreenGui
gui.ResetOnSpawn = false
gui.Parent = playerGui

local fillInstance = gui:FindFirstChild("Fill", true)
local fill: GuiObject? = if fillInstance and fillInstance:IsA("GuiObject") then fillInstance else nil

local function setProgress(value: number)
	if fill then
		fill.Size = UDim2.new(value, 0, fill.Size.Y.Scale, fill.Size.Y.Offset)
	end
end

-- Barra animada numa thread própria: o require abaixo espera o ReplicatedStorage chegar.
local finished = false
task.spawn(function()
	local progress = 0
	setProgress(progress)
	while not finished do
		local dt = task.wait()
		progress += (WAITING_TARGET - progress) * math.min(dt * FILL_SPEED, 1)
		setProgress(progress)
	end
end)

local StatNames = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("StatNames"))

if not game:IsLoaded() then
	game.Loaded:Wait()
end
while player:GetAttribute(StatNames.DataReady) ~= true do
	player:GetAttributeChangedSignal(StatNames.DataReady):Wait()
end

finished = true
setProgress(1)
task.wait(FINISH_PAUSE)

local root = gui:FindFirstChild("Root")
if root and root:IsA("CanvasGroup") then
	local fade = TweenService:Create(root, FADE_INFO, { GroupTransparency = 1 })
	fade:Play()
	fade.Completed:Wait()
end
gui:Destroy()
