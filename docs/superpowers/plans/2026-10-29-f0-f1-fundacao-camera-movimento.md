# F0 Fundação + F1 Câmera e Movimento — Plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deixar o projeto com ferramentas, estrutura, definições de conteúdo e bootstrap prontos (F0), e provar câmera top-down 65° + movimento nativo + rotação para o mouse sob Server Authority (F1).

**Architecture:** Módulos com `Init()`/`Start()` carregados por um bootstrap por lado (servidor: `Services/`, cliente: `Controllers/`). Conteúdo e paleta são dados puros em `src/shared` (testáveis no Lune). A rotação do personagem roda em `RunService:BindToSimulation` no servidor e no cliente (predição), lendo uma InputAction `Aim` alimentada pelo cliente.

**Tech Stack:** Luau `--!strict`, Rojo 7.7.1, Rokit, Lune 0.11.1 (testes), selene 0.32.0, StyLua 2.6.0, luau-lsp 1.70.1. (Wally, Blink e Vide entram nas fases que os usam.)

**Spec:** `docs/superpowers/specs/2026-10-28-ember-wilds-mvp-design.md`

## Global Constraints

- `--!strict` na primeira linha de todo `.luau` em `src/` e `tests/`.
- Identificadores em inglês; comentários em português explicando o porquê; textos exibidos só via `Strings`.
- IDs de conteúdo: string estável, regex `^[a-z0-9_]+$`, igual à chave da tabela.
- Defs e Palette são dados puros: sem `game`, `Instance`, `Color3`, `Vector3` (para rodar no Lune). Cores como hex `"#RRGGBB"`.
- Require por string (`require("./X")`, `require("@self/X")`, `require("../X")`), que funciona no Roblox e no Lune.
- Server Authority: lógica de simulação usa `time()`; nada de `Destroy()`/trocar `Parent` dentro de `BindToSimulation`; atributos replicados ≤ 64 por instância e strings ≤ 50 chars.
- Cada `Start()` é síncrono e curto; quem precisa de loop cria a própria thread (`task.spawn`) ou conexão.
- Rokit: binários em `~/.rokit/bin` (no Git Bash, `export PATH="$HOME/.rokit/bin:$PATH"`). Rodar ferramentas da raiz do repo.
- Commit por tarefa, mensagem em pt-BR, sem push. Branch `mvp-n0`.
- Após mudar código: `& (Get-Content graphify-out\.graphify_python) -m graphify update .` (PowerShell).

## Review Focus

1. **Jogador que entrou antes do `Start()` do serviço** — `PlayerAdded` já disparou; ele precisa receber InputContext e configuração de personagem do mesmo jeito. (Task 6: iterar `Players:GetPlayers()` no `Start`.)
2. **Respawn** — referências a `Character`/`Humanoid`/`HumanoidRootPart` ficam velhas; a rotação deve usar sempre o personagem atual e ignorar personagem sem root. (Task 7: buscar o personagem a cada passo da simulação.)
3. **Cursor sobre a UI ou fora da janela / raycast sem chão** — a mira não pode virar NaN nem zerar e "pular"; mantém a última direção válida. (Task 7: `Facing.yawFromDirection` devolve `nil` para vetor ~zero e o chamador mantém o yaw atual; teste incluso.)
4. **Troca de dispositivo no meio da sessão** (`PreferredInput` muda de mouse para toque/gamepad) — a mira deve ir para zero e o personagem passa a virar para onde anda. (Task 7, passo do AimController.)
5. **Erro de digitação nas Defs** (item com tier inexistente, id diferente da chave, maxStack 0, nameKey sem texto) — o jogo deve falhar no boot com mensagem clara, nunca seguir silenciosamente. (Task 3: testes de validação.)

---

### Task 1: Toolchain, lint, testes e script de verificação

**Files:**
- Modify: `rokit.toml` (já atualizado: rojo 7.7.1, wally 0.3.2, wally-package-types 1.7.0, selene 0.32.0, StyLua 2.6.0, luau-lsp 1.70.1, blink 0.18.9, lune 0.11.1 — só commitar)
- Create: `selene.toml`, `stylua.toml`, `.luaurc`, `scripts/check.sh`, `tests/run.luau`, `tests/smoke.spec.luau`
- Modify: `.gitignore`, `README.md`

