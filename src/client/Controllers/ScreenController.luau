--!strict
-- Telas fora da HUD (moldes de ReplicatedStorage.UITemplates): monta todas no
-- PlayerGui e mostra/esconde conforme o estado de tela (ScreenState):
-- menu no "menu", tela de morte no "dead", configurações por cima quando
-- abertas e permitidas (ScreenFlow.canOpenSettings). A HUD (UI/App) se
-- esconde sozinha fora do "playing". Também liga o volume por grupo
-- (AudioSettings). Veja docs/guia/telas.md.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local ScreenFlow = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("UIFlow"):WaitForChild("ScreenFlow"))
local Client = script.Parent.Parent
local AudioSettings = require(Client:WaitForChild("AudioSettings"))
local ScreenState = require(Client:WaitForChild("ScreenState"))
local Template = require(Client:WaitForChild("UITemplates"):WaitForChild("Template"))
local MenuShell = require(Client:WaitForChild("Menu"):WaitForChild("MenuShell"))
local MenuState = require(Client:WaitForChild("Menu"):WaitForChild("MenuState"))
local Screens = Client:WaitForChild("Screens")
local DeathScreen = require(Screens:WaitForChild("DeathScreen"))
local KitList = require(Screens:WaitForChild("KitList"))
local MainMenu = require(Screens:WaitForChild("MainMenu"))
local RecipeBookScreen = require(Screens:WaitForChild("RecipeBookScreen"))
local SettingsScreen = require(Screens:WaitForChild("SettingsScreen"))

local ScreenController = {}

local function showWhen(gui: ScreenGui?, visible: () -> boolean)
	if gui == nil then
		return
	end
	vide.effect(function()
		Template.show(gui, visible())
	end)
end

function ScreenController.Start(_self)
	ScreenState.start()
	AudioSettings.start()

	task.spawn(function()
		-- Tudo que espera fica antes do root: dentro dele não pode haver yield.
		if not game:IsLoaded() then
			game.Loaded:Wait()
		end
		ReplicatedStorage:WaitForChild("UITemplates")
		local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

		vide.root(function()
			local menu = MainMenu.mount(playerGui, function()
				SettingsScreen.open(true)
			end)
			-- Casca do mockup (coluna, barra, painéis): liga e desliga sozinha.
			MenuShell.mount(playerGui)
			local death = DeathScreen.mount(playerGui)
			local settings = SettingsScreen.mount(playerGui)
			local recipeBook = RecipeBookScreen.mount(playerGui)

			showWhen(menu, function()
				return ScreenState.current() == "menu"
			end)
			showWhen(death, function()
				return ScreenState.current() == "dead"
			end)
			showWhen(settings, function()
				return SettingsScreen.open() and ScreenFlow.canOpenSettings(ScreenState.current())
			end)
			showWhen(recipeBook, function()
				return RecipeBookScreen.open() and ScreenState.current() == "playing"
			end)

			vide.effect(function()
				local screen: ScreenState.Screen = ScreenState.current()
				-- Estado que não permite configurações (morreu jogando, por
				-- exemplo): a janela fecha sozinha.
				if not ScreenFlow.canOpenSettings(screen) then
					SettingsScreen.open(false)
				end
				-- O menu sempre abre no "play", sem painel do mockup aberto.
				if screen ~= "menu" then
					MenuState.open("play")
				end
				if screen ~= "playing" then
					RecipeBookScreen.open(false)
				end
				-- Nasceu: o kit escolhido já foi usado (ou recusado); a próxima
				-- escolha começa vazia, para nada ser cobrado sem querer.
				if screen == "playing" then
					KitList.selected(nil)
				end
			end)
		end)
	end)
end

return ScreenController
