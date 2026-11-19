# Ajustes do teste com amigo (19/11) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Resolver os 16 pedidos que o Elizeu anotou jogando com um amigo antes do lançamento do Ember Wilds.

**Architecture:** Jogo Roblox survival top-down (estilo Starve.io) em Luau `--!strict`, sincronizado pelo Rojo, com Server Authority. Regras puras ficam em `src/shared` e são testadas no Lune (`tests/*.spec.luau`); serviços do servidor em `src/server/Services`; telas do cliente em Vide (`src/client`); rede em Blink (`net/game.blink` gera `src/*/Net.luau`). Conteúdo é dado (`src/shared/Defs`), nunca código que conhece item pelo nome.

**Tech Stack:** Luau, Rojo 7.7.1, Vide (UI), Blink (rede), ProfileStore (dados), Lune (testes), StyLua, selene, luau-lsp.

**Spec:** `docs/pendencias.md`, seção "Teste com amigo (19/11) — antes de lançar". Guias de cada sistema em `docs/guia/` (inventario.md, combate.md, armaduras.md, sobrevivencia.md, construcao.md, mobs.md, hud.md, telas.md, loja.md).

## Global Constraints

- Branch `lancamento`. Um commit por tarefa, mensagem em português do Brasil.
- Todo texto novo entra em `src/shared/Strings/ptBR.luau` **e** em `src/shared/Strings/en.luau` com as mesmas `{variáveis}` (o `tests/strings.spec.luau` falha se faltar).
- Comentários do código em português, explicando o porquê, no estilo do arquivo vizinho. Acentos corretos.
- Ferramentas em `$HOME/.rokit/bin`. Verificação completa: `bash scripts/check.sh` (StyLua, selene, Rojo build, luau-lsp, testes). Testes só: `lune run tests/run`. Rede: depois de mexer em `net/game.blink`, rodar `blink net/game`.
- Antes de procurar código, consultar o grafo: `& (Get-Content graphify-out\.graphify_python) -m graphify query "<pergunta>"` (PowerShell). Depois de terminar, `& (Get-Content graphify-out\.graphify_python) -m graphify update .`.
- Números do Starve.io: a config oficial está embutida em `https://starve.io/commands.html` (`<script type="application/json" id="server-data">`). Receitas no formato `[ingredientes, bancada, fogo, poço, água, tempo, pontos, quantidade]`. Os números abaixo já foram tirados de lá em 19/11.
- Passos marcados **[Studio — Elizeu]** precisam do Roblox Studio aberto; quem não tem Studio deixa o passo anotado no relatório final.
- Item que não deve aparecer aos jogadores usa `testOnly = true` (ver `src/shared/ItemAccess.luau`); nada nesta lista é `testOnly`.
- Arquivos `src/client/Net.luau` e `src/server/Net.luau` são gerados: nunca editar à mão.

## Review Focus

- **Inventário cheio no meio de uma operação que já tirou item de algum lugar** (baú, caixa, colheita, poço): o item não pode sumir. Teste em `tests/chestrules.spec.luau` (Task 9) e conferência no relatório da Task 3.
- **Golpe em vários alvos com aliado no meio**: colega de time e fantasma não levam dano do golpe em área. Teste em `tests/gather.spec.luau` (Task 5).
- **Dano mínimo com dano original muito pequeno** (ex.: 1 de espinho): 25% de 1 é 0,25 — arredondar sem virar 0 nem passar do original. Teste na Task 6.
- **Inventário de quem já estava jogando com 10 espaços** (servidor atualizado no meio da vida, ou revive que restaura a foto antiga com capacidade 10): tem de crescer para 16 sem perder item. Conferência na Task 1, Step 4.
- **Baú antigo com conteúdo de um tipo só (formato velho)** não existe em produção (baú não persiste), mas o servidor recebe pedidos de clientes antigos durante a atualização: `ChestTake` sem slot deve tirar do slot 1. Teste na Task 9.

---

## Parte A — Inventário

### Task 1: Sem mochila por enquanto — todo mundo tem 16 espaços (+3 do VIP)

**Decisão do Elizeu (19/11):** a ideia de mochila como item sai do jogo por enquanto. Todo jogador tem **10 espaços da hotbar + 6 fixos**, e o VIP soma 3 (16 / 19). As **skins de mochila** (cosméticos, `Assets.Bags`, loja e roletas) **não mudam**: são só visual nas costas.

