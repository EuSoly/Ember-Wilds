## Starve.io — Catálogo completo e roadmap para o Roblox

Oct 28, 2026 · @Elizeu Walczuk Ruthes

### Resumo e como ler

O Starve.io é um survival multiplayer top-down de navegador (LapaMauve, França, 2016–2017): você coleta, crafta, constrói base e sobrevive à fome, à sede e ao frio enquanto lida com animais e outros jogadores. Este documento lista o conteúdo do jogo e marca cada item com o nível em que ele deveria entrar na nossa versão para o Roblox.

| Nível | Quando entra | O que agrupa |
|---|---|---|
| N0 — MVP | Lançamento | Floresta + loop básico: coletar, craftar, sobreviver à noite, PvP e ranking |
| N1 — Floresta completa | 2–4 semanas depois | Fazenda, times, baús, roubo, defesa de base, paredes e capacete de ouro |
| N2 — Inverno | 1–2 meses | Bioma de inverno, diamante e ametista, dragão e mamute (primeiros bosses), quests de tempo |
| N3 — Oceano | 2–3 meses | Praia, oceano, ilhas, oxigênio, barco, kraken, baús de tesouro |
| N4 — Deserto e lava | 3–5 meses | Endgame: esmeralda, reidite, arcos, proteções de calor, bosses finais |
| N5 — Extras | Quando houver público | Montarias, modos alternativos (zumbi, vampiro), eventos sazonais, itens de nicho |

Os nomes de itens aqui são os do Starve.io, só como referência. Na versão para o Roblox, nome, arte, ícones e sons precisam ser próprios, porque o jogo original é propriedade dos seus criadores.

### Mecânicas centrais

O jogo inteiro gira em torno de manter barras cheias: a vida só regenera quando fome, sede e frio estão acima de 35%, e qualquer barra vazia passa a tirar vida. O ciclo dia/noite (4 min + 4 min) dita o ritmo: de noite o frio cai muito mais rápido e você precisa de fogo.

| Mecânica | Como funciona no Starve.io | Nível |
|---|---|---|
| Vida | Cai com barra vazia, espinhos, mobs e jogadores. Regenera devagar só com as outras barras acima de 35% (e calor abaixo de 65% na lava) | N0 |
| Fome | Cai com o tempo. Cada comida repõe uma % da barra (frutinha 10%, carne assada 35%, sanduíche 100%) | N0 |
| Frio (temperatura) | Cai mais rápido de noite e no inverno; fogueira e roupas seguram. Na água cai mais rápido | N0 |
| Sede (hidratação) | Entrou junto com o oceano (jul/2017). Enche dentro d'água (rio, lago, mar) ou bebendo garrafa d'água | N0 (só lago/rio) |
| Dia e noite | Dia de 4 min, noite de 4 min. De noite o frio acelera, o visual muda e o minimapa fica mais difícil de ler | N0 |
| Inventário | 10 slots. A mochila dá +6 (16 no total) e duas quests dão +1 cada (no N4) | N0 |
| Crafting com tempo | Cada receita leva de 5 s a 3 min 20 s e gasta fome. O Livro ("IKEA Manual") deixa 3x mais rápido | N0 (tempo simples), Livro N1 |
| Armas na mão | Segurar espada ou lança deixa você mais lento, e a arma fica "travada" na mão alguns segundos após equipar | N0 |
| Pontos e ranking | Pontos por recurso coletado (ex.: diamante 4, esmeralda 20), por mob, por jogador morto (1/6 dos pontos da vítima) e por quest. Sobreviver AFK rende 500 pontos/dia | N0 |
| Morte | Você perde tudo e volta do zero. Os pontos viram moeda premium (ver Monetização) | N0 |
| Ressurreição | Com Pedra da Ressurreição + Coração de Dragão (ou Coroa do Anjo): 60 s para chegar à pedra, mantém 1/3 dos pontos, perde armas e picareta | N2 |
| Bandagem | Triplica a regeneração (15% a cada 10 s) enquanto as outras barras estão acima de 35% | N1 |
| Oxigênio | Cai enquanto você nada. Ponte, barco e roupa de mergulho resolvem | N3 |
| Calor | Barra própria do deserto (de dia) e da lava. Cheia, tira vida; cubos de gelo baixam | N4 |
| Controles | WASD ou setas + mouse | N0 (adicionar toque para celular) |

No Roblox, todas essas barras são atributos do jogador calculados no servidor a cada tick; nenhuma delas exige algo que a engine não tenha.

### Mapa e biomas

O mapa tem 5 biomas principais (floresta, inverno, oceano, deserto e lava) e 4 sub-áreas (rio, caverna do dragão, praia e ilhas). Todo mundo nasce na floresta, e cada bioma novo libera um tier de material, por isso eles funcionam como os "capítulos" naturais dos updates.

| Bioma | Onde fica | Recursos | Mobs | Regras e perigos | Nível |
|---|---|---|---|---|---|
| Floresta | Metade de baixo do mapa, ao lado do oceano. Ponto de spawn | Madeira, pedra, ouro, frutinhas; terra (pá) a partir do N1. Único lugar onde frutinha, trigo, abóbora e alho crescem sem canteiro | Coelho, lobo, aranha, javali, falcão | Mais quente, mobs mais fracos, movimento mais rápido. Sem diamante, ametista ou pele de inverno | N0 |
| Rio (dentro da floresta) | Corta a floresta de cima a baixo e termina num lago | Água | Piranha e kraken podem subir por ele | A correnteza empurra o jogador para baixo, exceto em ponte. Na água a sede enche e o oxigênio cai | N0 (como lago simples) |
| Inverno | Acima da floresta, cerca de 1/5 do mapa | Pedra, ouro e diamante (9 jazidas), sem reidite nem esmeralda; árvores dão 25–40 madeira; cubo de gelo (pá) | Raposa ártica, urso polar, pinguim, mamute, filhote de mamute, filhote de dragão | É o bioma mais frio: -20% de velocidade, sem plantas naturais nem lagos (água vem do gelo). Tem nevascas | N2 |
| Caverna do dragão | Canto superior esquerdo, entrando pelo inverno | Ametista (2 jazidas) | Até 5 dragões ao mesmo tempo | O dragão ignora quem usa o Chapéu de Explorador, a menos que seja atacado | N2 |
| Praia | Faixa fina entre floresta e oceano (menor bioma) | Areia (pá), que às vezes solta pedra, ouro, diamante ou ametista | Caranguejo, caranguejo-rei | Sem perigos próprios | N3 |
| Oceano | Cerca de 2/5 do mapa | Peixe | Piranha GMO, kraken | Sede enche, frio cai mais rápido, oxigênio acaba. Pontes e roupa de mergulho ajudam | N3 |
| Ilhas | 6 ilhas no oceano | Baús de tesouro (1 item aleatório cada, reaparecem em outra ilha) | — | Contam como floresta para regras e quests | N3 |
| Deserto | Canto sudeste, cerca de 1/5 do mapa | Esmeralda (3 jazidas), cacto, babosa | Abutre, verme de areia | Quente de dia, frio de noite. Tempestades de areia dão dano rápido; turbante ou telhado protegem. Abutre ataca quem não está sob telhado | N4 |
| Lava | Canto superior direito, cerca de 1/5 do mapa | Reidite (cerca de 5 jazidas) | Monstro de lava, dragão de lava, filhote de dragão de lava | Barra de calor; poças e rios de lava dão muito dano (ponte evita). Comer cubo de gelo esfria; a wiki recomenda levar 300–500 | N4 |

