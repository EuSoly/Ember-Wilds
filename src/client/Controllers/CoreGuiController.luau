--!strict
-- Desliga partes da interface padrão do Roblox que o jogo substitui:
-- a mochila (temos hotbar e inventário próprios) e a barra de vida (temos os anéis).
-- O botão "Reset Character" do menu do Roblox passa pelo DeathService do jogo,
-- que só reseta depois de 10 s parado; a contagem fica em UI/ResetCountdown.
-- O chat padrão continua ligado. No celular o jogo só roda deitado
-- (LandscapeSensor: vira entre as duas horizontais, nunca em pé); o
-- StarterGui do projeto já vem assim e aqui garante no PlayerGui.
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local Net = require(script.Parent.Parent:WaitForChild("Net"))

local DISABLED: { Enum.CoreGuiType } = { Enum.CoreGuiType.Backpack, Enum.CoreGuiType.Health }
local MAX_ATTEMPTS = 10
local RETRY_DELAY = 0.5

local CoreGuiController = {}

-- As chamadas da CoreGui podem falhar nos primeiros instantes do jogo,
-- enquanto ela ainda carrega; por isso tenta algumas vezes.
local function retry(call: () -> ())
	for _ = 1, MAX_ATTEMPTS do
		if pcall(call) then
			return
		end
		task.wait(RETRY_DELAY)
	end
end

function CoreGuiController.Start(_self)
	-- O PlayerGui copia a orientação do StarterGui ao entrar, às vezes depois
	-- deste script: se trocar para outra, volta para a horizontal.
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui
	local function landscape()
		if playerGui.ScreenOrientation ~= Enum.ScreenOrientation.LandscapeSensor then
			playerGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeSensor
		end
	end
	landscape()
	playerGui:GetPropertyChangedSignal("ScreenOrientation"):Connect(landscape)
	task.spawn(function()
		for _, coreGuiType in DISABLED do
			retry(function()
				StarterGui:SetCoreGuiEnabled(coreGuiType, false)
			end)
		end
		local resetEvent = Instance.new("BindableEvent")
		resetEvent.Event:Connect(function()
			Net.RequestReset.Fire()
		end)
		retry(function()
			StarterGui:SetCore("ResetButtonCallback", resetEvent)
		end)
	end)
end

return CoreGuiController
