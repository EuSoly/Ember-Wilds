# Construção

As peças de base (bancada, fogueiras, paredes, portas, espinhos e baú; mais as estruturas novas da G8, só para teste, abaixo) são colocadas no chão, do jeito do Starve.io. Cada peça tem dono, vida e comportamento próprios, tudo vindo de dados. O servidor decide tudo: o cliente só mostra um fantasma e pede para construir.

## Como colocar

1. Crafte a peça (veja `crafting.md`) e selecione o slot dela na hotbar.
2. Um **fantasma** aparece no chão, **a uma distância fixa do boneco, na direção da mira**. Ele é o **próprio modelo da peça**, translúcido e sem textura, com as peças **pintadas de verde** se pode construir e **de vermelho** se não pode (o `Highlight` não aparecia por cima dos modelos), sem luz, efeitos nem som. Sem template no place, aparece o modelo provisório (o mesmo que o servidor coloca); o bloco com a faixa da frente só volta se o modelo falhar. É só uma aproximação do cliente; quem decide é o servidor.
3. **PC:** solte o clique (botão de usar). **Celular:** solte o joystick direito. Posição inválida não gasta nada.
4. Para parar de construir, troque de slot. Com uma peça na mão, o golpe não bate (só constrói).

O servidor recusa e não gasta nada se: a peça não está na mão, a peça cairia sobre outra peça, sobre um recurso, sobre um jogador, ou o centro da peça cairia na água, ou o limite foi atingido.

## Posição livre e rotação

As peças são livres, sem grade, com uma exceção: as de chão e teto (veja "Encaixe em grade" abaixo). A peça nasce no ponto `BuildRules.placePoint`: a partir do centro do boneco, `PLACE_DISTANCE` studs na direção da mira. A distância é fixa, então a peça sempre aparece num círculo em volta do jogador, em qualquer direção.

- **De frente para o jogador:** sem girar, a frente da peça olha para quem constrói (`BuildRules.facingYaw`).
- **Girar:** a tecla **R** (PC) ou o botão **"Girar"** (celular, só aparece com uma peça na mão) gira o fantasma 45° por vez (`ROTATE_STEP`), em 8 passos (`ROTATE_STEPS`). O giro vale **até trocar de item** (ou renascer), quando volta a 0 (o servidor zera o dele, e o cliente também manda `SetBuildRotation(0)` ao zerar com uma peça na mão, porque a troca chega ao cliente um pouco depois; assim a última mensagem sempre bate com o fantasma). A tecla R é ignorada enquanto você digita no chat.
- **Na rede:** o cliente manda só o número do passo (`SetBuildRotation`, 0 a 7). O servidor ignora valor fora disso, fracionário ou mandado sem uma peça na mão (`BuildRules.validSteps`), e guarda o giro por jogador.
- **O fantasma e a peça são iguais:** o cliente usa o mesmo ponto, o mesmo giro e os mesmos raios (constantes em `BuildRules`), por isso a peça construída cai onde o fantasma estava.

## Encaixe em grade (chão e teto)

Peças com `snap = true` no bloco `structure` do item se encaixam umas nas outras. Hoje são o telhado, o piso e o canteiro (fazenda, 12/11: na camada do piso, mas fora da água; veja `fazenda.md`). Paredes, espinhos, portas e o resto continuam livres (decisão do Elizeu, 11/11).

- Perto de uma peça da **mesma camada** que também tem `snap`, a nova vai para a **casa mais próxima da grade dessa vizinha**. O lado da casa é o diâmetro dela (`2 × radius`), os eixos são os dela, e a nova **copia o giro da vizinha**: forma um piso contínuo, sem fresta.
- O ponto livre em cima da própria vizinha vai para a casa ao lado, na direção da mira.
- A vizinha puxa a peça quando o centro dela está a até `2 × raio + BuildRules.SNAP_RANGE` (3 studs de folga) do ponto livre; aí a peça sempre vai para a casa mais próxima, inclusive nos cantos. Sem vizinha ao alcance, a peça fica livre.
- Encaixada, a peça usa o giro da vizinha: a tecla R (e o botão Girar) não muda nada até ela sair da grade.
- A conta é `BuildRules.snapPlacement`, a mesma no servidor (`StructureService.place`, com `StructureService.snapNeighbors`) e no fantasma (`BuildGhost`). Testes em `tests/build.spec.luau` (`encaixe_*`).

