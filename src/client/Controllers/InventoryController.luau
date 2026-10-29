--!strict
-- Liga a parte de inventário do cliente: a cópia do inventário (ouvintes +
-- pedido inicial), o estado da mochila (capacidade além da hotbar) e o arrastar entre slots.
local Client = script.Parent.Parent
local BackpackState = require(Client:WaitForChild("BackpackState"))
local DragState = require(Client:WaitForChild("DragState"))
local InventoryState = require(Client:WaitForChild("InventoryState"))

local InventoryController = {}

function InventoryController.Start(_self)
	InventoryState.start()
	BackpackState.start()
	DragState.start()
end

return InventoryController