**Files:**
- Modify: `src/shared/InventoryConfig.luau` (`BASE_SLOTS`)
- Modify: `src/shared/Defs/Items.luau` (`leather_bag` ~L187: `testOnly = true`)
- Modify (se usarem a mochila): `src/shared/Defs/Kits.luau`, `src/server/Services/SpawnService.luau` (`deliverKit` ~L96 continua aceitando mochila, mas nenhum kit liberado dá uma)
- Test: `tests/inventory.spec.luau` (ou o spec que testa `Inventory.capacityFor`), `tests/defs.spec.luau`, `tests/bookinfo.spec.luau`, `tests/iteminfo.spec.luau` (citam `leather_bag`)
- Docs: `docs/guia/inventario.md`

**Interfaces:**
- Produces: `InventoryConfig.BASE_SLOTS = 16` (`HOTBAR_SLOTS` continua `10`; `MAX_SLOTS` continua `40`). `Inventory.capacityFor(bagSlots, bonusSlots)` não muda de assinatura: sem mochila, `capacityFor(0, 0) == 16` e `capacityFor(0, 3) == 19`.

- [ ] **Step 1: Teste:** `["capacidade base é 16 e o VIP soma 3"]` — `Inventory.capacityFor(0, 0) == 16`, `Inventory.capacityFor(0, 3) == 19`.
- [ ] **Step 2:** Rodar `lune run tests/run` — falha (hoje dá 10 e 13).
- [ ] **Step 3:** `BASE_SLOTS = 16`, com o comentário do topo do `InventoryConfig` explicando a decisão. `leather_bag` ganha `testOnly = true` (some do livro e a receita deixa de ser liberada; volta tirando a marca). Conferir que nenhum kit liberado (`Defs/Kits.luau`) dá `leather_bag` — se der, tirar do kit. Ajustar os testes que citam `leather_bag` só se quebrarem.
- [ ] **Step 4:** O painel da mochila (`UI/Backpack.luau`, `BackpackState.hasBag`) continua: ele mostra os espaços além da hotbar, que agora todo mundo tem (6). Trocar o título do painel e a dica, se disserem "mochila" de um jeito que pressuponha o item, para "Inventário" (ptBR e en). Conferir que perfis e inventários antigos com 10 espaços crescem para 16 sem perder item (`Inventory.setCapacity` aumentar sempre pode).
- [ ] **Step 5:** `bash scripts/check.sh` verde. Atualizar `docs/guia/inventario.md` (16 espaços: 10 na hotbar + 6 no painel; VIP +3; mochila como item guardada como `testOnly`).
- [ ] **Step 6:** Commit `feat(inventario): todo mundo tem 16 espaços; mochila como item sai por enquanto`.

### Task 2: Botão da mochila no PC, à direita da hotbar

**Files:**
- Modify: `src/client/UI/Backpack.luau` (`Backpack.Button`, ~L37-L55)
- Modify: `src/client/UI/HudBottom.luau` (nova posição)

**Interfaces:**
- Produces: `HudBottom.rightOfHotbar(): UDim2` — posição logo à direita do último slot da hotbar, centrada na altura dela (use `HudBottom.hotbar()` para medir).

- [ ] **Step 1:** Depois da Task 1 todo mundo tem espaços além da hotbar, então o botão sempre aparece em jogo. Hoje ele só aparece em tela de toque (`Visible = isTouch() and hasBag()`). Passar a aparecer também no PC (`Visible = BackpackState.hasBag()`). No PC usar `HudBottom.rightOfHotbar()`; no toque manter `HudBottom.rightOfRings`. A tecla B continua funcionando.
- [ ] **Step 2:** `bash scripts/check.sh` verde.
- [ ] **Step 3 [Studio — Elizeu]:** Conferir no PC (1280×720 e 1920×1080) e no emulador de celular 749×330 que o botão não cobre nada e que a tela do celular não passa a rolar.
- [ ] **Step 4:** Commit `feat(hud): botão da mochila também no PC, à direita da hotbar`.

### Task 3: Inventário cheio — nunca perder item, sempre avisar