## Peças são círculos

Cada peça ocupa um círculo no chão (centro x, z e raio). Duas peças **encostadas** (círculos que só se tocam) são aceitas; **sobrepostas**, recusadas (`BuildRules.circlesOverlap`), inclusive com peças giradas. O mesmo círculo vale para recurso (atributo `ResourceRadius`), jogador (`PLAYER_RADIUS`), golpe, espinho e porta. As peças ficam num índice espacial (`SpatialGrid`) no servidor; ele é só um índice interno de busca e não tem relação com onde as peças podem ser colocadas (isso continua livre, sem grade). Assim conferir vizinhos é barato; a peça removida (vida 0, fogo, dono, apagada por fora) sai dele.

| Número | Valor | Onde |
|---|---:|---|
| Raio padrão da peça | 2 studs (peça de 4) | `BuildRules.PIECE_RADIUS` |
| Raio do corpo do jogador | 1,5 studs | `BuildRules.PLAYER_RADIUS` |
| Distância até o centro da peça | 5,5 studs | `BuildRules.PLACE_DISTANCE` |
| Passo do giro | 45° (8 passos) | `BuildRules.ROTATE_STEP` / `ROTATE_STEPS` |
| Golpe de mão em peça | 5 de dano | `BuildRules.HAND_DAMAGE` |
| Intervalo do espinho | 1 s por espinho/vítima | `BuildRules.SPIKE_INTERVAL` |
| Limite de peças por jogador | sem limite (`nil`) | `BuildRules.MAX_PER_PLAYER` |

A distância é meia peça + o raio do corpo (1,5) + meia peça: a peça nasce sempre à frente do corpo, e o próprio construtor nunca a bloqueia. As regras puras estão em `src/shared/Build/BuildRules.luau` (testadas no Lune).

**Peça maior:** coloque `radius` no bloco `structure` do item (opcional; sem ele vale `PIECE_RADIUS`, via `BuildRules.radiusOf`). Desde a G8 cada peça com modelo do Elizeu tem o `radius` do tamanho do modelo (metade da maior medida vista de cima, ajustado na bancada): paredes, portas, espinhos e portas com espinhos 2,5 desde 11/11 (o modelo tem 6: dá para colocar um pouco mais perto, pedido do Elizeu), bancada e fornalha 3, fogueira 2,7, fogueira grande 3,1, baú 2,3, extratores 3,75 desde 11/11 (todos os modelos em 7,5 studs, um pouco maiores que a parede; antes pedra e ouro tinham 5,4 e os outros 3,2), poço 2,6, cama 3,5, ponte 3,1, telhado 3,2; a placa usa o padrão (2). Mudou o tamanho de um modelo na bancada? Ajuste o `radius` do item junto. O campo `size` e a grade não existem mais. Atenção: a distância de colocação é fixa; o raio máximo aceito é `PLACE_DISTANCE - PLAYER_RADIUS` (4 studs); acima disso a peça sempre cobriria o corpo e o boot recusa o item.

## Vida e dano em construção

Cada peça tem vida (atributos de vida e vida máxima). Qualquer jogador pode bater nela com o golpe de coleta (um a cada 0,5 s): o golpe acerta o que estiver mais perto à frente, recurso ou peça. Com vida 0, a peça some e o espaço é liberado. Ao levar dano, a peça mostra uma barrinha de vida por 3 s (`StructureHealth`).

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

O dono (e, no futuro, o time) bate na porta e ela abre ou fecha; aberta, deixa passar. Ela **não fecha com alguém dentro** (alguém tocando o círculo da porta). Quem não é aliado, batendo, só tira vida: nunca abre.

## Espinho

