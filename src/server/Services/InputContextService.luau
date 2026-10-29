--!strict
-- Cria o InputContext de gameplay de cada jogador.
--
-- Com Server Authority, todo input que muda a simulação precisa vir de uma
-- InputAction, e o InputContext tem de estar dentro do Player. O servidor cria
-- a estrutura; o cliente só alimenta os valores.
--
-- Ações: mira (Aim) e seleção de slot (Slot1 … Slot10). Bater, mochila etc.
-- entram neste mesmo contexto.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InputNames = require(ReplicatedStorage.Shared.InputNames)

-- Tecla de cada slot da hotbar (1 … 9 e 0 para o décimo).
local SLOT_KEYS: { Enum.KeyCode } = {
	Enum.KeyCode.One,
	Enum.KeyCode.Two,
	Enum.KeyCode.Three,
	Enum.KeyCode.Four,
	Enum.KeyCode.Five,
	Enum.KeyCode.Six,
	Enum.KeyCode.Seven,
	Enum.KeyCode.Eight,
	Enum.KeyCode.Nine,
	Enum.KeyCode.Zero,
}

local InputContextService = {}

-- Ação de botão (Bool) com uma tecla.
local function keyAction(context: InputContext, name: string, key: Enum.KeyCode)
	local action = Instance.new("InputAction")
	action.Name = name
	action.Type = Enum.InputActionType.Bool
	local binding = Instance.new("InputBinding")
	binding.KeyCode = key
	binding.Parent = action
	action.Parent = context
end

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

	-- Seleção de slot da hotbar pelas teclas 1 … 0 (no celular, toque no slot).
	for index, name in InputNames.Slot do
		keyAction(context, name, SLOT_KEYS[index])
	end

	context.Parent = player
end

function InputContextService.Start(_self)
	Players.PlayerAdded:Connect(createContext)
	for _, player in Players:GetPlayers() do
		createContext(player)
	end
end

return InputContextService