**Files:**
- Modify: `src/server/Services/CrateService.luau` (`onTake` ~L388-L420)
- Modify (só se o caso estiver errado): `ChestService.luau` (`onTake` ~L158), `FarmService.luau` (~L191), `WellService.luau`, `SpawnService.luau` (`deliverKit`/`giveSpawnItems` só dão `warn`), `MissionService.luau` (`onClaim` ~L331), `ShopService.luau`/`GiftService.luau` (recompensas que dão item), `CreativeService.luau`.
- Docs: `docs/guia/inventario.md` (tabela dos casos)

- [ ] **Step 1:** Montar a tabela "caso → o que acontece hoje" lendo cada ponto que chama `InventoryService.give` (lista acima; `give` devolve a sobra que não coube). Casos: coletar recurso (já avisa `gather.full`), craftar (`craft.full`), saquear caixa, tirar do baú, colher planta (`gather.full`), comer/balde, Pegar do criativo (`creative.full`), kit e livro no nascimento, revive, missão/conquista, presente/compra que dá item.
- [ ] **Step 2:** Regra para todos: se o item já saiu de algum lugar e não coube, ele volta para onde estava (baú, caixa) ou cai no chão perto do jogador (use a mesma rotina de "soltar no chão" do `DropSlot` — procure `onDrop` no `CrateService`); e o jogador recebe o aviso com a chave `inventory.full` (nova, ptBR "Inventário cheio", en "Inventory full"), usando o canal de aviso que cada serviço já usa (`Net.CraftNotice` ou o `notify` local).
- [ ] **Step 3:** Corrigir o saque da caixa: hoje clicar num item com o inventário cheio não faz nada e não avisa (`docs/pendencias.md`, "Caixas e combate"). Passa a avisar.
- [ ] **Step 4:** Kit no nascimento: em vez de só `warn`, a sobra cai no chão perto do jogador.
- [ ] **Step 5:** `bash scripts/check.sh` verde. Colocar a tabela final no `docs/guia/inventario.md`.
- [ ] **Step 6:** Commit `fix(inventario): inventário cheio nunca some com item e sempre avisa`.

### Task 4: Soltar item arrastando para fora não funciona no jogo publicado

**Files:**
- Modify: `src/client/DragState.luau` (`isSolid` ~L68, `overWorld` ~L80)

**Causa provável:** `overWorld` só deixa soltar se nenhuma peça "visível" da interface estiver embaixo do ponteiro, e `isSolid` conta qualquer `ImageLabel` com imagem e `ImageTransparency < 1`. Overlays de tela inteira que não recebem clique (ex.: `StatusVignette`, imagem que no Studio às vezes não carrega) bloqueiam o drop no jogo publicado. O botão direito não passa por essa conta, por isso funciona.

- [ ] **Step 1:** Trocar a regra: só bloqueia o drop o que **recebe clique** — `gui:IsA("GuiButton")`, ou `gui.Active == true`, ou tem um ancestral com o atributo `BlocksDrop = true`. Os painéis já usam `Active = true` (ver `Backpack.Panel`). Overlays decorativos (`Active = false`) deixam de bloquear.
- [ ] **Step 2:** Conferir com `grep` os painéis que o jogador pode ter aberto durante o arrasto (mochila, baú, caixa, livro, receita fixada, minimapa, hotbar) e garantir `Active = true` no frame raiz de cada um, para soltar em cima do painel não jogar o item no chão.
- [ ] **Step 3:** `bash scripts/check.sh` verde.
- [ ] **Step 4 [Studio — Elizeu]:** Publicar e testar no jogo de verdade: arrastar para o mundo solta; arrastar para cima de um painel aberto não solta.
- [ ] **Step 5:** Commit `fix(inventario): arrastar para fora solta o item também no jogo publicado`.

## Parte B — Combate e vida

### Task 5: Golpe acerta todos os alvos no círculo

**Files:**
- Modify: `src/shared/Gather/GatherRules.luau` (nova função ao lado de `pickTarget` ~L91)
- Modify: `src/server/Services/GatherService.luau` (`hit` ~L165-L336)
- Test: `tests/gather.spec.luau`
- Docs: `docs/guia/combate.md`

**Interfaces:**
- Produces: `GatherRules.pickTargets<T>(candidates: { T }, px: number, pz: number, hitRadius: number): { T }` — todos os candidatos cuja borda está a `hitRadius` ou menos do centro do golpe (`distância − radius ≤ hitRadius`), ordenados do mais perto para o mais longe.