**Interfaces:**
- Produces: `tests/run.luau` descobre `tests/**/*.spec.luau`; cada spec retorna `{ [string]: () -> () }`; o runner executa cada função com `pcall`, imprime `PASS`/`FAIL nome: erro` e sai com código 1 se houver falha. `scripts/check.sh` é o comando único de verificação de todas as tarefas seguintes.

- [ ] **Step 1:** `selene.toml` com `std = "roblox"`; `stylua.toml` com tabs, `column_width = 120`, `call_parentheses = "Always"`; `.luaurc` com `{"languageMode": "strict"}`.
- [ ] **Step 2:** `.gitignore` acrescenta `Packages/`, `ServerPackages/`, `build/`, `.luau-lsp/`, `*.rbxlx` (o `sourcemap.json` já está).
- [ ] **Step 3: Write the smoke test** `tests/smoke.spec.luau`: `return { ["runner works"] = function() assert(1 + 1 == 2) end }`.
- [ ] **Step 4:** Implementar `tests/run.luau` (usa `@lune/fs` para listar recursivamente, `@lune/process` para `exit`). Requer cada spec por caminho relativo.
- [ ] **Step 5:** `scripts/check.sh` (bash, `set -e`): `stylua --check src tests` → `selene src tests` → `rojo build -o build/check.rbxlx` → `rojo sourcemap default.project.json -o sourcemap.json` → baixar `https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.luau` para `.luau-lsp/globalTypes.d.luau` se não existir → `luau-lsp analyze --platform=roblox --sourcemap=sourcemap.json --definitions=@roblox=.luau-lsp/globalTypes.d.luau src` → `lune run tests/run`.
- [ ] **Step 6: Verify:** `bash scripts/check.sh` → termina com `1 passed, 0 failed` e exit 0 (o scaffold atual com `--!strict` adicionado aos 3 arquivos existentes).
- [ ] **Step 7:** README em pt-BR: pré-requisitos (Rokit), `rokit install`, `bash scripts/check.sh`, `rojo serve` + plugin no Studio, onde estão os docs.
- [ ] **Step 8: Commit** `chore: toolchain, lint, testes com Lune e script de verificação`.

### Task 2: Estrutura do projeto, bootstrap e configuração do Workspace

**Files:**
- Modify: `default.project.json`
- Create: `src/shared/Lifecycle.luau`, `tests/lifecycle.spec.luau`, `src/first/` (pasta vazia com `.gitkeep`)
- Replace: `src/server/init.server.luau`, `src/client/init.client.luau`; Delete: `src/shared/Hello.luau`
- Create: `src/server/Services/` e `src/client/Controllers/` (vazios com `.gitkeep`)

**Interfaces:**
- Produces: `export type System = { Name: string?, Init: ((any) -> ())?, Start: ((any) -> ())? }` e `Lifecycle.run(systems: { System }): ()` — chama `Init` de todos na ordem dada, depois `Start` de todos; erro em qualquer um é relançado como `"[Lifecycle] <Init|Start> falhou em <Name>: <erro>"`. Bootstraps: requerem cada `ModuleScript` filho de `Services`/`Controllers`, ordenados por `Name`, definem `module.Name = child.Name` se ausente e chamam `Lifecycle.run`.

- [ ] **Step 1: Write the failing tests** `tests/lifecycle.spec.luau`:
  - `"init all before start"`: dois sistemas registram em `log`; esperado `{"A.Init","B.Init","A.Start","B.Start"}`.
  - `"optional phases"`: sistema sem `Init` e outro sem `Start` não quebram.
  - `"error names the system"`: `Init` que dá `error("boom")` em sistema `Name="Bad"` → `pcall` falha e a mensagem contém `"Init falhou em Bad"` e `"boom"`.
