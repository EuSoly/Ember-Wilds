--!strict
-- Estado da Loja (mockup UI 2): giros comprados por tipo, tela do giro aberta
-- e se está girando. As regras puras ficam em SpinRules.
--
-- Mockup: nada aqui fala com o servidor nem grava nada. Comprar giros só soma
-- no contador (e mostra o aviso de "compra simulada"); o saldo de Golden Ember
-- nunca muda, mas o giro com Golden Ember só é comprado se o saldo pagar.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local SpinRules = require(Shared:WaitForChild("UIFlow"):WaitForChild("SpinRules"))
local StatNames = require(Shared:WaitForChild("StatNames"))
local Strings = require(Shared:WaitForChild("Strings"))
local MenuState = require(script.Parent.Parent:WaitForChild("MenuState"))

-- Fonte Vide: chamar sem argumento lê, com argumento escreve.
type Source<T> = (() -> T) & ((T) -> T)

local ShopState = {}

local counts: Source<SpinRules.Counts> = vide.source(SpinRules.newCounts()) :: any
ShopState.counts = counts

local spinType: Source<string?> = vide.source(nil :: string?) :: any
ShopState.spinType = spinType -- tipo da tela do giro aberta (nil = fechada)

local spinning: Source<boolean> = vide.source(false) :: any
ShopState.spinning = spinning

local function balance(): number
	local value = Players.LocalPlayer:GetAttribute(StatNames.Currency)
	return if type(value) == "number" then value else 0
end

-- Compra (simulada) `qty` giros do tipo. O normal custa Golden Ember: sem saldo
-- não compra (o botão já fica apagado; isto é só a última garantia).
function ShopState.buySpins(typeId: string, kind: SpinRules.Kind, qty: number, price: number): boolean
	if kind == "normal" and not SpinRules.canAfford(balance(), price) then
		return false
	end
	counts(SpinRules.addSpins(vide.untrack(counts), typeId, kind, qty))
	MenuState.notify(Strings.get("mock.simulated"))
	return true
end

-- Gasta um giro (true se havia). Quem chama anima o carrossel.
function ShopState.useSpin(typeId: string, kind: SpinRules.Kind): boolean
	local current = vide.untrack(counts)
	if vide.untrack(spinning) or not SpinRules.canSpin(current, typeId, kind) then
		return false
	end
	counts(SpinRules.useSpin(current, typeId, kind))
	return true
end

-- Abre a tela do giro de um tipo (nil fecha; não fecha no meio de um giro).
function ShopState.openSpin(typeId: string?)
	if typeId == nil and vide.untrack(spinning) then
		return
	end
	spinType(typeId)
end

return ShopState