As frações de área são as da wiki e não fecham 100%, então tome como ordem de grandeza. No Roblox, dá para manter o mesmo layout num mapa único com StreamingEnabled, e ir "abrindo" as regiões a cada update.

### Recursos e materiais

A progressão é uma escada de 6 materiais de mineração: madeira → pedra → ouro → diamante → ametista → reidite (a esmeralda é um ramo lateral do deserto). Cada picareta libera o material seguinte. O resto dos recursos vem de pá, plantas e drops de mobs.

#### Mineração e solo

| Recurso | Onde | Ferramenta mínima | Usos principais | Nível |
|---|---|---|---|---|
| Madeira | Árvores (floresta; no inverno rendem 25–40) | Mão | Quase tudo, combustível de fornalha e forno | N0 |
| Pedra | Rochas | Picareta de madeira | Ferramentas, paredes, fogueiras | N0 |
| Ouro | Jazidas de ouro | Picareta de pedra | Tier ouro, coroas, fornalha, baú | N0 |
| Diamante | Inverno, 9 jazidas (pequena até 10, média até 20, grande até 30) — 4 pontos cada | Picareta de ouro | Tier diamante, pedra da ressurreição | N2 |
| Ametista | Caverna do dragão, 2 jazidas | Picareta de diamante | Tier ametista | N2 |
| Reidite | Lava, cerca de 5 jazidas | Picareta de ametista | Tier reidite, armas de lava | N4 |
| Esmeralda | Deserto, 3 jazidas — 20 pontos cada | Picareta de ametista (1/golpe) | Máquina de Esmeralda, arco e flechas de dragão | N4 |
| Terra | Floresta, infinita | Pá | Canteiro, poço | N1 |
| Areia | Praia | Pá | Garrafa, sela | N3 |
| Cubo de gelo | Inverno | Pá | Vira água no inverno, esfria na lava, bolo | N2 |

#### Rendimento por golpe da picareta

| Picareta | Madeira | Pedra | Ouro | Diamante | Ametista | Reidite | Esmeralda |
|---|---|---|---|---|---|---|---|
| Madeira | 2 | 1 | — | — | — | — | — |
| Pedra | 3 | 2 | 1 | — | — | — | — |
| Ouro | 4 | 3 | 2 | 1 | — | — | — |
| Diamante | 5 | 4 | 3 | 2 | 1 | — | — |
| Ametista | 6 | 5 | 4 | 3 | 2 | 1 | 1 |
| Reidite | 7 | 6 | 5 | 4 | 3 | 2 | 2 |

#### Drops de mobs

| Drop | Quem dropa | Usado em | Nível |
|---|---|---|---|
| Carne crua | Coelho, lobo, raposa, urso, dragão, javali, mamute, falcão | Comida (assar na fogueira) | N0 |
| Pele de coelho | Coelho | Protetor de orelha, túnica, capuz, chapéu de explorador, sela | N0 |
| Pele de lobo | Lobo | Mochila, casaco, capuz, livro, sela | N0 |
| Linha | Aranha (2) | Bandagem, roupas, moinho, mochila | N0 |
| Pele de javali | Javali | Turbante, roupa ninja | N1 |
| Pele de inverno | Raposa ártica (1), urso polar (2) | Gorro e cachecol, capuz e túnica de inverno | N2 |
| Pena de pinguim | Pinguim | Trenó, capuz de inverno, flechas, chapéu de piloto | N2 |
| Pele de mamute | Mamute (10), filhote (1) | Chapéu de pele (melhor proteção de frio) | N2 |
| Coração de dragão | Dragão | Ressurreição, Coroa do Anjo, espada/lança de dragão | N2 |
| Peixe | Piranha (2), kraken (5) | Comida | N3 |
| Escama de piranha | Piranha | Máscara de mergulho, super martelo, barco | N3 |
| Pele de kraken | Kraken | Roupa de mergulho, super martelo | N3 |
| Garra e carne de caranguejo | Caranguejo (1+1), caranguejo-rei (4+4) | Comida, capacete e lança de caranguejo | N3 |
| Pena de falcão | Falcão (até 4) | Avião, arco de ouro, flecha de pedra, chapéu de piloto | N4 |
| Pena de abutre | Abutre | Flechas de ametista e reidite, roupa ninja | N4 |
| Chama | Monstro de lava | Proteções de calor, flecha de reidite | N4 |
| Coração de lava | Dragão de lava | Espada, lança e capacete de lava | N4 |
| Suco de verme | Verme de areia | Máquina de Esmeralda, flechas de dragão | N4 |

Itens de quest (gemas, orbes e cubos) estão em Sistemas sociais, junto com as quests que os dão.

### Ferramentas e armas

Toda ferramenta e arma segue o mesmo padrão: o tier novo pede o tier anterior + materiais, sempre na bancada. Espada tem alcance curto e mais dano; lança tem mais alcance e atinge através de estruturas e arbustos. Receitas e danos abaixo vêm da NamuWiki e da wiki do Fandom; tempos são de crafting sem Livro.

#### Picaretas

