--!strict
-- Configurações (molde Settings): janela por cima do menu e do jogo. Uma linha
-- por configuração de Defs.Settings (na ordem do campo order), clonando o molde
-- do tipo: SettingRowNumber, SettingRowBoolean ou SettingRowChoice. Configuração
-- nova num update aparece sozinha.
--
-- Nomes combinados:
-- - Settings: List (onde entram as linhas), CloseButton.
-- - Todas as linhas: NameLabel e ValueLabel (TextLabel).
-- - SettingRowNumber: MinusButton / PlusButton (passo 0,1).
-- - SettingRowBoolean: ToggleButton.
-- - SettingRowChoice: PrevButton / NextButton.
--
-- Cada mudança é um pedido ao servidor (Net.SetSetting, ele valida); o valor
-- mostrado é sempre o do atributo Setting_<id> do Player (fonte da verdade).
-- "quality" e "left_handed" só são salvos por enquanto (spec F5, seção 7): o
-- Roblox não deixa o jogo mudar a qualidade gráfica do jogador (vai controlar os
-- nossos efeitos quando existirem), e o modo canhoto precisa mexer no joystick
-- do PlayerModule (fica para quando testarmos o celular a fundo).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Defs = require(Shared:WaitForChild("Defs"))
local SettingsFormat = require(Shared:WaitForChild("UIFlow"):WaitForChild("SettingsFormat"))
local StatNames = require(Shared:WaitForChild("StatNames"))
local Strings = require(Shared:WaitForChild("Strings"))
local Client = script.Parent.Parent
local Net = require(Client:WaitForChild("Net"))
local Template = require(Client:WaitForChild("UITemplates"):WaitForChild("Template"))
local Sources = require(Client:WaitForChild("UI"):WaitForChild("Sources"))

local ROW_TEMPLATES: { [string]: string } = {
	number = "SettingRowNumber",
	boolean = "SettingRowBoolean",
	choice = "SettingRowChoice",
}

local SettingsScreen = {}

-- Janela aberta? Quem abre: botão do menu e engrenagem da HUD. Quem fecha:
-- CloseButton, ou o ScreenController quando o estado de tela não permite.
SettingsScreen.open = vide.source(false)

function SettingsScreen.toggle()
	SettingsScreen.open(not vide.untrack(SettingsScreen.open))
end

local function connectButton(row: Instance, name: string, onClick: () -> ())
	local button = Template.find(row, name, "GuiButton") :: GuiButton?
	if button then
		button.Activated:Connect(onClick)
	end
end

local function buildRow(list: Instance, def: Defs.SettingDef, order: number)
	local row = Template.clone(ROW_TEMPLATES[def.kind])
	if row == nil then
		return
	end
	row.Name = def.id
	if row:IsA("GuiObject") then
		row.LayoutOrder = order
	end
	Template.bind(row)
	Template.setText(Template.find(row, "NameLabel", "TextLabel"), Strings.get(def.nameKey))

	local value = Sources.attribute(Players.LocalPlayer, StatNames.SettingPrefix .. def.id, def.default)
	local valueLabel = Template.find(row, "ValueLabel", "TextLabel")
	vide.effect(function()
		Template.setText(valueLabel, SettingsFormat.display(def, value(), Strings.get))
	end)

	-- Campo do evento conforme o tipo (o servidor só lê esse).
	if def.kind == "number" then
		local function step(direction: number)
			local current = vide.untrack(value)
			if type(current) == "number" then
				Net.SetSetting.Fire({ Id = def.id, Number = SettingsFormat.step(def, current, direction) })
			end
		end
		connectButton(row, "MinusButton", function()
			step(-1)
		end)
		connectButton(row, "PlusButton", function()
			step(1)
		end)
	elseif def.kind == "boolean" then
		connectButton(row, "ToggleButton", function()
			Net.SetSetting.Fire({ Id = def.id, Flag = vide.untrack(value) ~= true })
		end)
	else
		local function cycle(direction: number)
			local current = vide.untrack(value)
			if type(current) == "string" then
				Net.SetSetting.Fire({ Id = def.id, Choice = SettingsFormat.cycle(def, current, direction) })
			end
		end
		connectButton(row, "PrevButton", function()
			cycle(-1)
		end)
		connectButton(row, "NextButton", function()
			cycle(1)
		end)
	end

	row.Parent = list
end

-- Clona e liga a janela (dentro do root Vide do ScreenController).
function SettingsScreen.mount(playerGui: Instance): ScreenGui?
	local gui = Template.clone("Settings")
	if gui == nil or not gui:IsA("ScreenGui") then
		return nil
	end
	gui.ResetOnSpawn = false
	gui.Enabled = false
	Template.bind(gui)

	local list = Template.find(gui, "List", "GuiObject")
	if list then
		for _, def in SettingsFormat.sorted(Defs.Settings) do
			buildRow(list, def, def.order)
		end
	end

	connectButton(gui, "CloseButton", function()
		SettingsScreen.open(false)
	end)

	gui.Parent = playerGui
	return gui
end

return SettingsScreen