Fere quem encosta, menos o dono e os aliados (com os times, os colegas: `times.md`). **Bater** num espinho alheio também machuca quem bate (`spikeHitDamage`, Starve "hit"; `BuildRules.spikeHitDamage`, aplicado no `StructureService.hit`). O `SpikeService` varre a 5 Hz as peças vizinhas (não usa `Touched`): quem chega no círculo do espinho, com margem de 1,8 studs (`PLAYER_RADIUS` + 0,3), é ferido. Cada espinho fere cada vítima no máximo 1× por segundo, então três espinhos em volta ferem três vezes mais. O dano é golpe de jogador (o capacete protege) e a morte tem causa "Espinho".

Números da config oficial do Starve (11/11), de madeira a reidite:

| Peça | Vida | Encostar | Bater |
|---|---|---|---|
| Espinho | 150 / 300 / 600 / 1200 / 2400 / 3000 | 10 / 20 / 30 / 40 / 50 / 60 | 2 / 3 / 3 / 4 / 4 / 5 |
| Porta com espinhos | 100 / 200 / 400 / 800 / 1600 / 2000 | 5 / 10 / 15 / 25 / 30 / 35 | 1 / 2 / 2 / 3 / 3 / 4 |
| Parede e porta | 1000 / 1500 / 2000 / 2500 / 3500 / 4000 | — | — |

## Extratores, fornalha e máquina de esmeralda

- **Extratores** (pedra, ouro, diamante, ametista, reidite): 2000 de vida; 1 minério a cada 10 s gastando 2 madeiras; até 255 de madeira e 255 de minério. Qualquer um põe madeira, só o dono e os aliados tiram.
- **Fornalha:** 1000 de vida, 1 madeira a cada 5 s, até 255.
- **Máquina de esmeralda:** 750 pontos por minuto ao dono vivo (`EmeraldService`, `EmeraldRules`). **Destruída por outra pessoa, o dono morre** (causa "Máquina de esmeralda destruída"); quebrada pelo próprio dono ou por um aliado, ou removida porque o dono morreu ou saiu, nada acontece.
- **Limite por jogador** (`structure.maxPerPlayer`): totem, pedra da ressurreição e máquina de esmeralda, **uma de cada**. Ao tentar colocar além do limite, aparece o aviso "Você já tem o máximo desta construção".
- **Descrições:** o livro mostra "Como funciona" (texto `desc.<id>` em `Strings/ptBR.luau`) nas construções, ferramentas especiais e peças de cabeça. Item novo que não é óbvio: escreva o `desc.<id>`.
- **Pedra da ressurreição:** veja `ressurreicao.md`. **Totem:** veja `times.md`.
- **Testar no Studio:** `ServerStorage.DevPlace:Invoke(player, "<itemId>")` coloca a peça à frente do jogador sem gastar item (só no Studio).

## Fogo

A fogueira colocada esquenta, queima quem pisa no centro e serve de estação `"fire"` do crafting. Ela **some sozinha**: fogueira em 2 min (`lifetime = 120`), fogueira grande em 6 min (`lifetime = 360`); o calor tem raio 12 na fogueira pequena e 18 na grande.

## Baú

- Guarda **3 tipos de item** (`ChestRules.SLOTS = 3`), cada um uma pilha até 9999 (`ChestRules.MAX`). Pôr um item soma no slot que já tem aquele tipo; se não houver, usa o primeiro slot vazio (`ChestRules.putAny`).
- Chegando perto (até 8 studs do centro, `ChestRules.RANGE`), o painel do baú aparece sobre a hotbar com 3 slots lado a lado, e cada slot do inventário ganha um **"+"**.
- Clicar no "+" põe 1; Shift+clique põe 10 (no celular, segurar o "+"). Clicar num slot do baú tira daquele slot (`ChestTake { Chest, Slot }`) o que couber no inventário.
- Qualquer jogador pode usar (baú sem cadeado). Vários ao mesmo tempo veem a quantidade atualizada.
- O conteúdo some junto com o baú (destruído, dono morto ou saído).
- O servidor (`ChestService`) é o dono do conteúdo. Os eventos `ChestPut` e `ChestTake` só pedem; ele confere distância, posse, tipo e quantidade (inteiro positivo), tem limite de taxa e troca tudo sem pausa no meio, o que serializa dois jogadores no mesmo baú.