**Regra decidida:** o golpe atinge **todos** os mobs, jogadores, peças sólidas e caixas dentro do círculo. Recurso (árvore, pedra) continua **um só por golpe** (o mais perto), mesmo com outros alvos acertados junto. Ponte/telhado (`overlays`) só se não houver nenhum outro alvo. A pá só cava se não acertou nada.

- [ ] **Step 1: Testes** em `tests/gather.spec.luau`:
  - `["pickTargets devolve todos no círculo, do mais perto ao mais longe"]`: candidatos `{x=0,z=0,radius=1}`, `{x=2,z=0,radius=1}`, `{x=10,z=0,radius=1}` com centro `(0,0)` e `hitRadius = 2.5` → devolve os dois primeiros, nessa ordem.
  - `["pickTargets vazio quando nada encosta"]`.
- [ ] **Step 2:** `lune run tests/run` — falha.
- [ ] **Step 3:** Implementar `pickTargets`. No `GatherService.hit`, trocar o `pickTarget` único por: lista de alvos = `pickTargets(candidates sem recursos)` + o melhor recurso (`pickTarget` só entre recursos); se a lista ficar vazia, `pickTarget(overlays)`. Aplicar a cada alvo o mesmo ramo que já existe (estrutura/fazenda, caixa, mob, personagem, recurso). Manter: filtro do tutorial, `ArmorService.markHit` uma vez por golpe, `SpawnShieldUntil` limpo se acertou mob ou jogador, colega de time e fantasma não levam dano (essas regras já estão em `CharacterService.hurt`/`TeamService`; confira que continuam valendo com vários alvos).
- [ ] **Step 4:** `lune run tests/run` passa; `bash scripts/check.sh` verde. Atualizar `docs/guia/combate.md`.
- [ ] **Step 5:** Commit `feat(combate): o golpe acerta todos os alvos no círculo (recurso continua um por golpe)`.

### Task 6: Dano mínimo — sempre passa 25%

**Files:**
- Modify: `src/shared/Survival/ArmorRules.luau` (`reduce` ~L107)
- Test: `tests/armorrules.spec.luau` (criar se não existir; senão o spec de armaduras que já testa `reduce`)
- Docs: `docs/game-design/balanco-armas-defesa.md` (gerado por `scripts/balanco-armas.luau`), `docs/pendencias.md`

**Interfaces:**
- Produces: `ArmorRules.MIN_DAMAGE_SHARE = 0.25`. `ArmorRules.reduce(amount, mods, source, held)` passa a devolver `math.max(amount - defense, amount * MIN_DAMAGE_SHARE)`, e `0` só quando `amount <= 0`.

- [ ] **Step 1: Testes:** `reduce(40, defesa 15)` → `25`; `reduce(16, defesa 15)` → `4` (25% de 16 é maior que 1); `reduce(1, defesa 15)` → `0.25`; `reduce(0, qualquer)` → `0`; `reduce(10, defesa 0)` → `10`.
- [ ] **Step 2:** Rodar — falha. **Step 3:** Implementar. Se `CharacterService.hurt` arredonda o dano para inteiro, conferir que 0,25 não vira 0 (manter fração ou arredondar para cima).
- [ ] **Step 4:** Rodar `lune run scripts/balanco-armas.luau` para regenerar o doc do balanço; tirar a pendência "Dano mínimo garantido" de `docs/pendencias.md`; `bash scripts/check.sh` verde.
- [ ] **Step 5:** Commit `feat(combate): todo golpe causa pelo menos 25% do dano original`.

### Task 7: Regeneração de vida conferida e curativo (bandage)

**Files:**
- Modify: `src/shared/Defs/Items.luau` (item `bandage`), `src/shared/Defs/Recipes.luau` (receita), `src/shared/Strings/ptBR.luau` e `en.luau`
- Test: `tests/survival.spec.luau` (ou o spec que já testa `SurvivalRules.step`), `tests/defs.spec.luau`/validação
- Docs: `docs/guia/sobrevivencia.md`

**Números do Starve (config oficial):** receita `bandage = [[cord, 2]]`, bancada, 5 s, 1 unidade; `bandage_heal = 30`; `bandage_stack_limit = 20`. No nosso jogo o equivalente de `cord` é `thread` (linha, loot da aranha). Vida máxima 200 nos dois jogos.

