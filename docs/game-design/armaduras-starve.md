# Armaduras do Starve.io: números brutos

Levantado em 10/11/2026 para a fase das armaduras (`docs/superpowers/specs/2026-11-10-armaduras-design.md`).

## De onde veio

- **Configuração oficial do servidor:** `https://starve.io/commands.html` (guia de servidor privado). A página traz o JSON com os padrões de cada item: `<item>_defense`, `<item>_mob_defense`, `<item>_blizzard`, `<item>_loss_oxygen`, `<item>_warm_<contexto>` e as receitas no formato `[ingredientes, bancada, fogo, poço, água, tempo, pontos, quantidade]`. É a fonte principal.
- **Wiki do Fandom** (`starveio.fandom.com`), para comportamento sem número na config (capuz, túnicas, explorador, bruxa) e para conferir. Onde a wiki diverge da config, vale a config.

## Como o Starve usa esses números

- **Vida do jogador:** 200. **Tick dos medidores:** 5 s.
- **Defesa:** `dano recebido = golpe − defesa` (mínimo 0). Uma defesa contra jogador (`defense`) e outra contra mob (`mob_defense`). Na config elas são negativas; aqui estão positivas.
- **Frio (`warm_*`):** soma na variação do frio por tick. Bases (perda por tick): floresta dia 2 / noite 18; água dia 5 / noite 25; inverno dia 25 / noite 50; lava esquenta +25 (o `warm_lava` da peça é subtraído do calor). Ex.: casaco de dia na floresta = −2 + 2 = 0 (não perde frio).
- **Oxigênio (`loss_oxygen`):** subtrai da perda base de 25 por tick (máscara 14 → perde 11).
- **Nevasca (`blizzard`):** subtrai do dano base 26 a cada 4 s.
- **Regeneração:** 12 de vida a cada 2 ticks; Coroa da Vida 40 (`crown_green_heal`).
- **Troca de capacete:** `helmet_delay` 5000 ms.
- Outros: `dig_luck` 8 e `tame_luck` 5 (Coroa da Sorte), `pilot_hat_acceleration` 2,5, `ghost_delay` 60 s (Coroa do Anjo).

## Status por peça

| id nosso | id no Starve | defense | mob_defense | blizzard | loss_oxygen | warm_day | warm_night | warm_water_day | warm_water_night | warm_winter_day | warm_winter_night | warm_lava_day | warm_lava_night |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| wood_helmet | `wood_helmet` | 1 | 4 | 0 | — | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| stone_helmet | `stone_helmet` | 2 | 8 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| gold_helmet | `gold_helmet` | 4 | 13 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| diamond_helmet | `diamond_helmet` | 5 | 19 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| amethyst_helmet | `amethyst_helmet` | 6 | 23 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| reidite_helmet | `reidite_helmet` | 7 | 25 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| dragon_helmet | `dragon_helmet` | 8 | 27 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| crab_helmet | `crab_helmet` | 5 | 19 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| lava_helmet | `lava_helmet` | 9 | 30 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| earmuffs | `earmuff` | 0 | 0 | 8 | 0 | 1 | 10 | 0 | 0 | 4 | 10 | -4 | -10 |
| coat | `coat` | 0 | 0 | 12 | 0 | 2 | 13 | 0 | 0 | 8 | 15 | -8 | -15 |
| winter_hat | `scarf` | 0 | 0 | 16 | 0 | 2 | 16 | 0 | 0 | 16 | 35 | -18 | -35 |
| fur_hat | `fur_hat` | 0 | 0 | 20 | 0 | 3 | 17 | 0 | 0 | 20 | 42 | -22 | -42 |
| turban | `turban1` | 0 | 0 | 0 | 0 | 1 | 10 | 0 | 0 | 4 | 10 | 5 | 5 |
| ninja | `turban2` | 0 | 0 | — | 0 | 1 | 10 | 0 | 0 | 4 | 10 | 10 | 10 |
| pilot | `pilot_hat` | 0 | 0 | 12 | 0 | 2 | 16 | 0 | 0 | 13 | 28 | -18 | -35 |
| diamond_protection | `warm_protection` | 2 | 8 | 0 | 0 | -5 | -5 | -5 | -5 | -5 | -5 | 10 | 10 |
| amethyst_protection | `warm_protection2` | 4 | 13 | 0 | 0 | -5 | -5 | -5 | -5 | -5 | -5 | 15 | 15 |
| reidite_protection | `warm_protection3` | 6 | 19 | 0 | 0 | -5 | -5 | -5 | -5 | -5 | -5 | 25 | 25 |
| explorer | `explorer_hat` | 0 | 0 | 0 | 0 | 0 | 3 | 0 | 0 | 0 | 3 | 0 | -3 |
| hood | `hood` | 0 | 0 | 8 | 0 | 1 | 10 | 0 | 0 | 4 | 10 | -4 | -10 |
| winter_hood | `winter_hood` | 0 | 0 | 12 | 0 | 2 | 16 | 0 | 0 | 14 | 28 | -18 | -35 |
| peasant | `peasant` | 0 | 0 | 8 | 0 | 1 | 10 | 0 | 0 | 4 | 10 | -4 | -10 |
| winter_peasant | `winter_peasant` | 0 | 0 | 12 | 0 | 2 | 16 | 0 | 0 | 14 | 28 | -18 | -35 |
| diving_mask | `diving_mask` | 2 | 8 | 0 | 14 | 0 | 0 | 2 | 15 | 4 | 10 | -4 | -10 |
| diving_suit | `super_diving_suit` | 4 | 16 | 0 | 19 | 0 | 0 | 4 | 20 | 8 | 15 | -8 | -15 |
| witch | `witch_hat` | — | — | — | — | — | — | — | — | — | — | — | — |
| santa | `christmas_hat` | 0 | 0 | 0 | 0 | 2 | 15 | 0 | 0 | 13 | 28 | -15 | -30 |
| elf | `elf_hat` | 0 | 0 | 0 | 0 | 2 | 14 | 0 | 0 | 10 | 20 | -10 | -20 |
| life_crown | `green_crown (receita crown_green)` | 4 | 16 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| angel_crown | `blue_crown (receita crown_blue)` | 2 | 16 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| luck_crown | `orange_crown (receita crown_orange)` | 4 | 16 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

