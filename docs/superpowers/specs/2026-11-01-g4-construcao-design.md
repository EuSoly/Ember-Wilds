# G4 — Construção (design)

Data: 2026-11-01. Conversado com o Elizeu em chat (respostas às 7 perguntas da construção, "perfeito, pode fazer o plano"). Números de vida: wiki de fãs do Starve.io (starveiopro.fandom.com) e changelog oficial (starve.io/changelog.html), pesquisados em 01/11; podem estar desatualizados, por isso ficam em dados.

## Intenção

A G3 crafta bancada, fogueiras, paredes, portas, espinhos e baú, mas eles só ficam no inventário. A G4 coloca essas peças no chão **do jeito do Starve.io**: o jogador monta uma base em volta de si, se protege com paredes e espinhos, abre a própria porta, guarda coisas no baú e acende a fogueira onde quiser. Quem é de fora pode quebrar a base batendo nela. É o que dá sentido ao crafting e prepara mobs e combate.

## Objetivos

- **Colocar peças** (categoria `placeable`) — **revisto pelo Elizeu em 01/11, depois de ver a primeira versão, que usava grade**: **não há grade**. Com a peça na mão, aparece um fantasma a uma **distância fixa** do boneco, na direção da mira (mouse no PC, joystick direito no celular), como no Starve: conforme se mira, o fantasma corre num círculo em volta do jogador. Verde se pode, vermelho se não pode. **PC: o clique constrói. Celular: soltar o joystick direito constrói** (posição inválida não gasta nada). Para parar, troca de slot. **Vale para todas as peças** (paredes, portas, espinhos, bancada, fogueiras, baú).
- **Rotação**: a peça nasce **de frente para o jogador**. **R** no PC (ou um botão que aparece no celular enquanto há peça na mão) soma **45°** a cada aperto; o giro **vale até trocar de item**.
- **Vida das peças** e **bater nelas**: qualquer jogador pode bater numa peça e tirar vida; com vida 0 ela some.
- **Porta**: o dono (e o time, quando existir) bate e ela abre ou fecha; aberta, deixa passar. Não fecha com alguém dentro. Os outros, batendo, só tiram vida.
- **Espinho**: fere quem encosta, menos o dono e o time.
- **Fogueira colocada**: aquece, queima quem pisa no centro, serve de estação "fire" do crafting e **apaga e some sozinha** depois do tempo dela.
- **Bancada colocada**: estação "workbench" do crafting.
- **Baú** funcionando (ver "Baú").
- **Dono**: cada peça tem dono. Quando o dono morre ou sai do jogo (sair = morte), **as peças dele somem**. Já preparado para um revive futuro manter as peças.
- **Limite de peças por jogador**: existe no código e nos dados, mas **sem limite** por enquanto.
- **Modelos provisórios**: blocos genéricos feitos de peças (como a bancada da G3), até os modelos do Elizeu chegarem. Trocar o modelo = trocar só o arquivo do modelo.

## Não-objetivos

- Martelo, chave inglesa, cadeado/chave, totem e times de verdade (N1). Aqui só os ganchos.
- Dano entre jogadores (combate) e mobs; o espinho já fere jogadores porque o Elizeu pediu.
- Quem bate num espinho também perder vida (changelog do Starve); fica para o combate.
- Porta-espinho, ponte, peças acima de ouro.
- Subir o tier de uma parede já colocada, consertar, girar peças.
- Revive em si (só o sistema preparado).
- Salvar a base entre sessões (nada persiste; sair = morte).
- Área sem construção em volta do nascimento: **não terá** (decisão do Elizeu). No futuro os jogadores vão nascer em pontos aleatórios da floresta, o que resolve alguém cercar o spawn; isso é de outra fase.

## Anti-objetivos

- Item duplicado ou sumido no baú (dois jogadores mexendo ao mesmo tempo, ou pedido forjado).
- Peça colocada longe do jogador, dentro de outro jogador, de recurso, de outra peça ou na água.
- Peça de jogador morto ficando no mapa.
- Sistema que conhece peça pelo nome (`if id == "wood_wall"`): tudo vem dos dados.

## Números

### Vida das peças

| Peça | Vida | Fonte |
|---|---|---|
| Parede de madeira / pedra / ouro | 1000 / 1500 / 2000 | wiki |
| Porta de madeira / pedra / ouro | 1000 / 1500 / 2000 | wiki |
| Espinho de madeira / pedra / ouro | 150 / 300 / 600 | wiki (o nosso catálogo dizia 300/600/900; escolha minha: wiki) |
| Bancada | 300 | wiki |
| Baú | 500 | wiki |
| Fogueira | 150 | wiki |
| Fogueira grande | 300 | escolha minha (a wiki não traz) |

### Espinho

Dano por toque: madeira 10, pedra 20, ouro 30 (wiki). Escolhas minhas (a wiki não traz o intervalo; o changelog só diz que há um "timer"):
- **Cada espinho fere no máximo uma vez por segundo cada vítima**, por conta própria: três espinhos em volta ferem três vezes mais (base bem montada é mais forte). O servidor guarda o último dano por par espinho/vítima.
- O dano é do tipo **combate** (`CharacterService.hurt(..., "combat")`): o capacete protege.
- A morte por espinho tem causa própria, **"Espinho"** (chave de texto nova na tela de morte).
- Conferido por varredura do servidor das peças perto de cada jogador (índice espacial), não por `Touched` (pesquisa 04). "Encostar" = o corpo do jogador toca o círculo da peça (ver "Forma das peças").

### Fogueira

