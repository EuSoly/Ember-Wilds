--!strict
-- Liga a cópia do inventário no cliente ao servidor (ouvintes + pedido inicial).
local InventoryState = require(script.Parent.Parent:WaitForChild("InventoryState"))

local InventoryController = {}

function InventoryController.Start(_self)
	InventoryState.start()
end

return InventoryController
