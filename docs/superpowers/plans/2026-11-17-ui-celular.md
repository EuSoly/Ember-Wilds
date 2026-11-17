# UIs no celular sem rolagem — Plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Menu, saldo/galho, loja, ranking, configurações, coluna de receitas e livro cabem inteiros no celular deitado (área útil ~749×330) sem rolar; zoom da câmera vira opção nas Configurações e a pinça sai.

**Architecture:** As medidas ficam nos módulos puros de `src/shared/UIFlow/` (testados no Lune). As telas em `src/client/` só leem esses módulos e trocam a composição quando estão no compacto (`layout.compact` / `ScreenMetrics.short()`). O PC não muda, exceto pela nova opção de zoom.

**Tech Stack:** Luau `--!strict`, Vide (UI reativa), Rojo, Lune (testes: `tests/*.spec.luau`), StyLua, Selene, Studio MCP (emulador).

**Spec:** `docs/superpowers/specs/2026-11-17-ui-celular-design.md`

## Global Constraints

- "Compacto" = largura < 900 ou altura < 500 (`MenuLayout.COMPACT_WIDTH/HEIGHT`). Telas de janela usam `ScreenMetrics.short()`.
- PC (1280×720, 1920×1080) visualmente igual ao de antes. Os testes de PC que já existem continuam passando sem mudar o que verificam.
- Toque ≥ 44 px. **Única exceção:** os botões da coluna do menu no compacto têm 40 de altura.
- Texto ≥ 12 px nas telas mexidas. Não usar UIScale para fazer caber.
- Comentários e textos em pt-BR, no estilo dos arquivos vizinhos: dizer o porquê e a data quando for decisão do Elizeu (ex.: "(17/11/2026)").
- Comandos (Git Bash, na raiz do repo): `export PATH="$HOME/.rokit/bin:$PATH"`, depois `lune run tests/run`, `stylua --check src tests` e `selene src`. Os três precisam passar antes de cada commit.
- Commits terminam com `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Verificação visual: emulador do Studio, celular deitado 749×330 (ver memórias `reference-emulador-celular-studio` e `reference-teste-play-studio`). Abrir as telas por um LocalScript temporário no Play, como na auditoria (`docs/game-design/auditoria-ui-celular.md`, "Como as telas foram abertas"). Capturas vão para `docs/game-design/auditoria-celular/` com o nome `1711-<tela>.jpg`.

## Review Focus

1. **Escala de interface 1,25 no celular** ("Tamanho da interface" no máximo): as contas recebem px lógicos menores (749/1,25 × 330/1,25 ≈ 599×264). Nada pode sair da tela; rolar como reserva é aceitável. Testes nos Tasks 1, 4 e 6 cobrem 599×264.
2. **Celular pequeno (568×320)**: a coluna do menu pode rolar (reserva), mas os botões não somem nem se sobrepõem. Teste no Task 1.
3. **Loja aberta pelo "+" do saldo** (`MenuState.openShop("ember")`) no compacto: abre direto na página da Golden Ember, sem a rolagem animada. Verificação no Task 4.
4. **Zoom salvo fora da faixa ou ausente** (perfil antigo sem `camera_zoom`): o servidor publica o padrão 0,5 (`SettingsService.publishAll`), e a câmera fica em 34. Teste no Task 5.
5. **Livro com item sem receita e fora do criativo**: a faixa de botões some e o texto usa a altura toda. Verificação no Task 8.

---

### Task 1: Menu compacto cabe sem rolar

**Files:**
- Modify: `src/shared/UIFlow/MenuLayout.luau`
- Modify: `src/client/Menu/MenuShell.luau:171-248` (`levelPod`), `:250-299` (`balancePod`)
- Test: `tests/menulayout.spec.luau`

**Interfaces:**
- Produces: `MenuLayout.POD_HEIGHT_COMPACT = 48`, `MenuLayout.BUTTON_HEIGHT_COMPACT = 40`, `MenuLayout.BUTTON_GAP_COMPACT = 3`. Novos campos em `Layout`: `podHeight: number`, `buttonGap: number`. `bodyTop` passa a ser `m + podHeight + m`, logo 64 no compacto. `MenuLayout.BODY_TOP` continua sendo o valor do PC.

- [ ] **Step 1: Ajustar e escrever os testes**

Em `tests/menulayout.spec.luau`:
- Em `["column buttons fit at touch min or the column scrolls"]`, troque as asserções de 44 por: `if l.compact then assert(l.buttonHeight == 40) else assert(l.buttonHeight >= 44) end`, e use `l.buttonGap` no lugar de `BUTTON_GAP` onde a altura for conferida.
- Novo `["phone sizes fit the column without scrolling"]`: `for _, s in { {749,330}, {844,390}, {667,375} } do assert(not MenuLayout.compute(s[1], s[2]).columnScrolls) end`, e `assert(MenuLayout.compute(749,330).bodyTop == 64)`.
- Novo `["small phone and big ui scale keep the column inside"]`: para `{568,320}` e `{599,264}`, `l.columnBottom <= h` e `l.bodyTop >= l.podBottom`. Pode rolar.
- Novo `["pc keeps the old sizes"]`: `MenuLayout.compute(1280,720)` com `podHeight == 56`, `buttonHeight == 52`, `buttonGap == 4` e `bodyTop == MenuLayout.BODY_TOP`.

- [ ] **Step 2: Rodar e ver falhar.** `lune run tests/run`. Esperado: falham os testes novos e o que foi ajustado.

- [ ] **Step 3: Implementar em `MenuLayout.compute`.** Use `podHeight`, `buttonHeight` e `buttonGap` pelo `compact`. O `contentHeight` passa a usar `buttonGap`, e `podBottom = m + podHeight`. `ShopLayout` usa `MenuLayout.POD_HEIGHT` para `topHeight`; deixe como está (a barra da loja continua com 56).

- [ ] **Step 4: MenuShell.** A coluna usa `layout().buttonGap` no `UIListLayout.Padding`, que deixa de ser constante. Em `levelPod`, a altura vem de `layout().podHeight`. No compacto: avatar de 36 em (6,6), nome e nível em y 4 com altura 18, barra de XP em y 26 com altura 16. No PC fica como hoje. Em `balancePod`, a altura também vem de `podHeight`. A moeda passa a ser `math.min(COIN_SIZE, podHeight - 12)` e o "+" fica em `podHeight - 8` no compacto (mínimo 40; é parte da exceção do menu).

- [ ] **Step 5: Rodar os testes, o stylua e o selene.** Esperado: tudo passa.

- [ ] **Step 6: Commit.** `feat(menu): coluna e cartões menores no celular, 6 botões sem rolar`

---

### Task 2: Galho encostado no canto (só no compacto)

**Files:**
- Modify: `src/client/Menu/MenuShell.luau:301-320` (`branch`), `:533-547` e `:615-637` (`backdrop`)

**Interfaces:**
- Consumes: `layout().compact`, `layout().podWidth` (Task 1).
- Produces: nada para outras tarefas.

- [ ] **Step 1: Implementar.** No compacto, o galho é filho do ScreenGui `MenuBackdrop`, que ignora a área segura. Ele vem depois da árvore e tem ZIndex maior, então fica por cima dela e por baixo do menu (DisplayOrder 0 < 1). Ancore em `(1, 0)`, na posição `UDim2.fromScale(1, 0)`: borda direita e topo reais da tela. A largura em px reais é `max(card.AbsoluteSize.X * BRANCH_SHARE, backdrop.AbsoluteSize.X - card.AbsolutePosition.X + 12)`, com `card` = o `TopRight` (balancePod), lida por `GetPropertyChangedSignal("AbsolutePosition"/"AbsoluteSize")` numa source. A altura é largura / `BRANCH_ASPECT`. No PC fica o galho de hoje, no gui do menu, sem mudar. Os dois galhos podem existir ao mesmo tempo, cada um com `Visible` pelo `compact`. Continua escondido na loja e, a partir do Task 3, também no ranking compacto.

- [ ] **Step 2: Verificar no emulador (749×330).** Captura `1711-menu.jpg`: as folhas do galho tocam a borda direita e o topo da tela, o card do saldo aparece inteiro e o "+" funciona (clique pelo MCP). Captura no PC (1280×720) `1711-menu-pc.jpg`: o galho igual ao de antes.

- [ ] **Step 3: Rodar os testes, o stylua e o selene, e commitar.** `feat(menu): galho do saldo encostado no canto da tela no celular`

---

### Task 3: Ranking ocupa o topo no celular

**Files:**
- Modify: `src/shared/UIFlow/MenuLayout.luau` (campo novo)
- Modify: `src/client/Menu/MenuShell.luau` (visibilidade do logo, do saldo e dos galhos)
- Modify: `src/client/Menu/Ranking/RankingScreen.luau:259-270` (posição e tamanho) e as labels das abas
- Modify: `src/client/UI/Rustic.luau:136-149` (`Rustic.label` ganha `minSize`)
- Test: `tests/menulayout.spec.luau`

**Interfaces:**
- Produces: `Layout.rankingTop: number`, que é `podTop` no compacto e `bodyTop` no PC. A largura do ranking vai de `panelX` até `width - m`, a mesma do `panelWidth`. `Rustic.label(props)` aceita `props.minSize: number?` (padrão 10) para o `MinTextSize`.

- [ ] **Step 1: Teste** `["ranking starts at the top on phones"]`: `compute(749,330).rankingTop == 8`, `compute(1280,720).rankingTop == compute(1280,720).bodyTop`, e para todos os `SIZES`, `rankingTop < panelBottom`.
- [ ] **Step 2: Rodar e ver falhar.**
- [ ] **Step 3: Implementar.** No MenuLayout, o campo novo. No RankingScreen, a posição usa `l.rankingTop` e a altura é `l.panelBottom - l.rankingTop`. No MenuShell: com `MenuState.panel() == "ranking"` e `layout().compact`, o logo, o `balance` e os dois galhos ficam com `Visible = false`. No Rustic, o `minSize`. Nas abas do ranking e nos textos do pódio (`RankingScreen` linhas ~108 e ~213, `RankingPodium` ~96 e ~108), passe `minSize = 12` quando for compacto. Se o texto de 12 não couber na aba, a aba mostra só o ícone. Decida olhando a captura.
- [ ] **Step 4: Testes passam. Emulador:** `1711-ranking.jpg`, com o painel do y 8 até o fim, sem logo nem saldo, abas legíveis e nada saindo pela borda de baixo. PC: `1711-ranking-pc.jpg` igual ao de antes.
- [ ] **Step 5: Commit.** `feat(ranking): no celular ocupa o topo, sem logo e sem saldo`

---

### Task 4: Loja paginada no celular

**Files:**
- Modify: `src/shared/UIFlow/ShopLayout.luau`
- Modify: `src/client/Menu/Shop/ShopScreen.luau`, `Passes.luau:149-170`, `EmberPacks.luau:140-170`, `Featured.luau` (~281, `bannerHeight`)
- Test: `tests/shoplayout.spec.luau`

**Interfaces:**
- Produces, em `ShopLayout`:
  - Campos em `Layout`: `paged: boolean` (= `compact`) e `pageHeight: number`. `pageHeight` é a altura para os cartões numa página: `height - contentTop - m - SECTION_TITLE`. No PC o valor existe, mas ninguém usa.
  - `ShopLayout.PASS_CARD_HEIGHT = 236`, `ShopLayout.PASS_MIN_WIDTH = 150`, `ShopLayout.EMBER_CARD_HEIGHT = 200`.
  - `ShopLayout.passGrid(l: Layout, count: number): (number, number)`, que devolve colunas e altura do cartão. PC: `(5, 236)`. Paginado: colunas = `min(count, floor((contentWidth + GAP) / (PASS_MIN_WIDTH + GAP)))`, no mínimo 1; fileiras = `ceil(count / colunas)`; altura = `min(236, (pageHeight - (fileiras-1)*GAP) / fileiras)`.
  - `ShopLayout.emberCardHeight(l: Layout): number`, que é `min(200, pageHeight)` paginado. No PC não é usado.
  - `bannerHeight` paginado = `pageHeight`. No PC fica a fórmula de hoje.

- [ ] **Step 1: Testes** em `tests/shoplayout.spec.luau`:
  - `["phone pages fit the screen"]`: para `{749,330}`, `{844,390}`, `{667,375}` e `{599,264}`: `l.paged`, `l.contentTop + SECTION_TITLE + l.pageHeight <= h - 8`, `l.bannerHeight == l.pageHeight`. Com `cols, ch = passGrid(l, 4)`, a soma `rows*ch + (rows-1)*GAP <= l.pageHeight` e `ch >= 120`. `emberCardHeight(l) <= l.pageHeight`.
  - `["phone passes: one row of 4 at 749"]`: `passGrid(compute(749,330), 4)` retorna 4 colunas.
  - `["pc shop unchanged"]`: `compute(1280,720)` não é paginado, e `passGrid` retorna `(5, 236)`.
- [ ] **Step 2: Rodar e ver falhar.**
- [ ] **Step 3: ShopLayout.** Implementar os campos e as funções acima.
- [ ] **Step 4: ShopScreen.** Com `layout().paged`, cada `Section_<id>` fica com `Visible = active() == id`. O clique na aba faz `active(id)` e zera o `CanvasPosition`, sem tween. O handler de `CanvasPosition` que recalcula a aba ativa só age quando não é paginado. O efeito de `MenuState.shopSection()` faz `active(wanted)` no paginado e o `jump` de hoje no PC. A página rola só se passar da altura (reserva).
- [ ] **Step 5: Seções.** Passes: `ShopParts.grid` recebe colunas e altura de `ShopLayout.passGrid(layout(), passCount)`, com `passCount` contado no build. Quando a altura for menor que 236, o conteúdo do cartão encolhe: a arte vira fração da altura, e nome, "Para sempre" e preço mantêm a altura. Confira na captura. EmberPacks: além das duas fileiras de hoje, construa uma fileira paginada com os 5 pacotes como `smallCard`, com `columns = #packs` e altura `emberCardHeight`. Ela aparece só no paginado, e as duas fileiras de hoje só no PC. Featured: a altura do banner já vem de `bannerHeight`. O estado vazio ("Nenhum pacote em destaque") usa a mesma altura.
- [ ] **Step 6: Testes passam. Emulador:** `1711-loja-pacotes.jpg`, `1711-loja-gamepasses.jpg`, `1711-loja-giros.jpg` e `1711-loja-ember.jpg`. Cada página aparece inteira, sem pedaço da seção seguinte. O "+" do saldo abre direto na Golden Ember (Review Focus 3). PC: `1711-loja-pc.jpg` com a lista contínua de antes.
- [ ] **Step 7: Commit.** `feat(loja): uma página por aba no celular`

