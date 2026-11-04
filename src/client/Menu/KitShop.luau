--!strict
-- Estado dos kits no menu (UI 1). Junta a escolha de pontos (a de verdade,
-- KitList.selected, compartilhada com a tela de morte) com o MOCKUP de Robux:
-- compra de 1 vida e kits permanentes. As regras puras ficam em KitOffer.
--
-- Mockup: nada aqui fala com o servidor nem grava nada. Comprar com Robux só
-- mostra o aviso de "compra simulada" e muda este estado local (que volta ao
-- início ao sair do jogo). Ao apertar JOGAR, só o kit de pontos vai para o
-- servidor; os outros aparecem como "(simulado)" no botão Kits.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local KitOffer = require(Shared:WaitForChild("UIFlow"):WaitForChild("KitOffer"))
local MockStore = require(Shared:WaitForChild("UIFlow"):WaitForChild("MockStore"))
local Strings = require(Shared:WaitForChild("Strings"))
local Client = script.Parent.Parent
local KitList = require(Client:WaitForChild("Screens"):WaitForChild("KitList"))
local MenuState = require(script.Parent:WaitForChild("MenuState"))

-- Fonte Vide: chamar sem argumento lê, com argumento escreve.
type Source<T> = (() -> T) & ((T) -> T)

local KitShop = {}

local state: Source<KitOffer.State> = vide.source(KitOffer.new(MockStore.KIT_STARTS_OWNED)) :: any
KitShop.state = state

local function update(change: (KitOffer.State) -> KitOffer.State)
	state(change(vide.untrack(state)))
end

-- Pontos, 1 vida: escolhe (ou desfaz) como sempre; escolher limpa a compra de
-- 1 vida com Robux (vai um kit por vida).
function KitShop.choosePoints(kitId: string)
	KitList.toggle(kitId)
	if vide.untrack(KitList.selected) == kitId then
		update(KitOffer.clearRobuxOnce)
	end
end

-- Robux, 1 vida (simulado): vira o kit desta vida no lugar do de pontos.
function KitShop.buyOnce(kitId: string)
	MenuState.notify(Strings.get("mock.simulated"))
	KitList.selected(nil)
	update(function(current)
		return KitOffer.chooseRobuxOnce(current, kitId)
	end)
end

-- Robux, para sempre (simulado): dá a posse; ativar é outro clique.
function KitShop.buyForever(kitId: string)
	MenuState.notify(Strings.get("mock.simulated"))
	update(function(current)
		return KitOffer.buyPermanent(current, kitId)
	end)
end

function KitShop.toggleActive(kitId: string)
	update(function(current)
		return KitOffer.toggleActive(current, kitId)
	end)
end

-- Kit desta vida e de onde vem (reativo).
function KitShop.current(): (string?, KitOffer.Source?)
	return KitOffer.current(state(), KitList.selected())
end

-- Nasceu: a compra de 1 vida foi usada.
function KitShop.spend()
	update(KitOffer.spend)
end

return KitShop
