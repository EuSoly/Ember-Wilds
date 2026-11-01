--!strict
local ChestState = require(script.Parent.Parent:WaitForChild("ChestState"))

local ChestController = {}

function ChestController.Start(_self)
	ChestState.Start(ChestState)
end

return ChestController
