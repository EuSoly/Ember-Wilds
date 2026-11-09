--!strict
-- Peças básicas da interface, já no estilo da identidade visual.
-- Todo componente do HUD monta a partir daqui, para o visual ficar consistente
-- e uma mudança de estilo valer para tudo.
--
-- Cada função recebe uma tabela de propriedades do Vide (valores fixos ou
-- funções reativas) e devolve a instância criada.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local HudImages = require(Shared:WaitForChild("HudImages"))
local Theme = require(Shared:WaitForChild("Theme"))

local create = vide.create

local Kit = {}

local MIN_TEXT_SIZE = 12

local PANEL_CORNER = 26 -- px lógicos da moldura de madeira do painel
local TOOLTIP_CORNER = 22

-- Moldura esticada em 9 partes como o PRÓPRIO quadro (ImageLabel), não como
-- filho: painéis com AutomaticSize e UIPadding cresceriam sem parar com um
-- filho de 100% do tamanho deles.
local function slicedFrame(kind: string, id: string, corner: number): ImageLabel?
	local art = HudImages.SLICED[kind]
	if art == nil or not HudImages.has(id) then
		return nil
	end
	local slice = art.slice
	return create("ImageLabel")({
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Image = id,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(slice[1], slice[2], slice[3], slice[4]),
		SliceScale = corner / slice[1],
	}) :: ImageLabel
end

-- Painel padrão: o couro escuro com moldura de madeira (HudImages.PANEL); sem
-- a arte, fundo escuro a 85% com canto arredondado e borda fina.
-- `props` vai direto para o quadro (Size, Position, filhos etc.).
function Kit.panel(props: { [any]: any }): Frame
	local framed = slicedFrame("panel", HudImages.PANEL, PANEL_CORNER)
	if framed then
		props.CornerRadius = nil
		props.BackgroundColor3 = nil
		props.BackgroundTransparency = nil
		return (vide.apply(framed)(props) :: any) :: Frame
	end
	local frame = create("Frame")({
		BackgroundColor3 = Theme.ui.panel,
		BackgroundTransparency = Theme.panelTransparency,
		BorderSizePixel = 0,
		create("UICorner")({ CornerRadius = props.CornerRadius or Theme.corner }),
		create("UIStroke")({
			Color = Theme.ui.border,
			Thickness = Theme.strokeThickness,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
	}) :: Frame
	props.CornerRadius = nil
	return vide.apply(frame)(props) :: Frame
end

-- Margem interna de um painel: com a moldura de madeira da arte, pelo menos
-- PANEL_PADDING px para o conteúdo não encostar nela.
local PANEL_PADDING = 16
function Kit.panelPadding(base: number): number
	return if HudImages.has(HudImages.PANEL) then math.max(base, PANEL_PADDING) else base
end

-- Balão de papel (dicas): o papel esticado em 9 partes com a pontinha embaixo,
-- no meio. Texto em cima dele deve ser escuro (Theme.rustic.charcoal). Sem a
-- arte, cai no painel padrão.
function Kit.tooltip(props: { [any]: any }): Frame
	local framed = slicedFrame("tooltip", HudImages.TOOLTIP, TOOLTIP_CORNER)
	if framed == nil then
		return Kit.panel(props)
	end
	local tail = HudImages.TOOLTIP_TAIL_SIZE
	local scale = TOOLTIP_CORNER / HudImages.SLICED.tooltip.slice[1]
	create("ImageLabel")({
		Name = "Tail",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 1, -math.floor(8 * scale)),
		Size = UDim2.fromOffset(tail[1] * scale, tail[2] * scale),
		BackgroundTransparency = 1,
		Image = HudImages.TOOLTIP_TAIL,
		Visible = HudImages.has(HudImages.TOOLTIP_TAIL),
		Parent = framed,
	})
	props.CornerRadius = nil
	props.BackgroundColor3 = nil
	props.BackgroundTransparency = nil
	return (vide.apply(framed)(props) :: any) :: Frame
end

-- Texto padrão: escala com a tela (com tamanho mínimo legível) e contorno
-- escuro para continuar legível sobre neve, areia ou lava.
-- `maxSize` é o tamanho máximo do texto em pixels (referência 1080p).
function Kit.text(props: { [any]: any }): TextLabel
	local maxSize = props.maxSize or 24
	props.maxSize = nil
	local label = create("TextLabel")({
		BackgroundTransparency = 1,
		FontFace = Theme.font.label,
		TextColor3 = Theme.ui.text,
		TextScaled = true,
		create("UITextSizeConstraint")({ MinTextSize = MIN_TEXT_SIZE, MaxTextSize = maxSize }),
		create("UIStroke")({
			Color = Theme.ui.panel,
			Thickness = 1.5,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
		}),
	}) :: TextLabel
	return vide.apply(label)(props) :: TextLabel
end

-- Pílula: painel totalmente arredondado com um texto centralizado.
-- `text` pode ser string ou função reativa; o resto de `props` vai para o painel.
function Kit.pill(props: { [any]: any }): Frame
	local text = props.text
	props.text = nil
	props.CornerRadius = UDim.new(1, 0)
	table.insert(
		props,
		Kit.text({
			Size = UDim2.fromScale(0.86, 0.7),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			FontFace = Theme.font.number,
			Text = text,
		})
	)
	return Kit.panel(props)
end

return Kit
