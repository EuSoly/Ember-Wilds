--!strict
-- Barrinha de vida acima de uma peça de construção ou de uma caixa de itens
-- (G6, mesmos atributos): aparece por 3 s sempre que o atributo StructureHealth muda. As peças chegam e saem pelo streaming, então
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

local function makeGui(piece: Instance, adornee: BasePart, parent: Instance): (BillboardGui, Frame)
	local gui = Instance.new("BillboardGui")
	gui.Name = "StructureHealth"
	gui.Size = BAR_SIZE
	gui.StudsOffset = Vector3.new(0, heightOf(piece) / 2 + 1.5, 0)
	gui.AlwaysOnTop = false
	gui.LightInfluence = 0
	gui.Adornee = adornee
	gui.Enabled = false
	-- Sem isto o Roblox destrói a barra quando o personagem renasce.
	gui.ResetOnSpawn = false
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
	gui.Parent = parent
	return gui, fill
end

function StructureHealth.start()
	-- Resolvido uma vez, fora do Heartbeat.
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
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

	for _, tag in { StatNames.StructureTag, StatNames.CrateTag } do
		CollectionService:GetInstanceAddedSignal(tag):Connect(track)
		CollectionService:GetInstanceRemovedSignal(tag):Connect(untrack)
		for _, piece in CollectionService:GetTagged(tag) do
			track(piece)
		end
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
				-- Cria sob demanda (e de novo se algo destruiu a barra).
				if entry.gui == nil or entry.gui.Parent == nil then
					local adornee = adorneeOf(piece)
					if adornee then
						entry.gui, entry.fill = makeGui(piece, adornee, playerGui)
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
			-- Some a barra de vez (e não só desliga) para não acumular guis.
			if entry.gui and now >= entry.hideAt then
				entry.gui:Destroy()
				entry.gui = nil
				entry.fill = nil
			end
		end
	end)
end

return StructureHealth
