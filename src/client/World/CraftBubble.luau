--!strict
-- Engrenagem e progresso do craft acima de todos os bonecos.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Defs = require(Shared:WaitForChild("Defs"))
local StatNames = require(Shared:WaitForChild("StatNames"))
local Theme = require(Shared:WaitForChild("Theme"))
local StatusRing = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("StatusRing"))

local OFFSET = Vector3.new(0, 4.5, 0)
local SIZE = UDim2.fromOffset(54, 54)
local bubbles: { [Model]: { gui: BillboardGui, gear: TextLabel, progress: (number) -> (), cleanup: () -> () } } = {}
local watched: { [Model]: boolean } = {}
local CraftBubble = {}

local function add(character: Model)
	if bubbles[character] then
		return
	end
	local rootPart = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
	if rootPart == nil or not rootPart:IsA("BasePart") then
		return
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "CraftBubble"
	gui.Size = SIZE
	gui.StudsOffset = OFFSET
	gui.AlwaysOnTop = false
	gui.LightInfluence = 0
	gui.Adornee = rootPart
	gui.Enabled = false
	local root = Instance.new("Frame")
	root.Name = "Root"
	root.BackgroundTransparency = 1
	root.Size = UDim2.fromScale(1, 1)
	root.Parent = gui
	local progressSource = vide.source(0)
	local cleanup = vide.mount(function()
		return StatusRing({
			value = function()
				return progressSource() * StatNames.StatusMax
			end,
			color = Theme.ui.action,
			name = "CraftProgress",
		})
	end, root)
	local gear = Instance.new("TextLabel")
	gear.Name = "Gear"
	gear.BackgroundTransparency = 1
	gear.AnchorPoint = Vector2.new(0.5, 0.5)
	gear.Position = UDim2.fromScale(0.5, 0.5)
	gear.Size = UDim2.fromScale(0.58, 0.58)
	gear.FontFace = Theme.font.number
	gear.Text = "⚙"
	gear.TextColor3 = Theme.ui.text
	gear.TextScaled = true
	gear.ZIndex = 4
	gear.Parent = root
	gui.Parent = rootPart
	bubbles[character] = { gui = gui, gear = gear, progress = progressSource, cleanup = cleanup }
end

local function remove(character: Model)
	local bubble = bubbles[character]
	if bubble then
		bubble.cleanup()
		bubble.gui:Destroy()
		bubbles[character] = nil
	end
	watched[character] = nil
end

function CraftBubble.start()
	local function update(character: Model)
		local recipeId = character:GetAttribute(StatNames.CraftRecipe)
		local started = character:GetAttribute(StatNames.CraftStart)
		local ends = character:GetAttribute(StatNames.CraftEnd)
		local active = type(recipeId) == "string"
			and Defs.Recipes[recipeId] ~= nil
			and type(started) == "number"
			and type(ends) == "number"
		local bubble = bubbles[character]
		if not active then
			if bubble then
				bubble.gui.Enabled = false
			end
			return
		end
		if bubble == nil then
			add(character)
			bubble = bubbles[character]
		end
		if bubble then
			bubble.gui.Enabled = true
			bubble.progress(
				math.clamp(
					(Workspace:GetServerTimeNow() - (started :: number))
						/ math.max((ends :: number) - (started :: number), 1e-3),
					0,
					1
				)
			)
			bubble.gear.Rotation = (os.clock() * 240) % 360
		end
	end

	local function watch(character: Instance)
		if not character:IsA("Model") then
			return
		end
		if watched[character] then
			return
		end
		watched[character] = true
		character:GetAttributeChangedSignal(StatNames.CraftRecipe):Connect(function()
			update(character)
		end)
		character:GetAttributeChangedSignal(StatNames.CraftEnd):Connect(function()
			update(character)
		end)
		update(character)
	end
	CollectionService:GetInstanceAddedSignal(StatNames.BonecoTag):Connect(watch)
	CollectionService:GetInstanceRemovedSignal(StatNames.BonecoTag):Connect(function(character)
		if character:IsA("Model") then
			remove(character)
		end
	end)
	for _, character in CollectionService:GetTagged(StatNames.BonecoTag) do
		watch(character)
	end
	-- Todo boneco com engrenagem está em `watched`: um passe só por quadro.
	RunService.RenderStepped:Connect(function()
		for character in watched do
			if character.Parent == nil then
				remove(character)
			else
				update(character)
			end
		end
	end)
end

return CraftBubble