## Modelos novos (G8)

Os modelos 3D do Elizeu (Blender) são só o **visual**; a colisão continua sendo o círculo da peça. O `StructureModel` monta cada peça assim:

- O bloco antigo (o colisor) continua, **invisível**.
- O modelo do Elizeu entra por cima, como filho `Visual`, com o pivô no centro da base (o mesmo ponto do círculo, no chão). Todas as partes do `Visual` ficam sem colisão, sem consulta e sem toque.
- Os modelos ficam no place como **templates**, com o mesmo id do item: `ReplicatedStorage.Assets.Structures/<itemId>`. Sem template, a peça usa o bloco antigo (continua funcionando). A fogueira grande do world-pack (`big_fire`) é o item `big_campfire`.
- Os depósitos de pedra e ouro do mapa vêm de `ServerStorage.Assets.Resources` (`rock_1` e `gold_vein_1`). Os modelos antigos de recurso, estrutura e ícone ficam guardados em `ServerStorage.ResourcesAntigos`, `EstruturasAntigas` e `IconesAntigos`: nada é apagado.

Peças que se mexem (cada uma é uma parte separada do modelo, com o nome do Blender):

| Peça | O que se mexe | Como |
|---|---|---|
| Porta e porta com espinhos | as duas folhas (`*_panel_left`/`*_panel_right`) | deslizam para os lados ao abrir (`DoorSlide`); o colisor da porta desliga aberta |
| Baú | a tampa (`chest_lid`) | abre enquanto você está perto (`StructureFx`, só no cliente) |
| Extratores | o rotor (`*_rotor`) | gira enquanto o atributo `Working` é verdadeiro |
| Fogueiras e fornalha | as chamas (`*_flames`) | somem quando o atributo `Lit` é falso |
| Telhado | a peça inteira | fica translúcido só para o jogador que está embaixo (`RoofFade`) |

Calor, estação de craft e tempo de vida das fogueiras são os mesmos de antes: o modelo novo só troca o visual. Para ajustar tamanho, posição ou giro de um modelo, use a bancada (veja abaixo). No chão, a parede tem ~3,9 studs de diâmetro e o círculo da peça tem 4.

## Porta com espinhos

`wood_spike_door`, `stone_spike_door` e `gold_spike_door` (kind `spike_door`). É uma porta (o dono bate e ela abre ou fecha, nunca fecha com alguém dentro) que também fere quem não é aliado, como o espinho do mesmo tier. O dono e os aliados nunca se ferem. O código reaproveita os dois comportamentos: `BuildRules.isDoor` diz se o kind é porta (inclui `spike_door`) e `BuildRules.hurts` diz se ele fere.

| Porta com espinhos | Vida | Encostar | Bater | Receita (bancada) |
|---|---:|---:|---:|---|
| Madeira | 100 | 5 | 1 | porta de madeira + 80 madeiras + 60 pedras |
| Pedra | 200 | 10 | 2 | porta de pedra + 140 pedras |
| Ouro | 400 | 15 | 2 | porta de ouro + 80 ouros + 60 pedras |

Números e receitas da config oficial do Starve (11/11); diamante, ametista e reidite na tabela da seção "Espinho". Madeira a ouro liberadas.

## Estruturas interativas

Chegue perto (até 8 studs do centro, `InteractRules.RANGE`) e o **painel de interação** aparece sobre a hotbar com um botão por ação (veja `hud.md`). O servidor confere tudo: distância, item, quantidade e taxa. O estado (madeira, estoque, água) vive só enquanto a peça existe, como o conteúdo do baú; ao destruir a peça, o painel some e nada fica preso. Números da config oficial do Starve (11/11). Liberados: extratores de pedra e ouro, fornalha, cama, placa, balde e poço (12/11). Fantasma não usa nada daqui (`ressurreicao.md`).

