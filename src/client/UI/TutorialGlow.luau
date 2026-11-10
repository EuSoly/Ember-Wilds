--!strict
-- Destaque do tutorial: borda dourada pulsando por cima de um botão (receita na
-- coluna, botão do livro, aba, item da grade), visível só quando `active()`.
-- É o mesmo em todo lugar, para o jogador reconhecer o "clique aqui". Vai como
-- filho do botão: TutorialGlow(function() return ... end).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Theme = require(Shared:WaitForChild("Theme"))

local create = vide.create

local PULSE_SPEED = 5 -- rad/s
local THICKNESS = 4

-- Um relógio só para todos os destaques (uma conexão, não uma por botão).
local clock = vide.source(0)
RunService.RenderStepped:Connect(function()
	clock(os.clock())
end)

-- `corner` = arredondado da borda (padrão: cantos de slot; UDim.new(1, 0) = redondo).
local function TutorialGlow(active: () -> boolean, corner: UDim?): Frame
	return create("Frame")({
		Name = "TutorialGlow",
		Visible = active,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 10,
		create("UICorner")({ CornerRadius = corner or UDim.new(0.15, 0) }),
		create("UIStroke")({
			Color = Theme.rustic.emberLight,
			Thickness = THICKNESS,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Transparency = function()
				if not active() then
					return 1
				end
				return 0.1 + 0.5 * (0.5 + 0.5 * math.sin(clock() * PULSE_SPEED))
			end,
		}),
	}) :: Frame
end

return TutorialGlow
