--!strict
-- Peças do design system rústico (docs/game-design/design-system/README.md):
-- madeira estrutura, couro convida à interação, papel explica, brasa destaca.
-- Enquanto não existem as texturas finais dos componentes, o volume é feito
-- com UIGradient (luz em cima, espessura escura embaixo) e o contorno carvão
-- com UIStroke. Quando a arte chegar, só este arquivo muda.
--
-- Como o Kit, cada função recebe uma tabela de propriedades do Vide (valores
-- fixos ou funções reativas) e devolve a instância criada.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Theme = require(Shared:WaitForChild("Theme"))
local UiImages = require(Shared:WaitForChild("UiImages"))
local ShopImages = require(Shared:WaitForChild("ShopImages"))

local create = vide.create
local R = Theme.rustic

local Rustic = {}

export type Kind = "wood" | "leather" | "ember" | "green" | "success" | "disabled"

-- Cores de cada material: luz (borda de cima), face e espessura (embaixo).
local MATERIAL: { [Kind]: { light: Color3, face: Color3, shadow: Color3, text: Color3 } } = {
	wood = { light = R.woodLight, face = R.walnut, shadow = R.woodShadow, text = R.cream },
	leather = { light = R.leatherLight, face = R.leather, shadow = R.leatherShadow, text = R.cream },
	ember = { light = R.emberLight, face = R.ember, shadow = R.emberShadow, text = R.charcoal },
	success = { light = R.success, face = R.success, shadow = R.woodShadow, text = R.charcoal },
	-- Verde do Robux (loja): sem a imagem, cai num degradê verde.
	green = {
		light = Color3.fromHex("#8FE36A"),
		face = Color3.fromHex("#4FB52B"),
		shadow = Color3.fromHex("#2E7A16"),
		text = R.charcoal,
	},
	disabled = { light = R.disabled, face = R.disabled, shadow = R.disabled, text = R.disabledText },
}

local CORNER = UDim.new(0, 4) -- o design system usa chanfro; o canto curto imita
local OUTLINE = 2
local LIGHT_EDGE = 0.1 -- fração da altura com a luz da borda de cima
local SHADOW_EDGE = 0.82 -- daqui para baixo, a espessura escura
local TEXT_MAX = 22
local SUBTEXT_MAX = 14

-- Madeira e couro usam a imagem da placa (com veio e pregos); o couro é a mesma
-- placa um pouco mais escura. Sem a imagem, caem no degradê.
local PLANK_TINT: { wood: Color3, leather: Color3 } = {
	wood = Color3.new(1, 1, 1),
	leather = Color3.fromRGB(215, 180, 160),
}
local TEXT_STROKE = 1.5 -- contorno do texto sobre a placa (veio atrás do texto)

local function usesPlank(kind: Kind): boolean
	return UiImages.has(UiImages.PLANK) and (kind == "wood" or kind == "leather")
end

-- A brasa (JOGAR, "+", selecionado) usa a imagem do botão laranja chanfrado.
local function usesEmberImage(kind: Kind): boolean
	return UiImages.has(UiImages.BUTTON_EMBER) and kind == "ember"
end

-- O verde do Robux usa a mesma arte chanfrada, em verde.
local function usesGreenImage(kind: Kind): boolean
	return ShopImages.has(ShopImages.BUTTON_GREEN) and kind == "green"
end

type SliceArt = { image: string, size: Vector2, slice: Rect }
local PLANK_ART: SliceArt = { image = UiImages.PLANK, size = UiImages.PLANK_SIZE, slice = UiImages.PLANK_SLICE }
local EMBER_ART: SliceArt =
	{ image = UiImages.BUTTON_EMBER, size = UiImages.BUTTON_EMBER_SIZE, slice = UiImages.BUTTON_EMBER_SLICE }
local GREEN_ART: SliceArt =
	{ image = ShopImages.BUTTON_GREEN, size = UiImages.BUTTON_EMBER_SIZE, slice = UiImages.BUTTON_EMBER_SLICE }

