--!strict
-- Desliga partes da interface padrão do Roblox que o jogo substitui:
-- a mochila (temos hotbar e inventário próprios) e a barra de vida (temos os anéis).
-- Também desliga o botão "Reset Character" do menu do Roblox: toda morte passa
-- pela morte do jogo (DeathService); não é um jogo de se matar.
-- O chat padrão continua ligado.
local StarterGui = game:GetService("StarterGui")

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
		retry(function()
			StarterGui:SetCore("ResetButtonCallback", false)
		end)
	end)
end

return CoreGuiController
