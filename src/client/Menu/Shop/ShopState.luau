--!strict
-- Estado da tela da Loja no cliente: qual roleta está aberta e se está
-- girando. Os saldos de giros são do servidor (ShopData); comprar e girar são
-- pedidos (Menu/Purchase, Net.RequestSpin).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local MockStore = require(Shared:WaitForChild("UIFlow"):WaitForChild("MockStore"))

-- Fonte Vide: chamar sem argumento lê, com argumento escreve.
type Source<T> = (() -> T) & ((T) -> T)

local ShopState = {}

local spinType: Source<string?> = vide.source(nil :: string?) :: any
ShopState.spinType = spinType -- tipo da tela do giro aberta (nil = fechada)

-- true do pedido do giro até o carrossel parar (trava GIRAR e fechar).
local spinning: Source<boolean> = vide.source(false) :: any
ShopState.spinning = spinning

-- Abre a tela do giro de um tipo (nil fecha; não fecha no meio de um giro;
-- tipo sem skins não abre).
function ShopState.openSpin(typeId: string?)
	if typeId == nil and vide.untrack(spinning) then
		return
	end
	if typeId ~= nil then
		-- Tipo sem skins ("Em breve") não abre: o sorteio não tem o que escolher.
		for _, spin in MockStore.SPIN_TYPES do
			if spin.id == typeId then
				if #spin.items == 0 then
					return
				end
				break
			end
		end
	end
	spinType(typeId)
end

return ShopState
