# F3 Inventário — Plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Inventário autoritativo no servidor (10 slots + 6 da mochila), replicado ao cliente por snapshot + deltas via Blink, com mover/empilhar/selecionar validados no servidor, hotbar e grade 4×4 ligadas a ele, e o item selecionado aparecendo na mão do personagem.

**Architecture:** A lógica do inventário é um módulo puro em `src/shared/Inventory.luau` (testado no Lune) que devolve quais slots mudaram. O `InventoryService` guarda um inventário por jogador, aplica pedidos do cliente (Blink) só depois de validar, e manda deltas dos slots alterados. O cliente mantém uma cópia (`InventoryState`, fontes Vide) que a hotbar e a mochila desenham. O item equipado vira um atributo do personagem e um modelo de peças soldado na mão.

**Tech Stack:** Luau `--!strict`, Blink 0.18.9 (`net/game.blink` → código gerado), Vide 0.4.1, Rojo 7.7.1, Lune.

**Spec:** `docs/superpowers/specs/2026-10-28-ember-wilds-mvp-design.md` (seções 5 "ações discretas via Blink", 6, 8 "Inventário", 9 "Arte", 10 F3)

## Global Constraints

- Tudo das fases anteriores continua valendo (strict, Strings/Theme, Init/Start, Server Authority, HUD só lê atributos/estado replicado).
- Inventário: `BASE_SLOTS = 10`, `BAG_SLOTS = 6` (total 16); hotbar = slots 1–10; mochila libera 11–16 quando o jogador tem bolsa (atributo `HasBag` no Player — por enquanto só ligado pelo comando de desenvolvimento).
- `maxStack` vem de `Defs.Items[id].maxStack`; itens desconhecidos são rejeitados.
- O cliente **pede**, o servidor **decide**: índices fora de `1..capacidade`, slot vazio ou item inexistente → pedido ignorado (sem erro no servidor).
- IDs de item na rede: `string(1..32)`; contagem `u16(1..)`; índices `u8(1..16)`.
- Código gerado pelo Blink é commitado e não passa por StyLua/selene; `check.sh` recompila o `.blink` antes do build.
- Inventário **não** é salvo (morre com a partida — spec seção 7).
- Commit por tarefa (pt-BR, sem push). Branch `f3-inventario` a partir da `main` com a F2.
- Verificação: `bash scripts/check.sh` + Play no Studio pelo MCP `Roblox_Studio`.

## Review Focus

1. **Pedido do cliente com índice inválido ou malicioso** (0, 17, slot 12 sem bolsa, mover de slot vazio, mover para si mesmo) — o servidor ignora e o inventário não muda. (Task 1 testes + Task 3.)
2. **Empilhar acima do `maxStack`** ao mover pilha sobre pilha do mesmo item — enche o destino até o máximo e o resto fica na origem. (Task 1 teste.)
3. **Cliente que conecta depois do servidor mandar o snapshot** — o cliente pede o snapshot quando está pronto, nunca fica com inventário vazio fantasma. (Task 3/4.)
4. **Respawn com item selecionado** — o modelo na mão volta no personagem novo. (Task 5.)
5. **Selecionar slot vazio** — nada na mão e atributo `Equipped` limpo. (Task 5.)

---

### Task 1: Lógica pura do inventário

**Files:**
- Create: `src/shared/Inventory.luau`, `tests/inventory.spec.luau`

**Interfaces:**
- Produces:
  - `export type Slot = { id: string, count: number }`
  - `export type Inventory = { capacity: number, slots: { [number]: Slot } }`
  - `Inventory.new(capacity: number): Inventory`
  - `Inventory.add(inv, id: string, count: number, maxStack: number): (number, { number })` — primeiro completa pilhas existentes do mesmo item (em ordem de slot), depois usa slots vazios em ordem; devolve `(sobra, slotsAlterados)`.
  - `Inventory.remove(inv, id: string, count: number): (boolean, { number })` — tudo ou nada; tira das últimas pilhas primeiro.
  - `Inventory.count(inv, id: string): number`
  - `Inventory.move(inv, from: number, to: number, maxStackOf: (string) -> number): { number }` — origem vazia, índices fora de `1..capacity` ou `from == to` → `{}`; destino vazio → move; mesmo item → junta até o `maxStack` (resto fica na origem); item diferente → troca. Devolve slots alterados.
  - `Inventory.setCapacity(inv, capacity: number)` — só aumenta (diminuir é ignorado nesta fase).
