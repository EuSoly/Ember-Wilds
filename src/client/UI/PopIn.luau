--!strict
-- Abertura das janelas do menu: ao aparecer, a janela cresce de 96% até o
-- tamanho certo em 0,15 s, a mesma animação das Configurações
-- (UITemplates/Template.show), para todas as telas abrirem do mesmo jeito
-- (pedido do Elizeu, 10/11/2026). Só a escala: o fade das Configurações pede
-- um CanvasGroup, que pesaria nas janelas cheias de quadradinhos 3D.
-- Uso: um filho da janela, PopIn.scale(function() return aberta end).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))

local create = vide.create

local INFO = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out) -- igual ao Template.show
local START_SCALE = 0.96

local PopIn = {}

function PopIn.scale(visible: () -> boolean): UIScale
	local scale = create("UIScale")({ Name = "PopIn", Scale = 1 }) :: UIScale
	local wasVisible = false
	vide.effect(function()
		local now = visible()
		if now and not wasVisible then
			scale.Scale = START_SCALE
			TweenService:Create(scale, INFO, { Scale = 1 }):Play()
		end
		wasVisible = now
	end)
	return scale
end

return PopIn