---

### Task 5: Opção de zoom da câmera, sem pinça

**Files:**
- Modify: `src/shared/Defs/Settings.luau` (entrada nova)
- Modify: `src/shared/Strings/ptBR.luau` (`"setting.camera_zoom"`)
- Modify: `src/shared/CameraMath.luau` (função nova)
- Modify: `src/client/Controllers/CameraController.luau`
- Test: `tests/cameramath.spec.luau`, `tests/settings.spec.luau`

**Interfaces:**
- Produces: `Defs.Settings.camera_zoom = { id = "camera_zoom", nameKey = "setting.camera_zoom", group = "controls", order = 7, kind = "number", default = 0.5, min = 0, max = 1 }`. O texto é `"Zoom da câmera"`. `CameraMath.zoomDistance(fraction: number, min: number, max: number): number`, que prende `fraction` em [0, 1] e devolve `min + fraction * (max - min)`.

- [ ] **Step 1: Testes.** `cameramath.spec`: `zoomDistance(0.5, 28, 40) == 34`, `zoomDistance(0, 28, 40) == 28`, `zoomDistance(1, 28, 40) == 40`, `zoomDistance(2, 28, 40) == 40` e `zoomDistance(-1, 28, 40) == 28`. `settings.spec`: `SettingsRules.validate(Defs.Settings.camera_zoom, nil)` não é válido (o servidor cai no padrão), e `validate(def, 0.5)` é válido.
- [ ] **Step 2: Rodar e ver falhar.**
- [ ] **Step 3: Implementar a def, a string e o CameraMath.**
- [ ] **Step 4: CameraController.** Leia `Players.LocalPlayer:GetAttribute(StatNames.SettingPrefix .. "camera_zoom")`, que é atributo do Player e dispara o `GetAttributeChangedSignal`. A cada mudança, e no `Start`, `setTargetDistance(CameraMath.zoomDistance(value, MIN_DISTANCE, MAX_DISTANCE))`. Valor não numérico vale 0,5. A roda continua como está. Apague a conexão `TouchPinch` e `pinchStartDistance`, e atualize o comentário do topo ("Zoom pela roda do mouse no PC; no toque, só pela opção das Configurações (17/11/2026)").
- [ ] **Step 5: Testes, stylua e selene passam. Play no Studio:** mudar a opção nas Configurações muda a altura da câmera.
- [ ] **Step 6: Commit.** `feat(camera): zoom nas configurações; pinça desligada no toque`