| Item | Receita | Tempo | Nível |
|---|---|---|---|
| Picareta de madeira | 10 madeira (sem bancada) | 5 s | N0 |
| Picareta de pedra | 50 madeira, 15 pedra + anterior | 15 s | N0 |
| Picareta de ouro | 40 madeira, 30 pedra, 20 ouro + anterior | 20 s | N0 |
| Picareta de diamante | 80 pedra, 50 ouro, 20 diamante + anterior | 30 s | N2 |
| Picareta de ametista | 60 ouro, 40 diamante, 30 ametista + anterior | 2 min | N2 |
| Picareta de reidite | 40 diamante, 30 ametista, 30 reidite + anterior | — | N4 |

#### Espadas

| Item | Receita | Dano | Nível |
|---|---|---|---|
| Espada de madeira | 30 madeira (sem bancada) | 12 | N0 |
| Espada de pedra | 50 madeira, 25 pedra + anterior | 19 | N0 |
| Espada de ouro | 60 madeira, 50 pedra, 40 ouro + anterior | 22 | N0 |
| Espada de diamante | 80 pedra, 60 ouro, 40 diamante + anterior | 24 | N2 |
| Espada de ametista | 100 ouro, 60 diamante, 40 ametista + anterior | 27 | N2 |
| Espada de dragão | 100 ametista, 20 diamante, 3 corações de dragão, 1 Orbe Azul (bancada + fogo + água) | 30 | N2 |
| Espada de reidite | 100 diamante, 80 ametista, 40 reidite + anterior (bancada + fogo) | 30 | N4 |
| Espada de lava | Espada de dragão, 150 reidite, 2 corações de lava, 1 Orbe de Lava | 33 (bônus contra mobs de lava) | N4 |
| Espada pirata | Não se crafta: sai de baú de tesouro | 24, um pouco mais de alcance | N3 |
| Espada amaldiçoada | Hoje inobtenível (pedia Orbe Vermelho, comprado com 500 mil pontos). Não pode ser desequipada e aumenta frio e fome | — | Fora |

#### Lanças

| Item | Receita | Dano | Nível |
|---|---|---|---|
| Lança de madeira | 40 madeira (sem bancada) | 10 | N0 |
| Lança de pedra | 60 madeira, 10 pedra + anterior | 14 | N0 |
| Lança de ouro | 80 madeira, 30 pedra, 30 ouro + anterior | 15 | N0 |
| Lança de diamante | 200 madeira, 60 ouro, 40 diamante + anterior | 17 | N2 |
| Lança de ametista | 90 ouro, 80 diamante, 40 ametista + anterior | 18 | N2 |
| Lança de dragão | 100 ametista, 20 diamante, 3 corações de dragão, 1 Orbe Azul + lança de reidite | 22 | N2 (sem o pré-requisito de reidite) |
| Lança de reidite | 100 diamante, 80 ametista, 40 reidite + anterior | 24 | N4 |
| Lança de lava | 100 reidite, 2 corações de lava, 1 Cubo de Lava + lança de dragão | 24 (bônus contra mobs de lava) | N4 |
| Lança de caranguejo | 20 garras de caranguejo, 10 linhas + lança de madeira | 14. Acalma e cura caranguejos | N3 |

#### Martelos, pás e escudos

| Item | Receita | Efeito | Nível |
|---|---|---|---|
| Martelo de pedra | 90 madeira, 50 pedra | Dano em construção 10 | N1 |
| Martelo de ouro | 160 madeira, 120 pedra, 80 ouro + anterior | Construção 20 | N1 |
| Martelo de diamante | 200 pedra, 150 ouro, 80 diamante + anterior | Construção 30 | N2 |
| Martelo de ametista | 250 ouro, 160 diamante, 60 ametista + anterior | Construção 50 | N2 |
| Martelo de reidite | 250 diamante, 160 ametista, 60 reidite + anterior | Construção 60 | N4 |
| Super martelo | 1 garrafa d'água, 1 pele de kraken, 10 escamas de piranha, 20 ametista | Dano 12, construção 70 | N3 |
| Pá de pedra / ouro | 30 madeira + 15 pedra / 30 pedra + 15 ouro | 1 / 2 itens por golpe (terra, areia, gelo) | N1 |
| Pá de diamante / ametista | 30 ouro + 15 diamante / 30 diamante + 15 ametista | 3 / 4 itens por golpe | N2 |
| Escudo de madeira → ouro | 100 madeira; depois + pedra; depois + ouro | Defesa contra jogador 1–3, contra flecha 13–21. Soma com o capacete | N1 |
| Escudo de diamante / ametista | Diamante: 50 pedra, 50 ouro, 50 diamante + anterior. Ametista: upgrade (receita não encontrada) | Defesa 4–5, contra flecha 25–29 | N2 |
| Escudo de reidite | Upgrade do de ametista | Defesa 6, contra flecha 33 | N4 |

#### Arcos e flechas

Existem arcos de madeira, pedra, ouro, diamante, ametista, reidite e dragão; cada flecha só funciona no arco do mesmo tier ou acima. As páginas dos arcos não abriram, então abaixo estão só as flechas.

| Flecha | Receita | Dano jogador / mob | Nível |
|---|---|---|---|
| Madeira | 30 madeira | — (alcance 2/3 das outras) | N4 |
| Pedra | 20 pedra, 1 pena de falcão | — | N4 |
| Ouro | 20 ouro, 1 pena de pinguim | 25 / 200 | N4 |
| Diamante | 10 diamante, 1 pena de pinguim | 30 / 300 | N4 |
| Ametista | 10 ametista, 1 pena de abutre | 35 / 600 | N4 |
| Reidite | 10 reidite, 1 pena de abutre, 1 chama | 35 / 900 | N4 |
| Dragão | 10 esmeralda, 1 suco de verme | 45 / 1200 | N4 |

Arcos ficam todos no N4 porque combate à distância muda o equilíbrio do PvP inteiro e depende de penas de mobs que só entram depois.

#### Utilitários

