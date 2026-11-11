--!strict
-- Modo criativo do jogador local (atributo Creative do Player, escrito só pelo
-- CreativeService a partir do perfil). Só muda a tela: o servidor confere a
-- marca no perfil antes de entregar qualquer item. Atributo do PLAYER (não do
-- personagem previsto), então o sinal de atributo funciona aqui.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local StatNames = require(Shared:WaitForChild("StatNames"))

local player = Players.LocalPlayer

local function read(): boolean
	return player:GetAttribute(StatNames.Creative) == true
end

local CreativeState = {
	on = vide.source(read()),
}

player:GetAttributeChangedSignal(StatNames.Creative):Connect(function()
	CreativeState.on(read())
end)

return CreativeState