---

### Task 6: Configurações em 2 colunas no celular

**Files:**
- Create: `src/shared/UIFlow/SettingsLayout.luau`
- Modify: `src/client/Screens/SettingsScreen.luau` (`rows`, `row`, `mount`, controles)
- Test: `tests/settingslayout.spec.luau`

**Interfaces:**
- Consumes: `SettingsFormat.grouped(defs): { Group }`, `Group = { id, settings: { SettingDef } }`. Inclui `camera_zoom` (Task 5).
- Produces: `SettingsLayout.ROW_COMPACT = 40`, `SettingsLayout.HEADER_COMPACT = 24`, `SettingsLayout.GAP = 4`. `SettingsLayout.split(groups: { Group }): ({ Group }, { Group })` divide sem quebrar grupo e sem trocar a ordem, minimizando a coluna mais alta (um título conta como uma linha). `SettingsLayout.columnHeight(groups: { Group }): number` soma títulos, linhas e espaços.

- [ ] **Step 1: Testes** em `tests/settingslayout.spec.luau`:
  - `["current settings split sound | screen+controls"]`: com `SettingsFormat.grouped(Defs.Settings)`, a esquerda tem só `sound` e a direita tem `screen` e `controls`, nessa ordem.
  - `["tallest column fits a 749x330 phone window"]`: a altura útil é `330*0.95 - 40 (título) - 16`, e `max(columnHeight(left), columnHeight(right))` cabe nela.
  - `["one group stays whole"]`: um grupo sozinho fica todo à esquerda e a direita sai vazia.
