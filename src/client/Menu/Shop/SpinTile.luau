--!strict
-- Quadradinho de uma skin da loja (carrossel, prêmio, pacotes): fundo na cor
-- da raridade (cores dos tiers), desenho da peça e nome embaixo.
-- Até existirem os ícones de verdade, cada tipo tem um desenho simples feito
-- de Frames na cor da skin: corpo (carinha do boneco), acessório (chapéu),
-- mochila, livro e caixa.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local MockStore = require(Shared:WaitForChild("UIFlow"):WaitForChild("MockStore"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local Client = script.Parent.Parent.Parent
local Rustic = require(Client:WaitForChild("UI"):WaitForChild("Rustic"))

local create = vide.create
local R = Theme.rustic

local SpinTile = {}

local function shade(color: Color3, factor: number): Color3
	return Color3.new(
		math.clamp(color.R * factor, 0, 1),
		math.clamp(color.G * factor, 0, 1),
		math.clamp(color.B * factor, 0, 1)
	)
end

-- Peça com contorno escuro e cantos arredondados (fração do tamanho do pai).
local function piece(props: { [any]: any }): Frame
	local corner = props.corner or 0.18
	props.corner = nil
	local frame = create("Frame")({
		BorderSizePixel = 0,
		create("UICorner")({ CornerRadius = UDim.new(corner, 0) }),
		create("UIStroke")({ Color = R.outline, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
	}) :: Frame
	return vide.apply(frame)(props) :: Frame
end

-- Desenho placeholder de cada tipo, preenchendo o pai (quadrado).
local function art(typeId: string, color: Color3): Frame
	local holder = create("Frame")({
		Name = "Art",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}) :: Frame
	local parts: { Frame }
	if typeId == "body" then
		parts = {
			piece({
				BackgroundColor3 = color,
				Position = UDim2.fromScale(0.08, 0.16),
				Size = UDim2.fromScale(0.84, 0.72),
				corner = 0.3,
			}),
			piece({
				BackgroundColor3 = R.outline,
				Position = UDim2.fromScale(0.28, 0.36),
				Size = UDim2.fromScale(0.14, 0.12),
				corner = 0.5,
			}),
			piece({
				BackgroundColor3 = R.outline,
				Position = UDim2.fromScale(0.58, 0.36),
				Size = UDim2.fromScale(0.14, 0.12),
				corner = 0.5,
			}),
		}
	elseif typeId == "accessory" then
		parts = {
			piece({
				BackgroundColor3 = color,
				Position = UDim2.fromScale(0.26, 0.18),
				Size = UDim2.fromScale(0.48, 0.48),
				corner = 0.2,
			}),
			piece({
				BackgroundColor3 = shade(color, 0.75),
				Position = UDim2.fromScale(0.08, 0.62),
				Size = UDim2.fromScale(0.84, 0.16),
				corner = 0.5,
			}),
			piece({
				BackgroundColor3 = R.emberLight,
				Position = UDim2.fromScale(0.26, 0.5),
				Size = UDim2.fromScale(0.48, 0.08),
				corner = 0,
			}),
		}
	elseif typeId == "bag" then
		parts = {
			piece({
				BackgroundColor3 = color,
				Position = UDim2.fromScale(0.18, 0.2),
				Size = UDim2.fromScale(0.64, 0.66),
				corner = 0.22,
			}),
			piece({
				BackgroundColor3 = shade(color, 0.75),
				Position = UDim2.fromScale(0.18, 0.2),
				Size = UDim2.fromScale(0.64, 0.28),
				corner = 0.22,
			}),
			piece({
				BackgroundColor3 = R.emberLight,
				Position = UDim2.fromScale(0.44, 0.42),
				Size = UDim2.fromScale(0.12, 0.12),
				corner = 0.2,
			}),
		}
	elseif typeId == "book" then
		parts = {
			piece({
				BackgroundColor3 = color,
				Position = UDim2.fromScale(0.2, 0.12),
				Size = UDim2.fromScale(0.6, 0.76),
				corner = 0.08,
			}),
			piece({
				BackgroundColor3 = shade(color, 0.7),
				Position = UDim2.fromScale(0.2, 0.12),
				Size = UDim2.fromScale(0.12, 0.76),
				corner = 0,
			}),
			piece({
				BackgroundColor3 = R.emberLight,
				Position = UDim2.fromScale(0.46, 0.38),
				Size = UDim2.fromScale(0.16, 0.16),
				corner = 0.1,
			}),
		}
	else -- caixa
		parts = {
			piece({
				BackgroundColor3 = color,
				Position = UDim2.fromScale(0.14, 0.14),
				Size = UDim2.fromScale(0.72, 0.72),
				corner = 0.06,
			}),
			piece({
				BackgroundColor3 = shade(color, 0.7),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.9, 0.1),
				Rotation = 45,
				corner = 0,
			}),
			piece({
				BackgroundColor3 = shade(color, 0.7),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.9, 0.1),
				Rotation = -45,
				corner = 0,
			}),
		}
	end
	for i, part in parts do
		part.ZIndex = 2 + i
		part.Parent = holder
	end
	return holder
end

local function tileFrame(typeId: string, colorHex: string, rarity: number, props: { [any]: any }): Frame
	local rarityColor = Color3.fromHex(MockStore.RARITIES[math.clamp(rarity, 1, #MockStore.RARITIES)].color)
	local frame = create("Frame")({
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		create("UICorner")({ CornerRadius = UDim.new(0.1, 0) }),
		create("UIStroke")({ Color = R.outline, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
		-- Fundo na cor da raridade, mais claro em cima.
		create("UIGradient")({
			Rotation = 90,
			Color = ColorSequence.new(shade(rarityColor, 1.3), shade(rarityColor, 0.75)),
		}),
	}) :: Frame
	local holder = create("Frame")({
		Name = "ArtBox",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.06),
		Size = UDim2.fromScale(0.66, 0.66),
		SizeConstraint = Enum.SizeConstraint.RelativeXX,
		BackgroundTransparency = 1,
		ZIndex = 2,
	}) :: Frame
	art(typeId, Color3.fromHex(colorHex)).Parent = holder
	holder.Parent = frame
	return vide.apply(frame)(props) :: Frame
end

-- Quadradinho do carrossel/prêmio, com `size` px de lado e o nome embaixo.
function SpinTile.build(item: MockStore.SpinItem, typeId: string, size: number): Frame
	return tileFrame(typeId, item.color, item.rarity, {
		Name = item.id,
		Size = UDim2.fromOffset(size, size),
		Rustic.label({
			Name = "ItemName",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.5, 0.96),
			Size = UDim2.fromScale(0.92, 0.2),
			dark = true,
			FontFace = Theme.font.number,
			Text = Strings.get(item.nameKey),
			maxSize = math.max(math.floor(size / 7), 11),
			ZIndex = 6,
		}),
	})
end

-- Peça solta (sem nome) para a prévia dos pacotes: `sizeScale` da altura do pai.
function SpinTile.preview(typeId: string, colorHex: string, rarity: number, sizeScale: number): Frame
	return tileFrame(typeId, colorHex, rarity, {
		Name = typeId,
		Size = UDim2.fromScale(sizeScale, sizeScale),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
	})
end

return SpinTile