Some depois de **2 min** (fogueira) e **6 min** (fogueira grande) (catálogo/wiki). Calor e queimadura iguais aos da fogueira de teste da G1 (`HeatRadius`/`BurnRadius`); a grande com raio de calor maior (escolha minha: o builder define, ex. 1,5×).

### Dano em construção (escolha minha, provisório)

No Starve só martelo derruba pedra e ouro, mas martelo é da N1. Aqui **qualquer golpe tira vida**, com um número por item nos dados (`structureDamage` no `ItemDef`), um golpe a cada 0,5 s (o mesmo compasso da coleta):

| Na mão | Dano por golpe |
|---|---|
| Nada / item sem número | 5 |
| Ferramentas de madeira / pedra / ouro / diamante / ametista / reidite | 10 / 15 / 20 / 25 / 30 / 35 |
| Espadas e lanças | metade da ferramenta do mesmo tier |

Ex.: parede de madeira (1000) com picareta de ouro = 50 golpes ≈ 25 s. Quando o martelo chegar, é só um item com `structureDamage` alto.

## Baú

Do jeito do Starve.io (catálogo e wiki concordam):

- Guarda **um tipo de item só**, numa quantidade com teto nos dados (escolha minha: 9999; o Starve não tem teto). Vazio aceita qualquer item.
- **Abrir**: estando perto de um baú (até 8 studs do centro do baú, escolha minha), o painel do baú aparece sozinho em cima da hotbar mostrando o item guardado e a quantidade, e cada slot do inventário ganha um **"+"**. (Como no Starve: não precisa clicar no baú, porque o clique bate.)
- **Pôr**: clicar/tocar no "+" de um slot põe 1; Shift+clique põe 10 (no celular, segurar o "+" põe 10; escolha minha).
- **Tirar**: clicar/tocar no item do baú tira o quanto couber no inventário.
- **Quem pode**: qualquer jogador (baú sem cadeado, como no Starve; cadeado é da N1). Vários podem estar perto ao mesmo tempo; todos veem a quantidade atualizada.
- **Destruído, ou dono morto/saiu**: o conteúdo **some** junto (como no Starve).
- **Segurança**: o servidor é dono do conteúdo. O cliente só pede "pôr N do slot X" / "tirar do baú Y"; o servidor confere distância, posse, quantidade e tipo e faz a troca **sem pausa no meio** (sem `yield`), o que já serializa dois jogadores no mesmo baú. Pedidos com limite de taxa.

## Como funciona (decisões)

- **Dados**: cada item `placeable` ganha um bloco `structure` nos Defs (vida, tipo: `wall`/`door`/`spike`/`station`/`chest`/`fire`, dano do espinho, duração do fogo, estação que oferece). `Validate` confere como o resto. Itens ganham `structureDamage` opcional.
- **Posição livre (revisto 01/11)**: o ponto da peça = centro do boneco + direção da mira × **distância fixa** (escolha minha: 5,5 studs, a de antes, meia peça + raio do corpo + meia peça — a peça nunca nasce dentro de quem constrói). A rotação = virada para o jogador + 45° × número de apertos de R.
- **Forma das peças (escolha minha)**: para todas as checagens (sobreposição, espinho, porta com alguém dentro, golpe), cada peça é um **círculo** no chão (raio nos dados, padrão ≈ meia largura do bloco, 2 studs). Duas peças podem ficar **coladas, não sobrepostas**; a peça não pode cobrir recurso, jogador ou água. O modelo pode ser quadrado e girado; só a colisão física do bloco segue o modelo.
- **No servidor**: as peças ficam num índice espacial (como os recursos) para buscar por perto; o servidor revalida tudo ao construir (distância e ângulo vindos da posição/mira do personagem no servidor, sobreposição, recurso, jogador, água, limite) e cria a peça já girada. O fantasma é só do cliente. (Pesquisa 04.)
- **Rotação na rede**: o cliente informa o giro escolhido (número de passos de 45°, 0–7); o servidor só aceita esse número e calcula o resto.
- **Peças**: modelos ancorados, `CanTouch = false`, com atributos de dono, vida e vida máxima; tag de construção. Criadas e destruídas só pelo servidor.
- **Golpe**: o mesmo golpe da coleta acerta o que estiver mais perto à frente, recurso ou peça. Com uma peça `placeable` na mão, o clique constrói em vez de bater.
- **Dono e vida do jogador**: cada peça guarda o dono e a **vida** (id da vida atual do jogador). A morte (e a saída) remove as peças daquela vida. Um revive futuro mantém a mesma vida, e as peças ficam.
- **Time**: uma função única "são aliados?" que hoje responde só "é o mesmo jogador". Porta, espinho e (no futuro) cadeado usam ela.
- **Limite**: número nos dados/config; vazio = sem limite.
- **Estações**: bancada e fogueiras colocadas ganham a tag `CraftStation` + `Station`, como na G3. Os comandos de teste `DevWorkbench` e `DevCampfire` saem.
- **Feedback**: ao levar dano, a peça mostra uma barrinha de vida por alguns segundos (escolha minha).

## Restrições

- Server Authority: o servidor decide tudo; o cliente pede e mostra.
- Conteúdo é dado; atributos e tags por `StatNames`.
- Rede por Blink, com o servidor validando cada pedido.
- O jogo vai crescer (mais tiers, martelo, times, cadeado, revive): cada um desses deve entrar mudando dados ou uma função de gancho, não refazendo o sistema.

## O que fica para quem implementa

Visual dos blocos provisórios, do fantasma, da barrinha de vida e do painel do baú; como o fantasma mostra "pode/não pode"; raio exato de calor da fogueira grande; como a porta aberta aparece; a organização dos serviços e eventos.