- [ ] **Step 2: Rodar e ver falhar. Step 3: Implementar o SettingsLayout.**
- [ ] **Step 4: SettingsScreen no `ScreenMetrics.short()`.** A janela vai de `UDim2.new(0.96, 0, SHORT_WINDOW_SHARE, 0)` até o máximo da área. O título fica numa linha de 40 dentro da janela, no lugar da placa que sai para fora. O X de 44 fica no canto direito da linha do título e fecha. "Resetar" vira um botão `leather` de 44 de altura na mesma linha, à esquerda do X, com a mesma ação de hoje. A faixa `Buttons` some. O corpo tem dois Frames lado a lado, com metade da largura menos `GAP`, cada um com `UIListLayout` e as linhas de `split`. As linhas têm `ROW_COMPACT`, os títulos `HEADER_COMPACT` e o texto `minSize = 12`. Nos controles, a barrinha, a chave e as setas ocupam a meia largura (nome 40%, controle 38%, valor 22%; reajuste se a captura pedir). A lista não rola. No PC fica como hoje: uma lista e a faixa de botões embaixo. Dá para montar as duas versões e trocar por `Visible`, ou reconstruir no `short()`. Escolha a mais simples, sem duplicar o código das linhas (a mesma função `row` serve às duas).
- [ ] **Step 5: Testes passam. Emulador:** `1711-configuracoes.jpg` com as 7 opções à vista, X e Resetar no topo e nada cortado. A barrinha arrasta (1º clique pelo MCP). PC: `1711-configuracoes-pc.jpg`, igual ao de antes mais a linha "Zoom da câmera".
- [ ] **Step 6: Commit.** `feat(configuracoes): duas colunas no celular, X e Resetar no topo`

