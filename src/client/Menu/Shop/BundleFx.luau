--!strict
-- Camadas de ambiente dos banners dos pacotes (BundleBanner): luz, bolhas,
-- peixes, folhas, vaga-lumes, vento... Cada efeito tem o seu canto do banner,
-- em vez de tudo no meio: os de trás (z 1) ficam atrás dos itens, os da
-- frente (z 3) por cima. Posições em fração do banner; tamanhos em fração da
-- altura (o banner muda de largura entre PC e celular, a altura quase não).
-- Artes: os zips "banners da loja" do Elizeu (18/11/2026), recortadas em
-- assets/ui/shop/bundles/efeitos/. Os ids são da imagem (Texture do Decal
-- enviado pelo Open Cloud), não do Decal.

export type Pose = {
	x: number, -- centro, fração da largura
	y: number, -- centro, fração da altura
	alpha: number, -- 0 = some, 1 = cheio
	rotation: number?,
	scaleX: number?, -- borboleta batendo as asas
	scale: number?,
}

type Layer = {
	image: string,
	aspect: number, -- largura / altura da arte
	height: number, -- fração da altura do banner
	z: number,
	color: Color3?,
	anchor: Vector2?,
	pose: (t: number) -> Pose,
}

local ID = {
	mar_raios = "rbxassetid://88763727443294",
	mar_bolhas = "rbxassetid://103026020191233",
	mar_peixes = "rbxassetid://85503143942159",
	mar_agua_viva = "rbxassetid://80633320087517",
	mar_brilhos = "rbxassetid://72005939144551",
	mar_algas = "rbxassetid://109229003314706",
	bosque_raios = "rbxassetid://139755303162157",
	bosque_folhas = "rbxassetid://100547398611523",
	bosque_vagalumes = "rbxassetid://138982248939358",
	bosque_borboleta = "rbxassetid://111172954429838",
	bosque_cipos = "rbxassetid://84556758098458",
	bosque_neblina = "rbxassetid://129574251061570",
	norte_vento = "rbxassetid://106119162268102",
}

local TAU = math.pi * 2

-- 0..1 dentro de um ciclo de `period` segundos, com atraso `phase` (0..1).
local function cycle(t: number, period: number, phase: number?): number
	return (t / period + (phase or 0)) % 1
end

-- Aparece e some suave ao longo do ciclo (0 nas pontas, 1 no meio).
local function fade(p: number): number
	return math.sin(math.pi * p)
end

-- Respira entre `low` e `high`.
local function breathe(t: number, period: number, low: number, high: number, phase: number?): number
	return low + (high - low) * (0.5 + 0.5 * math.sin(TAU * (t / period + (phase or 0))))
end

-- Campo de partículas subindo (bolhas) ou caindo (folhas) numa coluna.
local function drift(x: number, period: number, phase: number, fromY: number, toY: number, sway: number, alpha: number)
	return function(t: number): Pose
		local p = cycle(t, period, phase)
		return {
			x = x + sway * math.sin(TAU * p),
			y = fromY + (toY - fromY) * p,
			alpha = alpha * fade(p),
		}
	end
end

