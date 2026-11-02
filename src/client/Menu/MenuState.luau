--!strict
-- Estado do menu: qual painel está aberto ao lado da coluna de botões.
-- "play" é o menu de sempre (molde MainMenu); os outros são os painéis do
-- mockup (MenuShell). Volta para "play" sempre que o jogador sai do menu.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))

export type Panel = "play" | "profile" | "cosmetics" | "shop" | "buy" | "tutorial" | "ranking"

-- Fonte Vide: chamar sem argumento lê, com argumento escreve (tipo escrito
-- aqui porque sem ele o vide.source alarga "play" para string).
type Source<T> = (() -> T) & ((T) -> T)

local MenuState = {}

local panel: Source<Panel> = vide.source("play" :: Panel) :: any
MenuState.panel = panel

-- Abre um painel (escrever pela fonte direto confunde o tipo nas chamadas).
function MenuState.open(target: Panel)
	panel(target)
end

return MenuState