---

### Task 7: Coluna de receitas abaixo do selo de pontos

**Files:**
- Modify: `src/shared/UIFlow/HudLayout.luau` (funções novas)
- Modify: `src/client/UI/HudBottom.luau` (fonte reativa), `src/client/UI/CraftColumn.luau:255-258`
- Test: `tests/hudlayout.spec.luau`

**Interfaces:**
- Produces: `HudLayout.scorePillBottom(width: number, height: number): number`, que é `0.02*height + max(min(0.075*height, 0.21*width/4), 38)`, a mesma conta do `ScorePill` (escala 0,21×0,075 com aspecto 4 e mínimo de 38). `HudLayout.craftTop(width, height): number`, que é `max(0.12*height, scorePillBottom + 8)`. `HudBottom.craftTop(): number` aplica isso ao canvas do HUD (vale no PC e no toque).

- [ ] **Step 1: Testes:** `craftTop(749,330) >= scorePillBottom(749,330) + 8` e `scorePillBottom(749,330)` ≈ 44,6 (±0,5). `craftTop(1280,720) == 0.12*720` (PC igual).
- [ ] **Step 2: Rodar e ver falhar. Step 3: Implementar.** O CraftColumn fica em `Position = UDim2.new(0.02, 0, 0, HudBottom.craftTop())`. A altura fica como hoje (`0.68` da tela), menos o que desceu: `UDim2.new(0, w, 0.80, -craftTop)`, que termina onde terminava antes. Se o ScorePill mudar a conta no futuro, os dois ficam lado a lado no HudLayout. Deixe um comentário no ScorePill apontando para `HudLayout.scorePillBottom`.
- [ ] **Step 4: Testes passam. Emulador:** `1711-hud.jpg` com a primeira receita 8 px abaixo do selo "0 pts · #1".
- [ ] **Step 5: Commit.** `fix(hud): coluna de receitas não encosta no selo de pontos`

