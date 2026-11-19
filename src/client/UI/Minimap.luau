--!strict
-- Minimapa (canto superior direito), refeito em 11/11: mostra só o bioma onde
-- o jogador está (na cruz do oceano, o mais perto: MinimapRules.biomeAt), com o
-- desenho dele (a floresta usa a imagem do gerador scripts/groundmap, com o
-- rio, os lagos, a areia e a pedreira; os outros biomas, a cor dele até ganharem
-- desenho) e uma seta na posição do jogador, girada para onde ele olha.
-- Tamanho e lugar vêm do MinimapRules.layout: maior no PC, com o livro e a
-- engrenagem alinhados nas bordas de baixo (CornerLayout).
-- O mapa grande (a tela inteira) vem depois.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Palette = require(Shared:WaitForChild("Palette"))
local StatNames = require(Shared:WaitForChild("StatNames"))
local Theme = require(Shared:WaitForChild("Theme"))
local WorldConfig = require(Shared:WaitForChild("WorldConfig"))
local HudImages = require(Shared:WaitForChild("HudImages"))
local MinimapRules = require(Shared:WaitForChild("World"):WaitForChild("MinimapRules"))
local CornerLayout = require(script.Parent:WaitForChild("CornerLayout"))
local HudArt = require(script.Parent:WaitForChild("HudArt"))
local Kit = require(script.Parent:WaitForChild("Kit"))

local create = vide.create

local REFRESH = 0.1 -- 10 vezes por segundo
local OUTLINE = Color3.fromRGB(45, 28, 16)
local OWN_DOT_COLOR = Theme.rustic.cream
local TEAM_DOT_COLOR = Color3.fromRGB(120, 230, 120)
local MAX_STRUCTURE_DOTS = 200
local OVERLAP = 0.035 -- fração do lado que o mapa entra por baixo da moldura

-- Desenho de cada bioma (gerado por scripts/groundmap: `lune run forest minimap
-- serve`; a linha de cima é −Z e a esquerda −X). Sem imagem: só a cor.
local IMAGES: { [string]: string } = {
	forest = "rbxassetid://83714901539965",
}

-- Cor de fundo de cada bioma (aparece sem imagem ou enquanto ela carrega).
local BIOME_COLORS: { [string]: string } = {
	forest = Palette.biome.forest[1],
	winter = Palette.biome.winter[1],
	lava = Palette.biome.lava[2],
	desert = Palette.biome.desert[1],
}
local LOCKED_SHADE = 0.55 -- quanto escurece um bioma ainda fechado

local function sameRect(a: WorldConfig.Rect, b: WorldConfig.Rect): boolean
	return a.minX == b.minX and a.minZ == b.minZ and a.maxX == b.maxX and a.maxZ == b.maxZ
end

-- Seta do jogador: um círculo claro com uma ponta em cima (losango), girada
-- para onde o boneco olha. Contorno escuro para aparecer na grama e na água.
local function Marker(position: () -> UDim2, rotation: () -> number): Frame
	local function piece(props: { [any]: any }): Frame
		return create("Frame")({
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			create("UIStroke")({ Color = OUTLINE, Thickness = 2 }),
			props,
		}) :: Frame
	end
	return create("Frame")({
		Name = "PlayerMarker",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = position,
		Size = function()
			local side = CornerLayout.get().markerSize
			return UDim2.fromOffset(side, side)
		end,
		Rotation = rotation,
		BackgroundTransparency = 1,
		ZIndex = 3,
		-- Ponta: um quadrado girado 45° no alto do círculo.
		piece({
			Name = "Tip",
			Position = UDim2.fromScale(0.5, 0.12),
			Size = UDim2.fromScale(0.5, 0.5),
			Rotation = 45,
			ZIndex = 3,
		}),
		piece({
			Name = "Body",
			Position = UDim2.fromScale(0.5, 0.55),
			Size = UDim2.fromScale(0.78, 0.78),
			ZIndex = 4,
			create("UICorner")({ CornerRadius = UDim.new(1, 0) }),
		}),
	}) :: Frame
end

type Dot = { position: UDim2, team: boolean }

local function StructureDot(dot: () -> Dot, index: number): Frame
	return create("Frame")({
		Name = `StructureDot{index}`,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = function()
			return dot().position
		end,
		Size = UDim2.fromOffset(4, 4),
		BackgroundColor3 = function()
			return if dot().team then TEAM_DOT_COLOR else OWN_DOT_COLOR
		end,
		BorderSizePixel = 0,
		ZIndex = 2,
		create("UICorner")({ CornerRadius = UDim.new(1, 0) }),
		create("UIStroke")({ Color = OUTLINE, Thickness = 1 }),
	}) :: Frame
end

