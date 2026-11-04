--!strict
-- Telhado translúcido sobre o próprio boneco (G8): a câmera é de cima, então o
-- telhado esconderia quem está embaixo. Os telhados (tag Roof + PieceRadius,
-- TaggedCircles) cujo círculo contém a raiz do personagem local ficam
-- semitransparentes só para este jogador (LocalTransparencyModifier) e voltam
-- ao normal quando ele sai de baixo.
-- A posição é lida a cada quadro (não por sinal de atributo: com o Server
-- Authority o personagem local é previsto).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Build = Shared:WaitForChild("Build")
local BuildRules = require(Build:WaitForChild("BuildRules"))
local StatNames = require(Shared:WaitForChild("StatNames"))
local TaggedCircles = require(Build:WaitForChild("TaggedCircles"))

local FADED = 0.7 -- 0 = normal, 1 = invisível

local RoofFade = {}

-- As peças do telhado (o modelo do Elizeu em Visual ou o provisório) e as
-- texturas/decals delas.
local function setFade(model: Model, value: number)
	for _, part in model:GetDescendants() do
		if not part:IsA("BasePart") then
			continue
		end
		part.LocalTransparencyModifier = value
		for _, child in part:GetChildren() do
			if child:IsA("Decal") then
				child.LocalTransparencyModifier = value
			end
		end
	end
end

-- Liga o efeito (chamado uma vez pelo WorldFxController).
function RoofFade.start()
	local roofs = TaggedCircles.watch(StatNames.RoofTag, StatNames.PieceRadius)
	local faded: { [Model]: boolean } = {}
	RunService.RenderStepped:Connect(function()
		local character = Players.LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local now: { [Model]: boolean } = {}
		if root and root:IsA("BasePart") then
			local x, z = root.Position.X, root.Position.Z
			local circles, owners = TaggedCircles.list(roofs)
			for i, circle in circles do
				if BuildRules.touchesCircle(x, z, circle.x, circle.z, circle.r, 0) then
					now[owners[i]] = true
				end
			end
		end
		-- Só mexe nos que mudaram.
		for model in now do
			if not faded[model] then
				setFade(model, FADED)
			end
		end
		for model in faded do
			if not now[model] and model.Parent then
				setFade(model, 0)
			end
		end
		faded = now
	end)
end

return RoofFade
