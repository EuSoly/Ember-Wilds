--!strict
-- Catálogo dos cosméticos (puro, sem Roblox): lê Defs.Cosmetics e entrega as
-- listas já ordenadas para a tela de Cosméticos e para o carrossel da loja.
local Defs = require("../Defs")
local Types = require("../Defs/Types")

type CosmeticDef = Types.CosmeticDef

export type Category = { id: string, side: string, slot: string? }
export type SpinItem = { id: string, nameKey: string, rarity: number, color: string }

local DEFAULT_COLOR = "#8B5A2B"

local CosmeticCatalog = {}

-- Ordem e lado (esquerda/direita) das categorias da tela. "accessory" ainda
-- não tem slot: aparece como "em breve".
CosmeticCatalog.CATEGORIES = {
	{ id = "body", side = "left", slot = "body" },
	{ id = "accessory", side = "left", slot = nil },
	{ id = "crate", side = "left", slot = "crate" },
	{ id = "bag", side = "right", slot = "bag" },
	{ id = "book", side = "right", slot = "book" },
} :: { Category }

local function byRarityThenId(a: CosmeticDef, b: CosmeticDef): boolean
	if a.rarity ~= b.rarity then
		return a.rarity < b.rarity
	end
	return a.id < b.id
end

-- Todas as skins do slot, com a padrão primeiro e depois da mais comum para a mais rara.
function CosmeticCatalog.items(slot: string): { CosmeticDef }
	local slotDef = Defs.CosmeticSlots[slot]
	local defaultId = slotDef and slotDef.default
	local list: { CosmeticDef } = {}
	for _, def in Defs.Cosmetics do
		if def.slot == slot then
			table.insert(list, def)
		end
	end
	table.sort(list, function(a: CosmeticDef, b: CosmeticDef): boolean
		if (a.id == defaultId) ~= (b.id == defaultId) then
			return a.id == defaultId
		end
		return byRarityThenId(a, b)
	end)
	return list
end

-- Cor que representa a skin num cartão/giro.
function CosmeticCatalog.colorOf(def: CosmeticDef): string
	if def.slot == "body" and def.body ~= nil then
		return def.body.bodyColor
	elseif def.slot == "bag" and def.bag ~= nil then
		return def.bag.color
	elseif def.slot == "crate" and def.crate ~= nil then
		return def.crate.bandColor
	end
	return DEFAULT_COLOR
end

-- Skins que podem sair no giro da loja. A padrão do slot só entra com
-- inSpins == true; as demais saem, a menos que inSpins == false.
function CosmeticCatalog.spinItems(slot: string): { SpinItem }
	local slotDef = Defs.CosmeticSlots[slot]
	local list: { SpinItem } = {}
	for _, def in CosmeticCatalog.items(slot) do
		local isDefault = slotDef ~= nil and slotDef.default == def.id
		local enters = if isDefault then def.inSpins == true else def.inSpins ~= false
		if enters then
			table.insert(list, {
				id = def.id,
				nameKey = def.nameKey,
				rarity = def.rarity,
				color = CosmeticCatalog.colorOf(def),
			})
		end
	end
	return list
end

function CosmeticCatalog.pageCount(count: number, perPage: number): number
	return math.max(1, math.ceil(count / perPage))
end

-- Fatia da página (1 = primeira); página fora da faixa é presa nas pontas.
function CosmeticCatalog.page<T>(list: { T }, page: number, perPage: number): { T }
	local clamped = math.clamp(page, 1, CosmeticCatalog.pageCount(#list, perPage))
	local out: { T } = {}
	for i = (clamped - 1) * perPage + 1, math.min(#list, clamped * perPage) do
		table.insert(out, list[i])
	end
	return out
end

-- Página (1 = primeira) em que a skin `id` aparece; id fora da lista = 1.
function CosmeticCatalog.pageOf(list: { CosmeticDef }, id: string, perPage: number): number
	for i, def in list do
		if def.id == id then
			return (i - 1) // perPage + 1
		end
	end
	return 1
end

return CosmeticCatalog
