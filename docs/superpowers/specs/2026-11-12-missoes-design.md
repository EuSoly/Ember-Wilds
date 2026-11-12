# Missões: partida, diárias, semanais e conquistas (design)

Branch `missoes`, 12/11/2026. Números brutos das chrono quests do Starve: `docs/game-design/quests-starve.md`.

## Por quê

A partida recomeça do zero a cada morte. O Elizeu quer objetivos que puxem o jogador de volta: na vida atual (chrono quests do Starve), todo dia, toda semana e para sempre (conquistas). As conquistas devem pedir jogo de verdade e dar prêmios bons, inclusive coisas que só se ganham ali (kits e skins exclusivos).

## O que é

Uma tela **Missões** com quatro abas: **Partida**, **Diárias**, **Semanais** e **Conquistas**.

| Tipo | Dura | Prêmio | Vai para |
|---|---|---|---|
| Partida (chrono quests) | a vida atual, com prazo em dias de jogo | item especial + pontos | inventário e pontos da vida |
| Diárias | até a meia-noite de Brasília | Golden Ember; a final dá 1 uso de kit | perfil |
| Semanais | até domingo 23:59 de Brasília (mesmo corte do ranking) | Golden Ember; a final dá mais (giro) | perfil |
| Conquistas | para sempre | Golden Ember, giros especiais, skins e kits exclusivos | perfil |

## A tela (layout A, escolhido no rascunho)

- Janela rústica (`UI/Rustic`, paleta `Palette.rustic`) com o título MISSÕES, um X e **quatro abas em cima**. Embaixo, uma área de papel com a lista de cartões.
- **Cartão:** ícone, nome, barra de progresso (laranja; verde quando completa), linha de detalhe (`120 / 200`, `faltam 1d 6h`, regra como "sozinho"), prêmio à direita. Completa = botão **RESGATAR** no lugar do prêmio.
- **Bolinha vermelha** na aba com o número de prêmios esperando resgate. A mesma bolinha aparece no botão que abre a tela.
- Cada aba tem uma linha de topo: Partida = "Valem só nesta vida · Dia N"; Diárias/Semanais = "Renova em 7h" / "Renova domingo"; Conquistas = "12 / 27".
- **Abre por dois lugares** (decisão do Elizeu): um botão no HUD durante a partida e um botão no menu. É a mesma tela. No menu a aba Partida mostra "Entre no jogo para começar" (minha escolha).
- **Aviso no jogo:** quando uma missão completa ou uma chrono quest falha, uma faixa desce do topo (já prevista em `identidade-visual.md`: faixa com confete na cor do tier, 400 ms). Falha = faixa sem confete, tom escuro.
- Precisa caber no celular (emulador 749×330).

## Partida (chrono quests)

- Lançamento com **só duas**, as que a floresta permite (decisão do Elizeu): **Sobreviver** e **Mãos Limpas** (a "Paz" do Starve; o Elizeu pediu um nome que lembre "sem dano", o nome é proposta minha). As outras 11 do Starve entram quando o bioma/mob delas existir (ficam escritas em `Defs/Quests` desligadas, como os itens `testOnly`).
- **Sobreviver:** 4 dias de jogo sem perder vida, sozinho. Prêmio Gema Verde (`green_gem`) + 7500 pontos.
- **Mãos Limpas:** 6 dias sem acertar jogador, mob passivo (coelho) nem mob neutro (javali, falcão) e sem colocar espinho. **Até para se defender** quebra a quest (decisão do Elizeu). Bater em mob agressivo (lobo, aranha) pode, como no Starve (minha leitura). Prêmio Gema Azul (`blue_gem`) + 3000 pontos.
- Regras como no Starve: começam sozinhas ao nascer; prazo em dias de jogo (1 dia = 8 min, `DayCycle`); quebrou a regra = falhou nesta vida; completou = fica esperando o RESGATAR, e só aí entram o item e os pontos. Morreu = tudo da Partida some.
- "Sozinho" = não estar em time do totem (`TeamService`). "Perder vida" = qualquer queda da barra de vida, de qualquer causa.
- Os itens de prêmio continuam `testOnly` só até ganharem modelo; quem os recebe por quest pode tê-los normalmente (a marca `testOnly` some deles quando o modelo chegar).

