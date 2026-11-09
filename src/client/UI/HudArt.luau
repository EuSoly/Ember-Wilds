--!strict
-- Peças com a arte do HUD (HudImages): fundo esticado em 9 partes e o botão
-- redondo de madeira com ícone. Sem a arte (id vazio), cada função cai no
-- desenho por código de antes, para o HUD continuar funcionando.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local HudImages = require(Shared:WaitForChild("HudImages"))
local Theme = require(Shared:WaitForChild("Theme"))

local create = vide.create

local HudArt = {}

local function rect(slice: { number }): Rect
	return Rect.new(slice[1], slice[2], slice[3], slice[4])
end

-- Fundo `kind` de HudImages.SLICED com a imagem `id`, cobrindo o pai, com os
-- cantos de `corner` px lógicos. nil sem a arte.
function HudArt.sliced(kind: string, id: string, corner: number): ImageLabel?
	local art = HudImages.SLICED[kind]
	if art == nil or not HudImages.has(id) then
		return nil
	end
	return create("ImageLabel")({
		Name = "Art",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Image = id,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = rect(art.slice),
		SliceScale = corner / art.slice[1],
		ZIndex = 0,
	}) :: ImageLabel
end

-- Imagem simples cobrindo o pai (ou com `props`), mantendo a proporção.
function HudArt.image(id: string, props: { [any]: any }?): ImageLabel
	local image = create("ImageLabel")({
		Name = "Art",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Image = id,
		ScaleType = Enum.ScaleType.Fit,
	}) :: ImageLabel
	return if props then vide.apply(image)(props) :: ImageLabel else image
end

-- Com a arte do slot (couro e madeira), os slots perdem o quadrado escuro.
HudArt.HAS_SLOT = HudImages.has(HudImages.SLOT)

-- Fundo de couro de um slot (cobre o pai, atrás do ícone). Só com a arte.
function HudArt.slotBack(): ImageLabel
	return HudArt.image(HudImages.SLOT, { Name = "SlotArt", ScaleType = Enum.ScaleType.Stretch, ZIndex = 0 })
end

-- Põe `icon` dentro da borda de madeira do slot (recuado SLOT_INSET de cada lado).
function HudArt.inSlot(icon: Instance): Frame
	local inner = 1 - 2 * HudImages.SLOT_INSET
	local holder = create("Frame")({
		Name = "IconHolder",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(inner, inner),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}) :: Frame
	icon.Parent = holder
	return holder
end

export type RoundProps = {
	Name: string,
	icon: string, -- id do ícone (HudImages.ICON[...])
	fallback: string, -- texto no desenho de reserva (sem a arte)
	Position: any,
	AnchorPoint: Vector2?,
	Size: UDim2,
	SizeConstraint: Enum.SizeConstraint?,
	Visible: any?,
	Activated: () -> (),
	minSize: Vector2,
	maxSize: Vector2,
}

-- Botão redondo de madeira com o ícone no meio (configurações, receitas,
-- mochila, girar). Sem a arte: círculo escuro com o texto de reserva.
function HudArt.roundButton(props: RoundProps): TextButton
	local hasArt = HudImages.has(HudImages.BUTTON_ROUND) and HudImages.has(props.icon)
	local children: { Instance } = {
		create("UISizeConstraint")({ MinSize = props.minSize, MaxSize = props.maxSize }),
		create("UIAspectRatioConstraint")({ AspectRatio = 1 }),
	}
	if hasArt then
		table.insert(children, HudArt.image(HudImages.BUTTON_ROUND))
		table.insert(
			children,
			HudArt.image(props.icon, {
				Name = "Icon",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.56, 0.56),
				ZIndex = 2,
			})
		)
	else
		table.insert(children, create("UICorner")({ CornerRadius = UDim.new(1, 0) }))
		table.insert(children, create("UIStroke")({ Color = Theme.ui.border, Thickness = Theme.strokeThickness }))
		table.insert(
			children,
			create("TextLabel")({
				Size = UDim2.fromScale(0.8, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				FontFace = Theme.font.number,
				TextColor3 = Theme.ui.text,
				TextScaled = true,
				Text = props.fallback,
			})
		)
	end
	return create("TextButton")({
		Name = props.Name,
		Text = "",
		AutoButtonColor = not hasArt,
		AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 0.5),
		Position = props.Position,
		Size = props.Size,
		SizeConstraint = props.SizeConstraint or Enum.SizeConstraint.RelativeYY,
		Visible = props.Visible or true,
		BackgroundColor3 = Theme.ui.panel,
		BackgroundTransparency = if hasArt then 1 else Theme.panelTransparency,
		BorderSizePixel = 0,
		Activated = props.Activated,
		children,
	}) :: TextButton
end

return HudArt
