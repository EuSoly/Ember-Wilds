--!strict
-- Slots da fornalha e dos extratores, dentro do painel de interação (11/11:
-- antes eram um texto "Madeira: 0" e botões lisos). Como o baú: slots de couro
-- com o ícone e a quantidade.
-- - Extrator: [madeira] ▓▓░░ [minério]. Clicar na madeira põe até 10
--   (MachineRules.WOOD_PER_PUT); clicar no minério pega o estoque (só o dono e
--   o time: para os outros o slot fica apagado). A barrinha mostra o ciclo.
-- - Fornalha: [madeira] ▓▓░░. A barrinha mostra quanto falta para queimar a
--   madeira da vez.
-- O cliente só vê os atributos Wood e Stock: a barrinha é uma estimativa
-- (MachineRules.cycleRestarted / cycleFraction), sem nada a mais pela rede.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local BuildRules = require(Shared:WaitForChild("Build"):WaitForChild("BuildRules"))
local Defs = require(Shared:WaitForChild("Defs"))
local InteractRules = require(Shared:WaitForChild("Build"):WaitForChild("InteractRules"))
local MachineRules = require(Shared:WaitForChild("Build"):WaitForChild("MachineRules"))
local StatNames = require(Shared:WaitForChild("StatNames"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local InteractState = require(script.Parent.Parent:WaitForChild("InteractState"))
local HudArt = require(script.Parent:WaitForChild("HudArt"))
local ItemIcon = require(script.Parent:WaitForChild("ItemIcon"))
local Kit = require(script.Parent:WaitForChild("Kit"))

local create = vide.create

local SLOT = 64 -- px (como o baú)
local GAP = 8
local BAR = Vector2.new(96, 12)
local CAPTION_HEIGHT = 16
local REFRESH = 0.1 -- segundos entre atualizações da barrinha
local DIM = 0.6 -- transparência do ícone apagado (vazio ou sem permissão)

local MachineSlots = {}

-- O tipo da peça perto é uma das máquinas deste painel?
function MachineSlots.handles(kind: string?): boolean
	return kind == "extractor" or kind == "furnace"
end

-- Um slot de couro com o ícone de `itemId`, a quantidade sempre visível (até o
-- 0) e a legenda embaixo. `dim` apaga o ícone; `onClick` = ação do slot.
local function MachineSlot(props: {
	name: string,
	itemId: () -> string,
	count: () -> number,
	caption: () -> string,
	dim: () -> boolean,
	onClick: () -> (),
}): Frame
	return create("Frame")({
		Name = props.name,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(SLOT, SLOT + CAPTION_HEIGHT + 2),
		create("TextButton")({
			Name = "Slot",
			Size = UDim2.fromOffset(SLOT, SLOT),
			Text = "",
			AutoButtonColor = false,
			BackgroundColor3 = Theme.ui.panel,
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
			Activated = props.onClick,
			-- O ícone sem a quantidade dele (count 1): a nossa vai embaixo, até o 0.
			(function()
				local item = function()
					return { id = props.itemId(), count = 1 }
				end
				local icon = if HudArt.HAS_SLOT
					then HudArt.inSlot(ItemIcon({ item = item, bare = true }))
					else ItemIcon({ item = item })
				return create("CanvasGroup")({
					Name = "Icon",
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, 1),
					GroupTransparency = function()
						return if props.dim() then DIM else 0
					end,
					icon,
				})
			end)(),
			Kit.text({
				Name = "Count",
				AnchorPoint = Vector2.new(1, 1),
				Position = UDim2.new(1, -8, 1, -6),
				Size = UDim2.fromOffset(SLOT - 16, 18),
				FontFace = Theme.font.number,
				TextXAlignment = Enum.TextXAlignment.Right,
				Text = function()
					return tostring(props.count())
				end,
				maxSize = 16,
				ZIndex = 3,
			}),
		}),
		Kit.text({
			Name = "Caption",
			Position = UDim2.fromOffset(0, SLOT + 2),
			Size = UDim2.fromOffset(SLOT, CAPTION_HEIGHT),
			FontFace = Theme.font.number,
			Text = props.caption,
			maxSize = 13,
		}),
	}) :: Frame
end

-- Barrinha de andamento (0 a 1) com a legenda do estado embaixo.
local function ProgressBar(fraction: () -> number, color: () -> Color3, caption: () -> string): Frame
	return create("Frame")({
		Name = "Progress",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(BAR.X, SLOT + CAPTION_HEIGHT + 2),
		create("Frame")({
			Name = "Track",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromOffset(0, SLOT / 2),
			Size = UDim2.fromOffset(BAR.X, BAR.Y),
			BackgroundColor3 = Color3.fromRGB(40, 26, 16),
			BackgroundTransparency = 0.2,
			BorderSizePixel = 0,
			create("UICorner")({ CornerRadius = UDim.new(0.5, 0) }),
			create("UIStroke")({ Color = Theme.ui.border, Thickness = 1 }),
			create("Frame")({
				Name = "Fill",
				Size = function()
					return UDim2.fromScale(fraction(), 1)
				end,
				BackgroundColor3 = color,
				BorderSizePixel = 0,
				create("UICorner")({ CornerRadius = UDim.new(0.5, 0) }),
			}),
		}),
		Kit.text({
			Name = "Caption",
			AnchorPoint = Vector2.new(0, 0),
			Position = UDim2.fromOffset(0, SLOT / 2 + BAR.Y),
			Size = UDim2.fromOffset(BAR.X, CAPTION_HEIGHT),
			FontFace = Theme.font.number,
			Text = caption,
			maxSize = 13,
		}),
	}) :: Frame
end

function MachineSlots.new(): Frame
	local function model(): Model?
		return InteractState.near()
	end
	local function def(): Defs.ItemDef?
		local current = model()
		return if current then InteractState.itemOf(current) else nil
	end
	local function kind(): string?
		local current = def()
		return if current and current.structure then current.structure.kind else nil
	end
	local function extractor(): MachineRules.ExtractorDef?
		local current = def()
		return if current and current.structure then current.structure.extractor else nil
	end
	local function wood(): number
		return InteractState.status().wood or 0
	end
	local function stock(): number
		return InteractState.status().stock or 0
	end
	local function working(): boolean
		local ex = extractor()
		if ex then
			return MachineRules.isWorking({ wood = wood(), stock = stock(), timer = 0 }, ex)
		end
		return wood() > 0
	end
	-- Dono ou time: o servidor confere de novo; isto só decide o que mostrar.
	local function canTake(): boolean
		local current = model()
		local owner = current and current:GetAttribute(StatNames.Owner)
		local isOwner = type(owner) == "number" and BuildRules.areAllies(owner, Players.LocalPlayer.UserId)
		return InteractRules.allowed("extractor", InteractRules.ACTIONS.take, isOwner)
	end

	-- Estimativa do ciclo: recomeça pelas mudanças de Wood/Stock.
	local fraction = vide.source(0)
	local lastModel: Model? = nil
	local seen: MachineRules.Seen = { wood = 0, stock = 0 }
	local wasWorking = false
	local since = os.clock()
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt: number)
		elapsed += dt
		if elapsed < REFRESH then
			return
		end
		elapsed = 0
		local current = vide.untrack(model)
		local currentKind = vide.untrack(kind)
		if current == nil or not MachineSlots.handles(currentKind) then
			lastModel = nil
			return
		end
		local now = os.clock()
		local after: MachineRules.Seen = { wood = vide.untrack(wood), stock = vide.untrack(stock) }
		local isWorking = vide.untrack(working)
		if current ~= lastModel then
			lastModel, since = current, now
		elseif MachineRules.cycleRestarted(currentKind :: string, seen, after, wasWorking, isWorking) then
			since = now
		end
		seen, wasWorking = after, isWorking
		local ex = vide.untrack(extractor)
		local d = vide.untrack(def)
		local furnace = d and d.structure and d.structure.furnace
		local cycle = if ex then ex.cycleSeconds elseif furnace then furnace.burnEvery else 0
		local done = if isWorking then MachineRules.cycleFraction(now - since, cycle) else 0
		-- Fornalha: quanto falta queimar da madeira da vez (cheia ao acender).
		fraction(if ex then done elseif isWorking then 1 - done else 0)
	end)

	local function barColor(): Color3
		local ex = extractor()
		local tier = ex and (Theme.tier :: any)[ex.output]
		return if typeof(tier) == "Color3" then tier else Theme.status.heat
	end
	local function barCaption(): string
		local ex = extractor()
		if ex then
			if stock() >= ex.maxStock then
				return Strings.get("machine.full")
			end
			return Strings.get(if working() then "machine.working" else "machine.no_wood")
		end
		return Strings.get(if working() then "machine.lit" else "machine.out")
	end

	return create("Frame")({
		Name = "MachineSlots",
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.fromOffset(0, 0),
		Visible = function()
			return MachineSlots.handles(kind())
		end,
		create("UIListLayout")({
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Top,
			Padding = UDim.new(0, GAP),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		(function()
			local slot = MachineSlot({
				name = "Wood",
				itemId = function()
					return MachineRules.FUEL
				end,
				count = wood,
				caption = function()
					return Strings.format("machine.put", { count = MachineRules.WOOD_PER_PUT })
				end,
				dim = function()
					return wood() <= 0
				end,
				onClick = function()
					InteractState.act(InteractRules.ACTIONS.put_wood)
				end,
			})
			slot.LayoutOrder = 1
			return slot
		end)(),
		(function()
			local bar = ProgressBar(fraction, barColor, barCaption)
			bar.LayoutOrder = 2
			return bar
		end)(),
		(function()
			local slot = MachineSlot({
				name = "Output",
				itemId = function()
					local ex = extractor()
					return if ex then ex.output else MachineRules.FUEL
				end,
				count = stock,
				caption = function()
					return Strings.get(if canTake() then "machine.take" else "machine.owner_only")
				end,
				dim = function()
					return stock() <= 0 or not canTake()
				end,
				onClick = function()
					if vide.untrack(canTake) then
						InteractState.act(InteractRules.ACTIONS.take)
					end
				end,
			})
			slot.LayoutOrder = 3
			slot.Visible = false
			return vide.apply(slot)({
				Visible = function()
					return extractor() ~= nil
				end,
			})
		end)(),
	}) :: Frame
end

return MachineSlots
