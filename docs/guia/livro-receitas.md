# Livro de receitas

O livro abre pelo botão redondo do livro no HUD (`RecipeBookButton`) e só aparece jogando. Ele **só mostra informação**: craftar continua pela coluna de receitas (`CraftColumn`).

- **Abas** em cima: Ferramentas, Armas, Armaduras, Comida, Construções, Recursos.
- **Grade** à esquerda com os itens da aba. O item que ainda não dá para fazer agora (falta material ou estação por perto) fica escurecido, mas abre a ficha igual.
- **Ficha** à direita, num papel, com o item selecionado. Reabre na última aba e no último item da sessão.

## O que a ficha mostra

| Seção | De onde vem |
|---|---|
| Nome e material · categoria | `Defs/Items` (`nameKey`, `tier`, `category`) |
| Como fazer | ingredientes da receita (`Defs/Recipes`); clicar num ingrediente abre a ficha dele, trocando de aba |
| Precisa de | estação da receita (`station`) pela tabela `BookInfo.STATIONS` e o tempo (`CraftRules.duration`, sem item na mão) |
| Dados | todas as linhas do `UIFlow/ItemInfo` (a dica do item mostra só 3) |
| Onde conseguir | mobs que deixam o item (`Defs/Mobs` → `loot`, com o retrato 3D do `Assets.Mobs`) e recursos do mapa que dão o item na coleta (`Defs/Resources` → `gather`, com a ferramenta mínima) |
| Serve para | itens cujas receitas usam este; clicar abre a ficha |

Seção sem conteúdo não aparece. **Nada é escrito à mão**: item, receita, mob ou recurso novo entra no livro sozinho.

### Que item vai em que aba

| Aba | Itens |
|---|---|
| Ferramentas | categoria `tool` e `misc` (livro, balde) |
| Armas | `weapon` |
| Armaduras | `armor` e `bag` |
| Comida | `food` |
| Construções | `placeable` |
| Recursos | todo item sem receita e os de categoria `resource` com receita (ex. papel) |

Um item pode estar em mais de uma aba (a frutinha está em Comida e em Recursos). A pedrinha do mapa é só decoração (não tem `gather`) e não aparece.

### Estação nova (ex. água)

"Precisa de" é montado só pela tabela `BookInfo.STATIONS` (texto e ícone). A água já está lá ("Perto da água"): quando a primeira receita com `station = "water"` existir (regra de jogo: tipo `CraftStation`, `CraftService`/`CraftRules`, `Validate`, `CraftState`), o livro mostra sozinho.

## Arquivos

| Arquivo | O que é |
|---|---|
| `src/shared/UIFlow/BookInfo.luau` | Regras puras (testadas em `tests/bookinfo.spec.luau`): `TABS`, `items`, `firstTab`, `recipeOf`, `craft`, `stats`, `STATIONS`, `sources`, `usedIn`, `craftableNow` |
| `src/client/Screens/RecipeBookScreen.luau` | A tela: moldura, abas, grade; `open`, `toggle`, `show(itemId)`, `mount` |
| `src/client/UI/BookSheet.luau` | A ficha (remontada a cada item) |
| `src/client/UI/MobPortrait.luau` | Retrato 3D do mob |
| `src/shared/BookImages.luau` | Ids das artes; id vazio = desenho por código |

## Artes

Arte do Elizeu (09/11), em `assets/ui/book/`, recortada por `assets/ui/book/prepare_book.py` a partir da pasta "Livro de Craft". Têm id: abas (normal e selecionada), papel, X de fechar, os 6 ícones das abas, os selos de bancada, fogo, água e relógio, os 4 recursos do mapa (árvore, rocha, veio de ouro, arbusto) e os 7 ícones dos dados (dano, dano em construções, velocidade, presa na mão, defesa, alcance, nível de picareta). Frio, vida, fome, sede e mochila usam os ícones do HUD. Os selos das abas no octógono (`badge_tools.png` etc.) e a gota solta (`icon_water.png`) foram recortados mas não são usados.

Para trocar uma arte: substitua o PNG, envie para o Roblox e troque o id no `BookImages`; se o tamanho de uma peça esticável mudar (aba, papel), ajuste o `SLICED` dela.

O molde `RecipeBook` em `UITemplates` (Studio) não é mais usado pelo livro.