- [ ] **Step 2: Verify fail:** `lune run tests/run` → falham por módulo inexistente.
- [ ] **Step 3:** Implementar `src/shared/Lifecycle.luau`.
- [ ] **Step 4: Verify pass:** `lune run tests/run` → lifecycle passa.
- [ ] **Step 5:** `default.project.json`:
  - `ReplicatedFirst.First` → `src/first`; `ReplicatedStorage.Shared` → `src/shared`; `ServerScriptService.Server` → `src/server`; `StarterPlayer.StarterPlayerScripts.Client` → `src/client`.
  - Remover o `Baseplate` (o chão vem do `WorldService`, Task 6).
  - `Workspace.$properties`: `AuthorityMode: "Server"`, `StreamingEnabled: true`, `SignalBehavior: "Deferred"`, `StreamOutBehavior: "Opportunistic"`, `StreamingIntegrityMode: "PauseOutsideLoadedArea"`, `ModelStreamingBehavior: "Improved"`.
  - `StarterPlayer.$properties`: `CharacterUseJumpPower: false`, `CharacterJumpHeight: 0`, `EnableMouseLockOption: false`.
  - `Lighting.$properties`: `Technology: "ShadowMap"` (o resto da iluminação é F6).
- [ ] **Step 6:** Bootstraps de servidor e cliente conforme Interfaces, com `print("[Server] pronto")` / `print("[Client] pronto")` ao final.
- [ ] **Step 7: Verify:** `bash scripts/check.sh` passa; `grep -E 'name="(AuthorityMode|StreamingEnabled)"' build/check.rbxlx` mostra `AuthorityMode` = `0` e `StreamingEnabled` = `true`. Se o Rojo rejeitar alguma propriedade, remover só ela e listá-la no README como passo manual.
- [ ] **Step 8 (manual, Elizeu):** no Studio, com `rojo serve` conectado, conferir em Workspace → Properties que `AuthorityMode = Server` (o plugin pode não aplicar propriedades do Workspace ao vivo; se não aplicou, setar à mão e salvar/publicar o place). Play → Output mostra `[Server] pronto` e `[Client] pronto`, sem erros.
- [ ] **Step 9: Commit** `feat: estrutura do projeto, bootstrap Init/Start e Workspace com Server Authority`.

### Task 3: Paleta, tiers, strings e definições de conteúdo com validação

**Files:**
- Create: `src/shared/Palette.luau`, `src/shared/Strings/init.luau`, `src/shared/Strings/ptBR.luau`, `src/shared/Defs/init.luau`, `src/shared/Defs/Tiers.luau`, `src/shared/Defs/Items.luau`, `src/shared/Defs/Validate.luau`
- Test: `tests/palette.spec.luau`, `tests/strings.spec.luau`, `tests/defs.spec.luau`

