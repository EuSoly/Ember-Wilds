# Inventário

O inventário de cada jogador existe **só no servidor**. O cliente recebe uma cópia para desenhar a hotbar e a mochila, e para mudar algo ele **pede**: o servidor valida, aplica e manda de volta só o que mudou.

- Capacidade = 10 slots básicos (a hotbar = slots 1–10) + os slots da **mochila vestida** + o bônus do **gamepass VIP**, até no máximo 40. Os números ficam em `src/shared/InventoryConfig.luau`.
- Os slots além da hotbar aparecem no painel da mochila. Sem mochila (e sem gamepass), o botão e o painel nem aparecem.
- O tamanho máximo de cada pilha vem de `Defs.Items[id].maxStack`. Itens que não existem em `Defs` são recusados.
- O inventário **não é salvo**: acaba junto com a partida.

## Onde fica cada coisa

| Arquivo | O que é |
|---|---|
| `src/shared/InventoryConfig.luau` | Base (10), hotbar (10), máximo (40) e o gamepass VIP (ID e slots extras) |
| `src/shared/Inventory.luau` | Lógica pura (`new`, `add`, `remove`, `count`, `move`, `setCapacity`, `capacityFor`), testada no Lune (`tests/inventory.spec.luau`) |
| `net/game.blink` | Contrato de rede (Blink). Gera `src/server/Net.luau` e `src/client/Net.luau` |
| `src/server/Services/InventoryService.luau` | Inventário de cada jogador, valida os pedidos, manda as mudanças (deltas), veste mochilas (`equipBag`) e soma o gamepass |
| `src/server/Services/EquipService.luau` | Item selecionado na mão (só o atributo `Equipped` no personagem) |
| `src/shared/Models/ToolModel.luau` | Modelo da ferramenta na mão: clone de `ReplicatedStorage.Assets.Tools.<id>` (só no place), desenhado pelo cliente |
| `src/server/Services/DevItemsService.luau` | Só no Studio: dá um kit, veste a Mochila de Couro e cria `ServerStorage.DevGive` e `DevEquipBag` |
| `src/client/InventoryState.luau` | Cópia do inventário no cliente (fontes do Vide) |
| `src/client/DragState.luau` | Arrastar itens entre slots (toque × arrasto, slot debaixo do dedo, `MoveSlot`) |
| `src/client/UI/DragGhost.luau` | O item que segue o dedo durante o arrasto |
| `src/client/HotbarState.luau` | Slot selecionado; selecionar avisa o servidor |
| `src/client/BackpackState.luau` | Se há slots além da hotbar (`hasBag`, vem da capacidade) e painel aberto/fechado |
| `src/client/UI/SlotButton.luau` | Um slot (usado pela hotbar e pela grade) |
| `src/client/UI/InventoryGrid.luau` | Os slots além da hotbar (11 até a capacidade), 3 por linha, rolando acima de 3 linhas |

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
mochila/gamepass  ◀───────────────────── InventoryCapacity(n)
```

- O cliente liga os ouvintes **antes** de pedir o inventário, então a resposta nunca chega sem ninguém ouvindo.
- O Blink já recusa dados com tipos ou faixas errados (índice fora de 1–40, slot da hotbar fora de 1–10). O `InventoryService` ainda confere a capacidade (slot 12 sem mochila), slot vazio e `de == para`.

## Mover itens

A hotbar mostra os slots 1–10 e a mochila (tecla **B** no PC, botão **Mochila** no celular, só com mochila vestida ou gamepass) mostra os slots de 11 em diante.

1. Segure um slot com item e arraste: o item passa a seguir o dedo/mouse e o slot debaixo dele ganha borda amarela.
2. Solte em cima de outro slot (da hotbar ou da mochila): o servidor move.
   - Destino vazio: o item muda de slot.
   - Mesmo item: as pilhas se juntam até o `maxStack`, e o que sobra fica na origem.
   - Item diferente: os dois trocam de lugar.
3. Soltar fora de um slot cancela.

Um toque rápido (o dedo anda menos de 8 px) não é arrasto: num slot da hotbar, seleciona. A regra está em `UIMath.isDrag` (testada no Lune).

Tocar num slot da hotbar só **seleciona**; mover é sempre arrastando.

> Tirar a mochila exige que os slots **do fim** do inventário estejam vazios (os que vão sumir). Com o gamepass VIP, esses são os 3 do bônus e os últimos da mochila, não necessariamente os primeiros slots da mochila.

## Item na mão

Quando o jogador seleciona um slot, o `EquipService` **só** grava o atributo `Equipped` no personagem com o id do item (ou `nil` se o slot está vazio). Refaz no respawn e quando o conteúdo do slot selecionado muda.

O modelo da ferramenta não existe no servidor: cada cliente lê o `Equipped` e desenha a ferramenta na mão direita do boneco visual (`BonecoModel.setHeldItem`, com o `ToolModel`). Assim todos veem o item na mão de todos. Outros itens (recursos, comida) ficam só no atributo, sem modelo. Veja `boneco.md`.

## Dar itens no Studio

O `DevItemsService` (só no Studio) dá ao entrar: madeira 24, pedra 12, ouro 5, frutinha 8 e as três picaretas, e veste a Mochila de Couro. Para testar mais, pela barra de comandos do **servidor**:

```lua
local player = game.Players:GetPlayers()[1]
print(game.ServerStorage.DevGive:Invoke(player, "wood", 300)) -- imprime o que não coube
print(game.ServerStorage.DevEquipBag:Invoke(player, nil)) -- tira a mochila (false se ela tem itens)
print(game.ServerStorage.DevEquipBag:Invoke(player, "leather_bag")) -- veste de novo
```

Em código do servidor, use `InventoryService.give(player, id, count)` (devolve a sobra) e `InventoryService.take(player, id, count)` (tudo ou nada).

## Mochilas

Mochilas são itens com `category = "bag"` e `bagSlots` (quantos slots dão). Vestida, a mochila **não ocupa slot**; o servidor guarda qual é (atributo `Bag` do Player, com o id) e recalcula a capacidade.

Para adicionar uma mochila nova num update, é só uma entrada em `Defs/Items.luau` (e o texto em `Strings/ptBR.luau`):

```lua
big_bag = {
	id = "big_bag",
	nameKey = "item.big_bag",
	category = "bag",
	maxStack = 1,
	bagSlots = 12, -- até 30 (40 do máximo − 10 da base)
},
```

A grade da mochila se ajusta sozinha à nova capacidade. Para vestir, o servidor chama `InventoryService.equipBag(player, "big_bag")` (hoje só o kit de teste chama; depois, o crafting/equipamentos). Trocar por uma mochila menor, ou tirar, só funciona se os slots que vão sumir estiverem vazios, para nenhum item se perder.

## Gamepass VIP (slots extras)

Em `src/shared/InventoryConfig.luau`:

```lua
vipPass = { gamePassId = 0, bonusSlots = 3 },
```

Com `gamePassId = 0` o bônus fica desligado. Para ligar: crie o gamepass no Creator Hub, copie o ID e coloque em `gamePassId`. O servidor confere o passe quando o jogador entra (`UserOwnsGamePassAsync`) e também libera na hora quando ele compra durante a partida. Os slots extras aparecem no painel da mochila, mesmo sem mochila vestida. Mantenha o bônus pequeno: slot a mais é uma vantagem leve num jogo com PvP.

## Adicionar um modelo de ferramenta

1. Crie o item em `Defs/Items.luau` com `category = "tool"` (veja `adicionar-item.md`). Ele já aparece na mão do boneco com o modelo provisório, na cor do tier.
2. Para um formato próprio, mude `ToolModel.build`: devolva um `Model` com `PrimaryPart` = `Handle`, um `Attachment` chamado `Grip` no cabo (Y = ao longo do cabo, X = lado da cabeça) e todas as peças com `CanCollide/CanQuery/CanTouch = false` e `Massless = true`.

## Mudando o contrato de rede

Edite `net/game.blink` e rode `bash scripts/check.sh` (ele roda o `blink net/game`). Os arquivos `Net.luau` gerados vão para o commit, mas não passam por StyLua nem selene.
