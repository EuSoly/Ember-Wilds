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
--     No Mítico (reveal.mystic), no lugar do confete: círculo mágico com
--     runas girando atrás, aura respirando, explosão de luzinhas e vaga-lumes
--     subindo enquanto a janelinha estiver aberta (combina com o som etéreo).
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
-- Mítico (místico)
local VIOLET = Color3.fromHex("#8B5CF6")
local CIRCLE_SIZE = 560 -- px do círculo mágico
local CIRCLE_SPEED = 14 -- graus por segundo (os anéis giram em sentidos opostos)
local RUNE_COUNT = 12
local AURA_INFO = TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local CIRCLE_IN = TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local BURST_COUNT = 28 -- luzinhas que saem da janelinha quando ela abre
local MOTE_EVERY = 0.09 -- s entre dois vaga-lumes novos
local MOTE_DRAG = 2.2 -- quanto a explosão freia por segundo

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

-- Luzinha do Mítico: uma bolinha com halo que pisca de leve. `base` é o ponto
-- de partida (UDim2 no overlay); x/y são o deslocamento em px a partir dele.
type Mote = {
	frame: Frame,
	base: UDim2,
	x: number,
	y: number,
	vx: number,
	vy: number,
	drag: number,
	age: number,
	life: number,
	phase: number,
	sway: number,
}

local function moteColor(color: Color3): Color3
	local pick = math.random(4)
	return if pick == 1
		then color:Lerp(WHITE, 0.35)
		elseif pick == 2 then VIOLET:Lerp(WHITE, 0.3)
		elseif pick == 3 then PINK
		else WHITE
end

local function newMote(overlay: GuiObject, base: UDim2, color: Color3, zIndex: number): Mote
	local size = 5 + math.random() * 9
	local frame = Instance.new("Frame")
	frame.Name = "Mote"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = base
	frame.Size = UDim2.fromOffset(size, size)
	frame.BackgroundColor3 = moteColor(color)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.ZIndex = zIndex
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = frame
	local halo = Instance.new("UIStroke")
	halo.Color = frame.BackgroundColor3
	halo.Thickness = size * 0.6
	halo.Transparency = 1
	halo.Parent = frame
	frame.Parent = overlay
	return {
		frame = frame,
		base = base,
		x = 0,
		y = 0,
		vx = 0,
		vy = 0,
		drag = 0,
		age = 0,
		life = 1,
		phase = math.random() * math.pi * 2,
		sway = 6 + math.random() * 14,
	}
end

-- Um anel fino (fração `scale` do círculo) com a borda que aparece aos poucos.
local function circleRing(parent: Instance, scale: number, color: Color3, thickness: number, zIndex: number): Frame
	local frame = Instance.new("Frame")
	frame.Name = "MagicRing"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.fromScale(scale, scale)
	frame.BackgroundTransparency = 1
	frame.ZIndex = zIndex
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.Transparency = 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = frame
	TweenService:Create(stroke, CIRCLE_IN, { Transparency = 0.25 }):Play()
	frame.Parent = parent
	return frame
end

