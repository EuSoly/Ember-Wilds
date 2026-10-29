--!strict
-- Liga os efeitos do mundo que só existem no cliente: a bolha de ar do
-- fôlego, as copas transparentes sobre o boneco e o aviso de borda.
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
end

return WorldFxController
