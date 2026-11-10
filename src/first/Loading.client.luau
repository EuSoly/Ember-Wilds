--!strict
-- Tela de carregamento (LocalScript em ReplicatedFirst: roda antes de tudo).
-- Tira o carregamento padrão do Roblox, mostra o molde LoadingScreen (irmão
-- deste script) e espera o jogo carregar, o servidor marcar o perfil como
-- pronto (atributo DataReady do Player) e as artes baixarem (AssetPreload:
-- a barra mostra "Carregando artes 312/1.730"). Então some com fade e se destrói.
-- As artes esperam no máximo ASSET_WAIT_MAX; com o perfil pronto, aparece o
-- botão Pular. Em qualquer dos dois casos o resto continua baixando em
-- segundo plano.
--
-- Um sol anda junto com a ponta da barra; na metade vira lua, o céu escurece
-- (Night) e a barra fica azul-noite. As contas ficam em LoadingMath.
--
-- Elementos do molde (todos opcionais; o que faltar só deixa de animar):
-- Root (CanvasGroup, fade), Art (ImageLabel: a arte de fundo), Night
-- (CanvasGroup do céu noturno), Track (trilho de madeira), Fill (a barra),
-- Sun e Moon (ImageLabel; sem imagem viram um círculo), StatusLabel.
-- Os textos ficam fixos aqui e no molde: o Strings ainda não chegou ao cliente.
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local LoadingMath = require(script.Parent:WaitForChild("LoadingMath"))

local FINISH_PAUSE = 0.2
local ASSET_WAIT_MAX = 60 -- s no máximo esperando as artes (depois, o resto vai em segundo plano)
local FADE_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local NIGHT_INFO = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- Cores do design system (Palette.rustic), repetidas aqui porque a Palette
-- fica no ReplicatedStorage, que ainda não chegou.
local DAY_FILL = Color3.fromHex("#E99843") -- ember
local NIGHT_FILL = Color3.fromHex("#5B6FC4") -- night
local DAY_TRACK = Color3.fromHex("#59402D") -- walnut
local NIGHT_TRACK = Color3.fromHex("#2E2A3A") -- madeira à noite (mais escura e fria)
local SUN_FALLBACK = Color3.fromHex("#FFC66B")
local MOON_FALLBACK = Color3.fromHex("#9FB6FF")

ReplicatedFirst:RemoveDefaultLoadingScreen()

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local gui = script.Parent:WaitForChild("LoadingScreen"):Clone() :: ScreenGui
gui.ResetOnSpawn = false
gui.Parent = playerGui

local function find<T>(name: string, className: string): T?
	local instance = gui:FindFirstChild(name, true)
	if instance and instance:IsA(className) then
		return instance :: any
	end
	return nil
end

local fill = find("Fill", "GuiObject") :: GuiObject?
local track = find("Track", "GuiObject") :: GuiObject?
local night = find("Night", "CanvasGroup") :: CanvasGroup?
local sun = find("Sun", "ImageLabel") :: ImageLabel?
local moon = find("Moon", "ImageLabel") :: ImageLabel?
local status = find("StatusLabel", "TextLabel") :: TextLabel?

-- Imagem ainda sem id (ou que falhou): mostra um círculo da mesma cor.
local function fallbackCircle(orb: ImageLabel?, color: Color3)
	if orb == nil or orb.Image ~= "" then
		return
	end
	orb.BackgroundTransparency = 0
	orb.BackgroundColor3 = color
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = orb
end
fallbackCircle(sun, SUN_FALLBACK)
fallbackCircle(moon, MOON_FALLBACK)

local function tween(instance: Instance?, goal: { [string]: any })
	if instance then
		TweenService:Create(instance, NIGHT_INFO, goal):Play()
	end
end

