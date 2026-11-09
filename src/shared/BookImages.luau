--!strict
-- Artes do livro de receitas (arte do Elizeu, 09/11), num lugar só. Fontes em
-- assets/ui/book/ (recorte por prepare_book.py). Id vazio ("") = sem a arte:
-- a peça volta ao desenho por código (o livro continua funcionando).
local HudImages = require("./HudImages")

local BookImages = {}

-- Abas: plaquinha de madeira (normal) e laranja (selecionada), esticadas em 9 partes.
BookImages.TAB = "rbxassetid://140291025564258" -- tab.png (256x90)
BookImages.TAB_SELECTED = "rbxassetid://81579472294484" -- tab_selected.png (256x85)
BookImages.PAPER = "rbxassetid://106048370688899" -- paper.png (406x512): fundo da ficha
BookImages.CLOSE = "rbxassetid://106085757348850" -- icon_close.png: X no octógono de madeira

-- Ícone de cada aba (BookInfo.TABS), solto, ao lado do nome.
BookImages.TAB_ICON = {
	tools = "rbxassetid://134182101941838", -- tab_tools.png: picareta e martelo
	weapons = "rbxassetid://79027735524138", -- tab_weapons.png: espada
	armor = "rbxassetid://74890238268503", -- tab_armor.png: capacete
	food = "rbxassetid://132962981168838", -- tab_food.png: coxa
	build = "rbxassetid://79950332198866", -- tab_build.png: fogueira
	resources = "rbxassetid://116460862607072", -- tab_resources.png: tora e pedra
} :: { [string]: string }

-- Selos do "Precisa de" (chave = BookInfo.STATIONS[*].icon) e o relógio do tempo.
BookImages.STATION = {
	workbench = "rbxassetid://132366148642774", -- badge_workbench.png
	fire = "rbxassetid://110597111005550", -- badge_fire.png
	water = "rbxassetid://133998679438131", -- badge_water.png
} :: { [string]: string }
BookImages.CLOCK = "rbxassetid://104378375989958" -- badge_clock.png

-- Recursos do mapa no "Onde conseguir" (id em Defs/Resources).
BookImages.RESOURCE = {
	tree = "rbxassetid://80512535381211", -- res_tree.png
	rock = "rbxassetid://85111541897373", -- res_rock.png
	gold_vein = "rbxassetid://137626614013390", -- res_gold_vein.png
	berry_bush = "rbxassetid://124263605015458", -- res_berry_bush.png
} :: { [string]: string }

-- Ícone de cada linha dos dados (chave = key da linha do UIFlow/ItemInfo). As
-- barras e a mochila usam os ícones do HUD.
BookImages.STAT = {
	["info.damage"] = "rbxassetid://126975906160745", -- stat_damage.png
	["info.structureDamage"] = "rbxassetid://135849070589358", -- stat_structure.png
	["info.speed"] = "rbxassetid://135535278294058", -- stat_speed.png
	["info.equipLock"] = "rbxassetid://101404604794158", -- stat_equiplock.png
	["info.defense"] = "rbxassetid://126319429706875", -- stat_defense.png
	["info.reach"] = "rbxassetid://126386316751278", -- stat_reach.png
	["info.pickaxe"] = "rbxassetid://96524621401433", -- stat_pickaxe.png
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