| Peça | Vida | Receita (bancada) | O que faz |
|---|---:|---|---|
| Extrator de pedra / ouro | 2000 | 50 madeiras + 100 pedras / 60 pedras + 120 ouros | Você põe madeira (não dá para tirar). Com madeira, gasta 2 madeiras a cada 10 s e produz 1 pedra / 1 ouro por ciclo, até 255 guardados. O dono (e os aliados do time) pega o estoque pelo painel. Guarda até 255 madeiras. Diamante, ametista e reidite: só de teste. |
| Fornalha | 1000 | 150 madeiras, 50 pedras, 15 ouros | "Baú de mão única": você põe madeira (até 255) e não tira. Queima 1 madeira a cada 5 s. Acesa, esquenta (raio 24) e é estação de fogo do craft; não queima quem encosta. Sem madeira, apaga: tira o calor e a estação. |
| Poço | 500 | 100 pedras + 30 terras, com fogo perto (config do Starve) | Com um balde cheio na mão, "Encher" põe água no poço: 1 balde = 12 goles (wiki), até 48. "Beber" gasta 1 gole e dá 20 de sede. A terra vem da pá (`coleta.md`). |
| Balde (`bucket`) | - | 20 madeiras + 1 linha (config do Starve) | Com o balde na mão, perto da água do mapa (até 3 studs), ele enche quando você aperta ou segura o botão de usar (vira `water_bucket`, no mesmo slot). Do balde não se bebe. Não empilha. Na mão aparece o modelo de `Assets.Tools.bucket` / `Assets.Tools.water_bucket` (item com `handModel = true`; `Tamanho` 1,5 e `Pegada` −0,9: de pé, na altura da mão e à frente dela). |
| Cama | 400 | 100 madeiras, 50 pedras, 5 peles de lobo, 5 de coelho, 6 linhas (wiki) | "Deitar" põe você em cima da cama: regeneração de vida x2; fome, frio e sede caem na metade (`SurvivalRules`). O bônus soma com o calor da fogueira. Andar ou levar dano levanta. Deitado, você pode ser atacado. Olhos fechados enquanto dorme. |
| Placa | 100 | 20 madeiras (wiki) | O dono escolhe no painel um símbolo de uma lista fixa (`SignRules.SYMBOLS`: setas, aviso, coração, caveira, estrela, casa, ! e ?). Sem texto livre, porque texto de jogador exige filtro da Roblox. Aparece nas duas faces. |

**Painel do poço** (12/11): um medidor de água (gota + barra com "12 / 48 goles") e botões com ícone: gota no Beber, balde cheio no Encher. Botão que não dá para usar agora fica apagado (`WellRules.canDrink` / `canFill`): Beber sem água no poço ou com a sede cheia; Encher sem balde cheio na mão ou com o poço cheio. O servidor confere de novo.

**Painel da fornalha e dos extratores** (`UI/MachineSlots`, 11/11; antes era um texto "Madeira: 0" e botões lisos): slots de couro como o do baú. Extrator: `[madeira] barrinha [minério]`. Clicar na madeira põe até 10, e clicar no minério pega o estoque; para quem não é do time, o slot do minério fica apagado com "Só o dono". Fornalha: `[madeira] barrinha`. A barrinha é estimada no cliente, só pelos atributos `Wood` e `Stock` (`MachineRules.cycleRestarted` e `cycleFraction`), sem tráfego a mais. No extrator ela enche a cada ciclo, na cor do minério, com "Trabalhando", "Sem madeira" ou "Cheio". Na fornalha mostra quanto falta para queimar a madeira da vez, com "Acesa" ou "Apagada".

**Luz da fornalha** (11/11): a peça `furnace_flames` do modelo ganha a luz de fogo (`FireLight`). Acesa, a luz liga e as chamas aparecem; apagada, as duas somem (`StructureModel.setLit`, chamado pelo `MachineService`).

Os números ficam nos blocos `extractor`, `furnace`, `well` e `bed` da peça, em `Defs/Items.luau`. O extrator produz mais devagar que bater numa rocha com picareta, para não deixar a mineração inútil. Qualquer jogador perto pode pôr madeira no extrator e na fornalha; pegar o estoque do extrator e trocar o símbolo da placa é só do dono (e aliados, via `BuildRules.areAllies`, quando os times chegarem). A regra está em `InteractRules`.

