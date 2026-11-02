# Combate e caixas

Na G6 os jogadores passaram a brigar entre si e **todo mundo que morre, jogador ou mob, vira uma caixa de itens** que qualquer um pode abrir e saquear. O servidor decide tudo; o cliente só pede e mostra. Todo número aqui é **provisório** e fica em dados ou em constantes. O desenho completo está em `docs/superpowers/specs/2026-11-02-g6-combate-caixas-design.md`.

## Vida 200

- A vida do jogador vai de 0 a **200** (`StatNames.HealthMax`). Fome, frio, sede e calor continuam de 0 a 100 (`StatNames.StatusMax`); só a vida tem teto próprio.
- Os danos não mudaram (mordidas, espinho, armas). O anel da vida mostra a porcentagem de 200.
- Comida e regeneração curam os mesmos pontos de antes, então curam proporcionalmente menos.
- Os mobs mordem a cada **1,5 s** (`MobRules.BITE_INTERVAL`). Um lobo (24 por mordida) tira 120 de 200 em umas 5 mordidas; dois lobos seguidos pedem capacete ou comida no meio.

## Golpe em jogador

É o mesmo golpe da coleta (`GatherService`, um a cada 0,5 s). Agora, além de recurso, peça, mob e caixa, **jogadores vivos** também são alvos:

- Leva o golpe o que estiver **mais perto à frente** (`GatherRules.pickTarget`), seja o que for. Um recurso na frente de um jogador protege o jogador.
- **Quem bate nunca é alvo de si mesmo.**
- O dano é o mesmo do golpe em mob (`mobDamage` do item, ou 5 de mão): espadas 12 / 19 / 22, lanças 10 / 14 / 15, picaretas 4 a 14. Veja a tabela em `mobs.md`.
- O dano é do tipo **combate**: o **capacete protege** (`defense`, veja `sobrevivencia.md`).
- A lança alcança mais longe, mas **nunca empurra jogador** (decisão do Elizeu).
- Todos batem em todos: ainda não há times (`BuildRules.areAllies` é o gancho).

## Quem matou e o bônus de pontos

- **Quem matou** é quem deu o **golpe final** (`CharacterService.hurt(..., attacker)`). Se o último dano veio de fome, mob, espinho ou queda, não é morte por jogador, mesmo que alguém tenha batido antes.
- O `DeathService` só aceita o matador se ele ainda está no jogo e não é o próprio morto.
- **Bônus:** o matador ganha **1/4 dos pontos que o morto tinha**, arredondado para baixo (`CrateRules.KILL_BONUS`, `CrateRules.killBonus`). É bônus: o morto não perde nada a mais (os pontos dele viram Golden Ember no fim da vida, como sempre). Só recebe quem ainda está vivo.
- A **tela de morte** mostra "Causa: <nome de quem matou>" (`LifeEnded.KillerName` em `net/game.blink`, o `DisplayName` do matador). Sem matador, a causa de sempre (`death.cause.*`).

## Caixas de itens

Toda a lógica está em `src/server/Services/CrateService.luau`; os números em `src/shared/Crate/CrateRules.luau`.

### De onde vêm

| Quem morreu | O que a caixa tem | Modelo da caixa | Some em |
|---|---|---|---|
| **Jogador** (qualquer causa) | o inventário inteiro (com os slots da mochila), a **mochila vestida (como item)** e a **armadura vestida (como item)** | a **skin de caixa** (veja abaixo) | 3 min |
| **Mob** | o `loot` dele em `Defs/Mobs.luau` | o id do mob (`wolf`, `spider`...) | 1 min |

- A caixa nasce no lugar da morte. Sem item nenhum, **não há caixa**.
- Na morte do jogador, o `CrateService` só **copia** (ouvinte do `DeathService.onDeath`, antes de zerar); quem zera o inventário, a mochila e a armadura é o `DeathService`, logo depois. Nada fica no inventário zerado e nada é copiado duas vezes.
- A caixa de mob nasce pelo gancho `MobService.onDeath`.
- Mob sem `loot` (ou lista vazia) não deixa caixa.

