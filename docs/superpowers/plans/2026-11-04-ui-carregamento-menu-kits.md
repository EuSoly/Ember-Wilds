# UI 1: carregamento, menu e kits — Plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Trocar a tela de carregamento e o menu pelo visual rústico aprovado: barra com sol que vira lua, menu com o boneco do jogador segurando o livro no centro, coluna à esquerda e kits atrás de um botão, com os três jeitos de comprar (pontos/1 vida, Robux/1 vida simulado, Robux/permanente simulado).

**Architecture:** Regras puras novas em `src/shared/UIFlow` (estado dos kits do mockup, layout do menu) e em `src/first` (progresso do carregamento), testadas no Lune. O menu passa a ser todo da casca Vide (`MenuShell`): o molde `MainMenu` deixa de ser usado. Componentes rústicos num módulo próprio (`UI/Rustic.luau`) a partir de tokens novos na `Palette`. Servidor: só o `CosmeticService` grava a skin equipada também no Player.

**Tech Stack:** Luau `--!strict`, Vide, Rojo 7.7.1, Lune (testes), MCP do Roblox Studio (verificação e envio de imagens).

**Spec:** `docs/superpowers/specs/2026-11-04-ui-carregamento-menu-kits-design.md` (ler inteiro antes de começar). Preview: `docs/game-design/propostas/menu-v1/preview.html`. Design system: `docs/game-design/design-system/README.md`.

## Global Constraints