-- Imagem em 9 partes cobrindo o pai: as pontas (pregos, chanfros) não esticam.
-- O SliceScale acompanha a altura, para as pontas crescerem junto.
local function sliceImage(art: SliceArt, visible: boolean | () -> boolean, tint: Color3 | () -> Color3): ImageLabel
	local image = create("ImageLabel")({
		Name = "Art",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Image = art.image,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = art.slice,
		ImageColor3 = tint,
		Visible = visible,
		ZIndex = 0,
	}) :: ImageLabel
	local function fit()
		if image.AbsoluteSize.Y <= 0 then
			return
		end
		-- O UIScale da tela (tamanho da interface) também aumenta as pontas da
		-- placa; sem descontar, os pregos ficariam com a escala aplicada duas vezes.
		local gui = image:FindFirstAncestorOfClass("ScreenGui")
		local uiScale = gui and gui:FindFirstChildOfClass("UIScale")
		local factor = if uiScale and uiScale.Scale > 0 then uiScale.Scale else 1
		image.SliceScale = image.AbsoluteSize.Y / factor / art.size.Y
	end
	image:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	fit()
	return image
end

-- Faixas duras (sem degradê suave): luz, face e espessura.
local function bevel(light: Color3, face: Color3, shadow: Color3): ColorSequence
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, light),
		ColorSequenceKeypoint.new(LIGHT_EDGE, light),
		ColorSequenceKeypoint.new(LIGHT_EDGE + 0.001, face),
		ColorSequenceKeypoint.new(SHADOW_EDGE, face),
		ColorSequenceKeypoint.new(SHADOW_EDGE + 0.001, shadow),
		ColorSequenceKeypoint.new(1, shadow),
	})
end

local function read<T>(value: T | () -> T): T
	if type(value) == "function" then
		return (value :: () -> T)()
	end
	return value :: T
end

local function outline(thickness: number?): UIStroke
	return create("UIStroke")({
		Color = R.outline,
		Thickness = thickness or OUTLINE,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}) :: UIStroke
end

-- Texto do rústico: sem o contorno grosso do HUD (fica sobre superfície lisa).
-- `dark = true` para texto carvão sobre papel ou brasa.
function Rustic.label(props: { [any]: any }): TextLabel
	local maxSize = props.maxSize or TEXT_MAX
	local dark = props.dark
	props.maxSize = nil
	props.dark = nil
	local label = create("TextLabel")({
		BackgroundTransparency = 1,
		FontFace = Theme.font.label,
		TextColor3 = if dark then R.charcoal else R.cream,
		TextScaled = true,
		create("UITextSizeConstraint")({ MinTextSize = 10, MaxTextSize = maxSize }),
	}) :: TextLabel
	return vide.apply(label)(props) :: TextLabel
end

-- Placa de madeira (placas do topo): a imagem da placa; sem ela, o degradê.
function Rustic.plate(props: { [any]: any }): Frame
	if UiImages.has(UiImages.PLANK) then
		local frame = create("Frame")({
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			sliceImage(PLANK_ART, true, PLANK_TINT.wood),
		}) :: Frame
		return vide.apply(frame)(props) :: Frame
	end
	local frame = create("Frame")({
		BackgroundColor3 = Color3.new(1, 1, 1), -- o UIGradient pinta
		BorderSizePixel = 0,
		create("UICorner")({ CornerRadius = CORNER }),
		create("UIGradient")({ Rotation = 90, Color = bevel(R.woodLight, R.walnut, R.woodShadow) }),
		outline(),
	}) :: Frame
	return vide.apply(frame)(props) :: Frame
end