### O que cada mob deixa

| Mob | Caixa |
|---|---|
| Coelho | 1 carne crua, 1 pele de coelho |
| Lobo | 2 carnes cruas, 1 pele de lobo |
| Aranha | 2 linhas |
| Javali | 4 carnes cruas, 1 pele de javali |
| Falcão | 2 carnes cruas, 4 penas de falcão |

Carne crua dá +15 de fome; **carne assada** dá +35 e sai da fogueira (1 carne crua, 3 s). Peles, linha e penas são recursos ainda sem receita.

### Skin da caixa (cosmético, slot `crate`)

- Morto **por outro jogador**: a caixa usa a skin de caixa **de quem matou**. Morto de **outro jeito** (ou matador que saiu do jogo): a skin **dele mesmo** (`CrateRules.skinFor`).
- A skin é um cosmético do slot `crate` (`Defs/CosmeticSlots.luau`, padrão `crate_default`). Veja `boneco.md`.
- O modelo vem de `ReplicatedStorage.Assets.Crates.<skin ou id do mob>` (um `Model` com o pivô **no chão, no centro**). Sem ele, o `CrateModel` monta uma caixa provisória: madeira com faixas **douradas** (jogador) ou de uma cor fixa tirada do id do mob. Os modelos finais o Elizeu vai fazer: basta pôr um Model com o nome certo, sem mexer em código.
- A caixa é ancorada e sem colisão, toque nem raycast (pode haver gente em cima dela); o golpe a acha pelo índice do servidor.

### Abrir e saquear

- Chegando a até **8 studs** do centro da caixa (`OPEN_RANGE`), o painel da caixa aparece. Qualquer um pode abrir e roubar; não há reserva para quem matou.
- Clicar (ou tocar) num slot **move aquele item para o seu inventário** e o painel se reorganiza.
- **Inventário cheio:** leva só o que cabe; o resto fica na caixa.
- **Dois jogadores no mesmo slot:** o servidor atende um depois do outro, sem pausa no meio; o segundo leva o que sobrou (ou nada). Ninguém ganha item duplicado.
- O servidor confere, a cada pedido (`CrateTake`): limite de taxa (10 por segundo), jogador vivo, caixa viva, distância até 8 studs e se o slot ainda guarda o item que o cliente viu. Se a lista estava velha, não entrega e reenvia o conteúdo.
- A caixa que fica **vazia some na hora**.

### Quebrar e sumir

- A caixa tem **600 de vida** (`CrateRules.HEALTH`) e leva golpes como uma construção: o dano é o `structureDamage` do item (mão 5), como em `construcao.md`. Uma picareta de ouro leva uns 30 golpes (~15 s). A barrinha de vida da G4 aparece ao levar dano.
- **Quebrada, os itens somem junto.**
- Some **sozinha** depois do tempo de vida (3 min jogador, 1 min mob).
- Toda saída (vazia, vida 0, tempo, apagada por fora) passa por uma só função `remove`, idempotente: nenhum pedido acha uma caixa que já se foi.
- O conteúdo mora **só no servidor**; o cliente recebe a cópia por `Net.CrateContents` enquanto olha a caixa.

## Os números (onde mudar)

| Quero mudar... | Onde |
|---|---|
| Tempo de vida da caixa de jogador / de mob | `PLAYER_LIFETIME` (180 s) / `MOB_LIFETIME` (60 s) em `src/shared/Crate/CrateRules.luau` |
| Vida da caixa | `HEALTH` (600) em `CrateRules.luau` |
| Alcance de abrir e pegar | `OPEN_RANGE` (8) em `CrateRules.luau` |
| Raio do corpo da caixa (alvo do golpe; a caixa não bloqueia peças de construção) | `RADIUS` (1,5) em `CrateRules.luau` |
| Fração dos pontos que o matador ganha | `KILL_BONUS` (0,25) em `CrateRules.luau` |
| Vida do jogador | `HealthMax` (200) em `src/shared/StatNames.luau` |
| Intervalo da mordida | `BITE_INTERVAL` (1,5) em `src/shared/Mobs/MobRules.luau` |
| Dano do golpe em jogador/mob | `mobDamage` do item (`Defs/Items.luau`) |
| Dano do golpe na caixa | `structureDamage` do item (mão 5) |
| O que um mob deixa | `loot` do mob em `Defs/Mobs.luau` |
| Limite de pedidos de pegar/olhar, folga de olhar | `TAKE_RATE_MAX`, `WATCH_RATE_MAX`, `WATCH_SLACK` no topo de `CrateService.luau` |
| Modelo ou skin da caixa | `ReplicatedStorage.Assets.Crates.<id>` e `Defs/Cosmetics.luau` |