- Branch `ui-menu-carregamento` a partir da `main`. Commits em pt-BR, terminando com `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Sem push.
- `--!strict`, comentários do porquê em pt-BR, identificadores em inglês, arquivos pequenos (o Elizeu estuda o código).
- Cores rústicas = hex exatos da seção 2 do design system (lista na Task 1).
- Alvos de toque ≥ 44 px (`Theme.touchMinSize`). Compacto = largura < 900 **ou** altura < 500.
- Textos novos em `src/shared/Strings/ptBR.luau`, exceto o carregamento (textos fixos no script/molde).
- Mockup: nenhum evento de rede novo, nenhum atributo escrito pelo cliente, nenhum `MarketplaceService`. JOGAR envia `Net.RequestSpawn.Fire({ KitId = KitList.selected })` como hoje (só kit de pontos).
- Preços Robux provisórios (1 vida / permanente): Iniciante 15/99, Explorador 25/199, Sobrevivente 49/399, Veterano 99/799. Kit que começa permanente no mockup: `kit_starter`.
- Livro do boneco = clone de `ReplicatedStorage.Assets.Tools.book` (só no place). Não usar `Workspace.book`.
- Enviar imagens ao Roblox **só depois de o Elizeu confirmar** (conta dele, CreatorType User).
- Depois de criar arquivos novos, o Rojo costuma DUPLICAR no place: conferir e apagar cópias antes de testar no Studio.
- `bash scripts/check.sh` verde ao fim de cada task.

## Review Focus

1. **Tela pequena (celular deitado 667×375, 568×320):** coluna, boneco, Kits/JOGAR e painel de kits não se sobrepõem nem saem da tela; no compacto o painel de kits cobre o boneco em vez de espremer. → testes em `menulayout.spec` (Task 3) + conferência no Studio (Task 9).
2. **Carregamento que termina antes da metade ou demora muito:** pronto cedo → a barra corre até o fim passando pela lua (sem pular a lua nem travar); demora → a barra fica parada perto de 90% sem passar de 1. → testes em `loadingmath.spec` (Task 6).
3. **Pontos mudam com um kit escolhido** (morreu/nasceu, `KitPoints` caiu): kit de pontos caro demais perde a seleção (já existe no `KitList`) e o botão Kits volta a mostrar o permanente ativo ou "Nenhum". → teste em `kitoffer.spec` (Task 2) sobre `current` com `pointsKit = nil`.
4. **Imagem ainda não carregada ou id vazio:** logo/sol/lua com id `""` não quebram a tela; sol/lua caem para um círculo de Frame. → Task 5 (fallback) e Task 6 (script não depende da imagem).
5. **Abrir/fechar painéis rápido e sair do menu com Kits aberto:** o boneco do menu é criado uma vez e destruído ao sair do menu; voltar ao menu abre no "play" (kits fechado). → Task 7/9, conferência no Studio.

---

### Task 1: Tokens e componentes rústicos

**Files:**
- Modify: `src/shared/Palette.luau` (grupo novo `rustic`)
- Modify: `src/shared/Theme.luau` (`Theme.rustic = toColors(Palette.rustic)`)
- Create: `src/client/UI/Rustic.luau`
- Test: `tests/palette.spec.luau`

**Interfaces:**
- Produces: `Palette.rustic` / `Theme.rustic` com as chaves `outline, charcoal, woodShadow, walnut, woodLight, woodEdge, leatherShadow, leather, leatherLight, paperShadow, paper, paperLight, moss, emberShadow, ember, emberLight, cream, textSecondaryDark, textSecondaryLight, success, disabled, disabledText, nightShadow, night, nightLight`.
- Produces (`Rustic.luau`, cada função recebe props do Vide como o `Kit` e devolve a instância):
  - `Rustic.plate(props): Frame` — placa de madeira (nogueira, filete claro em cima via `UIGradient`, `UIStroke` outline 2 px, `UICorner` 4 px).
  - `Rustic.paper(props): Frame` — folha de papel (paper, borda paperShadow).
  - `Rustic.button(props): TextButton` — `props.kind: "wood" | "leather" | "ember" | "success" | "disabled"`, `props.text: string | () -> string`, `props.subtext: (string | () -> string)?` (linha menor embaixo), `props.Activated`. Texto creme, exceto ember/success (carvão). Altura padrão 52, mín 44.
  - `Rustic.label(props): TextLabel` — texto sem contorno grosso (para papel), `props.dark: boolean?`.

- [ ] **Step 1:** Em `tests/palette.spec.luau`, incluir `Palette.rustic` em "every color is #RRGGBB" e um teste novo "rustic colors match the design system" com `walnut == "#59402D"`, `leather == "#95603D"`, `paper == "#E8D5AE"`, `ember == "#E99843"`, `cream == "#FFF3D6"`, `charcoal == "#29241F"`.
- [ ] **Step 2:** `lune run tests/run` → falha (`rustic` nil).
- [ ] **Step 3:** Adicionar `Palette.rustic` com os hex da seção 2 do design system (`outline #211A15, charcoal #29241F, woodShadow #38291F, walnut #59402D, woodLight #805739, woodEdge #AD7745, leatherShadow #68432D, leather #95603D, leatherLight #B87C4B, paperShadow #B99462, paper #E8D5AE, paperLight #F4E5C6, moss #78834F, emberShadow #B75A22, ember #E99843, emberLight #FFC66B, cream #FFF3D6, textSecondaryDark #C9B898, textSecondaryLight #59402D, success #92B56A, disabled #51483D, disabledText #B9AA91`) e as cores da noite do carregamento (`nightShadow #363F84, night #5B6FC4, nightLight #9FB6FF`, do preview). `Theme.rustic`. Criar `Rustic.luau`.
- [ ] **Step 4:** `bash scripts/check.sh` → verde.
- [ ] **Step 5:** Commit `feat: tokens e componentes rústicos da UI`.

### Task 2: Regras dos kits do mockup (pontos, Robux 1 vida, permanente)

**Files:**
- Create: `src/shared/UIFlow/KitOffer.luau`
- Modify: `src/shared/UIFlow/MockStore.luau` (preços Robux dos kits e kit inicial permanente)
- Test: `tests/kitoffer.spec.luau`, `tests/mockstore.spec.luau`

**Interfaces:**
- Produces (`KitOffer`, puro, sem Roblox):
  - `export type State = { owned: { [string]: boolean }, active: string?, robuxOnce: string? }`
  - `export type Source = "points" | "robuxOnce" | "permanent"`
  - `KitOffer.new(owned: { string }): State`
  - `KitOffer.chooseRobuxOnce(state, kitId): State` — define `robuxOnce`.
  - `KitOffer.clearRobuxOnce(state): State`
  - `KitOffer.buyPermanent(state, kitId): State` — marca posse (não ativa).
  - `KitOffer.toggleActive(state, kitId): State` — só se possuído; ativa (troca o anterior) ou desativa se já ativo.
  - `KitOffer.current(state, pointsKit: string?): (string?, Source?)` — ordem: `pointsKit` → `robuxOnce` → `active` → `nil`.
  - `KitOffer.spend(state): State` — limpa `robuxOnce`, mantém `active`.
  - Todas devolvem estado novo (não mutam o argumento).
