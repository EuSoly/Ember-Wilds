--!strict
-- "GIROS · ESCOLHA O TIPO": um cartão por tipo de skin (MockStore.SPIN_TYPES)
-- com uma roleta girando devagar e o botão Escolher, que abre a tela do giro.
-- A roleta é um placeholder (disco com as cores das raridades) até chegar a
-- arte; ela só gira com a loja aberta.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local MockStore = require(Shared:WaitForChild("UIFlow"):WaitForChild("MockStore"))
local ShopLayout = require(Shared:WaitForChild("UIFlow"):WaitForChild("ShopLayout"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local Client = script.Parent.Parent.Parent
local Rustic = require(Client:WaitForChild("UI"):WaitForChild("Rustic"))
local ShopParts = require(script.Parent:WaitForChild("ShopParts"))
local ShopState = require(script.Parent:WaitForChild("ShopState"))

local create = vide.create
local R = Theme.rustic

local CARD_HEIGHT = 250
local WHEEL_SPEED = 40 -- graus por segundo

local SpinTypes = {}

-- Disco com faixas nas cores das raridades (girando parece uma roleta).
local function wheel(): Frame
	local keys: { ColorSequenceKeypoint } = {}
	local n = #MockStore.RARITIES
	for i, id in MockStore.RARITIES do
		local color = Theme.tier[id]
		table.insert(keys, ColorSequenceKeypoint.new((i - 1) / n, color))
		table.insert(keys, ColorSequenceKeypoint.new(i / n - (if i < n then 0.001 else 0), color))
	end
	return create("Frame")({
		Name = "Wheel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.9, 0.9),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ZIndex = 3,
		create("UICorner")({ CornerRadius = UDim.new(1, 0) }),
		create("UIStroke")({ Color = R.outline, Thickness = 4, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
		create("UIGradient")({ Color = ColorSequence.new(keys) }),
		create("Frame")({
			Name = "Hub",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.3, 0.3),
			BackgroundColor3 = R.outline,
			BorderSizePixel = 0,
			ZIndex = 4,
			create("UICorner")({ CornerRadius = UDim.new(1, 0) }),
			create("UIStroke")({ Color = R.emberLight, Thickness = 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
		}),
	}) :: Frame
end

local function card(spinType: MockStore.SpinType, order: number, wheels: { Frame }): Frame
	local disc = wheel()
	table.insert(wheels, disc)
	return ShopParts.vividCard(Color3.fromHex(spinType.theme), {
		Name = spinType.id,
		LayoutOrder = order,
		ShopParts.outlined({
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.05),
			Size = UDim2.fromScale(0.9, 0.12),
			FontFace = Theme.font.title,
			Text = Strings.get(spinType.nameKey),
			maxSize = 28,
		}),
		create("Frame")({
			Name = "WheelBox",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.2),
			Size = UDim2.fromScale(0.52, 0.52),
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
			BackgroundTransparency = 1,
			ZIndex = 3,
			disc :: Instance,
			-- Pino em cima da roleta.
			ShopParts.outlined({
				Name = "Pin",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.02),
				Size = UDim2.fromScale(0.3, 0.3),
				FontFace = Theme.font.title,
				Text = "▼",
				TextColor3 = R.cream,
				maxSize = 40,
				ZIndex = 6,
			}),
		}),
		Rustic.button({
			Name = "Choose",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -10),
			Size = UDim2.new(0.86, 0, 0, 46),
			ZIndex = 4,
			kind = "ember",
			text = Strings.get("shop.choose"),
			Activated = function()
				ShopState.openSpin(spinType.id)
			end,
		}),
	})
end

-- Monta a seção. `open` = loja aberta (as roletas só giram nela).
function SpinTypes.build(layout: () -> ShopLayout.Layout, open: () -> boolean): Frame
	local wheels: { Frame } = {}
	local children: { Instance } = {
		ShopParts.grid(function()
			return layout().spinColumns
		end, CARD_HEIGHT, ShopLayout.GAP),
	}
	for i, spinType in MockStore.SPIN_TYPES do
		table.insert(children, card(spinType, i, wheels))
	end

	-- Uma conexão só gira todas as roletas, e só enquanto a loja está aberta.
	local connection: RBXScriptConnection? = nil
	vide.effect(function()
		local shouldSpin = open()
		if shouldSpin and not connection then
			connection = RunService.RenderStepped:Connect(function(dt)
				for _, disc in wheels do
					disc.Rotation = (disc.Rotation + WHEEL_SPEED * dt) % 360
				end
			end)
		elseif not shouldSpin and connection then
			connection:Disconnect()
			connection = nil
		end
	end)
	vide.cleanup(function()
		if connection then
			connection:Disconnect()
		end
	end)

	return create("Frame")({
		Name = "SpinTypes",
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		children,
	}) :: Frame
end

return SpinTypes
