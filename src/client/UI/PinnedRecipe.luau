--!strict
-- Receita fixada pelo livro (PinState), na coluna da direita do HUD, abaixo do
-- quadrinho do tutorial: o nome do item e uma linha por ingrediente, com ícone
-- e "Madeira 15/10" (sem teto, para ver o que já passou; verde quando já tem).
-- O nome fica verde quando dá para fazer. O X desafixa.
-- Com a arte do pergaminho (MonetizationImages.RECIPE_SCROLL, 400x600) ele vira o
-- fundo em 9 partes (só a altura estica: os rolos de cima e de baixo ficam
-- fixos); sem o id, vale o papel de sempre, desenhado por código.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Defs = require(Shared:WaitForChild("Defs"))
local HudColumn = require(Shared:WaitForChild("UIFlow"):WaitForChild("HudColumn"))
local MonetizationImages = require(Shared:WaitForChild("MonetizationImages"))
local PinRules = require(Shared:WaitForChild("UIFlow"):WaitForChild("PinRules"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local PinState = require(script.Parent.Parent:WaitForChild("PinState"))
local HudColumnState = require(script.Parent:WaitForChild("HudColumnState"))
local ItemIcon = require(script.Parent:WaitForChild("ItemIcon"))
local Rustic = require(script.Parent:WaitForChild("Rustic"))

local create = vide.create
local R = Theme.rustic

local DONE_COLOR = Color3.fromRGB(46, 140, 52) -- verde do "já tem"

local SCROLL_SIZE = Vector2.new(400, 600) -- tamanho da arte do pergaminho
local SCROLL_SIDE = 0.12 -- margem lateral para o texto (LEIA-ME: pelo menos 12%)
local SCROLL_ROLL = 0.45 -- quanto do rolo (em volta do miolo) o texto deixa livre

-- Fundo do pergaminho em 9 partes. O SliceScale segue a LARGURA (os rolos
-- mantêm a proporção da arte) e desconta o UIScale da tela, que também
-- aumenta as pontas (igual ao Rustic.sliceImage).
local function scrollArt(padding: UIPadding): ImageLabel
	local slice = MonetizationImages.RECIPE_SCROLL_SLICE
	local image = create("ImageLabel")({
		Name = "ScrollArt",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Image = MonetizationImages.RECIPE_SCROLL,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = slice,
		ZIndex = 0,
	}) :: ImageLabel
	local function fit()
		if image.AbsoluteSize.X <= 0 then
			return
		end
		local gui = image:FindFirstAncestorOfClass("ScreenGui")
		local uiScale = gui and gui:FindFirstChildOfClass("UIScale")
		local factor = if uiScale and uiScale.Scale > 0 then uiScale.Scale else 1
		local scale = image.AbsoluteSize.X / factor / SCROLL_SIZE.X
		image.SliceScale = scale
		-- O texto fica dentro do miolo liso, um pouco entrando nos rolos.
		padding.PaddingTop = UDim.new(0, slice.Min.Y * scale * SCROLL_ROLL)
		padding.PaddingBottom = UDim.new(0, (SCROLL_SIZE.Y - slice.Max.Y) * scale * SCROLL_ROLL)
	end
	image:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	task.defer(fit) -- o tamanho só existe depois de montado
	return image
end

local function itemName(id: string): string
	local def = Defs.Items[id]
	return if def then Strings.get(def.nameKey) else id
end

-- Uma linha: ícone e "Madeira 15/10".
local function Line(line: () -> PinRules.Line, index: number): Frame
	return create("Frame")({
		Name = "Line",
		LayoutOrder = index,
		Size = function()
			local rows = math.max(#PinState.lines(), 1)
			return UDim2.fromScale(1, 1 / rows)
		end,
		BackgroundTransparency = 1,
		create("Frame")({
			Name = "IconBox",
			Size = UDim2.fromScale(0.9, 0.9),
			Position = UDim2.fromScale(0, 0.05),
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
			BackgroundTransparency = 1,
			ItemIcon({
				item = function()
					return { id = line().item, count = 1 }
				end,
				bare = true,
			}),
		}),
		Rustic.label({
			Name = "Count",
			dark = true,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.fromScale(1, 0.5),
			Size = UDim2.fromScale(0.8, 0.8),
			FontFace = Theme.font.number,
			TextXAlignment = Enum.TextXAlignment.Left,
			maxSize = 16,
			TextColor3 = function()
				return if line().done then DONE_COLOR else R.charcoal
			end,
			Text = function()
				local l = line()
				return `{itemName(l.item)} {l.have}/{l.need}`
			end,
		}),
	}) :: Frame
end

local function PinnedRecipe(): Frame
	local lines = vide.derive(PinState.lines)
	local hasArt = MonetizationImages.has(MonetizationImages.RECIPE_SCROLL)
	local props: { [any]: any } = {
		Name = "PinnedRecipe",
		AnchorPoint = HudColumnState.anchor,
		Visible = function()
			return #lines() > 0 and not HudColumnState.yieldsToPanel()
		end,
		Position = function()
			return UDim2.fromScale(HudColumnState.x(), HudColumnState.column().pinnedY)
		end,
		Size = function()
			return UDim2.fromScale(HudColumn.WIDTH, math.max(HudColumnState.pinnedHeight(), 0.01))
		end,
	}
	-- Título, X de desafixar e as linhas (iguais com e sem a arte).
	local function content(): { Instance }
		return {
			Rustic.label({
				Name = "Title",
				Size = UDim2.new(1, -30, 0, 22),
				TextXAlignment = Enum.TextXAlignment.Left,
				maxSize = 18,
				TextColor3 = function()
					return if PinState.ready() then DONE_COLOR else R.emberShadow
				end,
				Text = function()
					local id = PinState.pinned()
					if id == nil then
						return ""
					end
					return Strings.format("hud.pinned.title", { item = itemName(id) })
				end,
			}),
			-- Desafixar sem abrir o livro. Um "X" de letra (o "✕" não existe na fonte e
			-- ficava invisível, visto em 11/11), num botão redondo de couro.
			create("TextButton")({
				Name = "Unpin",
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, 2, 0, -2),
				Size = UDim2.fromOffset(26, 26),
				BackgroundColor3 = R.emberShadow,
				AutoButtonColor = true,
				Text = "X",
				FontFace = Theme.font.number,
				TextScaled = true,
				TextColor3 = R.cream,
				ZIndex = 3,
				create("UICorner")({ CornerRadius = UDim.new(1, 0) }),
				create("UIPadding")({
					PaddingTop = UDim.new(0, 5),
					PaddingBottom = UDim.new(0, 5),
				}),
				Activated = function()
					PinState.pinned(nil)
				end,
			}),
			create("Frame")({
				Name = "Lines",
				Position = UDim2.fromOffset(0, 26),
				Size = UDim2.new(1, 0, 1, -26),
				BackgroundTransparency = 1,
				create("UIListLayout")({ SortOrder = Enum.SortOrder.LayoutOrder }),
				vide.indexes(lines, Line),
			}),
		}
	end
	if hasArt then
		local padding = create("UIPadding")({
			PaddingLeft = UDim.new(SCROLL_SIDE, 0),
			PaddingRight = UDim.new(SCROLL_SIDE, 0),
			PaddingTop = UDim.new(0, 6),
			PaddingBottom = UDim.new(0, 6),
		}) :: UIPadding
		props.BackgroundTransparency = 1
		props.BorderSizePixel = 0
		props[1] = scrollArt(padding)
		-- O pergaminho ocupa o painel todo; o texto vai num quadro à parte, com a
		-- margem (um UIPadding no painel encolheria o fundo também).
		local contentProps: { [any]: any } = {
			Name = "Content",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			padding,
			content(),
		}
		props[2] = create("Frame")(contentProps)
		return create("Frame")(props) :: Frame
	end
	props[1] = create("UIPadding")({
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 8),
		PaddingTop = UDim.new(0, 6),
		PaddingBottom = UDim.new(0, 6),
	})
	props[2] = content()
	return Rustic.paper(props)
end

return PinnedRecipe
