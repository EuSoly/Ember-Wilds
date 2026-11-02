--!strict
-- Um anel de status (vida, fome, temperatura ou sede): uma barra contínua em volta,
-- que vai se fechando no sentido horário a partir do topo conforme o valor.
-- Abaixo de 35% o anel pulsa; zerado, o trilho pisca.
--
-- Como é feito (sem imagens):
-- - um disco cheio na cor da barra, dividido em duas metades (direita e esquerda)
--   que recortam (ClipsDescendants) a sua parte;
-- - em cada metade, um UIGradient com corte seco no meio esconde o que passou do
--   valor; girar o gradiente (UIMath.ringRotations) mostra mais ou menos arco;
-- - um miolo escuro por cima transforma o disco em anel.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local StatNames = require(Shared:WaitForChild("StatNames"))
local Theme = require(Shared:WaitForChild("Theme"))
local UIMath = require(Shared:WaitForChild("UIMath"))

local create = vide.create

local CORE_SIZE = 0.7 -- miolo escuro; a barra tem (1 - 0.7) / 2 = 15% de espessura
local PULSE_PERIOD = 0.8 -- segundos (identidade visual: pulso a cada 0,8 s)

-- Metade opaca / metade transparente, com o corte seco no meio.
local HALF_MASK = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(0.5, 0),
	NumberSequenceKeypoint.new(0.501, 1),
	NumberSequenceKeypoint.new(1, 1),
})

export type Props = {
	value: () -> number, -- 0 a max
	max: number?, -- valor cheio; padrão StatNames.StatusMax (a vida usa HealthMax)
	color: Color3 | () -> Color3, -- fixa ou reativa (o anel de temperatura troca de cor)
	name: string,
	-- Alerta (pulso) e crítico (trilho piscando). Padrão: abaixo de 35% / zerado.
	-- O anel de temperatura em modo quente inverte (calor alto é o perigo).
	warning: (() -> boolean)?,
	critical: (() -> boolean)?,
}

local function disc(props: { [any]: any }): Frame
	local frame = create("Frame")({
		BorderSizePixel = 0,
		create("UICorner")({ CornerRadius = UDim.new(1, 0) }),
	}) :: Frame
	return vide.apply(frame)(props) :: Frame
end

-- Uma metade do arco. `side` = "Right" (0..50%) ou "Left" (50..100%).
local function half(side: "Right" | "Left", color: Color3 | () -> Color3, rotation: () -> number): Frame
	local isRight = side == "Right"
	-- Metade sem arco fica escondida: o corte do gradiente deixaria uma
	-- linha de 1 px na emenda.
	local visible = function()
		return if isRight then rotation() > 0 else rotation() > 180
	end
	return create("Frame")({
		Name = side,
		Visible = visible,
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Position = UDim2.fromScale(if isRight then 0.5 else 0, 0),
		Size = UDim2.fromScale(0.5, 1),
		ZIndex = 2,
		-- O disco inteiro, deslocado para que só a sua metade apareça.
		disc({
			Name = "Fill",
			BackgroundColor3 = color,
			Position = UDim2.fromScale(if isRight then -1 else 0, 0),
			Size = UDim2.fromScale(2, 1),
			create("UIGradient")({
				Transparency = HALF_MASK,
				Rotation = rotation,
			}),
		}),
	}) :: Frame
end

local function StatusRing(props: Props): Frame
	local fraction = vide.derive(function()
		return UIMath.fraction(props.value(), props.max or StatNames.StatusMax)
	end)
	local rightRotation = vide.derive(function()
		local right = UIMath.ringRotations(fraction())
		return right
	end)
	local leftRotation = vide.derive(function()
		local _, left = UIMath.ringRotations(fraction())
		return left
	end)
	local warning = vide.derive(function()
		if props.warning then
			return props.warning()
		end
		return fraction() < StatNames.WarningFraction
	end)
	local empty = vide.derive(function()
		if props.critical then
			return props.critical()
		end
		return fraction() <= 0
	end)

	-- Relógio do pulso/pisca: alterna enquanto o anel está em alerta.
	local beat = vide.source(false)
	vide.cleanup(task.spawn(function()
		while true do
			task.wait(PULSE_PERIOD / 2)
			beat(not beat())
		end
	end))

	local targetScale = vide.derive(function()
		return if warning() and beat() then 1.1 else 1
	end)
	local scale = vide.spring(targetScale, 0.25)

	return create("Frame")({
		Name = props.name,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		create("UIAspectRatioConstraint")({ AspectRatio = 1 }),
		create("UIScale")({ Scale = scale }),

		-- Trilho: o anel vazio por baixo da barra.
		disc({
			Name = "Track",
			Size = UDim2.fromScale(1, 1),
			ZIndex = 1,
			BackgroundColor3 = Theme.ui.border,
			BackgroundTransparency = function()
				return if empty() and beat() then 0.6 else 0
			end,
		}),

		half("Right", props.color, rightRotation),
		half("Left", props.color, leftRotation),

		-- Pontes de 2 px nas emendas das metades (6 h e 12 h): o recorte das
		-- duas metades deixa um fio de fundo aparecendo quando o arco passa por ali.
		create("Frame")({
			Name = "BottomSeam",
			Visible = function()
				return fraction() > 0.5
			end,
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.5, 1),
			Size = UDim2.new(0, 2, (1 - CORE_SIZE) / 2, 1),
			BackgroundColor3 = props.color,
			BorderSizePixel = 0,
			ZIndex = 2,
		}),
		create("Frame")({
			Name = "TopSeam",
			Visible = function()
				return fraction() >= 1
			end,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0),
			Size = UDim2.new(0, 2, (1 - CORE_SIZE) / 2, 1),
			BackgroundColor3 = props.color,
			BorderSizePixel = 0,
			ZIndex = 2,
		}),

		-- Miolo escuro: transforma o disco em anel.
		disc({
			Name = "Core",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(CORE_SIZE, CORE_SIZE),
			ZIndex = 3,
			BackgroundColor3 = Theme.ui.panel,
		}),
	}) :: Frame
end

return StatusRing
