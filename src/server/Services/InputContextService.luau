--!strict
-- Cria o InputContext de gameplay de cada jogador.
--
-- Com Server Authority, todo input que muda a simulação precisa vir de uma
-- InputAction, e o InputContext tem de estar dentro do Player. O servidor cria
-- a estrutura; o cliente só alimenta os valores.
--
-- Por enquanto só existe a mira (Aim). Os botões de ação, construir, mochila e
-- hotbar entram na Fase 2, neste mesmo contexto.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InputNames = require(ReplicatedStorage.Shared.InputNames)

local InputContextService = {}

local function createContext(player: Player)
	if player:FindFirstChild(InputNames.Context) then
		return
	end

	local context = Instance.new("InputContext")
	context.Name = InputNames.Context

	-- Mira: vetor (x, z) do personagem até o ponto mirado. Zero = sem mira
	-- (celular/gamepad), e aí o personagem vira para onde anda.
	local aim = Instance.new("InputAction")
	aim.Name = InputNames.Aim
	aim.Type = Enum.InputActionType.Direction2D
	aim.Parent = context

	-- Binding "Scriptable": não vem de tecla nenhuma; o AimController do cliente
	-- calcula a direção do mouse e chama AimBinding:Fire(Vector2).
	local binding = Instance.new("InputBinding")
	binding.Name = InputNames.AimBinding
	binding.Type = Enum.InputBindingType.Scriptable
	binding.Parent = aim

	context.Parent = player
end

function InputContextService.Start(_self)
	Players.PlayerAdded:Connect(createContext)
	for _, player in Players:GetPlayers() do
		createContext(player)
	end
end

return InputContextService