| Item | Receita | Efeito | Nível |
|---|---|---|---|
| Garrafa / garrafa d'água | Bancada; no Starve.io leva areia, que só vem da praia (N3). No MVP, usar uma receita só com madeira e pedra. Enche na água | Carrega água para beber | N0 |
| Papel | 20 madeira em qualquer fogo | Livro, chapéu de explorador, avião | N1 |
| Livro ("IKEA Manual") | 4 papel, 4 linha, 4 pele de lobo | Crafting 3x mais rápido segurando | N1 |
| Bandagem | 2 linhas | Regeneração 3x | N1 |
| Regador | 50 madeira; enche em fonte d'água | Rega plantas; infinito depois de cheio | N1 |
| Balde | 20 madeira, 1 linha | Só serve para encher o poço (1 balde = 12 garrafas) | N1 |
| Chave inglesa | 70 pedra | Conserta paredes, portas e espinhos | N1 |
| Linha azul | Bancada (quantidades não encontradas) | Roupas de inverno e barco | N2 |
| Forcado / forcado de ouro | Peça de quest; o de ouro pede 1 melancia + 250 ouro | Ligado à fazenda no mar (página não abriu) | N3 |
| Facão | Página não abriu | Mata monstros de lava mais rápido | N4 |
| Sela | 10 linhas, 6 pele de lobo, 4 pele de coelho, 50 areia | Domar e montar mobs neutros | N5 |

### Equipamentos

O jogador usa um item de cabeça por vez (capacete, roupa ou coroa) mais a mochila. Por isso cada peça de roupa é uma escolha: defesa, frio, roubo, fazenda ou mergulho. Essa troca é boa de manter no Roblox, porque cria decisões sem precisar de muito conteúdo.

#### Capacetes (defesa contra jogador / contra mob)

| Item | Receita | Defesa | Nível |
|---|---|---|---|
| Capacete de madeira | 50 madeira | 1 / 4 | N0 |
| Capacete de pedra | 75 madeira, 75 pedra | 2 / 8 | N0 |
| Capacete de ouro | 90 madeira, 90 pedra, 90 ouro + anterior | 4 / 16 | N1 |
| Capacete de diamante | 100 pedra, 100 ouro, 100 diamante + anterior | 5 / 20 | N2 |
| Capacete de ametista | 150 ouro, 120 diamante, 80 ametista + anterior | 6 / 24 | N2 |
| Capacete de dragão | Capacete de ametista, 150 diamante, 1 Cubo Azul (bancada + fogo + água) | 8 / 27 | N2 |
| Capacete de caranguejo | 10 garras, 10 carnes de caranguejo, 10 linhas + capacete de ouro | Igual ao de diamante; caranguejos seguem você | N3 |
| Capacete de reidite | Página não abriu | — | N4 |
| Capacete de lava | Capacete de dragão, 150 reidite, 2 corações de lava, 1 Cubo de Lava | O mais forte; aranha não dá dano | N4 |

#### Roupas de frio e calor

| Item | Receita | Efeito | Nível |
|---|---|---|---|
| Protetor de orelha | 1 pele de coelho, 2 linhas | Frio cai mais devagar (tier 1) | N0 |
| Casaco | 10 pele de lobo, 6 linhas + protetor | Tier 2; de dia na floresta não perde calor | N1 |
| Gorro e cachecol | 5 pele de inverno, 4 linha azul + casaco | Tier 3, para o inverno | N2 |
| Chapéu de pele | Gorro e cachecol, 5 pele de inverno, 10 pele de mamute, 4 linha azul | Melhor proteção de frio; dá para ficar AFK na floresta sem fogo | N2 |
| Turbante | 4 linhas, 2 pele de javali | Protege de tempestade de areia, frio e calor do deserto | N4 |
| Roupa ninja | Gorro e cachecol, 6 linhas, 4 pele de javali, 12 pena de abutre, 4 pena de pinguim | Quase imune a tempestade de areia; fresco na lava | N4 |
| Chapéu de piloto | 8 penas de cada (falcão, abutre e pinguim), 6 linhas, Óculos de Piloto (quest) | Temperatura estável no deserto | N4 |
| Proteção de diamante | Página não abriu | Para a barra de calor perto do fogo | N4 |
| Proteção de ametista | 100 ametista, 15 chamas + proteção de diamante | Reduz muito o calor da lava | N4 |
| Proteção de reidite | 100 ametista, 100 reidite, 25 chamas + anterior | Permite ficar AFK na lava | N4 |

#### Roupas especiais

| Item | Receita | Efeito | Nível |
|---|---|---|---|
| Mochila | 5 pele de lobo, 6 linhas | +6 slots (16 no total) | N0 |
| Chapéu de explorador | 1 pele de coelho, 1 papel, 2 linhas | Mobs hostis ignoram você; atacar ou minerar desliga por 10 s | N1 |
| Capuz | 5 pele de coelho, 10 pele de lobo, 6 linhas | Esconde o nome e permite roubar (ver Sistemas sociais) | N1 |
| Capuz de inverno | Capuz, 15 pele de inverno, 5 linha azul, 8 pena de pinguim, 1 Pele de Lobo Preto (quest) | Rouba a cada 4 s e de qualquer um; esquenta mais | N2 |
| Túnica de camponês | 3 pele de coelho, 2 linhas | Plantações crescem 20% mais rápido; imune ao capuz comum | N1 |
| Túnica de camponês de inverno | Túnica, 10 pele de inverno, 5 linha azul, 2 pena de pinguim, 1 Pele de Lobo Branco (quest) | +40% de crescimento; imune a qualquer capuz | N2 |
| Máscara de mergulho | 40 diamante, 2 escamas de piranha, 4 linhas | Gasta menos oxigênio, mais rápido na água | N3 |
| Roupa de mergulho | Máscara, 80 ouro, 20 ametista, 1 pele de kraken | Muito menos oxigênio e mais velocidade na água | N3 |
| Chapéu de bruxa | 5 pele de lobo, 2 pele de coelho, 6 linhas, 2 vaga-lumes | Voa na vassoura e usa varinhas (Halloween) | N5 |
| Gorro de Natal / de elfo | Saem do presente de Natal | Frio como casaco / protetor | N5 |

#### Coroas (bancada + fogo + água)

| Item | Receita | Efeito | Nível |
|---|---|---|---|
| Coroa da Vida | 100–200 ouro + Gema Verde (quest: 4 dias sem perder vida) | Regeneração extra a cada 10 s; defesa de capacete de ouro | N2 |
| Coroa do Anjo | 200 ouro, 1 coração de dragão, Gema Azul (quest: 6 dias pacífico) | Permite ressuscitar na pedra; protege menos contra jogadores | N2 |
| Coroa da Sorte | 200 ouro + Gema Laranja (quest: abrir 5 baús de tesouro) | Itens melhores nos baús, mais minério na pá, chance de domar até 5x | N3 |

