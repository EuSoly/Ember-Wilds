# Chrono quests do Starve.io: números brutos

Levantado em 12/11/2026 para a fase das missões (branch `missoes`).

## De onde veio

- **Configuração oficial do servidor:** `https://starve.io/commands.html`. O JSON da página traz `"quests": {"defaults": [...]}` com as 13 quests padrão. É a fonte principal; onde o nosso `catalogo-e-roadmap.md` diverge (prazos), vale a config.
- **Changelog oficial** (`assets/skins/reference/changelog.html`, update 10/08): 27 tipos de objetivo, 17 regras que falham a quest, condições de início e prêmios (itens, slots de mochila, pontos, comandos). Uma quest pode voltar depois do prêmio, ter só N vencedores (corrida), e `quests_per_life` sorteia N quests por vida.
- `time` está em milissegundos. **1 dia de jogo = 480000 ms = 8 min** (igual ao nosso `DayCycle`: 240 s de dia + 240 s de noite).

## As 13 quests

| id | Título no jogo | Prazo | Termina quando | Objetivo | Regras (falha se quebrar) | Prêmio | Pontos |
|---|---|---|---|---|---|---|---|
| `dragon` | Collect 1 dragon heart inside the cave | 6 dias | objetivo | ter 1 `dragon_heart`, pego no inverno/caverna (fora = falha) | `alone` | `dragon_orb` (Orbe Azul) | 7500 |
| `amethyst` | Gather 1 amethyst | 3 dias | objetivo | ter 1 `amethyst` | `alone`, `mined` (minerado por você) | `dragon_cube` (Cubo Azul) | 7500 |
| `survive` | Survive without losing life | 4 dias | tempo | — | `alone`, `unhurt` (`life: 100`) | `gemme_green` (Gema Verde) | 7500 |
| `luck` | Open 5 treasure chests | 3 dias | objetivo | abrir 5 baús de tesouro | — | `gemme_orange` (Gema Laranja) | 3000 |
| `peace` | Be peaceful | 6 dias | tempo | — | `peaceful` | `gemme_blue` (Gema Azul) | 3000 |
| `farmer` | 100 bread in winter, alone, without come back | 5 dias | objetivo | colher 100 trigo, 100 farinha, 100 pão | `alone`, `stay` no inverno desde que entra | `special_fur` (Pele de Lobo Branco) | 3000 |
| `hood` | After 1 day, survive in winter | 5 dias | tempo | — | `alone`, `stay` no inverno a partir do dia 1 | `special_fur_2` (Pele de Lobo Preto) | 3000 |
| `lava` | Kill the Lava Dragon inside the Lava Biome | 10 dias | objetivo | ter 1 `lava_heart`, pego na lava | `alone` | `lava_orb` (Orbe de Lava) | 10000 |
| `reidite` | Gather 1 reidite | 6 dias | objetivo | ter 1 `reidite` | `alone`, `mined` | `lava_cube` (Cubo de Lava) | 7500 |
| `farmer_desert` | 100 bread in desert, alone, without come back | 7 dias | objetivo | 100 trigo, 100 farinha, 100 pão | `alone`, `stay` no deserto desde que entra | `pitchfork_part` (Peça do Forcado) | 6000 |
| `emerald` | Gather 1 emerald | 6 dias | objetivo | ter 1 `emerald` | `alone`, `mined` | `pilot_glasses` (Óculos de Piloto) | 7500 |
| `sandworm` | Kill 1 Sand Worm | 8 dias | objetivo | ter 1 `sandworm_juice`, pego no deserto | `alone` | +1 slot de mochila | 10000 |
| `explorer` | Explore each biome for at least 1 day | 7 dias | objetivo | 1 dia em cada bioma: floresta, inverno, deserto, lava | `alone` | +1 slot de mochila | 10000 |

Ids da config → ids do nosso `Defs/Items.luau`: `gemme_green` → `green_gem`, `gemme_blue` → `blue_gem`, `gemme_orange` → `orange_gem`, `dragon_cube` → `blue_cube`, `special_fur` → `white_wolf_fur`, `special_fur_2` → `black_wolf_fur`. Os outros têm o mesmo id. Todos já existem como `testOnly`, sem modelo.

`end: "time"` = vence quem chega ao fim do prazo sem quebrar regra. `end: "goals"` = vence ao cumprir o objetivo dentro do prazo. Os pontos só contam quando o prêmio é resgatado (botão "Claim").

## O que o motor do Starve aceita (para quests próprias)

- **Objetivos (28 na lista):** have, kill, open, farm, craft, gather, spend, score, players, tame, break, ghost, wear, build, water, fuel, store, dig, extract, use, recycle, buy, steal, unlock, earn, reach, travel, gauge.
- **Lugares de `spend`:** biome, water, air, mount, bed, roof, fire, night, blizzard, sandstorm.
- **Regras vistas nas padrão:** `alone` (sem time), `mined` (o item tem de ser minerado por você, não pego de caixa/baú), `unhurt` (não perder vida), `peaceful` (não atacar jogadores nem mobs não agressivos; changelog: espinhos e arco também quebram), `stay` (não sair do bioma). O changelog cita outras: unarmed, vegetarian.
- **Limites:** até 32 quests, 20 objetivos e 4 prêmios por quest, título até 48 caracteres, descrição até 160.
- **Detalhes do changelog:** largar um item próprio e pegar de volta não quebra a quest; prêmio com inventário cheio foi bug corrigido; a janela mostra a descrição em tooltip; tem alerta de quest e botão de resgatar.
