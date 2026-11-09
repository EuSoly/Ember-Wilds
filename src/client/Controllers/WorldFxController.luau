--!strict
-- Liga os efeitos do mundo que só existem no cliente: a bolha de ar do
-- fôlego, as copas transparentes sobre o boneco, o aviso de borda, a
-- tremulação das luzes de fogo (o servidor só cria a luz; tremer é visual),
-- os efeitos da coleta, as frutinhas visíveis dos arbustos, o telhado
-- translúcido sobre o boneco e as peças móveis das caixas 3D.
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
local RoofFade = require(World:WaitForChild("RoofFade"))
local CraftBubble = require(World:WaitForChild("CraftBubble"))
local CrateAnimator = require(World:WaitForChild("CrateAnimator"))
local BuildGhost = require(World:WaitForChild("BuildGhost"))
local BuildRotation = require(Client:WaitForChild("BuildRotation"))
local StructureHealth = require(World:WaitForChild("StructureHealth"))
local StructureFx = require(World:WaitForChild("StructureFx"))
local WebVisual = require(World:WaitForChild("WebVisual"))

local WorldFxController = {}

function WorldFxController.Start(_self)
	task.spawn(OxygenBubble.start)
	CanopyFade.start()
	BorderWarning.start()
	GatherFx.start()
	BerryDisplay.start()
	CraftBubble.start()
	CrateAnimator.start()
	BuildRotation.start()
	BuildGhost.start()
	StructureHealth.start()
	WebVisual.start()
	StructureFx.start()
	RoofFade.start()

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