**Interfaces:**
- Produces:
  - `Palette`: tabela congelada com `ui` (tokens da identidade: `panel = "#1E2230"`, `panelRaised = "#2A3042"`, `border = "#3A4258"`, `text = "#F4F1EA"`, `textSecondary = "#A9B0C2"`, `action = "#FF8A1F"`, `success = "#4CC38A"`, `warning = "#F5C542"`, `danger = "#E5484D"`), `tier` (`wood "#8B5A2B"`, `stone "#8A8F98"`, `gold "#F2B632"`, `diamond "#3FD0E0"`, `amethyst "#9B5DE5"`, `reidite "#D63384"`, `emerald "#2ECC71"`), `status` (`health "#E5484D"`, `hunger "#F28C28"`, `cold "#4DA3FF"`, `thirst "#2EC4B6"`, `oxygen "#E8F4FF"`, `heat "#FF6B35"`), `biome` (listas de 4 hex: `forest {"#6FBF4A","#3E8E41","#7A4E2A","#A77B4F"}`, `winter {"#EAF4FB","#A8D8F0","#2F6F62","#5B6C8F"}`, `ocean {"#F2D79B","#4FC3D9","#1F6F9F","#1F3F6F"}`, `desert {"#E8B86D","#C9774A","#5E9E4F","#FFD9A0"}`, `lava {"#3A2B2E","#FF5A1F","#FFB84D","#6E5A5E"}`, `nightFire {"#1B2A4A","#7F9CD6","#FFA43A","#FF8A1F"}`), `neutralFrame = "#8A8F98"`.
  - `export type TierDef = { id: string, order: number, color: string, rarityKey: string, nameKey: string }`. Tiers: wood 1 (`rarity.common`), stone 2 (`rarity.uncommon`), gold 3 (`rarity.rare`), diamond 4 (`rarity.epic`), amethyst 5 (`rarity.mythic`), reidite 6 (`rarity.legendary`), emerald 0 (ramo lateral, `rarity.legendary`). `color` vem de `Palette.tier`.
  - `export type ItemCategory = "resource" | "food" | "tool" | "weapon" | "armor" | "placeable" | "misc"`; `export type ItemDef = { id: string, nameKey: string, category: ItemCategory, tier: string?, maxStack: number }`. Itens iniciais: `wood`, `stone`, `gold` (resource, maxStack 255, sem tier), `berry` (food, 255), `wood_pickaxe`, `stone_pickaxe`, `gold_pickaxe` (tool, maxStack 1, tier wood/stone/gold).
  - `Strings.get(key: string): string` — devolve o texto pt-BR; chave ausente → `"[" .. key .. "]"`. `Strings.has(key: string): boolean`. Textos: `rarity.*` = Comum, Incomum, Raro, Épico, Mítico, Lendário; `tier.*` = Madeira, Pedra, Ouro, Diamante, Ametista, Reidite, Esmeralda; `item.*` dos 7 itens.
  - `Validate.all(defs: { Tiers: {[string]: TierDef}, Items: {[string]: ItemDef} }, hasString: (string) -> boolean): { string }` — devolve lista de erros (vazia = ok). `Defs/init.luau` monta `{ Tiers, Items }`, roda `Validate.all(..., Strings.has)` e dá `error` com todos os erros juntos se houver algum; retorna a tabela congelada.
  - `Palette`, cada def e as tabelas de Defs passam por `table.freeze`.

- [ ] **Step 1: Write the failing tests:**
  - `palette.spec`: todo valor em `ui`, `tier`, `status` e em cada lista de `biome` casa `^#%x%x%x%x%x%x$`; `Palette.tier.gold == "#F2B632"`; tentar `Palette.ui.text = "x"` dá erro (congelada).
  - `strings.spec`: `Strings.get("tier.gold") == "Ouro"`; `Strings.get("nao.existe") == "[nao.existe]"`; `Strings.has("rarity.legendary") == true`.
  - `defs.spec`: `require` do `Defs` não dá erro; `Defs.Tiers.gold.order == 3` e `.color == "#F2B632"`; `Defs.Items.gold_pickaxe.tier == "gold"`. Com tabelas falsas passadas a `Validate.all`: item com `tier = "plastic"` → erro contendo `"plastic"`; chave `"wood"` com `id = "Wood"` → erro de id; `maxStack = 0` → erro; `nameKey` que `hasString` nega → erro; defs corretas → `{}`.
- [ ] **Step 2: Verify fail:** `lune run tests/run` → os três specs falham.
- [ ] **Step 3:** Implementar Palette, Strings (+ptBR), Tiers, Items, Validate e Defs/init.
- [ ] **Step 4: Verify pass:** `bash scripts/check.sh` → tudo passa.
- [ ] **Step 5:** `docs/guia/adicionar-item.md` (pt-BR, curto): onde criar o item, o texto em `ptBR.luau`, o que a validação checa, como rodar `bash scripts/check.sh`.
- [ ] **Step 6: Commit** `feat: paleta, tiers, strings e definições de itens com validação no boot`.

### Task 4: Theme (cores e fontes para o Roblox)

**Files:**
- Create: `src/shared/Theme.luau`

