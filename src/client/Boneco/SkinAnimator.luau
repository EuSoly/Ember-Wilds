--!strict
-- Mexe as peças animadas das skins (asas do Dragão, tentáculos do Polvo,
-- raízes do Toco, cristais e folhas dos tomos...). Cada peça vem presa por um
-- Motor6D no pivô dela (SkinAssets.attachPart); aqui só se escreve o
-- Transform, como as juntas do próprio boneco. Quem diz o movimento é o
-- Models/SkinMotion, pelo skinId e papel da peça no SkinManifest.
-- Só no cliente e só visual: o boneco fica numa pasta local que não replica.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Models = Shared:WaitForChild("Models")
local SkinAssets = require(Models:WaitForChild("SkinAssets"))
local SkinMotion = require(Models:WaitForChild("SkinMotion"))
local SkinManifest = require(Shared:WaitForChild("Defs"):WaitForChild("SkinManifest"))

export type Joint = { motor: Motor6D, motion: SkinMotion.Motion, route: { SphereHandleAdornment }?, started: number? }

local SkinAnimator = {}

-- Coordenadas da rota no espaço do pivô da agulha (X, Z, -Y do FBX).
local ROUTE =
	{ Vector3.new(0.752, -0.115, -1.102), Vector3.new(1.032, -0.115, -1.412), Vector3.new(1.392, -0.115, -1.522) }

local function compassRoute(motor: Motor6D): { SphereHandleAdornment }
	local dots: { SphereHandleAdornment } = {}
	for i, offset in ROUTE do
		local name = `Rota{i}`
		local found = motor:FindFirstChild(name)
		local dot: SphereHandleAdornment
		if found and found:IsA("SphereHandleAdornment") then
			dot = found
		else
			dot = Instance.new("SphereHandleAdornment")
			dot.Name = name
			dot.Adornee = motor.Part0 :: BasePart
			dot.CFrame = motor.C0 * CFrame.new(offset)
			dot.Radius = 0.065
			dot.Color3 = Color3.fromRGB(255, 206, 106)
			dot.Visible = false
			dot.Parent = motor
		end
		table.insert(dots, dot)
	end
	return dots
end

-- Juntas animadas dentro de `root` (o boneco inteiro: corpo, livro na mão).
function SkinAnimator.collect(root: Instance): { Joint }
	local joints: { Joint } = {}
	for _, descendant in root:GetDescendants() do
		if descendant:IsA("Motor6D") and descendant.Name == SkinAssets.ANIM_JOINT then
			local part = descendant.Part1
			local info = part and SkinManifest.PARTS[part.Name]
			local motion = info and SkinMotion.of(info.skinId, info.papel)
			if motion then
				local started: number?, route: { SphereHandleAdornment }?
				if motion.compass then
					local saved = descendant:GetAttribute("CompassStarted")
					started = if type(saved) == "number" then saved else os.clock()
					descendant:SetAttribute("CompassStarted", started)
					route = compassRoute(descendant)
				end
				table.insert(joints, { motor = descendant, motion = motion, started = started, route = route })
			end
		end
	end
	return joints
end

-- Põe cada junta na pose do tempo `t` (s), com a fase dos passos e a fração
-- de velocidade do boneco (BonecoAnim.State.phase e speedFraction).
function SkinAnimator.step(joints: { Joint }, t: number, stepPhase: number, walk: number)
	for _, joint in joints do
		local elapsed = if joint.started then t - joint.started else t
		if joint.route then
			for i, dot in joint.route do
				dot.Visible = SkinMotion.compassDot(i, elapsed)
			end
		end
		local p = SkinMotion.pose(joint.motion, elapsed, stepPhase, walk)
		joint.motor.Transform = CFrame.new(p.px, p.py, p.pz) * CFrame.Angles(p.x, p.y, p.z)
	end
end

return SkinAnimator
