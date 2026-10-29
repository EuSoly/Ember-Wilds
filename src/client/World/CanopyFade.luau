--!strict
-- Copas transparentes: a câmera é de cima, então a copa de uma árvore
-- esconderia o boneco que passa embaixo dela. As peças com a tag Occluder
-- (copas) que ficam entre a câmera e o PRÓPRIO boneco ficam semitransparentes
-- só para este jogador (LocalTransparencyModifier) e voltam ao normal depois.
--
-- Barato: só olha copas perto do boneco (no plano) e mede a distância do
-- centro de cada uma até a linha câmera → boneco.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local StatNames = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("StatNames"))

local CHECK_EVERY = 0.1 -- segundos
local FADED = 0.6 -- 0 = normal, 1 = invisível
local NEAR = 24 -- só copas a até essa distância (studs, no plano) do boneco

local CanopyFade = {}

-- Distância do ponto `p` ao segmento de `a` até `b`.
local function distanceToSegment(p: Vector3, a: Vector3, b: Vector3): number
	local ab = b - a
	local lengthSquared = ab:Dot(ab)
	if lengthSquared == 0 then
		return (p - a).Magnitude
	end
	local t = math.clamp((p - a):Dot(ab) / lengthSquared, 0, 1)
	return (p - (a + ab * t)).Magnitude
end

local function covers(part: BasePart, from: Vector3, to: Vector3): boolean
	local radius = math.max(part.Size.X, part.Size.Y, part.Size.Z) / 2
	return distanceToSegment(part.Position, from, to) < radius
end

-- Liga o efeito (chamado uma vez pelo WorldFxController).
function CanopyFade.start()
	local faded: { [BasePart]: boolean } = {}
	task.spawn(function()
		while true do
			task.wait(CHECK_EVERY)
			local character = Players.LocalPlayer.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local camera = Workspace.CurrentCamera
			local now: { [BasePart]: boolean } = {}
			if root and root:IsA("BasePart") and camera then
				local target = root.Position
				local eye = camera.CFrame.Position
				for _, instance in CollectionService:GetTagged(StatNames.OccluderTag) do
					if instance:IsA("BasePart") then
						local offset = instance.Position - target
						if
							offset.X * offset.X + offset.Z * offset.Z < NEAR * NEAR and covers(instance, eye, target)
						then
							now[instance] = true
						end
					end
				end
			end
			-- Só mexe nas que mudaram.
			for part in now do
				if not faded[part] then
					part.LocalTransparencyModifier = FADED
				end
			end
			for part in faded do
				if not now[part] and part.Parent then
					part.LocalTransparencyModifier = 0
				end
			end
			faded = now
		end
	end)
end

return CanopyFade
