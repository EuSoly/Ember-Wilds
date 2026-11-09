--!strict
-- Dica do item: ao passar o mouse num slot da hotbar ou da mochila (ou segurar
-- o dedo, no celular), aparece em cima dele o nome do item, o material (na cor
-- do tier) e até 3 linhas do que ele faz (UIFlow/ItemInfo). Some durante o
-- arrasto e quando o slot fica vazio.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Defs = require(Shared:WaitForChild("Defs"))
local ItemInfo = require(Shared:WaitForChild("UIFlow"):WaitForChild("ItemInfo"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local Client = script.Parent.Parent
local DragState = require(Client:WaitForChild("DragState"))
local InventoryState = require(Client:WaitForChild("InventoryState"))
local ItemHover = require(Client:WaitForChild("ItemHover"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local Rustic = require(script.Parent:WaitForChild("Rustic"))

local WIDTH = 240
local NAME_HEIGHT = 28
local TIER_HEIGHT = 18
local LINE_HEIGHT = 20
local PAD = 8
local GAP = 20 -- distância entre a dica e o slot (a pontinha do balão fica nela)
local EDGE = 8 -- folga até a borda da tela

local function uiScale(instance: Instance): number
	local gui = instance:FindFirstAncestorOfClass("ScreenGui")
	local scale = gui and gui:FindFirstChildOfClass("UIScale")
	return if scale and scale.Scale > 0 then scale.Scale else 1
end

local function ItemTooltip(): Frame
	-- Item do slot sob o mouse (nil = sem dica).
	local def = vide.derive(function(): Defs.ItemDef?
		local hover = ItemHover.current()
		if hover == nil or DragState.current() ~= nil then
			return nil
		end
		local slot = InventoryState.slots()[hover.index]
		return if slot then Defs.Items[slot.id] else nil
	end)
	local lines = vide.derive(function(): { ItemInfo.Line }
		local current = def()
		return if current then ItemInfo.lines(current) else {}
	end)
	local function tierKey(): string?
		local current = def()
		if current == nil then
			return nil
		end
		return (ItemInfo.tier(current))
	end
	local function height(): number
		return PAD * 2 + NAME_HEIGHT + (if tierKey() then TIER_HEIGHT else 0) + #lines() * LINE_HEIGHT
	end

	local rows: { Instance } = {}
	for i = 1, ItemInfo.MAX_LINES do
		table.insert(
			rows,
			Rustic.label({
				dark = true,
				Name = "Line" .. i,
				Position = function()
					local top = PAD + NAME_HEIGHT + (if tierKey() then TIER_HEIGHT else 0)
					return UDim2.fromOffset(PAD, top + (i - 1) * LINE_HEIGHT)
				end,
				Size = UDim2.new(1, -2 * PAD, 0, LINE_HEIGHT),
				FontFace = Theme.font.body,
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = function()
					local line = lines()[i]
					return if line then Strings.format(line.key, line.vars) else ""
				end,
				Visible = function()
					return lines()[i] ~= nil
				end,
				maxSize = 15,
				ZIndex = 21,
			})
		)
	end

	local panel: Frame? = nil
	panel = Kit.tooltip({
		Name = "ItemTooltip",
		AnchorPoint = Vector2.new(0.5, 1),
		Visible = function()
			return def() ~= nil
		end,
		-- Em cima do slot, centralizada, sem sair da tela.
		Position = function()
			local hover = ItemHover.current()
			-- Na montagem a própria dica ainda não existe (a posição roda antes).
			if hover == nil or def() == nil or panel == nil then
				return UDim2.fromOffset(0, 0)
			end
			local scale = uiScale(panel)
			local anchor = hover.anchor
			local gui = panel:FindFirstAncestorOfClass("ScreenGui")
			local screenWidth = if gui then gui.AbsoluteSize.X / scale else 1920
			local x = (anchor.AbsolutePosition.X + anchor.AbsoluteSize.X / 2) / scale
			local half = WIDTH / 2
			x = math.clamp(x, half + EDGE, math.max(screenWidth - half - EDGE, half + EDGE))
			local y = anchor.AbsolutePosition.Y / scale - GAP
			return UDim2.fromOffset(x, math.max(y, height() + EDGE))
		end,
		Size = function()
			return UDim2.fromOffset(WIDTH, height())
		end,
		ZIndex = 20,
		Rustic.label({
			dark = true,
			Name = "ItemName",
			Position = UDim2.fromOffset(PAD, PAD),
			Size = UDim2.new(1, -2 * PAD, 0, NAME_HEIGHT),
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = function()
				local current = def()
				return if current then Strings.get(current.nameKey) else ""
			end,
			maxSize = 20,
			ZIndex = 21,
		}),
		Rustic.label({
			dark = true,
			Name = "Tier",
			Position = UDim2.fromOffset(PAD, PAD + NAME_HEIGHT),
			Size = UDim2.new(1, -2 * PAD, 0, TIER_HEIGHT),
			TextXAlignment = Enum.TextXAlignment.Left,
			FontFace = Theme.font.label,
			TextColor3 = function()
				local current = def()
				local color: string? = nil
				if current then
					local _, tierColor = ItemInfo.tier(current)
					color = tierColor
				end
				-- Escurecida: a cor pura do tier (ouro, madeira) some no papel claro.
				return if color then Theme.color(color):Lerp(Color3.new(0, 0, 0), 0.35) else Theme.rustic.charcoal
			end,
			Text = function()
				local key = tierKey()
				return if key then Strings.get(key) else ""
			end,
			Visible = function()
				return tierKey() ~= nil
			end,
			maxSize = 14,
			ZIndex = 21,
		}),
		rows,
	})
	return panel :: Frame
end

return ItemTooltip