- [ ] **Step 1:** Conferir a regeneração: `SurvivalConfig.REGEN_RATE = 0.5` vida/s, só com fome, frio e sede ≥ `REGEN_MIN` (35) e calor < `REGEN_MAX_HEAT` (65) (`SurvivalRules.step` ~L141). Escrever (ou confirmar) um teste `["regenera 0.5/s com barras ok e para com fome abaixo de 35"]`. Reescrever o trecho confuso de regeneração em `docs/guia/sobrevivencia.md` (pendência em `docs/pendencias.md`, "Caixas e combate").
- [ ] **Step 2:** Item: `bandage = { id = "bandage", nameKey = "item.bandage", category = "food", maxStack = 20, food = { health = 30, crumbColor = "#F2E6D0" } }` (usar como comida: cura 30 na hora; `FoodEffect.health` já existe em `Defs/Types.luau` L18). Receita `recipe("bandage", 1, { ingredient("thread", 2) }, 5, "workbench", <próximo order livre>)`. Textos `item.bandage` (ptBR "Curativo", en "Bandage") e `desc.bandage` (ptBR "Cura 30 de vida na hora.", en "Heals 30 health instantly.").
- [ ] **Step 3:** O Elizeu vai modelar o curativo e importar o modelo em `ReplicatedStorage.Assets.Icons.bandage` (no padrão dos ícones de comida). O código não precisa esperar: até o modelo chegar, o `ItemIcon` usa o reserva por iniciais. Não marcar `testOnly`.
- [ ] **Step 4:** `bash scripts/check.sh` verde (o `Validate` das Defs confere receita e textos).
- [ ] **Step 5:** Commit `feat(vida): curativo (2 linhas na bancada, cura 30) e regeneração conferida`.

## Parte C — Mundo e itens

### Task 8: Frutinha dá água

**Files:** Modify `src/shared/Defs/Items.luau` (`berry` ~L25); Docs `docs/guia/sobrevivencia.md` (tabela de comidas, se houver)

- [ ] **Step 1:** `berry.food = { hunger = 10, thirst = 5, crumbColor = "#7B3FA6" }` (`FoodEffect.thirst` já existe). Valor 5 escolhido aqui (o Starve não dá sede na frutinha); deixar comentário `-- 19/11: pedido do Elizeu, frutinha mata um pouco a sede`.
- [ ] **Step 2:** `lune run tests/run` passa. Commit `feat(comida): frutinha também mata um pouco a sede`.

### Task 9: Baú guarda 3 tipos de item

**Files:**
- Modify: `src/shared/Build/ChestRules.luau`, `src/server/Services/ChestService.luau`, `src/client/ChestState.luau`, `src/client/UI/ChestPanel.luau`, `src/client/Audio/GameSounds.luau` (~L162, L241 leem `ChestCount`), `src/shared/StatNames.luau` (~L237), `net/game.blink` (~L283-L305)
- Test: `tests/chestrules.spec.luau` (criar se não existir)
- Docs: `docs/guia/construcao.md` (seção do baú)

**Interfaces:**
- Produces:
  - `ChestRules.SLOTS = 3`
  - `export type Chest = { Contents }` (3 entradas `{ id: string?, count: number }`)
  - `ChestRules.new(): Chest`
  - `ChestRules.putAny(chest: Chest, id: string, count: number): (number, number?)` — põe no slot que já tem `id`; senão no primeiro vazio; devolve (quanto entrou, índice do slot) ou `(0, nil)`.
  - `ChestRules.takeAt(chest: Chest, slot: number, count: number): (string?, number)` — usa o `take` atual no slot.
  - Atributos no modelo do baú: `ChestItem1..3` e `ChestCount1..3` (`StatNames.chestItem(i)`, `StatNames.chestCount(i)`); os antigos `ChestItem`/`ChestCount` saem.
  - Rede: `event ChestTake { Data: struct { Chest: Instance?, Slot: u8 } }` (slot 1..3).

