# Mobs

Os mobs da floresta (coelho, lobo, aranha, javali e falcão) vivem no jogo: nascem espalhados, andam à toa, fogem, perseguem, mordem, apanham, morrem e renascem. O servidor decide tudo; o cliente só desenha (o visual, as juntas e as animações estão em [`mobs-modelos.md`](mobs-modelos.md)). Os outros 18 mobs ainda são só visual: entram bioma por bioma, só com dados.

Todo número aqui é **provisório** e fica em dados ou em constantes, nunca espalhado no código. Os números do design vêm da wiki de fãs do Starve.io (a vida do jogador do Ember Wilds vai de 0 a 100, a do Starve de 0 a 200, então **a mordida é a metade da wiki**) e de escolhas do Elizeu.

## Os 5 mobs da floresta

Tudo em `src/shared/Defs/Mobs.luau`, no bloco `stats` de cada mob. A velocidade do jogador é 16 studs/s.

| Mob | Comportamento | Vida | Mordida | Velocidade | Raio do corpo | Pontos |
|---|---|---:|---:|---:|---:|---:|
| Coelho (`rabbit`) | passivo | 60 | não morde | 15 | 1,8 | 20 |
| Lobo (`wolf`) | agressivo | 300 | 24 | 14 | 2 | 60 |
| Aranha (`spider`) | agressivo | 120 | 16 + teia | 20 | 2,2 | 40 |
| Javali (`boar`) | neutro | 400 | 25 | 15 | 2,2 | 80 |
| Falcão (`hawk`) | neutro, voa | 300 | 24 | 18 | 2,2 | 60 |

- Uma mordida por segundo (`BITE_INTERVAL`): o lobo tira 24 por segundo e mata um jogador parado em uns 5 s.
- O raio do corpo é o círculo no chão (como as peças da construção, veja `construcao.md`).
- Os mobs **não têm barra de vida** (decisão do Elizeu). A reação ao golpe é a do visual: pisca em vermelho, recua, fecha os olhos.

## Comportamentos

O cérebro é puro e testado no Lune: `src/shared/Mobs/MobBrain.luau` (a cada passo decide andar, perseguir, fugir, morder ou voar). O servidor só aplica a intenção. Os tempos e raios ficam em `src/shared/Mobs/MobRules.luau`.

| Tipo | O que faz |
|---|---|
| **Agressivo** (lobo, aranha) | Percebe o jogador só num raio pequeno (`SENSE_RADIUS` = 18 studs). Depois que começa, **não desiste por distância**: corre atrás. Desiste quando passam `GIVE_UP` = 10 s sem o alvo bater nele; cada golpe do alvo reinicia o tempo. |
| **Passivo** (coelho) | Foge de quem chega a `FLEE_RADIUS` = 14 studs (até ficar mais longe que isso) e, depois de apanhar, foge por `FLEE_AFTER_HIT` = 3 s. Nunca ataca. |
| **Neutro** (javali, falcão) | Ignora o jogador até apanhar. Depois age como o agressivo (persegue, desiste do mesmo jeito). |
| **Sozinho** | Anda devagar (`WANDER_SPEED` = 40% da velocidade) até um ponto a `WANDER_RADIUS` = 20 studs de onde nasceu, para de 1 a 4 s e sorteia outro. |

Detalhes que valem saber:

- **Desistir**: volta a andar à toa e fica `CALM_TIME` = 5 s sem perseguir ninguém sozinho (um golpe do jogador nesse tempo ainda o faz perseguir).
- **Alvo que some** (morreu, renasceu, saiu do bioma): o mob desiste e volta a andar à toa.
- **Golpe de outro jogador** durante a perseguição não troca o alvo: só o alvo reinicia o tempo de desistir.
- **Mordida**: alcance = raio do mob + `BITE_REACH` (2) + raio do jogador (1,5), uma a cada `BITE_INTERVAL` (1 s). Usa `CharacterService.hurt(..., "combat")`: o capacete protege. A morte mostra o mob ("Morto por: Lobo", texto `mob.<id>` em `Strings/ptBR.luau`).
- **Borda vermelha** (`MobHostile`): sempre acesa no agressivo; no neutro acende ao ficar bravo e apaga ao desistir; o passivo nunca acende.
- **Sem pathfinding**: o mob vai reto e escorrega pela beirada (`MobMove.luau`). Um lobo atrás de uma parede fica empurrando a parede, como no Starve.