-- Comemoração mística do Mítico: círculo mágico atrás da janelinha, aura
-- respirando, explosão de luzinhas e vaga-lumes subindo até a janelinha fechar.
local function mystic(overlay: GuiObject, popup: GuiObject, color: Color3)
	local behind = math.max(popup.ZIndex - 1, 1)
	local light = color:Lerp(WHITE, 0.45)

	local circle = Instance.new("Frame")
	circle.Name = "MagicCircle"
	circle.AnchorPoint = Vector2.new(0.5, 0.5)
	circle.Position = popup.Position
	circle.Size = UDim2.fromOffset(CIRCLE_SIZE, CIRCLE_SIZE)
	circle.BackgroundTransparency = 1
	circle.ZIndex = behind
	local grow = Instance.new("UIScale")
	grow.Scale = 0.55
	grow.Parent = circle
	TweenService:Create(grow, CIRCLE_IN, { Scale = 1 }):Play()

	-- Aura: um disco na cor do Mítico puxada para o violeta, respirando.
	local aura = Instance.new("Frame")
	aura.Name = "Aura"
	aura.AnchorPoint = Vector2.new(0.5, 0.5)
	aura.Position = UDim2.fromScale(0.5, 0.5)
	aura.Size = UDim2.fromScale(0.8, 0.8)
	aura.BackgroundColor3 = color:Lerp(VIOLET, 0.45)
	aura.BackgroundTransparency = 0.82
	aura.BorderSizePixel = 0
	aura.ZIndex = behind
	local auraCorner = Instance.new("UICorner")
	auraCorner.CornerRadius = UDim.new(1, 0)
	auraCorner.Parent = aura
	local auraFade = Instance.new("UIGradient")
	auraFade.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.6),
		NumberSequenceKeypoint.new(0.5, 0),
		NumberSequenceKeypoint.new(1, 0.6),
	})
	auraFade.Parent = aura
	aura.Parent = circle
	local breathe =
		TweenService:Create(aura, AURA_INFO, { BackgroundTransparency = 0.6, Size = UDim2.fromScale(0.92, 0.92) })
	breathe:Play()

	-- Brilho suave por fora do anel: um anel largo e bem transparente.
	local glow = circleRing(circle, 1.02, color:Lerp(VIOLET, 0.3), 14, behind)
	local glowStroke = glow:FindFirstChildOfClass("UIStroke")
	if glowStroke then
		TweenService:Create(glowStroke, CIRCLE_IN, { Transparency = 0.8 }):Play()
	end

	-- Anel de fora com as runas (losangos vazados e pontinhos), girando para um
	-- lado; os dois de dentro giram para o outro.
	local outer = circleRing(circle, 1, light, 3, behind)
	for i = 1, RUNE_COUNT do
		local angle = (i - 1) * 360 / RUNE_COUNT
		local rad = math.rad(angle)
		local rune = Instance.new("Frame")
		rune.Name = "Rune"
		rune.AnchorPoint = Vector2.new(0.5, 0.5)
		rune.Position = UDim2.fromScale(0.5 + 0.5 * math.sin(rad), 0.5 - 0.5 * math.cos(rad))
		local big = i % 2 == 1
		rune.Size = if big then UDim2.fromOffset(16, 16) else UDim2.fromOffset(7, 7)
		rune.Rotation = 45 + angle
		rune.BackgroundColor3 = if big then color:Lerp(VIOLET, 0.3) else WHITE
		rune.BackgroundTransparency = 1
		rune.BorderSizePixel = 0
		rune.ZIndex = behind
		local stroke = Instance.new("UIStroke")
		stroke.Color = if big then WHITE else light
		stroke.Thickness = 2
		stroke.Transparency = 1
		stroke.Parent = rune
		TweenService:Create(rune, CIRCLE_IN, { BackgroundTransparency = if big then 0.35 else 0.1 }):Play()
		TweenService:Create(stroke, CIRCLE_IN, { Transparency = 0.2 }):Play()
		rune.Parent = outer
	end
	local inner = Instance.new("Frame")
	inner.Name = "Inner"
	inner.AnchorPoint = Vector2.new(0.5, 0.5)
	inner.Position = UDim2.fromScale(0.5, 0.5)
	inner.Size = UDim2.fromScale(1, 1)
	inner.BackgroundTransparency = 1
	inner.ZIndex = behind
	inner.Parent = circle
	circleRing(inner, 0.86, VIOLET:Lerp(WHITE, 0.4), 2, behind)
	circleRing(inner, 0.8, light, 1, behind)
	-- Estrela de seis pontas dentro do anel de 0,8: dois triângulos, cada lado
	-- uma corda do círculo (a uma distância de meio raio do centro).
	local radius = 0.4
	for i = 0, 5 do
		local angle = i * 60
		local rad = math.rad(angle)
		local line = Instance.new("Frame")
		line.Name = "Line"
		line.AnchorPoint = Vector2.new(0.5, 0.5)
		line.Position = UDim2.fromScale(0.5 + radius / 2 * math.sin(rad), 0.5 - radius / 2 * math.cos(rad))
		line.Size = UDim2.new(radius * math.sqrt(3), 0, 0, 2)
		line.Rotation = angle
		line.BackgroundColor3 = light
		line.BackgroundTransparency = 1
		line.BorderSizePixel = 0
		line.ZIndex = behind
		TweenService:Create(line, CIRCLE_IN, { BackgroundTransparency = 0.6 }):Play()
		line.Parent = inner
	end
	circle.Parent = overlay

	-- Explosão: luzinhas saem do centro da janelinha para todos os lados e
	-- freiam; depois só sobem devagar.
	local motes: { Mote } = {}
	for _ = 1, BURST_COUNT do
		local mote = newMote(overlay, popup.Position, color, 46)
		local angle = math.random() * math.pi * 2
		local speed = 260 + math.random() * 260
		mote.vx, mote.vy = math.cos(angle) * speed, math.sin(angle) * speed
		mote.drag = MOTE_DRAG
		mote.life = 1.6 + math.random() * 1.2
		table.insert(motes, mote)
	end

	local clock, sinceMote = 0, 0
	local connection: RBXScriptConnection
	connection = RunService.RenderStepped:Connect(function(dt)
		if not overlay.Visible or popup.Parent == nil or circle.Parent == nil then
			connection:Disconnect()
			breathe:Cancel()
			circle:Destroy()
			for _, mote in motes do
				mote.frame:Destroy()
			end
			table.clear(motes)
			return
		end
		clock += dt
		outer.Rotation = (outer.Rotation + CIRCLE_SPEED * dt) % 360
		inner.Rotation = (inner.Rotation - CIRCLE_SPEED * 1.6 * dt) % 360

		-- Vaga-lumes: nascem embaixo, em qualquer ponto, e sobem balançando.
		sinceMote += dt
		while sinceMote >= MOTE_EVERY do
			sinceMote -= MOTE_EVERY
			local mote = newMote(overlay, UDim2.fromScale(0.08 + math.random() * 0.84, 1.03), color, 46)
			mote.vy = -(45 + math.random() * 55)
			mote.life = 3 + math.random() * 2.5
			table.insert(motes, mote)
		end

		for i = #motes, 1, -1 do
			local mote = motes[i]
			mote.age += dt
			if mote.age >= mote.life then
				mote.frame:Destroy()
				table.remove(motes, i)
				continue
			end
			local slow = math.exp(-mote.drag * dt)
			mote.vx *= slow
			-- A explosão freia até ficar subindo devagar como os outros.
			mote.vy = mote.vy * slow + (1 - slow) * -30
			mote.x += mote.vx * dt
			mote.y += mote.vy * dt
			local swing = math.sin(mote.age * 2 + mote.phase) * mote.sway
			mote.frame.Position = mote.base + UDim2.fromOffset(mote.x + swing, mote.y)
			-- Acende rápido, some devagar no fim e pisca de leve.
			local fadeIn = math.min(mote.age / 0.25, 1)
			local fadeOut = math.min((mote.life - mote.age) / (mote.life * 0.4), 1)
			local twinkle = 0.75 + 0.25 * math.sin(mote.age * 9 + mote.phase)
			local alpha = fadeIn * fadeOut * twinkle
			mote.frame.BackgroundTransparency = 1 - alpha * 0.95
			local halo = mote.frame:FindFirstChildOfClass("UIStroke")
			if halo then
				halo.Transparency = 1 - alpha * 0.3
			end
		end
	end)
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
	if reveal.mystic then
		-- Mítico: o círculo mágico e as luzinhas no lugar dos raios e do confete.
		mystic(overlay, popup, color)
		return
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
