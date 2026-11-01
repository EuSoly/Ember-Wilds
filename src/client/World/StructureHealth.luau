--!strict
-- Barrinha de vida acima de uma peça de construção: aparece por 3 s sempre que
-- o atributo StructureHealth muda. As peças chegam e saem pelo streaming, então
-- cada uma é seguida enquanto existe e a barra é limpa quando ela some.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local StatNames = require(Shared:WaitForChild("StatNames"))
local Theme = require(Shared:WaitForChild("Theme"))

local SHOW_SECONDS = 3
local BAR_SIZE = UDim2.fromOffset(70, 9)
local LOW_FRACTION = 0.35

local StructureHealth = {}

type Tracked = { last: number?, hideAt: number, gui: BillboardGui?, fill: Frame? }

local function adorneeOf(piece: Instance): BasePart?
	if piece:IsA("BasePart") then
		return piece
	end
	if piece:IsA("Model") and piece.PrimaryPart then
		return piece.PrimaryPart
	end
	return piece:FindFirstChildWhichIsA("BasePart", true)
end

local function heightOf(piece: Instance): number
	if piece:IsA("Model") then
		return piece:GetExtentsSize().Y
	elseif piece:IsA("BasePart") then
		return piece.Size.Y
	end
	return 4
end

local function makeGui(piece: Instance, adornee: BasePart): (BillboardGui, Frame)
	local gui = Instance.new("BillboardGui")
	gui.Name = "StructureHealth"
	gui.Size = BAR_SIZE
	gui.StudsOffset = Vector3.new(0, heightOf(piece) / 2 + 1.5, 0)
	gui.AlwaysOnTop = false
	gui.LightInfluence = 0
	gui.Adornee = adornee
	gui.Enabled = false
	local back = Instance.new("Frame")
	back.Name = "Back"
	back.Size = UDim2.fromScale(1, 1)
	back.BackgroundColor3 = Theme.ui.panel
	back.BackgroundTransparency = 0.15
	back.BorderSizePixel = 0
	back.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.ui.border
	stroke.Parent = back
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BorderSizePixel = 0
	fill.Parent = back
	-- No PlayerGui: local, não replica.
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	return gui, fill
end

function StructureHealth.start()
	local tracked: { [Instance]: Tracked } = {}

	local function untrack(piece: Instance)
		local entry = tracked[piece]
		if entry then
			if entry.gui then
				entry.gui:Destroy()
			end
			tracked[piece] = nil
		end
	end

	local function track(piece: Instance)
		if tracked[piece] == nil then
			local health = piece:GetAttribute(StatNames.StructureHealth)
			tracked[piece] = {
				last = if typeof(health) == "number" then health else nil,
				hideAt = 0,
				gui = nil,
				fill = nil,
			}
		end
	end

	CollectionService:GetInstanceAddedSignal(StatNames.StructureTag):Connect(track)
	CollectionService:GetInstanceRemovedSignal(StatNames.StructureTag):Connect(untrack)
	for _, piece in CollectionService:GetTagged(StatNames.StructureTag) do
		track(piece)
	end

	-- Polling: não depende de AttributeChanged (que falha com Server Authority).
	RunService.Heartbeat:Connect(function()
		local now = os.clock()
		for piece, entry in tracked do
			if piece.Parent == nil then
				untrack(piece)
				continue
			end
			local health = piece:GetAttribute(StatNames.StructureHealth)
			if typeof(health) == "number" and health ~= entry.last then
				entry.last = health
				entry.hideAt = now + SHOW_SECONDS
				local max = piece:GetAttribute(StatNames.StructureHealthMax)
				local fraction = if typeof(max) == "number" and max > 0 then math.clamp(health / max, 0, 1) else 0
				if entry.gui == nil then
					local adornee = adorneeOf(piece)
					if adornee then
						entry.gui, entry.fill = makeGui(piece, adornee)
					end
				end
				local fill = entry.fill
				if fill then
					fill.Size = UDim2.fromScale(fraction, 1)
					fill.BackgroundColor3 = if fraction <= LOW_FRACTION then Theme.ui.danger else Theme.ui.success
				end
				if entry.gui then
					entry.gui.Enabled = true
				end
			end
			if entry.gui and entry.gui.Enabled and now >= entry.hideAt then
				entry.gui.Enabled = false
			end
		end
	end)
end

return StructureHealth
