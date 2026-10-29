--!strict
-- Corpo simulado do personagem (o StarterCharacter): só o que a física e o
-- Server Authority precisam, tudo invisível e igual para todos (mesmo hitbox).
-- - HumanoidRootPart: o colisor; anda (PlayerModule) e gira (FacingSim).
-- - Head: invisível e sem colisão, só para o balão do chat ter onde aparecer.
-- - Humanoid: sem pulo, sem rotação automática, sem nome/vida padrão.
-- O que aparece na tela é o boneco visual que cada cliente monta (BonecoModel).
-- (Só roda no Roblox: cria instâncias.)
local C = require("../BonecoConfig")

local CharacterBody = {}

function CharacterBody.build(): Model
	local model = Instance.new("Model")
	model.Name = "StarterCharacter"

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(C.ROOT_WIDTH, C.ROOT_HEIGHT, C.ROOT_DEPTH)
	root.Transparency = 1
	root.CanCollide = true
	root.CastShadow = false
	root.Anchored = false
	root.TopSurface = Enum.SurfaceType.Smooth
	root.BottomSurface = Enum.SurfaceType.Smooth
	-- Centro a HIP_HEIGHT + ROOT_HEIGHT/2 do chão (o spawn reposiciona de qualquer jeito).
	root.CFrame = CFrame.new(0, C.HIP_HEIGHT + C.ROOT_HEIGHT / 2, 0)
	root.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.one
	head.Transparency = 1
	head.CanCollide = false
	head.CanQuery = false
	head.CanTouch = false
	head.Massless = true
	head.CastShadow = false
	head.CFrame = root.CFrame * CFrame.new(0, C.HEAD_HEIGHT, 0)
	head.Parent = model

	local neck = Instance.new("Motor6D")
	neck.Name = "Neck"
	neck.Part0 = root
	neck.Part1 = head
	neck.C0 = CFrame.new(0, C.HEAD_HEIGHT, 0)
	neck.Parent = root

	local humanoid = Instance.new("Humanoid")
	humanoid.RigType = Enum.HumanoidRigType.R15
	humanoid.HipHeight = C.HIP_HEIGHT
	humanoid.AutoRotate = false
	humanoid.UseJumpPower = false
	humanoid.JumpHeight = 0
	humanoid.RequiresNeck = false
	humanoid.BreakJointsOnDeath = false
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.Parent = model

	model.PrimaryPart = root
	return model
end

return CharacterBody