-- Folha de papel (kits, leitura): borda ocre por dentro, contorno carvão por fora.
function Rustic.paper(props: { [any]: any }): Frame
	local frame = create("Frame")({
		BackgroundColor3 = R.paper,
		BorderSizePixel = 0,
		create("UICorner")({ CornerRadius = CORNER }),
		outline(3),
		create("Frame")({
			Name = "Edge",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ZIndex = 0,
			create("UICorner")({ CornerRadius = CORNER }),
			create("UIStroke")({ Color = R.paperShadow, Thickness = 4, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
		}),
	}) :: Frame
	return vide.apply(frame)(props) :: Frame
end

-- Botão de material. `kind` (fixo ou reativo) escolhe o material; `text` e
-- `subtext` (opcionais, fixos ou reativos) são o rótulo e uma linha menor
-- embaixo. O resto de `props` vai para o TextButton (Size, Activated…).
function Rustic.button(props: { [any]: any }): TextButton
	local kind: Kind | () -> Kind = props.kind or "wood"
	local text = props.text
	local subtext = props.subtext
	local maxSize = props.maxSize or TEXT_MAX
	props.kind = nil
	props.text = nil
	props.subtext = nil
	props.maxSize = nil

	local function material()
		return MATERIAL[read(kind)]
	end
	local function hasSub(): boolean
		local value = read(subtext)
		return value ~= nil and value ~= ""
	end
	local function plank(): boolean
		return usesPlank(read(kind))
	end
	local function emberArt(): boolean
		return usesEmberImage(read(kind))
	end
	local function greenArt(): boolean
		return usesGreenImage(read(kind))
	end
	local function anyArt(): boolean
		return plank() or emberArt() or greenArt()
	end
	local function textStroke(): UIStroke
		return create("UIStroke")({
			Enabled = plank,
			Color = R.outline,
			Thickness = TEXT_STROKE,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
		}) :: UIStroke
	end

	local button = create("TextButton")({
		Text = "",
		AutoButtonColor = function()
			return read(kind) ~= "disabled"
		end,
		Active = function()
			return read(kind) ~= "disabled"
		end,
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = function()
			return if anyArt() then 1 else 0
		end,
		BorderSizePixel = 0,
		create("UISizeConstraint")({ MinSize = Theme.touchMinSize }),
		create("UICorner")({ CornerRadius = CORNER }),
		create("UIGradient")({
			Enabled = function()
				return not anyArt()
			end,
			Rotation = 90,
			Color = function()
				local m = material()
				return bevel(m.light, m.face, m.shadow)
			end,
		}),
		create("UIStroke")({
			Enabled = function()
				return not anyArt()
			end,
			Color = R.outline,
			Thickness = OUTLINE,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
		sliceImage(PLANK_ART, plank, function()
			return if read(kind) == "leather" then PLANK_TINT.leather else PLANK_TINT.wood
		end),
		sliceImage(EMBER_ART, emberArt, Color3.new(1, 1, 1)),
		sliceImage(GREEN_ART, greenArt, Color3.new(1, 1, 1)),
		Rustic.label({
			Name = "Label",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = function()
				return if hasSub() then UDim2.fromScale(0.5, 0.36) else UDim2.fromScale(0.5, 0.46)
			end,
			Size = function()
				return if hasSub() then UDim2.fromScale(0.88, 0.42) else UDim2.fromScale(0.88, 0.56)
			end,
			FontFace = Theme.font.number,
			TextColor3 = function()
				return material().text
			end,
			Text = function()
				return read(text) or ""
			end,
			maxSize = maxSize,
			textStroke(),
		}),
		Rustic.label({
			Name = "Subtext",
			Visible = hasSub,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.7),
			Size = UDim2.fromScale(0.88, 0.26),
			TextColor3 = function()
				local m = material()
				return if m.text == R.cream then R.emberLight else R.charcoal
			end,
			Text = function()
				return read(subtext) or ""
			end,
			maxSize = SUBTEXT_MAX,
			textStroke(),
		}),
	}) :: TextButton
	return vide.apply(button)(props) :: TextButton
end

-- Barra de progresso (XP): trilho escuro com contorno carvão, preenchimento
-- de brasa com brilho em cima e o texto contornado por cima. `fraction` (0..1)
-- e `text` são fixos ou reativos; o resto de `props` vai para o Frame.
local BAR_TRACK = Color3.fromHex("#1A130D")

function Rustic.bar(props: { [any]: any }): Frame
	local fraction: number | () -> number = props.fraction or 0
	local text = props.text
	local maxSize = props.maxSize or 14
	props.fraction = nil
	props.text = nil
	props.maxSize = nil
	local frame = create("Frame")({
		BackgroundColor3 = BAR_TRACK,
		BorderSizePixel = 0,
		create("UICorner")({ CornerRadius = UDim.new(1, 0) }),
		outline(2),
		create("Frame")({
			Name = "Fill",
			Size = function()
				return UDim2.fromScale(math.clamp(read(fraction), 0, 1), 1)
			end,
			BackgroundColor3 = Color3.new(1, 1, 1), -- o UIGradient pinta
			BorderSizePixel = 0,
			create("UICorner")({ CornerRadius = UDim.new(1, 0) }),
			create("UIGradient")({
				Rotation = 90,
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, R.emberLight),
					ColorSequenceKeypoint.new(0.45, R.ember),
					ColorSequenceKeypoint.new(1, R.emberShadow),
				}),
			}),
		}),
		Rustic.label({
			Name = "Text",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.92, 0.82),
			FontFace = Theme.font.number,
			ZIndex = 2,
			Text = function()
				return read(text) or ""
			end,
			maxSize = maxSize,
			create("UIStroke")({ Color = R.outline, Thickness = TEXT_STROKE }),
		}),
	}) :: Frame
	return vide.apply(frame)(props) :: Frame
end

return Rustic