- Produces (`MockStore`): `MockStore.KIT_ROBUX: { [string]: { once: number, forever: number } }` e `MockStore.KIT_STARTS_OWNED: { string } = { "kit_starter" }`.

- [ ] **Step 1:** Testes em `tests/kitoffer.spec.luau`:
  - "points choice wins over robux once and active": `current(s, "kit_explorer")` → `"kit_explorer", "points"` com `robuxOnce = "kit_survivor"` e `active = "kit_starter"`.
  - "robux once wins over active": sem pontos → `"kit_survivor", "robuxOnce"`.
  - "active alone": → `"kit_starter", "permanent"`; nada → `nil, nil`.
  - "toggleActive ignores not owned": `toggleActive(new({}), "kit_veteran").active == nil`.
  - "toggleActive swaps and turns off": ativa A, ativa B → `active == B`; ativa B de novo → `nil`.
  - "spend clears only robuxOnce": `spend` → `robuxOnce == nil`, `active` igual.
  - "functions do not mutate the input": guardar referência, chamar `chooseRobuxOnce`, conferir que o antigo continua com `robuxOnce == nil`.
  - "points kit dropped falls back" (Review Focus 3): `current(s, nil)` com `active = "kit_starter"` → `"kit_starter", "permanent"`.
- [ ] **Step 2:** Em `tests/mockstore.spec.luau`: "kit robux prices" — os 4 pares exatos da Global Constraints; "every kit has robux prices" — cada id de `Defs.Kits` (require `../src/shared/Defs`) tem entrada em `KIT_ROBUX`; "starts owned exists" — cada id de `KIT_STARTS_OWNED` existe em `Defs.Kits`.
- [ ] **Step 3:** `lune run tests/run` → falha.
- [ ] **Step 4:** Implementar `KitOffer.luau` e as tabelas no `MockStore` (comentário: dados de mockup, apagar na fase da compra real).
- [ ] **Step 5:** `bash scripts/check.sh` → verde.
- [ ] **Step 6:** Commit `feat: regras dos kits do mockup (pontos, Robux, permanente)`.

### Task 3: Layout do menu novo

**Files:**
- Modify: `src/shared/UIFlow/MenuLayout.luau`
- Test: `tests/menulayout.spec.luau`

**Interfaces:**
- Produces: `MenuLayout.compute(width, height, kitsOpen: boolean?): Layout` com os campos atuais **mais**: `compact: boolean`, `heroCenterX: number`, `heroBottom: number` (base do boneco), `heroSize: number` (lado do quadrado do `ViewportFrame`), `actionsY: number` (topo da linha Kits/JOGAR), `actionsHeight: number`, `kitPanelX: number`, `kitPanelWidth: number`, `kitsCoverHero: boolean`.
- Constantes novas: `NAV_COUNT = 6` (Perfil, Cosméticos, Loja, Tutorial, Ranking, Configurações — continua 6), `COLUMN_WIDTH` 200 desktop / 144 compacto (design system §8), `ACTIONS_HEIGHT = 60` (botão principal), `KIT_PANEL_MAX = 520`, `KIT_PANEL_MIN = 340`.
- Regras: hero centrado na área à direita da coluna; com `kitsOpen` e não compacto, centrado na área entre a coluna e o painel de kits; no compacto o painel de kits ocupa toda a área à direita da coluna e `kitsCoverHero = true`.

- [ ] **Step 1:** Ampliar `SIZES` do spec para `{800,400},{1130,793},{1920,1080},{1280,720},{844,390},{667,375},{568,320}` e acrescentar:
  - "compact by width or height": `compute(899, 700).compact`, `compute(1280, 499).compact`, `not compute(1280, 720).compact`.
  - "hero and actions stay inside the play area": para cada tamanho, `heroCenterX - heroSize/2 >= columnX + columnWidth`, `actionsY + actionsHeight <= height - MARGIN`, `heroBottom <= actionsY`, `heroSize > 0`.
  - "kits panel never overlaps the column and fits": `kitPanelX >= columnX + columnWidth`, `kitPanelX + kitPanelWidth <= width - MARGIN`.
  - "desktop kits keep the hero visible": em 1920×1080 e 1280×720 com `kitsOpen`, `heroCenterX + heroSize/2 <= kitPanelX` e `not kitsCoverHero`.
  - "compact kits cover the hero": em 667×375 com `kitsOpen`, `kitsCoverHero`.
  - Manter os testes atuais passando (ajustar "800x400 should fit" se a coluna compacta mudar a conta).