## Obstáculos

Os mobs que não voam colidem como círculos no chão (`MobMove.step`), com:

- paredes, espinhos, bancada, baú e fogueira (pelo índice do `StructureService`); **porta aberta não segura**, porta fechada sim; eles só batem de frente, não quebram nada;
- recursos (árvores, pedras), outros mobs no chão e jogadores;
- **água**: mob que não voa não entra no lago. Um jogador dentro da água está a salvo deles;
- **borda do bioma**: o mob nunca sai do bioma em que nasceu. Perseguindo, para na borda e solta o alvo, como se tivesse desistido.

Os espinhos também ferem os mobs que encostam (`SpikeService`), com o mesmo dano e o mesmo compasso de 1 s do espinho em jogador. Mob morto por espinho **não dá pontos**.

## Dano do jogador no mob

O mesmo golpe da coleta (`GatherService`, um a cada 0,5 s) acerta o que estiver mais perto à frente: recurso, peça ou mob. O dano vem do campo `mobDamage` do item na mão (`src/shared/Defs/Items.luau`); sem o campo, vale a mão: `HAND_DAMAGE` = 5 (`MobRules.damageOf`).

| Na mão | Dano |
|---|---:|
| Nada / item sem `mobDamage` | 5 |
| Espada de madeira / pedra / ouro | 12 / 19 / 22 |
| Lança de madeira / pedra / ouro | 10 / 14 / 15 |
| Picareta de madeira / pedra / ouro | 4 / 6 / 8 |
| Picareta de diamante / ametista / reidite | 10 / 12 / 14 |

Exemplos: lobo (300) com espada de pedra = 16 golpes, uns 8 s; aranha (120) com espada de ouro = 6 golpes e dá 40 pontos.

Com uma peça `placeable` na mão o golpe continua construindo, não bate. Mob **voando** não é acertado por quem está no chão.

## Morte, pontos e renascer

Quando a vida zera (`MobService.damage`):

1. Marca `MobDead` na raiz (o cliente anima a morte) e a raiz some `DEATH_REMOVE` = 0,6 s depois.
2. Dá os pontos a quem deu o último golpe (uma vez só: mob morto não apanha de novo).
3. Chama os ouvintes de `MobService.onDeath(listener)`: é o **gancho da caixa de drop** (hoje o mob morto não deixa nada; a caixa vai entrar ali).
4. A vaga esfria por `RESPAWN_DELAY` = 30 s e então a população repõe outro.

## População

Em `population` de cada mob em `Defs/Mobs.luau`, por bioma e por período (dia/noite). À noite há menos coelho e mais mobs agressivos.

| | Coelho | Lobo | Aranha | Javali | Falcão |
|---|---:|---:|---:|---:|---:|
| Dia | 40 | 10 | 8 | 8 | 6 |
| Noite | 15 | 20 | 16 | 8 | 6 |

- O `MobService` confere a cada `POPULATION_EVERY` = 2 s: meta do período menos (vivos + vagas esfriando). Falta: nascem até `SPAWN_PER_TYPE` = 2 de cada tipo por rodada.
- **Onde nasce**: ponto aleatório do bioma, fora da água, sem encostar em recurso ou outro mob, a pelo menos `SPAWN_PLAYER_GAP` = 60 studs de qualquer jogador e `SPAWN_STRUCTURE_GAP` = 30 studs de qualquer construção (assim nunca nasce dentro de uma base). A escolha tenta até `SPAWN_TRIES` = 20 vezes e **desiste** se não achar lugar; tenta de novo na próxima rodada, sem laço infinito (`MobSpawn.pick`).
- **Troca dia/noite**: o tipo acima do novo limite some aos poucos: primeiro as vagas esfriando, depois **um mob por rodada que esteja longe de todos os jogadores** (ninguém vê sumir). Os abaixo do limite nascem aos poucos.
- Enquanto o ponto de nascer do jogador for fixo, um lobo pode ficar esperando no ponto de nascer. Isso some quando o nascimento aleatório na floresta entrar numa fase futura.

