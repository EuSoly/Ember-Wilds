--!strict
-- Bolha de ar ao lado do próprio boneco: mostra o fôlego (atributo Oxygen do
-- Player). Esvazia conforme o fôlego cai, pisca perto do fim e só aparece
-- enquanto o jogador está na água ou o fôlego não está cheio. Só o próprio
-- jogador vê a sua bolha.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Palette = require(Shared:WaitForChild("Palette"))
local StatNames = require(Shared:WaitForChild("StatNames"))
local Theme = require(Shared:WaitForChild("Theme"))

local SIZE = UDim2.fromOffset(40, 40)
local OFFSET = Vector3.new(3.2, 2.4, 0) -- ao lado e um pouco acima do corpo
local LOW_FRACTION = 0.25 -- abaixo disso a bolha pisca
local BLINK_SPEED = 8 -- piscadas (radianos) por segundo

local OxygenBubble = {}

local function makeGui(): (BillboardGui, Frame, UIStroke)
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

	-- Contorno da bolha (sempre inteiro) e o ar dentro (encolhe com o fôlego).
	local shell = Instance.new("Frame")
	shell.Name = "Shell"
	shell.Size = UDim2.fromScale(1, 1)
	shell.BackgroundTransparency = 1
	local shellCorner = Instance.new("UICorner")
	shellCorner.CornerRadius = UDim.new(1, 0)
	shellCorner.Parent = shell
	-- Contorno escuro (cor dos painéis): a cor do fôlego é clara e sumiria
	-- sobre a água e a neve.
	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.ui.panel
	stroke.Thickness = 2.5
	stroke.Parent = shell
	shell.Parent = gui

	local air = Instance.new("Frame")
	air.Name = "Air"
	air.AnchorPoint = Vector2.new(0.5, 0.5)
	air.Position = UDim2.fromScale(0.5, 0.5)
	air.Size = UDim2.fromScale(1, 1)
	air.BackgroundColor3 = Theme.color(Palette.status.oxygen)
	air.BackgroundTransparency = 0.1
	air.BorderSizePixel = 0
	local airCorner = Instance.new("UICorner")
	airCorner.CornerRadius = UDim.new(1, 0)
	airCorner.Parent = air
	air.Parent = shell

	return gui, air, stroke
end

-- Liga a bolha (chamado uma vez pelo WorldFxController).
function OxygenBubble.start()
	local player = Players.LocalPlayer
	local gui, air, stroke = makeGui()
	gui.Parent = player:WaitForChild("PlayerGui")

	RunService.RenderStepped:Connect(function()
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local oxygen = player:GetAttribute(StatNames.Oxygen)
		local fraction = if type(oxygen) == "number" then oxygen / StatNames.StatusMax else 1
		local inWater = player:GetAttribute(StatNames.InWater) == true
		local visible = root ~= nil and (inWater or fraction < 1)

		gui.Enabled = visible
		if not visible then
			return
		end
		if gui.Adornee ~= root then
			gui.Adornee = root
		end
		air.Size = UDim2.fromScale(fraction, fraction)
		if fraction < LOW_FRACTION then
			-- Pisca: o ar some e volta, para chamar atenção.
			local pulse = 0.5 + 0.5 * math.sin(os.clock() * BLINK_SPEED)
			air.BackgroundTransparency = 0.1 + 0.7 * pulse
			stroke.Transparency = 0.6 * pulse
		else
			air.BackgroundTransparency = 0.1
			stroke.Transparency = 0
		end
	end)
end

return OxygenBubble