- [ ] **Step 1: Testes** `tests/chestrules.spec.luau`: pôr 3 tipos diferentes ocupa os 3 slots; o 4º tipo devolve `(0, nil)`; pôr mais do mesmo tipo vai para o slot que já tem; `takeAt` num slot esvazia só ele; `takeAt` com slot fora de 1..3 devolve `(nil, 0)`; `ChestRules.MAX = 9999` vale por slot.
- [ ] **Step 2:** Rodar — falha. **Step 3:** Implementar `ChestRules`; depois `ChestService` (`contents[entry]` vira `Chest`; `onPut` usa `putAny`; `onTake` recebe o slot e usa `takeAt` + `InventoryService.spaceFor`; publicar os 6 atributos). Mudar o `.blink` e rodar `blink net/game`. Cliente: `ChestState` lê os 3 slots; `ChestPanel` mostra 3 slots lado a lado (clicar num slot tira daquele slot); `GameSounds` soma os 3 `ChestCount` para o som de pôr/tirar.
- [ ] **Step 4:** `bash scripts/check.sh` verde. Atualizar o guia.
- [ ] **Step 5 [Studio — Elizeu]:** pôr 3 itens diferentes, tentar um 4º (recusado), tirar de cada slot, dois jogadores no mesmo baú.
- [ ] **Step 6:** Commit `feat(bau): baú guarda 3 tipos de item`.

### Task 10: Poço enche com o tempo; balde acelera

**Files:**
- Modify: `src/shared/Defs/Types.luau` (`WellDef` L103), `src/shared/Defs/Items.luau` (`well.structure.well` ~L1516), `src/shared/Build/WellRules.luau`, `src/server/Services/WellService.luau`
- Test: `tests/wellrules.spec.luau`
- Docs: `docs/guia/construcao.md` (poço)

**Hoje:** o poço só ganha água quando alguém despeja um balde cheio (`WellRules.fill`, +12 goles, máx 48); o balde vazio enche perto da água. **Pedido:** o poço gera água sozinho de tempos em tempos; o balde continua servindo para encher mais rápido.

**Interfaces:**
- Produces: `WellDef.refillEvery: number` (segundos por gole; valor `30`); `WellRules.refill(drinks: number, elapsed: number, def: WellDef): (number, number)` — devolve (goles novos, sobra de tempo que não completou um gole); nunca passa de `maxDrinks`.

- [ ] **Step 1: Testes:** `refill(0, 30, def)` → `(1, 0)`; `refill(0, 75, def)` → `(2, 15)`; `refill(47, 120, def)` → `(48, 0)`; `refill(48, 999, def)` → `(48, 0)`.
- [ ] **Step 2:** Rodar — falha. **Step 3:** Implementar; no `WellService`, um laço (o mesmo passo que já atualiza poços, ou um `task.spawn` de 1 s) soma o tempo por poço e aplica `refill`, publicando o atributo de goles que o painel já lê. Poço novo começa vazio. O botão "encher com balde" e o "beber" não mudam.
- [ ] **Step 4:** `bash scripts/check.sh` verde; guia atualizado (texto: "o poço junta 1 gole a cada 30 s, até 48; um balde cheio põe 12 de uma vez").
- [ ] **Step 5:** Commit `feat(poco): poço junta água sozinho com o tempo; o balde acelera`.

### Task 11: Garrafa de vidro e garrafa de água

**Files:**
- Modify: `src/shared/Defs/Items.luau`, `src/shared/Defs/Recipes.luau`, `src/shared/Strings/ptBR.luau`, `en.luau`
- Create: `scripts/studio/import-bottles.luau` (copiar os modelos)
- Test: `tests/defs.spec.luau` ou o validador das Defs

**Números do Starve:** `bottle_empty = [[sand, 25]]`, bancada + fogo, 5 s, 1 unidade. `bottle_full = [[bottle_empty, 1]]`, perto da água, 5 s, 1 unidade (`drink_bottle_full = 50`).

- [ ] **Step 1:** Itens: `bottle_empty = { id, nameKey = "item.bottle_empty", category = "misc", maxStack = 255 }`; `bottle_full = { id, nameKey = "item.bottle_full", category = "food", maxStack = 255, food = { thirst = 50, crumbColor = "#9FD8F0" } }`. Receitas: `recipe("bottle_empty", 1, { ingredient("sand", 25) }, 5, "workbench", <order>, { "fire" })` e `recipe("bottle_full", 1, { ingredient("bottle_empty", 1) }, 5, "water", <order>)`. Textos ptBR "Garrafa de vidro" / "Garrafa de água" (descs: "Feita de areia derretida. Encha perto da água." / "Mata 50 de sede."), en "Glass Bottle" / "Water Bottle" ("Made of melted sand. Fill it near water." / "Quenches 50 thirst.").
- [ ] **Step 2:** `scripts/studio/import-bottles.luau` (rodar no Studio em Edit): copia `ServerStorage.ImportsOriginais.DoWorkspace["farming-pack"].bottle_empty` e `.bottle_full` para `ReplicatedStorage.Assets.Icons` com os nomes `bottle_empty`/`bottle_full` (ancorados, sem colisão, `CanQuery = false`), seguindo o padrão de `scripts/studio/import-icons.luau`. Sem os modelos o ícone usa iniciais (funciona igual).
- [ ] **Step 3:** `bash scripts/check.sh` verde.
- [ ] **Step 4 [Studio — Elizeu]:** rodar o script, conferir o ícone no livro e ajustar `IconeGiro`/`IconeZoom` se precisar; salvar o place.
- [ ] **Step 5:** Commit `feat(itens): garrafa de vidro (areia na bancada com fogo) e garrafa de água`.

