--!strict
-- Fontes reativas (Vide) para a interface: transformam atributos, o tipo de
-- dispositivo e o relógio do ciclo em valores que os componentes leem.
-- Cada fonte desconecta sozinha quando o componente que a criou é destruído.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local DayCycle = require(Shared:WaitForChild("DayCycle"))
local StatNames = require(Shared:WaitForChild("StatNames"))

local CYCLE_REFRESH = 0.25 -- segundos

local Sources = {}

-- Valor atual do atributo `name` de `instance`; enquanto o atributo não existe
-- (ex.: o cliente entrou antes do servidor preencher), devolve `default`.
function Sources.attribute<T>(instance: Instance, name: string, default: T): () -> T
	local function read(): T
		local value = instance:GetAttribute(name)
		if value == nil then
			return default
		end
		return value :: any
	end

	local value = vide.source(read())
	vide.cleanup(instance:GetAttributeChangedSignal(name):Connect(function()
		value(read())
	end))
	return function()
		return value()
	end
end

-- Como attribute, mas lido do filho `childName` de `parent` (ex.: a pasta
-- ProfileStats do Player), que o servidor cria e pode chegar depois: até lá
-- (ou sem o atributo) devolve `default`. Não espera (WaitForChild) para não
-- travar quem monta a tela.
function Sources.childAttribute<T>(parent: Instance, childName: string, name: string, default: T): () -> T
	local value = vide.source(default)
	local changed: RBXScriptConnection? = nil

	local function bind(child: Instance)
		if changed then
			changed:Disconnect()
		end
		local function read()
			local current = child:GetAttribute(name)
			value(if current == nil then default else current :: any)
		end
		read()
		changed = child:GetAttributeChangedSignal(name):Connect(read)
	end

	local existing = parent:FindFirstChild(childName)
	if existing then
		bind(existing)
	end
	local added = parent.ChildAdded:Connect(function(child)
		if child.Name == childName then
			bind(child)
		end
	end)
	vide.cleanup(function()
		added:Disconnect()
		if changed then
			changed:Disconnect()
		end
	end)
	return function()
		return value()
	end
end

-- Dispositivo preferido do jogador (teclado e mouse, toque, gamepad).
function Sources.preferredInput(): () -> Enum.PreferredInput
	local value = vide.source(UserInputService.PreferredInput)
	vide.cleanup(UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(function()
		value(UserInputService.PreferredInput)
	end))
	return function()
		return value()
	end
end

-- true quando o jogador está no celular/tablet (controles de toque visíveis).
function Sources.isTouch(): () -> boolean
	local preferred = Sources.preferredInput()
	return vide.derive(function()
		return preferred() == Enum.PreferredInput.Touch
	end)
end

-- Estado do ciclo de dia e noite, recalculado algumas vezes por segundo.
function Sources.cycle(): () -> DayCycle.CycleState
	local function compute(): DayCycle.CycleState
		local start = Workspace:GetAttribute(StatNames.CycleStart)
		local elapsed = if type(start) == "number" then Workspace:GetServerTimeNow() - start else 0
		return DayCycle.at(elapsed)
	end

	local value = vide.source(compute())
	local thread = task.spawn(function()
		while true do
			task.wait(CYCLE_REFRESH)
			value(compute())
		end
	end)
	vide.cleanup(thread)
	return function()
		return value()
	end
end

return Sources