As fontes divergem em alguns valores das coroas (100 ou 200 de ouro); vale testar no jogo antes de copiar números.

### Comida, bebida e agricultura

No começo você vive de frutinha e carne assada; a fazenda (trigo → farinha → pão) é o que permite ficar dias na base sem caçar. Os valores são a % da barra de fome que cada item repõe.

#### Comidas e bebidas

| Item | Como obter | Fome | Extra | Nível |
|---|---|---|---|---|
| Frutinha | Arbusto na floresta | 10% | — | N0 |
| Carne crua | Drop de mobs | 15% | Tira um pouco de vida | N0 |
| Carne assada | Carne crua perto do fogo | 35% | — | N0 |
| Garrafa d'água | Garrafa cheia em água | — | Mata a sede | N0 |
| Pão | 3 farinhas no fogo, ou 1 farinha + 1 madeira no forno | 15% | — | N1 |
| Biscoito | 3 farinhas + 1 frutinha no fogo | 50% | — | N1 |
| Sanduíche | 1 pão + 1 carne assada | 100% | — | N1 |
| Abóbora | Plantação | 30% | — | N1 |
| Bolo | 5 farinhas, 2 frutinhas, 2–10 cubos de gelo no fogo | 100% | — | N2 |
| Peixe cru / assado | Piranha, kraken; assar no fogo | 18% / 35% | Cru tira vida | N3 |
| Carne e garra de caranguejo | Caranguejo | 20% / 10% | — | N3 |
| Cenoura | Plantação | 20% | — | N3 |
| Tomate | Plantação | 16% | — | N3 |
| Melancia | Plantação | 15% | +8% de água | N3 |
| Cacto | Deserto | 20% | +10% de água, mas dá dano (pode matar) | N4 |
| Babosa | Deserto | — | Alimenta e cura com o tempo | N4 |
| Alho | Plantação | 14% | Segura o frio por alguns segundos; mata vampiro | N5 |
| Doce / bengala doce | Presente de Natal | 100% | Item sazonal | N5 |

#### Plantações

A semente se faz perto do fogo a partir do próprio fruto, dura 8 dias e precisa ser regada. Tempos abaixo são para crescer no chão da floresta, sem canteiro.

| Semente | Receita | Crescer | Rega a cada | Nível |
|---|---|---|---|---|
| Frutinha | 3 frutinhas | 55 s | 3 min 20 s | N1 |
| Trigo | 3 trigos | 16 s | 2 min | N1 |
| Abóbora | 8 abóboras | 2 min | 2 min | N1 |
| Arbusto de espinho | 8 arbustos | 15 s | 3 min | N1 (dá 20 de dano, vira defesa) |
| Cenoura | 8 cenouras | 30 s | 1 min 40 s | N3 |
| Tomate | 8 tomates | 30 s | 1 min 40 s | N3 |
| Melancia | 16 melancias | 3 min | 3 min 20 s | N3 |
| Babosa | 16 babosas | — | — | N4 |
| Alho | 8 alhos | 1 min 10 s | 1 min 40 s | N5 |

#### Estruturas da fazenda

| Estrutura | Receita | Efeito | Nível |
|---|---|---|---|
| Canteiro | 20 madeira, 15 terra | Crescimento 2x (trigo 16 s → 8 s; com túnica de inverno, 4,8 s). Necessário para plantar fora da floresta | N1 |
| Moinho | 60 madeira, 20 pedra, 2 linhas | Transforma trigo em farinha | N1 |
| Forno de pão | 40 madeira, 40 pedra | Assa pão queimando madeira | N1 |
| Poço | 100 pedra, 30 terra | Guarda água; 1 balde = 12 garrafas | N1 |

O ciclo da fazenda é o que segura o jogador na base; por isso ele entra já no N1, logo depois do lançamento.

### Estruturas e construção

A base é feita de peças colocadas no grid: paredes, portas (só você e o time abrem) e espinhos que dão dano por contato. Cada tier é um upgrade em cima da peça anterior. No Roblox, esta é a parte que mais pesa no servidor, então precisa de limite de peças por jogador.

#### Estações e fogo

| Estrutura | Receita | Efeito | Nível |
|---|---|---|---|
| Bancada | 20–35 madeira, 10 pedra | Necessária para quase toda receita | N0 |
| Fogueira | 25 madeira, 5 pedra | Aquece e cozinha; dura cerca de 2 min; queima quem fica em cima | N0 |
| Fogueira grande | 35 madeira, 10 pedra + fogueira | Dura cerca de 6 min | N0 |
| Fornalha | 150 madeira, 50 pedra, 15 ouro | Queima 1 madeira a cada 5 s (cerca de 40 por noite); não queima quem está no centro | N1 |
| Fogo + água + bancada | Ficar perto dos três | Exigência das receitas de coroa, dragão e lava | N2 |

#### Paredes, portas e espinhos (vida da peça)

| Material | Parede | Porta | Espinho (vida / dano) | Porta-espinho (dano) | Nível |
|---|---|---|---|---|---|
| Madeira | 20 madeira, 1000 | 30 madeira, 1000 | 300 / 10 | 5 | N0 |
| Pedra | 17 pedra, 1500 | 27 pedra, 1500 | 600 / 20 | 10 | N0 |
| Ouro | 14 ouro, 2000 | 24 ouro, 2000 | 900 / 30 | — | N1 |
| Diamante | 11 diamante, 2500 | 21 diamante, 2500 | 1200 / 40 | 20 | N2 |
| Ametista | 8 ametista, 3500 | 18 ametista, 3500 | 2400 / 50 | 25 | N2 |
| Reidite | — | — | — | 30 | N4 |

Paredes e portas levam 5–8 s para craftar; espinhos, 20 s. Uma parede que virou espinho não sobe mais de tier. Martelos e picaretas quebram peças acima de madeira; espadas e lanças quase não dão dano nelas.

#### Base e utilidades

