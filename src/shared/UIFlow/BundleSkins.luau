--!strict
-- Skins que vêm nos pacotes em destaque da loja (puro): lido direto de
-- Shop/Bundles para pacote novo funcionar sem marcar nada à mão no
-- Defs/Cosmetics. A tela de Cosméticos usa para mostrar essas skins trancadas
-- (mesmo `unreleased`) e o CosmeticTags para dar a etiqueta Limitada.
-- Pacote `rascunho` (ou sem preço) não está à venda, então não conta: senão
-- a skin dele apareceria antes da hora. As datas (startsAt/endsAt) não
-- entram: pacote que acabou continua Limitada, e o módulo fica sem relógio.
local Bundles = require("../Shop/Bundles")
local Types = require("../Shop/Types")

local BundleSkins = {}

-- Monta o conjunto { [id da skin] = true } a partir de uma lista de pacotes
-- (separado para o teste passar pacotes de mentira).
function BundleSkins.fromBundles(list: { Types.BundleDef }): { [string]: boolean }
	local set: { [string]: boolean } = {}
	for _, bundle in list do
		if bundle.rascunho or bundle.robux == nil then
			continue
		end
		for _, reward in bundle.rewards do
			if reward.kind == "cosmetic" and reward.id ~= nil then
				set[reward.id] = true
			end
		end
	end
	return set
end

local current = table.freeze(BundleSkins.fromBundles(Bundles))

-- A skin `id` vem em algum pacote à venda da loja?
function BundleSkins.has(id: string): boolean
	return current[id] == true
end

return BundleSkins
