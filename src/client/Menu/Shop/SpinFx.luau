--!strict
-- Efeitos do giro pago (e a comemoração do prêmio), ligados na tela do giro:
--   start(box, window) — raios de luz girando atrás da janela, borda brilhando
--     e pulsando, borda colorida correndo no carrossel, marcador piscando e
--     faíscas atravessando as skins. Devolve a função que para e limpa tudo.
--   land(box) — clarão e tremidinha quando o carrossel para.
--   celebrate(popup, rarity, paid) — raios na cor da raridade atrás da
--     janelinha do prêmio e confete (quantidade em SpinRules.confettiFor).
-- Tudo some sozinho; nada fica rodando com a tela fechada.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MockStore = require(Shared:WaitForChild("UIFlow"):WaitForChild("MockStore"))
local SpinRules = require(Shared:WaitForChild("UIFlow"):WaitForChild("SpinRules"))
local Theme = require(Shared:WaitForChild("Theme"))

local PURPLE = Color3.fromHex("#B48CFF")
local GOLD = Theme.tier.gold
local PINK = Color3.fromHex("#FF6BD6")
local WHITE = Color3.new(1, 1, 1)
local RAY_COUNT = 14
local RAY_SPEED = 70 -- graus por segundo
local SPARK_EVERY = 0.05
local CONFETTI_COLORS = { GOLD, PURPLE, Color3.fromHex("#4DA3FF"), PINK, Color3.fromHex("#92B56A"), Theme.rustic.cream }

local SpinFx = {}

-- Leque de raios (retângulos finos girados) num quadrado transparente.
local function rays(parent: Instance, size: UDim2, colors: { Color3 }, zIndex: number): Frame
	local holder = Instance.new("Frame")
	holder.Name = "Rays"
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.fromScale(0.5, 0.5)
	holder.Size = size
	holder.BackgroundTransparency = 1
	holder.ZIndex = zIndex
	for i = 1, RAY_COUNT do
		-- O Roblox gira cada peça em volta do próprio centro: o centro do raio
		-- fica no meio do caminho entre o centro do leque e a borda.
		local angle = (i - 1) * 360 / RAY_COUNT
		local rad = math.rad(angle)
		local ray = Instance.new("Frame")
		ray.AnchorPoint = Vector2.new(0.5, 0.5)
		ray.Position = UDim2.fromScale(0.5 + 0.25 * math.sin(rad), 0.5 - 0.25 * math.cos(rad))
		ray.Size = UDim2.fromScale(0.07, 0.5)
		ray.Rotation = angle
		ray.BackgroundColor3 = colors[(i - 1) % #colors + 1]
		ray.BackgroundTransparency = 0.55
		ray.BorderSizePixel = 0
		ray.ZIndex = zIndex
		local fade = Instance.new("UIGradient")
		fade.Rotation = 90
		fade.Transparency = NumberSequence.new(1, 0.1) -- some na ponta de fora
		fade.Parent = ray
		ray.Parent = holder
	end
	holder.Parent = parent
	return holder
end

local function strokeOf(object: Instance): UIStroke?
	return object:FindFirstChildOfClass("UIStroke")
end

function SpinFx.start(box: GuiObject, window: GuiObject): () -> ()
	local parent = box.Parent :: Instance
	local behind = rays(parent, UDim2.fromScale(1.4, 1.4), { PURPLE, GOLD }, math.max(box.ZIndex - 1, 1))
	behind.SizeConstraint = Enum.SizeConstraint.RelativeXX
	-- Centro do leque no centro da janela (em fração do pai: vale com qualquer escala).
	local parentObject = parent :: GuiObject
	local center = box.AbsolutePosition + box.AbsoluteSize / 2 - parentObject.AbsolutePosition
	behind.Position = UDim2.fromScale(center.X / parentObject.AbsoluteSize.X, center.Y / parentObject.AbsoluteSize.Y)

	local boxStroke = strokeOf(box)
	local boxColor = if boxStroke then boxStroke.Color else WHITE
	local boxThickness = if boxStroke then boxStroke.Thickness else 0

	local windowStroke = strokeOf(window)
	local flow = Instance.new("UIGradient")
	flow.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, PURPLE),
		ColorSequenceKeypoint.new(0.33, GOLD),
		ColorSequenceKeypoint.new(0.66, PINK),
		ColorSequenceKeypoint.new(1, PURPLE),
	})
	local windowThickness = if windowStroke then windowStroke.Thickness else 0
	local windowColor = if windowStroke then windowStroke.Color else WHITE
	if windowStroke then
		windowStroke.Color = WHITE -- o UIGradient pinta por cima
		windowStroke.Thickness = 4
		flow.Parent = windowStroke
	end

	local marker = window:FindFirstChild("Marker") :: GuiObject?
	local markerColor = if marker then marker.BackgroundColor3 else GOLD

	local sparks: { GuiObject } = {}
	local clock, sinceSpark = 0, 0
	local connection = RunService.RenderStepped:Connect(function(dt)
		clock += dt
		behind.Rotation = (behind.Rotation + RAY_SPEED * dt) % 360
		if boxStroke then
			local pulse = (math.sin(clock * 7) + 1) / 2
			boxStroke.Color = PURPLE:Lerp(GOLD, pulse)
			boxStroke.Thickness = 4 + pulse * 4
		end
		flow.Offset = Vector2.new((clock * 1.5) % 2 - 1, 0)
		if marker then
			marker.BackgroundColor3 = if math.floor(clock * 8) % 2 == 0 then WHITE else GOLD
		end
		-- Faíscas: nascem em qualquer ponto e correm para a esquerda.
		sinceSpark += dt
		while sinceSpark >= SPARK_EVERY do
			sinceSpark -= SPARK_EVERY
			local spark = Instance.new("Frame")
			spark.Name = "Spark"
			spark.AnchorPoint = Vector2.new(0.5, 0.5)
			spark.Position = UDim2.fromScale(math.random(), math.random())
			spark.Size = UDim2.fromOffset(7, 7)
			spark.BackgroundColor3 = if math.random() < 0.5 then WHITE else GOLD
			spark.BorderSizePixel = 0
			spark.ZIndex = 12
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(1, 0)
			corner.Parent = spark
			spark.Parent = window
			table.insert(sparks, spark)
			local life = 0.5 + math.random() * 0.6
			TweenService
				:Create(spark, TweenInfo.new(life, Enum.EasingStyle.Linear), {
					Position = spark.Position
						+ UDim2.fromOffset(-(120 + math.random() * 160), (math.random() - 0.5) * 40),
					Size = UDim2.fromOffset(2, 2),
					BackgroundTransparency = 1,
				})
				:Play()
			task.delay(life, function()
				spark:Destroy()
			end)
		end
	end)

	local stopped = false
	return function()
		if stopped then
			return
		end
		stopped = true
		connection:Disconnect()
		behind:Destroy()
		for _, spark in sparks do
			spark:Destroy()
		end
		flow:Destroy()
		if boxStroke then
			boxStroke.Color = boxColor
			boxStroke.Thickness = boxThickness
		end
		if windowStroke then
			windowStroke.Color = windowColor
			windowStroke.Thickness = windowThickness
		end
		if marker then
			marker.BackgroundColor3 = markerColor
		end
	end
