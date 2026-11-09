--!strict
-- Minimapa (canto superior direito): o mapa inteiro de forma esquemática,
-- montado a partir do WorldConfig (os quatro biomas nos cantos sobre o
-- oceano), com as regiões ainda fechadas escurecidas e um ponto na posição do
-- jogador. Não lê o mapa desenhado: com streaming, o cliente nem o tem inteiro.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Palette = require(Shared:WaitForChild("Palette"))
local Theme = require(Shared:WaitForChild("Theme"))
local WorldConfig = require(Shared:WaitForChild("WorldConfig"))
local HudImages = require(Shared:WaitForChild("HudImages"))
local HudArt = require(script.Parent:WaitForChild("HudArt"))
local Kit = require(script.Parent:WaitForChild("Kit"))

local create = vide.create

local REFRESH = 0.1 -- 10 vezes por segundo

-- Cor de cada bioma no minimapa.
local BIOME_COLORS: { [string]: string } = {
	forest = Palette.biome.forest[1],
	winter = Palette.biome.winter[1],
	lava = Palette.biome.lava[2],
	desert = Palette.biome.desert[1],
}
local LOCKED_SHADE = 0.55 -- quanto escurece uma região ainda fechada

-- Posição no mundo (x, z) → fração do minimapa (0 a 1); o mapa é centrado na origem.
local function toScale(x: number, z: number): (number, number)
	local half = WorldConfig.MAP_SIZE / 2
	return math.clamp((x + half) / WorldConfig.MAP_SIZE, 0, 1), math.clamp((z + half) / WorldConfig.MAP_SIZE, 0, 1)
end

local function toMap(position: Vector3): UDim2
	local x, z = toScale(position.X, position.Z)
	return UDim2.fromScale(x, z)
end

local function sameRect(a: WorldConfig.Rect, b: WorldConfig.Rect): boolean
	return a.minX == b.minX and a.minZ == b.minZ and a.maxX == b.maxX and a.maxZ == b.maxZ
end

-- Um retângulo de bioma; fora da área jogável, com uma sombra por cima.
local function Biome(name: string, area: WorldConfig.Rect): Frame
	local x0, z0 = toScale(area.minX, area.minZ)
	local x1, z1 = toScale(area.maxX, area.maxZ)
	local locked = not sameRect(area, WorldConfig.PLAYABLE)
	return create("Frame")({
		Name = name,
		Position = UDim2.fromScale(x0, z0),
		Size = UDim2.fromScale(x1 - x0, z1 - z0),
		BackgroundColor3 = Theme.color(BIOME_COLORS[name] or Palette.biome.forest[2]),
		BorderSizePixel = 0,
		create("Frame")({
			Name = "Locked",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Theme.ui.panel,
			BackgroundTransparency = if locked then 1 - LOCKED_SHADE else 1,
			BorderSizePixel = 0,
		}),
	}) :: Frame
end

local function Minimap(): Frame
	local dot = vide.source(UDim2.fromScale(0.5, 0.5))
	vide.cleanup(task.spawn(function()
		while true do
			-- Sempre o personagem atual: depois do respawn segue o novo.
			local character = Players.LocalPlayer.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root and root:IsA("BasePart") then
				dot(toMap(root.Position))
			end
			task.wait(REFRESH)
		end
	end))

	local framed = HudImages.has(HudImages.MINIMAP_FRAME)
	-- Com a moldura de madeira, o mapa fica dentro do furo dela.
	local inner = if framed then 1 - 2 * HudImages.MINIMAP_INSET else 0.88
	local ground = create("Frame")({
		Name = "Ground",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(inner, inner),
		-- Fundo = oceano; os biomas por cima.
		BackgroundColor3 = Theme.color(Palette.biome.ocean[3]),
		BorderSizePixel = 0,
		ClipsDescendants = true,
		create("UICorner")({ CornerRadius = Theme.slotCorner }),
		Biome("forest", WorldConfig.BIOMES.forest),
		Biome("winter", WorldConfig.BIOMES.winter),
		Biome("lava", WorldConfig.BIOMES.lava),
		Biome("desert", WorldConfig.BIOMES.desert),
		create("Frame")({
			Name = "PlayerDot",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = dot,
			Size = UDim2.fromScale(0.07, 0.07),
			BackgroundColor3 = Theme.ui.text,
			BorderSizePixel = 0,
			ZIndex = 2,
			create("UICorner")({ CornerRadius = UDim.new(1, 0) }),
		}),
	})
	local children: { Instance } = { create("UIAspectRatioConstraint")({ AspectRatio = 1 }), ground }
	if framed then
		table.insert(
			children,
			HudArt.image(HudImages.MINIMAP_FRAME, { Name = "Frame", ScaleType = Enum.ScaleType.Stretch, ZIndex = 5 })
		)
	end
	local frame: Frame = if framed
		then create("Frame")({ BackgroundTransparency = 1, BorderSizePixel = 0 }) :: Frame
		else Kit.panel({})
	return vide.apply(frame)({
		Name = "Minimap",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(0.98, 0.02),
		Size = UDim2.fromScale(0.15, 0.2),
		children,
	}) :: Frame
end

return Minimap
