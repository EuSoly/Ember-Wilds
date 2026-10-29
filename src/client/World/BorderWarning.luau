--!strict
-- Aviso de borda: quando o próprio boneco chega perto da borda da área
-- jogável (WorldConfig.PLAYABLE, a floresta no lançamento), mostra
-- "Região ainda não descoberta" na HUD. As paredes de Map/Borders é que
-- impedem de passar; isto só explica por quê.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("WorldConfig"))
local Notifications = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Notifications"))

local CHECK_EVERY = 0.5 -- segundos
local COOLDOWN = 4 -- no máximo um aviso a cada 4 s
local TEXT_KEY = "world.locked"

local BorderWarning = {}

-- Distância (studs, no plano) até a borda mais perto da área jogável.
local function distanceToEdge(x: number, z: number): number
	local area = WorldConfig.PLAYABLE
	return math.min(x - area.minX, area.maxX - x, z - area.minZ, area.maxZ - z)
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
				local near = distanceToEdge(root.Position.X, root.Position.Z) < WorldConfig.BORDER_WARNING_DISTANCE
				if near and now - lastWarning >= COOLDOWN then
					lastWarning = now
					Notifications.push(TEXT_KEY)
				end
			end
		end
	end)
end

return BorderWarning
