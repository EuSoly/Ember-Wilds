--!strict
-- Indicador pequeno no canto do menu enquanto as artes do mundo e dos
-- cosméticos ainda baixam em segundo plano (Shared/AssetPreload): "Baixando
-- artes 812/1.706". Some quando termina.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local AssetPreloader = require(Shared:WaitForChild("AssetPreload"):WaitForChild("AssetPreloader"))
local ProfileFormat = require(Shared:WaitForChild("UIFlow"):WaitForChild("ProfileFormat"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local Client = script.Parent.Parent
local Rustic = require(Client:WaitForChild("UI"):WaitForChild("Rustic"))
local MenuState = require(script.Parent:WaitForChild("MenuState"))

local create = vide.create
local R = Theme.rustic

local REFRESH = 0.5 -- s entre leituras da contagem

local AssetProgress = {}

function AssetProgress.build(): Frame
	local progress = vide.source({ loaded = 0, total = 0, running = true })
	local alive = true
	task.spawn(function()
		while alive do
			progress({
				loaded = AssetPreloader.loaded(),
				total = AssetPreloader.total(),
				running = not AssetPreloader.finished(),
			})
			if AssetPreloader.finished() then
				break
			end
			task.wait(REFRESH)
		end
	end)
	vide.cleanup(function()
		alive = false
	end)

	return create("Frame")({
		Name = "AssetProgress",
		-- Só na tela inicial do menu: com uma janela aberta, ficaria por cima dela.
		Visible = function()
			local p = progress()
			return p.running and p.total > 0 and MenuState.panel() == "play"
		end,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -16),
		Size = UDim2.fromOffset(230, 30),
		BackgroundColor3 = R.outline,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		ZIndex = 9, -- abaixo das janelas por cima do menu (check-in 11, Presentear 12)
		create("UICorner")({ CornerRadius = UDim.new(1, 0) }),
		Rustic.label({
			Size = UDim2.new(1, -20, 1, -8),
			Position = UDim2.fromOffset(10, 4),
			FontFace = Theme.font.number,
			TextColor3 = R.cream,
			maxSize = 16,
			ZIndex = 16,
			Text = function()
				local p = progress()
				return Strings.format("menu.assets.downloading", {
					loaded = ProfileFormat.thousands(p.loaded),
					total = ProfileFormat.thousands(p.total),
				})
			end,
		}),
	}) :: Frame
end

return AssetProgress
