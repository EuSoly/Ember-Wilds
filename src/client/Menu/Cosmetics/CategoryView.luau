--!strict
-- Cosméticos (tela da categoria): aparece no lugar da tela principal quando o
-- jogador clica num cartão (a fonte `category` do CosmeticsScreen).
--
-- Esquerda: a vitrine com a skin selecionada (corpo/mochila → o boneco com
-- ela; caixa → a prévia da caixa; livro → o boneco com o livro), o nome e a
-- raridade (na cor da raridade) e o Voltar. Direita: placa com a categoria,
-- grade 3×3 das skins do slot (CosmeticCatalog.items: da Comum à Mítica) e as
-- setas das páginas, desativadas nas pontas.
--
-- Cada quadradinho: fundo na cor da raridade, o item em 3D e o nome. A
-- equipada tem a borda de brasa; a selecionada (experimentando), borda creme.
-- Sem posse (não é a padrão e não está na pasta OwnedCosmetics) fica escurecida com um
-- cadeado. Clique: tem → pede ao servidor para equipar e seleciona; não tem →
-- só seleciona (experimenta na vitrine). A posse e a equipada são atributos
-- do Player, então dar a skin com a tela aberta tira o cadeado na hora.
--
-- Cada abertura monta tudo de novo: a seleção volta à equipada e a página é a
-- da equipada. Voltar (ou fechar a janela) desmonta e a vitrine principal
-- mostra o que está equipado.
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
local Net = require(Client:WaitForChild("Net"))
local Rustic = require(Client:WaitForChild("UI"):WaitForChild("Rustic"))
local Sources = require(Client:WaitForChild("UI"):WaitForChild("Sources"))
local MenuBoneco = require(Menu:WaitForChild("MenuBoneco"))
local CratePreview = require(script.Parent:WaitForChild("CratePreview"))
local ItemViewport = require(script.Parent:WaitForChild("ItemViewport"))

local create = vide.create
local R = Theme.rustic

local SHOWCASE = Color3.fromHex("#221912") -- igual ao fundo da vitrine principal
local PER_PAGE = CosmeticsLayout.PER_PAGE
local NAME_SHARE = 0.24 -- altura do nome no quadradinho (o resto é o item)
local LOCKED_SHADE = 0.45 -- transparência da sombra sobre a skin sem posse
local LOCK_SHARE = 0.2 -- largura do cadeado (fração do quadradinho)
local CRATE_SHARE = 0.8 -- tamanho da caixa na vitrine (fração do lado menor)

-- Borda do quadradinho: equipada (brasa grossa), selecionada (creme), comum.
local STROKE = {
	equipped = { color = R.ember, thickness = 4 },
	selected = { color = R.cream, thickness = 3 },
	normal = { color = R.outline, thickness = 2 },
}

-- Fonte Vide: chamar sem argumento lê, com argumento escreve.
type Source<T> = (() -> T) & ((T) -> T)

local CategoryView = {}

local function outlined(props: { [any]: any }, thickness: number?): TextLabel
	table.insert(props, create("UIStroke")({ Color = R.outline, Thickness = thickness or 2 }))
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

-- O vide.switch só tira do pai o que desmonta: destrói depois (no fim do
-- quadro) para soltar os ViewportFrames e os modelos.
local function destroyLater(instance: Instance)
	vide.cleanup(function()
		task.defer(function()
			instance:Destroy()
		end)
	end)
end

local function rarityOf(id: string): MockStore.Rarity
	local def = Defs.Cosmetics[id]
	return def and MockStore.RARITIES[def.rarity] or MockStore.RARITIES[1]
end

-- Cadeadinho de peças (alça e corpo), no canto do quadradinho.
local function lockIcon(): Frame
	return create("Frame")({
		Name = "Lock",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -4, 0, 4),
		-- Pequeno em relação ao quadradinho (no celular ele é bem menor).
		Size = UDim2.fromScale(LOCK_SHARE, LOCK_SHARE),
		BackgroundTransparency = 1,
		ZIndex = 4,
		create("UIAspectRatioConstraint")({ AspectRatio = 0.8 }),
		create("UISizeConstraint")({ MaxSize = Vector2.new(16, 20) }),
		create("Frame")({
			Name = "Shackle",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0),
			Size = UDim2.fromScale(0.62, 0.6),
			BackgroundTransparency = 1,
			ZIndex = 4,
			create("UICorner")({ CornerRadius = UDim.new(0.5, 0) }),
			create("UIStroke")({ Color = R.cream, Thickness = 2 }),
		}),
		create("Frame")({
			Name = "Body",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.5, 1),
			Size = UDim2.fromScale(1, 0.58),
			BackgroundColor3 = R.cream,
			BorderSizePixel = 0,
			ZIndex = 5,
			create("UICorner")({ CornerRadius = UDim.new(0, 3) }),
			create("UIStroke")({ Color = R.outline, Thickness = 1.5 }),
			create("Frame")({
				Name = "Keyhole",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.2, 0.45),
				BackgroundColor3 = R.outline,
				BorderSizePixel = 0,
				ZIndex = 6,
			}),
		}),
	}) :: Frame