| Estrutura | Receita | Efeito | Nível |
|---|---|---|---|
| Baú | 25 madeira, 2 ouro | Guarda 1 tipo de item; 500 de vida | N1 |
| Cadeado / chave | 10 ouro / 250 ouro | Tranca o baú / abre baú trancado | N1 |
| Totem | 50 madeira | Cria um time de até 8 (ver Sistemas sociais) | N1 |
| Telhado | 30 madeira | Protege de sol e tempestade; abaixo dele o frio cai mais devagar | N1 |
| Cama | 100 madeira, 50 pedra, 5 pele de lobo, 5 pele de coelho, 6 linhas | Deitado, as barras caem mais devagar e a vida regenera mais rápido | N1 |
| Placa | 20 madeira | 4 mensagens fixas: "Sem briga", "Sirva-se", "Não entre", "Socorro" | N1 |
| Ponte | 30 madeira | Permite construir e andar sobre a água sem perder oxigênio | N3 |
| Pedra da Ressurreição | 45 pedra, 40 diamante | Ponto de renascimento (ver Mecânicas) | N2 |
| Máquina de Esmeralda | 40 esmeralda, 1 suco de verme, 1 pedra da ressurreição (bancada + fogo + água) | Gera pontos por dia: floresta 6 mil, inverno 8 mil, lava 10 mil, deserto 12 mil. Uma por partida; se for destruída, você morre | N4 |
| Torre, extrator | Páginas não abriram | Constam na lista de itens da wiki | N5 |

#### Veículos

| Veículo | Receita | Efeito | Nível |
|---|---|---|---|
| Trenó | Madeira, linhas, pele de inverno, penas de pinguim | Mais rápido no inverno | N2 |
| Barco | 250 madeira, 10 linha azul, escamas de piranha | Mais rápido no mar, funciona como ponte, não perde oxigênio | N3 |
| Avião | 250 madeira, 10 papel, 8 penas de falcão, 10 linhas | Voa sobre floresta, inverno e oceano; você não ataca no ar, mas pode ser atacado | N4 |

### Animais, NPCs e bosses

São cerca de 25 mobs. Para o MVP bastam 3 (coelho, lobo e aranha), que cobrem os três comportamentos que todo o resto reaproveita: fugir, perseguir e prender. A wiki quase não traz vida e dano exatos; onde há número, ele está na tabela.

| Mob | Bioma | Comportamento | Stats | Drops | Nível |
|---|---|---|---|---|---|
| Coelho | Floresta | Passivo; foge e é mais rápido que o jogador | — | 1–2 carnes, 1 pele de coelho | N0 |
| Lobo | Floresta | Hostil; persegue até perder linha de visão; mais lento que o jogador | Cada mordida tira cerca de 1/5 da vida | 2 carnes, 1 pele de lobo | N0 |
| Aranha | Floresta | Hostil e rápida, para bastante; prende na teia por 2–3 s e depois bate forte | — | 2 linhas | N0 |
| Javali | Floresta | Neutro, forte. Domável com sela (10%) | — | Pele de javali, carne | N1 |
| Falcão | Floresta | Neutro, voa. Domável (3%) | Igual ao lobo | 2 carnes, até 4 penas | N4 |
| Raposa ártica | Inverno | Hostil; mais rápida que você quando você está atacando | Igual ao lobo | 1 pele de inverno, 2 carnes | N2 |
| Urso polar | Inverno | Hostil, lento, muita vida | Mata em cerca de 3 golpes | 2 peles de inverno, 3 carnes | N2 |
| Pinguim | Inverno | Página não abriu; foge como o coelho | — | Penas de pinguim | N2 |
| Filhote de mamute | Inverno | Neutro; ataca se provocado. Domável (1%) | Dano 50 (1/4 da vida) | 3 carnes, 1 pele de mamute | N2 |
| Mamute (boss) | Inverno | Agressivo, quebra construções e fogueiras | Vida 2x a do dragão; 150 de dano em construção | 10 peles de mamute, 7 carnes | N2 |
| Dragão (boss) | Caverna do dragão | Hostil; até 5 na caverna; quebra construções | 90 de dano em construção | 5 carnes, coração de dragão | N2 |
| Filhote de dragão | Inverno | Neutro. Domável (1%) | — | — | N5 |
| Caranguejo | Praia | Neutro; depois de atacado persegue em qualquer bioma | — | 1 garra, 1 carne de caranguejo | N3 |
| Caranguejo-rei | Praia | Neutro, grande. Domável (2%) e montável | — | 4 garras, 4 carnes | N3 |
| Piranha GMO | Oceano | Hostil; sobe em pontes | — | 1 escama, 2 peixes | N3 |
| Kraken (boss) | Oceano | Hostil; sobe em pontes; se voltar ao mar a luta reseta | Vida 6000, dano 99 (mata em 3 golpes) | Pele de kraken, 5 peixes | N3 |
| Monstro de lava | Lava | Hostil; o toque tira metade dos seus cubos de gelo | — | Chama | N4 |
| Dragão de lava | Lava | Raro; segue você fora da lava, mas fica mais lento | Vida 3000, dano 90 | Coração de lava | N4 |
| Filhote de dragão de lava | Lava | Neutro; domável (0,2%); a montaria mais rápida | Vida 1500, dano 70 | — | N5 |
| Abutre | Deserto | Hostil, voa; para quando você entra sob telhado | Muita vida e velocidade | Penas de abutre | N4 |
| Verme de areia (boss) | Deserto | Persegue por baixo da areia; só leva dano quando sai | Vida igual à do dragão | Suco de verme | N4 |
| Zumbi | Só no modo Zumbi | Jogador transformado; dano cresce com os dias (2 + dia) | Super zumbi: 10 + 2 × dia | — | N5 |
| Vampiro | Só no modo Vampiro | Jogador; mais forte de noite, toma dano do sol fora do telhado, morre com alho | — | — | N5 |

#### Objetos que se comportam como mob

| Objeto | Onde | Como funciona | Nível |
|---|---|---|---|
| Baú de tesouro | Ilhas (até 6 por ilha) | Bate até quebrar; dá 1 item aleatório, às vezes de tier máximo; reaparece em outra ilha | N3 |
| Presente de Natal | Floresta, no evento | Bate até quebrar; dá gorro de Natal ou de elfo, doce, bengala doce, espada pirata ou guirlanda | N5 |

#### Domar e montar

Com a sela você bate num mob neutro: se der certo, ele vira montaria; se falhar, fica agressivo. A Coroa da Sorte multiplica a chance por até 5. Chances base: javali 10%, falcão 3%, caranguejo-rei 2%, filhote de mamute 1%, filhote de dragão 1%, filhote de dragão de lava 0,2%. Todo o sistema fica no N5, porque depende de quase todos os biomas.

