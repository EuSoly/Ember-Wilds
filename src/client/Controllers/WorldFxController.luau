--!strict
-- Liga os efeitos do mundo que só existem no cliente: a bolha de ar do
-- fôlego, as copas transparentes sobre o boneco, o aviso de borda, a
-- tremulação das luzes de fogo (o servidor só cria a luz; tremer é visual),
-- os efeitos da coleta e as frutinhas visíveis dos arbustos.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local FireLight = require(Shared:WaitForChild("Models"):WaitForChild("FireLight"))
local StatNames = require(Shared:WaitForChild("StatNames"))

local Client = script.Parent.Parent
local World = Client:WaitForChild("World")
local BerryDisplay = require(World:WaitForChild("BerryDisplay"))
local BorderWarning = require(World:WaitForChild("BorderWarning"))
local CanopyFade = require(World:WaitForChild("CanopyFade"))
local GatherFx = require(World:WaitForChild("GatherFx"))
local OxygenBubble = require(World:WaitForChild("OxygenBubble"))
local CraftBubble = require(World:WaitForChild("CraftBubble"))

local WorldFxController = {}

function WorldFxController.Start(_self)
	task.spawn(OxygenBubble.start)
	CanopyFade.start()
	BorderWarning.start()
	GatherFx.start()
	BerryDisplay.start()
	CraftBubble.start()

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
