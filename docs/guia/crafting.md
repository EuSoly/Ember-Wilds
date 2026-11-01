# Crafting

O crafting transforma os recursos coletados em ferramentas, armas, armaduras e peças de base. A grade de quatro colunas à esquerda da HUD mostra receitas cujos materiais você tem e cuja estação requerida está perto. Clique ou toque para começar. O livro de receitas mostra todas as receitas e destaca em vermelho os materiais que faltam.

## Como funciona

- Os materiais são retirados do inventário quando o craft começa. O resultado entra ao terminar.
- Só é permitido um craft por vez. O boneco pode andar, trocar o item da mão e comer, mas não ataca, não coleta e não veste armadura ou mochila enquanto crafta.
- O tempo é fixado ao começar: trocar o Livro de mão no meio não muda nada.
- No PC, botão direito cancela. No celular, toque outra vez no ícone que está craftando. O cancelamento devolve os ingredientes.
- Morrer cancela o craft sem devolução; a morte já zera o inventário.
- Segurar o Livro ao iniciar deixa o craft três vezes mais rápido. O livro não é consumido.
- Bancada e fogo são conferidos ao começar, em um raio horizontal de 10 studs. Andar para longe não cancela o craft.
- O servidor valida a receita, a estação, os materiais e o espaço no inventário antes de cobrar qualquer coisa.
- **Craft é segredo:** só quem crafta vê a engrenagem e a barra. Saber que o outro está craftando seria vantagem de combate, então o estado não fica em atributos (que replicam para todos): o servidor guarda em `CraftService` e manda só para o dono pelo evento `Net.CraftProgress`. No servidor, pergunte `CraftService.isCrafting(player)`.

## Receitas

Os tempos abaixo são sem o Livro. “Bancada” e “Fogo” indicam a estação que deve estar perto.

| Resultado | Materiais | Tempo | Estação |
|---|---|---:|---|
| Picareta de madeira | 10 madeira | 5 s | — |
| Picareta de pedra | 50 madeira, 15 pedra, picareta de madeira | 15 s | Bancada |
| Picareta de ouro | 40 madeira, 30 pedra, 20 ouro, picareta de pedra | 20 s | Bancada |
| Picareta de diamante | 60 madeira, 40 pedra, 30 ouro, picareta de ouro | 30 s | Bancada |
| Picareta de ametista | 80 madeira, 60 pedra, 45 ouro, picareta de diamante | 40 s | Bancada |
| Picareta de reidite | 100 madeira, 80 pedra, 60 ouro, picareta de ametista | 50 s | Bancada |
| Espada de madeira | 30 madeira | 5 s | — |
| Espada de pedra | 50 madeira, 25 pedra, espada de madeira | 15 s | Bancada |
| Espada de ouro | 60 madeira, 50 pedra, 40 ouro, espada de pedra | 20 s | Bancada |
| Lança de madeira | 40 madeira | 5 s | — |
| Lança de pedra | 60 madeira, 10 pedra, lança de madeira | 15 s | Bancada |
| Lança de ouro | 80 madeira, 30 pedra, 30 ouro, lança de pedra | 20 s | Bancada |
| Capacete de madeira | 50 madeira | 5 s | — |
| Capacete de pedra | 75 madeira, 75 pedra, capacete de madeira | 20 s | Bancada |
| Capacete de ouro | 90 madeira, 90 pedra, 90 ouro, capacete de pedra | 20 s | Bancada |
| Bancada | 30 madeira, 10 pedra | 10 s | — |
| Fogueira | 25 madeira, 5 pedra | 10 s | — |
| Fogueira grande | 35 madeira, 10 pedra, fogueira | 15 s | — |
| Parede de madeira | 20 madeira | 5 s | Bancada |
| Parede de pedra | 17 pedra | 5 s | Bancada |
| Parede de ouro | 14 ouro | 5 s | Bancada |
| Porta de madeira | 30 madeira | 8 s | Bancada |
| Porta de pedra | 27 pedra, porta de madeira | 8 s | Bancada |
| Porta de ouro | 24 ouro, porta de pedra | 8 s | Bancada |
| Espinho de madeira | 40 madeira, 30 pedra, parede de madeira | 20 s | Bancada |
| Espinho de pedra | 70 pedra, parede de pedra | 20 s | Bancada |
| Espinho de ouro | 40 ouro, 30 pedra, parede de ouro | 20 s | Bancada |
| Baú | 25 madeira, 2 ouro | 20 s | Bancada |
| Papel | 20 madeira | 5 s | Fogo |
| Livro | 4 papel, 10 ouro (provisória) | 30 s | Bancada |
| Protetor de orelha | 30 madeira, 5 ouro (provisória) | 10 s | Bancada |
| Mochila | 60 madeira, 20 pedra, 5 ouro (provisória) | 15 s | Bancada |

Livro, protetor e mochila usam receitas provisórias até os mobs existirem (no Starve: pele de lobo/coelho e linha). As picaretas de diamante, ametista e reidite também são provisórias: ainda não pedem o próprio minério, que não existe no mapa. Os números e ingredientes ficam em `src/shared/Defs/Recipes.luau`.

## Vestir armadura e mochila

Com um capacete, protetor de orelha ou mochila selecionado na mão, aperte o botão de usar. O item vestido anteriormente volta ao inventário. A troca não acontece se não houver espaço para guardar a peça antiga ou se a nova mochila reduzir a capacidade sobre slots ocupados.

Capacetes reduzem dano de combate (valores provisórios: 10%, 20% e 30% por tier). O protetor multiplica a perda de frio por 0,7. O combate ainda não está implementado.

## Como adicionar uma receita

1. Defina o item de resultado em `src/shared/Defs/Items.luau`, com `category`, `tier` e `maxStack` adequados.
2. Acrescente `item.<id>` em `src/shared/Strings/ptBR.luau`.
3. Acrescente uma entrada em `src/shared/Defs/Recipes.luau`: `result` é o id do item, `count` é a quantidade, `ingredients` é a lista `{ id, count }`, `time` é em segundos, `station` é opcional (`"workbench"` ou `"fire"`) e `order` é uma posição única no livro.
4. Rode `bash scripts/check.sh`; a validação exige que todos os itens existam, que os números sejam válidos e que a ordem não se repita.

Para dar velocidade ao craft de um item segurado, use `category = "misc"` e `craftSpeed` maior que 1. O Livro tem `craftSpeed = 3`.

## Estações e comandos de teste

Uma estação é uma **peça colocada** (veja `construcao.md`): a bancada e as fogueiras, depois de colocadas, ganham a tag `CraftStation` e o atributo `Station` igual a `"workbench"` ou `"fire"`, vindos do bloco `structure` do item. A fogueira some sozinha, então a estação de fogo some junto.

Para testar no Studio, use o Command Bar no servidor: dê a peça e coloque no chão (selecione o slot e solte o clique).

```lua
game.ServerStorage.DevGive:Invoke(player, "workbench", 1)
game.ServerStorage.DevGive:Invoke(player, "campfire", 1)
game.ServerStorage.DevGive:Invoke(player, "wood", 100)
```

Os antigos `DevWorkbench` e `DevCampfire` foram removidos.