### Task 12: Um pouco mais de mobs (o mapa cresceu)

**Files:** Modify `src/shared/Defs/Mobs.luau` (`population.forest`)

A terra firme passou de 960×960 para 1080×1080 (+27% de área, praia de 60 studs). Subir ~25%, arredondando:

| Mob | Dia (hoje → novo) | Noite (hoje → novo) |
|---|---|---|
| rabbit | 40 → 50 | 15 → 19 |
| hawk | 6 → 8 | 6 → 8 |
| boar | 8 → 10 | 8 → 10 |
| wolf | 10 → 13 | 20 → 25 |
| spider | 8 → 10 | 16 → 20 |

- [ ] **Step 1:** Trocar os números; se algum teste de `tests/mobspawn.spec.luau` fixar contagens, atualizar. **Step 2:** `lune run tests/run` passa. **Step 3:** Commit `balance(mobs): população da floresta +25% (mapa com praia)`.

### Task 13: Auditoria das receitas liberadas

**Files:**
- Create: `scripts/auditoria-receitas.luau` (Lune), Create: `docs/game-design/auditoria-receitas.md` (gerado)

- [ ] **Step 1:** Script Lune que carrega `src/shared/Defs` e, para cada receita cujo resultado e ingredientes são liberados (`ItemAccess.recipeAvailable(recipe, false)`), confere que cada ingrediente **dá para conseguir** fora do Studio: vem de coleta (`Defs.Resources[*].gather.item`), loot de mob com população (`Defs.Mobs[*].loot` de mob com `population`), pá (`DigRules`), fazenda (`structure.plant.fruit`), outra receita liberada, ou kit. Gera a tabela `resultado | qtd | ingredientes | tempo | estação | obtível?` no `.md`, com uma seção "Problemas" listando ingrediente impossível e receita liberada sem ícone/texto.
- [ ] **Step 2:** Rodar `lune run scripts/auditoria-receitas.luau`; corrigir o que for erro óbvio de dado (ex.: ingrediente com id errado). O que for decisão de balanço fica listado para o Elizeu.
- [ ] **Step 3:** Commit `docs(receitas): auditoria das receitas liberadas aos jogadores`.

## Parte D — Telas

### Task 14: Receita fixada mostra bancada/fogo/água

**Files:**
- Modify: `src/client/UI/PinnedRecipe.luau`, `src/shared/UIFlow/HudColumn.luau` (`pinnedHeight` ~L91 conta as linhas)

**Interfaces:**
- Consumes: `BookInfo.craft(itemId).stations: { CraftStation }` (já existe, `src/shared/UIFlow/BookInfo.luau` L109) e `BookInfo.STATIONS[station]` (ícone e texto, já usados em `UI/BookSheet.luau` ~L320); `CraftState.near(): { [string]: boolean }` (estação perto agora, `src/client/CraftState.luau` L28).

- [ ] **Step 1:** Depois das linhas de ingrediente, uma linha por estação exigida, com o ícone `BookImages.STATION[...]` e o nome; verde quando `CraftState.near()[station]` é verdadeiro (mesmo verde `DONE_COLOR` dos ingredientes). O nome do item só fica verde quando ingredientes **e** estações estão ok.
- [ ] **Step 2:** `HudColumn.pinnedHeight(rows)` recebe ingredientes + estações; se houver teste do `HudColumn`, acrescentar o caso com estações.
- [ ] **Step 3:** `bash scripts/check.sh` verde. **Step 4 [Studio — Elizeu]:** fixar a espada (bancada) e a carne assada (fogo); conferir no celular 749×330 que a coluna não estoura.
- [ ] **Step 5:** Commit `feat(hud): receita fixada mostra as estações (bancada, fogo, água)`.