- [x] **Step 1: Write the failing tests** (`tests/inventory.spec.luau`): add em vazio (`add("wood", 30, 255)` → slot 1 `{wood,30}`, sobra 0, alterados `{1}`); add completa pilha e transborda (`maxStack 10`: com `{wood,8}` no slot 1, `add("wood", 15, 10)` → slot1 10, slot2 10, slot3 3); add sem espaço devolve sobra; remove tudo-ou-nada (`remove` de mais do que tem → false e nada muda); count soma pilhas; move para vazio; move troca itens diferentes; move junta mesmo item respeitando `maxStack` (`{wood,8}`→`{wood,5}` com max 10 → destino 10, origem 3); move inválido (`0`, `capacity+1`, origem vazia, `from == to`) → `{}` e nada muda; capacidade 10 rejeita índice 11; `setCapacity(16)` libera 11.
- [x] **Step 2: Verify fail**, **Step 3:** implementar, **Step 4: Verify pass** (`lune run tests/run`).
- [x] **Step 5: Commit** `feat: lógica pura do inventário (adicionar, remover, mover, empilhar)`.

### Task 2: Contrato de rede com Blink

**Files:**
- Create: `net/game.blink`, `src/server/Net.luau` (gerado), `src/client/Net.luau` (gerado), `.styluaignore`
- Modify: `selene.toml` (excluir gerados), `scripts/check.sh` (rodar `blink net/game` antes do build), `docs/guia/como-rodar.md`

**Interfaces:**
- Produces (`net/game.blink`, `option ServerOutput = "../src/server/Net.luau"`, `option ClientOutput = "../src/client/Net.luau"`, `option Casing = Pascal`):
  - `struct Slot { Id: string(1..32), Count: u16(1..) }`
  - `map SlotMap = { [u8(1..16)]: Slot }`
  - `event InventorySync { From: Server, Type: Reliable, Call: SingleAsync, Data: struct { Capacity: u8(1..16), Slots: SlotMap } }` — snapshot.
  - `event InventorySlot { From: Server, Type: Reliable, Call: SingleAsync, Data: (u8(1..16), Slot?) }` — delta de um slot (nil = vazio).
  - `event InventoryCapacity { From: Server, Type: Reliable, Call: SingleAsync, Data: u8(1..16) }`
  - `event RequestInventory { From: Client, Type: Reliable, Call: SingleAsync }`
  - `event MoveSlot { From: Client, Type: Reliable, Call: SingleAsync, Data: (u8(1..16), u8(1..16)) }`
  - `event SelectSlot { From: Client, Type: Reliable, Call: SingleAsync, Data: u8(1..10) }`
- [x] **Step 1:** Escrever o `.blink`, gerar, excluir os gerados do StyLua (`.styluaignore`: `src/server/Net.luau`, `src/client/Net.luau`) e do selene (`exclude` em `selene.toml`).
- [x] **Step 2: Verify:** `bash scripts/check.sh` passa (luau-lsp aceita o código gerado); `require` dos dois módulos no Studio (Play pelo MCP) sem erro.
- [x] **Step 3: Commit** `feat: contrato de rede do inventário com Blink`.

### Task 3: InventoryService (servidor)

**Files:**
- Create: `src/server/Services/InventoryService.luau`, `src/server/Services/DevItemsService.luau`

**Interfaces:**
- Consumes: `Inventory` (Task 1), `Net` servidor (Task 2), `Defs`.
- Produces:
  - `InventoryService.get(player: Player): Inventory.Inventory?`
  - `InventoryService.give(player: Player, id: string, count: number): number` — valida o item em `Defs`, chama `Inventory.add`, manda deltas dos slots alterados, devolve sobra.
  - `InventoryService.take(player: Player, id: string, count: number): boolean` — idem com `remove`.
  - `InventoryService.selectedSlot(player: Player): number` e sinal simples `InventoryService.onSelected(fn: (Player, Slot?) -> ())` para o Task 5.
  - Handlers: `RequestInventory` → `InventorySync` do jogador; `MoveSlot(from, to)` → `Inventory.move` + deltas (inválido = ignorado); `SelectSlot(i)` → guarda a seleção e avisa `onSelected`. Capacidade = 10 + 6 se `Player:GetAttribute("HasBag")`; ao mudar o atributo, `setCapacity` + `InventoryCapacity`.
  - Inventário criado no `PlayerAdded` (e jogadores já presentes) e apagado no `PlayerRemoving`.
  - `DevItemsService` (só no Studio): ao entrar, dá `wood 24, stone 12, gold 5, berry 8, wood_pickaxe 1, stone_pickaxe 1, gold_pickaxe 1` e liga `HasBag`; cria `ServerStorage.DevGive` (`BindableFunction`: `(player, id, count) -> sobra`) para testes pelo MCP. Comentário: some quando a coleta existir.
