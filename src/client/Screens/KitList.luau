--!strict
-- Lista de kits iniciais, usada pelo menu e pela tela de morte. Clona o molde
-- KitRow para cada kit (na ordem de Defs.Kits) dentro do elemento "KitList" da
-- tela e escreve os pontos disponíveis em "KitPointsLabel".
--
-- Nomes combinados do molde KitRow: NameLabel, PriceLabel, ItemsLabel (TextLabel)
-- e SelectButton (GuiButton). Kit que custa mais que os pontos (KitPoints) fica
-- apagado e sem clique; um clique seleciona, clicar no selecionado tira a seleção.
-- A seleção é UMA para as duas telas (escolher na morte vale no menu).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Defs = require(Shared:WaitForChild("Defs"))
local KitRules = require(Shared:WaitForChild("UIFlow"):WaitForChild("KitRules"))
local StatNames = require(Shared:WaitForChild("StatNames"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local Template = require(script.Parent.Parent:WaitForChild("UITemplates"):WaitForChild("Template"))
local Sources = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Sources"))

local ROW_TEMPLATE = "KitRow"
local DISABLED_TRANSPARENCY = 0.6 -- quanto o kit indisponível fica apagado
local SELECTED_STROKE = 2

local KitList = {}

-- Id do kit escolhido (nil = sem kit).
KitList.selected = vide.source(nil :: string?)

local kitPoints: (() -> number)? = nil

-- Pontos para kit (atributo do Player). Uma fonte só, criada no primeiro
-- mount, no corpo do root do ScreenController: Sources.attribute usa
-- vide.cleanup, e dentro de um effect a conexão cairia a cada reexecução.
local function ensurePoints()
	if kitPoints == nil then
		kitPoints = Sources.attribute(Players.LocalPlayer, StatNames.KitPoints, 0)
	end
end

local function points(): number
	return if kitPoints then kitPoints() else 0
end

-- "8× Frutinha, 20× Madeira" (nomes de Strings).
local function itemsText(kit: Defs.KitDef): string
	local parts: { string } = {}
	for _, entry in kit.items do
		local def = Defs.Items[entry.id]
		local name = if def then Strings.get(def.nameKey) else entry.id
		table.insert(parts, `{entry.count}× {name}`)
	end
	return table.concat(parts, ", ")
end

function KitList.toggle(kitId: string)
	local kit = Defs.Kits[kitId]
	if vide.untrack(KitList.selected) == kitId then
		KitList.selected(nil)
	elseif KitRules.canBuy(kit, vide.untrack(points)) then
		KitList.selected(kitId)
	end
end

-- Transparências originais de uma linha, para o estado apagado ser relativo
-- ao visual do molde (o designer pode usar qualquer transparência).
type Snapshot = { instance: GuiObject, background: number, text: number? }

local function snapshot(row: Instance): { Snapshot }
	local list: { Snapshot } = {}
	local instances = row:GetDescendants()
	table.insert(instances, 1, row)
	for _, instance in instances do
		if instance:IsA("GuiObject") then
			local text = if instance:IsA("TextLabel") or instance:IsA("TextButton")
				then (instance :: any).TextTransparency
				else nil
			table.insert(list, { instance = instance, background = instance.BackgroundTransparency, text = text })
		end
	end
	return list
end

local function applyDisabled(entries: { Snapshot }, disabled: boolean)
	for _, entry in entries do
		local function fade(value: number): number
			return if disabled then value + (1 - value) * DISABLED_TRANSPARENCY else value
		end
		entry.instance.BackgroundTransparency = fade(entry.background)
		if entry.text ~= nil then
			(entry.instance :: any).TextTransparency = fade(entry.text)
		end
	end
end

local function buildRow(container: Instance, kit: Defs.KitDef)
	local row = Template.clone(ROW_TEMPLATE)
	if row == nil then
		return
	end
	row.Name = kit.id
	if row:IsA("GuiObject") then
		row.LayoutOrder = kit.order
	end
	Template.bind(row)
	Template.setText(Template.find(row, "NameLabel", "TextLabel"), Strings.get(kit.nameKey))
	Template.setText(Template.find(row, "PriceLabel", "TextLabel"), Strings.format("kit.price", { price = kit.price }))
	Template.setText(Template.find(row, "ItemsLabel", "TextLabel"), itemsText(kit))

	local button = Template.find(row, "SelectButton", "GuiButton") :: GuiButton?
	if button then
		button.Activated:Connect(function()
			KitList.toggle(kit.id)
		end)
	end

	local entries = snapshot(row)
	local stroke = row:FindFirstChildOfClass("UIStroke")
	local baseStrokeColor = if stroke then stroke.Color else nil
	local baseStrokeThickness = if stroke then stroke.Thickness else nil
	local baseBackground = if row:IsA("GuiObject") then row.BackgroundColor3 else nil

	vide.effect(function()
		local canBuy = KitRules.canBuy(kit, points())
		local isSelected = KitList.selected() == kit.id
		applyDisabled(entries, not canBuy)
		if button then
			button.Active = canBuy
			button.AutoButtonColor = canBuy
		end
		-- Selecionado: borda laranja (cor de ação); sem UIStroke no molde, o fundo.
		if stroke then
			stroke.Color = if isSelected then Theme.ui.action else baseStrokeColor :: Color3
			stroke.Thickness = if isSelected then SELECTED_STROKE else baseStrokeThickness :: number
		elseif row:IsA("GuiObject") and baseBackground then
			row.BackgroundColor3 = if isSelected then Theme.ui.action else baseBackground
		end
	end)

	row.Parent = container
end

-- Monta a lista dentro da tela `screen` (precisa estar num root Vide).
function KitList.mount(screen: Instance)
	ensurePoints()
	local container = Template.find(screen, "KitList", "GuiObject")
	if container then
		for _, kit in KitRules.sorted(Defs.Kits) do
			buildRow(container, kit)
		end
	end

	local pointsLabel = Template.find(screen, "KitPointsLabel", "TextLabel")
	vide.effect(function()
		local value = points()
		Template.setText(pointsLabel, Strings.format("kit.points", { points = value }))
		-- Os pontos mudaram e o escolhido ficou caro demais: tira a seleção.
		local selectedId = vide.untrack(KitList.selected)
		if selectedId ~= nil and not KitRules.canBuy(Defs.Kits[selectedId], value) then
			KitList.selected(nil)
		end
	end)
end

return KitList
