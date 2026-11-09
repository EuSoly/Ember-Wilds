--!strict
-- Engrenagem e progresso do craft acima do PRÓPRIO boneco: o medalhão dos
-- anéis de status com o arco enchendo e a engrenagem (HudImages.ICON.settings)
-- girando no meio. Só o dono vê: os
-- outros jogadores não podem saber que alguém está craftando (o servidor manda
-- o estado só para o dono, via CraftState).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local CraftRules = require(Shared:WaitForChild("Craft"):WaitForChild("CraftRules"))
local HudImages = require(Shared:WaitForChild("HudImages"))
local StatNames = require(Shared:WaitForChild("StatNames"))
local Theme = require(Shared:WaitForChild("Theme"))
local CraftState = require(script.Parent.Parent:WaitForChild("CraftState"))
local StatusRing = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("StatusRing"))

local OFFSET = Vector3.new(0, 4.5, 0)
local SIZE = UDim2.fromOffset(60, 60)
-- Graus por segundo da engrenagem.
local SPIN_SPEED = 240

local CraftBubble = {}

type Bubble = { gui: BillboardGui, gear: GuiObject, progress: (number) -> (), cleanup: () -> () }

local function build(adornee: BasePart): Bubble
	local gui = Instance.new("BillboardGui")
	gui.Name = "CraftBubble"
	gui.Size = SIZE
	gui.StudsOffset = OFFSET
	gui.AlwaysOnTop = false
	gui.LightInfluence = 0
	gui.Adornee = adornee
	gui.Enabled = false
	local root = Instance.new("Frame")
	root.Name = "Root"
	root.BackgroundTransparency = 1
	root.Size = UDim2.fromScale(1, 1)
	root.Parent = gui
	local progress = vide.source(0)
	local cleanup = vide.mount(function()
		return StatusRing({
			value = function()
				return progress() * StatNames.StatusMax
			end,
			color = Theme.ui.action,
			name = "CraftProgress",
			-- Enchendo não é alerta: sem pulso.
			warning = function()
				return false
			end,
			critical = function()
				return false
			end,
		})
	end, root)
	local gear: GuiObject
	if HudImages.has(HudImages.ICON.settings) then
		local image = Instance.new("ImageLabel")
		image.Image = HudImages.ICON.settings
		image.ScaleType = Enum.ScaleType.Fit
		image.Size = UDim2.fromScale(0.42, 0.42)
		gear = image
	else
		local text = Instance.new("TextLabel")
		text.FontFace = Theme.font.number
		text.Text = "⚙"
		text.TextColor3 = Theme.ui.text
		text.TextScaled = true
		text.Size = UDim2.fromScale(0.58, 0.58)
		gear = text
	end
	gear.Name = "Gear"
	gear.BackgroundTransparency = 1
	gear.AnchorPoint = Vector2.new(0.5, 0.5)
	gear.Position = UDim2.fromScale(0.5, 0.5)
	gear.ZIndex = 7 -- acima do medalhão (5)
	gear.Parent = root
	-- No PlayerGui (local, não replica), preso ao personagem pelo Adornee.
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	return { gui = gui, gear = gear, progress = progress, cleanup = cleanup }
end

local function destroy(bubble: Bubble)
	bubble.cleanup()
	bubble.gui:Destroy()
end

function CraftBubble.start()
	local bubble: Bubble? = nil
	RunService.RenderStepped:Connect(function()
		local character = Players.LocalPlayer.Character
		local adornee = character and (character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart"))
		-- Personagem novo (ou nenhum): refaz a bolha presa ao corpo atual.
		if bubble and (adornee == nil or bubble.gui.Adornee ~= adornee) then
			destroy(bubble)
			bubble = nil
		end
		if adornee == nil or not adornee:IsA("BasePart") then
			return
		end
		local current = CraftState.current()
		if bubble == nil then
			if current == nil then
				return
			end
			bubble = build(adornee)
		end
		local active = bubble :: Bubble
		active.gui.Enabled = current ~= nil
		if current then
			active.progress(CraftRules.progress(current.start, current.finish, Workspace:GetServerTimeNow()))
			active.gear.Rotation = (os.clock() * SPIN_SPEED) % 360
		end
	end)
end

return CraftBubble