## Teia da aranha

A aranha, ao morder, pode prender o jogador (`stats.web = { duration = 2, cooldown = 6 }` em `Defs/Mobs.luau`):

- prende `duration` = 2 s com velocidade 0; ele **continua podendo bater**;
- a aranha só atira teia de novo depois de `cooldown` = 6 s;
- teia nova só renova o tempo, não soma;
- o servidor grava no personagem o atributo `WebbedUntil`, um **instante absoluto** (fim da teia). `MobRules.isWebbed(untilTime, now)` só prende se `now` ainda está antes dele: teia vencida não prende mesmo com o atributo ainda lá, e o atributo de um personagem morto não passa para o próximo;
- quem zera a velocidade é o `WaterSim` (dono do `WalkSpeed`, nos dois lados da simulação); ele lê o atributo **por polling**, porque `AttributeChanged` não dispara no personagem previsto;
- o visual é um disco com linhas nos pés de quem está preso (`src/client/World/WebVisual.luau`), provisório até o Elizeu modelar.

## Voo (falcão)

`stats.flies = true`. O falcão **alterna ao acaso** entre voar e andar no chão (`FLY_TIME` e `GROUND_TIME` = 4 a 10 s cada, em `MobRules`):

- **Voando**: passa por cima de paredes, recursos e água (só não sai do bioma); **não acerta nem é acertado** por quem está no chão. No visual, o servidor liga o atributo `MobFlying` na raiz e o cliente desenha o mob **6 studs mais alto e com transparência 0,4** (`FLY_HEIGHT`, `FLY_TRANSPARENCY` e `FLY_FADE` em `MobAnimConfig.luau`).
- **Para morder, pousa**: perseguindo, pousa quando está a até `LAND_RANGE` = 8 studs do alvo e só morde no chão. Perseguindo no chão não decola; volta a alternar quando desiste.
- **Só pousa em chão livre**: o servidor confere se o corpo cabe ali (sem parede, recurso, água, mob ou jogador). Se não cabe, **continua voando** e tenta de novo; nunca pousa dentro de nada.
- Nasce no chão.

## Comandos do Studio

Só funcionam no Studio, na barra de comandos do **servidor** (com o jogo rodando):

```lua
local p = game.Players:GetPlayers()[1]
print(game.ServerStorage.DevSpawnMob:Invoke(p, "wolf")) -- cria um lobo a 12 studs à frente
print(game.ServerStorage.DevMobCount:Invoke())          -- vivos, vagas esfriando e meta por tipo
```

- `DevSpawnMob:Invoke(player, id)`: cria o mob a `DEV_SPAWN_DISTANCE` = 12 studs à frente do jogador, **sem** as distâncias de nascimento. Responde `"mob sem IA: <id>"` para os 18 que ainda não têm `stats`, e `"fora de bioma"` se o ponto cai fora.
- `DevMobCount:Invoke()`: devolve `dia` ou `noite` e, por bioma e tipo, `N vivos + M esfriando, meta K`.
- `ServerStorage.DevMobs:Invoke(true / false)` continua sendo a galeria de teste do visual dos 23 mobs (`mobs-modelos.md`); não tem IA.

## Onde mudar cada coisa

