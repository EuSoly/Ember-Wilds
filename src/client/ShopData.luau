--!strict
-- Estado da loja do jogador no cliente, lido da pasta Player.Shop que o
-- servidor (ShopService) publica. Só leitura: comprar, girar e ativar kit são
-- pedidos ao servidor (Menu/Purchase, Net.RequestSpin, Net.SetActiveKit).
--
-- Uma fonte Vide com o retrato inteiro, refeito (uma vez por quadro, no
-- máximo) quando a pasta muda. As funções abaixo leem dela e são reativas.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local StatNames = require(Shared:WaitForChild("StatNames"))

export type Snapshot = {
	spins: { normal: number, paid: number },
	balance: { [string]: number },
	owned: { [string]: boolean },
	active: string?,
	purchased: { [string]: boolean },
	passes: { [string]: boolean },
}

type Source<T> = (() -> T) & ((T) -> T)

local function empty(): Snapshot
	return { spins = { normal = 0, paid = 0 }, balance = {}, owned = {}, active = nil, purchased = {}, passes = {} }
end

local snapshot: Source<Snapshot> = vide.source(empty()) :: any

local ShopData = {}

ShopData.snapshot = snapshot

function ShopData.spins(kind: "normal" | "paid"): number
	return snapshot().spins[kind]
end

function ShopData.balances(): { [string]: number }
	return snapshot().balance
end

function ShopData.kitBalance(kitId: string): number
	return snapshot().balance[kitId] or 0
end

function ShopData.kitOwned(kitId: string): boolean
	return snapshot().owned[kitId] == true
end

-- Kit para sempre ativo (nil = nenhum).
function ShopData.kitActive(): string?
	return snapshot().active
end

function ShopData.purchased(productId: string): boolean
	return snapshot().purchased[productId] == true
end

function ShopData.hasPass(passId: string): boolean
	return snapshot().passes[passId] == true
end

local function numberAttribute(folder: Instance, name: string): number
	local value = folder:GetAttribute(name)
	return if type(value) == "number" then value else 0
end

local function flags(folder: Instance?): { [string]: boolean }
	local set: { [string]: boolean } = {}
	if folder then
		for _, child in folder:GetChildren() do
			if child:IsA("BoolValue") and child.Value then
				set[child.Name] = true
			end
		end
	end
	return set
end

local function counts(folder: Instance?): { [string]: number }
	local map: { [string]: number } = {}
	if folder then
		for _, child in folder:GetChildren() do
			if child:IsA("IntValue") and child.Value > 0 then
				map[child.Name] = child.Value
			end
		end
	end
	return map
end

local function read(root: Instance): Snapshot
	local active = root:GetAttribute(StatNames.KitActive)
	return {
		spins = {
			normal = numberAttribute(root, StatNames.SpinsNormal),
			paid = numberAttribute(root, StatNames.SpinsPaid),
		},
		balance = counts(root:FindFirstChild(StatNames.KitBalanceFolder)),
		owned = flags(root:FindFirstChild(StatNames.KitsOwnedFolder)),
		active = if type(active) == "string" and active ~= "" then active else nil,
		purchased = flags(root:FindFirstChild(StatNames.PurchasedFolder)),
		passes = flags(root:FindFirstChild(StatNames.PassesFolder)),
	}
end

-- Liga na pasta assim que ela existir; cada mudança agenda um retrato novo.
local function watch(root: Instance)
	local pending = false
	local function refresh()
		if pending then
			return
		end
		pending = true
		task.defer(function()
			pending = false
			if root.Parent then
				snapshot(read(root))
			end
		end)
	end
	local function hook(instance: Instance)
		if instance:IsA("ValueBase") then
			(instance :: any).Changed:Connect(refresh)
		end
	end
	root.AttributeChanged:Connect(refresh)
	root.DescendantAdded:Connect(function(instance)
		hook(instance)
		refresh()
	end)
	root.DescendantRemoving:Connect(refresh)
	for _, instance in root:GetDescendants() do
		hook(instance)
	end
	refresh()
end

local player = Players.LocalPlayer
local existing = player:FindFirstChild(StatNames.ShopFolder)
if existing then
	watch(existing)
else
	local connection: RBXScriptConnection
	connection = player.ChildAdded:Connect(function(child)
		if child.Name == StatNames.ShopFolder then
			connection:Disconnect()
			watch(child)
		end
	end)
end

return ShopData