### Task 15: Construções do jogador no minimapa

**Files:**
- Modify: `src/client/UI/Minimap.luau` (marcadores, ao lado do `Marker` ~L51), `src/shared/World/MinimapRules.luau` (posição já existe: `MinimapRules.toView(x, z, rect)`)

**Interfaces:**
- Consumes: modelos de peça em `Workspace.Structures` (`StatNames` ~L214), com o dono no atributo que o `StructureService` grava (procure `Owner`/`OwnerId` em `StructureService.luau`).

- [ ] **Step 1:** Pontinhos (4 px, cor creme com contorno escuro) no minimapa para cada peça cujo dono é o `LocalPlayer` (e, se houver time, as do time em outra cor). Acompanhar `ChildAdded`/`ChildRemoved` de `Workspace.Structures` (cuidado com streaming: a peça pode chegar depois). Limitar a 200 pontos (as mais perto) para não pesar.
- [ ] **Step 2:** `bash scripts/check.sh` verde. **Step 3 [Studio — Elizeu]:** colocar umas peças e conferir.
- [ ] **Step 4:** Commit `feat(minimapa): mostra as construções do jogador`.

### Task 16: Lista de jogadores (placar da partida, estilo Starve)

**Files:**
- Create: `src/client/UI/Leaderboard.luau`, Create: `src/shared/UIFlow/LeaderboardRules.luau`
- Modify: `src/client/UI/App.luau` (montar), `src/shared/Strings/ptBR.luau`/`en.luau`
- Test: `tests/leaderboardrules.spec.luau`

**Interfaces:**
- Consumes: atributos `Score` e `Rank` de cada `Player` (`StatNames.Score`, `StatNames.Rank`; lidos hoje pelo `UI/ScorePill.luau` com `Sources.attribute`).
- Produces: `LeaderboardRules.top(entries: { { name: string, score: number, userId: number } }, limit: number, me: number): { { rank: number, name: string, score: number, isMe: boolean } }` — ordena por pontos (empate: nome), corta em `limit`, e se o jogador local (`me` = userId) ficar de fora, acrescenta ele no fim com o rank real.

- [ ] **Step 1: Testes:** 12 jogadores → 10 linhas; o local em 12º aparece como 11ª linha com `rank = 12, isMe = true`; empate ordena por nome; lista vazia → vazia.
- [ ] **Step 2:** Rodar — falha. **Step 3:** Implementar a regra; a tela é um painel rústico pequeno (estilo `Kit`/`Rustic`) no canto direito, abaixo dos botões do minimapa, com título (ptBR "Jogadores", en "Players"), linhas `#1  Nome  1.240`; o local destacado. No PC aparece sempre; no celular atrás de um botão (para caber em 749×330). Atualiza quando `Score` de alguém muda e quando entra/sai jogador.
- [ ] **Step 4:** `bash scripts/check.sh` verde. **Step 5 [Studio — Elizeu]:** Test → 2 Players.
- [ ] **Step 6:** Commit `feat(hud): placar da partida com os jogadores e pontos`.

### Task 17: Perfil salvo com 2 jogadores **[Studio — Elizeu]**

Sem código, a não ser que apareça bug. No Studio, **Test → Clients and Servers → 2 Players**:

- [ ] Cada jogador ganha pontos, Golden Ember e XP; sair e entrar de novo: os valores de cada um voltam certos e **não se misturam**.
- [ ] Um jogador compra/ganha uma skin; o outro não recebe.
- [ ] Os dois no mesmo servidor ao mesmo tempo, depois um sai: o do outro continua salvando (autosave).
- [ ] Anotar qualquer problema em `docs/pendencias.md`.

## Ao terminar tudo

- [ ] `bash scripts/check.sh` verde na branch inteira.
- [ ] `& (Get-Content graphify-out\.graphify_python) -m graphify update .`
- [ ] Riscar os itens feitos da seção "Teste com amigo (19/11)" em `docs/pendencias.md`.
- [ ] Relatório final: o que foi feito por tarefa e os passos **[Studio — Elizeu]** que ficaram para ele (inclusive importar o modelo do curativo em `Assets.Icons.bandage`).
