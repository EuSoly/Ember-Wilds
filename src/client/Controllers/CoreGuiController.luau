--!strict
-- Desliga partes da interface padrão do Roblox que o jogo substitui:
-- a mochila (temos hotbar e inventário próprios) e a barra de vida (temos os anéis).
-- O chat padrão continua ligado.
local StarterGui = game:GetService("StarterGui")

local DISABLED: { Enum.CoreGuiType } = { Enum.CoreGuiType.Backpack, Enum.CoreGuiType.Health }
local MAX_ATTEMPTS = 10
local RETRY_DELAY = 0.5

local CoreGuiController = {}

function CoreGuiController.Start(_self)
	-- SetCoreGuiEnabled pode falhar nos primeiros instantes do jogo, enquanto a
	-- CoreGui ainda carrega; por isso tenta algumas vezes numa thread própria.
	task.spawn(function()
		for _, coreGuiType in DISABLED do
			for _ = 1, MAX_ATTEMPTS do
				local ok = pcall(StarterGui.SetCoreGuiEnabled, StarterGui, coreGuiType, false)
				if ok then
					break
				end
				task.wait(RETRY_DELAY)
			end
		end
	end)
end

return CoreGuiController
