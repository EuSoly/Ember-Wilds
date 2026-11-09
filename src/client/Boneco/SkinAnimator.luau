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

export type Joint = { motor: Motor6D, motion: SkinMotion.Motion }

local SkinAnimator = {}

-- Juntas animadas dentro de `root` (o boneco inteiro: corpo, livro na mão).
function SkinAnimator.collect(root: Instance): { Joint }
	local joints: { Joint } = {}
	for _, descendant in root:GetDescendants() do
		if descendant:IsA("Motor6D") and descendant.Name == SkinAssets.ANIM_JOINT then
			local part = descendant.Part1
			local info = part and SkinManifest.PARTS[part.Name]
			local motion = info and SkinMotion.of(info.skinId, info.papel)
			if motion then
				table.insert(joints, { motor = descendant, motion = motion })
			end
		end
	end
	return joints
end

-- Põe cada junta na pose do tempo `t` (s), com a fase dos passos e a fração
-- de velocidade do boneco (BonecoAnim.State.phase e speedFraction).
function SkinAnimator.step(joints: { Joint }, t: number, stepPhase: number, walk: number)
	for _, joint in joints do
		local p = SkinMotion.pose(joint.motion, t, stepPhase, walk)
		joint.motor.Transform = CFrame.new(p.px, p.py, p.pz) * CFrame.Angles(p.x, p.y, p.z)
	end
end

return SkinAnimator
