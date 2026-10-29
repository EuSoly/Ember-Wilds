--!strict
-- Luz quente de fogo (fogueira e, no futuro, tochas e fornalhas).
-- attach: cria a PointLight na peça e marca a peça com a tag FireLight. Quem
-- monta o modelo (o servidor) só chama attach.
-- flicker: a tremulação do brilho roda no CLIENTE (é só visual e não precisa
-- passar pela rede): o WorldFxController chama flicker em cada luz das peças
-- com a tag FireLight, inclusive as que chegam depois pelo streaming.
-- (Só roda no Roblox: cria instâncias.)
local RunService = game:GetService("RunService")

local Palette = require("../Palette")
local StatNames = require("../StatNames")
local Theme = require("../Theme")

local FireLight = {}

-- Valores da luz da fogueira [spec §8].
local COLOR = Palette.biome.nightFire[3] -- #FFA43A
local RANGE = 18
local BRIGHTNESS = 2
-- Faixa da tremulação e velocidade do ruído (ciclos por segundo, aproximado).
local FLICKER_MIN = 1.6
local FLICKER_MAX = 2.2
local FLICKER_SPEED = 3

local LIGHT_NAME = "FireLight"

function FireLight.attach(part: BasePart): PointLight
	local light = Instance.new("PointLight")
	light.Name = LIGHT_NAME
	light.Color = Theme.color(COLOR)
	light.Range = RANGE
	light.Brightness = BRIGHTNESS
	light.Shadows = false
	light.Parent = part
	part:AddTag(StatNames.FireLightTag)
	return light
end

-- A luz de uma peça marcada (ou nil se ainda não chegou pelo streaming).
function FireLight.find(part: Instance): PointLight?
	local light = part:FindFirstChild(LIGHT_NAME)
	if light ~= nil and light:IsA("PointLight") then
		return light
	end
	return nil
end

-- Liga a tremulação: o brilho anda entre FLICKER_MIN e FLICKER_MAX seguindo um
-- ruído suave (math.noise), com uma fase própria por luz para duas fogueiras
-- não piscarem juntas. Desconecta sozinha quando a luz sai do jogo.
function FireLight.flicker(light: PointLight): RBXScriptConnection
	local phase = math.random() * 1000
	local connection: RBXScriptConnection
	connection = RunService.Heartbeat:Connect(function()
		if not light:IsDescendantOf(game) then
			connection:Disconnect()
			return
		end
		-- math.noise devolve mais ou menos de -0.5 a 0.5: leva para 0..1.
		local n = math.clamp(math.noise(os.clock() * FLICKER_SPEED, phase) + 0.5, 0, 1)
		light.Brightness = FLICKER_MIN + (FLICKER_MAX - FLICKER_MIN) * n
	end)
	return connection
end

return FireLight
