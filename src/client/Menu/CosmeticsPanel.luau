--!strict
-- Conteúdo do painel Cosméticos (mockup G7a): abas das categorias, prévia do
-- boneco num ViewportFrame e grade de cartões. Na aba Skins os cartões são as
-- skins de corpo reais e clicar pinta a prévia; nas outras são itens falsos que
-- só ficam "selecionados". Nada é salvo: a seleção é estado local do painel.
-- O boneco da prévia existe só enquanto o painel está aberto (um por vez).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Defs = require(Shared:WaitForChild("Defs"))
local MockStore = require(Shared:WaitForChild("UIFlow"):WaitForChild("MockStore"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local Client = script.Parent.Parent
local ScreenState = require(Client:WaitForChild("ScreenState"))
local BonecoModel = require(Client:WaitForChild("Boneco"):WaitForChild("BonecoModel"))
local Kit = require(Client:WaitForChild("UI"):WaitForChild("Kit"))
local MenuState = require(script.Parent:WaitForChild("MenuState"))

local create = vide.create

local SKINS = "skins"
local TAB_WIDTH = 0.19
local PREVIEW_WIDTH = 0.4
local TABS_ROW = Theme.touchMinSize.Y + 4 -- linha das abas + respiro; preview e grade começam abaixo
-- Câmera da prévia: de cima e de frente (a frente do boneco é -Z).
local CAMERA_DIRECTION = Vector3.new(0, 1, -1.1).Unit
local CAMERA_FOV = 30
local CAMERA_MARGIN = 1.15

type Card = { id: string, nameKey: string, look: Defs.BodyLook? }

-- Skins de corpo reais, em ordem estável.
local function bodySkins(): { Card }
	local cards: { Card } = {}
	for _, def in Defs.Cosmetics do
		if def.slot == "body" and def.body ~= nil then
			table.insert(cards, { id = def.id, nameKey = def.nameKey, look = def.body })
		end
	end
	table.sort(cards, function(a, b)
		return a.id < b.id
	end)
	return cards
end

-- Câmera olhando o centro do modelo, afastada até caber na prévia.
local function frameCamera(camera: Camera, model: Model)
	local cframe, size = model:GetBoundingBox()
	local radius = size.Magnitude / 2
	local distance = CAMERA_MARGIN * radius / math.sin(math.rad(CAMERA_FOV) / 2)
	camera.FieldOfView = CAMERA_FOV
	camera.CFrame = CFrame.lookAt(cframe.Position + CAMERA_DIRECTION * distance, cframe.Position)
end

local CosmeticsPanel = {}

-- Monta o conteúdo (chamar dentro do root Vide; o efeito da prévia mora nele).
function CosmeticsPanel.build(): Frame
	local skins = bodySkins()
	local defaultSkin = Defs.CosmeticSlots.body.default

	local tab = vide.source(SKINS)
	local skinSelected = vide.source(defaultSkin)
	local mockSelected = vide.source({} :: { [string]: string }) -- categoria → item

	local camera = Instance.new("Camera")
	local viewport = create("ViewportFrame")({
		Name = "Preview",
		Size = UDim2.fromScale(1, 0.86),
		BackgroundTransparency = 1,
		CurrentCamera = camera,
		camera,
	}) :: ViewportFrame

	local function skinLook(id: string): Defs.BodyLook
		local look = Defs.Cosmetics[id].body
		assert(look ~= nil, "[CosmeticsPanel] skin sem cores: " .. id)
		return look
	end

	-- Um boneco só: criado ao abrir, destruído ao fechar, ao trocar de painel ou
	-- ao sair do menu. O efeito roda síncrono, então abrir/fechar rápido não
	-- acumula. O build põe o modelo na pasta do Workspace; move já para a prévia.
	local preview: BonecoModel.Boneco? = nil
	vide.effect(function()
		local open = MenuState.panel() == "cosmetics" and ScreenState.current() == "menu"
		if open then
			local look = skinLook(skinSelected())
			if preview == nil then
				local boneco = BonecoModel.build("")
				boneco.model.Parent = viewport
				frameCamera(camera, boneco.model)
				preview = boneco
			end
			if preview ~= nil then
				BonecoModel.applyLook(preview, look)
			end
		elseif preview ~= nil then
			BonecoModel.destroy(preview)
			preview = nil
			tab(SKINS)
			skinSelected(defaultSkin)
			mockSelected({})
		end
	end)

	local function selectedName(): string
		local current = tab()
		if current == SKINS then
			return Strings.get(Defs.Cosmetics[skinSelected()].nameKey)
		end
		local itemId = mockSelected()[current]
		for _, category in MockStore.CATEGORIES do
			for _, item in category.items do
				if category.id == current and item.id == itemId then
					return Strings.get(item.nameKey)
				end
			end
		end
		return ""
	end

	local function tabButton(categoryId: string, nameKey: string): TextButton
		return create("TextButton")({
			Name = "Tab_" .. categoryId,
			Text = "",
			AutoButtonColor = true,
			Size = UDim2.fromScale(TAB_WIDTH, 1),
			BackgroundColor3 = function()
				return if tab() == categoryId then Theme.ui.action else Theme.ui.panelRaised
			end,
			BorderSizePixel = 0,
			create("UISizeConstraint")({ MinSize = Theme.touchMinSize }),
			create("UICorner")({ CornerRadius = Theme.corner }),
			Activated = function()
				tab(categoryId)
			end,
			Kit.text({
				Size = UDim2.fromScale(0.9, 0.6),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				FontFace = Theme.font.number,
				Text = Strings.get(nameKey),
				maxSize = 20,
			}),
		}) :: TextButton
	end

	local function cardButton(categoryId: string, card: Card): TextButton
		local function isSelected(): boolean
			if categoryId == SKINS then
				return skinSelected() == card.id
			end
			return mockSelected()[categoryId] == card.id
		end
		local look = card.look
		return create("TextButton")({
			Name = "Card_" .. card.id,
			Text = "",
			AutoButtonColor = true,
			BackgroundColor3 = function()
				return if isSelected() then Theme.ui.action else Theme.ui.panelRaised
			end,
			BorderSizePixel = 0,
			create("UICorner")({ CornerRadius = Theme.corner }),
			Activated = function()
				if look ~= nil then
					skinSelected(card.id) -- o efeito da prévia aplica a cor
				else
					local all = table.clone(mockSelected())
					all[categoryId] = card.id
					mockSelected(all)
				end
			end,
			-- Skins reais mostram a cor do corpo e do contorno; as falsas, um quadrado neutro.
			create("Frame")({
				Name = "Swatch",
				Position = UDim2.fromScale(0.5, 0.36),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromScale(0.34, 0.4),
				BackgroundColor3 = if look then Theme.color(look.bodyColor) else Theme.ui.border,
				BorderSizePixel = 0,
				create("UICorner")({ CornerRadius = Theme.corner }),
				create("UIAspectRatioConstraint")({ AspectRatio = 1 }),
				create("UIStroke")({
					Color = if look then Theme.color(look.outlineColor) else Theme.ui.panel,
					Thickness = Theme.strokeThickness,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				}),
			}),
			Kit.text({
				Position = UDim2.fromScale(0.5, 0.82),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromScale(0.92, 0.26),
				FontFace = Theme.font.body,
				Text = Strings.get(card.nameKey),
				maxSize = 16,
			}),
		}) :: TextButton
	end

	-- Uma grade por categoria; só a da aba atual aparece.
	local function grid(categoryId: string, cards: { Card }): ScrollingFrame
		local children: { Instance } = {
			create("UIGridLayout")({
				SortOrder = Enum.SortOrder.LayoutOrder,
				CellSize = UDim2.fromScale(0.47, 0.3),
				CellPadding = UDim2.fromScale(0.03, 0.03),
			}) :: Instance,
		}
		for _, card in cards do
			table.insert(children, cardButton(categoryId, card))
		end
		return create("ScrollingFrame")({
			Name = "Grid_" .. categoryId,
			Visible = function()
				return tab() == categoryId
			end,
			Position = UDim2.new(PREVIEW_WIDTH + 0.02, 0, 0, TABS_ROW),
			Size = UDim2.new(1 - PREVIEW_WIDTH - 0.02, 0, 1, -TABS_ROW),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 6,
			CanvasSize = UDim2.fromScale(0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			children,
		}) :: ScrollingFrame
	end

	local tabs: { Instance } = {
		create("UIListLayout")({
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0.0125, 0),
		}) :: Instance,
	}
	local grids: { Instance } = {}
	for _, category in MockStore.CATEGORIES do
		table.insert(tabs, tabButton(category.id, category.nameKey))
		local cards: { Card } = skins
		if category.id ~= SKINS then
			cards = {}
			for _, item in category.items do
				table.insert(cards, { id = item.id, nameKey = item.nameKey, look = nil })
			end
		end
		table.insert(grids, grid(category.id, cards))
	end

	return create("Frame")({
		Name = "Cosmetics",
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.02, 0.15),
		Size = UDim2.fromScale(0.96, 0.82),
		create("Frame")({
			Name = "Tabs",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, Theme.touchMinSize.Y),
			tabs,
		}),
		create("Frame")({
			Name = "PreviewBox",
			Position = UDim2.fromOffset(0, TABS_ROW),
			Size = UDim2.new(PREVIEW_WIDTH, 0, 1, -TABS_ROW),
			BackgroundColor3 = Theme.ui.panelRaised,
			BorderSizePixel = 0,
			create("UICorner")({ CornerRadius = Theme.corner }),
			viewport,
			Kit.text({
				Name = "ItemName",
				Position = UDim2.fromScale(0.5, 0.93),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromScale(0.9, 0.1),
				FontFace = Theme.font.number,
				Text = selectedName,
				maxSize = 22,
			}),
		}),
		grids,
	}) :: Frame
end

return CosmeticsPanel