- [x] **Step 1:** Implementar.
- [x] **Step 2: Verify:** check; Play pelo MCP: no servidor, `ServerStorage.DevGive:Invoke(player, "wood", 300)` devolve a sobra certa (pilhas de 255); o cliente recebeu os slots (ver Task 4).
- [x] **Step 3: Commit** `feat: inventário autoritativo no servidor com pedidos validados`.

### Task 4: Estado no cliente, hotbar e mochila ligadas ao inventário

**Files:**
- Create: `src/client/InventoryState.luau`, `src/client/UI/InventoryGrid.luau`
- Modify: `src/client/HotbarState.luau` (deixa de ter itens fixos), `src/client/UI/Hotbar.luau`, `src/client/UI/Backpack.luau`, `src/client/Controllers/HudController.luau`

**Interfaces:**
- Produces:
  - `InventoryState.slots: () -> { [number]: Slot }`, `InventoryState.capacity: () -> number`; liga `InventorySync`/`InventorySlot`/`InventoryCapacity` e dispara `RequestInventory` **depois** de ligar os ouvintes (Review Focus 3).
  - `HotbarState.slots` = slots 1–10 de `InventoryState`; `HotbarState.select(i)` também dispara `SelectSlot(i)`.
  - Mover no PC e no celular: **toque/clique na origem, depois no destino** (`InventoryState.pick: Source<number?>` guarda a origem; segundo toque dispara `MoveSlot(origem, destino)` e limpa; tocar de novo na origem cancela). A origem escolhida fica com borda `Theme.ui.warning`.
  - `InventoryGrid()`: grade 4×4 no painel da mochila com os slots 1–16; 11–16 aparecem trancados (fundo escuro, sem ícone) enquanto `capacity() < 16`. Hotbar e grade usam o mesmo componente de slot (extrair `UI/SlotButton.luau` do `Hotbar`).
- [x] **Step 1:** Implementar.
- [x] **Step 2: Verify:** check; Play pelo MCP: hotbar mostra os itens do `DevItemsService`; abrir a mochila (B) mostra 16 slots com 11–16 liberados (`HasBag`); clicar slot 1 e depois slot 12 move a madeira (servidor confirma pelo `InventoryService.get`); clicar slot de pedra e depois de madeira troca; `screen_capture` da grade.
- [x] **Step 3: Commit** `feat: hotbar e mochila ligadas ao inventário do servidor, mover com dois toques`.

### Task 5: Item na mão

**Files:**
- Create: `src/shared/Models/ToolModel.luau`, `src/server/Services/EquipService.luau`

**Interfaces:**
- Consumes: `InventoryService.onSelected`, `Defs`, `Palette`/`Theme`.
- Produces:
  - `ToolModel.build(itemId: string): Model?` — só para `category == "tool"` por enquanto: cabo (cilindro marrom `Palette.biome.forest[3]`) + cabeça (cunha/bloco na cor do tier), tamanho proporcional ao avatar de ~5 studs, peças sem colisão (`CanCollide/CanQuery/CanTouch = false`, `Massless = true`), com `PrimaryPart` = `Handle` e um `Attachment` "Grip". Outros itens → `nil`.
  - `EquipService`: ao selecionar, grava `Character:SetAttribute("Equipped", id)` (ou `nil` se o slot está vazio) e troca o modelo `HeldItem` soldado (`WeldConstraint`) à `RightHand`; refaz no `CharacterAdded` se houver item selecionado (Review Focus 4); limpa ao selecionar slot vazio ou item que não é ferramenta (Review Focus 5).
- [x] **Step 1:** Implementar.
- [x] **Step 2: Verify:** check; Play pelo MCP: tecla 5 (picareta de madeira) → `Equipped == "wood_pickaxe"` e `HeldItem` na mão; `screen_capture` mostra a picareta; tecla de slot vazio → sem modelo; resetar o personagem com a picareta selecionada → modelo volta.
- [x] **Step 3: Commit** `feat: ferramenta selecionada aparece na mão do personagem`.

### Task 6: Fechamento

- [x] **Step 1:** `docs/guia/inventario.md` (como o inventário funciona, fluxo de rede, como dar itens no Studio, como adicionar um modelo de ferramenta); `docs/guia/hud.md` e `arquitetura.md` atualizados (Blink, `Net`, `InventoryState`); remover menções a "itens fixos" no `HotbarState`.
- [x] **Step 2: Verify:** `bash scripts/check.sh`; `graphify update .`.
- [x] **Step 3: Commit** `docs: guia do inventário`.

**Fora desta fase:** largar item no chão, dividir pilha, arrastar com o dedo (toque-toque por enquanto), modelos de armas/capacetes/comida na mão, lentidão por arma (entram com combate), perda do inventário na morte (entra com morte/PvP).