end

type Slot = {
	slot: string,
	equipped: () -> string,
	has: (id: string) -> boolean,
	selected: Source<string>,
}

-- Quadradinho da skin `id` (a i-ésima da página).
local function tile(state: Slot, id: string, i: number, rect: (i: number) -> CosmeticsLayout.Rect): TextButton
	local def = Defs.Cosmetics[id]
	local rarity = rarityOf(id)
	local function locked(): boolean
		return not state.has(id)
	end
	local function stroke()
		if state.equipped() == id then
			return STROKE.equipped
		elseif state.selected() == id then
			return STROKE.selected
		end
		return STROKE.normal
	end
	local props: { [any]: any } = place(function()
		return rect(i)
	end)
	props.Name = "Tile_" .. id
	props.Text = ""
	props.AutoButtonColor = true
	props.BackgroundColor3 = Color3.fromHex(rarity.color)
	props.BorderSizePixel = 0
	props.Activated = function()
		if state.has(id) and vide.untrack(state.equipped) ~= id then
			Net.EquipCosmetic.Fire({ Id = id })
		end
		state.selected(id)
	end
	table.insert(props, create("UICorner")({ CornerRadius = UDim.new(0, 8) }))
	table.insert(
		props,
		create("UIStroke")({
			Color = function()
				return stroke().color
			end,
			Thickness = function()
				return stroke().thickness
			end,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		})
	)
	table.insert(
		props,
		outlined({
			Name = "ItemName",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -2),
			Size = UDim2.new(1, -6, NAME_SHARE, -2),
			FontFace = Theme.font.label,
			Text = Strings.get(def.nameKey),
			maxSize = 16,
			ZIndex = 2,
		}, 1.5)
	)
	table.insert(
		props,
		create("Frame")({
			Name = "Shade",
			Visible = locked,
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = LOCKED_SHADE,
			BorderSizePixel = 0,
			ZIndex = 3,
			create("UICorner")({ CornerRadius = UDim.new(0, 8) }),
		})
	)
	local lock = lockIcon()
	vide.apply(lock)({ Visible = locked })
	table.insert(props, lock)

	local button = create("TextButton")(props) :: TextButton
	local item = ItemViewport.build(id)
	item.Size = UDim2.fromScale(1, 1 - NAME_SHARE)
	item.ZIndex = 1
	item.Parent = button
	return button
end

-- Vitrine da categoria: o que está selecionado agora.
local function showcase(state: Slot): GuiObject
	local slot = state.slot
	local function always(): boolean
		return true
	end
	if slot == "crate" then
		return CratePreview.build(function()
			return state.selected()
		end)
	elseif slot == "body" then
		return MenuBoneco.build(always, function(): MenuBoneco.Override
			return { body = state.selected() }
		end)
	elseif slot == "bag" then
		return MenuBoneco.build(always, function(): MenuBoneco.Override
			return { bag = state.selected() }
		end)
	end
	return MenuBoneco.build(always) -- livro: o boneco com o livro de sempre
end