Código: as regras puras são `MachineRules`, `WellRules`, `SignRules` e `InteractRules` (com testes no Lune); os serviços são `MachineService` (extrator e fornalha), `WellService`, `BedService` e `SignService`, todos registrados no `InteractService.register`. A água do mapa vem de `WaterSim.isWaterAt` e a troca de balde de `InventoryService.swapAt`.

## Ponte e telhado

Os dois são exceções da regra "uma peça por círculo": cada um vive numa **camada** (`BuildRules`) e só bloqueia peças da mesma camada, e os dois **se encaixam em grade** (veja "Encaixe em grade"). Ponte: raio 3,1, vida 300. Telhado: raio 3,2, vida 1000. Liberados em 11/11.

- **Piso** (id `bridge`, 15 madeiras; era "ponte" até 11/11): vai **na terra ou na água**, e não sobre outro piso. Jogador em cima não impede colocar (`BuildRules.blockedByPlayers`). Quem está em cima é tratado como em terra: não perde oxigênio nem fica lento. A ponte vale como chão dentro do raio dela mais o raio do corpo do jogador (1,5), para que uma fileira de pontes encostadas forme um caminho sem buraco. Se a ponte some, quem estava em cima volta a estar na água. Colocar qualquer outra peça "na água" continua proibido. Os mobs usam a água crua: a ponte não os protege.
- **Telhado** (`roof`, 30 madeiras; debaixo de qualquer telhado, **todos os telhados na tela** ficam translúcidos para você: `BuildRules.roofsToFade`, `RoofFade`. "Debaixo" usa o círculo que passa pelos cantos do quadrado, raio × √2, para não ter buraco entre telhados encaixados, e quem já estava debaixo só sai 2 studs além, `ROOF_EXIT_MARGIN`; antes piscava andando por baixo): fica numa camada de cima, a `ROOF_HEIGHT = 3` studs do chão (altura provisória), e pode cobrir outras peças sem colidir com elas nem com o jogador. Protege quem está embaixo: mobs voadores (o falcão) não mordem quem está sob um telhado. Fica translúcido só para você quando está embaixo. Nevasca e tempestade de areia ficam para quando esses biomas existirem. O golpe de coleta acerta ponte e telhado por último (não atrapalham bater no que está embaixo).

Ponte e telhado são achados por tag (`Bridge` / `Roof`, com o atributo `PieceRadius`) no módulo `TaggedCircles`, para a simulação de água e os mobs não precisarem conhecer o `StructureService`.

## Só para teste (`testOnly`)

Item com `testOnly = true` em `Defs/Items.luau` só existe no Studio. Fora do Studio (`RunService:IsStudio()` falso, inclusive servidor privado) é como se não existisse: não aparece no craft nem nas listas, não é craftável, não é dado (nem pelo `InventoryService.give`) e não é colocável. O `Validate` proíbe item `testOnly` em kit e no loot de mob. O lugar único dessa regra é `src/shared/ItemAccess.luau`.

Itens marcados hoje (12/11): as peças de diamante, ametista e reidite (paredes, portas, espinhos, portas com espinho e extratores), pedra da ressurreição e máquina de esmeralda. Liberados em 12/11: balde, balde cheio, poço, as pás de pedra e de ouro, o canteiro e a semente de frutinha (as outras 8 sementes e os frutos delas seguem de teste: `fazenda.md`). Liberados em 11/11: portas com espinho de madeira a ouro, extratores de pedra e ouro, fornalha, ponte, telhado, placa, cama e totem.

**Para liberar um item num update:** apague a linha `testOnly = true` do item em `Defs/Items.luau` (e do `bucket` e do `water_bucket` se for liberar o poço, senão ele não tem uso). Antes, revise os números marcados `-- provisório` da peça e da receita (em `Defs/Items.luau` e `Defs/Recipes.luau`). Rode `bash scripts/check.sh`. Não existe dado salvo para limpar: o inventário e a base não persistem.

## Importar os modelos (`import-world.luau`)

