--!strict
-- Bordas da tela quando o jogador sofre: clarão vermelho no golpe (a vida
-- caiu), gelo com o frio acabando, laranja com o calor alto, e uma cor para a
-- fome, a sede e o fôlego baixos. Quanto e quando aparece vem de
-- UIFlow/ScreenFx; aqui só pinta. Zerada (machucando), a borda pulsa.
--
-- Fica num ScreenGui próprio, atrás do HUD e cobrindo a tela toda (inclusive
-- embaixo da barra do Roblox). Sem arte (HudImages.FX vazio), cada borda é
-- feita de quatro faixas em degradê; com a arte, a imagem cobre a tela.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local HudImages = require(Shared:WaitForChild("HudImages"))
local Palette = require(Shared:WaitForChild("Palette"))
local ScreenFx = require(Shared:WaitForChild("UIFlow"):WaitForChild("ScreenFx"))
local ScreenFlow = require(Shared:WaitForChild("UIFlow"):WaitForChild("ScreenFlow"))
local StatNames = require(Shared:WaitForChild("StatNames"))
local Theme = require(Shared:WaitForChild("Theme"))
local ScreenState = require(script.Parent.Parent:WaitForChild("ScreenState"))

local create = vide.create

local EDGE_Y = 0.22 -- altura das faixas de cima e de baixo (fração da tela)
local EDGE_X = 0.16 -- largura das faixas dos lados
local PULSE_SPEED = 5 -- radianos por segundo do pulso (barra zerada)

-- "damage", "cold", "heat", "hunger", "thirst" ou "oxygen".
type Kind = string
type Strength = (number?) -> number -- fonte do vide: s() lê, s(x) escreve

-- Cor e opacidade máxima de cada efeito (na borda, efeito cheio).
local LOOK: { [Kind]: { color: Color3, alpha: number } } = {
	damage = { color = Theme.color(Palette.status.health), alpha = 0.55 },
	cold = { color = Color3.fromRGB(200, 232, 255), alpha = 0.6 }, -- gelo: mais claro que o azul do anel
	heat = { color = Theme.color(Palette.status.heat), alpha = 0.5 },
	hunger = { color = Color3.fromRGB(122, 62, 16), alpha = 0.45 }, -- marrom: não confunde com o calor
	thirst = { color = Theme.color(Palette.status.thirst), alpha = 0.4 },
	oxygen = { color = Color3.fromRGB(11, 37, 69), alpha = 0.6 }, -- azul-escuro: a vista escurece
}
local ORDER: { Kind } = { "hunger", "thirst", "oxygen", "cold", "heat", "damage" } -- o golpe por cima

-- Opaco na borda da tela, some para dentro.
local FADE = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(0.45, 0.6),
	NumberSequenceKeypoint.new(1, 1),
})

local function edge(name: string, color: Color3, position: UDim2, size: UDim2, rotation: number): Frame
	return create("Frame")({
		Name = name,
		Position = position,
		Size = size,
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		create("UIGradient")({ Transparency = FADE, Rotation = rotation }),
	}) :: Frame
end

-- Uma camada (um efeito): `strength` 0 a 1.
local function layer(kind: Kind, strength: () -> number): GuiObject
	local look = LOOK[kind]
	local image = HudImages.FX[kind]
	if HudImages.has(image) then
		return create("ImageLabel")({
			Name = kind,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Image = image,
			ScaleType = Enum.ScaleType.Stretch,
			ImageTransparency = function()
				return 1 - strength()
			end,
			Visible = function()
				return strength() > 0
			end,
		}) :: ImageLabel
	end
	local edges = {
		edge("Top", look.color, UDim2.fromScale(0, 0), UDim2.fromScale(1, EDGE_Y), 90),
		edge("Bottom", look.color, UDim2.fromScale(0, 1 - EDGE_Y), UDim2.fromScale(1, EDGE_Y), -90),
		edge("Left", look.color, UDim2.fromScale(0, 0), UDim2.fromScale(EDGE_X, 1), 0),
		edge("Right", look.color, UDim2.fromScale(1 - EDGE_X, 0), UDim2.fromScale(EDGE_X, 1), 180),
	}
	-- A transparência da faixa multiplica a do degradê: a força vira opacidade.
	vide.effect(function()
		local transparency = 1 - strength() * look.alpha
		for _, frame in edges do
			frame.BackgroundTransparency = transparency
		end
	end)
	return create("Frame")({
		Name = kind,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Visible = function()
			return strength() > 0
		end,
		edges,
	}) :: Frame
end

local function number(player: Player, name: string, default: number): number
	local value = player:GetAttribute(name)
	return if type(value) == "number" then value else default
end

local function StatusVignette(): ScreenGui
	local player = Players.LocalPlayer
	local strengths: { [Kind]: Strength } = {}
	for _, kind in ORDER do
		strengths[kind] = vide.source(0) :: any
	end

	local lastHealth: number? = nil
	local hitAt = -math.huge
	local connection = RunService.RenderStepped:Connect(function()
		local now = os.clock()
		local health = number(player, StatNames.Health, StatNames.HealthMax)
		if ScreenFx.hit(lastHealth, health) then
			hitAt = now
		end
		lastHealth = health
		local levels = ScreenFx.levels({
			hunger = number(player, StatNames.Hunger, StatNames.StatusMax),
			cold = number(player, StatNames.Cold, StatNames.StatusMax),
			heat = number(player, StatNames.Heat, 0),
			thirst = number(player, StatNames.Thirst, StatNames.StatusMax),
			oxygen = number(player, StatNames.Oxygen, StatNames.StatusMax),
		})
		-- Zerada: pulsa entre 70% e 100%.
		local pulse = 0.85 + 0.15 * math.sin(now * PULSE_SPEED)
		for kind, level in levels :: { [string]: number } do
			strengths[kind](if level >= 1 then pulse else level)
		end
		strengths["damage"](ScreenFx.flash(now - hitAt))
	end)
	vide.cleanup(function()
		connection:Disconnect()
	end)

	local layers = {}
	for _, kind in ORDER do
		table.insert(layers, layer(kind, strengths[kind]))
	end
	return create("ScreenGui")({
		Name = "StatusVignette",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ScreenInsets = Enum.ScreenInsets.None,
		DisplayOrder = -1, -- atrás do HUD
		Enabled = function()
			return ScreenFlow.hudVisible(ScreenState.current())
		end,
		layers,
	}) :: ScreenGui
end

return StatusVignette
