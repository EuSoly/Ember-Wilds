--!strict
-- Painel da caixa: aparece sozinho com uma caixa perto, empilhado logo acima do
-- painel do baú (acima da hotbar), com os itens da caixa em grade. Clicar/tocar
-- num slot pega o item (o servidor entrega o que couber no inventário).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local ChestState = require(script.Parent.Parent:WaitForChild("ChestState"))
local CrateState = require(script.Parent.Parent:WaitForChild("CrateState"))
local HudArt = require(script.Parent:WaitForChild("HudArt"))
local ItemIcon = require(script.Parent:WaitForChild("ItemIcon"))
local Kit = require(script.Parent:WaitForChild("Kit"))

local create = vide.create

local CELL = 56 -- px (slot: acima do mínimo de toque)
local GAP = 6
local COLUMNS = 8
local CHEST_SPACE = 76 -- px: altura do painel do baú (64) + folga, para não sobrepor

local function CratePanel(): Frame
	return Kit.panel({
		Name = "CratePanel",
		AnchorPoint = Vector2.new(0.5, 1),
		-- Na base do painel do baú; sobe a altura dele só quando o baú está visível.
		Position = function()
			return UDim2.new(0.5, 0, 0.77, if ChestState.near() ~= nil then -CHEST_SPACE else 0)
		end,
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.fromOffset(0, 0),
		Visible = function()
			return CrateState.near() ~= nil
		end,
		create("UIPadding")({
			PaddingTop = UDim.new(0, Kit.panelPadding(GAP)),
			PaddingBottom = UDim.new(0, Kit.panelPadding(GAP)),
			PaddingLeft = UDim.new(0, Kit.panelPadding(GAP)),
			PaddingRight = UDim.new(0, Kit.panelPadding(GAP)),
		}),
		create("UIListLayout")({
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, GAP),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		Kit.text({
			Name = "Title",
			LayoutOrder = 1,
			Size = UDim2.fromOffset(COLUMNS * CELL + (COLUMNS - 1) * GAP, 20),
			Text = Strings.get("hud.crate"),
			maxSize = 18,
		}),
		create("Frame")({
			Name = "Slots",
			LayoutOrder = 2,
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.fromOffset(COLUMNS * CELL + (COLUMNS - 1) * GAP, 0),
			create("UIGridLayout")({
				CellSize = UDim2.fromOffset(CELL, CELL),
				CellPadding = UDim2.fromOffset(GAP, GAP),
				FillDirectionMaxCells = COLUMNS,
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			vide.indexes(CrateState.contents, function(item, index)
				return create("TextButton")({
					Name = "CrateSlot",
					LayoutOrder = index,
					Text = "",
					AutoButtonColor = false,
					BackgroundColor3 = Theme.ui.panel,
					-- Com a arte, o couro do slot é o fundo e a borda.
					BackgroundTransparency = if HudArt.HAS_SLOT then 1 else Theme.panelTransparency,
					BorderSizePixel = 0,
					create("UICorner")({ CornerRadius = Theme.slotCorner }),
					create("UIStroke")({
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
						Color = Theme.ui.border,
						Thickness = Theme.strokeThickness,
						Enabled = not HudArt.HAS_SLOT,
					}),
					if HudArt.HAS_SLOT then { HudArt.slotBack() } else {},
					Activated = function()
						CrateState.take(index)
					end,
					if HudArt.HAS_SLOT
						then HudArt.inSlot(ItemIcon({ item = item, bare = true }))
						else ItemIcon({ item = item }),
				})
			end),
		}),
	}) :: Frame
end

return CratePanel
