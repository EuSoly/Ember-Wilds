# Livro de receitas Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Trocar o livro de receitas (lista do molde `RecipeBook`) por um guia com abas, grade de itens e ficha que explica como conseguir cada item e o que ele faz.

**Architecture:** Toda a regra (que item vai em que aba, a ficha, de onde vem, para que serve, se dá para fazer agora) fica num módulo puro `src/shared/UIFlow/BookInfo.luau`, testado no Lune com os Defs reais. A tela vira código Vide (sem o molde do Studio), com a mesma API pública de hoje (`RecipeBookScreen.open`, `.toggle`, `.mount`), então `ScreenController` e `RecipeBookButton` não mudam. As artes têm ids num `src/shared/BookImages.luau`; id vazio = desenho por código.

**Tech Stack:** Luau `--!strict`, Vide, Rojo, Lune (`bash scripts/check.sh`), stylua, selene, luau-lsp.

**Spec:** `docs/superpowers/specs/2026-11-09-livro-receitas-design.md` (rascunho aprovado: `.superpowers/brainstorm/9399-1794237875/content/livro-v1.html`)

## Global Constraints

- Tudo vem dos Defs (`Items`, `Recipes`, `Mobs`, `Resources`, `Tiers`); nada de texto de "onde conseguir" escrito à mão.
- Itens com `ItemAccess.isAvailable(id, inStudio) == false` não aparecem (nem em abas, nem em "onde conseguir", nem em "serve para").
- O livro só mostra informação; craftar continua pela `CraftColumn`.
- Visual do HUD do Ember Wilds (couro, madeira, papel; `Kit.panel`, `HudArt`, `ItemIcon({ bare = true })`, fonte `Theme.font.number`, texto escuro no papel). Não imitar a tela do Starve.
- Slots ≥ 44 px (toque); grade e ficha rolam quando não cabem.
- Textos em pt-BR com acentos, em `src/shared/Strings/ptBR.luau`.
- Commits em pt-BR terminando com `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; `export PATH="$HOME/.rokit/bin:$PATH"` antes de stylua/lune; depois de mudar código, `& (Get-Content graphify-out\.graphify_python) -m graphify update .` (PowerShell).
- Envio de imagens para o Roblox só com a confirmação do Elizeu.

## Review Focus

1. Item com receita **e** fonte (ex. `paper`: categoria resource, feito no fogo) — a ficha mostra as duas coisas, sem duplicar seção. (Teste na Task 3.)
2. Item sem receita e sem fonte nenhuma (só vem de kit) — "Onde conseguir" vazio não pode quebrar nem mostrar seção vazia. (Teste na Task 3.)
3. Ingrediente `testOnly` ou item `testOnly` fora do Studio — some de abas, fontes e "serve para". (Testes nas Tasks 1 e 3.)
4. Clicar num ingrediente ou em "serve para" leva à ficha certa mesmo se o item for de outra aba (troca a aba para a primeira que o contém). (Teste na Task 1: `firstTab`.)
5. Nome comprido / receita com 3+ ingredientes não sai do papel (a ficha rola). (Conferência no Studio, Task 6.)

---

### Task 1: Abas e itens por aba

**Files:**
- Create: `src/shared/UIFlow/BookInfo.luau`
- Test: `tests/bookinfo.spec.luau`
- Modify: `src/shared/Strings/ptBR.luau` (nomes das abas)

**Interfaces:**
- Produces:
  - `export type Tab = "tools" | "weapons" | "armor" | "food" | "build" | "resources"`
  - `BookInfo.TABS: { Tab }` na ordem acima; nome de cada aba em `"book.tab." .. tab`.
  - `BookInfo.items(tab: Tab, inStudio: boolean): { string }` — ids, ordenados por `recipe.order` de quem tem receita, depois os sem receita por id.
  - `BookInfo.firstTab(itemId: string, inStudio: boolean): Tab?`
  - `BookInfo.recipeOf(itemId: string): RecipeDef?` (a receita cujo `result` é o item)

Regra das abas (spec, "Que item vai em que aba"): tools = categoria `tool` + `misc`; weapons = `weapon`; armor = `armor` + `bag`; food = `food`; build = `placeable`; resources = todo item sem receita + itens de categoria `resource` com receita. Um item pode estar em várias abas.

- [ ] **Step 1: Write the failing tests** (`tests/bookinfo.spec.luau`, no estilo dos outros specs: tabela de funções)

```lua
["tabs come in the book order"] = function()
	assert(table.concat(BookInfo.TABS, ",") == "tools,weapons,armor,food,build,resources")