`scripts/studio/import-world.luau` transforma `Workspace["mundo-completo"]` (o world-pack exportado do Blender) nos templates acima. Rode na barra de comandos do Studio em **Edit** e **salve o place** depois.

1. `*_deposit_icon` vira recurso em `ServerStorage.Assets.Resources` (pedra = `rock_1`, ouro = `gold_vein_1`; diamante, ametista, reidite e esmeralda entram com o nome original, para o futuro). `*_viewport` vira `Assets.Icons/<itemId>`. O resto vira `Assets.Structures/<itemId>`.
2. Cada template recebe o pivô no centro da base, peças ancoradas, sem colisão, e o nome sem `_root`.
3. Modelos antigos de mesmo nome vão para `ResourcesAntigos` / `EstruturasAntigas` / `IconesAntigos`; backup nunca é sobrescrito. Rodar de novo troca só o que o script criou (atributo `MundoCompleto`). O `mundo-completo` não é apagado.

## Bancada das estruturas (ajustar os modelos)

`scripts/studio/structure-bench.luau`, no Studio em **Edit**, igual à `weapon-bench.luau` das armas. Troque `MODE` no topo e rode:

1. `MODE = "montar"`: cria `Workspace.BancadaEstruturas` perto de (-630, 0, 520), com uma estação por template: um disco travado do tamanho do círculo da peça e o `Visual` por cima, posto como o jogo põe (o telhado já na altura dele). Uma fileira por tipo de peça.
2. Mova, gire e redimensione só o `Visual` de cada estação, em relação ao disco.
3. `MODE = "captar"`: para cada `Visual` que mudou, refaz o template em `Assets.Structures` com o pivô no centro do disco, guarda o antigo em `ServerStorage.EstruturasAntigas` (nunca sobrescreve) e confere remontando como o jogo. **Salve o place.**
4. `MODE = "apagar"`: tira a bancada.

Regra: o pivô do template continua sendo o centro do círculo da peça, no chão.

## Dono e revive

Toda peça guarda o dono (não há id de vida). Quando o dono **morre ou sai do jogo**, o `StructureService.removeOwned` apaga todas as peças dele e libera o espaço (a morte chama pelo `DeathService`, a saída também). A morte/saída chama `removeOwned(player)` uma única vez; um revive futuro simplesmente não chama, e as peças ficam. Uma peça apagada por fora (pelo Studio, por exemplo) também libera o espaço.

"Aliado" é uma função única, `BuildRules.areAllies(userIdA, userIdB)`, que hoje só responde "é o mesmo jogador". Porta e espinho usam ela: quando os times existirem, muda só essa função.

## Limite

`BuildRules.MAX_PER_PLAYER` é `nil` (sem limite). Para limitar, coloque um número ali; o servidor já confere.

## Como adicionar uma peça nova

Peça nova é dado, sem código. Veja `adicionar-item.md`:

1. Item com `category = "placeable"` e bloco `structure` em `src/shared/Defs/Items.luau`.
2. Texto `item.<id>` em `src/shared/Strings/ptBR.luau`.
3. Receita em `src/shared/Defs/Recipes.luau`.
4. `bash scripts/check.sh` valida o bloco.

Nenhum sistema testa o id da peça; só o `kind` (`wall`, `door`, `spike`, `spike_door`, `station`, `chest`, `fire`, `extractor`, `furnace`, `bridge`, `roof`, `sign`, `well`, `bed`) decide o comportamento. O visual é um bloco provisório em `src/shared/Models/StructureModel.luau`: trocar o modelo é trocar só esse arquivo.

## Comandos de teste

No Studio, Command Bar no servidor:

```lua
local p = game.Players:GetPlayers()[1]
game.ServerStorage.DevGive:Invoke(p, "campfire", 1)
game.ServerStorage.DevGive:Invoke(p, "wood_wall", 10)
game.ServerStorage.DevGive:Invoke(p, "chest", 1)
```

Selecione o slot e solte o clique (ou o joystick direito) para colocar. Os antigos `DevWorkbench` e `DevCampfire` não existem mais.
