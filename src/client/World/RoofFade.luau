--!strict
-- Telhados translúcidos (G8; 11/11): a câmera é de cima, então o telhado
-- esconderia quem está embaixo. Estando debaixo de algum telhado (tag Roof +
-- PieceRadius, TaggedCircles), TODOS os telhados a até VIEW_RADIUS (a tela) ficam
-- semitransparentes só para este jogador (LocalTransparencyModifier); saindo de
-- baixo, voltam ao normal (BuildRules.roofsToFade).
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
local VIEW_RADIUS = 80 -- studs: o que cabe na tela com a câmera de cima

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
			local circles, owners = TaggedCircles.list(roofs)
			for i in BuildRules.roofsToFade(root.Position.X, root.Position.Z, circles, VIEW_RADIUS) do
				now[owners[i]] = true
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
