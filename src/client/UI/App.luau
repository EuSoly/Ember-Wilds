--!strict
-- Raiz do HUD: o ScreenGui onde todos os componentes do jogo são montados.
-- Para adicionar um componente ao HUD, crie o arquivo em UI/ e coloque-o na
-- lista de filhos abaixo.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local ScreenFlow = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("UIFlow"):WaitForChild("ScreenFlow"))
local ScreenState = require(script.Parent.Parent:WaitForChild("ScreenState"))
local AimStick = require(script.Parent:WaitForChild("AimStick"))
local Backpack = require(script.Parent:WaitForChild("Backpack"))
local Clock = require(script.Parent:WaitForChild("Clock"))
local DragGhost = require(script.Parent:WaitForChild("DragGhost"))
local Hotbar = require(script.Parent:WaitForChild("Hotbar"))
local Minimap = require(script.Parent:WaitForChild("Minimap"))
local Notifications = require(script.Parent:WaitForChild("Notifications"))
local ScorePill = require(script.Parent:WaitForChild("ScorePill"))
local SettingsButton = require(script.Parent:WaitForChild("SettingsButton"))
local StatusRings = require(script.Parent:WaitForChild("StatusRings"))
local Template = require(script.Parent.Parent:WaitForChild("UITemplates"):WaitForChild("Template"))

local create = vide.create

local function App(): ScreenGui
	-- Componentes do HUD, na ordem em que são desenhados.
	local children: { Instance } = {
		ScorePill(),
		Clock(),
		Minimap(),
		SettingsButton(),
		Notifications.Component(),
		Hotbar({ StatusRings() :: Instance }),
		AimStick(),
		Backpack.Button(),
		Backpack.Panel(),
		DragGhost(), -- por último: o item arrastado fica por cima de tudo
	}

	local hud = create("ScreenGui")({
		Name = "Hud",
		ResetOnSpawn = false, -- o HUD sobrevive ao respawn
		-- Só jogando: no carregamento, menu e morte quem aparece são as telas.
		Enabled = function()
			return ScreenFlow.hudVisible(ScreenState.current())
		end,
		IgnoreGuiInset = false,
		-- Desvia da barra superior do Roblox e do notch do celular.
		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		children,
	}) :: ScreenGui
	-- Mesmo "Tamanho da interface" (ui_scale) das telas de molde.
	Template.bindUiScale(hud)
	return hud
end

return App