| Quero mudar... | Onde |
|---|---|
| Vida, mordida, velocidade, raio, pontos, voo, teia de um mob | `stats` em `src/shared/Defs/Mobs.luau` |
| População de dia e de noite | `population` em `Defs/Mobs.luau` |
| Raio de percepção, fuga, tempo de desistir, calma, mordida, passeio, voo, distâncias de nascer, tempo de renascer | constantes em `src/shared/Mobs/MobRules.luau` |
| Dano de uma arma em mob | `mobDamage` no item (`Defs/Items.luau`; veja `adicionar-item.md`) |
| Duração e intervalo da teia | `stats.web` do mob |
| Quanto o falcão sobe e fica translúcido | `FLY_HEIGHT`, `FLY_TRANSPARENCY` em `MobAnimConfig.luau` |
| Suavização do movimento no cliente | `ROOT_SMOOTHING` em `MobAnimConfig.luau` |
| Quantos passos de IA por segundo, rodada da população, mob longe pensando menos | constantes no topo de `MobService.luau` (`FAR_RADIUS`, `FAR_EVERY`, `POPULATION_EVERY`, `SPAWN_PER_TYPE`, `SPAWN_TRIES`) e `TICK` em `MobRules` |
| Nome na tela de morte | `mob.<id>` em `src/shared/Strings/ptBR.luau` |

Depois de mexer, `bash scripts/check.sh`: o `Validate` confere os dados (vida, velocidade e raio positivos; população não negativa; teia com duração e intervalo maiores que 0) e os testes cobrem cérebro, movimento e nascimento.

## Como funciona (para quem vai mexer no código)

| Arquivo | O que é |
|---|---|
| `src/shared/Mobs/MobRules.luau` | Constantes de gameplay e `damageOf`, `isWebbed` |
| `src/shared/Mobs/MobBrain.luau` | O cérebro puro: `new`, `onHit`, `think(...) → Intent` (direção, velocidade, quem morder, teia, voando, hostil) |
| `src/shared/Mobs/MobMove.luau` | Anda e escorrega em volta de círculos |
| `src/shared/Mobs/MobSpawn.luau` | Metas da população (`targets`, `diff`) e o ponto livre (`pick`) |
| `src/server/Services/MobService.luau` | Dono dos mobs: raiz, índice espacial (`SpatialGrid`), passo de IA a 10 Hz, mordida, dano, morte e população |
| `src/client/Mobs/MobRenderer.luau` | Desenha cada raiz e suaviza a posição entre as atualizações do servidor (a raiz anda a 10 Hz); lê `MobFlying` |

- Cada mob é uma raiz invisível ancorada com a tag `Mob` e os atributos do contrato (`MobId`, `MobAttack`, `MobHurt`, `MobDead`, `MobHostile` e `MobFlying`), numa pasta `Workspace.Mobs`. O `MobService` só mexe nos mobs que ele criou; a galeria do `DevMobService` convive com ele.
- Os atributos só são escritos quando mudam. Mob a mais de `FAR_RADIUS` = 150 studs de todo jogador pensa só a cada `FAR_EVERY` = 0,5 s.
- O código nunca testa o id do mob (`if id == "wolf"`): tudo vem de `Defs.Mobs`.
- O `GatherService` (golpe) e o `SpikeService` (espinho) falam com o `MobService` por `near`, `list`, `hit` e `damage`.

## Como pôr os mobs de outro bioma

Quando os outros biomas ficarem jogáveis, o sistema já serve: é só dado.

1. Dê ao mob um bloco `stats` em `Defs/Mobs.luau` (vida, mordida, velocidade, raio, pontos; `flies` e `web` se couber). Sem `stats`, o mob continua só visual.
2. Dê a ele `population = { <bioma> = { day = N, night = N } }`, com o id do bioma como está em `WorldConfig.BIOMES`. Um mob pode ter vários biomas.
3. Garanta o texto `mob.<id>` e a animação (`MobAnimConfig`), como em `mobs-modelos.md`.
4. `bash scripts/check.sh`. O código não muda.

## Fora do escopo (por enquanto)

- **Drops**: o mob morto não deixa nada; a caixa de drop entra em `MobService.onDeath`.
- **Domesticar e montar**: só existe o campo `mountFlies` nos dados.
- Mobs quebrando construções, telhado (que protegeria de voadores), PvP, bosses e cavernas.
- Busca de caminho inteligente.
