--!strict
-- Gera a tabela de balanço armas × defesas a partir das Defs (sem chutar número).
-- Uso (Git Bash, na raiz): lune run scripts/balanco-armas > docs/game-design/balanco-armas-defesa.md
-- Regra usada: a mesma do jogo (ArmorRules.reduce + MobRules.damageOf), vida 200.
local ArmorRules = require("../src/shared/Survival/ArmorRules")
local Defs = require("../src/shared/Defs")
local MobRules = require("../src/shared/Mobs/MobRules")
local Strings = require("../src/shared/Strings")

local HEALTH = 200

-- Colunas: sem nada, cada capacete e capacete + escudo do mesmo material.
local COLUMNS: { { label: string, helmet: string?, shield: string? } } = {
	{ label = "Sem peça" },
	{ label = "Cap. madeira", helmet = "wood_helmet" },
	{ label = "Cap. pedra", helmet = "stone_helmet" },
	{ label = "Cap. ouro", helmet = "gold_helmet" },
	{ label = "Cap. diamante", helmet = "diamond_helmet" },
	{ label = "Cap. ametista", helmet = "amethyst_helmet" },
	{ label = "Cap. reidite", helmet = "reidite_helmet" },
	{ label = "Cap. dragão", helmet = "dragon_helmet" },
	{ label = "Cap. lava", helmet = "lava_helmet" },
	{ label = "Ouro + escudo de ouro", helmet = "gold_helmet", shield = "gold_shield" },
	{ label = "Reidite + escudo de reidite", helmet = "reidite_helmet", shield = "reidite_shield" },
	{ label = "Lava + escudo de reidite", helmet = "lava_helmet", shield = "reidite_shield" },
}

local function name(id: string): string
	return Strings.get(Defs.Items[id].nameKey)
end

local function cell(damage: number): string
	if damage <= 0 then
		return "**0**"
	end
	return `{damage} ({math.ceil(HEALTH / damage)})`
end

-- Armas: tudo que bate com dano próprio (e a mão), do mais fraco ao mais forte.
local weapons: { { id: string?, label: string, damage: number, released: boolean } } = {
	{ id = nil, label = "Mão", damage = MobRules.HAND_DAMAGE, released = true },
}
for id, def in Defs.Items do
	if def.mobDamage and def.mobDamage > 0 and (def.category == "weapon" or def.category == "tool") then
		table.insert(weapons, { id = id, label = name(id), damage = def.mobDamage, released = def.testOnly ~= true })
	end
end
table.sort(weapons, function(a, b)
	if a.damage == b.damage then
		return a.label < b.label
	end
	return a.damage < b.damage
end)

local out = {}
local function line(text: string)
	table.insert(out, text)
end

line("# Balanço: armas × defesas")
line("")
line(
	"Gerado por `scripts/balanco-armas.luau` a partir das Defs (`lune run scripts/balanco-armas > docs/game-design/balanco-armas-defesa.md`)."
)
line(
	"Cada célula: **dano por golpe de jogador** e, entre parênteses, golpes para matar um jogador de vida cheia (200). Regra do jogo: `golpe − defesa do capacete − defesa do escudo na mão`, nunca abaixo de 0 (Starve)."
)
line("Itens marcados com * ainda são só de teste. O bônus de conjunto (dragão e lava) aparece em linhas próprias.")
line("")
local header = "| Arma (dano) |"
local sep = "|---|"
for _, column in COLUMNS do
	header ..= ` {column.label} |`
	sep ..= "---|"
end
line(header)
line(sep)

local function row(label: string, weapon: Defs.ItemDef?, attackerArmor: Defs.ItemDef?)
	local text = `| {label} |`
	for _, column in COLUMNS do
		local helmet = if column.helmet then Defs.Items[column.helmet] else nil
		local shield = if column.shield then Defs.Items[column.shield] else nil
		local hit = MobRules.damageOf(weapon, attackerArmor)
		local damage = ArmorRules.reduce(hit, ArmorRules.modifiers(helmet), "player", shield)
		text ..= ` {cell(damage)} |`
	end
	line(text)
end

for _, weapon in weapons do
	local def = if weapon.id then Defs.Items[weapon.id] else nil
	row(`{weapon.label}{if weapon.released then "" else "*"} ({weapon.damage})`, def, nil)
	local bonus = def and def.gearBonus
	if bonus then
		local helmetId = if bonus.set == "dragon" then "dragon_helmet" else "lava_helmet"
		row(`{weapon.label}* + {name(helmetId)} ({weapon.damage + bonus.damage})`, def, Defs.Items[helmetId])
	end
end

line("")
line("## Defesas usadas")
line("")
line("| Peça | Contra jogador | Contra mob |")
line("|---|---|---|")
for _, column in COLUMNS do
	if column.helmet and not column.shield then
		local armor = Defs.Items[column.helmet].armor :: any
		line(`| {name(column.helmet)} | {armor.defense or 0} | {armor.mobDefense or 0} |`)
	end
end
for _, id in { "wood_shield", "stone_shield", "gold_shield", "diamond_shield", "amethyst_shield", "reidite_shield" } do
	local shield = Defs.Items[id].shield :: any
	line(`| {name(id)} (na mão) | {shield.defense} | {shield.mobDefense} |`)
end

print(table.concat(out, "\n"))