## Diárias

- Cada jogador **sorteia 3 missões por dia** de um banco (decisão do Elizeu), mais uma **final** que libera quando as 3 estão resgatadas e dá **1 uso de kit** (saldo de 1 vida, o mesmo `kitOnce` da loja).
- Renovam à **meia-noite de Brasília**. Missão não resgatada some na virada (minha escolha: simples, e o aviso da bolinha deixa claro).
- Progresso conta em qualquer vida do dia; não depende de uma vida só, a não ser que a missão diga ("sobreviva 2 dias numa vida").
- Banco inicial (minha proposta; números a ajustar): coletar N madeira/pedra/ouro/frutas, matar N de um mob da floresta, craftar um item, comer N vezes, sobreviver N dias numa vida, fazer N pontos numa vida, colocar N construções.
- Prêmio de cada diária: Golden Ember (faixa sugerida 30–80 por missão). Final: 1 uso de um kit sorteado entre Explorador e Sobrevivente (minha escolha).

## Semanais

O Elizeu não detalhou; segue o mesmo molde das diárias com metas maiores (minha proposta, ele confere):

- 3 semanais sorteadas por jogador + 1 final. Renovam domingo 23:59 de Brasília (mesmo corte do ranking, `RankRules`).
- Prêmio: Golden Ember (faixa 150–300). Final: 1 giro especial + 1 uso do kit Veterano.

## Conquistas

Permanentes, em três níveis. Contam pelas estatísticas que já guardamos (`Defs/Stats`), então quem já joga começa com o progresso que tem. Ficaram de fora o que dá para fazer AFK ou de propósito (tempo de jogo, mortes). Números são proposta minha aprovada pelo Elizeu ("está perfeito").

| Conquista | Conta | I | II | III | Prêmio do III |
|---|---|---|---|---|---|
| Lenhador | madeira coletada (`resources_gathered.wood`) | 1.000 | 10.000 | 50.000 | skin exclusiva |
| Minerador | ouro coletado (`resources_gathered.gold`) | 300 | 3.000 | 15.000 | skin exclusiva |
| Caçador | mobs mortos (`mobs_killed`, soma) | 100 | 1.000 | 5.000 | kit Caçador (permanente, só de conquista) |
| Sobrevivente | dias numa vida só (`days_best`) | 5 | 15 | 30 | kit Guardião da Floresta (permanente, só de conquista) |
| Artesão | itens craftados (`items_crafted`, soma) | 100 | 1.000 | 5.000 | skin de livro exclusiva |
| Lenda | pontos numa vida só (`score_best`) | 50 mil | 200 mil | 1 milhão | skin Mítica exclusiva |
| Guerreiro | jogadores mortos (`players_killed`) | 10 | 100 | 500 | skin de caixa exclusiva |
| Fiel | dias com todas as diárias feitas (estatística nova) | 7 | 30 | 100 | skin de mochila exclusiva |
| Cronista | chrono quests completadas (estatística nova) | 1 | 10 | 50 | giros especiais + skin |

- Nível I dá Golden Ember; nível II dá um giro especial; o valor sobe de uma conquista para outra.
- **Guerreiro sem trava:** jogadores podem farmar entre si (decisão do Elizeu).
- **Skins exclusivas:** o Elizeu escolhe entre as que já temos ou ajusta alguma. Precisam ficar fora das roletas (`inSpins = false`) e dos pacotes.
- **Kits só de conquista:** kits NOVOS (Caçador e Guardião da Floresta), de um tipo novo em `Defs/Kits` que não aparece na loja, não se compra com pontos nem Robux e entra na escolha do nascimento (`KitChoice`) como kit para sempre. Não confundir com o `kit_veteran` da loja (esse é o da final semanal). Conteúdo dos dois kits: proposta minha no plano, o Elizeu confere.
- **Skin exclusiva que o jogador já tem:** recebe Golden Ember no lugar, como a skin repetida da roleta especial (`DUPLICATE_REFUND` do giro especial). Como os perfis serão zerados antes de ligar a cobrança, quase ninguém vai ter (minha escolha).
- **Antes de o Elizeu escolher as skins:** as conquistas já funcionam; o prêmio do nível III sem skin definida aparece como "em breve" e é entregue quando a skin for definida (minha escolha). Tirar a skin das roletas e pacotes vale a partir da escolha.
- Prêmio também por RESGATAR (não entra sozinho), para o jogador ver o que ganhou.