**Interfaces:**
- Consumes: `Palette` (Task 3).
- Produces: `Theme.color(hex: string): Color3` (cache por hex, via `Color3.fromHex`); `Theme.ui`, `Theme.tier`, `Theme.status`: tabelas com os mesmos nomes da `Palette`, mas em `Color3`; `Theme.font`: `title = Font.fromEnum(Enum.Font.LuckiestGuy)`, `number = Font.fromEnum(Enum.Font.FredokaOne)`, `label = Font.new(BuilderSans, Bold)`, `body = Font.new(BuilderSans, Medium)` (BuilderSans via `Font.fromEnum(Enum.Font.BuilderSans)` com `Weight` ajustado); `Theme.panelTransparency = 0.15`, `Theme.corner = UDim.new(0, 12)`, `Theme.slotCorner = UDim.new(0, 8)`, `Theme.strokeThickness = 1`.

- [ ] **Step 1:** Implementar `Theme.luau` (Roblox-only, não testado no Lune).
- [ ] **Step 2: Verify:** `bash scripts/check.sh` passa (luau-lsp sem erros de tipo).
- [ ] **Step 3: Commit** `feat: módulo Theme com cores da paleta e fontes`.

### Task 5: Mundo de teste e personagem (servidor)

**Files:**
- Create: `src/server/Services/WorldService.luau`, `src/server/Services/CharacterService.luau`

**Interfaces:**
- Consumes: `Palette`/`Theme` (Tasks 3–4), `Lifecycle` (Task 2).
- Produces: `Workspace.World` (Folder) com `TestGround` (Part anchored, 256×2×256 studs, topo em Y=0, cor `Theme.color(Palette.biome.forest[1])`, `Material.SmoothPlastic`) e um `SpawnLocation` neutro no centro; `CharacterService` configura todo personagem: `Humanoid.AutoRotate = false`, `JumpHeight = 0`, e em `CharacterAppearanceLoaded` reaplica `HumanoidDescription` com `HeightScale/WidthScale/DepthScale/HeadScale = 1`, `BodyTypeScale = 0`, `ProportionScale = 0` (só se algum valor diferir, para não reaplicar à toa).

- [ ] **Step 1:** `WorldService.Init` cria a pasta, o chão e o spawn (fora da simulação, no Init).
- [ ] **Step 2:** `CharacterService.Start` conecta `PlayerAdded`/`CharacterAdded` **e** percorre `Players:GetPlayers()` existentes (Review Focus 1).
- [ ] **Step 3: Verify:** `bash scripts/check.sh` passa.
- [ ] **Step 4 (manual, Elizeu):** em Game Settings → Avatar, escolher o preset "Consistent Gameplay" (ou Custom Scale + colisor único) e salvar. Play: o avatar nasce no chão verde, não pula, e não gira sozinho ao andar (AutoRotate desligado; a rotação vem na Task 7).
- [ ] **Step 5: Commit** `feat: chão de teste e configuração do personagem (sem pulo, escala travada)`.

### Task 6: Contexto de input por jogador (InputAction de mira)

**Files:**
- Create: `src/server/Services/InputContextService.luau`, `src/shared/InputNames.luau`

**Interfaces:**
- Produces: `InputNames` = `{ Context = "Gameplay", Aim = "Aim", AimBinding = "AimBinding" }` (congelado). Para cada jogador (existente ou novo), o servidor cria `Player.Gameplay` (`InputContext`) → `Aim` (`InputAction`, `Type = Enum.InputActionType.Direction2D`) → `AimBinding` (`InputBinding` scriptable, alimentado pelo cliente via `InputBinding:Fire(Vector2)`; `InputAction:Fire` está depreciado). As ações de botão (Ação, Construir, Mochila, hotbar) entram na F2 neste mesmo contexto.

- [ ] **Step 1:** Implementar o serviço (cria no `PlayerAdded` e para jogadores já presentes no `Start`).
- [ ] **Step 2: Verify:** `bash scripts/check.sh` passa. Play no Studio: no Explorer, `Players.<você>.Gameplay.Aim.AimBinding` existe no servidor e no cliente.
- [ ] **Step 3:** Se a API de binding scriptable tiver outro nome/forma na versão atual do Studio, ajustar e registrar o que foi usado em `docs/research/05-server-authority.md` (seção "Achados na implementação").
- [ ] **Step 4: Commit** `feat: InputContext de gameplay por jogador com ação de mira`.

