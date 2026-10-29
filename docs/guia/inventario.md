# Inventário

O inventário de cada jogador existe **só no servidor**. O cliente recebe uma cópia para desenhar a hotbar e a mochila, e para mudar algo ele **pede**: o servidor valida, aplica e manda de volta só o que mudou.

- 10 slots básicos (a hotbar = slots 1–10) + 6 da mochila (11–16), liberados quando o Player tem o atributo `HasBag = true` (mochila equipada). Sem mochila, o botão e o painel da mochila nem aparecem.
- O tamanho máximo de cada pilha vem de `Defs.Items[id].maxStack`. Itens que não existem em `Defs` são recusados.
- O inventário **não é salvo**: acaba junto com a partida.

## Onde fica cada coisa

| Arquivo | O que é |
|---|---|
| `src/shared/Inventory.luau` | Lógica pura (`new`, `add`, `remove`, `count`, `move`, `setCapacity`), testada no Lune (`tests/inventory.spec.luau`) |
| `net/game.blink` | Contrato de rede (Blink). Gera `src/server/Net.luau` e `src/client/Net.luau` |
| `src/server/Services/InventoryService.luau` | Inventário de cada jogador, valida os pedidos e manda as mudanças (deltas) |
| `src/server/Services/EquipService.luau` | Item selecionado na mão (atributo `Equipped` + modelo `HeldItem`) |
| `src/shared/Models/ToolModel.luau` | Modelo provisório de ferramenta (cabo + cabeça na cor do tier) |
| `src/server/Services/DevItemsService.luau` | Só no Studio: dá um kit de itens e cria `ServerStorage.DevGive` |
| `src/client/InventoryState.luau` | Cópia do inventário no cliente (fontes do Vide) |
| `src/client/DragState.luau` | Arrastar itens entre slots (toque × arrasto, slot debaixo do dedo, `MoveSlot`) |
| `src/client/UI/DragGhost.luau` | O item que segue o dedo durante o arrasto |
| `src/client/HotbarState.luau` | Slot selecionado; selecionar avisa o servidor |
| `src/client/BackpackState.luau` | Mochila equipada (`HasBag`) e painel aberto/fechado |
| `src/client/UI/SlotButton.luau` | Um slot (usado pela hotbar e pela grade) |
| `src/client/UI/InventoryGrid.luau` | Os 6 slots da mochila (11–16) dentro do painel |

## Fluxo de rede

```
Cliente                                  Servidor
InventoryState.start()
  liga os ouvintes ──────────────────────
  RequestInventory ─────────────────────▶ envia o inventário inteiro
                   ◀───────────────────── InventorySync { Capacity, Slots }
arrasta de um slot e solta em outro
  MoveSlot(de, para) ───────────────────▶ Inventory.move (inválido = ignorado)
                   ◀───────────────────── InventorySlot(i, slot|nil) para cada slot alterado
tecla 1…0 / toque na hotbar
  SelectSlot(i) ────────────────────────▶ guarda a seleção → EquipService põe na mão
HasBag muda       ◀───────────────────── InventoryCapacity(16)
```

- O cliente liga os ouvintes **antes** de pedir o inventário, então a resposta nunca chega sem ninguém ouvindo.
- O Blink já recusa dados com tipos ou faixas errados (índice fora de 1–16, slot da hotbar fora de 1–10). O `InventoryService` ainda confere a capacidade (slot 12 sem mochila), slot vazio e `de == para`.

## Mover itens

A hotbar mostra os slots 1–10 e a mochila (tecla **B** no PC, botão **Mochila** no celular, só com mochila equipada) mostra os slots 11–16.

1. Segure um slot com item e arraste: o item passa a seguir o dedo/mouse e o slot debaixo dele ganha borda amarela.
2. Solte em cima de outro slot (da hotbar ou da mochila): o servidor move.
   - Destino vazio: o item muda de slot.
   - Mesmo item: as pilhas se juntam até o `maxStack`, e o que sobra fica na origem.
   - Item diferente: os dois trocam de lugar.
3. Soltar fora de um slot cancela.

Um toque rápido (o dedo anda menos de 8 px) não é arrasto: num slot da hotbar, seleciona. A regra está em `UIMath.isDrag` (testada no Lune).

Com a mochila fechada, tocar num slot da hotbar só **seleciona**.

## Item na mão

Quando o jogador seleciona um slot, o `EquipService`:

- grava `Character:GetAttribute("Equipped")` com o id do item (ou `nil` se o slot está vazio);
- para ferramentas (`category = "tool"`), solda um modelo `HeldItem` na `RightHand`, alinhado ao `RightGripAttachment`;
- refaz tudo no respawn e quando o conteúdo do slot selecionado muda.

Outros itens (recursos, comida) ficam só no atributo, sem modelo.

## Dar itens no Studio

O `DevItemsService` (só no Studio) dá ao entrar: madeira 24, pedra 12, ouro 5, frutinha 8 e as três picaretas, e liga `HasBag`. Para dar mais, pela barra de comandos do **servidor**:

```lua
local player = game.Players:GetPlayers()[1]
print(game.ServerStorage.DevGive:Invoke(player, "wood", 300)) -- imprime o que não coube
```

Em código do servidor, use `InventoryService.give(player, id, count)` (devolve a sobra) e `InventoryService.take(player, id, count)` (tudo ou nada).

## Adicionar um modelo de ferramenta

1. Crie o item em `Defs/Items.luau` com `category = "tool"` (veja `adicionar-item.md`). Ele já aparece na mão com o modelo provisório, na cor do tier.
2. Para um formato próprio, mude `ToolModel.build`: devolva um `Model` com `PrimaryPart` = `Handle`, um `Attachment` chamado `Grip` no cabo (Y = ao longo do cabo, X = lado da cabeça) e todas as peças com `CanCollide/CanQuery/CanTouch = false` e `Massless = true`.

## Mudando o contrato de rede

Edite `net/game.blink` e rode `bash scripts/check.sh` (ele roda o `blink net/game`). Os arquivos `Net.luau` gerados vão para o commit, mas não passam por StyLua nem selene.
