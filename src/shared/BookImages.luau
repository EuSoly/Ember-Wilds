--!strict
-- Artes do livro de receitas (arte do Elizeu, 09/11), num lugar só. Fontes em
-- assets/ui/book/ (recorte por prepare_book.py). Id vazio ("") = sem a arte:
-- a peça volta ao desenho por código (o livro continua funcionando).
local HudImages = require("./HudImages")

local BookImages = {}

-- Abas: plaquinha de madeira (normal) e laranja (selecionada), esticadas em 9 partes.
BookImages.TAB = "" -- tab.png (256x90)
BookImages.TAB_SELECTED = "" -- tab_selected.png (256x85)
BookImages.PAPER = "" -- paper.png (406x512): fundo da ficha
BookImages.CLOSE = "" -- icon_close.png: X no octógono de madeira

-- Ícone de cada aba (BookInfo.TABS), solto, ao lado do nome.
BookImages.TAB_ICON = {
	tools = "", -- tab_tools.png: picareta e martelo
	weapons = "", -- tab_weapons.png: espada
	armor = "", -- tab_armor.png: capacete
	food = "", -- tab_food.png: coxa
	build = "", -- tab_build.png: fogueira
	resources = "", -- tab_resources.png: tora e pedra
} :: { [string]: string }

-- Selos do "Precisa de" (chave = BookInfo.STATIONS[*].icon) e o relógio do tempo.
BookImages.STATION = {
	workbench = "", -- badge_workbench.png
	fire = "", -- badge_fire.png
	water = "", -- badge_water.png
} :: { [string]: string }
BookImages.CLOCK = "" -- badge_clock.png

-- Recursos do mapa no "Onde conseguir" (id em Defs/Resources).
BookImages.RESOURCE = {
	tree = "", -- res_tree.png
	rock = "", -- res_rock.png
	gold_vein = "", -- res_gold_vein.png
	berry_bush = "", -- res_berry_bush.png
} :: { [string]: string }

-- Ícone de cada linha dos dados (chave = key da linha do UIFlow/ItemInfo). As
-- barras e a mochila usam os ícones do HUD.
BookImages.STAT = {
	["info.damage"] = "", -- stat_damage.png
	["info.structureDamage"] = "", -- stat_structure.png
	["info.speed"] = "", -- stat_speed.png
	["info.equipLock"] = "", -- stat_equiplock.png
	["info.defense"] = "", -- stat_defense.png
	["info.reach"] = "", -- stat_reach.png
	["info.pickaxe"] = "", -- stat_pickaxe.png
	["info.cold"] = HudImages.STATUS_ICON.cold,
	["info.health"] = HudImages.STATUS_ICON.health,
	["info.food.hunger"] = HudImages.STATUS_ICON.hunger,
	["info.food.thirst"] = HudImages.STATUS_ICON.thirst,
	["info.food.health"] = HudImages.STATUS_ICON.health,
	["info.bag"] = HudImages.ICON.backpack,
} :: { [string]: string }

-- Peças esticadas em 9 partes: tamanho da arte e o miolo que estica
-- ({ min.x, min.y, max.x, max.y }); os cantos chanfrados/rasgados não esticam.
BookImages.SLICED = {
	tab = { size = { 256, 90 }, slice = { 26, 24, 230, 66 } },
	tab_selected = { size = { 256, 85 }, slice = { 26, 22, 230, 63 } },
	paper = { size = { 406, 512 }, slice = { 44, 44, 362, 468 } },
} :: { [string]: { size: { number }, slice: { number } } }

function BookImages.has(id: string?): boolean
	return id ~= nil and id ~= ""
end

return BookImages