- [ ] **Step 2:** `lune run tests/run` → falha.
- [ ] **Step 3:** Implementar no `MenuLayout`.
- [ ] **Step 4:** `bash scripts/check.sh` → verde.
- [ ] **Step 5:** Commit `feat: layout do menu com boneco, kits e compacto`.

### Task 4: Skin equipada também no Player (servidor)

**Files:**
- Modify: `src/server/Services/CosmeticService.luau` (`apply`)
- Modify: `docs/guia/dados.md` ou `docs/guia/boneco.md` (onde o atributo `Cosmetic_<slot>` está documentado: acrescentar "também no Player")

**Interfaces:**
- Produces: atributo `StatNames.CosmeticPrefix .. slot` (ex. `Cosmetic_body`) no **Player**, com o mesmo id do personagem, escrito em `apply` (perfil carregado e cada `equip`).

- [ ] **Step 1:** Em `apply`, além do personagem, `player:SetAttribute(attribute, cosmeticId)` (só se mudou, como `writeSlot`). Atualizar o comentário do topo do arquivo.
- [ ] **Step 2:** `bash scripts/check.sh` → verde.
- [ ] **Step 3:** Studio (MCP): Play, no Server conferir `Players:GetPlayers()[1]:GetAttribute("Cosmetic_body") == "body_default"` (ou o equipado salvo). Equipar outra skin pelo comando de dev (DevDataService) e conferir que o atributo do Player muda.
- [ ] **Step 4:** Commit `feat: skin equipada também no Player para o menu`.

### Task 5: Imagens (logo, sol, lua) e ids num lugar só

**Files:**
- Create: `assets/ui/brand/sun.png`, `assets/ui/brand/moon.png` (512×512, transparente, desenho do preview: sol brasa com 8 raios e contorno carvão; lua crescente azul-clara com 2 crateras)
- Create: `src/shared/UiImages.luau`
- Modify: `src/first/LoadingScreen.model.json` (ids na propriedade `Image`, Task 6)

**Interfaces:**
- Produces: `UiImages.LOGO: string`, `UiImages.SUN: string`, `UiImages.MOON: string` (`"rbxassetid://N"`; `""` = ainda não enviado). `UiImages.has(id: string): boolean` (`id ~= ""`).

- [ ] **Step 1:** Gerar `sun.png` e `moon.png` com Python/PIL (script no scratchpad, não no repo), cores do design system.
- [ ] **Step 2:** **Parar e pedir ao Elizeu** a confirmação para enviar `ember-wilds-logo.png`, `sun.png` e `moon.png` na conta dele pelo MCP do Studio (`upload_image`). Sem confirmação: seguir com ids `""` (as telas usam o fallback).
- [ ] **Step 3:** Enviar e gravar os ids em `UiImages.luau` (comentário: de onde vem cada imagem e como trocar).
- [ ] **Step 4:** `bash scripts/check.sh` → verde.
- [ ] **Step 5:** Commit `feat: imagens do logo, sol e lua`.

### Task 6: Tela de carregamento (sol → lua)

**Files:**
- Create: `src/first/LoadingMath.luau` (ModuleScript em `ReplicatedFirst`, puro)
- Modify: `src/first/Loading.client.luau`
- Modify: `src/first/LoadingScreen.model.json`
- Test: `tests/loadingmath.spec.luau`