## Regras gerais

- **Golden Ember das missões fica fora do limite de 300 por hora** (decisão do Elizeu). Entrega pelo caminho de presentes da loja (`ShopService.give`, que já entrega `ember`, `spins`, `cosmetic`, `kit`, `kitOnce`).
- Tudo é decidido no servidor; o cliente só pede para resgatar. Estado vai só para o dono.
- **Modo criativo:** missões desligadas (sem progresso nem prêmio), como já acontece com pontos, ranking e estatísticas (minha escolha).
- Diárias, semanais e conquistas salvam no perfil (ProfileStore); a Partida não salva (vida = sessão; sair = morte).
- Conteúdo é dado: quests, banco das diárias/semanais e conquistas ficam em `Defs`, nunca em código que conhece missão pelo nome.

## Assets

Do Elizeu:

1. **Modelos/ícones dos 2 prêmios de lançamento:** Gema Verde e Gema Azul. Os outros 9 itens de quest (gema laranja, cubos azul e de lava, orbes azul e de lava, peça do forcado, óculos de piloto, peles de lobo preto e branco) quando os biomas chegarem.
2. **Skins exclusivas das conquistas:** 2 de corpo (Lenhador, Minerador), 1 Mítica (Lenda), 1 de livro (Artesão), 1 de caixa (Guerreiro), 1 de mochila (Fiel), 1 do Cronista. Escolhidas entre as existentes ou ajustadas.
3. **Arte da UI** (se quiser algo além do que dá com o Rustic em código): ícone do botão de Missões (relógio/ampulheta), ícones das abas, medalhas dos níveis I/II/III.

Meus (no código ou por IA, com aprovação): ícones dos cartões a partir dos ícones de item que já temos (`ItemIcon`), faixa de aviso, bolinha.

Sons (`sons.md`): missão completa, chrono quest falhou, resgatar. Proposta: escolher do pacote que já usamos.

## Fora desta fase

- As 11 chrono quests que dependem de inverno, deserto, lava, dragões, baús de tesouro, fazenda e minérios novos.
- Trocar uma diária (reroll), corrida com N vencedores, `quests_per_life`.
- Passe de batalha.

## Decisões do Elizeu (12/11)

- Quatro tipos: partida, diárias, semanais e conquistas.
- Layout A (abas em cima).
- Tela abre no HUD e no menu.
- Diárias dão Golden Ember; uma final, que depende de completar as outras, dá uso de kit.
- Conquistas liberam skins, kits permanentes, giros especiais etc.; precisam pedir jogo de verdade.
- O que vem das missões não entra no limite de Golden Ember por hora.
- 3 diárias sorteadas por jogador + final, meia-noite de Brasília.
- Partida começa com Sobreviver e Paz (agora Mãos Limpas) e cresce com os biomas.
- Na Mãos Limpas, acertar mob neutro quebra a quest mesmo para se defender; a quest ganha nome que lembre "sem dano".
- Lista de conquistas aprovada; Guerreiro pode ser farmado entre jogadores.
- Skins exclusivas: ele escolhe entre as existentes e às vezes ajusta.

## Escolhas minhas (para o Elizeu conferir)

- Semanais no mesmo molde das diárias (3 + final, giro especial + Veterano na final).
- Missão diária/semanal não resgatada some na virada.
- Final da diária = 1 uso de Explorador ou Sobrevivente, sorteado.
- Nome do kit do Sobrevivente III virou "Guardião da Floresta" para não confundir com o `kit_veteran` da loja.
- Skin exclusiva repetida vira Golden Ember; nível III sem skin escolhida fica "em breve" e entrega depois.
- Banco inicial das diárias e faixas de Golden Ember.
- Aba Partida no menu mostra "Entre no jogo para começar".
- Missões desligadas no modo criativo.
- Faixa de falha sem confete.
- Nome "Mãos Limpas" e mob agressivo liberado na quest.
