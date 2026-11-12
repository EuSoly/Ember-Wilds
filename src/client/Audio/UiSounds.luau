--!strict
-- Clique da interface: todo botão (GuiButton) do PlayerGui ganha o som sozinho,
-- sem cada tela precisar lembrar. O som sai do nome do botão
-- (SoundRules.uiKey): slot do inventário, aba ou botão comum. Botão novo já
-- nasce com clique; para um som diferente, dê o nome certo ou ajuste a regra.
-- Um botão com o atributo "SemSom" = true fica mudo (ex.: áreas invisíveis).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SoundRules = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Audio"):WaitForChild("SoundRules"))
local SoundPlayer = require(script.Parent:WaitForChild("SoundPlayer"))

local MUTE_ATTRIBUTE = "SemSom"

local UiSounds = {}

local started = false

local function hook(instance: Instance)
	if not instance:IsA("GuiButton") then
		return
	end
	instance.Activated:Connect(function()
		if instance:GetAttribute(MUTE_ATTRIBUTE) ~= true then
			SoundPlayer.play(SoundRules.uiKey(instance.Name))
		end
	end)
end

-- Liga os cliques (chamado uma vez pelo AudioController).
function UiSounds.start()
	if started then
		return
	end
	started = true
	task.spawn(function()
		local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
		playerGui.DescendantAdded:Connect(hook)
		for _, descendant in playerGui:GetDescendants() do
			hook(descendant)
		end
	end)
end

return UiSounds
