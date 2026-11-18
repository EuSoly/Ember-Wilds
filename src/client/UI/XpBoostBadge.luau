--!strict
-- Selo do boost de XP enquanto XpBoostUntil (unix do servidor) está no futuro:
-- o ícone do boost (MonetizationImages.XP_BOOST) e "XP 2× mm:ss" com contorno,
-- sem placa de fundo (teste do Elizeu de 18/11/2026: a placa ocupava espaço à
-- toa). Dois lugares:
--  * Menu (`build` com a posição do MenuShell): canto de baixo à esquerda.
--  * HUD (`hud`): logo abaixo do selo de pontos, encostado à esquerda (o topo
--    entre os pontos e o relógio fica livre).
-- A contagem usa ShopData.now (hora do servidor, 1x por segundo).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local MonetizationImages = require(Shared:WaitForChild("MonetizationImages"))
local ShopDates = require(Shared:WaitForChild("Shop"):WaitForChild("ShopDates"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local ShopData = require(script.Parent.Parent:WaitForChild("ShopData"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local ScreenMetrics = require(script.Parent:WaitForChild("ScreenMetrics"))

local create = vide.create
local R = Theme.rustic

-- HUD: o selo de pontos (ScorePill) fica em 2% do topo com 7,5% da altura (ou
-- o mínimo de Theme.hudPillMinSize); o boost vem logo embaixo.
local PILL_TOP = 0.02
local PILL_HEIGHT = 0.075
local HUD_GAP = 6
local HUD_HEIGHT = 30
local WIDTH_PER_HEIGHT = 4.4 -- ícone quadrado + "XP 2× 00:00"

local XpBoostBadge = {}

local function left(): number
	return ShopData.xpBoostUntil() - ShopData.now()
end

-- Boost correndo agora?
function XpBoostBadge.active(): boolean
	return left() > 0
end

-- O selo: ícone e contagem. `props` (Position, Size, AnchorPoint...) vão para
-- o quadro; `visible` extra (menu: só no menu limpo) soma-se a "boost correndo".
function XpBoostBadge.build(props: { [any]: any }, visible: (() -> boolean)?): Frame
	props.Name = "XpBoostBadge"
	props.BackgroundTransparency = 1
	props.Visible = function()
		return XpBoostBadge.active() and (visible == nil or visible())
	end
	table.insert(
		props,
		create("ImageLabel")({
			Name = "Icon",
			Size = UDim2.fromScale(1, 1),
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
			BackgroundTransparency = 1,
			Image = MonetizationImages.XP_BOOST,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 2,
		})
	)
	table.insert(
		props,
		Kit.text({
			Name = "Label",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.fromScale(1, 0.5),
			Size = UDim2.fromScale(0.74, 0.62),
			FontFace = Theme.font.number,
			TextColor3 = R.emberLight,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 2,
			Text = function()
				return Strings.format("hud.xpBoost", { time = ShopDates.clock(left()) })
			end,
		})
	)
	return create("Frame")(props) :: Frame
end

function XpBoostBadge.hud(): Frame
	return XpBoostBadge.build({
		Position = function()
			local h = ScreenMetrics.guiHeight()
			local pill = math.max(PILL_HEIGHT * h, Theme.hudPillMinSize.Y)
			return UDim2.new(PILL_TOP, 0, PILL_TOP, pill + HUD_GAP)
		end,
		Size = UDim2.fromOffset(HUD_HEIGHT * WIDTH_PER_HEIGHT, HUD_HEIGHT),
	})
end

-- Altura do selo no menu (px) e largura que ele pede.
XpBoostBadge.MENU_HEIGHT = 40
XpBoostBadge.MENU_WIDTH = 40 * WIDTH_PER_HEIGHT

return XpBoostBadge
