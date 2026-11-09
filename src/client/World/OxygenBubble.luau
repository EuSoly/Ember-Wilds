--!strict
-- Fôlego ao lado do próprio boneco: o medalhão dos anéis de status com o
-- ícone de bolha (HudImages.STATUS_ICON.oxygen) e o arco do fôlego (atributo
-- Oxygen do Player). Pulsa perto do fim e o trilho pisca zerado; só aparece
-- enquanto o jogador está na água ou o fôlego não está cheio. Só o próprio
-- jogador vê.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local HudImages = require(Shared:WaitForChild("HudImages"))
local Palette = require(Shared:WaitForChild("Palette"))
local StatNames = require(Shared:WaitForChild("StatNames"))
local Theme = require(Shared:WaitForChild("Theme"))
local StatusRing = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("StatusRing"))

local SIZE = UDim2.fromOffset(52, 52)
local OFFSET = Vector3.new(3.4, 2.4, 0) -- ao lado e um pouco acima do corpo
local LOW_FRACTION = 0.25 -- abaixo disso o medalhão pulsa

local OxygenBubble = {}

-- Liga a bolha (chamado uma vez pelo WorldFxController).
function OxygenBubble.start()
	local player = Players.LocalPlayer
	local gui = Instance.new("BillboardGui")
	gui.Name = "OxygenBubble"
	gui.Size = SIZE
	gui.StudsOffset = OFFSET
	-- AlwaysOnTop = false de propósito: testado no Studio (29/10), com true a
	-- bolha não aparecia. Ela fica acima do corpo, então quase nada a cobre.
	gui.AlwaysOnTop = false
	gui.LightInfluence = 0
	gui.ResetOnSpawn = false
	gui.Enabled = false
	local root = Instance.new("Frame")
	root.Name = "Root"
	root.BackgroundTransparency = 1
	root.Size = UDim2.fromScale(1, 1)
	root.Parent = gui

	local fraction = vide.source(1)
	vide.mount(function()
		return StatusRing({
			name = "Oxygen",
			value = function()
				return fraction() * StatNames.StatusMax
			end,
			color = Theme.color(Palette.status.oxygen),
			icon = HudImages.STATUS_ICON.oxygen,
			warning = function()
				return fraction() < LOW_FRACTION
			end,
		})
	end, root)
	gui.Parent = player:WaitForChild("PlayerGui")

	RunService.RenderStepped:Connect(function()
		local character = player.Character
		local rootPart = character and character:FindFirstChild("HumanoidRootPart")
		local oxygen = player:GetAttribute(StatNames.Oxygen)
		local current = if type(oxygen) == "number" then math.clamp(oxygen / StatNames.StatusMax, 0, 1) else 1
		local inWater = player:GetAttribute(StatNames.InWater) == true
		local visible = rootPart ~= nil and (inWater or current < 1)

		gui.Enabled = visible
		if not visible then
			return
		end
		if gui.Adornee ~= rootPart then
			gui.Adornee = rootPart
		end
		if current ~= vide.untrack(fraction) then
			fraction(current)
		end
	end)
end

return OxygenBubble
