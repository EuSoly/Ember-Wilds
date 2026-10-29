--!strict
-- Bootstrap do cliente: carrega todo ModuleScript dentro de Controllers/
-- (em ordem alfabética) e roda o ciclo Init/Start de todos.
-- Para criar um controlador novo, basta adicionar um arquivo em src/client/Controllers.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Lifecycle = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Lifecycle"))

local function loadSystems(folder: Instance): { Lifecycle.System }
	local modules = {}
	for _, child in folder:GetChildren() do
		if child:IsA("ModuleScript") then
			table.insert(modules, child)
		end
	end
	table.sort(modules, function(a, b)
		return a.Name < b.Name
	end)

	local systems = {}
	for _, module in modules do
		local system = (require :: any)(module) :: Lifecycle.System
		system.Name = system.Name or module.Name
		table.insert(systems, system)
	end
	return systems
end

Lifecycle.run(loadSystems(script:WaitForChild("Controllers")))
print("[Client] pronto")
