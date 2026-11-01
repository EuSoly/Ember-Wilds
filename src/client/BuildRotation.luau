--!strict
-- Giro da peça na mão (construção livre), no cliente:
-- - `steps`: giro atual, 0 a ROTATE_STEPS - 1 (45 graus por passo); o fantasma
--   usa este valor, e o servidor guarda o mesmo número (Net.SetBuildRotation);
-- - `placing`: há uma peça colocável na mão (o botão de girar e a tecla R só
--   valem então).
-- O giro volta a 0 quando o item da mão ou o personagem muda. O servidor zera o
-- dele sozinho, mas a troca chega aqui ~1 RTT depois: um R apertado nesse
-- intervalo seria aceito lá e zerado só aqui. Por isso, ao zerar com uma peça
-- na mão, o cliente também manda 0 (a última mensagem bate com o fantasma).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local BuildRules = require(Shared:WaitForChild("Build"):WaitForChild("BuildRules"))
local Defs = require(Shared:WaitForChild("Defs"))
local StatNames = require(Shared:WaitForChild("StatNames"))
local Net = require(script.Parent:WaitForChild("Net"))

local BuildRotation = {}

BuildRotation.steps = vide.source(0)
BuildRotation.placing = vide.source(false)

local started = false

-- Soma 1 passo (módulo ROTATE_STEPS) e avisa o servidor. Sem peça na mão, nada.
function BuildRotation.rotate()
	if not vide.untrack(BuildRotation.placing) then
		return
	end
	local steps = (vide.untrack(BuildRotation.steps) + 1) % BuildRules.ROTATE_STEPS
	BuildRotation.steps(steps)
	Net.SetBuildRotation.Fire(steps)
end

-- Liga o polling e a tecla R (chamado uma vez pelo WorldFxController).
function BuildRotation.start()
	if started then
		return
	end
	started = true

	local lastCharacter: Model? = nil
	local lastEquipped: unknown = nil
	-- Polling de propósito: com Server Authority o AttributeChanged não
	-- dispara no personagem previsto local.
	RunService.RenderStepped:Connect(function()
		local character = Players.LocalPlayer.Character
		local equipped: unknown = if character then character:GetAttribute(StatNames.Equipped) else nil
		local item = if typeof(equipped) == "string" then Defs.Items[equipped] else nil
		local placing = item ~= nil and item.category == "placeable" and item.structure ~= nil
		if character ~= lastCharacter or equipped ~= lastEquipped then
			lastCharacter = character
			lastEquipped = equipped
			BuildRotation.steps(0)
			-- O servidor troca o item antes de o cliente ver a troca; um R apertado
			-- nessa janela já chegou lá. Mandar o 0 faz a última mensagem sempre
			-- bater com o que o fantasma mostra. Sem peça na mão o servidor ignoraria.
			if placing then
				Net.SetBuildRotation.Fire(0)
			end
		end
		if placing ~= vide.untrack(BuildRotation.placing) then
			BuildRotation.placing(placing)
		end
	end)

	UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
		-- Evento já processado pelo jogo (chat, TextBox...): não gira.
		if gameProcessed then
			return
		end
		if input.KeyCode == Enum.KeyCode.R then
			BuildRotation.rotate()
		end
	end)
end

return BuildRotation