local LAYERS: { [string]: { Layer } } = {
	mare_profunda = {
		-- Luz da superfície caindo atrás dos itens e no meio da gruta.
		{
			image = ID.mar_raios,
			aspect = 668 / 517,
			height = 1.15,
			z = 1,
			anchor = Vector2.new(0.5, 0),
			pose = function(t)
				return { x = 0.3, y = -0.08, alpha = breathe(t, 5, 0.45, 0.85) }
			end,
		},
		{
			image = ID.mar_raios,
			aspect = 668 / 517,
			height = 1.0,
			z = 1,
			anchor = Vector2.new(0.5, 0),
			pose = function(t)
				return { x = 0.63, y = -0.05, alpha = breathe(t, 6, 0.35, 0.75, 0.4), rotation = -6 }
			end,
		},
		-- Cardume cruzando o fundo devagar, da direita para a esquerda.
		{
			image = ID.mar_peixes,
			aspect = 547 / 157,
			height = 0.2,
			z = 1,
			pose = function(t)
				local p = cycle(t, 20)
				return { x = 1.15 - 1.3 * p, y = 0.3 + 0.03 * math.sin(TAU * p * 3), alpha = 0.55 }
			end,
		},
		-- Água-viva boiando no vão entre os itens e o texto.
		{
			image = ID.mar_agua_viva,
			aspect = 281 / 323,
			height = 0.36,
			z = 1,
			pose = function(t)
				return {
					x = 0.585 + 0.01 * math.sin(TAU * t / 8),
					y = 0.36 + 0.05 * math.sin(TAU * t / 4),
					alpha = 0.9,
					rotation = 5 * math.sin(TAU * t / 8),
					scale = breathe(t, 4, 0.96, 1.04, 0.25),
				}
			end,
		},
		-- Algas balançando no chão, atrás da água-viva.
		{
			image = ID.mar_algas,
			aspect = 262 / 362,
			height = 0.55,
			z = 1,
			anchor = Vector2.new(0.5, 1),
			pose = function(t)
				return { x = 0.5, y = 1.02, alpha = 0.95, rotation = 4 * math.sin(TAU * t / 5) }
			end,
		},
		-- Bolhas subindo em duas colunas, fora de compasso.
		{
			image = ID.mar_bolhas,
			aspect = 830 / 361,
			height = 0.7,
			z = 3,
			pose = drift(0.24, 8, 0, 1.25, -0.25, 0.015, 0.75),
		},
		{
			image = ID.mar_bolhas,
			aspect = 830 / 361,
			height = 0.55,
			z = 1,
			pose = drift(0.7, 10, 0.5, 1.25, -0.25, 0.02, 0.6),
		},
		-- Brilhos mágicos piscando em cima dos itens.
		{
			image = ID.mar_brilhos,
			aspect = 799 / 300,
			height = 0.45,
			z = 3,
			pose = function(t)
				return { x = 0.24, y = 0.22, alpha = breathe(t, 2.5, 0, 0.8) }
			end,
		},
	},
	bosque_desperto = {
		-- Raios de sol entrando pela copa, sobre a clareira.
		{
			image = ID.bosque_raios,
			aspect = 864 / 627,
			height = 1.2,
			z = 1,
			anchor = Vector2.new(0.5, 0),
			pose = function(t)
				return { x = 0.5, y = -0.1, alpha = breathe(t, 6, 0.45, 0.85) }
			end,
		},
		-- Névoa baixa andando devagar.
		{
			image = ID.bosque_neblina,
			aspect = 1024 / 201,
			height = 0.35,
			z = 1,
			pose = function(t)
				return { x = 0.55 + 0.06 * math.sin(TAU * t / 18), y = 0.86, alpha = 0.45 }
			end,
		},
		-- Cipós pendurados no topo, balançando pela ponta de cima.
		{
			image = ID.bosque_cipos,
			aspect = 509 / 345,
			height = 0.5,
			z = 1, -- atrás do Toco
			anchor = Vector2.new(0.5, 0),
			pose = function(t)
				return { x = 0.07, y = -0.04, alpha = 1, rotation = 3 * math.sin(TAU * t / 5) }
			end,
		},
		{
			image = ID.bosque_cipos,
			aspect = 509 / 345,
			height = 0.42,
			z = 1,
			anchor = Vector2.new(0.5, 0),
			pose = function(t)
				return { x = 0.66, y = -0.04, alpha = 0.95, rotation = 3 * math.sin(TAU * (t / 6 + 0.3)) }
			end,
		},
		-- Vaga-lumes piscando na clareira, à direita dos itens.
		{
			image = ID.bosque_vagalumes,
			aspect = 1024 / 376,
			height = 0.55,
			z = 1,
			pose = function(t)
				return { x = 0.62, y = 0.58 + 0.03 * math.sin(TAU * t / 7), alpha = breathe(t, 3, 0.15, 0.9) }
			end,
		},
		-- Folhas caindo pela frente, em duas levas.
		{
			image = ID.bosque_folhas,
			aspect = 1024 / 319,
			height = 0.42,
			z = 3,
			pose = drift(0.3, 9, 0, -0.25, 1.25, 0.06, 0.95),
		},
		{
			image = ID.bosque_folhas,
			aspect = 1024 / 319,
			height = 0.34,
			z = 1,
			pose = drift(0.72, 12, 0.5, -0.25, 1.25, 0.05, 0.8),
		},
		-- Borboleta dourada voando em curva pelo vão do meio.
		{
			image = ID.bosque_borboleta,
			aspect = 307 / 190,
			height = 0.16,
			z = 3,
			pose = function(t)
				local p = cycle(t, 12)
				return {
					x = 0.42 + 0.22 * math.sin(TAU * p),
					y = 0.4 + 0.16 * math.sin(2 * TAU * p),
					alpha = 1,
					rotation = 12 * math.cos(TAU * p),
					scaleX = 0.45 + 0.55 * math.abs(math.cos(t * 9)),
				}
			end,
		},
	},
	norte_perdido = {
		-- Sol de fim de tarde passando pela copa da árvore da esquerda.
		{
			image = ID.bosque_raios,
			aspect = 864 / 627,
			height = 1.15,
			z = 1,
			color = Color3.fromRGB(255, 196, 120),
			anchor = Vector2.new(0.5, 0),
			pose = function(t)
				return { x = 0.3, y = -0.08, alpha = breathe(t, 6, 0.25, 0.55), rotation = 8 }
			end,
		},
		-- Rajadas de vento cruzando o céu sobre o vale.
		{
			image = ID.norte_vento,
			aspect = 684 / 122,
			height = 0.14,
			z = 1,
			color = Color3.fromRGB(255, 240, 220),
			pose = function(t)
				local p = cycle(t, 7)
				return { x = 0.42 + 0.5 * p, y = 0.16, alpha = 0.8 * fade(p) }
			end,
		},
		{
			image = ID.norte_vento,
			aspect = 684 / 122,
			height = 0.11,
			z = 1,
			color = Color3.fromRGB(255, 240, 220),
			pose = function(t)
				local p = cycle(t, 9, 0.45)
				return { x = 0.5 + 0.45 * p, y = 0.34, alpha = 0.65 * fade(p) }
			end,
		},
		-- Folhas soltando da árvore e voando com o vento.
		{
			image = ID.bosque_folhas,
			aspect = 1024 / 319,
			height = 0.3,
			z = 3,
			pose = function(t)
				local p = cycle(t, 10)
				return { x = 0.12 + 0.35 * p, y = 0.05 + 0.75 * p, alpha = 0.9 * fade(p), rotation = 10 * p }
			end,
		},
	},
}