-- Troca dia ↔ noite (só quando muda, com transição curta).
local isNight = false
local function setNight(value: boolean)
	if value == isNight then
		return
	end
	isNight = value
	tween(night, { GroupTransparency = if value then 0 else 1 })
	tween(fill, { BackgroundColor3 = if value then NIGHT_FILL else DAY_FILL })
	tween(track, { BackgroundColor3 = if value then NIGHT_TRACK else DAY_TRACK })
	if sun then
		sun.Visible = not value
	end
	if moon then
		moon.Visible = value
	end
end

-- Carregador das artes (chega quando o ReplicatedStorage chegar).
local preloader: any = nil

local function render(progress: number)
	if fill then
		fill.Size = UDim2.new(progress, 0, fill.Size.Y.Scale, fill.Size.Y.Offset)
	end
	-- Sol e lua na ponta da barra.
	for _, orb in { sun, moon } do
		if orb then
			orb.Position = UDim2.new(progress, 0, orb.Position.Y.Scale, orb.Position.Y.Offset)
		end
	end
	setNight(LoadingMath.isNight(progress))
	if status then
		status.Text = if preloader
				and preloader.counting()
				and progress < 1
			then LoadingMath.assetStatus(preloader.loaded(), preloader.total())
			else LoadingMath.status(progress)
	end
end

-- Botão Pular: aparece quando o perfil está pronto e só faltam as artes.
local skipped = false
local skip = Instance.new("TextButton")
skip.Name = "SkipButton"
skip.Visible = false
skip.AnchorPoint = Vector2.new(1, 1)
skip.Position = UDim2.new(1, -24, 1, -24)
skip.Size = UDim2.fromOffset(150, 52)
skip.BackgroundColor3 = DAY_FILL
skip.Text = "Pular"
skip.FontFace = Font.fromEnum(Enum.Font.FredokaOne)
skip.TextSize = 28
skip.TextColor3 = Color3.fromHex("#29241F") -- charcoal
skip.AutoButtonColor = true
skip.ZIndex = 50
local skipCorner = Instance.new("UICorner")
skipCorner.CornerRadius = UDim.new(0, 12)
skipCorner.Parent = skip
local skipStroke = Instance.new("UIStroke")
skipStroke.Color = Color3.fromHex("#211A15") -- outline
skipStroke.Thickness = 3
skipStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
skipStroke.Parent = skip
skip.Parent = gui:FindFirstChild("Root") or gui
skip.Activated:Connect(function()
	skipped = true
	skip.Visible = false
end)

-- A barra anda numa thread própria: o require abaixo espera o ReplicatedStorage chegar.
local ready = false
local done = false
task.spawn(function()
	local progress = 0
	render(progress)
	while progress < 1 do
		local target = if preloader and preloader.counting()
			then LoadingMath.assetTarget(preloader.loaded(), preloader.total())
			else nil
		progress = LoadingMath.step(progress, task.wait(), ready, target)
		render(progress)
	end
	done = true
end)

local Shared = ReplicatedStorage:WaitForChild("Shared")
local StatNames = require(Shared:WaitForChild("StatNames"))
preloader = require(Shared:WaitForChild("AssetPreload"):WaitForChild("AssetPreloader"))
preloader.start()
local assetsStarted = os.clock()

if not game:IsLoaded() then
	game.Loaded:Wait()
end
while player:GetAttribute(StatNames.DataReady) ~= true do
	player:GetAttributeChangedSignal(StatNames.DataReady):Wait()
end

-- Perfil pronto: espera as artes (com Pular e o tempo máximo).
while not preloader.finished() and not skipped and os.clock() - assetsStarted < ASSET_WAIT_MAX do
	skip.Visible = true
	task.wait(0.1)
end
skip.Visible = false

-- Pronto: a barra corre até o fim (passando pela lua) antes do fade.
ready = true
while not done do
	task.wait()
end
task.wait(FINISH_PAUSE)

local root = gui:FindFirstChild("Root")
if root and root:IsA("CanvasGroup") then
	local fade = TweenService:Create(root, FADE_INFO, { GroupTransparency = 1 })
	fade:Play()
	fade.Completed:Wait()
end
gui:Destroy()
