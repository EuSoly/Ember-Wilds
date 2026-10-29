--!strict
-- Lê a ação "bater" (Use) dentro da simulação e marca no personagem o atributo
-- `Using` (true enquanto o jogador segura). A fase de combate/coleta lê esse
-- atributo para dar os golpes no ritmo da ferramenta.
-- Roda nos dois lados, como o FacingSim (servidor = autoridade, cliente = predição).
local RunService = game:GetService("RunService")

local InputNames = require("../InputNames")

local ATTRIBUTE = "Using"

local UseSim = {}

local function readUse(player: Player): boolean
	local context = player:FindFirstChild(InputNames.Context)
	local action = context and context:FindFirstChild(InputNames.Use)
	if action and action:IsA("InputAction") then
		return action:GetState() == true
	end
	return false
end

function UseSim.start(getPlayers: () -> { Player }): RBXScriptConnection
	return RunService:BindToSimulation(function()
		for _, player in getPlayers() do
			local character = player.Character
			if character then
				local using = readUse(player)
				-- Só escreve quando muda, para não replicar à toa.
				if character:GetAttribute(ATTRIBUTE) ~= using then
					character:SetAttribute(ATTRIBUTE, using)
				end
			end
		end
	end, Enum.StepFrequency.Hz60)
end

return UseSim