Depois de mexer, `bash scripts/check.sh`.

## Como pôr o loot de um mob novo

Um campo nos dados, sem código (`src/shared/Defs/Mobs.luau`):

```lua
wolf = mob("wolf", "aggressive", {
	loot = { { id = "raw_meat", count = 2 }, { id = "wolf_fur", count = 1 } },
	stats = { ... },
}),
```

1. Cada entrada é `{ id = <item existente em Defs/Items.luau>, count = <inteiro >= 1> }`. Item novo: veja `adicionar-item.md`.
2. Pronto: a caixa do mob usa o id dele como modelo (caixa provisória com cor própria, ou `Assets.Crates.<id>` se existir).
3. `bash scripts/check.sh`: o `Validate` reprova `loot` com item inexistente ou `count` que não seja inteiro maior ou igual a 1.

## Comando do Studio

Só no Studio, na barra de comandos do **servidor** (jogo rodando):

```lua
local p = game.Players:GetPlayers()[1]
print(game.ServerStorage.DevCrate:Invoke(p)) -- cria uma caixa 6 studs à frente
```

A caixa vem com 30 madeiras, 12 pedras, 3 carnes cruas, 1 pele de lobo e 1 picareta de pedra, na skin de caixa de quem chamou, e dura 3 min. Para testar o loot de mob use `DevSpawnMob` (veja `mobs.md`) e mate o mob.

## O que foi visto no Studio (02/11)

- Perto de uma caixa o painel aparece logo acima da hotbar (sobe só quando há também um baú perto), com 8 colunas; clicar num slot move o item para o inventário e o painel se reorganiza.
- Morrer deixa uma caixa com o inventário inteiro mais a mochila vestida (como item).
- Uma aranha morta com espada de ouro deu 40 pontos e deixou uma caixa com 2 linhas.
- A caixa leva golpes e mostra a barra de vida da G4.
- Uma caixa de mob sumiu sozinha ao fim de `MOB_LIFETIME`.
- **Ainda não testado:** a briga entre **dois jogadores** (golpe em jogador, bônus de pontos, skin do matador, saque simultâneo). Foi tudo com um jogador só no Studio; vale testar com dois clientes (Studio, Testar > Local Server com 2 jogadores).

## Onde fica no código

| Arquivo | O que faz |
|---|---|
| `src/shared/Crate/CrateRules.luau` | números e regras puras (`killBonus`, `skinFor`) |
| `src/server/Services/CrateService.luau` | dono das caixas: índice espacial, vida, tempo, slots, olhar, pegar, `DevCrate` |
| `src/shared/Models/CrateModel.luau` | modelo da caixa (de `Assets.Crates` ou provisório) |
| `src/server/Services/DeathService.luau` | morte, matador, bônus de pontos, ouvintes `onDeath` |
| `src/server/Services/CharacterService.luau` | `hurt` com `attacker` |
| `src/server/Services/GatherService.luau` | o golpe (jogador e caixa como alvos) |
| `src/client/CrateState.luau` | acha a caixa mais perto (polling a cada 0,25 s) e guarda o conteúdo |
| `src/client/UI/CratePanel.luau` | o painel (veja `hud.md`) |
| `net/game.blink` | `CrateWatch`, `CrateTake`, `CrateContents`, `LifeEnded.KillerName` |
