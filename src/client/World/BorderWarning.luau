--!strict
-- Aviso de volta para a terra: em volta da terra firme (WorldConfig.LAND, a
-- floresta e a praia no lançamento) é mar. Quando o próprio boneco sai da terra
-- e entra no mar (mais de SEA_WARNING_DEPTH studs), mostra "Volte para a terra!"
-- na HUD, repetindo enquanto ele estiver lá. As paredes invisíveis de
-- Map/Borders (a SEA_MARGIN da praia) é que impedem de ir mais longe.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("WorldConfig"))
local Notifications = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Notifications"))

local CHECK_EVERY = 0.5 -- segundos
local COOLDOWN = 4 -- no máximo um aviso a cada 4 s
local TEXT_KEY = "world.backToLand"

local BorderWarning = {}

-- Quanto (studs, no plano) o ponto está fora da terra firme; 0 ou menos = em terra.
local function distanceOutside(x: number, z: number): number
	local area = WorldConfig.LAND
	return math.max(area.minX - x, x - area.maxX, area.minZ - z, z - area.maxZ)
end

-- Liga o aviso (chamado uma vez pelo WorldFxController).
function BorderWarning.start()
	local lastWarning = -math.huge
	task.spawn(function()
		while true do
			task.wait(CHECK_EVERY)
			local character = Players.LocalPlayer.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root and root:IsA("BasePart") then
				local now = os.clock()
				local atSea = distanceOutside(root.Position.X, root.Position.Z) > WorldConfig.SEA_WARNING_DEPTH
				if atSea and now - lastWarning >= COOLDOWN then
					lastWarning = now
					Notifications.push(TEXT_KEY, nil, "alert")
				end
			end
		end
	end)
end

return BorderWarning
