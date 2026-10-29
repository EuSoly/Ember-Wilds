--!strict
-- Minimapa (canto superior direito). Por enquanto mostra o chão da floresta e
-- um ponto na posição do jogador; o mapa desenhado de verdade entra na Fase 6.
-- Lê só a posição do próprio personagem (o resto do mundo pode nem estar
-- carregado por causa do streaming).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Palette = require(Shared:WaitForChild("Palette"))
local Theme = require(Shared:WaitForChild("Theme"))
local WorldConfig = require(Shared:WaitForChild("WorldConfig"))
local Kit = require(script.Parent:WaitForChild("Kit"))

local create = vide.create

local REFRESH = 0.1 -- 10 vezes por segundo

-- Posição no mundo (x, z) → posição no minimapa (0 a 1).
local function toMap(position: Vector3): UDim2
	local half = WorldConfig.size / 2
	return UDim2.fromScale(
		math.clamp((position.X + half) / WorldConfig.size, 0, 1),
		math.clamp((position.Z + half) / WorldConfig.size, 0, 1)
	)
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

	return Kit.panel({
		Name = "Minimap",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(0.98, 0.02),
		Size = UDim2.fromScale(0.15, 0.2),
		create("UIAspectRatioConstraint")({ AspectRatio = 1 }),
		create("Frame")({
			Name = "Ground",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.88, 0.88),
			BackgroundColor3 = Theme.color(Palette.biome.forest[2]),
			BorderSizePixel = 0,
			create("UICorner")({ CornerRadius = Theme.slotCorner }),
			create("Frame")({
				Name = "PlayerDot",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = dot,
				Size = UDim2.fromScale(0.08, 0.08),
				BackgroundColor3 = Theme.ui.text,
				BorderSizePixel = 0,
				create("UICorner")({ CornerRadius = UDim.new(1, 0) }),
			}),
		}),
	})
end

return Minimap
