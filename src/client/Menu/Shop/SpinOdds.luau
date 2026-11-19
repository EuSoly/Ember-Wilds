--!strict
-- Chances de cada item, embaixo dos dois lados da tela do giro (pedido do
-- Elizeu, 19/11): uma seção por raridade, de Comum a Mítico, fechadas por
-- padrão; clicar no cabeçalho abre a lista dos itens daquela raridade com a
-- chance de cada um no giro com Golden Ember e no Premium.
-- A conta é a do sorteio de verdade (SpinRules.itemChances com
-- ShopConfig.SPIN_ODDS): a chance da raridade dividida entre os itens dela.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local MockStore = require(Shared:WaitForChild("UIFlow"):WaitForChild("MockStore"))
local ShopConfig = require(Shared:WaitForChild("Shop"):WaitForChild("ShopConfig"))
local SpinRules = require(Shared:WaitForChild("UIFlow"):WaitForChild("SpinRules"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local Client = script.Parent.Parent.Parent
local Rustic = require(Client:WaitForChild("UI"):WaitForChild("Rustic"))

local create = vide.create
local R = Theme.rustic

local TITLE_HEIGHT = 30
local HEADER_HEIGHT = 36
local ROW_HEIGHT = 24
local GAP = 6
local NAME_SHARE = 0.5 -- largura da coluna do nome; as duas chances dividem o resto

type Entry = { name: string, normal: string, paid: string }
type Section = {
	rarity: number,
	entries: { Entry },
	normal: string, -- soma da raridade no giro com Golden Ember
	paid: string, -- soma no Premium
}

local SpinOdds = {}

local function percent(value: number): string
	return SpinRules.formatPercent(value, Strings.language() == "ptBR")
end

-- Seções (só as raridades que têm item nesta roleta), da Comum à Mítica.
local function sectionsOf(items: { MockStore.SpinItem }): { Section }
	local normal = SpinRules.itemChances(items, ShopConfig.SPIN_ODDS.normal)
	local paid = SpinRules.itemChances(items, ShopConfig.SPIN_ODDS.paid)
	local sections: { Section } = {}
	for rarity = 1, #MockStore.RARITIES do
		local list: { MockStore.SpinItem } = {}
		for _, item in items do
			if item.rarity == rarity then
				table.insert(list, item)
			end
		end
		if #list > 0 then
			table.sort(list, function(a, b)
				return Strings.get(a.nameKey) < Strings.get(b.nameKey)
			end)
			local entries: { Entry } = {}
			local normalSum, paidSum = 0, 0
			for _, item in list do
				local n, p = normal[item.id] or 0, paid[item.id] or 0
				normalSum += n
				paidSum += p
				table.insert(entries, { name = Strings.get(item.nameKey), normal = percent(n), paid = percent(p) })
			end
			table.insert(sections, {
				rarity = rarity,
				entries = entries,
				normal = percent(normalSum),
				paid = percent(paidSum),
			})
		end
	end
	return sections
end

-- Uma linha de três colunas (nome, Golden Ember, Premium).
local function row(name: () -> string, normal: () -> string, paid: () -> string, order: number, bold: boolean): Frame
	local font = if bold then Theme.font.number else Theme.font.label
	local color = if bold then R.emberLight else R.cream
	return create("Frame")({
		Name = `Row{order}`,
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, ROW_HEIGHT),
		BackgroundTransparency = 1,
		Rustic.label({
			Size = UDim2.fromScale(NAME_SHARE, 1),
			FontFace = font,
			TextColor3 = color,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Text = name,
			maxSize = 16,
		}),
		Rustic.label({
			Position = UDim2.fromScale(NAME_SHARE, 0),
			Size = UDim2.fromScale((1 - NAME_SHARE) / 2, 1),
			FontFace = font,
			TextColor3 = color,
			Text = normal,
			maxSize = 16,
		}),
		Rustic.label({
			Position = UDim2.fromScale(NAME_SHARE + (1 - NAME_SHARE) / 2, 0),
			Size = UDim2.fromScale((1 - NAME_SHARE) / 2, 1),
			FontFace = font,
			TextColor3 = color,
			Text = paid,
			maxSize = 16,
		}),
	}) :: Frame
end

local function SectionView(section: () -> Section, index: number): Frame
	local open = vide.source(false) -- fechada por padrão
	local function rarityColor(): Color3
		return Color3.fromHex(MockStore.RARITIES[section().rarity].color)
	end
	return create("Frame")({
		Name = `Section{index}`,
		LayoutOrder = index,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.fromHex("#2B2018"),
		BorderSizePixel = 0,
		create("UICorner")({ CornerRadius = UDim.new(0, 8) }),
		create("UIStroke")({ Color = rarityColor, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
		create("UIListLayout")({ SortOrder = Enum.SortOrder.LayoutOrder }),
		-- Cabeçalho (o botão): raridade e quantos itens, e a soma das chances.
		create("TextButton")({
			Name = "Header",
			LayoutOrder = 0,
			Size = UDim2.new(1, 0, 0, HEADER_HEIGHT),
			BackgroundColor3 = rarityColor,
			AutoButtonColor = true,
			Text = "",
			create("UICorner")({ CornerRadius = UDim.new(0, 8) }),
			create("UIPadding")({ PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }),
			Rustic.label({
				Size = UDim2.fromScale(NAME_SHARE, 1),
				dark = true,
				FontFace = Theme.font.number,
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = function()
					local s = section()
					local arrow = if open() then "▾" else "▸"
					local rarityName = Strings.get(MockStore.RARITIES[s.rarity].nameKey)
					return `{arrow}  {rarityName} ({#s.entries})`
				end,
				maxSize = 18,
			}),
			Rustic.label({
				Position = UDim2.fromScale(NAME_SHARE, 0),
				Size = UDim2.fromScale((1 - NAME_SHARE) / 2, 1),
				dark = true,
				FontFace = Theme.font.number,
				Text = function()
					return section().normal
				end,
				maxSize = 18,
			}),
			Rustic.label({
				Position = UDim2.fromScale(NAME_SHARE + (1 - NAME_SHARE) / 2, 0),
				Size = UDim2.fromScale((1 - NAME_SHARE) / 2, 1),
				dark = true,
				FontFace = Theme.font.number,
				Text = function()
					return section().paid
				end,
				maxSize = 18,
			}),
			Activated = function()
				open(not vide.untrack(open))
			end,
		}),
		-- Itens da raridade (só com a seção aberta).
		create("Frame")({
			Name = "Items",
			LayoutOrder = 1,
			Visible = open,
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			create("UIPadding")({
				PaddingLeft = UDim.new(0, 12),
				PaddingRight = UDim.new(0, 12),
				PaddingTop = UDim.new(0, 4),
				PaddingBottom = UDim.new(0, 6),
			}),
			create("UIListLayout")({ SortOrder = Enum.SortOrder.LayoutOrder }),
			vide.indexes(function()
				return section().entries
			end, function(entry, i)
				return row(function()
					return entry().name
				end, function()
					return entry().normal
				end, function()
					return entry().paid
				end, i, false)
			end),
		}),
	}) :: Frame
end

-- Painel inteiro para a roleta de `items` (a lista do tipo aberto).
function SpinOdds.panel(items: () -> { MockStore.SpinItem }): Frame
	local sections = function(): { Section }
		return sectionsOf(items())
	end
	return create("Frame")({
		Name = "SpinOdds",
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Visible = function()
			return #items() > 0
		end,
		create("UIListLayout")({ SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, GAP) }),
		create("UIPadding")({ PaddingBottom = UDim.new(0, 12) }),
		Rustic.label({
			Name = "Title",
			LayoutOrder = -2,
			Size = UDim2.new(1, 0, 0, TITLE_HEIGHT),
			FontFace = Theme.font.title,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = Strings.get("shop.odds.title"),
			maxSize = 24,
		}),
		-- Cabeçalho das colunas, alinhado com as seções (mesmo recuo).
		create("Frame")({
			Name = "Columns",
			LayoutOrder = -1,
			Size = UDim2.new(1, 0, 0, ROW_HEIGHT),
			BackgroundTransparency = 1,
			create("UIPadding")({ PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }),
			row(function()
				return Strings.get("shop.odds.item")
			end, function()
				return Strings.get("shop.spin.normal")
			end, function()
				return Strings.get("shop.spin.paid")
			end, 0, true),
		}),
		vide.indexes(sections, SectionView),
	}) :: Frame
end

return SpinOdds
