# Bots que parecem jogadores

Desde 20/11/2026 (branch `npc`). Design: `docs/superpowers/specs/2026-11-20-bots-design.md`. Plano: `docs/superpowers/plans/2026-11-20-bots.md`.

Para o servidor não parecer vazio enquanto o jogo cresce: até 10 bots que vivem como um jogador. Coletam, craftam até pedra, colocam fogueira à noite, comem e morrem. Aparecem no placar, só revidam quem bateu duas vezes neles e nunca caçam ninguém.

## Quantos

`bots = 20 − jogadores`, entre 0 e 10 (com até 10 jogadores, 10 bots; com 11, 9; com 20 ou mais, nenhum). Se o servidor tiver menos de 20 vagas, conta as vagas no lugar de 20. A cada 5 s entra ou sai no máximo 1. Sai o bot mais longe de todos os jogadores, e só se nenhum jogador estiver a menos de 120 studs. Bot morto volta depois de 20 s como bot novo.

Números para mexer (`src/shared/Bots/BotRules.luau`):

| Nome | Valor | O que é |
|---|---|---|
| `MAX_BOTS` | 10 | máximo de bots |
| `TARGET_TOTAL` | 20 | jogadores + bots |
| `BOT_SCORE_CAP` | 3000 | teto de pontos de um bot (matar bot dá 25% disso no máximo) |
| `PROVOKE_WINDOW` / `PROVOKE_HITS` | 4 s / 2 | golpes do mesmo jogador para virar briga |

## O que fazem (cérebro: `src/shared/Bots/BotBrain.luau`)

Na ordem: briga com quem provocou (foge com vida abaixo de 30%) → mob perigoso (luta armado com vida acima de 50%, senão foge) → noite ou frio (vai para a fogueira perto ou coloca uma) → fome (come, caça ou pega frutinha; de dia guarda 2 comidas) → escada de itens (`BotLadder`: picareta e espada de madeira, picareta e espada de pedra, capacete de madeira e de pedra; coloca a bancada quando a receita pede) → coleta.

Mesmas regras do jogador: fome, frio, receitas, rendimento da coleta, dano das armas e defesa da armadura. A sede não é simulada (fica cheia). Nada do bot é salvo.

## Para quem joga

- Mesmo boneco, nome em cima, skin e mochila sorteadas entre as que saem nos giros (nunca Limitadas).
- Matar bot: caixa com o que ele tinha e o bônus de kill de sempre (com o teto acima). Não conta em missão, estatística nem ranking.
- Bot que mata alguém aparece na tela de morte como "Causa: NomeDoBot".
- Mobs atacam bots, e bots caçam bicho fraco para comer.

## Onde fica cada coisa

- `src/shared/Bots/`: regras puras (`BotRules`, `BotNames`, `BotLadder`, `BotBrain`), testadas em `tests/botrules.spec.luau` e `tests/botbrain.spec.luau`.
- `src/server/Services/BotService/`: `init` (quantos, laço, comandos), `Body` (corpo), `Actor` (um bot: barras, alvo, golpes, morte).
- Portas nos serviços (só acréscimos): `CharacterService.onNonPlayerHurt` e `hurt(..., attackerName)`, `DeathService.kill(..., killerName)`, `StructureService.placeForBot`, `SpawnService.forestSpot`, `GatherService.resourceFx` (e bots como alvo do golpe), `MobService` (vê bots), `ScoreService` (posições contam bots), `CrateService.takeAll`, `SurvivalService.isNight/fireAround`, `Leaderboard` (lista os bots), `BonecoRenderer` (armadura do modelo).

## Studio (barra de comandos do servidor)

- `game.ServerStorage.DevBots:Invoke(10)`: força 10 bots (`nil` volta ao automático).
- `game.ServerStorage.DevBotInfo:Invoke()`: uma linha por bot (objetivo, vida, fome, frio, pontos, inventário, alvo).
- `game.ServerStorage.DevKillBot:Invoke("Nome")`: mata um bot.
- `game.ServerStorage.DevBotCost:Invoke(10)`: ms médios por quadro gastos pelos bots no servidor (no MicroProfiler: "BotService").

## Medições (20/11/2026, Studio no PC)

- Custo dos bots no servidor: 0,10 ms por quadro com 10 bots e 0,22 ms com 20 (de 16,6 ms por quadro).
- Quadros por segundo no Play do Studio (servidor e cliente na mesma máquina): 34,6 sem bots, 31,3 com 10, 30,8 com 20. A diferença fica dentro da variação normal do Studio. Falta medir no celular de verdade.