local function Minimap(): Frame
	local biome = vide.source("forest")
	local position = vide.source(UDim2.fromScale(0.5, 0.5))
	local rotation = vide.source(0)
	local dots = vide.source({} :: { Dot })

	-- Acompanha Workspace.Structures (cuidado com streaming: a pasta ou a peça podem chegar depois).
	local tracked: { [Instance]: boolean } = {}
	local function trackFolder(folder: Instance)
		for _, child in folder:GetChildren() do
			tracked[child] = true
		end
		vide.cleanup(folder.ChildAdded:Connect(function(child)
			tracked[child] = true
		end))
		vide.cleanup(folder.ChildRemoved:Connect(function(child)
			tracked[child] = nil
		end))
	end
	local existing = Workspace:FindFirstChild("Structures")
	if existing then
		trackFolder(existing)
	end
	vide.cleanup(Workspace.ChildAdded:Connect(function(child)
		if child.Name == "Structures" then
			trackFolder(child)
		end
	end))

	vide.cleanup(task.spawn(function()
		while true do
			-- Sempre o personagem atual: depois do respawn segue o novo.
			local me = Players.LocalPlayer
			local character = me.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local px, pz = 0, 0
			local currentBiome = vide.untrack(biome)
			if root and root:IsA("BasePart") then
				local at = root.Position
				px, pz = at.X, at.Z
				local name = MinimapRules.biomeAt(px, pz)
				if currentBiome ~= name then
					currentBiome = name
					biome(name)
				end
				local x, z = MinimapRules.toView(px, pz, WorldConfig.BIOMES[name])
				position(UDim2.fromScale(x, z))
				local look = root.CFrame.LookVector
				rotation(MinimapRules.heading(look.X, look.Z))
			end
			-- Construções do jogador (e do time) no bioma mostrado, limitadas a 200 (as mais perto).
			local myId = me.UserId
			local myTeam = me:GetAttribute(StatNames.Team)
			local teamMembers: { [number]: boolean } = {}
			if type(myTeam) == "number" then
				for _, p in Players:GetPlayers() do
					if p:GetAttribute(StatNames.Team) == myTeam then
						teamMembers[p.UserId] = true
					end
				end
			end
			local rect = WorldConfig.BIOMES[currentBiome]
			local candidates: { { x: number, z: number, distSq: number, team: boolean } } = {}
			for inst in tracked do
				if inst.Parent == nil then
					tracked[inst] = nil
					continue
				end
				local owner = inst:GetAttribute(StatNames.Owner)
				if type(owner) ~= "number" then
					continue
				end
				local isOwn = owner == myId
				local isTeam = not isOwn and teamMembers[owner] == true
				if (isOwn or isTeam) and inst:IsA("PVInstance") then
					local pos = inst:GetPivot().Position
					local dx, dz = pos.X - px, pos.Z - pz
					table.insert(candidates, { x = pos.X, z = pos.Z, distSq = dx * dx + dz * dz, team = isTeam })
				end
			end
			if #candidates > MAX_STRUCTURE_DOTS then
				table.sort(candidates, function(a, b)
					return a.distSq < b.distSq
				end)
			end
			local nextDots: { Dot } = {}
			for i = 1, math.min(#candidates, MAX_STRUCTURE_DOTS) do
				local c = candidates[i]
				local fx, fz = MinimapRules.toView(c.x, c.z, rect)
				table.insert(nextDots, { position = UDim2.fromScale(fx, fz), team = c.team })
			end
			dots(nextDots)
			task.wait(REFRESH)
		end
	end))

	local framed = HudImages.has(HudImages.MINIMAP_FRAME)
	-- Com a moldura de madeira, o mapa fica dentro do furo dela e entra um pouco
	-- por baixo da madeira (OVERLAP): encostado só na borda, sobrava um fio
	-- entre o desenho e a moldura (visto em 11/11).
	local inner = if framed then 1 - 2 * (HudImages.MINIMAP_INSET - OVERLAP) else 0.88
	local ground = create("Frame")({
		Name = "Ground",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(inner, inner),
		BackgroundColor3 = function()
			return Theme.color(BIOME_COLORS[biome()] or Palette.biome.forest[2])
		end,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		create("UICorner")({ CornerRadius = Theme.slotCorner }),
		create("ImageLabel")({
			Name = "Drawing",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ScaleType = Enum.ScaleType.Stretch,
			Image = function()
				return IMAGES[biome()] or ""
			end,
			create("UICorner")({ CornerRadius = Theme.slotCorner }),
		}),
		create("Frame")({
			Name = "Locked",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Theme.ui.panel,
			BackgroundTransparency = function()
				local open = sameRect(WorldConfig.BIOMES[biome()], WorldConfig.PLAYABLE)
				return if open then 1 else 1 - LOCKED_SHADE
			end,
			BorderSizePixel = 0,
			ZIndex = 2,
		}),
		create("Frame")({
			Name = "Structures",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ZIndex = 2,
			vide.indexes(dots, StructureDot),
		}),
		Marker(position, rotation),
	})
	local children: { Instance } = { ground }
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
		Active = true,
		AnchorPoint = Vector2.new(1, 0),
		Position = function()
			local layout = CornerLayout.get()
			return UDim2.new(1, -layout.margin, 0, layout.top)
		end,
		Size = function()
			local side = CornerLayout.get().mapSize
			return UDim2.fromOffset(side, side)
		end,
		children,
	}) :: Frame
end

return Minimap
