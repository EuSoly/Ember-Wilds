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

local create = vide.create
local R = Theme.rustic

local Rustic = {}

export type Kind = "wood" | "leather" | "ember" | "success" | "disabled"

-- Cores de cada material: luz (borda de cima), face e espessura (embaixo).
local MATERIAL: { [Kind]: { light: Color3, face: Color3, shadow: Color3, text: Color3 } } = {
	wood = { light = R.woodLight, face = R.walnut, shadow = R.woodShadow, text = R.cream },
	leather = { light = R.leatherLight, face = R.leather, shadow = R.leatherShadow, text = R.cream },
	ember = { light = R.emberLight, face = R.ember, shadow = R.emberShadow, text = R.charcoal },
	success = { light = R.success, face = R.success, shadow = R.woodShadow, text = R.charcoal },
	disabled = { light = R.disabled, face = R.disabled, shadow = R.disabled, text = R.disabledText },
}

local CORNER = UDim.new(0, 4) -- o design system usa chanfro; o canto curto imita
local OUTLINE = 2
local LIGHT_EDGE = 0.1 -- fração da altura com a luz da borda de cima
local SHADOW_EDGE = 0.82 -- daqui para baixo, a espessura escura
local TEXT_MAX = 22
local SUBTEXT_MAX = 14

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

-- Placa de madeira (molduras, placas do topo).
function Rustic.plate(props: { [any]: any }): Frame
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

	local button = create("TextButton")({
		Text = "",
		AutoButtonColor = function()
			return read(kind) ~= "disabled"
		end,
		Active = function()
			return read(kind) ~= "disabled"
		end,
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		create("UISizeConstraint")({ MinSize = Theme.touchMinSize }),
		create("UICorner")({ CornerRadius = CORNER }),
		create("UIGradient")({
			Rotation = 90,
			Color = function()
				local m = material()
				return bevel(m.light, m.face, m.shadow)
			end,
		}),
		outline(),
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
		}),
	}) :: TextButton
	return vide.apply(button)(props) :: TextButton
end

return Rustic
