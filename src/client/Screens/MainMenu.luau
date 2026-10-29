--!strict
-- Menu principal (molde MainMenu). Aparece no estado "menu", sem personagem;
-- a câmera passeia pelo mapa (CameraController + SpectateService).
--
-- Nomes combinados: BalanceLabel (TextLabel, saldo de Golden Ember), PlayButton
-- (GuiButton), SettingsButton (GuiButton), KitList (onde entram as linhas de
-- kit) e KitPointsLabel (TextLabel). Textos fixos vêm do atributo TextKey.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local StatNames = require(Shared:WaitForChild("StatNames"))
local Strings = require(Shared:WaitForChild("Strings"))
local Client = script.Parent.Parent
local Net = require(Client:WaitForChild("Net"))
local Template = require(Client:WaitForChild("UITemplates"):WaitForChild("Template"))
local Sources = require(Client:WaitForChild("UI"):WaitForChild("Sources"))
local KitList = require(script.Parent:WaitForChild("KitList"))

local MainMenu = {}

-- Clona e liga o menu (dentro do root Vide do ScreenController).
-- openSettings: abre a janela de configurações (ScreenController).
function MainMenu.mount(playerGui: Instance, openSettings: () -> ()): ScreenGui?
	local gui = Template.clone("MainMenu")
	if gui == nil or not gui:IsA("ScreenGui") then
		return nil
	end
	gui.ResetOnSpawn = false
	gui.Enabled = false
	Template.bind(gui)

	local currency = Sources.attribute(Players.LocalPlayer, StatNames.Currency, 0)
	local balance = Template.find(gui, "BalanceLabel", "TextLabel")
	vide.effect(function()
		Template.setText(balance, Strings.format("menu.balance", { amount = currency() }))
	end)

	local play = Template.find(gui, "PlayButton", "GuiButton") :: GuiButton?
	if play then
		play.Activated:Connect(function()
			Net.RequestSpawn.Fire({ KitId = vide.untrack(KitList.selected) })
		end)
	end

	local settings = Template.find(gui, "SettingsButton", "GuiButton") :: GuiButton?
	if settings then
		settings.Activated:Connect(openSettings)
	end

	KitList.mount(gui)
	gui.Parent = playerGui
	return gui
end

return MainMenu