local BundleFx = {}

-- Monta as camadas do pacote dentro do banner e devolve a função que as
-- posiciona no tempo t (s). Pacote sem camadas: nil.
function BundleFx.build(id: string, frame: Frame): ((t: number) -> ())?
	local layers = LAYERS[id]
	if layers == nil then
		return nil
	end
	local labels: { ImageLabel } = {}
	for index, layer in layers do
		local label = Instance.new("ImageLabel")
		label.Name = `Ambiente{index}`
		label.Image = layer.image
		label.ImageColor3 = layer.color or Color3.new(1, 1, 1)
		label.AnchorPoint = layer.anchor or Vector2.new(0.5, 0.5)
		label.BackgroundTransparency = 1
		label.ScaleType = Enum.ScaleType.Stretch
		label.ZIndex = layer.z
		label.Parent = frame
		labels[index] = label
	end
	return function(t: number)
		local height = frame.AbsoluteSize.Y
		for index, layer in layers do
			local pose = layer.pose(t)
			local label = labels[index]
			local h = layer.height * height * (pose.scale or 1)
			local w = h * layer.aspect * (pose.scaleX or 1)
			label.Size = UDim2.fromOffset(w, h)
			label.Position = UDim2.fromScale(pose.x, pose.y)
			label.Rotation = pose.rotation or 0
			label.ImageTransparency = 1 - math.clamp(pose.alpha, 0, 1)
		end
	end
end

return BundleFx
