--!strict
-- Raiz do HUD: o ScreenGui onde todos os componentes do jogo são montados.
-- Para adicionar um componente ao HUD, crie o arquivo em UI/ e coloque-o na
-- lista de filhos abaixo.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))

local create = vide.create

local function App(): ScreenGui
	return create("ScreenGui")({
		Name = "Hud",
		ResetOnSpawn = false, -- o HUD sobrevive ao respawn
		IgnoreGuiInset = false,
		-- Desvia da barra superior do Roblox e do notch do celular.
		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}) :: ScreenGui
end

return App
