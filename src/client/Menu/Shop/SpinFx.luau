--!strict
-- Efeitos da tela do giro (o quanto de cada um vem de SpinRules.revealFor e
-- SpinRules.confettiFor, na medida da raridade):
--   start(box, window) — só no giro pago: raios de luz girando atrás da
--     janela, borda brilhando e pulsando, borda colorida correndo no
--     carrossel, marcador piscando e faíscas atravessando as skins. Devolve a
--     função que para e limpa tudo.
--   tick(window) — um quadradinho passou: o marcador dá um "tranco".
--   land(box, window, tile, rarity, paid) — o carrossel parou: tremidinha, o
--     resto do carrossel escurece e o prêmio ganha uma borda pulsando na cor
--     da raridade. Devolve a função que desfaz o destaque.
--   celebrate(popup, rarity, paid) — a janelinha do prêmio abriu: ela "pula"
--     (cresce com um quique), ganha a borda na cor da raridade, clarão, raios
--     girando atrás, onda de choque e confete puxado para a cor da raridade.
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
local MARKER_WIDTH = 4 -- px do marcador parado (igual ao da SpinScreen)
local MARKER_KICK = 10 -- px no tranco
local KICK_INFO = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local KICK_GAP = 0.04 -- s mínimos entre dois trancos (no começo passam muitos)
local DIM = 0.45 -- transparência do escuro sobre os vizinhos do prêmio
local DIM_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local PULSE_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local POP_INFO = TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local POP_FROM = 0.6
local FLASH_INFO = TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local RING_INFO = TweenInfo.new(0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local SHAKE_PATTERN = { Vector2.new(-1, 0.5), Vector2.new(0.9, -0.6), Vector2.new(-0.5, 0.4), Vector2.new(0.4, 0) }

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

local function rarityColor(rarity: number): Color3
	return Color3.fromHex(MockStore.RARITIES[math.clamp(rarity, 1, #MockStore.RARITIES)].color)
end

-- Tranco do marcador a cada quadradinho que passa: engrossa e volta.
local lastKick = 0
function SpinFx.tick(window: GuiObject)
	local now = os.clock()
	if now - lastKick < KICK_GAP then
		return
	end
	lastKick = now
	local marker = window:FindFirstChild("Marker") :: GuiObject?
	if marker == nil then
		return
	end
	marker.Size = UDim2.new(0, MARKER_KICK, 1, 0)
	TweenService:Create(marker, KICK_INFO, { Size = UDim2.new(0, MARKER_WIDTH, 1, 0) }):Play()
end

function SpinFx.land(box: GuiObject, window: GuiObject, tile: GuiObject, rarity: number, paid: boolean): () -> ()
	local reveal = SpinRules.revealFor(rarity, paid)
	-- Tremidinha: alguns deslocamentos curtos e volta ao lugar.
	if reveal.shake > 0 then
		local home = box.Position
		task.spawn(function()
			for _, shake in SHAKE_PATTERN do
				box.Position = home + UDim2.fromOffset(shake.X * reveal.shake, shake.Y * reveal.shake)
				task.wait(0.05)
			end
			box.Position = home
		end)
	end
	-- Escurece o carrossel dos dois lados do prêmio (em fração da janela: vale
	-- com qualquer escala da interface).
	local made: { Instance } = {}
	local width = math.max(window.AbsoluteSize.X, 1)
	local left = (tile.AbsolutePosition.X - window.AbsolutePosition.X) / width
	local right = left + tile.AbsoluteSize.X / width
	for _, span in { { 0, left }, { right, 1 } } do
		local dim = Instance.new("Frame")
		dim.Name = "Dim"
		dim.Position = UDim2.fromScale(span[1], 0)
		dim.Size = UDim2.fromScale(math.max(span[2] - span[1], 0), 1)
		dim.BackgroundColor3 = Color3.new(0, 0, 0)
		dim.BackgroundTransparency = 1
		dim.BorderSizePixel = 0
		dim.ZIndex = 9
		dim.Parent = window
		TweenService:Create(dim, DIM_INFO, { BackgroundTransparency = DIM }):Play()
		table.insert(made, dim)
	end
	-- Borda pulsando no prêmio, na cor da raridade.
	local glow = Instance.new("Frame")
	glow.Name = "PrizeGlow"
	glow.Size = UDim2.fromScale(1, 1)
	glow.BackgroundTransparency = 1
	glow.ZIndex = 8
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.1, 0)
	corner.Parent = glow
	local stroke = Instance.new("UIStroke")
	stroke.Color = rarityColor(rarity):Lerp(WHITE, 0.25)
	stroke.Thickness = 3
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = glow
	glow.Parent = tile
	table.insert(made, glow)
	local pulse = TweenService:Create(stroke, PULSE_INFO, { Thickness = 7, Color = WHITE })
	pulse:Play()

	local marker = window:FindFirstChild("Marker") :: GuiObject?
	if marker then
		marker.Visible = false -- o prêmio aparece inteiro, sem o risco no meio
	end

	local undone = false
	return function()
		if undone then
			return
		end
		undone = true
		pulse:Cancel()
		for _, instance in made do
			instance:Destroy()
		end
		if marker then
			marker.Visible = true
		end
	end
end

-- Clarão na cor da raridade (puxada para o branco), que some sozinho.
local function flash(overlay: GuiObject, color: Color3, opacity: number)
	local frame = Instance.new("Frame")
	frame.Name = "Flash"
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = color:Lerp(WHITE, 0.5)
	frame.BackgroundTransparency = 1 - opacity
	frame.BorderSizePixel = 0
	frame.ZIndex = 40
	frame.Parent = overlay
	local fade = TweenService:Create(frame, FLASH_INFO, { BackgroundTransparency = 1 })
	fade.Completed:Once(function()
		frame:Destroy()
	end)
	fade:Play()
end

-- Onda de choque: um anel que cresce a partir do centro da janelinha e some.
local function ring(overlay: GuiObject, popup: GuiObject, color: Color3)
	local frame = Instance.new("Frame")
	frame.Name = "Ring"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = popup.Position
	frame.Size = UDim2.fromOffset(160, 160)
	frame.BackgroundTransparency = 1
	frame.ZIndex = math.max(popup.ZIndex - 1, 1)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Color = color:Lerp(WHITE, 0.3)
	stroke.Thickness = 14
	stroke.Transparency = 0.1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = frame
	frame.Parent = overlay
	local grow = TweenService:Create(frame, RING_INFO, { Size = UDim2.fromOffset(820, 820) })
	TweenService:Create(stroke, RING_INFO, { Transparency = 1, Thickness = 2 }):Play()
	grow.Completed:Once(function()
		frame:Destroy()
	end)
	grow:Play()
end

function SpinFx.celebrate(popup: GuiObject, rarity: number, paid: boolean)
	local overlay = popup.Parent :: GuiObject
	local reveal = SpinRules.revealFor(rarity, paid)
	local color = rarityColor(rarity)

	-- A janelinha "pula": nasce menor e cresce com um quique.
	local pop = popup:FindFirstChild("Pop") :: UIScale?
	if pop == nil then
		local created = Instance.new("UIScale")
		created.Name = "Pop"
		created.Parent = popup
		pop = created
	end
	if pop then
		pop.Scale = POP_FROM
		TweenService:Create(pop, POP_INFO, { Scale = 1 }):Play()
	end
	-- Borda na cor da raridade (Comum fica com o dourado de sempre).
	local border = strokeOf(popup)
	if border then
		border.Color = if rarity >= 2 then color else GOLD
	end

	if reveal.flash > 0 then
		flash(overlay, color, reveal.flash)
	end
	if reveal.ring then
		ring(overlay, popup, color)
	end
	if reveal.rays then
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
	end

	-- Confete: metade na cor da raridade, o resto colorido.
	local count = SpinRules.confettiFor(rarity, paid)
	for i = 1, count do
		local piece = Instance.new("Frame")
		piece.Name = "Confetti"
		piece.AnchorPoint = Vector2.new(0.5, 0.5)
		piece.Position = UDim2.fromScale(math.random(), -0.05)
		piece.Size = UDim2.fromOffset(9, 14)
		piece.Rotation = math.random(0, 360)
		piece.BackgroundColor3 = if i % 2 == 0 then color else CONFETTI_COLORS[(i // 2) % #CONFETTI_COLORS + 1]
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