**Interfaces:**
- Produces (`LoadingMath`):
  - `LoadingMath.WAITING_TARGET = 0.9`, `LoadingMath.WAIT_RATE = 0.4` (aproximação exponencial: metade em ~2 s), `LoadingMath.FINISH_RATE = 1.5` (fração por segundo, linear, depois de pronto), `LoadingMath.NIGHT_AT = 0.5`.
  - `LoadingMath.step(progress: number, dt: number, ready: boolean): number` — esperando: `progress + (WAITING_TARGET - progress) * min(dt * WAIT_RATE, 1)`, nunca acima de `WAITING_TARGET`; pronto: `min(progress + dt * FINISH_RATE, 1)`.
  - `LoadingMath.isNight(progress: number): boolean` — `progress >= NIGHT_AT`.
  - `LoadingMath.status(progress: number): string` — `"Carregando o mundo…"` antes da metade, `"Acendendo as fogueiras…"` depois, `"Pronto!"` em 1.
- Molde (nomes combinados, todos opcionais): `Root` (CanvasGroup), `Art` (ImageLabel tela cheia, fundo provisório = gradiente de dia do preview; Image vazia), `Night` (Frame tela cheia azul-noite, `BackgroundTransparency` 1 → ~0,35 à noite, com estrelas), `Logo` (ImageLabel, `UiImages.LOGO` gravado no molde), `Track` (Frame de madeira), `Fill` (Frame dentro do `Track`), `Sun`/`Moon` (ImageLabel; com Image vazia, mostram um círculo `UICorner` 1,0 na cor ember/nightLight), `StatusLabel`, `TipLabel` ("Dica: fique perto da fogueira à noite para não congelar.").

- [ ] **Step 1:** Testes em `tests/loadingmath.spec.luau` (require `../src/first/LoadingMath`):
  - "waiting approaches but never passes the target": 600 passos de 1/60 sem pronto → `<= 0.9` e `> 0.85`.
  - "reaches the middle in about two seconds": 120 passos de 1/60 sem pronto → entre 0.4 e 0.6.
  - "ready runs to the end through the night" (Review Focus 2): de 0.2, pronto, passos de 1/60 → passa por algum valor com `isNight` verdadeiro e termina em exatamente 1; nunca acima de 1.
  - "status text by phase": 0.1 → dia, 0.5 → noite, 1 → "Pronto!".
  - "big dt is clamped": `step(0, 10, false) <= 0.9`.
- [ ] **Step 2:** `lune run tests/run` → falha.
- [ ] **Step 3:** Implementar `LoadingMath.luau`.
- [ ] **Step 4:** Reescrever `LoadingScreen.model.json` com os elementos acima (Scale, não pixels; `IgnoreGuiInset`, `ScreenInsets None`, `DisplayOrder 100`, cores do `Palette.rustic` escritas como Color3 no JSON).
- [ ] **Step 5:** `Loading.client.luau`: usar `LoadingMath.step` no laço (ready = jogo carregado **e** `DataReady`), posicionar `Sun`/`Moon` na ponta do `Fill` (`Position.X.Scale = progress` dentro do `Track`), alternar `Sun.Visible`/`Moon.Visible` por `isNight`, tween de ~150 ms em `Night.BackgroundTransparency`, na cor do `Fill` (ember → night) e no brilho do `Track`; `StatusLabel.Text = status(progress)`. Fallback de círculo quando `Image == ""`. Todos os elementos via `FindFirstChild(nome, true)` e opcionais.
- [ ] **Step 6:** `bash scripts/check.sh` → verde.
- [ ] **Step 7:** Studio: Play e capturar a tela (MCP `screen_capture`) no começo (sol) e depois da metade (lua, fundo escuro). Conferir que some com fade.
- [ ] **Step 8:** Commit `feat: carregamento com sol que vira lua`.

### Task 7: Boneco do menu com o livro

**Files:**
- Create: `src/client/Menu/MenuBoneco.luau`

**Interfaces:**
- Consumes: `BonecoModel.build/applyLook/destroy` (`src/client/Boneco/BonecoModel.luau`), `Sources.attribute`, `Defs.Cosmetics`, `Defs.CosmeticSlots.body.default`, atributo `Cosmetic_body` do Player (Task 4).
- Produces: `MenuBoneco.build(visible: () -> boolean): ViewportFrame` — `ViewportFrame` transparente (Size/Position definidos por quem chama). Cria o boneco quando `visible()` fica verdadeiro e destrói quando fica falso (mesmo padrão do `CosmeticsPanel`). Skin = `Cosmetic_body` do Player (id inválido/ausente → padrão). Livro = clone de `ReplicatedStorage.Assets.Tools.book` (sem `Tool`: usar o `Handle`/modelo dentro dele), soldado na frente do corpo entre as duas mãos, mãos puxadas para as bordas do livro (mexer nos `C0` de `leftHandJoint`/`rightHandJoint`); sem o asset, boneco sem livro + um `warn`. Câmera de frente, um pouco de cima (como o `CosmeticsPanel`), com sombra no chão (Frame elíptico atrás do `ViewportFrame`, feito por quem chama).