---

### Task 8: Livro de receitas no celular

**Files:**
- Modify: `src/client/Screens/RecipeBookScreen.luau` (constantes por `short()`, `TabButton`, `CloseButton`, `Book`, Pin/Give)
- Modify: `src/client/UI/BookSheet.luau:356-368` (`props.bottomInset`)

**Interfaces:**
- Produces: em `BookSheet(props)`, o `props.bottomInset: (() -> number)?` (padrão 0). O `Content` (ScrollingFrame) termina `bottomInset()` px antes do fim da ficha.

- [ ] **Step 1: Implementar no `ScreenMetrics.short()`** (no PC fica como hoje):
  - Painel: tela toda da área segura, menos 8 de cada lado (`UDim2.new(1, -16, 1, -16)`), centrado. A placa do título some, e o X (44) vai para a ponta direita da linha das abas, dentro do painel. `PAD` passa a ser o mínimo que ainda livra a moldura do `Kit.panel` (comece em 16 e confira na captura).
  - Abas: 44 de altura e só o ícone (a `Label` some), dividindo a largura menos 44 + GAP do X.
  - Grade: `CELL = 48`, `GAP = 6`, `GRID_SHARE = 0.46`. A ficha fica à direita com o resto.
  - Faixa de ações: um Frame de 44 de altura no fundo da área da ficha, com `UIListLayout` horizontal alinhado à direita, contendo Fixar e Pegar (mesma visibilidade e ação de hoje, 104×44). Visível quando algum dos dois está. `bottomInset` da ficha = `44 + GAP` quando a faixa está visível, senão 0. O posicionamento antigo por `besidePin`/`shift` só vale no PC.
- [ ] **Step 2: Rodar os testes, o stylua e o selene.**
- [ ] **Step 3: Emulador.** `1711-livro.jpg` com um item com receita: o texto ("Como fazer", "Precisa de") aparece inteiro ao rolar, e nenhum botão o cobre. `1711-livro-criativo.jpg` com Pegar e Fixar lado a lado na faixa. Um item sem receita e fora do criativo não tem faixa e o texto usa a altura toda (Review Focus 5). PC: `1711-livro-pc.jpg` igual ao de antes.
- [ ] **Step 4: Commit.** `feat(livro): layout de celular, ações numa faixa fixa embaixo`

---

### Task 9: Fechamento — escala 1,25, documentação e grafo

**Files:**
- Modify: `docs/game-design/auditoria-ui-celular.md` (seção "Corrigido em 17/11" com as medidas e as capturas)
- Modify: `docs/guia/hud.md` (zoom e coluna de receitas)

- [ ] **Step 1: Emulador com "Tamanho da interface" em 125%.** Menu, loja (as 4 páginas), ranking, configurações e livro, sem nada para fora da tela (Review Focus 1). Anote o que rola como reserva.
- [ ] **Step 2: Atualizar os docs** com o que mudou e as capturas `1711-*`.
- [ ] **Step 3: Grafo.** No PowerShell: `& (Get-Content graphify-out\.graphify_python) -m graphify update .`
- [ ] **Step 4: Testes, stylua e selene passam. Commit.** `docs(ui-celular): auditoria atualizada com as telas de 17/11`
