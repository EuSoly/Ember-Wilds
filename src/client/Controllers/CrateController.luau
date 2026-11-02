--!strict
local CrateState = require(script.Parent.Parent:WaitForChild("CrateState"))

local CrateController = {}

function CrateController.Start(_self)
	CrateState.Start(CrateState)
end

return CrateController
