--!strict
-- Liga os efeitos do mundo que só existem no cliente: a bolha de ar do
-- fôlego, as copas transparentes sobre o boneco, o aviso de borda e a
-- tremulação das luzes de fogo (o servidor só cria a luz; tremer é visual).
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local FireLight = require(Shared:WaitForChild("Models"):WaitForChild("FireLight"))
local StatNames = require(Shared:WaitForChild("StatNames"))

local Client = script.Parent.Parent
local World = Client:WaitForChild("World")
local BorderWarning = require(World:WaitForChild("BorderWarning"))
local CanopyFade = require(World:WaitForChild("CanopyFade"))
local OxygenBubble = require(World:WaitForChild("OxygenBubble"))

local WorldFxController = {}

function WorldFxController.Start(_self)
	task.spawn(OxygenBubble.start)
	CanopyFade.start()
	BorderWarning.start()

	-- Fogueiras chegam aos poucos (streaming): liga cada uma quando aparece.
	local function flicker(instance: Instance)
		local light = FireLight.find(instance)
		if light then
			FireLight.flicker(light)
		end
	end
	CollectionService:GetInstanceAddedSignal(StatNames.FireLightTag):Connect(flicker)
	for _, instance in CollectionService:GetTagged(StatNames.FireLightTag) do
		flicker(instance)
	end
end

return WorldFxController
