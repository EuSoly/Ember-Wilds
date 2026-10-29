--!strict
-- Telas fora da HUD (moldes de ReplicatedStorage.UITemplates): monta todas no
-- PlayerGui e mostra/esconde conforme o estado de tela (ScreenState):
-- menu no "menu", tela de morte no "dead". A HUD (UI/App) se esconde sozinha
-- fora do "playing". Veja docs/guia/telas.md.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Client = script.Parent.Parent
local ScreenState = require(Client:WaitForChild("ScreenState"))
local Template = require(Client:WaitForChild("UITemplates"):WaitForChild("Template"))
local Screens = Client:WaitForChild("Screens")
local DeathScreen = require(Screens:WaitForChild("DeathScreen"))
local KitList = require(Screens:WaitForChild("KitList"))
local MainMenu = require(Screens:WaitForChild("MainMenu"))

local ScreenController = {}

local function showWhen(gui: ScreenGui?, screen: ScreenState.Screen)
	if gui == nil then
		return
	end
	vide.effect(function()
		Template.show(gui, ScreenState.current() == screen)
	end)
end

function ScreenController.Start(_self)
	ScreenState.start()

	task.spawn(function()
		-- Tudo que espera fica antes do root: dentro dele não pode haver yield.
		if not game:IsLoaded() then
			game.Loaded:Wait()
		end
		ReplicatedStorage:WaitForChild("UITemplates")
		local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

		vide.root(function()
			local menu = MainMenu.mount(playerGui, function() end)
			local death = DeathScreen.mount(playerGui)
			showWhen(menu, "menu")
			showWhen(death, "dead")

			-- Nasceu: o kit escolhido já foi usado (ou recusado); a próxima
			-- escolha começa vazia, para nada ser cobrado sem querer.
			vide.effect(function()
				if ScreenState.current() == "playing" then
					KitList.selected(nil)
				end
			end)
		end)
	end)
end

return ScreenController
