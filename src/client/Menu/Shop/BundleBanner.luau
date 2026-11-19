--!strict
-- Camadas configuradas em ReplicatedStorage.ArteBundles/<bundle>/<camada> (StringValue).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BundleFx = require(script.Parent:WaitForChild("BundleFx"))
local BundleImages = require(script.Parent:WaitForChild("BundleImages")) :: { [string]: { [string]: string } }

local BundleBanner = {}
local ROLES = { "personagem", "caixa", "mochila", "livro" }
local CENTERS = { 92, 228, 329, 432 }
local SIZES = { 190, 116, 115, 112 }

function BundleBanner.build(id: string, active: () -> boolean): Frame?
	local library = ReplicatedStorage:FindFirstChild("ArteBundles")
	local assets = if library then library:FindFirstChild(id) else nil
	if not assets and not BundleImages[id] then
		return nil
	end
	local images: { [string]: string } = {}
	for _, key in { "fundo", "personagem", "caixa", "mochila", "livro", "particula", "ambiente" } do
		local value = assets and assets:FindFirstChild(key)
		local digits = if value and value:IsA("StringValue")
			then string.match(value.Value, "^rbxassetid://(%d+)$") or string.match(value.Value, "^(%d+)$")
			else nil
		if not digits or tonumber(digits) == 0 then
			local fallback = BundleImages[id] and BundleImages[id][key]
			if fallback then
				images[key] = fallback
				continue
			end
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
	local items = {}
	for i, key in ROLES do
		items[i] = layer(key, 2)
	end
	-- Ambiente (BundleFx): luz, bolhas, folhas... atrás (z 1) e na frente (z 3).
	local ambient = BundleFx.build(id, frame)

	-- Coordenadas normalizadas nos recortes da mochila e do livro. Assim cada
	-- efeito acompanha o desenho mesmo quando o carrossel muda de proporção.
	local bag, book = items[3], items[4]
	local function effect(key: string, parent: ImageLabel, name: string): ImageLabel
		local sprite = layer(key, 3)
		sprite.Name = name
		sprite.Parent = parent
		return sprite
	end

	local sea = id == "mare_profunda"
	local forest = id == "bosque_desperto"
	local sparks = {}
	for i = 1, 3 do
		sparks[i] = effect("particula", if sea or forest then bag else book, "Particula" .. i)
	end
	local accent = if images.ambiente then effect("ambiente", book, "DetalheDoTomo") else nil
	local route = { Vector2.new(0.21, 0.67), Vector2.new(0.30, 0.66), Vector2.new(0.40, 0.60) }
	local function place(sprite: ImageLabel, x: number, y: number, size: number, opacity: number)
		sprite.Position = UDim2.fromScale(x, y)
		sprite.Size = UDim2.fromScale(size, size)
		sprite.ImageTransparency = 1 - math.clamp(opacity, 0, 1)
	end
	local function pose(t: number)
		local bounds = frame.AbsoluteSize
		local left = 66
		local s = math.max(0, math.min(bounds.Y / 300, (bounds.X * 0.56 - left) / 490))
		local wave = math.sin(t * math.pi / 3)
		if ambient then
			ambient(t)
		end
		bg.Position = UDim2.fromScale(0.5 + 0.006 * wave, 0.5)
		for i, item in items do
			local offset = if i == 1 then -3 * wave else 0
			item.Size = UDim2.fromOffset(SIZES[i] * s, SIZES[i] * s)
			item.Position = UDim2.fromOffset(left + CENTERS[i] * s, bounds.Y * 0.64 + (offset - SIZES[i] / 2) * s)
			item.Rotation = if i == 1 then 1.5 * wave else 0
		end
		if sea then
			-- Bolhas nascem no aro azul, entre as pinças. O vórtice segue o selo da capa.
			for i, bubble in sparks do
				local p = (t / 2 + (i - 1) / 3) % 1
				local x = 0.38 + (i - 1) * 0.115 + 0.055 * math.sin(p * math.pi * 2)
				place(bubble, x, 0.49 - 0.64 * p, 0.045 + 0.09 * p, 0.9 * math.sin(math.pi * p))
			end
			if accent then
				place(accent, 0.515, 0.575, 0.32 + 0.02 * wave, 0.38 + 0.10 * wave)
				accent.Rotation = t * 60
			end
		elseif forest then
			-- Vaga-lumes emergem das três sementes em tempos diferentes.
			for i, firefly in sparks do
				local p = (t / 3 + (i - 1) / 3) % 1
				local x = (if i == 1 then 0.23 elseif i == 2 then 0.45 else 0.73)
				local y = if i == 2 then 0.21 else 0.47
				place(
					firefly,
					x + 0.08 * math.sin(2 * math.pi * p),
					y - 0.44 * p,
					0.045 + 0.025 * math.sin(math.pi * p),
					math.sin(math.pi * p) ^ 2
				)
			end
			if accent then
				local p = (t / 3) % 1
				place(
					accent,
					0.84 + 0.09 * math.sin(2 * math.pi * p) - 0.16 * p,
					0.22 + 0.42 * p,
					0.15,
					0.85 * math.sin(math.pi * p)
				)
				accent.Rotation = -30 + 110 * p
			end
		else
			-- A luz percorre a linha impressa no mapa e termina na ponta da agulha.
			local beat = t % 3
			for i, dot in sparks do
				local age = beat - 0.25 - (i - 1) * 0.28
				local light = math.clamp(age / 0.15, 0, 1) * math.clamp((1.9 - beat) / 0.45, 0, 1)
				place(dot, route[i].X, route[i].Y, 0.047 + light * 0.022, 0.90 * light)
			end
			if accent then
				local p = math.clamp((beat - 0.98) / 0.8, 0, 1)
				local flash = math.sin(math.pi * p) ^ 2
				place(accent, 0.637, 0.237, 0.06 + 0.12 * flash, flash)
				accent.Rotation = -20 + 40 * p
			end
		end
	end
	local elapsed = 0
	pose(0)
	local connection = RunService.RenderStepped:Connect(function(dt)
		if active() then
			-- 2520 s: múltiplo dos ciclos de todos os efeitos (não pula ao virar).
			elapsed = (elapsed + dt) % 2520
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
