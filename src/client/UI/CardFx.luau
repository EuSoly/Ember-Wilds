--!strict
-- Cartões em camadas com efeitos animados (MonetizationImages, seção 5 da
-- lista de artes): base → halo pulsando → raios girando devagar → poucas
-- faíscas subindo e sumindo → moldura (centro transparente). O conteúdo do
-- cartão vai por cima (a pilha fica num Frame de ZIndex 0, e a tela usa
-- ZIndexBehavior.Sibling). Os efeitos vêm brancos e são tingidos por
-- ImageColor3.
--
-- Uma animação só para todas as peças: um RenderStepped que passa por todos
-- os cartões de um canal ativo (CardFx.run, ex. "shop" com a loja aberta). Sem
-- canal ativo a conexão é desligada; cartão destruído sai da lista.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local MonetizationImages = require(Shared:WaitForChild("MonetizationImages"))
local Rustic = require(script.Parent:WaitForChild("Rustic"))

local create = vide.create

local CardFx = {}

local RAY_SPEED = 360 / 20 -- graus por segundo: uma volta a cada 20 s
local RAY_TRANSPARENCY = 0.45
local HALO_PERIOD = 2.6 -- s de uma respiração do halo
local HALO_MIN, HALO_MAX = 0.35, 0.75 -- transparência do halo (mais e menos aceso)
local SPARK_COUNT = 3
local SPARK_SHARE = 0.13 -- lado da faísca no lado menor do cartão
local SPARK_PERIOD = { 2.4, 3.6 } -- s para uma faísca subir e sumir
local SPARK_FROM, SPARK_TO = 0.9, 0.18 -- altura (fração) em que nasce e some
local SPARK_KINDS = { "ember", "star4", "dot", "cross" }
local SHOWN_EVERY = 0.25 -- s entre duas leituras de "o cartão está à vista?"

type Spark = { image: ImageLabel, period: number, offset: number, x: number, last: number }
type Entry = {
	key: string,
	holder: GuiObject,
	rays: ImageLabel?,
	halo: ImageLabel?,
	sparks: { Spark },
	phase: number,
	alive: boolean,
	shown: boolean, -- o cartão e todos os pais visíveis (lido a cada SHOWN_EVERY)
}

local entries: { Entry } = {}
local activeKeys: { [string]: boolean } = {}
local connection: RBXScriptConnection? = nil
local clock = 0
local sinceShown = SHOWN_EVERY -- lê na primeira volta
local rng = Random.new()

local function anyActive(): boolean
	for _, on in activeKeys do
		if on then
			return true
		end
	end
	return false
end

-- O cartão e todos os pais até a ScreenGui estão visíveis? (Seção da loja ou
-- página escondida para os efeitos dela.)
local function onScreen(object: GuiObject): boolean
	local current: Instance? = object
	while current and not current:IsA("LayerCollector") do
		if current:IsA("GuiObject") and not (current :: GuiObject).Visible then
			return false
		end
		current = current.Parent
	end
	return current ~= nil
end

local function update(entry: Entry)
	local rays = entry.rays
	if rays then
		rays.Rotation = (clock * RAY_SPEED + entry.phase * 360) % 360
	end
	local halo = entry.halo
	if halo then
		local wave = (math.sin((clock / HALO_PERIOD + entry.phase) * 2 * math.pi) + 1) / 2
		halo.ImageTransparency = HALO_MAX - (HALO_MAX - HALO_MIN) * wave
	end
	for _, spark in entry.sparks do
		local t = ((clock + spark.offset) % spark.period) / spark.period
		if t < spark.last then
			-- Começou outra subida: nasce noutro ponto da largura.
			spark.x = rng:NextNumber(0.15, 0.85)
		end
		spark.last = t
		local alpha = if t < 0.2 then t / 0.2 elseif t > 0.6 then (1 - t) / 0.4 else 1
		local image = spark.image
		image.Position =
			UDim2.fromScale(spark.x + 0.03 * math.sin(t * 2 * math.pi), SPARK_FROM - (SPARK_FROM - SPARK_TO) * t)
		image.ImageTransparency = 1 - 0.85 * alpha
	end
end

local function step(dt: number)
	clock += dt
	sinceShown += dt
	local recheck = sinceShown >= SHOWN_EVERY
	if recheck then
		sinceShown = 0
	end
	for i = #entries, 1, -1 do
		local entry = entries[i]
		if not entry.alive then
			table.remove(entries, i)
		elseif activeKeys[entry.key] then
			if recheck then
				entry.shown = onScreen(entry.holder)
			end
			if entry.shown then
				update(entry)
			end
		end
	end
end

local function refresh()
	-- Tira da lista os cartões já destruídos.
	for i = #entries, 1, -1 do
		if not entries[i].alive then
			table.remove(entries, i)
		end
	end
	local wanted = #entries > 0 and anyActive()
	if wanted and not connection then
		connection = RunService.RenderStepped:Connect(step)
	elseif not wanted and connection then
		connection:Disconnect()
		connection = nil
	end
