--!strict
-- Conteúdo do painel Loja (mockup G7a): giros de skin e de visual, kit inicial
-- e a tela de detalhe de um giro (tabela de chances + animação de sorteio).
-- Nada é cobrado nem gravado: comprar só mostra o aviso de compra simulada.
-- Uma animação por vez; sair da loja ou voltar cancela por um token de geração.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local MockStore = require(Shared:WaitForChild("UIFlow"):WaitForChild("MockStore"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local Client = script.Parent.Parent
local ScreenState = require(Client:WaitForChild("ScreenState"))
local Kit = require(Client:WaitForChild("UI"):WaitForChild("Kit"))
local MenuState = require(script.Parent:WaitForChild("MenuState"))

local create = vide.create

-- A lista rola: a altura do canvas é CANVAS_H "janelas"; as posições abaixo
-- estão em janelas e viram escala do canvas em `applyRect`.
local CANVAS_H = 2.1
local SPIN_SECONDS = 1.5
local FIRST_DELAY = 0.08
local SLOWDOWN = 1.15

local function applyRect(props: { [any]: any }, x: number, y: number, w: number, h: number): { [any]: any }
	props.Position = UDim2.fromScale(x, y / CANVAS_H)
	props.Size = UDim2.fromScale(w, h / CANVAS_H)
	return props
end

local function sectionTitle(textKey: string, y: number): TextLabel
	return Kit.text(applyRect({
		FontFace = Theme.font.title,
		Text = Strings.get(textKey),
		TextXAlignment = Enum.TextXAlignment.Left,
		maxSize = 26,
	}, 0, y, 1, 0.12))
end

-- Botão de ação com texto; `enabled` (opcional) escurece e ignora o toque.
local function actionButton(props: { [any]: any }, text: string, onClick: () -> (), enabled: (() -> boolean)?): any
	props.Text = ""
	props.AutoButtonColor = true
	props.BackgroundColor3 = function()
		return if enabled == nil or enabled() then Theme.ui.action else Theme.ui.panelRaised
	end
	props.BorderSizePixel = 0
	props.Activated = function()
		if enabled == nil or enabled() then
			onClick()
		end
	end
	table.insert(props, create("UISizeConstraint")({ MinSize = Theme.touchMinSize }))
	table.insert(props, create("UICorner")({ CornerRadius = Theme.corner }))
	table.insert(
		props,
		Kit.text({
			Size = UDim2.fromScale(0.9, 0.6),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			FontFace = Theme.font.number,
			Text = text,
			maxSize = 20,
		})
	)
	return create("TextButton")(props)
end

local ShopPanel = {}

function ShopPanel.build(): Frame
	local selected = vide.source(nil :: string?)
	local spinning = vide.source(false)
	local display = vide.source("")

	-- Token da animação: qualquer mudança invalida o laço em andamento.
	local generation = 0
	local function cancelSpin()
		generation += 1
		spinning(false)
		display("")
	end

	-- Fechar a loja, trocar de painel ou sair do menu volta à lista, sem giro.
	vide.effect(function()
		local open = MenuState.panel() == "shop" and ScreenState.current() == "menu"
		if not open then
			cancelSpin()
			selected(nil)
		end
	end)

	local function startSpin(spin: MockStore.Spin)
		if spinning() then
			return
		end
		MenuState.notify(Strings.get("mock.simulated"))
		generation += 1
		local mine = generation
		spinning(true)
		display("")
		task.spawn(function()
			local delay = FIRST_DELAY
			local elapsed = 0
			local index = 0
			while elapsed < SPIN_SECONDS do
				index += 1
				display(Strings.get(spin.odds[(index - 1) % #spin.odds + 1].nameKey))
				task.wait(delay)
				if mine ~= generation then
					return
				end
				elapsed += delay
				delay *= SLOWDOWN
			end
			local prize = spin.odds[MockStore.roll(spin.odds, math.random())]
			display(Strings.format("mock.spin.result", { prize = Strings.get(prize.nameKey) }))
			spinning(false)
		end)
	end

	local function spinCard(spin: MockStore.Spin, x: number, y: number): TextButton
		return create("TextButton")(applyRect({
			Name = "Spin_" .. spin.id,
			Text = "",
			AutoButtonColor = true,
			BackgroundColor3 = Theme.ui.panelRaised,
			BorderSizePixel = 0,
			Activated = function()
				selected(spin.id)
			end,
			create("UICorner")({ CornerRadius = Theme.corner }),
			Kit.text({
				Position = UDim2.fromScale(0.5, 0.32),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromScale(0.9, 0.42),
				FontFace = Theme.font.number,
				Text = Strings.get(spin.nameKey),
				maxSize = 20,
			}),
			Kit.text({
				Position = UDim2.fromScale(0.5, 0.78),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromScale(0.9, 0.26),
				FontFace = Theme.font.body,
				Text = Strings.format("mock.price", { price = spin.price }),
				maxSize = 16,
			}),
		}, x, y, 0.31, 0.42)) :: TextButton
	end

	local list: { Instance } = {}
	local counts: { [string]: number } = {}
	for _, spin in MockStore.SPINS do
		local n = counts[spin.kind] or 0
		counts[spin.kind] = n + 1
		local rowY = if spin.kind == "skin" then 0.13 else 0.75
		table.insert(list, spinCard(spin, n * 0.345, rowY))
	end
	table.insert(list, sectionTitle("mock.section.skin", 0))
	table.insert(list, sectionTitle("mock.section.custom", 0.62))
	table.insert(list, sectionTitle("mock.section.kit", 1.24))
	for i, key in MockStore.KIT.items do
		table.insert(
			list,
			Kit.text(applyRect({
				Name = "KitItem" .. i,
				FontFace = Theme.font.body,
				Text = Strings.get(key),
				TextXAlignment = Enum.TextXAlignment.Left,
				maxSize = 20,
			}, 0.02, 1.37 + (i - 1) * 0.16, 0.9, 0.14))
		)
	end
	for i, offer in MockStore.KIT.offers do
		table.insert(
			list,
			actionButton(
				applyRect({ Name = "Offer" .. i }, (i - 1) * 0.5, 1.74, 0.48, 0.26),
				Strings.format("mock.offer", { hours = offer.hours, price = offer.price }),
				function()
					MenuState.notify(Strings.get("mock.simulated"))
				end
			)
		)
	end

	local listFrame = create("ScrollingFrame")({
		Name = "List",
		Visible = function()
			return selected() == nil
		end,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		CanvasSize = UDim2.fromScale(0, CANVAS_H),
		ScrollingDirection = Enum.ScrollingDirection.Y,
		list,
	}) :: ScrollingFrame

	-- Um detalhe por giro; só o do giro escolhido aparece.
	local function detail(spin: MockStore.Spin): Frame
		local rows: { Instance } = {
			create("UIListLayout")({ SortOrder = Enum.SortOrder.LayoutOrder }) :: Instance,
		}
		for _, odd in spin.odds do
			table.insert(
				rows,
				create("Frame")({
					Size = UDim2.fromScale(1, 1 / #spin.odds),
					BackgroundTransparency = 1,
					Kit.text({
						Size = UDim2.fromScale(0.6, 0.8),
						Position = UDim2.fromScale(0.03, 0.5),
						AnchorPoint = Vector2.new(0, 0.5),
						FontFace = Theme.font.body,
						Text = Strings.get(odd.nameKey),
						TextXAlignment = Enum.TextXAlignment.Left,
						maxSize = 20,
					}),
					Kit.text({
						Size = UDim2.fromScale(0.3, 0.8),
						Position = UDim2.fromScale(0.97, 0.5),
						AnchorPoint = Vector2.new(1, 0.5),
						FontFace = Theme.font.number,
						Text = Strings.format("mock.chance", { percent = math.floor(odd.chance * 100 + 0.5) }),
						TextXAlignment = Enum.TextXAlignment.Right,
						maxSize = 20,
					}),
				})
			)
		end
		return create("Frame")({
			Name = "Detail_" .. spin.id,
			Visible = function()
				return selected() == spin.id
			end,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Kit.text({
				Name = "SpinName",
				Size = UDim2.fromScale(1, 0.12),
				FontFace = Theme.font.title,
				Text = Strings.get(spin.nameKey),
				TextXAlignment = Enum.TextXAlignment.Left,
				maxSize = 28,
			}),
			create("Frame")({
				Name = "Odds",
				Position = UDim2.fromScale(0, 0.14),
				Size = UDim2.fromScale(1, 0.44),
				BackgroundColor3 = Theme.ui.panelRaised,
				BorderSizePixel = 0,
				create("UICorner")({ CornerRadius = Theme.corner }),
				rows,
			}),
			Kit.text({
				Name = "Result",
				Position = UDim2.fromScale(0.5, 0.7),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromScale(0.9, 0.14),
				FontFace = Theme.font.number,
				Text = display,
				maxSize = 26,
			}),
			actionButton(
				{
					Name = "Spin",
					Position = UDim2.fromScale(0.02, 0.84),
					Size = UDim2.fromScale(0.46, 0.16),
				},
				Strings.get("mock.spin.go"),
				function()
					startSpin(spin)
				end,
				function()
					return not spinning()
				end
			),
			actionButton(
				{
					Name = "Back",
					Position = UDim2.fromScale(0.52, 0.84),
					Size = UDim2.fromScale(0.46, 0.16),
				},
				Strings.get("mock.spin.back"),
				function()
					cancelSpin()
					selected(nil)
				end
			),
		}) :: Frame
	end

	local children: { Instance } = { listFrame }
	for _, spin in MockStore.SPINS do
		table.insert(children, detail(spin))
	end
	return create("Frame")({
		Name = "Shop",
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.02, 0.15),
		Size = UDim2.fromScale(0.96, 0.82),
		children,
	}) :: Frame
end

return ShopPanel
