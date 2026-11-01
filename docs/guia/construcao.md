# Construção

As peças de base (bancada, fogueiras, paredes, portas, espinhos e baú) são colocadas no chão, do jeito do Starve.io. Cada peça tem dono, vida e comportamento próprios, tudo vindo de dados. O servidor decide tudo: o cliente só mostra um fantasma e pede para construir.

## Como colocar

1. Crafte a peça (veja `crafting.md`) e selecione o slot dela na hotbar.
2. Um **fantasma** aparece no chão, na grade, à frente do boneco: verde se pode construir, vermelho se não pode. É só uma aproximação do cliente; quem decide é o servidor.
3. **PC:** solte o clique (botão de usar). **Celular:** solte o joystick direito. Posição inválida não gasta nada.
4. Para parar de construir, troque de slot. Com uma peça na mão, o golpe não bate (só constrói).

O servidor recusa e não gasta nada se: a peça não está na mão, a célula está ocupada, está longe, tem jogador, recurso ou água em cima, ou o limite foi atingido.

## Grade e alcance

| Número | Valor | Onde |
|---|---:|---|
| Célula | 4×4 studs | `BuildRules.CELL` |
| Alcance até a célula-alvo | 5,5 studs | `BuildRules.REACH` |
| Golpe de mão em peça | 5 de dano | `BuildRules.HAND_DAMAGE` |
| Intervalo do espinho | 1 s por espinho/vítima | `BuildRules.SPIKE_INTERVAL` |
| Limite de peças por jogador | sem limite (`nil`) | `BuildRules.MAX_PER_PLAYER` |

O alcance é meia célula + o raio do corpo (1,5) + meia célula: a célula-alvo fica sempre à frente do corpo, e o próprio construtor nunca a bloqueia. Toda peça ocupa uma célula nesta fase; o campo `size` já existe para peças maiores no futuro. As regras puras estão em `src/shared/Build/BuildRules.luau` (testadas no Lune).

## Vida e dano em construção

Cada peça tem vida (atributos de vida e vida máxima). Qualquer jogador pode bater nela com o golpe de coleta (um a cada 0,5 s): o golpe acerta o que estiver mais perto à frente, recurso ou peça. Com vida 0, a peça some e a célula é liberada. Ao levar dano, a peça mostra uma barrinha de vida por 3 s (`StructureHealth`).

O dano do golpe vem de `structureDamage` no item da mão (sem o campo, vale 5, a mão).

| Na mão | Dano por golpe |
|---|---:|
| Nada / item sem `structureDamage` | 5 |
| Picareta de madeira / pedra / ouro | 10 / 15 / 20 |
| Picareta de diamante / ametista / reidite | 25 / 30 / 35 |
| Espada ou lança de madeira / pedra / ouro | 5 / 7,5 / 10 |

Valores provisórios. Quando o martelo chegar, é só um item com `structureDamage` alto.

| Peça | Vida |
|---|---:|
| Parede e porta de madeira / pedra / ouro | 1000 / 1500 / 2000 |
| Espinho de madeira / pedra / ouro | 150 / 300 / 600 |
| Bancada | 300 |
| Baú | 500 |
| Fogueira / fogueira grande | 150 / 300 |

## Porta

O dono (e, no futuro, o time) bate na porta e ela abre ou fecha; aberta, deixa passar. Ela **não fecha com alguém dentro**. Quem não é aliado, batendo, só tira vida: nunca abre.

## Espinho

Fere quem encosta, menos o dono e os aliados. O `SpikeService` varre a 5 Hz as células vizinhas (não usa `Touched`), com margem de 1,8 studs. Cada espinho fere cada vítima no máximo 1× por segundo, então três espinhos em volta ferem três vezes mais. O dano é do tipo `"combat"` (o capacete protege) e a morte tem causa "Espinho".

| Espinho | Dano por toque |
|---|---:|
| Madeira / pedra / ouro | 10 / 20 / 30 |

## Fogo

A fogueira colocada esquenta, queima quem pisa no centro e serve de estação `"fire"` do crafting. Ela **some sozinha**: fogueira em 2 min (`lifetime = 120`), fogueira grande em 6 min (`lifetime = 360`, calor de raio 18).

## Baú

- Guarda **um tipo de item só**, até 9999 (`ChestRules.MAX`). Vazio aceita qualquer item.
- Chegando perto (até 8 studs do centro, `ChestRules.RANGE`), o painel do baú aparece sobre a hotbar e cada slot ganha um **"+"**.
- Clicar no "+" põe 1; Shift+clique põe 10 (no celular, segurar o "+"). Clicar no item do baú tira o que couber no inventário.
- Qualquer jogador pode usar (baú sem cadeado). Vários ao mesmo tempo veem a quantidade atualizada.
- O conteúdo some junto com o baú (destruído, dono morto ou saído).
- O servidor (`ChestService`) é o dono do conteúdo. Os eventos `ChestPut` e `ChestTake` só pedem; ele confere distância, posse, tipo e quantidade (inteiro positivo), tem limite de taxa e troca tudo sem pausa no meio, o que serializa dois jogadores no mesmo baú.

## Dono e revive

Toda peça guarda o dono e a vida dele. Quando o dono **morre ou sai do jogo**, o `StructureService.removeOwned` apaga todas as peças dele e libera as células (a morte chama pelo `DeathService`, a saída também). Um revive futuro só não chama `removeOwned`, e as peças ficam. Uma peça apagada por fora (pelo Studio, por exemplo) também libera a célula.

"Aliado" é uma função única, `BuildRules.areAllies(userIdA, userIdB)`, que hoje só responde "é o mesmo jogador". Porta e espinho usam ela: quando os times existirem, muda só essa função.

## Limite

`BuildRules.MAX_PER_PLAYER` é `nil` (sem limite). Para limitar, coloque um número ali; o servidor já confere.

## Como adicionar uma peça nova

Peça nova é dado, sem código. Veja `adicionar-item.md`:

1. Item com `category = "placeable"` e bloco `structure` em `src/shared/Defs/Items.luau`.
2. Texto `item.<id>` em `src/shared/Strings/ptBR.luau`.
3. Receita em `src/shared/Defs/Recipes.luau`.
4. `bash scripts/check.sh` valida o bloco.

Nenhum sistema testa o id da peça; só o `kind` (`wall`, `door`, `spike`, `station`, `chest`, `fire`) decide o comportamento. O visual é um bloco provisório em `src/server/Services/StructureModel.luau`: trocar o modelo é trocar só esse arquivo.

## Comandos de teste

No Studio, Command Bar no servidor:

```lua
local p = game.Players:GetPlayers()[1]
game.ServerStorage.DevGive:Invoke(p, "campfire", 1)
game.ServerStorage.DevGive:Invoke(p, "wood_wall", 10)
game.ServerStorage.DevGive:Invoke(p, "chest", 1)
```

Selecione o slot e solte o clique (ou o joystick direito) para colocar. Os antigos `DevWorkbench` e `DevCampfire` não existem mais.
