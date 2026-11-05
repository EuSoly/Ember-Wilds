--!strict
-- Desliga partes da interface padrão do Roblox que o jogo substitui:
-- a mochila (temos hotbar e inventário próprios) e a barra de vida (temos os anéis).
-- O botão "Reset Character" do menu do Roblox passa pelo DeathService do jogo.
-- O chat padrão continua ligado.
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
