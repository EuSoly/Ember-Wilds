# Auditoria das receitas liberadas

Gerado por `lune run scripts/auditoria-receitas.luau` a partir de `src/shared/Defs`.
Lista todas as receitas em que o resultado e todos os ingredientes estão liberados fora do Studio (`ItemAccess.recipeAvailable(recipe, false)`).

| # | Resultado | Qtd | Ingredientes | Tempo | Estação | Obtível? |
|---:|---|---:|---|---:|---|---|
| 1 | Picareta de Madeira (`wood_pickaxe`) | 1 | 10× Madeira (`wood`) | 5 s | — | Sim |
| 2 | Picareta de Pedra (`stone_pickaxe`) | 1 | 50× Madeira (`wood`), 15× Pedra (`stone`), 1× Picareta de Madeira (`wood_pickaxe`) | 15 s | Bancada | Sim |
| 3 | Picareta de Ouro (`gold_pickaxe`) | 1 | 40× Madeira (`wood`), 30× Pedra (`stone`), 20× Ouro (`gold`), 1× Picareta de Pedra (`stone_pickaxe`) | 20 s | Bancada | Sim |
| 4 | Espada de Madeira (`wood_sword`) | 1 | 30× Madeira (`wood`) | 5 s | — | Sim |
| 5 | Espada de Pedra (`stone_sword`) | 1 | 50× Madeira (`wood`), 25× Pedra (`stone`), 1× Espada de Madeira (`wood_sword`) | 15 s | Bancada | Sim |
| 6 | Espada de Ouro (`gold_sword`) | 1 | 60× Madeira (`wood`), 50× Pedra (`stone`), 40× Ouro (`gold`), 1× Espada de Pedra (`stone_sword`) | 20 s | Bancada | Sim |
| 7 | Lança de Madeira (`wood_spear`) | 1 | 40× Madeira (`wood`) | 5 s | — | Sim |
| 8 | Lança de Pedra (`stone_spear`) | 1 | 60× Madeira (`wood`), 10× Pedra (`stone`), 1× Lança de Madeira (`wood_spear`) | 15 s | Bancada | Sim |
| 9 | Lança de Ouro (`gold_spear`) | 1 | 80× Madeira (`wood`), 30× Pedra (`stone`), 30× Ouro (`gold`), 1× Lança de Pedra (`stone_spear`) | 20 s | Bancada | Sim |
| 10 | Capacete de Madeira (`wood_helmet`) | 1 | 50× Madeira (`wood`) | 5 s | — | Sim |
| 11 | Capacete de Pedra (`stone_helmet`) | 1 | 75× Pedra (`stone`), 75× Madeira (`wood`), 1× Capacete de Madeira (`wood_helmet`) | 10 s | Bancada | Sim |
| 12 | Capacete de Ouro (`gold_helmet`) | 1 | 90× Pedra (`stone`), 90× Madeira (`wood`), 90× Ouro (`gold`), 1× Capacete de Pedra (`stone_helmet`) | 20 s | Bancada | Sim |
| 13 | Bancada (`workbench`) | 1 | 30× Madeira (`wood`), 10× Pedra (`stone`) | 10 s | — | Sim |
| 14 | Fogueira (`campfire`) | 1 | 25× Madeira (`wood`), 5× Pedra (`stone`) | 10 s | — | Sim |
| 15 | Fogueira Grande (`big_campfire`) | 1 | 35× Madeira (`wood`), 10× Pedra (`stone`), 1× Fogueira (`campfire`) | 15 s | — | Sim |
| 16 | Parede de Madeira (`wood_wall`) | 1 | 20× Madeira (`wood`) | 5 s | Bancada | Sim |
| 17 | Parede de Pedra (`stone_wall`) | 1 | 17× Pedra (`stone`) | 5 s | Bancada | Sim |
| 18 | Parede de Ouro (`gold_wall`) | 1 | 14× Ouro (`gold`) | 5 s | Bancada | Sim |
| 19 | Porta de Madeira (`wood_door`) | 1 | 30× Madeira (`wood`) | 8 s | Bancada | Sim |
| 20 | Porta de Pedra (`stone_door`) | 1 | 27× Pedra (`stone`), 1× Porta de Madeira (`wood_door`) | 8 s | Bancada | Sim |
| 21 | Porta de Ouro (`gold_door`) | 1 | 24× Ouro (`gold`), 1× Porta de Pedra (`stone_door`) | 8 s | Bancada | Sim |
| 22 | Espinho de Madeira (`wood_spike`) | 1 | 40× Madeira (`wood`), 30× Pedra (`stone`), 1× Parede de Madeira (`wood_wall`) | 20 s | Bancada | Sim |
| 23 | Espinho de Pedra (`stone_spike`) | 1 | 70× Pedra (`stone`), 1× Parede de Pedra (`stone_wall`) | 20 s | Bancada | Sim |
| 24 | Espinho de Ouro (`gold_spike`) | 1 | 40× Ouro (`gold`), 30× Pedra (`stone`), 1× Parede de Ouro (`gold_wall`) | 20 s | Bancada | Sim |
| 25 | Baú (`chest`) | 1 | 25× Madeira (`wood`), 2× Ouro (`gold`) | 20 s | Bancada | Sim |
| 26 | Papel (`paper`) | 1 | 20× Madeira (`wood`) | 5 s | Fogo | Sim |
| 27 | Livro (`book`) | 1 | 4× Papel (`paper`), 10× Ouro (`gold`) | 30 s | Bancada | Sim |
| 28 | Protetor de Orelha (`earmuffs`) | 1 | 1× Pele de coelho (`rabbit_fur`), 2× Linha (`thread`) | 5 s | Bancada | Sim |
| 40 | Carne assada (`cooked_meat`) | 1 | 1× Carne crua (`raw_meat`) | 3 s | Fogo | Sim |
| 41 | Curativo (`bandage`) | 1 | 2× Linha (`thread`) | 5 s | Bancada | Sim |
| 42 | Garrafa de vidro (`bottle_empty`) | 1 | 25× Areia (`sand`) | 5 s | Bancada + Fogo | Sim |
| 43 | Garrafa de água (`bottle_full`) | 1 | 1× Garrafa de vidro (`bottle_empty`) | 5 s | Água | Sim |
| 44 | Fornalha (`furnace`) | 1 | 150× Madeira (`wood`), 50× Pedra (`stone`), 15× Ouro (`gold`) | 20 s | Bancada | Sim |
| 45 | Piso (`bridge`) | 1 | 15× Madeira (`wood`) | 5 s | Bancada | Sim |
| 46 | Telhado (`roof`) | 1 | 30× Madeira (`wood`) | 5 s | Bancada | Sim |
| 47 | Placa (`sign`) | 1 | 20× Madeira (`wood`) | 5 s | Bancada | Sim |
| 48 | Poço (`well`) | 1 | 100× Pedra (`stone`), 30× Terra (`ground`) | 10 s | Bancada + Fogo | Sim |
| 49 | Cama (`bed`) | 1 | 100× Madeira (`wood`), 50× Pedra (`stone`), 5× Pele de lobo (`wolf_fur`), 5× Pele de coelho (`rabbit_fur`), 6× Linha (`thread`) | 10 s | Bancada | Sim |
| 50 | Balde (`bucket`) | 1 | 20× Madeira (`wood`), 1× Linha (`thread`) | 5 s | Bancada | Sim |
| 51 | Porta de espinhos de madeira (`wood_spike_door`) | 1 | 1× Porta de Madeira (`wood_door`), 80× Madeira (`wood`), 60× Pedra (`stone`) | 20 s | Bancada | Sim |
| 52 | Porta de espinhos de pedra (`stone_spike_door`) | 1 | 1× Porta de Pedra (`stone_door`), 140× Pedra (`stone`) | 20 s | Bancada | Sim |
| 53 | Porta de espinhos de ouro (`gold_spike_door`) | 1 | 1× Porta de Ouro (`gold_door`), 80× Ouro (`gold`), 60× Pedra (`stone`) | 20 s | Bancada | Sim |
| 54 | Extrator de pedra (`stone_extractor`) | 1 | 50× Madeira (`wood`), 100× Pedra (`stone`) | 90 s | Bancada | Sim |
| 55 | Extrator de ouro (`gold_extractor`) | 1 | 60× Pedra (`stone`), 120× Ouro (`gold`) | 90 s | Bancada | Sim |
| 66 | Casaco (`coat`) | 1 | 1× Protetor de Orelha (`earmuffs`), 5× Pele de lobo (`wolf_fur`), 4× Linha (`thread`) | 12 s | Bancada | Sim |
| 69 | Turbante (`turban`) | 1 | 4× Linha (`thread`), 2× Pele de javali (`boar_fur`) | 15 s | Bancada | Sim |
| 75 | Chapéu de Explorador (`explorer`) | 1 | 1× Papel (`paper`), 1× Pele de coelho (`rabbit_fur`), 2× Linha (`thread`) | 5 s | Bancada | Sim |
| 76 | Capuz (`hood`) | 1 | 10× Pele de lobo (`wolf_fur`), 5× Pele de coelho (`rabbit_fur`), 6× Linha (`thread`) | 10 s | Bancada | Sim |
| 78 | Túnica de Camponês (`peasant`) | 1 | 3× Pele de coelho (`rabbit_fur`), 2× Linha (`thread`) | 10 s | Bancada | Sim |
| 101 | Martelo de Pedra (`stone_hammer`) | 1 | 90× Madeira (`wood`), 50× Pedra (`stone`) | 10 s | Bancada | Sim |
| 102 | Martelo de Ouro (`gold_hammer`) | 1 | 160× Madeira (`wood`), 120× Pedra (`stone`), 80× Ouro (`gold`), 1× Martelo de Pedra (`stone_hammer`) | 15 s | Bancada | Sim |
| 107 | Escudo de Madeira (`wood_shield`) | 1 | 100× Madeira (`wood`) | 25 s | Bancada | Sim |
| 108 | Escudo de Pedra (`stone_shield`) | 1 | 1× Escudo de Madeira (`wood_shield`), 100× Pedra (`stone`), 50× Madeira (`wood`) | 40 s | Bancada | Sim |
| 109 | Escudo de Ouro (`gold_shield`) | 1 | 1× Escudo de Pedra (`stone_shield`), 50× Ouro (`gold`), 50× Pedra (`stone`), 50× Madeira (`wood`) | 50 s | Bancada | Sim |
| 113 | Chave Inglesa (`wrench`) | 1 | 70× Pedra (`stone`) | 10 s | Bancada | Sim |
| 114 | Pá de Pedra (`stone_shovel`) | 1 | 30× Madeira (`wood`), 15× Pedra (`stone`) | 5 s | Bancada | Sim |
| 115 | Pá de Ouro (`gold_shovel`) | 1 | 1× Pá de Pedra (`stone_shovel`), 20× Ouro (`gold`), 30× Pedra (`stone`), 40× Madeira (`wood`) | 10 s | Bancada | Sim |
| 118 | Forcado (`pitchfork`) | 1 | 100× Madeira (`wood`), 50× Pedra (`stone`) | 10 s | Bancada | Sim |
| 120 | Regador (`watering_can`) | 1 | 50× Madeira (`wood`) | 5 s | Bancada | Sim |
| 137 | Totem (`totem`) | 1 | 50× Madeira (`wood`) | 10 s | Bancada | Sim |
| 140 | Canteiro (`plot`) | 1 | 20× Madeira (`wood`), 15× Terra (`ground`) | 5 s | Bancada | Sim |
| 141 | Semente de Frutinha (`berry_seed`) | 1 | 3× Frutinha (`berry`) | 5 s | Fogo | Sim |

## Problemas

Nenhum ingrediente impossível ou texto faltando nas receitas liberadas. (Nota: o modelo 3D `Assets.Icons.bandage` do Curativo fica para o Elizeu importar no Studio; até lá o slot mostra as iniciais.)
