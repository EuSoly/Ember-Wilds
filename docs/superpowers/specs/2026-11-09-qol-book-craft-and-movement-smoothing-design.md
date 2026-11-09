# QoL: auto-equipar livro no craft + suavização de movimento (client-side)

Data: 2026-11-09
Branch: `qol/book-craft-and-movement-smoothing`

Duas melhorias de qualidade de vida, independentes entre si.

---

## Feature 1 — Auto-equipar o livro ao craftar

### Problema
O item `book` (`src/shared/Defs/Items.luau:555`) dá `craftSpeed = 3` (craft 3× mais
rápido), mas o bônus só vale se o jogador **manualmente** selecionar o slot do livro
na hotbar antes de craftar. O servidor calcula a duração a partir do item na mão
(`src/server/Services/CraftService.luau:122-125`).

### Objetivo
Se houver um livro na hotbar, ao iniciar um craft o cliente seleciona o livro
automaticamente (o jogador vê o slot do livro realçar e o boneco segurá-lo) e,
ao terminar/cancelar, volta para o slot que estava selecionado antes.

### Decisões (confirmadas com o usuário)
- **Troca manual no meio do craft:** respeitar. Só restaura se, ao terminar, o slot
  selecionado ainda for o do livro. Se o jogador trocou de propósito, não força a volta.
- **Crafts em sequência:** por craft individual (equipa no início de cada craft,
  restaura no fim de cada craft).
- **Escopo:** comportamento do cliente local (quem está craftando).

### A corrida que precisa ser resolvida
O cliente dispara `SelectSlot(livro)` e `RequestCraft(id)` no mesmo frame. Pelo Blink,
os dois eventos vão no mesmo buffer, **na ordem de disparo**, e o servidor os processa
em ordem: `onSelect` (síncrono) atualiza `selected[player]` **antes** de `start()` rodar.
Porém `CraftService.start` hoje lê o **atributo** `Equipped`, que o `EquipService`
grava via `task.defer` (`src/server/Services/EquipService.luau:40-52`) — ou seja, 1 ciclo
atrasado. Resultado: sem correção, o craft recém-pedido usaria o item **antigo**.

### Mudanças

**Servidor — `src/server/Services/CraftService.luau` (~linha 122):**
Ler o item na mão pelo **slot selecionado** (síncrono), não pelo atributo deferido:
```lua
local heldSlot = inv.slots[InventoryService.selectedSlot(player)]
local held = if heldSlot then Defs.Items[heldSlot.id] else nil
```
Equivalente ao atributo no jogo normal (o atributo espelha o slot selecionado), mas
imediato — o livro selecionado no mesmo frame já conta para a velocidade. É também a
leitura mais correta (remove um atraso latente de 1 frame).

**Cliente — `src/client/CraftState.luau`:**
- Novo estado de módulo `bookRestore: { prev, bookSlot, requestedAt, confirmed }?`.
- Helper `findBookSlot()`: varre `InventoryState.slots()` nos índices `1..HOTBAR_SLOTS`
  procurando `id == "book"`; retorna o índice ou `nil`.
- Em `CraftState.start(id)`, no ramo que inicia um craft novo (não o cancelamento):
  acha o slot do livro; se existir, não for o selecionado e a hotbar não estiver
  travada (`HotbarState.isLocked()`), guarda `prev = HotbarState.selected()`, marca
  `bookRestore` e chama `HotbarState.select(bookSlot)` **antes** de `Net.RequestCraft.Fire(id)`.
- No handler de `Net.CraftProgress`: se veio receita, `bookRestore.confirmed = true`;
  se veio `nil` (craft acabou/cancelou), chama `restoreBook()`.
- `restoreBook()`: se `bookRestore` existe, limpa e — **só se** `HotbarState.selected()`
  ainda é o slot do livro e não está travado — chama `HotbarState.select(prev)`.
- Rede de segurança no loop de polling (já roda a cada 0.1s): se `bookRestore` existe,
  não foi confirmado, `current()` é `nil` e passou `REJECT_GRACE` (~0.5s) desde o pedido,
  chama `restoreBook()` (cobre craft rejeitado pelo servidor, que não manda `CraftProgress`).

### O que NÃO muda
- A autoridade do craft continua no servidor. `CraftRules.duration` não muda.
- A UI de "Recipe Book" (tela de consulta) não tem relação com isto.

---

## Feature 2 — Suavização de movimento client-side (outros jogadores)

### Problema
Os bonecos dos **outros jogadores** dão "snap" direto para o `HumanoidRootPart`
replicado a cada frame (`src/client/Boneco/BonecoRenderer.luau:437`), o que treme em
rede. Os **mobs já têm** suavização exponencial (`src/client/Mobs/MobRenderer.luau:121-128`).

### Objetivo
Replicar o padrão dos mobs nos bonecos, para testar o resultado e tunar. O **jogador
local fica 1:1** (é previsto/network-owned; suavizar adicionaria lag no próprio movimento).

### Mudanças

**`src/shared/BonecoConfig.luau`** — novos campos (espelhando os mobs):
- `ROOT_SMOOTHING = 15` — 1/s; maior = segue a posição mais rápido.
- `TELEPORT_DISTANCE = 30` — studs; salto maior que isso não desliza (renasceu/teleporte).

**`src/client/Boneco/BonecoRenderer.luau`:**
- Campo `displayed: CFrame` no `Entry` (struct ~49-80), iniciado em `hrp.CFrame` no
  `build` (~254), resetado em `refreshRoot` quando reacha a raiz (~402) e na transição
  escondido→visível (~429-431).
- Em `update` (~437), em vez de `target = entry.hrp.CFrame`:
  ```lua
  local goal = entry.hrp.CFrame
  local isLocal = entry.character == Players.LocalPlayer.Character
  local target
  if isLocal then
      target = goal                 -- local: 1:1, sem lag artificial
      entry.displayed = goal
  else
      local alpha = 1 - math.exp(-C.ROOT_SMOOTHING * math.clamp(dt, 0, C.MAX_DT))
      target = if (goal.Position - entry.displayed.Position).Magnitude > C.TELEPORT_DISTANCE
          then goal
          else entry.displayed:Lerp(goal, alpha)
      entry.displayed = target
  end
  ```
- A velocidade da animação passa a sair de `target` (igual ao MobRenderer), para a
  animação de andar continuar casada com o movimento mostrado.

### Teste / tuning
Sem teste unitário (é sensação visual). Avaliar no Studio com `rojo serve` e ajustar
`ROOT_SMOOTHING`/`TELEPORT_DISTANCE`. Começar em 15/30 (igual aos mobs).

---

## Testes

- Feature 1: teste puro em Lune para `findBookSlot` (dado um mapa de slots, acha o
  índice do livro dentro da hotbar; ignora livro fora da hotbar; `nil` sem livro).
  A lógica de rede/UI é verificada no Studio.
- Feature 2: verificação visual no Studio (dois clientes / DevCrowd).

## Fora de escopo
- Mudar o balanceamento do `craftSpeed` do livro.
- Suavizar o jogador local ou os mobs (os mobs já têm; o local fica 1:1 de propósito).