-- Conteúdo de uma categoria. Montado a cada abertura (vide.switch).
local function view(
	category: CosmeticCatalog.Category,
	layout: () -> CosmeticsLayout.CategoryLayout,
	back: () -> ()
): Frame
	local slot = category.slot :: string
	local player = Players.LocalPlayer
	local default = Defs.CosmeticSlots[slot].default
	local items = CosmeticCatalog.items(slot)
	local owned: { [string]: () -> boolean } = {}
	for _, def in items do
		owned[def.id] = Sources.childAttribute(player, StatNames.OwnedFolder, def.id, false)
	end
	local equipped = Sources.attribute(player, StatNames.CosmeticPrefix .. slot, default)
	local state: Slot = {
		slot = slot,
		equipped = equipped,
		has = function(id: string): boolean
			return id == default or (owned[id] ~= nil and owned[id]() == true)
		end,
		selected = vide.source(vide.untrack(equipped)) :: any,
	}
	local pageCount = CosmeticCatalog.pageCount(#items, PER_PAGE)
	local page: Source<number> = vide.source(CosmeticCatalog.pageOf(items, vide.untrack(equipped), PER_PAGE)) :: any

	local function selectedDef(): Defs.CosmeticDef?
		return Defs.Cosmetics[state.selected()]
	end
	local function tileRect(i: number): CosmeticsLayout.Rect
		return layout().tiles[i]
	end

	-- Grade: uma página de quadradinhos por vez (vide.switch monta a nova e
	-- desmonta a velha); posse, equipada e seleção só mudam propriedades.
	local pages: { [number]: (present: () -> boolean) -> Instance } = {}
	for number = 1, pageCount do
		pages[number] = function(_present: () -> boolean): Instance
			local holder = create("Frame")({
				Name = "Page" .. number,
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
			}) :: Frame
			for i, def in CosmeticCatalog.page(items, number, PER_PAGE) do
				tile(state, def.id, i, tileRect).Parent = holder
			end
			destroyLater(holder)
			return holder
		end
	end
	local grid = create("Frame")({
		Name = "Grid",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		vide.switch(page)(pages :: any),
	}) :: Frame

	local function arrow(name: string, text: string, step: number, rect: () -> CosmeticsLayout.Rect): TextButton
		local function can(): boolean
			local target = page() + step
			return target >= 1 and target <= pageCount
		end
		local props: { [any]: any } = place(rect)
		props.Name = name
		props.kind = function()
			return if can() then "wood" else "disabled"
		end
		props.text = text
		props.maxSize = 26
		props.Activated = function()
			if vide.untrack(can) then
				page(vide.untrack(page) + step)
			end
		end
		return Rustic.button(props)
	end

	local backProps: { [any]: any } = place(function()
		return layout().back
	end)
	backProps.Name = "BackButton"
	backProps.kind = "leather"
	backProps.text = Strings.get("cosmetics.back")
	backProps.maxSize = 22
	backProps.Activated = back

	local preview = showcase(state)
	if slot == "crate" then
		-- A câmera da caixa enquadra num quadrado: centralizada e com folga.
		vide.apply(preview)({
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(CRATE_SHARE, CRATE_SHARE),
			create("UIAspectRatioConstraint")({ AspectRatio = 1 }),
		})
	else
		vide.apply(preview)({ Size = UDim2.fromScale(1, 1) })
	end

	local frame = create("Frame")({
		Name = "Category_" .. category.id,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		create("Frame")({
			Name = "Showcase",
			BackgroundColor3 = SHOWCASE,
			BorderSizePixel = 0,
			create("UICorner")({ CornerRadius = UDim.new(0, 10) }),
			place(function()
				return layout().showcase
			end),
			preview,
		}) :: Instance,
		outlined({
			Name = "SkinName",
			FontFace = Theme.font.title,
			Text = function()
				local def = selectedDef()
				return if def then string.upper(Strings.get(def.nameKey)) else ""
			end,
			maxSize = 24,
			place(function()
				return layout().name
			end),
		}),
		outlined({
			Name = "Rarity",
			FontFace = Theme.font.label,
			TextColor3 = function()
				return Color3.fromHex(rarityOf(state.selected()).color)
			end,
			Text = function()
				return Strings.get(rarityOf(state.selected()).nameKey)
			end,
			maxSize = 18,
			place(function()
				return layout().rarity
			end),
		}),
		Rustic.button(backProps),
		Rustic.plate({
			Name = "NamePlate",
			place(function()
				return layout().plate
			end),
			outlined({
				Name = "Name",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.88, 0.7),
				FontFace = Theme.font.title,
				Text = string.upper(Strings.get("cosmetics.category." .. category.id)),
				maxSize = 20,
			}),
		}),
		arrow("PrevPage", "<", -1, function()
			return layout().prev
		end),
		arrow("NextPage", ">", 1, function()
			return layout().next
		end),
		grid,
	}) :: Frame
	destroyLater(frame)
	return frame
end

-- A tela da categoria (filha da janela, ao lado da Main). Aparece quando
-- `category()` tem uma categoria com slot; Voltar escreve nil.
function CategoryView.build(category: Source<string?>, layout: () -> CosmeticsLayout.Layout): Frame
	local function categoryLayout(): CosmeticsLayout.CategoryLayout
		return layout().category
	end
	local function back()
		category(nil)
	end
	local views: { [string]: (present: () -> boolean) -> Instance } = {}
	for _, entry in CosmeticCatalog.CATEGORIES do
		if entry.slot ~= nil then
			views[entry.id] = function(_present: () -> boolean): Instance
				return view(entry, categoryLayout, back)
			end
		end
	end
	return create("Frame")({
		Name = "Category",
		Visible = function()
			return category() ~= nil
		end,
		Position = UDim2.fromOffset(CosmeticsLayout.BODY_SIDE, CosmeticsLayout.BODY_TOP),
		Size = UDim2.new(
			1,
			-2 * CosmeticsLayout.BODY_SIDE,
			1,
			-(CosmeticsLayout.BODY_TOP + CosmeticsLayout.CATEGORY_BOTTOM)
		),
		BackgroundTransparency = 1,
		vide.switch(function(): string?
			return category()
		end)(views :: any),
	}) :: Frame
end

return CategoryView
