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
- `nameKey` (ou `rarityKey` de tier) sem texto em `Strings`.

Se algo estiver errado, o jogo para no início com a lista de erros no Output, em vez de quebrar no meio da partida.

## Cores

A cor de um item com tier vem do tier (`Defs/Tiers.luau`), que vem da `Palette` (`src/shared/Palette.luau`). Para mudar a cor de um tier, mude só a `Palette`.
