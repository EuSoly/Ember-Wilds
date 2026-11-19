--!strict
-- Camadas configuradas em ReplicatedStorage.ArteBundles/<bundle>/<camada> (StringValue).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BundleBanner = {}
local ROLES = { "personagem", "caixa", "mochila", "livro" }
local CENTERS = { 92, 228, 329, 432 }
local SIZES = { 190, 116, 115, 112 }

function BundleBanner.build(id: string, active: () -> boolean): Frame?
	local library = ReplicatedStorage:FindFirstChild("ArteBundles")
	local assets = if library then library:FindFirstChild(id) else nil
	if not assets then
		return nil
	end
	local images: { [string]: string } = {}
	for _, key in { "fundo", "personagem", "caixa", "mochila", "livro", "particula", "ambiente" } do
		local value = assets:FindFirstChild(key)
		local digits = if value and value:IsA("StringValue")
			then string.match(value.Value, "^rbxassetid://(%d+)$") or string.match(value.Value, "^(%d+)$")
			else nil
		if not digits or tonumber(digits) == 0 then
			if key == "ambiente" then
				continue
			end
			return nil
		end
		images[key] = "rbxassetid://" .. digits
	end
	local frame = Instance.new("Frame")
	frame.Name = "ArteAnimada"
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundTransparency = 1
	frame.ClipsDescendants = true
	frame.ZIndex = 0
	local function layer(key: string, z: number): ImageLabel
		local label = Instance.new("ImageLabel")
		label.Name = key
		label.Image = images[key]
		label.AnchorPoint = Vector2.new(0.5, 0.5)
		label.BackgroundTransparency = 1
		label.ScaleType = Enum.ScaleType.Fit
		label.ZIndex = z
		label.Parent = frame
		return label
	end
	local bg = layer("fundo", 0)
	bg.ScaleType = Enum.ScaleType.Crop
	bg.Size = UDim2.fromScale(1.025, 1.025)
	local scenery: { ImageLabel } = {}
	if images.ambiente then
		for i = 1, if id == "bosque_desperto" then 3 else 1 do
			scenery[i] = layer("ambiente", 0)
		end
	end
	local items = {}
	for i, key in ROLES do
		items[i] = layer(key, 1)
	end
	local sparks = {}
	for i = 1, 3 do
		sparks[i] = layer("particula", 2)
	end
	local function pose(t: number)
		local bounds = frame.AbsoluteSize
		local left = 66
		local s = math.max(0, math.min(bounds.Y / 300, (bounds.X * 0.56 - left) / 490))
		local wave = math.sin(t * math.pi / 3)
		bg.Position = UDim2.fromScale(0.5 + 0.006 * wave, 0.5)
		for i, sprite in scenery do
			local leaves = id == "bosque_desperto"
			local sea = id == "mare_profunda"
			local p = (t / 3 - (i - 1) / 3) % 1
			local side = bounds.Y * (if leaves then 0.09 + 0.05 * p elseif sea then 0.32 else 0.24)
			sprite.Size = UDim2.fromOffset(side, side)
			sprite.Position = if leaves
				then UDim2.fromScale(0.57 + 0.05 * math.sin(p * math.pi * 2), 0.12 + 0.52 * p)
				else UDim2.fromScale(0.58, if sea then 0.51 else 0.42)
			sprite.Rotation = if leaves then 100 * p elseif sea then t * 60 else 14 * wave
			sprite.ImageTransparency = if leaves then 1 - 0.70 * math.sin(p * math.pi) elseif sea then 0.5 else 0.24
		end
		for i, item in items do
			local offset = if i == 1 then -3 * wave else 0
			item.Size = UDim2.fromOffset(SIZES[i] * s, SIZES[i] * s)
			item.Position = UDim2.fromOffset(left + CENTERS[i] * s, bounds.Y * 0.64 + (offset - SIZES[i] / 2) * s)
			item.Rotation = if i == 1 then 1.5 * wave else 0
		end
		local route = id == "norte_perdido"
		for i, spark in sparks do
			local p = (t / 2.1 - (i - 1) * 0.16) % 1
			local dx = (i - 2) * 8
			local y = bounds.Y * 0.64
			if route then
				spark.Position = UDim2.fromOffset(left + (CENTERS[4] - 16 + dx) * s, y - (36 + (i - 1) * 5) * s)
				local elapsed = t % 6 - 1.3 - (i - 1) * 0.17
				spark.ImageTransparency = 1 - math.clamp(elapsed * 8, 0, 1) * math.clamp((3.4 - t % 6) * 3, 0, 1)
			else
				spark.Position =
					UDim2.fromOffset(left + (CENTERS[3] + dx + 5 * math.sin(p * math.pi)) * s, y - (94 + 48 * p) * s)
				spark.ImageTransparency = 1 - math.sin(p * math.pi)
			end
			local size = (if route then 11 else 13 + 3 * i) * s
			spark.Size = UDim2.fromOffset(size, size)
		end
	end
	local elapsed = 0
	pose(0)
	local connection = RunService.RenderStepped:Connect(function(dt)
		if active() then
			elapsed = (elapsed + dt) % 6
			pose(elapsed)
		elseif elapsed > 0 then
			elapsed = 0
			pose(0)
		end
	end)
	frame.Destroying:Once(function()
		connection:Disconnect()
	end)
	return frame
end

return BundleBanner
