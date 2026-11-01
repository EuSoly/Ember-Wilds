# Como adicionar um item

Itens são **dados**: nenhum sistema conhece um item pelo nome. Para criar um item novo você mexe em dois arquivos.

## 1. A definição — `src/shared/Defs/Items.luau`

```lua
diamond_pickaxe = {
	id = "diamond_pickaxe",          -- igual à chave; só a-z, 0-9 e _
	nameKey = "item.diamond_pickaxe", -- chave do texto em Strings
	category = "tool",               -- resource | food | tool | weapon | armor | placeable | misc
	tier = "diamond",                -- opcional; precisa existir em Defs/Tiers.luau
	maxStack = 1,                    -- inteiro >= 1
},
```

### Comida e armadura

Comida (`category = "food"`) precisa do bloco `food`, com o que repõe ao comer (0 a 100 cada):

```lua
berry = { id = "berry", nameKey = "item.berry", category = "food", maxStack = 255, food = { hunger = 10 } },
```

Armadura (`category = "armor"`) precisa do bloco `armor` (todos os campos opcionais):

```lua
wood_helmet = {
	id = "wood_helmet", nameKey = "item.wood_helmet", category = "armor", tier = "wood", maxStack = 1,
	armor = { defense = 0.2 },  -- corta 20% do dano de combate (máx. 0,9)
},
coat = {
	id = "coat", nameKey = "item.coat", category = "armor", maxStack = 1,
	armor = { coldFactor = 0.5 },  -- o frio cai na metade da velocidade (0 a 2; também hungerFactor, thirstFactor e heatFactor)
},
```

Veja `sobrevivencia.md`.

Picareta (`category = "tool"`) ganha `pickaxe = { level = n }`: quanto maior o nível, mais pega por golpe e mais duros os recursos que ela coleta. Veja `coleta.md`.

### Peça de construção e dano em construção

Peça colocada no chão (`category = "placeable"`) precisa do bloco `structure`. Só o `kind` decide o comportamento (`wall`, `door`, `spike`, `station`, `chest`, `fire`):

```lua
wood_spike = {
	id = "wood_spike", nameKey = "item.wood_spike", category = "placeable", tier = "wood", maxStack = 255,
	structure = { kind = "spike", health = 150, spikeDamage = 10 },
},
```

Campos: `health` (vida máxima, obrigatório), `size` (células por lado, padrão 1), `spikeDamage` (obrigatório no `spike`), `lifetime` e `heatRadius` (obrigatórios no `fire`), `station` (`"workbench"` ou `"fire"`, a estação que a peça oferece). Qualquer item pode ter `structureDamage` (maior que 0): o dano do golpe em peça de construção; sem ele vale o golpe de mão (5). Veja `construcao.md`.

### Receita e velocidade de crafting

Para craftar o item, acrescente uma entrada com o mesmo id em `src/shared/Defs/Recipes.luau` e escolha materiais, tempo, estação e ordem no livro. Veja `crafting.md` para o formato e as receitas existentes.

Itens `category = "misc"` podem ter `craftSpeed` maior que 1. Esse valor divide o tempo da receita quando o item está na mão; o Livro usa `craftSpeed = 3`.

O `id` vai para o save do jogador, então **nunca renomeie um id já publicado**. Se precisar, crie um novo e faça uma migração.

## 2. O texto — `src/shared/Strings/ptBR.luau`

```lua
["item.diamond_pickaxe"] = "Picareta de Diamante",
```

## 3. Verificar

```bash
bash scripts/check.sh
```

A validação (`src/shared/Defs/Validate.luau`) roda no boot do jogo e nos testes. Ela reprova:

- `id` diferente da chave, ou com maiúsculas e símbolos;
- `tier` que não existe em `Tiers`;
- `maxStack` menor que 1 ou não inteiro;
- comida sem `food`, armadura sem `armor`, ou esses blocos em outra categoria, ou valores fora da faixa;
- `nameKey` (ou `rarityKey` de tier) sem texto em `Strings`.

Se algo estiver errado, o jogo para no início com a lista de erros no Output, em vez de quebrar no meio da partida.

## Cores

A cor de um item com tier vem do tier (`Defs/Tiers.luau`), que vem da `Palette` (`src/shared/Palette.luau`). Para mudar a cor de um tier, mude só a `Palette`.