### Task 7: Rotação do personagem na simulação (mouse no PC, movimento no celular)

**Files:**
- Create: `src/shared/Facing.luau`, `tests/facing.spec.luau`, `src/shared/Simulation/FacingSim.luau`, `src/server/Services/SimulationService.luau`, `src/client/Controllers/SimulationController.luau`, `src/client/Controllers/AimController.luau`

**Interfaces:**
- Consumes: `InputNames` (Task 6), personagem com `AutoRotate = false` (Task 5).
- Produces:
  - `Facing.yawFromDirection(x: number, z: number): number?` — yaw em radianos para olhar na direção `(x, z)` do mundo (convenção do Roblox: frente = −Z, então `(0, -1) → 0`, `(1, 0) → -π/2`, `(-1, 0) → π/2`, `(0, 1) → π` ou `-π`); `nil` se o comprimento < 0,01.
  - `Facing.stepYaw(current: number, target: number, maxDelta: number): number` — gira pelo menor ângulo, no máximo `maxDelta`, resultado normalizado em `(-π, π]`.
  - `FacingSim.start(getPlayers: () -> { Player })`: chama `RunService:BindToSimulation(fn)` (60 Hz); a cada passo, para cada jogador devolvido: pega o personagem **atual** e o `HumanoidRootPart` (pula se não houver); lê `Player.Gameplay.Aim:GetState()` (Vector2); alvo = direção da mira se não-nula, senão `Humanoid.MoveDirection` (x, z); se `yawFromDirection` der `nil`, mantém o yaw atual; aplica `stepYaw` com `maxDelta = math.rad(900) * dt` e escreve só a rotação no CFrame do root (posição preservada).
  - Servidor: `SimulationService.Start` → `FacingSim.start(function() return Players:GetPlayers() end)`. Cliente: `SimulationController.Start` → `FacingSim.start(function() return { Players.LocalPlayer } end)` (predição do próprio personagem).
  - `AimController`: em `RenderStepped`, se `UserInputService.PreferredInput == Enum.PreferredInput.KeyboardAndMouse`, faz raycast da posição do mouse até o plano horizontal na altura do root (só o `World`), calcula `(x, z)` do root até o ponto e chama `AimBinding:Fire(Vector2.new(x, z).Unit)`; se o raycast falhar ou o vetor for ~zero, não dispara (mantém o último). Quando `PreferredInput` muda para outro valor, dispara `Vector2.zero` uma vez.

- [ ] **Step 1: Write the failing tests** `tests/facing.spec.luau` (tolerância 1e-6): os quatro casos de `yawFromDirection` acima (para `(0, 1)` aceitar `|yaw| ≈ π`); `yawFromDirection(0, 0) == nil` e `yawFromDirection(0.001, 0.001) == nil`; `stepYaw(0, math.rad(90), math.rad(30)) ≈ math.rad(30)`; `stepYaw(math.rad(170), math.rad(-170), math.rad(30)) ≈ math.rad(-180)` normalizado (gira 20° pelo lado curto, resultado com `|valor| ≈ π`); `stepYaw(0, math.rad(10), math.rad(30)) ≈ math.rad(10)`.
- [ ] **Step 2: Verify fail:** `lune run tests/run` → facing falha.
- [ ] **Step 3:** Implementar `Facing.luau`.
- [ ] **Step 4: Verify pass:** `lune run tests/run` → passa.
- [ ] **Step 5:** Implementar `FacingSim`, `SimulationService`, `SimulationController`, `AimController`.
- [ ] **Step 6: Verify:** `bash scripts/check.sh` passa.
- [ ] **Step 7 (manual, Elizeu):** Play no PC: o personagem gira para o cursor enquanto anda em qualquer direção, sem tremer; com a janela de "Network Simulation" do Studio em ~150 ms de latência, continua suave. Emulador de celular (paisagem): o personagem vira para onde anda. Trocar de emulador para PC no meio do teste: passa a seguir o mouse.
- [ ] **Step 8: Commit** `feat: rotação do personagem na simulação (mouse no PC, movimento no celular)`.