end,
["swords are in weapons"] = function()
	assert(table.find(BookInfo.items("weapons", false), "gold_sword"))
end,
["bag sits with armor"] = function()
	assert(table.find(BookInfo.items("armor", false), "leather_bag"))
end,
["raw items are resources and food at once"] = function()
	assert(table.find(BookInfo.items("resources", false), "berry"))
	assert(table.find(BookInfo.items("food", false), "berry"))
	assert(table.find(BookInfo.items("resources", false), "wolf_fur"))
end,
["crafted material stays in resources"] = function()
	assert(table.find(BookInfo.items("resources", false), "paper"))
end,
["test-only items hide outside studio"] = function()
	assert(not table.find(BookInfo.items("tools", false), "water_bucket"))
	assert(table.find(BookInfo.items("tools", true), "water_bucket"))
end,
["first tab finds the tab of an ingredient"] = function()
	assert(BookInfo.firstTab("stone_sword", false) == "weapons")
	assert(BookInfo.firstTab("wood", false) == "resources")
end,
["recipes come before raw items, by recipe order"] = function()
	local tools = BookInfo.items("tools", false)
	assert(table.find(tools, "wood_pickaxe") < table.find(tools, "stone_pickaxe"))
end,
```

(Conferir os ids reais em `src/shared/Defs/Items.luau` antes; se `leather_bag`/`water_bucket`/`stone_sword` tiverem outro id, usar o real e manter a intenção.)

- [ ] **Step 2: Run to verify it fails** — `export PATH="$HOME/.rokit/bin:$PATH"; lune run tests/run 2>&1 | grep -i "bookinfo\|passed"` → FAIL (módulo não existe).
- [ ] **Step 3: Implement** `BookInfo.TABS`, `items`, `firstTab`, `recipeOf` em `src/shared/UIFlow/BookInfo.luau` (requires relativos como `ItemInfo`: `require("../Defs")`, `require("../ItemAccess")`). Strings: `book.tab.tools` "Ferramentas", `book.tab.weapons` "Armas", `book.tab.armor` "Armaduras", `book.tab.food` "Comida", `book.tab.build` "Construções", `book.tab.resources` "Recursos".
- [ ] **Step 4: Run** `bash scripts/check.sh` → todos passam.
- [ ] **Step 5: Commit** — `feat(livro): abas e itens por aba (BookInfo)`.

### Task 2: Ficha — receita, estação, tempo e dados

**Files:**
- Modify: `src/shared/UIFlow/BookInfo.luau`, `src/shared/UIFlow/ItemInfo.luau`, `src/shared/Strings/ptBR.luau`
- Test: `tests/bookinfo.spec.luau`, `tests/iteminfo.spec.luau`

**Interfaces:**
- Consumes: `BookInfo.recipeOf` (Task 1).
- Produces:
  - `ItemInfo.lines(def: ItemDef, max: number?): { Line }` — `max` padrão `ItemInfo.MAX_LINES` (a dica continua igual); a ficha passa `math.huge`.
  - nova linha `info.equipLock` = "Presa na mão: {value} s" (adicionada **depois** de `info.reach`, para a dica de 3 linhas não mudar).
  - `BookInfo.STATIONS: { [string]: { key: string, icon: string } }` com `workbench` ("book.station.workbench" = "Bancada", icon "workbench"), `fire` ("book.station.fire" = "Fogo", icon "fire"), `water` ("book.station.water" = "Perto da água", icon "water"). A tela monta "Precisa de" só por esta tabela (receitas futuras com `station = "water"` aparecem sozinhas).
  - `export type Craft = { ingredients: { RecipeIngredient }, count: number, station: string?, seconds: number }`
  - `BookInfo.craft(itemId: string): Craft?` — nil sem receita; `seconds = CraftRules.duration(recipe, nil)`.
  - `BookInfo.stats(itemId: string): { ItemInfo.Line }` — `ItemInfo.lines(def, math.huge)`.

- [ ] **Step 1: Write the failing tests**

```lua
-- bookinfo.spec
["sword craft lists ingredients, workbench and time"] = function()
	local craft = BookInfo.craft("gold_sword")
	assert(craft and craft.station == "workbench" and craft.seconds > 0)
	assert(#craft.ingredients >= 2)
end,
["raw item has no craft"] = function()
	assert(BookInfo.craft("wood") == nil)
end,
["every station used by a recipe is in the table"] = function()
	for _, recipe in Defs.Recipes do
		assert(recipe.station == nil or BookInfo.STATIONS[recipe.station], recipe.id)
	end
	assert(BookInfo.STATIONS.water, "água já prevista para receitas futuras")
end,
["sheet shows every stat, not just three"] = function()
	assert(#BookInfo.stats("gold_sword") >= 4)
end,
-- iteminfo.spec
["weapon tells how long it stays in the hand"] = function()
	local all = ItemInfo.lines(Defs.Items.gold_sword, math.huge)
	-- procurar "Presa na mão: 5 s" (valor real do equipLock da espada de ouro)
end,
["tooltip still caps at three lines"] = function()
	assert(#ItemInfo.lines(Defs.Items.gold_sword) <= ItemInfo.MAX_LINES)
end,
```

- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement** os itens de Interfaces. Strings novas: as três `book.station.*`, `info.equipLock`.
- [ ] **Step 4: Run** `bash scripts/check.sh` → passam (a dica do item continua com no máximo 3 linhas).
- [ ] **Step 5: Commit** — `feat(livro): ficha com receita, estação, tempo e dados`.

### Task 3: De onde vem, para que serve e se dá para fazer agora

**Files:**
- Modify: `src/shared/UIFlow/BookInfo.luau`, `src/shared/Strings/ptBR.luau`
- Test: `tests/bookinfo.spec.luau`

**Interfaces:**
- Produces:
  - `export type Source = { kind: "mob", id: string, count: number } | { kind: "resource", id: string, hardness: number? }` (`hardness` nil = rendimento fixo, qualquer coisa na mão; 0 = mão; ≥1 = picareta nível N)
  - `BookInfo.sources(itemId: string): { Source }` — mobs (de `Mobs[*].loot`) por nome, depois recursos do mapa (de `Resources[*].gather.item`); recursos sem `gather` (pedrinha) nunca entram.
  - `BookInfo.usedIn(itemId: string, inStudio: boolean): { string }` — `result` das receitas que usam o item, ordem por `recipe.order`, sem `testOnly` fora do Studio.
  - `BookInfo.craftableNow(itemId: string, counts: { [string]: number }, near: { [string]: boolean }): boolean` — true se tem receita, todos os ingredientes em quantidade e (sem estação ou `near[station]`); item sem receita → true (recursos nunca ficam apagados).
- Strings: `book.source.mob` "{name} — deixa {count} ao morrer", `book.source.hand` "Com a mão", `book.source.pickaxe` "Com picareta nível {level}", `book.source.any` "Com qualquer coisa na mão".

- [ ] **Step 1: Write the failing tests**

```lua
["wolf fur comes from wolves"] = function()
	local s = BookInfo.sources("wolf_fur")
	assert(#s == 1 and s[1].kind == "mob" and s[1].id == "wolf" and s[1].count == 1)
end,
["stone comes from rocks with a pickaxe"] = function()
	local found = false
	for _, s in BookInfo.sources("stone") do
		if s.kind == "resource" and s.id == "rock" then found = (s :: any).hardness ~= nil end
	end
	assert(found)
end,
["decorative pebble is never a source"] = function()
	for _, id in Defs.Items do -- todos os itens
		for _, s in BookInfo.sources(id.id) do assert(s.id ~= "pebble") end
	end
end,
["crafted material shows both craft and source rules"] = function()
	assert(BookInfo.craft("paper") ~= nil) -- (fonte pode ser vazia; não pode quebrar)
	BookInfo.sources("paper")
end,
["item with no source returns empty list"] = function()
	assert(#BookInfo.sources("gold_sword") == 0)
end,
["wood is used in many recipes"] = function()
	assert(table.find(BookInfo.usedIn("wood", false), "wood_pickaxe"))
end,
["test-only results hide from used-in"] = function()
	for _, id in BookInfo.usedIn("wood", false) do
		assert(not Defs.Items[id].testOnly, id)
	end
end,
["craftable now needs items and station"] = function()
	assert(BookInfo.craftableNow("wood_pickaxe", { wood = 10 }, {}) == true)
	assert(BookInfo.craftableNow("wood_pickaxe", { wood = 9 }, {}) == false)
	-- uma receita de bancada sem a bancada perto:
	assert(BookInfo.craftableNow("gold_sword", { wood = 99, stone = 99, gold = 99, stone_sword = 1 }, {}) == false)
	assert(BookInfo.craftableNow("wood", {}, {}) == true)
end,
```

(Valores reais conferidos nos Defs: `wood_pickaxe` = 10 madeira; ajustar o kit da espada de ouro ao que a receita pedir.)

- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `bash scripts/check.sh` → passam.
- [ ] **Step 5: Commit** — `feat(livro): de onde vem, para que serve e se dá para fazer agora`.

### Task 4: Ids das artes

**Files:**
- Create: `src/shared/BookImages.luau`
- Test: `tests/bookimages.spec.luau`

**Interfaces:**
- Produces (todos começam `""`; o envio é a Task 7):
  - `BookImages.TAB`, `BookImages.TAB_SELECTED` (+ `BookImages.SLICED.tab = { size = {256, 92}, slice = {...} }` medido no PNG `assets/ui/book/tab.png`; a aba selecionada tem 256×86 — usar o mesmo `slice` proporcional ou medir o dela também)
  - `BookImages.PAPER` (+ `SLICED.paper`, de `paper.png` 407×512)
  - `BookImages.CLOSE`
  - `BookImages.TAB_ICON: { [Tab]: string }` (`tab_tools.png` ... `tab_resources.png`)
  - `BookImages.STATION: { workbench: string, fire: string, water: string }` — `fire` = `badge_fire.png`, `water` = `badge_water.png`, `workbench` = "" (arte ainda não feita)
  - `BookImages.RESOURCE: { [string]: string }` — `tree`, `rock`, `gold_vein`, `berry_bush`
  - `BookImages.STAT: { [string]: string }` — chave = a `key` da linha do `ItemInfo` (`info.damage`, `info.structureDamage`, `info.speed`, `info.equipLock`, `info.defense`, `info.reach`, `info.pickaxe`), todas `""` por enquanto; `info.cold`/`info.health`/`info.food.*`/`info.bag` apontam para os ícones de status/mochila do `HudImages`.
  - `BookImages.has(id: string?): boolean`
- [ ] **Step 1: Failing tests** — "every tab has an icon key" (`BookImages.TAB_ICON[tab] ~= nil` para cada `BookInfo.TABS`), "every station in BookInfo has an icon key", "sliced rects stay inside their art" (mesma função do `hudimages.spec`).
- [ ] **Step 2: Run** → FAIL. **Step 3: Implement.** **Step 4:** `bash scripts/check.sh`. **Step 5: Commit** — `feat(livro): lugar dos ids das artes`.

### Task 5: Tela — moldura, abas e grade

**Files:**
- Modify (reescrever): `src/client/Screens/RecipeBookScreen.luau`
- Modify: `src/shared/Strings/ptBR.luau` (`book.title` "Livro de receitas")

**Interfaces:**
- Consumes: `BookInfo.TABS/items/craftableNow/firstTab` (Tasks 1, 3), `BookImages` (Task 4).
- Produces (API mantida, `ScreenController` e `RecipeBookButton` não mudam):
  - `RecipeBookScreen.open: vide.Source<boolean>`, `RecipeBookScreen.toggle()`, `RecipeBookScreen.mount(playerGui: Instance): ScreenGui?` (agora monta com `vide.mount` um ScreenGui próprio, `ResetOnSpawn = false`, `Enabled = false` — o `showWhen` do `ScreenController` liga/desliga).
  - `RecipeBookScreen.tab: vide.Source<Tab>` e `RecipeBookScreen.selected: vide.Source<string?>` (estado da sessão: reabre na última aba/item; primeira vez = `tools` + primeiro item).
  - `RecipeBookScreen.show(itemId: string)` — seleciona o item e troca para `BookInfo.firstTab` (usado pela ficha).

Layout: `Kit.panel` centralizado (≈ 900×560 lógicos, `UIScale` da interface via `Template.bindUiScale`), placa de madeira com o título (`Rustic.plate`), botão de fechar (`HudArt.roundButton` com `BookImages.CLOSE`, fallback "X") no canto, fileira de abas (aba de madeira `TAB`/`TAB_SELECTED` em 9 partes com ícone + nome; sem arte, `Kit.pill`), grade à esquerda num `ScrollingFrame` (6 colunas, slots 56 px com `HudArt.slotBack` / `SLOT_SELECTED`, `ItemIcon({ bare = true })` dentro de `HudArt.inSlot`), apagados (`ImageTransparency`/`GroupTransparency` ~0,5) quando `craftableNow` é falso, e à direita o espaço da ficha (Task 6). O molde `RecipeBook` do Studio deixa de ser usado (não apagar do Studio).

- [ ] **Step 1:** Reescrever a tela. **Step 2:** `bash scripts/check.sh` verde. **Step 3: Conferir no Studio** (Rojo sincronizado no Edit antes do Play): abrir pelo botão do livro, trocar as 6 abas, rolar a grade, itens apagados sem material, fechar pelo X e pelo botão do livro; tela some ao morrer. **Step 4: Commit** — `feat(livro): tela nova com abas e grade`.

### Task 6: Ficha na tela

**Files:**
- Create: `src/client/UI/BookSheet.luau`, `src/client/UI/MobPortrait.luau`
- Modify: `src/client/Screens/RecipeBookScreen.luau` (põe a ficha), `src/shared/Strings/ptBR.luau`

**Interfaces:**
- Consumes: `BookInfo.recipeOf/craft/stats/sources/usedIn/STATIONS` (Tasks 1–3), `BookImages` (Task 4), `RecipeBookScreen.selected/show` (Task 5), `ItemInfo.tier` (cor do tier escurecida como em `ItemTooltip`).
- Produces:
  - `BookSheet(props: { item: () -> string? }): Frame` — papel (`BookImages.PAPER` em 9 partes; sem arte, `Rustic.paper`) com `ScrollingFrame` e `UIListLayout`: nome, material/categoria, seções **Como fazer** (chips de ingrediente clicáveis → `RecipeBookScreen.show`), **Precisa de** (estação pela `STATIONS` + "{s} s"), **Dados** (linhas com ícone de `BookImages.STAT` quando houver), **Onde conseguir** (mob: `MobPortrait` + `book.source.mob`; recurso: ícone `BookImages.RESOURCE[id]` + nome `resource.<id>` + ferramenta), **Serve para** (chips clicáveis). Seção sem conteúdo não aparece.
  - `MobPortrait(props: { mob: string }): ViewportFrame` — clona `ReplicatedStorage.Assets.Mobs/<id>`, câmera de frente/3⁄4 enquadrando a caixa do modelo (mesma ideia do `ItemIcon.flatView` + `UIMath.fitDistance`); sem modelo, o nome no lugar.
- Strings: `book.section.how` "Como fazer", `book.section.needs` "Precisa de", `book.section.stats` "Dados", `book.section.where` "Onde conseguir", `book.section.usedIn` "Serve para", `book.seconds` "{value} s", `book.category.<categoria>` para as 8 categorias.

- [ ] **Step 1:** Implementar. **Step 2:** `bash scripts/check.sh` verde. **Step 3: Conferir no Studio:** Espada de Ouro (ingredientes, Bancada, tempo, dano/velocidade/presa), Fogueira (vida), um capacete (defesa/frio), carne assada (Fogo, repõe), Pele de Lobo (retrato do lobo, serve para), Pedra (rocha + picareta), papel (receita + material); clicar num ingrediente troca de aba e de ficha; Fogueira Grande (3 ingredientes) e nomes compridos não saem do papel. **Step 4: Commit** — `feat(livro): ficha do item`.

### Task 7: Artes, guia e grafo

**Files:**
- Modify: `src/shared/BookImages.luau` (ids), `docs/guia/hud.md` (ou novo `docs/guia/livro-receitas.md`, ligado no `hud.md`)
- Add: `assets/ui/book/*.png`, `assets/ui/book/prepare_book.py` (já existem, não commitados)

- [ ] **Step 1:** **Com a confirmação do Elizeu**, servir `assets/ui/book/` (`python -m http.server` em segundo plano) e enviar os PNGs com `mcp__Roblox_Studio__upload_image`; preencher os ids no `BookImages`.
- [ ] **Step 2:** `bash scripts/check.sh` verde; conferir no Studio as abas de madeira, o papel, o X, os selos de fogo/água e os ícones de recurso.
- [ ] **Step 3:** Guia: o que o livro mostra, de onde vêm os dados (BookInfo ← Defs), como uma estação nova (ex. água) aparece, onde ficam as artes e o que ainda não tem arte (bancada, relógio, ícones dos dados). Rodar `graphify update .`.
- [ ] **Step 4: Commit** — `feat(livro): artes do livro de receitas e guia`.
