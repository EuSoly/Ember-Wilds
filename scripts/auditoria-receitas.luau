--!strict
-- Auditoria das receitas liberadas aos jogadores fora do Studio.
-- Uso: lune run scripts/auditoria-receitas.luau
-- Gera docs/game-design/auditoria-receitas.md e imprime o resumo.
local fs = require("@lune/fs")

local CraftRules = require("../src/shared/Craft/CraftRules")
local Defs = require("../src/shared/Defs")
local DigRules = require("../src/shared/Gather/DigRules")
local ItemAccess = require("../src/shared/ItemAccess")
local Strings = require("../src/shared/Strings")

-- Fontes diretas (sem receita) disponíveis fora do Studio.
local directSources: { [string]: { string } } = {}
local function addSource(id: string, source: string)
	if not ItemAccess.isAvailable(id, false) then
		return
	end
	if directSources[id] == nil then
		directSources[id] = {}
	end
	if table.find(directSources[id], source) == nil then
		table.insert(directSources[id], source)
	end
end

-- 1. Coleta de recursos no mapa
for _, res in Defs.Resources do
	if not res.decorative and res.gather then
		addSource(res.gather.item, `coleta ({res.id})`)
	end
end

-- 2. Loot de mobs que têm população ativa
for _, mob in Defs.Mobs do
	if mob.population and next(mob.population) ~= nil and mob.loot then
		for _, drop in mob.loot do
			addSource(drop.id, `loot ({mob.id})`)
		end
	end
end

-- 3. Pá (DigRules)
addSource("ground", "pá (chão)")
addSource("sand", "pá (areia)")
for _, luck in DigRules.LUCK do
	addSource(luck.id, "pá (sorte)")
end

-- 4. Kits iniciais
for _, kit in Defs.Kits do
	for _, entry in kit.items do
		addSource(entry.id, `kit ({kit.id})`)
	end
end

-- 5. Quests ativas da partida (Defs.Quests)
if (Defs :: any).Quests then
	for _, quest in (Defs :: any).Quests do
		if not quest.disabled and quest.rewardItem then
			addSource(quest.rewardItem, `quest ({quest.id})`)
		end
	end
end

-- Propaga obtenção via receitas liberadas e plantações liberadas
local obtainable: { [string]: boolean } = {}
for id in directSources do
	obtainable[id] = true
end

local releasedRecipes: { Defs.RecipeDef } = {}
for _, recipe in Defs.Recipes do
	if ItemAccess.recipeAvailable(recipe, false) then
		table.insert(releasedRecipes, recipe)
	end
end
table.sort(releasedRecipes, function(a, b)
	return a.order < b.order
end)

local changed = true
while changed do
	changed = false
	for _, recipe in releasedRecipes do
		if not obtainable[recipe.result] then
			local allOk = true
			for _, ing in recipe.ingredients do
				if not obtainable[ing.id] then
					allOk = false
					break
				end
			end
			if allOk then
				obtainable[recipe.result] = true
				changed = true
			end
		end
	end
	for _, item in Defs.Items do
		if ItemAccess.isAvailable(item.id, false) and item.structure and item.structure.plant then
			local fruit = item.structure.plant.fruit
			if obtainable[item.id] and not obtainable[fruit] and ItemAccess.isAvailable(fruit, false) then
				obtainable[fruit] = true
				addSource(fruit, `fazenda ({item.id})`)
				changed = true
			end
		end
	end
end

local function itemName(id: string): string
	local def = Defs.Items[id]
	return if def and Strings.has(def.nameKey) then Strings.get(def.nameKey) else id
end

local out: { string } = {}
local function line(text: string)
	table.insert(out, text)
end

line("# Auditoria das receitas liberadas")
line("")
line("Gerado por `lune run scripts/auditoria-receitas.luau` a partir de `src/shared/Defs`.")
line("Lista todas as receitas em que o resultado e todos os ingredientes estão liberados fora do Studio (`ItemAccess.recipeAvailable(recipe, false)`).")
line("")
line("| # | Resultado | Qtd | Ingredientes | Tempo | Estação | Obtível? |")
line("|---:|---|---:|---|---:|---|---|")

local problems: { string } = {}

for _, recipe in releasedRecipes do
	local parts: { string } = {}
	local missingIngs: { string } = {}
	for _, ing in recipe.ingredients do
		local ok = obtainable[ing.id] == true
		table.insert(parts, `{ing.count}× {itemName(ing.id)} (\`{ing.id}\`){if ok then "" else " **[!]**"}`)
		if not ok then
			table.insert(missingIngs, ing.id)
		end
	end
	local stations: { string } = {}
	for _, st in CraftRules.stationsOf(recipe) do
		table.insert(stations, Strings.get(`craft.station.{st}`))
	end
	local stationText = if #stations > 0 then table.concat(stations, " + ") else "—"
	local ok = obtainable[recipe.result] == true
	line(
		`| {recipe.order} | {itemName(recipe.result)} (\`{recipe.result}\`) | {recipe.count} | {table.concat(parts, ", ")} | {recipe.time} s | {stationText} | {if ok then "Sim" else "**Não**"} |`
	)
	local def = Defs.Items[recipe.result]
	if def == nil or not Strings.has(def.nameKey) then
		table.insert(problems, `- Receita \`{recipe.id}\`: falta texto \`{def and def.nameKey or "?"}\`.`)
	end
	if not ok then
		table.insert(
			problems,
			`- Receita \`{recipe.id}\` ({itemName(recipe.result)}): ingrediente(s) sem fonte fora do Studio: \`{table.concat(missingIngs, ", ")}\`.`
		)
	end
end

line("")
line("## Problemas")
line("")
if #problems == 0 then
	line("Nenhum ingrediente impossível ou texto faltando nas receitas liberadas. (Nota: o modelo 3D `Assets.Icons.bandage` do Curativo fica para o Elizeu importar no Studio; até lá o slot mostra as iniciais.)")
else
	for _, p in problems do
		line(p)
	end
end
line("")

local content = table.concat(out, "\n")
fs.writeFile("docs/game-design/auditoria-receitas.md", content)
print(`[auditoria-receitas] {#releasedRecipes} receitas liberadas auditadas, {#problems} problema(s).`)