### Sistemas sociais e quests

O servidor é PvP livre: qualquer um pode atacar qualquer um. O que segura a convivência são três sistemas: times pelo totem, roubo com o capuz e as "chrono quests", que dão os melhores itens a quem cumpre regras de comportamento (não atacar, não tomar dano) por vários dias.

#### Times, PvP e roubo

| Sistema | Como funciona | Nível |
|---|---|---|
| PvP livre | Matar um jogador dá 1/6 dos pontos dele e larga os itens no chão (caixa de loot) | N0 |
| Totem (times) | Até 8 membros. Companheiros dão 30% de dano entre si, abrem as portas e baús trancados um do outro e não tomam dano dos espinhos do time. O líder expulsa; quem sai espera cerca de 20 s para entrar em outro. O totem pode ser trancado | N1 |
| Roubo com capuz | De noite, longe de fogo e de mãos vazias: um soco tira um item do inventário da vítima. Precisa de 8 s com o capuz para armar e 8 s de recarga após roubar ou apanhar. Não rouba item equipado nem quem usa túnica de camponês | N1 |
| Roubo com capuz de inverno | Recarga de 4 s e rouba de qualquer um, exceto túnica de camponês de inverno | N2 |
| Placas | 4 mensagens fixas, um jeito seguro de comunicação | N1 |
| Chat | Chat de texto do servidor. No Roblox usar o TextChatService padrão, com filtro obrigatório | N0 |

#### Chrono quests

Cada quest tem um prazo em dias de jogo (1 dia = 8 min) e dá um item que só existe por ela. As fontes divergem em alguns prazos; usamos o da página do item quando havia.

| Recompensa | Condição | Serve para | Nível |
|---|---|---|---|
| Gema Verde | Sobreviver 4 dias sem perder vida | Coroa da Vida | N2 |
| Gema Azul | 6 dias sem atacar jogadores nem mobs não agressivos, sem colocar espinhos | Coroa do Anjo | N2 |
| Orbe Azul | Pegar um coração de dragão em menos de 5 dias | Espada, lança e arco de dragão | N2 |
| Cubo Azul | Pegar 1 ametista em menos de 4–6 dias | Capacete de dragão | N2 |
| Pele de Lobo Preto | Sobreviver 4–5 dias no inverno | Capuz de inverno | N2 |
| Pele de Lobo Branco | Juntar 100 pães no inverno em 3–4 dias | Túnica de camponês de inverno | N2 |
| Gema Laranja | Abrir 5 baús de tesouro em 2–4 dias | Coroa da Sorte | N3 |
| Peça de forcado | Página não abriu | Forcado de ouro | N3 |
| Orbe de Lava | Matar um dragão de lava em até 10 dias | Espada de lava (as fontes divergem sobre a lança) | N4 |
| Cubo de Lava | Condição não encontrada | Capacete e lança de lava | N4 |
| Óculos de Piloto | Conseguir 1 esmeralda (uma das mais difíceis) | Chapéu de piloto | N4 |
| +1 slot de mochila | Matar 1 verme de areia em 8 dias | Inventário | N4 |
| +1 slot de mochila | Explorar cada bioma por pelo menos 1 dia, em 7 dias | Inventário | N4 |

As quests são o melhor recurso de retenção do jogo: dão um objetivo de várias sessões dentro de uma partida que, de resto, recomeça do zero a cada morte. O sistema entra no N2 e cada update seguinte traz as quests do seu bioma.

### Modos de jogo

O modo Normal é o jogo; os outros são variações de regra sobre o mesmo conteúdo. A wiki lista seis modos e cerca de 30–42 servidores em várias regiões (EU, NA, AS, RU, AU), com 1000–2000 jogadores simultâneos na época em que foi escrita.

| Modo | O que muda | Nível |
|---|---|---|
| Normal | Todos contra todos; entra e sai quando quiser; mapa completo (no nosso MVP, só a floresta) | N0 |
| Legacy / Forest | Pelo nome, uma versão clássica focada na floresta; a wiki não detalha as regras (Legacy foi renomeado para Forest por volta de 2019) | N5 (quase de graça: é o próprio MVP) |
| Hunger Games | Partida com fim: último vivo ganha. Saiu do jogo em jul/2018 | N5 |
| Zumbi | A partir do 3º dia, quem morre volta como zumbi. Zumbi usa capacete mas não arma, não coleta e não entra no ranking; o dano cresce com os dias (2 + dia; super zumbi 10 + 2 × dia) | N5 |
| Vampiro | Vampiros são jogadores: mais rápidos e fortes de noite, tomam dano do sol fora do telhado (sombra de árvore não conta), começam com 4 telhados e morrem ao comer alho | N5 |
| Community / Experimental | Servidores de teste e da comunidade; a wiki não descreve as regras | Fora |

No Roblox, cada modo pode ser um "place" dentro da mesma experiência, com o mesmo código e uma tabela de regras diferente. Isso deixa os modos baratos depois que o jogo base estiver pronto.

### Monetização e cosméticos

O Starve.io ganha dinheiro com uma moeda premium, o Pão Dourado, gasta em roletas de cosméticos e num kit inicial. A maior parte do Pão Dourado sai jogando: os seus pontos viram moeda quando você morre. O app Android complementa com anúncios e compras (cerca de metade da receita cada).

#### Como funciona no Starve.io

| Elemento | Detalhe |
|---|---|
| Pão Dourado (moeda premium) | Ganha 1 por 1.000 pontos ao morrer (máx. 500 por partida e 60 por hora), 10 × nível ao subir de nível, 100 no primeiro login. Também vendido na loja (preço não encontrado) |
| Roleta de skin | Inicial 100, Dourada 300, Dragão 600 pães. Dá skins de personagem e acessórios |
| Roleta custom | Inicial 50, Dourada 150, Dragão 300 pães. Dá skins de livro, mochila, caixa e acessórios |
| Raridades | Madeira, pedra, ouro, diamante, ametista, reidite (as mesmas dos materiais). Cada roleta sorteia 4 delas: Inicial madeira→diamante, Dourada pedra→ametista, Dragão ouro→reidite |
| Tipos de cosmético | Skins do personagem, 57 acessórios (12 por nível, 45 por roleta), caixa de loot, caixa de morte, livro e mochila |
| Kit inicial | 300 pães por 1 hora ou 600 por 24 horas: você nasce com livro e mochila |
| Orbe Vermelho | Antigo kit de 500 mil pontos; dava a Espada Amaldiçoada. Hoje fora do jogo |
| Anúncios | Só confirmados no app Android |

