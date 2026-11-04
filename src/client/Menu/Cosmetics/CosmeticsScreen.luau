--!strict
-- Cosméticos (tela principal): janela rústica no centro do menu, no visual do
-- Perfil, sem escurecer o menu atrás. Abre pelo botão Cosméticos da coluna
-- (painel "cosmetics" do MenuState); Fechar volta ao "play".
--
-- No meio, a vitrine: o boneco com tudo equipado (MenuBoneco: skin, mochila
-- nas costas e livro na mão) e, embaixo, a caixa equipada (CratePreview).
-- Dos lados, um cartão por categoria (CosmeticCatalog.CATEGORIES): placa com
-- o nome, uma frase e até 3 quadradinhos das skins que o jogador tem (o item
-- em 3D sobre a cor da raridade). Tem = a padrão do slot ou Owns_<id> no
-- Player. Acessórios ainda não tem slot: mostra "Em breve" e não abre.
--
-- Clicar num cartão abre a categoria: o estado local `category` (nil = esta
-- tela principal) guarda qual, e a CategoryView aparece no lugar da Main (com
-- o próprio Voltar; o Fechar some). Onde cada peça fica vem do
-- CosmeticsLayout; no celular tudo vira uma lista que rola, com o Fechar
-- sempre à vista.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Defs = require(Shared:WaitForChild("Defs"))
local UIFlow = Shared:WaitForChild("UIFlow")
local CosmeticCatalog = require(UIFlow:WaitForChild("CosmeticCatalog"))
local CosmeticsLayout = require(UIFlow:WaitForChild("CosmeticsLayout"))
local MockStore = require(UIFlow:WaitForChild("MockStore"))
local StatNames = require(Shared:WaitForChild("StatNames"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local Menu = script.Parent.Parent
local Client = Menu.Parent
local ScreenState = require(Client:WaitForChild("ScreenState"))
local Rustic = require(Client:WaitForChild("UI"):WaitForChild("Rustic"))
local Sources = require(Client:WaitForChild("UI"):WaitForChild("Sources"))
local MenuState = require(Menu:WaitForChild("MenuState"))
local MenuBoneco = require(Menu:WaitForChild("MenuBoneco"))
local CategoryView = require(script.Parent:WaitForChild("CategoryView"))
local CratePreview = require(script.Parent:WaitForChild("CratePreview"))
local ItemViewport = require(script.Parent:WaitForChild("ItemViewport"))

local create = vide.create
local R = Theme.rustic

local TITLE_HEIGHT = CosmeticsLayout.TITLE_HEIGHT
local BODY_TOP = CosmeticsLayout.BODY_TOP
local BODY_SIDE = CosmeticsLayout.BODY_SIDE
local BODY_BOTTOM = CosmeticsLayout.BODY_BOTTOM

local BODY = Color3.fromHex("#2B2018")
local ROW = Color3.fromHex("#3A2B20")
local SHOWCASE = Color3.fromHex("#221912") -- fundo da vitrine, um tom abaixo do corpo

local SAMPLE_MAX = 3
-- Cartão (pixels lógicos a partir do topo): placa, frase e as amostras embaixo.
local PLATE_TOP, PLATE_HEIGHT = 6, 30
local TAGLINE_TOP, TAGLINE_HEIGHT = 40, 18
local SAMPLES_TOP, SAMPLES_BOTTOM = 62, 8
local TILE_GAP = 6

-- Fonte Vide: chamar sem argumento lê, com argumento escreve.
type Source<T> = (() -> T) & ((T) -> T)

local CosmeticsScreen = {}

local function outlined(props: { [any]: any }): TextLabel
	table.insert(props, create("UIStroke")({ Color = R.outline, Thickness = 2 }))
	return Rustic.label(props)
end

local function place(rect: () -> CosmeticsLayout.Rect): { [string]: any }
	return {
		Position = function()
			local r = rect()
			return UDim2.fromOffset(r.x, r.y)
		end,
		Size = function()
			local r = rect()
			return UDim2.fromOffset(r.w, r.h)
		end,
	}
end

-- Ids (separados por vírgula) das até 3 skins do slot que o jogador tem: a
-- equipada primeiro, depois das mais raras para as mais comuns.
local function sampleIds(slot: string): () -> string
	local player = Players.LocalPlayer
	local default = Defs.CosmeticSlots[slot].default
	local items = CosmeticCatalog.items(slot)
	local owned: { [string]: () -> boolean } = {}
	for _, def in items do
		owned[def.id] = Sources.attribute(player, StatNames.OwnedPrefix .. def.id, false)
	end
	local equipped = Sources.attribute(player, StatNames.CosmeticPrefix .. slot, default)
	local function has(id: string): boolean
		return id == default or (owned[id] ~= nil and owned[id]() == true)
	end
	return vide.derive(function(): string
		local list: { string } = {}
		local current = equipped()
		if owned[current] ~= nil and has(current) then
			table.insert(list, current)
		end
		for i = #items, 1, -1 do
			if #list >= SAMPLE_MAX then
				break
			end
			local id = items[i].id
			if id ~= current and has(id) then
				table.insert(list, id)
			end
		end
		return table.concat(list, ",")
	end)
end

-- Quadradinho da amostra: cor da raridade com o item em 3D por cima.
local function tile(id: string, order: number): Frame
	local def = Defs.Cosmetics[id]
	local rarity = MockStore.RARITIES[def.rarity] or MockStore.RARITIES[1]
	local frame = create("Frame")({
		Name = "Tile_" .. id,
		LayoutOrder = order,
		Size = UDim2.new(1 / SAMPLE_MAX, -TILE_GAP, 1, 0),
		BackgroundColor3 = Color3.fromHex(rarity.color),
		BorderSizePixel = 0,
		create("UIAspectRatioConstraint")({ AspectRatio = 1 }),
		create("UICorner")({ CornerRadius = UDim.new(0, 6) }),
		create("UIStroke")({ Color = R.outline, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
	}) :: Frame
	ItemViewport.build(id).Parent = frame
	return frame
end

-- Linha das amostras. Os quadradinhos (ViewportFrames) só existem com a tela
-- principal à vista: montados ao abrir e refeitos quando a posse ou a
-- equipada muda.
local function samples(slot: string, open: () -> boolean): Frame
	local ids = sampleIds(slot)
	local row = create("Frame")({
		Name = "Samples",
		Position = UDim2.fromOffset(8, SAMPLES_TOP),
		Size = UDim2.new(1, -16, 1, -(SAMPLES_TOP + SAMPLES_BOTTOM)),
		BackgroundTransparency = 1,
		create("UIListLayout")({
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, TILE_GAP),
		}),
	}) :: Frame
	local tiles: { Instance } = {}
	vide.effect(function()
		local key = if open() then ids() else ""
		for _, old in tiles do
			old:Destroy()
		end
		table.clear(tiles)
		if key == "" then
			return
		end
		for i, id in string.split(key, ",") do
			local new = tile(id, i)
			new.Parent = row
			table.insert(tiles, new)
		end
	end)
	return row
end

local function soon(): TextLabel
	return outlined({
		Name = "Soon",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0, SAMPLES_TOP + 20),
		Size = UDim2.new(0.8, 0, 0, 26),
		FontFace = Theme.font.title,
		TextColor3 = R.emberLight,
		Text = string.upper(Strings.get("cosmetics.soon")),
		maxSize = 22,
	})
end

local function card(
	category: CosmeticCatalog.Category,
	rect: () -> CosmeticsLayout.Rect,
	open: () -> boolean,
	choose: (id: string) -> ()
): TextButton
	local slot = category.slot
	local props: { [any]: any } = place(rect)
	props.Name = "Card_" .. category.id
	props.Text = ""
	props.AutoButtonColor = slot ~= nil
	props.Active = slot ~= nil
	props.BackgroundColor3 = ROW
	props.BorderSizePixel = 0
	props.Activated = function()
		if slot ~= nil then
			choose(category.id)
		end
	end
	table.insert(props, create("UICorner")({ CornerRadius = UDim.new(0, 8) }))
	table.insert(
		props,
		create("UIStroke")({ Color = R.woodShadow, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
	)
	table.insert(
		props,
		Rustic.plate({
			Name = "NamePlate",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, PLATE_TOP),
			Size = UDim2.new(0.8, 0, 0, PLATE_HEIGHT),
			outlined({
				Name = "Name",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.88, 0.7),
				FontFace = Theme.font.title,
				Text = string.upper(Strings.get("cosmetics.category." .. category.id)),
				maxSize = 20,
			}),
		})
	)
	table.insert(
		props,
		Rustic.label({
			Name = "Tagline",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, TAGLINE_TOP),
			Size = UDim2.new(1, -16, 0, TAGLINE_HEIGHT),
			FontFace = Theme.font.body,
			TextColor3 = R.textSecondaryDark,
			Text = Strings.get("cosmetics.tagline." .. category.id),
			maxSize = 15,
		})
	)
	table.insert(props, if slot ~= nil then samples(slot, open) else soon())
	return create("TextButton")(props) :: TextButton
end

-- A janela dos Cosméticos (filha do MenuShell; aparece com o painel
-- "cosmetics"). `screenSize` = tamanho da tela em pixels lógicos.
function CosmeticsScreen.build(screenSize: () -> Vector2): Frame
	local player = Players.LocalPlayer
	local sides: { string } = {}
	for _, category in CosmeticCatalog.CATEGORIES do
		table.insert(sides, category.side)
	end
	local layout = vide.derive(function(): CosmeticsLayout.Layout
		local size = screenSize()
		return CosmeticsLayout.compute(size.X, size.Y, sides)
	end)

	local function open(): boolean
		return MenuState.panel() == "cosmetics" and ScreenState.current() == "menu"
	end
	-- Categoria aberta (nil = tela principal). A CategoryView lê e escreve
	-- esta fonte (Voltar = nil); fechar a janela volta à principal.
	local category: Source<string?> = vide.source(nil :: string?) :: any
	vide.effect(function()
		if not open() then
			category(nil)
		end
	end)
	local function main(): boolean
		return open() and category() == nil
	end

	-- Vitrine: o boneco com tudo equipado e a caixa equipada embaixo.
	local boneco = MenuBoneco.build(main)
	vide.apply(boneco)(place(function()
		return layout().boneco
	end))
	local crate = CratePreview.build(
		Sources.attribute(player, StatNames.CosmeticPrefix .. "crate", Defs.CosmeticSlots.crate.default)
	)
	vide.apply(crate)(place(function()
		return layout().crate
	end))
	-- Fundo da vitrine: o retângulo que cobre o boneco e a caixa.
	local showcase = create("Frame")({
		Name = "Showcase",
		BackgroundColor3 = SHOWCASE,
		BorderSizePixel = 0,
		create("UICorner")({ CornerRadius = UDim.new(0, 10) }),
		place(function()
			local l = layout()
			local x = math.min(l.boneco.x, l.crate.x)
			local y = math.min(l.boneco.y, l.crate.y)
			local right = math.max(l.boneco.x + l.boneco.w, l.crate.x + l.crate.w)
			local bottom = math.max(l.boneco.y + l.boneco.h, l.crate.y + l.crate.h)
			return { x = x, y = y, w = right - x, h = bottom - y }
		end),
	}) :: Frame

	local children: { Instance } = { showcase, boneco, crate }
	for i, entry in CosmeticCatalog.CATEGORIES do
		table.insert(
			children,
			card(
				entry,
				function()
					return layout().cards[i]
				end,
				main,
				function(id: string)
					category(id)
				end
			)
		)
	end

	return create("Frame")({
		Name = "Cosmetics",
		Visible = function()
			return MenuState.panel() == "cosmetics"
		end,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, TITLE_HEIGHT / 4),
		Size = function()
			local l = layout()
			return UDim2.fromOffset(l.windowWidth, l.windowHeight)
		end,
		BackgroundColor3 = BODY,
		BorderSizePixel = 0,
		Active = true,
		ZIndex = 8, -- acima das placas do topo (o saldo usa 6)
		create("UICorner")({ CornerRadius = UDim.new(0, 12) }),
		create("UIStroke")({
			Color = R.woodShadow,
			Thickness = 4,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
		Rustic.plate({
			Name = "TitlePlate",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0),
			Size = UDim2.new(0.5, 0, 0, TITLE_HEIGHT),
			ZIndex = 3,
			create("UISizeConstraint")({ MaxSize = Vector2.new(360, math.huge) }),
			outlined({
				Name = "Title",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.86, 0.6),
				FontFace = Theme.font.title,
				Text = string.upper(Strings.get("cosmetics.title")),
				maxSize = 32,
				ZIndex = 4,
			}),
		}),
		-- Tela principal: no PC cabe sem rolar; no celular a lista rola.
		create("ScrollingFrame")({
			Name = "Main",
			Visible = function()
				return category() == nil
			end,
			Position = UDim2.fromOffset(BODY_SIDE, BODY_TOP),
			Size = UDim2.new(1, -2 * BODY_SIDE, 1, -(BODY_TOP + BODY_BOTTOM)),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = function()
				return UDim2.fromOffset(0, layout().canvasHeight)
			end,
			ScrollBarThickness = function()
				return if layout().compact then 6 else 0
			end,
			ScrollBarImageColor3 = R.woodLight,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			children,
		}),
		CategoryView.build(category, layout),
		Rustic.button({
			Name = "CloseButton",
			Visible = function()
				return category() == nil
			end,
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -14),
			Size = UDim2.fromOffset(200, CosmeticsLayout.CLOSE_HEIGHT),
			kind = "ember",
			text = Strings.get("menu.close"),
			maxSize = 24,
			Activated = function()
				MenuState.open("play")
			end,
		}),
	}) :: Frame
end

return CosmeticsScreen
