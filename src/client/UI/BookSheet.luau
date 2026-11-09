--!strict
-- Ficha do item no livro de receitas, num papel: nome e material, Como fazer
-- (ingredientes clicáveis), Precisa de (estação e tempo), Dados, Onde
-- conseguir (mobs e recursos do mapa) e Serve para (itens clicáveis). Seção
-- sem conteúdo não aparece. Tudo vem do UIFlow/BookInfo.
--
-- O conteúdo só depende do item: a cada troca, é montado de novo num
-- vide.root próprio e o anterior é desmontado (solta ícones 3D e retratos).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local BookImages = require(Shared:WaitForChild("BookImages"))
local BookInfo = require(Shared:WaitForChild("UIFlow"):WaitForChild("BookInfo"))
local Defs = require(Shared:WaitForChild("Defs"))
local ItemInfo = require(Shared:WaitForChild("UIFlow"):WaitForChild("ItemInfo"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local HudArt = require(script.Parent:WaitForChild("HudArt"))
local ItemIcon = require(script.Parent:WaitForChild("ItemIcon"))
local MobPortrait = require(script.Parent:WaitForChild("MobPortrait"))
local Rustic = require(script.Parent:WaitForChild("Rustic"))

local create = vide.create

local PAD_X = 24 -- folga até a borda do papel
local PAD_Y = 20
local CHIP_HEIGHT = 44
local CHIP_WIDTH = 168
local ROW_HEIGHT = 30
local SOURCE_HEIGHT = 52
local SECTION_COLOR = Color3.fromRGB(122, 84, 46) -- título de seção: marrom do couro
-- O livro mostra o que o jogador vê: sem itens de teste, nem no Studio
-- (decisão do Elizeu, 09/11). Craftar no Studio pela coluna continua valendo.
local inStudio = false

export type Props = {
	item: () -> string?,
	onShow: (string) -> (), -- abre a ficha de outro item (ingrediente, "serve para")
	Position: UDim2,
	Size: UDim2,
}

local function text(props: { [any]: any }): TextLabel
	local size = props.size or 16
	props.size = nil
	local label = create("TextLabel")({
		BackgroundTransparency = 1,
		FontFace = Theme.font.number,
		TextColor3 = Theme.rustic.charcoal,
		TextSize = size,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
	}) :: TextLabel
	return vide.apply(label)(props) :: TextLabel
end

local function itemName(id: string): string
	local def = Defs.Items[id]
	return if def then Strings.get(def.nameKey) else id
end

-- Ícone pequeno (selo/estatística) ou nada sem a arte.
local function badge(id: string?, size: number): Instance?
	if not BookImages.has(id) then
		return nil
	end
	return HudArt.image(id :: string, {
		Name = "Badge",
		Size = UDim2.fromOffset(size, size),
		LayoutOrder = 0,
	})
end

-- Fileira com ícone (opcional) e texto, crescendo com o texto.
local function row(order: number, iconId: string?, label: string): Frame
	local children: { Instance } = {
		create("UIListLayout")({
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}
	local icon = badge(iconId, ROW_HEIGHT - 2)
	if icon then
		table.insert(children, icon)
	end
	table.insert(
		children,
		text({
			LayoutOrder = 1,
			-- Altura mínima de uma linha; texto comprido quebra e a fileira cresce.
			Size = UDim2.new(1, if icon then -(ROW_HEIGHT + 8) else 0, 0, ROW_HEIGHT),
			AutomaticSize = Enum.AutomaticSize.Y,
			TextYAlignment = Enum.TextYAlignment.Center,
			Text = label,
		})
	)
	return create("Frame")({
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, ROW_HEIGHT),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		children,
	}) :: Frame
end

local function sectionTitle(order: number, key: string): TextLabel
	return text({
		Name = "Title",
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 24),
		TextColor3 = SECTION_COLOR,
		Text = Strings.get(key),
		size = 17,
	})
end

-- Seção: título e as linhas; nil se não tem linhas.
local function section(order: number, key: string, rows: { Instance }): Frame?
	if #rows == 0 then
		return nil
	end
	return create("Frame")({
		Name = (string.gsub(key, "%.", "_")), -- sem pontos: o caminho da instância fica legível
		LayoutOrder = order,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		create("UIListLayout")({ Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
		sectionTitle(0, key),
		rows,
	}) :: Frame
end

-- Chip clicável de item (ingrediente ou "serve para"): ícone 3D + texto.
local function chip(id: string, label: string, onShow: (string) -> ()): TextButton
	local icon = ItemIcon({
		item = function()
			return { id = id, count = 1 }
		end,
		bare = HudArt.HAS_SLOT,
	})
	local holder = create("Frame")({
		Name = "Slot",
		Size = UDim2.fromOffset(CHIP_HEIGHT, CHIP_HEIGHT),
		BackgroundTransparency = 1,
	}) :: Frame
	if HudArt.HAS_SLOT then
		HudArt.slotBack().Parent = holder
		HudArt.inSlot(icon).Parent = holder
	else
		icon.Parent = holder
	end
	return create("TextButton")({
		Name = "Chip_" .. id,
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(CHIP_WIDTH, CHIP_HEIGHT),
		Activated = function()
			onShow(id)
		end,
		holder :: Instance,
		text({
			Position = UDim2.fromOffset(CHIP_HEIGHT + 6, 0),
			Size = UDim2.new(1, -CHIP_HEIGHT - 6, 1, 0),
			Text = label,
			-- Célula de tamanho fixo: o texto comprido encolhe (até 10) em vez de vazar.
			TextScaled = true,
			create("UITextSizeConstraint")({ MinTextSize = 10, MaxTextSize = 15 }),
		}),
	}) :: TextButton
end

local function chipGrid(order: number, chips: { Instance }): Frame
	return create("Frame")({
		LayoutOrder = order,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		create("UIGridLayout")({
			CellSize = UDim2.fromOffset(CHIP_WIDTH, CHIP_HEIGHT),
			CellPadding = UDim2.fromOffset(8, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		chips,
	}) :: Frame
end

local function toolText(hardness: number?): string
	if hardness == nil then
		return Strings.get("book.source.any")
	elseif hardness <= 0 then
		return Strings.get("book.source.hand")
	end
	return Strings.format("book.source.pickaxe", { level = hardness })
end

-- Uma fonte (mob ou recurso do mapa): retrato/ícone, nome e o detalhe.
local function sourceRow(order: number, source: BookInfo.Source): Frame
	local s = source :: any
	local picture: Instance
	local title: string
	local detail: string
	if s.kind == "mob" then
		picture = MobPortrait({ mob = s.id })
		local mob = Defs.Mobs[s.id]
		local name = if mob then Strings.get(mob.nameKey) else s.id
		title = name
		detail = Strings.format("book.source.mob", { count = s.count })
	else
		local icon = BookImages.RESOURCE[s.id]
		picture = if BookImages.has(icon) then HudArt.image(icon) else create("Frame")({ BackgroundTransparency = 1 })
		title = Strings.get("resource." .. s.id)
		detail = toolText(s.hardness)
	end
	vide.apply(picture :: any)({
		Name = "Picture",
		Size = UDim2.fromOffset(SOURCE_HEIGHT, SOURCE_HEIGHT),
	})
	return create("Frame")({
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, SOURCE_HEIGHT),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		picture :: Instance,
		create("Frame")({
			Name = "Texts",
			Position = UDim2.fromOffset(SOURCE_HEIGHT + 8, 4),
			Size = UDim2.new(1, -SOURCE_HEIGHT - 8, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			create("UIListLayout")({ Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }),
			text({
				LayoutOrder = 1,
				Size = UDim2.fromScale(1, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				Text = title,
				size = 17,
			}),
			text({
				LayoutOrder = 2,
				Size = UDim2.fromScale(1, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				Text = detail,
				size = 14,
			}),
		}),
	}) :: Frame
end

-- Todo o conteúdo da ficha de `id`.
local function content(id: string, onShow: (string) -> ()): { Instance }
	local def = Defs.Items[id]
	if def == nil then
		return {}
	end
	local out: { Instance } = {}
	local function add(child: Instance?)
		if child then
			table.insert(out, child)
		end
	end

	add(text({
		Name = "ItemName",
		LayoutOrder = 1,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = itemName(id),
		size = 24,
	}))
	local tierKey, tierColor = ItemInfo.tier(def)
	local subtitle = Strings.get("book.category." .. def.category)
	if tierKey then
		subtitle = `{Strings.get(tierKey)} · {subtitle}`
	end
	add(text({
		Name = "Subtitle",
		LayoutOrder = 2,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = subtitle,
		TextColor3 = if tierColor
			then Theme.color(tierColor):Lerp(Color3.new(0, 0, 0), 0.35)
			else Theme.rustic.charcoal,
		size = 15,
	}))

	local craft = BookInfo.craft(id)
	if craft then
		local chips: { Instance } = {}
		for index, ingredient in craft.ingredients do
			local item = chip(ingredient.id, `{ingredient.count}× {itemName(ingredient.id)}`, onShow)
			item.LayoutOrder = index
			table.insert(chips, item)
		end
		add(section(3, "book.section.how", { chipGrid(1, chips) }))

		local needs: { Instance } = {}
		local station = craft.station and BookInfo.STATIONS[craft.station]
		if station then
			table.insert(needs, row(1, BookImages.STATION[station.icon], Strings.get(station.key)))
		end
		local seconds = string.format("%.0f", craft.seconds)
		table.insert(needs, row(2, BookImages.CLOCK, Strings.format("book.seconds", { value = seconds })))
		add(section(4, "book.section.needs", needs))
	end

	local stats: { Instance } = {}
	for index, line in BookInfo.stats(id) do
		table.insert(stats, row(index, BookImages.STAT[line.key], Strings.format(line.key, line.vars)))
	end
	add(section(5, "book.section.stats", stats))

	local sources: { Instance } = {}
	for index, source in BookInfo.sources(id) do
		table.insert(sources, sourceRow(index, source))
	end
	add(section(6, "book.section.where", sources))

	local used: { Instance } = {}
	for index, result in BookInfo.usedIn(id, inStudio) do
		local item = chip(result, itemName(result), onShow)
		item.LayoutOrder = index
		table.insert(used, item)
	end
	if #used > 0 then
		add(section(7, "book.section.usedIn", { chipGrid(1, used) }))
	end
	return out
end

local function BookSheet(props: Props): Frame
	local list = create("ScrollingFrame")({
		Name = "Content",
		Position = UDim2.fromOffset(PAD_X, PAD_Y),
		Size = UDim2.new(1, -2 * PAD_X + 10, 1, -2 * PAD_Y),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = SECTION_COLOR,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}) :: ScrollingFrame

	-- Monta o conteúdo do item atual; o anterior sai junto com a sua raiz.
	local unmount: (() -> ())? = nil
	local body: Frame? = nil
	vide.effect(function()
		local id = props.item()
		vide.untrack(function()
			if unmount then
				unmount()
				unmount = nil
			end
			if body then
				body:Destroy()
				body = nil
			end
			if id == nil then
				return
			end
			unmount = vide.root(function(destroy)
				body = create("Frame")({
					Name = "Body",
					Size = UDim2.new(1, -12, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					create("UIListLayout")({ Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
					content(id, props.onShow),
				}) :: Frame
				return destroy
			end)
			if body then
				body.Parent = list
			end
			list.CanvasPosition = Vector2.zero
		end)
	end)
	vide.cleanup(function()
		if unmount then
			unmount()
		end
	end)

	local paper: Frame
	if BookImages.has(BookImages.PAPER) then
		local art = BookImages.SLICED.paper
		paper = create("ImageLabel")({
			BackgroundTransparency = 1,
			Image = BookImages.PAPER,
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(art.slice[1], art.slice[2], art.slice[3], art.slice[4]),
			SliceScale = 0.5,
		}) :: any
	else
		paper = Rustic.paper({})
	end
	return vide.apply(paper)({
		Name = "Sheet",
		Position = props.Position,
		Size = props.Size,
		list,
	}) :: Frame
end

return BookSheet
