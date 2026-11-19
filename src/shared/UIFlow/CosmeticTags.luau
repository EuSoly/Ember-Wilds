--!strict
-- Etiquetas das skins (puro): faixas na diagonal nos cantos do quadradinho
-- da tela de Cosméticos e a lista no painel da skin escolhida.
--   "animated" (Animada): a skin tem peças que se mexem (Models/SkinMotion)
--   "effects"  (Efeitos): a mochila solta partículas (BagFxConfig)
--   "limited"  (Limitada): skin que não volta. Sai sozinha para toda skin
--              de pacote da loja (UIFlow/BundleSkins, lido de Shop/Bundles);
--              para outras (evento...), marca à mão no Defs/Cosmetics (`tags`)
-- Animada e Efeitos saem sozinhas: skin nova com animação ou partículas
-- ganha a etiqueta sem ninguém marcar. Limitada fica no canto de cima à
-- direita; Animada (ou, sem ela, Efeitos) no de cima à esquerda (pedido do
-- Elizeu, 18/11/2026).
local BagFxConfig = require("../BagFxConfig")
local BundleSkins = require("./BundleSkins")
local SkinMotion = require("../Models/SkinMotion")
local Types = require("../Defs/Types")

export type Tag = "limited" | "animated" | "effects"
export type Corners = { limited: boolean, left: Tag? }

local CosmeticTags = {}

-- Etiquetas que se marcam à mão no Defs/Cosmetics (o Validate confere).
CosmeticTags.MANUAL = table.freeze({ "limited" })

local function animated(id: string): boolean
	return table.find(SkinMotion.skins(), id) ~= nil
end

local function effects(id: string): boolean
	return BagFxConfig.of(id) ~= nil
end

local function marked(def: Types.CosmeticDef, tag: string): boolean
	local tags = def.tags
	return tags ~= nil and table.find(tags, tag) ~= nil
end

-- Limitada: marcada à mão ou vinda de pacote da loja (pacote futuro já ganha
-- a etiqueta só de entrar em Shop/Bundles).
local function limited(def: Types.CosmeticDef): boolean
	return marked(def, "limited") or BundleSkins.has(def.id)
end

-- O que vai em cada canto do quadradinho.
function CosmeticTags.of(def: Types.CosmeticDef): Corners
	local left: Tag? = if animated(def.id) then "animated" elseif effects(def.id) then "effects" else nil
	return { limited = limited(def), left = left }
end

-- Todas as etiquetas, na ordem do painel: Limitada, Animada, Efeitos.
function CosmeticTags.list(def: Types.CosmeticDef): { Tag }
	local list: { Tag } = {}
	if limited(def) then
		table.insert(list, "limited")
	end
	if animated(def.id) then
		table.insert(list, "animated")
	end
	if effects(def.id) then
		table.insert(list, "effects")
	end
	return list
end

return CosmeticTags
