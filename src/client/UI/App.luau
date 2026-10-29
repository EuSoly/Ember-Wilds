--!strict
-- Raiz do HUD: o ScreenGui onde todos os componentes do jogo são montados.
-- Para adicionar um componente ao HUD, crie o arquivo em UI/ e coloque-o na
-- lista de filhos abaixo.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local AimStick = require(script.Parent:WaitForChild("AimStick"))
local Backpack = require(script.Parent:WaitForChild("Backpack"))
local Clock = require(script.Parent:WaitForChild("Clock"))
local Hotbar = require(script.Parent:WaitForChild("Hotbar"))
local Minimap = require(script.Parent:WaitForChild("Minimap"))
local Notifications = require(script.Parent:WaitForChild("Notifications"))
local ScorePill = require(script.Parent:WaitForChild("ScorePill"))
local StatusRings = require(script.Parent:WaitForChild("StatusRings"))

local create = vide.create

local function App(): ScreenGui
	-- Componentes do HUD, na ordem em que são desenhados.
	local children: { Instance } = {
		ScorePill(),
		Clock(),
		Minimap(),
		Notifications.Component(),
		StatusRings(),
		Hotbar(),
		AimStick(),
		Backpack.Button(),
		Backpack.Panel(),
	}

	return create("ScreenGui")({
		Name = "Hud",
		ResetOnSpawn = false, -- o HUD sobrevive ao respawn
		IgnoreGuiInset = false,
		-- Desvia da barra superior do Roblox e do notch do celular.
		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		children,
	}) :: ScreenGui
end

return App
