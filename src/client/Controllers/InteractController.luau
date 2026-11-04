--!strict
local InteractState = require(script.Parent.Parent:WaitForChild("InteractState"))

local InteractController = {}

function InteractController.Start(_self)
	InteractState.Start(InteractState)
end

return InteractController
