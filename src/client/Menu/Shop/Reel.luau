--!strict
-- Carrossel de skins da tela do giro (estilo CS:GO).
-- Parado, ele anda devagar para a esquerda mostrando o que pode sair (pesos
-- de vitrine) e vai trocando os quadradinhos que saem da tela. Ao girar,
-- acrescenta quadradinhos com o prêmio lá na frente e desliza até o prêmio
-- parar embaixo do marcador, freando forte no fim.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MockStore = require(Shared:WaitForChild("UIFlow"):WaitForChild("MockStore"))
local SpinRules = require(Shared:WaitForChild("UIFlow"):WaitForChild("SpinRules"))
local SpinTile = require(script.Parent:WaitForChild("SpinTile"))

local IDLE_SPEED = 40 -- px lógicos por segundo
local SPIN_SECONDS = 5.2
local SPIN_INFO = TweenInfo.new(SPIN_SECONDS, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local START_TILES = 14
local EXTRA_TILES = 40 -- acrescentados ao girar
local PRIZE_AHEAD = 34 -- o prêmio fica tantos quadradinhos à frente
local JITTER = 0.35 -- o prêmio pode parar até 35% de um quadradinho fora do centro

-- Chamado a cada quadro do giro: `progress` 0..1 do tempo e o número do
-- quadradinho embaixo do marcador (muda quando um passa — hora do tique).
export type OnFrame = (progress: number, tile: number) -> ()

export type Reel = {
	idle: (self: Reel) -> (),
	spinTo: (self: Reel, prize: MockStore.SpinItem, onDone: () -> (), onFrame: OnFrame?) -> (),
	destroy: (self: Reel) -> (),
}

local Reel = {}

-- Escala da interface (UIScale do ScreenGui): AbsoluteSize vem em pixels de
-- tela, e as posições aqui dentro são em pixels lógicos.
local function uiScale(instance: Instance): number
	local gui = instance:FindFirstAncestorOfClass("ScreenGui")
	local scale = gui and gui:FindFirstChildOfClass("UIScale")
	return if scale and scale.Scale > 0 then scale.Scale else 1
end

-- `window` é a janela (com ClipsDescendants); `tileSize` em px lógicos.
function Reel.new(window: GuiObject, spinType: MockStore.SpinType, tileSize: number, gap: number): Reel
	local rng = Random.new()
	local step = tileSize + gap
	local strip = Instance.new("Frame")
	strip.Name = "Strip"
	strip.BackgroundTransparency = 1
	strip.Size = UDim2.fromOffset(0, tileSize)
	strip.AutomaticSize = Enum.AutomaticSize.X
	strip.AnchorPoint = Vector2.new(0, 0.5)
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.Padding = UDim.new(0, gap)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = strip
	strip.Parent = window

	local tiles: { GuiObject } = {}
	local order = 0
	local offset = 0
	local mode: string = "idle" -- "idle" (andando devagar), "spinning" ou "stopped"
	local tween: Tween? = nil
	local connection: RBXScriptConnection? = nil
	local frameCallback: OnFrame? = nil
	local spinStarted = 0
	local spinWindow = 0 -- largura da janela (px lógicos) no começo do giro

	local function showcaseItem(): MockStore.SpinItem
		local rarity = SpinRules.pickIndex(MockStore.SHOWCASE_WEIGHTS, rng:NextNumber())
		return SpinRules.pickItem(spinType.items, rarity, rng:NextNumber())
	end

	local function push(item: MockStore.SpinItem)
		order += 1
		local tile = SpinTile.build(item, spinType.id, tileSize)
		tile.LayoutOrder = order
		tile.Parent = strip
		table.insert(tiles, tile)
	end

	local function place()
		strip.Position = UDim2.new(0, offset, 0.5, 0)
	end

	for _ = 1, START_TILES do
		push(showcaseItem())
	end
	place()

	-- Anda devagar; o quadradinho que sai pela esquerda vai para o fim.
	connection = RunService.RenderStepped:Connect(function(dt)
		if mode == "spinning" then
			local callback = frameCallback
			if callback then
				local progress = math.min((os.clock() - spinStarted) / SPIN_SECONDS, 1)
				callback(progress, SpinRules.markerTile(strip.Position.X.Offset, step, spinWindow))
			end
			return
		end
		if mode ~= "idle" then
			return
		end
		offset -= IDLE_SPEED * dt
		while -offset > step and #tiles > 0 do
			local gone = table.remove(tiles, 1)
			if gone then
				gone:Destroy()
			end
			push(showcaseItem())
			offset += step
		end
		place()
	end)

	local self = {} :: Reel

	-- Volta a andar devagar (depois de fechar a janelinha do prêmio).
	function self.idle(_: Reel)
		mode = "idle"
	end

	function self.spinTo(_: Reel, prize: MockStore.SpinItem, onDone: () -> (), onFrame: OnFrame?)
		if mode == "spinning" then
			return
		end
		mode = "spinning"
		frameCallback = onFrame
		spinStarted = os.clock()
		local prizeIndex = #tiles + PRIZE_AHEAD
		for _ = 1, EXTRA_TILES do
			push(if #tiles + 1 == prizeIndex then prize else showcaseItem())
		end
		local windowWidth = window.AbsoluteSize.X / uiScale(window)
		spinWindow = windowWidth
		local jitter = (rng:NextNumber() - 0.5) * 2 * JITTER * tileSize
		local target = -((prizeIndex - 1) * step + tileSize / 2 - windowWidth / 2 + jitter)
		tween = TweenService:Create(strip, SPIN_INFO, { Position = UDim2.new(0, target, 0.5, 0) })
		local current = tween :: Tween
		current.Completed:Once(function(state)
			if state ~= Enum.PlaybackState.Completed or mode ~= "spinning" then
				return
			end
			offset = target
			-- Tira os quadradinhos que ficaram para trás (mantém a mesma posição na tela).
			while #tiles > 0 and -offset > step * 2 do
				local gone = table.remove(tiles, 1)
				if gone then
					gone:Destroy()
				end
				offset += step
			end
			place()
			mode = "stopped"
			frameCallback = nil
			onDone()
		end)
		current:Play()
	end

	function self.destroy(_: Reel)
		mode = "stopped"
		frameCallback = nil
		if tween then
			tween:Cancel()
		end
		if connection then
			connection:Disconnect()
		end
		strip:Destroy()
	end

	return self
end

return Reel
