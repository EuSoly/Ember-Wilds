--!strict
local CraftState = require(script.Parent.Parent:WaitForChild("CraftState"))

local CraftController = {}

function CraftController.Start(_self)
	CraftState.Start(CraftState)
end

return CraftController
