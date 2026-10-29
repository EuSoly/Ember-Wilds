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
local Theme = require(Shared:WaitForChild("Theme"))

local create = vide.create

local Kit = {}

local MIN_TEXT_SIZE = 12

-- Painel padrão: fundo escuro a 85%, canto arredondado e borda fina.
-- `props` vai direto para o Frame (Size, Position, filhos etc.).
function Kit.panel(props: { [any]: any }): Frame
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
