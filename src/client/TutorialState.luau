--!strict
-- Estado do tutorial no cliente, lido dos atributos que o TutorialService põe
-- no Player (no Player, não no personagem: AttributeChanged não dispara no
-- personagem previsto). Quem desenha (quadrinho, rastro, destaques, selo,
-- pop-up da roleta) só lê daqui.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local StatNames = require(Shared:WaitForChild("StatNames"))
local TutorialRules = require(Shared:WaitForChild("Tutorial"):WaitForChild("TutorialRules"))
local TutorialSteps = require(Shared:WaitForChild("Tutorial"):WaitForChild("TutorialSteps"))
local InventoryState = require(script.Parent:WaitForChild("InventoryState"))

local player = Players.LocalPlayer

local function attribute<T>(name: string, default: T): () -> T
	local function read(): T
		local value = player:GetAttribute(name)
		return if value == nil then default else value :: any
	end
	local source = vide.source(read())
	player:GetAttributeChangedSignal(name):Connect(function()
		source(read())
	end)
	return source
end

local TutorialState = {}

-- Etapa atual: 0 = fora do tutorial, 1..6 = etapa.
TutorialState.step = attribute(StatNames.TutorialStep, 0) :: () -> number
-- Protegido nesta vida (nem leva nem causa dano).
TutorialState.protected = attribute(StatNames.TutorialProtected, false) :: () -> boolean
-- O perfil ainda não completou o tutorial (a próxima vida é de tutorial).
TutorialState.pending = attribute(StatNames.TutorialPending, false) :: () -> boolean
-- Mostrar o pop-up da roleta no menu.
TutorialState.popupPending = attribute(StatNames.SpinPopupPending, false) :: () -> boolean

-- A etapa atual (definição), ou nil fora do tutorial.
function TutorialState.current(): TutorialSteps.Step?
	return TutorialSteps.LIST[TutorialState.step()]
end

-- Quantos de cada item há no inventário agora.
function TutorialState.counts(): { [string]: number }
	local counts: { [string]: number } = {}
	for _, item in InventoryState.slots() do
		counts[item.id] = (counts[item.id] or 0) + item.count
	end
	return counts
end

-- O que pisca agora (TutorialRules.highlights), com o estado do livro passado
-- por quem pergunta (o livro não é lido daqui, para não haver ciclo de require).
function TutorialState.highlights(bookOpen: boolean, tab: string): TutorialRules.Highlights
	return TutorialRules.highlights(TutorialState.current(), {
		bookOpen = bookOpen,
		tab = tab,
		counts = TutorialState.counts(),
	})
end

return TutorialState