A bruxa (`witch_hat`) não tem entrada na config: os números do nosso jogo copiam o protetor de orelha, como diz a wiki.

## Receitas (config oficial)

| Starve | ingredientes | estação | tempo | pontos |
|---|---|---|---|---|
| wood_helmet | 50 wood | — | 5 | 20 |
| stone_helmet | 75 stone, 75 wood, wood_helmet | B | 10 | 58 |
| gold_helmet | 90 stone, 90 wood, 90 gold, stone_helmet | B | 20 | 130 |
| diamond_helmet | 100 stone, 100 gold, 100 diamond, gold_helmet | B | 30 | 210 |
| amethyst_helmet | 80 amethyst, 150 gold, 120 diamond, diamond_helmet | B | 60 | 351 |
| reidite_helmet | 80 reidite, 150 diamond, 120 amethyst, amethyst_helmet | B+F | 90 | 537 |
| dragon_helmet | 30 blue_cord, 1 dragon_cube, 150 amethyst, 3 dragon_heart | B+F+água | 120 | 4975 |
| crab_helmet | gold_helmet, 10 claw, 10 crab_stick, 10 cord | B | 60 | 1120 |
| lava_helmet | dragon_helmet, 1 lava_cube, 150 reidite, 2 lava_heart | B+F+água | 180 | 9430 |
| earmuffs | 1 fur, 2 cord | B | 5 | 140 |
| coat | earmuffs, 5 fur_wolf, 4 cord | B | 12 | 474 |
| scarf | coat, 5 fur_winter, 4 blue_cord | B | 30 | 360 |
| fur_hat | scarf, 5 fur_winter, 10 fur_mammoth, 4 blue_cord | B | 50 | 2400 |
| turban1 | 4 cord, 2 fur_boar | B | 15 | 330 |
| turban2 | turban1, 6 cord, 4 fur_boar, 12 vulture_feather, 4 penguin_feather | B | 150 | 1360 |
| pilot_hat | pilot_glasses, 8 hawk_feather, 8 vulture_feather, 8 penguin_feather, 6 cord | B | 60 | 8980 |
| warm_protection | 5 flame, 50 diamond, 5 blue_cord | B+F | 20 | 325 |
| warm_protection2 | warm_protection, 10 flame, 50 amethyst | B+F | 60 | 665 |
| warm_protection3 | warm_protection2, 15 flame, 50 amethyst, 50 reidite | B+F | 90 | 1065 |
| explorer_hat | 1 paper, 1 fur, 2 cord | B | 5 | 140 |
| hood | 10 fur_wolf, 5 fur, 6 cord | B | 10 | 970 |
| winter_hood | hood, 1 special_fur_2, 15 fur_winter, 5 blue_cord, 8 penguin_feather | B | 60 | 4180 |
| peasant | 3 fur, 2 cord | B | 10 | 210 |
| winter_peasant | peasant, 1 special_fur, 10 fur_winter, 5 blue_cord, 8 penguin_feather | B | 60 | 3880 |
| diving_mask | 2 scales, 40 diamond, 4 cord | B | 20 | 348 |
| super_diving_suit | diving_mask, 80 gold, 1 kraken_skin, 20 amethyst | B | 90 | 2238 |
| crown_green | 1 gemme_green, 200 gold | B+F+água | 60 | 3220 |
| crown_blue | 1 gemme_blue, 200 gold, 1 dragon_heart | B+F+água | 60 | 3420 |
| crown_orange | 1 gemme_orange, 200 gold | B+F+água | 60 | 3220 |
| blue_cord | 1 diamond, 1 cord | B | 3 | 57 |

Nomes do Starve → nossos: fur = `rabbit_fur`, cord = `thread`, blue_cord = `blue_thread`, fur_wolf = `wolf_fur`, fur_winter = `winter_fur`, fur_mammoth = `mammoth_fur`, fur_boar = `boar_fur`, scales = `piranha_scales`, claw = `crab_claws`, crab_stick = `crab_sticks`, special_fur = `white_wolf_fur`, special_fur_2 = `black_wolf_fur`, dragon_cube = `blue_cube`, gemme_* = `green_gem`/`blue_gem`/`orange_gem`. Bruxa (wiki): 5 pele de lobo, 2 pele de coelho, 6 linhas, 2 vaga-lumes. Gorros de Natal e de elfo: saem do presente de Natal, sem receita.

## Divergências conhecidas (wiki × config)

- Capacete de ouro: o texto da wiki diz 90/60/60; o infobox e a config dizem 90/90/90.
- Proteções: as páginas de cada item pedem o dobro (10 chamas/100 diamante…); a página "Heat Protections" e a config pedem o que está acima.
- Coroa da Sorte: a wiki diz 100 de ouro; a config diz 200.
- Changelog de 16/03/2026 diz "Reidite helmet is cheaper" e "All crowns are cheaper", mas a config ainda mostra os valores acima.
- Coroa do Anjo: a página "Crowns" diz defesa 4; a do item e a config dizem 2.