end

-- Liga a animação do canal `key` enquanto `active()` (chamar dentro de um
-- escopo do Vide, ex. no build da loja com a loja aberta).
function CardFx.run(key: string, active: () -> boolean)
	vide.effect(function()
		activeKeys[key] = active()
		sinceShown = SHOWN_EVERY -- relê o "à vista" logo na próxima volta
		refresh()
	end)
	vide.cleanup(function()
		activeKeys[key] = nil
		refresh()
	end)
end

export type LayersProps = {
	key: string, -- canal da animação ("shop", "checkin")
	base: string,
	frame: string,
	size: Vector2, -- tamanho da arte (para o SliceScale)
	slice: Rect,
	baseTint: Color3?, -- base neutra tingida (cartão genérico da loja)
	fx: Color3?, -- cor dos efeitos; nil = sem efeitos (só base e moldura)
	center: (UDim2 | () -> UDim2)?, -- centro dos raios e do halo (padrão 0.5, 0.4)
	visible: (() -> boolean)?,
	sliceShare: number?, -- fração do encaixe do SliceScale (moldura mais fina < 1)
}

-- Imagem quadrada de efeito (raios, halo), do lado menor do cartão.
local function square(name: string, image: string, color: Color3, center: UDim2 | () -> UDim2, z: number): ImageLabel
	return create("ImageLabel")({
		Name = name,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = center,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Image = image,
		ImageColor3 = color,
		ImageTransparency = RAY_TRANSPARENCY,
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = z,
		create("UIAspectRatioConstraint")({ AspectRatio = 1 }),
	}) :: ImageLabel
end

-- A pilha base → efeitos → moldura cobrindo o pai (ZIndex 0). Os efeitos só
-- entram se as artes deles existem.
function CardFx.layers(p: LayersProps): Frame
	local center = p.center or UDim2.fromScale(0.5, 0.4)
	local base = create("ImageLabel")({
		Name = "Base",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Image = p.base,
		ImageColor3 = p.baseTint or Color3.new(1, 1, 1),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = p.slice,
		ZIndex = 1,
	}) :: ImageLabel
	local frame = create("ImageLabel")({
		Name = "Frame",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Image = p.frame,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = p.slice,
		ZIndex = 5,
	}) :: ImageLabel
	Rustic.fitSlice(base, p.size, p.sliceShare)
	Rustic.fitSlice(frame, p.size, p.sliceShare)

	local holder = create("Frame")({
		Name = "Layers",
		Visible = p.visible or true,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		ZIndex = 0,
		base,
		frame,
	}) :: Frame

	local color = p.fx
	if not color then
		return holder
	end
	local entry: Entry = {
		key = p.key,
		holder = holder,
		rays = nil,
		halo = nil,
		sparks = {},
		phase = rng:NextNumber(),
		alive = true,
		shown = false,
	}
	if MonetizationImages.has(MonetizationImages.HALO) then
		local halo = square("Halo", MonetizationImages.HALO, color, center, 2)
		halo.Size = UDim2.fromScale(1.1, 1.1)
		halo.Parent = holder
		entry.halo = halo
	end
	if MonetizationImages.has(MonetizationImages.RAYS) then
		-- Os raios somem a 88% do raio do quadrado: girando, não passam do lado
		-- menor do cartão (o recorte não vale para peça girada).
		local rays = square("Rays", MonetizationImages.RAYS, color, center, 3)
		rays.Parent = holder
		entry.rays = rays
	end
	for i = 1, SPARK_COUNT do
		local id = MonetizationImages.SPARKS[SPARK_KINDS[(i - 1) % #SPARK_KINDS + 1]]
		if MonetizationImages.has(id) then
			local image = create("ImageLabel")({
				Name = "Spark",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, SPARK_FROM),
				Size = UDim2.fromScale(SPARK_SHARE, SPARK_SHARE),
				BackgroundTransparency = 1,
				Image = id,
				ImageColor3 = color:Lerp(Color3.new(1, 1, 1), 0.35),
				ImageTransparency = 1,
				ScaleType = Enum.ScaleType.Fit,
				ZIndex = 4,
				create("UIAspectRatioConstraint")({ AspectRatio = 1 }),
				Parent = holder,
			}) :: ImageLabel
			local period = rng:NextNumber(SPARK_PERIOD[1], SPARK_PERIOD[2])
			table.insert(entry.sparks, {
				image = image,
				period = period,
				offset = period * (i - 1) / SPARK_COUNT,
				x = rng:NextNumber(0.15, 0.85),
				last = 0,
			})
		end
	end
	table.insert(entries, entry)
	holder.Destroying:Connect(function()
		entry.alive = false
		refresh()
	end)
	refresh()
	return holder
end

return CardFx