end

function SpinFx.land(box: GuiObject)
	local parent = box.Parent :: Instance
	local flash = Instance.new("Frame")
	flash.Name = "Flash"
	flash.Size = UDim2.fromScale(1, 1)
	flash.BackgroundColor3 = Color3.fromHex("#FFF3D6")
	flash.BackgroundTransparency = 0.15
	flash.BorderSizePixel = 0
	flash.ZIndex = 40
	flash.Parent = parent
	local fade = TweenService:Create(flash, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 1,
	})
	fade.Completed:Once(function()
		flash:Destroy()
	end)
	fade:Play()
	-- Tremidinha: alguns deslocamentos curtos e volta ao lugar.
	local home = box.Position
	task.spawn(function()
		for _, shake in { Vector2.new(-8, 4), Vector2.new(7, -5), Vector2.new(-4, 3), Vector2.new(3, 0) } do
			box.Position = home + UDim2.fromOffset(shake.X, shake.Y)
			task.wait(0.05)
		end
		box.Position = home
	end)
end

function SpinFx.celebrate(popup: GuiObject, rarity: number, paid: boolean)
	local overlay = popup.Parent :: GuiObject
	local count = SpinRules.confettiFor(rarity, paid)
	if count <= 0 then
		return
	end
	local color = Color3.fromHex(MockStore.RARITIES[rarity].color)
	-- Atrás da janelinha (irmão dela, com ZIndex menor), no mesmo centro.
	local glow = rays(overlay, UDim2.fromOffset(640, 640), { color, WHITE }, math.max(popup.ZIndex - 1, 1))
	glow.Position = popup.Position
	-- Os raios giram enquanto a janelinha estiver aberta.
	local connection: RBXScriptConnection
	connection = RunService.RenderStepped:Connect(function(dt)
		if not overlay.Visible or glow.Parent == nil then
			connection:Disconnect()
			glow:Destroy()
			return
		end
		glow.Rotation = (glow.Rotation + 35 * dt) % 360
	end)
	for i = 1, count do
		local piece = Instance.new("Frame")
		piece.Name = "Confetti"
		piece.AnchorPoint = Vector2.new(0.5, 0.5)
		piece.Position = UDim2.fromScale(math.random(), -0.05)
		piece.Size = UDim2.fromOffset(9, 14)
		piece.Rotation = math.random(0, 360)
		piece.BackgroundColor3 = CONFETTI_COLORS[(i - 1) % #CONFETTI_COLORS + 1]
		piece.BorderSizePixel = 0
		piece.ZIndex = 45
		piece.Parent = overlay
		local life = 1.4 + math.random() * 1.6
		local tween = TweenService:Create(piece, TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.fromScale(piece.Position.X.Scale + (math.random() - 0.5) * 0.3, 1.1),
			Rotation = piece.Rotation + math.random(-450, 450),
		})
		task.delay(math.random() * 0.4, function()
			tween:Play()
		end)
		task.delay(life + 0.5, function()
			piece:Destroy()
		end)
	end
end

return SpinFx