- [ ] **Step 1:** Implementar `MenuBoneco.luau` (pose e câmera ajustadas no olho).
- [ ] **Step 2:** `bash scripts/check.sh` → verde.
- [ ] **Step 3:** Commit `feat: boneco do menu segurando o livro`. (A verificação visual é na Task 9, quando ele entra no menu.)

### Task 8: Estado dos kits e painel de kits

**Files:**
- Create: `src/client/Menu/KitShop.luau` (estado Vide do mockup)
- Create: `src/client/Menu/KitsPanel.luau`
- Modify: `src/client/Menu/MenuState.luau` (Panel ganha `"kits"`)
- Modify: `src/shared/Strings/ptBR.luau`
- Test: `tests/mockstore.spec.luau` (chaves novas existem)

**Interfaces:**
- Consumes: `KitOffer` (Task 2), `MockStore.KIT_ROBUX/KIT_STARTS_OWNED`, `KitList.selected`/`KitList.toggle` (`src/client/Screens/KitList.luau`), `KitRules.canBuy/sorted`, `Rustic` (Task 1), `MenuState.notify`, `ItemIcon` (ícone do primeiro item do kit).
- Produces (`KitShop`):
  - `KitShop.state: () -> KitOffer.State` (fonte Vide, começa com `KitOffer.new(MockStore.KIT_STARTS_OWNED)`).
  - `KitShop.choosePoints(kitId)` — `KitList.toggle(kitId)` e, se ficou escolhido, `clearRobuxOnce`.
  - `KitShop.buyOnce(kitId)` / `KitShop.buyForever(kitId)` — `MenuState.notify(Strings.get("mock.simulated"))` (chave do aviso que a Loja já usa) e atualizam o estado; `buyOnce` também faz `KitList.selected(nil)`.
  - `KitShop.toggleActive(kitId)`.
  - `KitShop.current(): (string?, KitOffer.Source?)` — reativo (lê `KitList.selected()` e `state()`).
  - `KitShop.spend()` — chamado ao nascer.
- Produces (`KitsPanel`): `KitsPanel.build(): Frame` — folha `Rustic.paper` com título, "Seus pontos: N", uma linha por kit (ordem `KitRules.sorted`), botões conforme o spec (pontos/Robux 1 vida/Robux para sempre; possuído → um botão verde "Usar"/"Ativo"; pontos insuficientes → `disabled` com "faltam N"); borda brasa no kit de `KitShop.current()`; botão fechar → `MenuState.open("play")`. Rola se não couber (`ScrollingFrame`, `AutomaticCanvasSize` Y).
- Strings novas: `menu.nav.settings = "Configurações"`, `menu.kits.button = "Kits"`, `menu.kits.none = "Nenhum"`, `menu.kits.simulated = "{name} (simulado)"`, `menu.play.big = "JOGAR"`, `kit.panel.title = "ESCOLHA SEU KIT"`, `kit.yourPoints = "Seus pontos: {points}"`, `kit.once = "1 vida"`, `kit.forever = "para sempre"`, `kit.missing = "faltam {points}"`, `kit.robux = "\u{E002} {price}"` (símbolo do Robux nas fontes do Roblox), `kit.use = "Usar"`, `kit.active = "Ativo"`.

- [ ] **Step 1:** Em `tests/mockstore.spec.luau`, teste "kit panel strings exist" com `Strings.has` para todas as chaves acima.
- [ ] **Step 2:** `lune run tests/run` → falha.
- [ ] **Step 3:** Strings; `MenuState.Panel` com `"kits"`; `KitShop.luau`; `KitsPanel.luau`.
- [ ] **Step 4:** `bash scripts/check.sh` → verde.
- [ ] **Step 5:** Commit `feat: painel de kits com pontos, Robux e permanente (mockup)`.

### Task 9: Casca nova do menu e aposentadoria do molde MainMenu