### Task 8: Câmera top-down e UI padrão desligada

**Files:**
- Create: `src/shared/CameraMath.luau`, `tests/cameramath.spec.luau`, `src/client/Controllers/CameraController.luau`, `src/client/Controllers/CoreGuiController.luau`

**Interfaces:**
- Produces:
  - `CameraMath.offset(pitchDeg: number, distance: number): (number, number)` → `(altura, recuo)` = `(distance * sin(pitch), distance * cos(pitch))`; câmera fica em `alvo + (0, altura, recuo)` olhando para o alvo (yaw fixo: "cima" no joystick = −Z do mundo).
  - `CameraMath.smoothAlpha(k: number, dt: number): number` = `1 - exp(-k * dt)`.
  - `CameraController`: `CameraType = Scriptable`; `BindToRenderStep("TopDownCamera", Enum.RenderPriority.Camera.Value + 1, ...)`; pitch 65°, distância inicial 34, zoom limitado a [28, 40] (roda do mouse e pinça), suavização `k = 12`; alvo = `HumanoidRootPart` atual (troca no respawn); sem personagem, mantém a última posição.
  - `CoreGuiController`: desliga `Backpack` e `Health` com `pcall` e até 10 tentativas espaçadas.

- [ ] **Step 1: Write the failing tests** `tests/cameramath.spec.luau`: `offset(90, 10) ≈ (10, 0)`; `offset(0, 10) ≈ (0, 10)`; `offset(65, 34)` ≈ `(30.8145, 14.3690)` (tolerância 1e-3); `smoothAlpha(12, 0) == 0`; `smoothAlpha(12, 1/60) ≈ 0.18127` (1e-4); `smoothAlpha` sempre em [0, 1).
- [ ] **Step 2: Verify fail**, **Step 3:** implementar `CameraMath`, **Step 4: Verify pass** (`lune run tests/run`).
- [ ] **Step 5:** Implementar `CameraController` e `CoreGuiController`.
- [ ] **Step 6: Verify:** `bash scripts/check.sh` passa.
- [ ] **Step 7 (manual, Elizeu):** Play no PC e no emulador de celular: câmera de cima a 65°, segue suave, zoom só dentro do limite; o "para cima" do joystick/WASD anda para o topo da tela; sem mochila nem barra de vida padrão; após resetar o personagem, a câmera segue o novo.
- [ ] **Step 8: Commit** `feat: câmera top-down a 65° com zoom limitado e CoreGui desligada`.

### Task 9: Fechamento da fase (guia, grafo, registro de achados)

**Files:**
- Create: `docs/guia/como-rodar.md`, `docs/guia/arquitetura.md`
- Modify: `docs/research/05-server-authority.md` (achados), `README.md` (link para o guia)

- [ ] **Step 1:** `como-rodar.md`: Rokit, check, `rojo serve`, passos manuais do Studio (AuthorityMode, Avatar Settings, emulador, Network Simulation). `arquitetura.md`: pastas, ciclo Init/Start, Defs/Palette/Theme/Strings, onde fica a simulação e as regras de Server Authority do projeto.
- [ ] **Step 2:** Registrar no doc de Server Authority o que a implementação confirmou ou contradisse (binding scriptable, AutoRotate na simulação, propriedades do Workspace via Rojo, comportamento do thumbstick nativo).
- [ ] **Step 3: Verify:** `bash scripts/check.sh` passa; `& (Get-Content graphify-out\.graphify_python) -m graphify update .` roda sem erro.
- [ ] **Step 4: Commit** `docs: guia de como rodar e da arquitetura, achados de Server Authority`.

**Pausa obrigatória ao fim da Task 8:** se a rotação ou o movimento sob Server Authority não ficarem bons no teste manual (tremor, atraso, binding inexistente), parar e trazer para o Elizeu antes da F2, conforme a seção 5 do spec.