#### Como traduzir para o Roblox

| No Starve.io | No Roblox | Nível |
|---|---|---|
| Pontos → moeda ao morrer | Moeda soft própria, ganha pela pontuação de cada vida e salva no DataStore | N0 |
| Loja de skins e acessórios | Loja de cosméticos com moeda soft + Robux (Developer Products). Cosmético não dá vantagem | N0 (poucos itens), cresce a cada update |
| Pão Dourado vendido na loja | Pacotes de moeda como Developer Products | N0 |
| Roletas com raridade | Caixas de cosmético. A Roblox exige mostrar as chances antes da compra de itens aleatórios pagos | N1 |
| Kit inicial (livro + mochila) | Game Pass "VIP" com conveniências leves: +slots, crafting um pouco mais rápido, tag no chat. Evitar armas ou armaduras pagas | N1 |
| Skins de caixa de morte, livro, mochila | Cosméticos de efeito: rastro, efeito de morte, visual da fogueira e das paredes | N2 |
| Servidores regionais | Servidor privado pago (recurso nativo da Roblox) | N1 |
| — | Premium Payouts: a Roblox paga pelo tempo de jogo de assinantes Premium, sem precisar implementar nada | N0 |
| Eventos sazonais (Natal, Halloween) | Cosméticos limitados por evento | N5 |

Regra de ouro para não matar o PvP: tudo que se vende com Robux é visual ou conveniência, nunca dano, defesa ou recursos.

### Roadmap por níveis

O lançamento precisa só da floresta; cada update seguinte abre um bioma com seu tier de material, seus mobs e um boss, na mesma ordem em que o Starve.io cresceu (inverno em abr/2017, oceano em jul/2017, deserto e lava depois). Os prazos são estimativa para um dev solo usando o Claude Code e contam a partir do update anterior.

roadmap · 6 níveis, do MVP aos extras

Cada nível só depende do anterior: o inverno pede picareta de ouro, o oceano pede diamante, ametista e linha azul do inverno, e a lava pede picareta de ametista e as quests do inverno.

#### Checklist do MVP (N0)

- ☐ Mapa da floresta com lago, árvores, rochas, jazidas de ouro e arbustos de frutinha

- ☐ Ciclo dia/noite de 8 min e barras de vida, fome, frio e sede calculadas no servidor

- ☐ Inventário de 10 slots, mochila (+6) e crafting com tempo

- ☐ Bancada, fogueira e fogueira grande

- ☐ Picaretas, espadas e lanças de madeira, pedra e ouro; capacetes de madeira e pedra; armas deixam o jogador mais lento e travam ao equipar

- ☐ Protetor de orelha, garrafa d'água (receita sem areia), carne assada

- ☐ Paredes, portas, espinhos e portas-espinho de madeira e pedra, com limite de peças por jogador

- ☐ Coelho, lobo e aranha com IA simples (fugir, perseguir, prender)

- ☐ PvP, morte com drop de itens, pontuação, leaderboard e chat com filtro

- ☐ Moeda soft ao morrer, loja com 10–15 cosméticos e pacotes de moeda

- ☐ Controles de toque para celular e câmera top-down travada

- ☐ Nome, arte, ícones e sons próprios (nada copiado do Starve.io)

### Fontes e lacunas

O site oficial (starve.io e o changelog) bloqueia leitura automatizada, então tudo aqui vem de wikis da comunidade. As wikis são de 2017 a 2019 em boa parte e podem estar desatualizadas.

#### O que não foi possível confirmar

- Updates de 2020 em diante: o changelog oficial e a página de Updates da wiki não abriram.

- Números exatos das barras (máximo, velocidade de queda, dano quando vazia) e a fórmula de pontos por recurso, além de diamante (4) e esmeralda (20).

- Vida e dano da maioria dos mobs comuns; só kraken, dragão de lava, filhote de dragão de lava e filhote de mamute têm números.

- Receitas dos arcos, do capacete de reidite, da proteção de diamante, do facão, do forcado, da torre e do extrator.

- Preço em dinheiro do Pão Dourado e se a versão web tem anúncios.

- Valores conflitantes entre fontes (ouro das coroas, chances de domar, prazos de algumas quests) foram marcados com faixa.

Para fechar essas lacunas, o caminho mais rápido é jogar algumas partidas e anotar os números, ou abrir o changelog no seu navegador e colar o texto aqui.

#### Páginas consultadas

- Fandom, visão geral: Game, Directory, Items, Drops, Miscellaneous Items, Cosmetics, Golden Bread

- Fandom, biomas: Forest, Winter, Ocean, Beach, Island, Desert, Lava Biome, River, Lake

- Fandom, mobs: Mobs, Rabbit, Wolf, Spider, Boar, Hawk, Arctic Fox, Polar Bear, Baby Mammoth, Mammoth, Dragon, Baby Dragon, Crab, King Crab, GMO Piranha, Kraken, Lava Monster, Lava Dragon, Baby Lava Dragon, Vulture, Sandworm, Zombie, Vampire, Treasure Chest, Saddle

- Fandom, equipamentos: Swords, Spears, Pickaxe, Hammers, Shields, Arrows, Pirate Sword, Crown of the Angel, Crown of Luck, Explorer's Hat, Hood, Winter Hood, Peasant's Tunic, Winter Peasant's Tunic, Diving Suit, Turban, Ninja Outfit, Pilot Glasses, Fur Hat, Coat, Bag, Book, Crab Helmet, Dragon Helmet, Lava Helmet, Amethyst Protection, Reidite Protection, Witch Hat, Santa Hat, Elf Hat, Wrench, Watering Can, Bucket, Bandage, Paper

- Fandom, estruturas e comida: Workbench, Furnace, Doors, Door Spikes, Totem, Roof, Bed, Sign, Resurrection Stone, Emerald Machine, Plant Plot, Boat, Sled, Plane, Gift, Candy Cane, Reidite, Emerald, Amethyst, Diamond, Ground, Cactus, Aloe Vera, Flour, Bread, Cookies, Sandwich, Garlic, Watermelon

- Outras: NamuWiki — combinações, TV Tropes, AppGoblin (app Android)