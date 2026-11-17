--!strict
-- Selo do boost de XP: "XP 2× mm:ss" enquanto XpBoostUntil (unix do servidor)
-- está no futuro. Dois lugares:
--  * HUD (`hud`): topo, entre o selo de pontos (esquerda) e o relógio
--    (centro); esse vão é livre no celular deitado (749x330) e no PC.
--  * Menu (`build` com a posição do MenuShell): logo abaixo do aviso do menu,
--    no centro, onde não há botão de canto.
-- A contagem usa ShopData.now (hora do servidor, 1x por segundo).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local ShopDates = require(Shared:WaitForChild("Shop"):WaitForChild("ShopDates"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local ShopData = require(script.Parent.Parent:WaitForChild("ShopData"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local Rustic = require(script.Parent:WaitForChild("Rustic"))

local create = vide.create
local R = Theme.rustic

local XpBoostBadge = {}

local function left(): number
	return ShopData.xpBoostUntil() - ShopData.now()
end

-- Boost correndo agora?
function XpBoostBadge.active(): boolean
	return left() > 0
end

-- A placa com a contagem. `props` (Position, Size, Visible...) vão para a placa;
-- `visible` extra (menu: só no menu limpo) soma-se a "boost correndo".
function XpBoostBadge.build(props: { [any]: any }, visible: (() -> boolean)?): Frame
	props.Name = "XpBoostBadge"
	props.Visible = function()
		return XpBoostBadge.active() and (visible == nil or visible())
	end
	table.insert(props, create("UISizeConstraint")({ MinSize = Theme.hudPillMinSize }))
	table.insert(
		props,
		Kit.text({
			Name = "Label",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.86, 0.5),
			FontFace = Theme.font.number,
			TextColor3 = R.emberLight,
			ZIndex = 2,
			Text = function()
				return Strings.format("hud.xpBoost", { time = ShopDates.clock(left()) })
			end,
		})
	)
	return Rustic.plate(props) :: Frame
end

function XpBoostBadge.hud(): Frame
	return XpBoostBadge.build({
		Position = UDim2.fromScale(0.235, 0.02),
		Size = UDim2.fromScale(0.13, 0.075),
		create("UIAspectRatioConstraint")({ AspectRatio = 2.4 }),
	})
end

return XpBoostBadge