**Files:**
- Modify: `src/client/Menu/MenuShell.luau`
- Modify: `src/client/Controllers/ScreenController.luau`
- Delete: `src/client/Screens/MainMenu.luau`, `assets/ui/MainMenu.model.json`
- Modify: `src/shared/Strings/ptBR.luau` (remover `menu.nav.play`; manter `menu.play`, `menu.balance`, `menu.kits` se ainda usados — conferir com grep)

**Interfaces:**
- Consumes: `MenuLayout.compute(w, h, kitsOpen)` (Task 3), `Rustic` (Task 1), `UiImages.LOGO` (Task 5), `MenuBoneco.build` (Task 7), `KitsPanel.build`/`KitShop.current/spend` (Task 8), `SettingsScreen.open(true)`, `Net.RequestSpawn`, `KitList.selected`.
- Produces: o menu completo.
  - Topo: placa de nível + XP (`MockStore.PROFILE`, selo MOCKUP), logo (`ImageLabel`, some se `UiImages.has` falso), saldo + "+" (`MenuState.open("buy")`), tudo com `Rustic`.
  - Coluna (`Rustic.button` kind `wood`, selecionado `ember`): profile, cosmetics, shop, tutorial, ranking e **Configurações** (`SettingsScreen.open(true)`, não é painel).
  - "Home" (painel `play` ou `kits`): sombra + `MenuBoneco` + linha Kits (`leather`, subtexto = nome do kit de `KitShop.current()`, com `menu.kits.simulated` quando a fonte não for `"points"`, ou `menu.kits.none`) e JOGAR (`ember`, `Net.RequestSpawn.Fire({ KitId = vide.untrack(KitList.selected) })`). Botão Kits alterna `"kits"`/`"play"`.
  - Painel de kits à direita quando `MenuState.panel() == "kits"`, nas medidas de `MenuLayout`.
  - Posições recalculadas quando o tamanho da tela muda (`AbsoluteSize` do ScreenGui → `vide.source`).
  - Painéis antigos (Perfil, Loja…) continuam com a mesma moldura de hoje (o redesenho deles é outra fase), só posicionados pela coluna nova.
- `ScreenController`: tirar `MainMenu.mount` e o `showWhen(menu, …)`; no efeito de "playing", além de `KitList.selected(nil)`, `KitShop.spend()`.

- [ ] **Step 1:** Reescrever `MenuShell` (topo, coluna, home, kits) e ajustar `ScreenController`; apagar `MainMenu.luau` e `assets/ui/MainMenu.model.json`; grep por `MainMenu`, `PlayButton`, `menu.nav.play` e limpar referências restantes.
- [ ] **Step 2:** `bash scripts/check.sh` → verde.
- [ ] **Step 3:** Studio (MCP): apagar duplicatas do Rojo; Play; capturas em 1920×1080, 1280×720 e emulador 844×390/667×375/568×320: menu sem painel, com Kits aberto, com Perfil aberto. Conferir: nada sobreposto nem fora da tela; boneco com a skin do Player e o livro; trocar a skin pelo comando de dev muda o boneco; escolher kit de pontos e apertar JOGAR nasce com os itens; "comprar" Robux 1 vida mostra o aviso, o botão Kits mostra "(simulado)" e some depois de nascer; ativar/desativar permanente; morrer e voltar ao menu abre sem painel; Configurações abre pela coluna.
- [ ] **Step 4:** Commit `feat: menu novo com boneco, Kits e JOGAR`.

### Task 10: Documentação e grafo

**Files:**
- Modify: `docs/guia/telas.md` (carregamento: nomes combinados novos e onde trocar a arte; menu: casca nova, `MainMenu` aposentado, painel de kits, `KitShop`/`KitOffer`, como mexer nos preços provisórios; seção "Como apagar tudo" atualizada)
- Modify: `docs/pendencias.md` (arestas que a revisão final achar)
- Modify: `docs/game-design/design-system/README.md` §12 (estado: carregamento e menu aplicados)

- [ ] **Step 1:** Atualizar os docs.
- [ ] **Step 2:** `& (Get-Content graphify-out\.graphify_python) -m graphify update .` (PowerShell) → sem erro.
- [ ] **Step 3:** Commit `docs: guia das telas novas de carregamento, menu e kits`.
