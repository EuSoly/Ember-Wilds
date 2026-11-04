# Perfil e nível do jogador — plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Nível/XP reais (XP = pontos da vida, com teto por hora), estatísticas reais chegando ao cliente, Perfil rústico com os números reais, placa de nível real no menu e "+N XP" na tela de morte.

**Architecture:** Regras puras novas em `src/shared/Data/LevelRules.luau` (curva, progresso, teto por hora, XP inicial) e `src/shared/UIFlow/ProfileFormat.luau` (texto). O servidor soma XP no fim da vida (`LifeService`), guarda a janela do teto em `data.Xp` e publica cada estatística como atributo `Stat_<id>` no Player (`StatsService`). O cliente só lê atributos e o resumo da vida (`Net.LifeEnded`).

**Tech Stack:** Luau `--!strict`, Vide, Blink (`net/game.blink`), Lune (`lune run tests/run`), `bash scripts/check.sh` (Blink, StyLua, selene, rojo build, luau-lsp, Lune). PATH precisa de `$HOME/.rokit/bin`.

**Spec:** `docs/superpowers/specs/2026-11-04-perfil-nivel-design.md`

## Global Constraints

- Curva: subir do nível n para n+1 pede `1000 × n` XP; XP total para chegar ao nível n = `1000 × n × (n − 1) / 2`. Começa no nível 1 com 0 XP. Sem máximo.
- XP = pontos da vida arredondados para baixo, no fim da vida; teto de **100.000 XP por hora** (janela de 3600 s salva no perfil, como a Golden Ember). O teto não vale para o XP inicial.
- XP inicial de quem já jogou: `xp_total = score_total` uma vez, marcado em `data.Xp.Seeded`; **não** subir `DataConfig.SCHEMA_VERSION`.
- Estatísticas novas: `xp_total`, `days_total`, `real_deaths` (counters). `real_deaths` só em morte de verdade (`DeathService.kill`).
- Atributos `Stat_<id>` no Player; keyed = total somado.
- Perfil: janela rústica no centro **sem escurecer** o menu; ordem: nome, nível, barra de XP ("XP no nível / XP do nível"), XP total; cartões Mortes (`real_deaths`), Dias sobrevividos (`days_total`), Recorde de dias (`days_best`); lista Outros: Jogadores mortos, Criaturas mortas, Recursos coletados, Itens criados, Recorde de pontos numa vida (`score_best`), Tempo de jogo ("12h 30min"; abaixo de 1 h "45min").
- Textos em pt-BR com acentos, em `src/shared/Strings/ptBR.luau`.
- Trabalho no branch `perfil`. Commits em pt-BR terminando com `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Sem push. Depois de mexer em código: `& (Get-Content graphify-out\.graphify_python) -m graphify update .` (PowerShell).

## Review Focus

1. Perfil antigo carregando pela primeira vez: `xp_total` recebe `score_total` uma vez só, mesmo que o jogador entre de novo, e mesmo que `xp_total` já tenha algum valor (fica o maior).
2. Teto por hora atravessando sair e voltar: a janela fica salva no perfil; ganhar 90 mil, sair e voltar no mesmo minuto e ganhar mais 30 mil concede só 10 mil.
3. Pontos fracionados ou absurdos (NaN, infinito, negativos) não viram XP.
4. Atributos ainda não publicados (perfil carregando): Perfil e placa mostram nível 1 e zeros, sem erro.
5. Tela de morte com várias subidas de nível de uma vez: a barra enche e volta do zero a cada nível, e o texto mostra o nível final.

---

### Task 1: Regras do nível (puras)

**Files:**
- Create: `src/shared/Data/LevelRules.luau`
- Modify: `src/shared/Data/DataConfig.luau` (constantes)
- Test: `tests/levelrules.spec.luau`

**Interfaces:**
- Produces:
  - `DataConfig.XP_STEP = 1000`, `DataConfig.MAX_XP_PER_HOUR = 100000` (reusa `HOUR_SECONDS`).
  - `export type XpData = { Seeded: boolean, HourWindowStart: number, HourEarned: number }`
  - `LevelRules.xpToReach(level: number): number`
  - `LevelRules.progress(xp: number): { level: number, into: number, need: number }` — `into` = XP dentro do nível, `need` = XP do nível inteiro (`1000 × level`). XP inválido conta como 0.
  - `LevelRules.earn(data: XpData, points: number, now: number): number` — floor dos pontos, aplica o teto por hora (mesma lógica de `CurrencyRules.earn`), muta `data`, devolve o concedido (≥ 0).
  - `LevelRules.seed(data: XpData, stats: { [string]: any }): boolean` — se `not data.Seeded`: `stats.xp_total = max(stats.xp_total or 0, stats.score_total or 0)`, `Seeded = true`, devolve true; senão false e nada muda.

- [ ] **Step 1: Write the failing tests** (`tests/levelrules.spec.luau`)
  - `xpToReach`: 1→0, 2→1000, 3→3000, 4→6000, 8→28000, 10→45000, 20→190000, 50→1225000.
  - `progress(0)` = `{1, 0, 1000}`; `progress(999)` = `{1, 999, 1000}`; `progress(1000)` = `{2, 0, 2000}`; `progress(30000)` = `{8, 2000, 8000}`; `progress(0/0)` e `progress(-5)` = `{1, 0, 1000}`.
  - `earn`: `earn(fresh, 30000.9, 100)` → 30000 e `HourEarned == 30000`; depois `earn(d, 80000, 200)` → 70000; `earn(d, 5, 300)` → 0; com `now = 100 + 3600` a janela recomeça e `earn(d, 5000, 3700)` → 5000; NaN/infinito/negativo → 0 e nada muda.
  - Cenário do Review Focus 2: ganhar 90000, depois 30000 no mesmo minuto → segundo devolve 10000.
  - `seed`: com `{score_total = 50000}` → `xp_total == 50000`, `Seeded`, devolve true; segunda chamada devolve false e não muda; com `{score_total = 100, xp_total = 900}` fica 900.

- [ ] **Step 2: Run** `lune run tests/run` — Expected: FAIL (`LevelRules` não existe).
- [ ] **Step 3: Implement** `LevelRules` e as constantes. `progress` pode iterar nível a nível (XP realista dá poucas centenas de níveis) ou resolver a equação; o teste decide.
- [ ] **Step 4: Run** `lune run tests/run` — Expected: tudo PASS.
- [ ] **Step 5: Commit** `feat: regras do nível e do XP (curva, teto por hora, XP inicial)`

### Task 2: XP e estatísticas novas no servidor

**Files:**
- Modify: `src/shared/Defs/Stats.luau` (+ `xp_total`, `days_total`, `real_deaths`), `src/shared/Strings/ptBR.luau` (`stat.xp_total` "XP total", `stat.days_total` "Dias sobrevividos", `stat.real_deaths` "Mortes")
- Modify: `src/shared/Data/ProfileTemplate.luau` (+ `Xp = { Seeded = false, HourWindowStart = 0, HourEarned = 0 }`)
- Modify: `src/server/Services/StatsService.luau` (XP inicial no onLoaded, antes de qualquer publicação)
- Modify: `src/server/Services/LifeService.luau` (XP e `days_total` no fim da vida; `LifeSummary.xp`)
- Modify: `src/server/Services/DeathService.luau` (`real_deaths` +1; `LifeEnded` com `Xp` e `XpTotal`)
- Modify: `net/game.blink` (`LifeEnded`: `Xp: u32`, `XpTotal: u32`)
- Test: `tests/defs.spec.luau` já valida stats novas (nameKey precisa existir); `tests/levelrules.spec.luau` cobre as regras.

**Interfaces:**
- Consumes: `LevelRules.earn`, `LevelRules.seed` (Task 1).
- Produces: `LifeSummary = { points: number, days: number, currency: number, xp: number }`; `Net.LifeEnded` com `Xp` (concedido) e `XpTotal` (total depois do ganho); estatísticas `xp_total`, `days_total`, `real_deaths` no perfil.

- [ ] **Step 1: Failing test** em `tests/defs.spec.luau`: `Defs.Stats.xp_total.kind == "counter"`, idem `days_total` e `real_deaths`.
- [ ] **Step 2: Run** `lune run tests/run` — Expected: FAIL nesse teste.
- [ ] **Step 3: Implement**
  - Stats + strings + template.
  - `StatsService` onLoaded: `LevelRules.seed(data.Xp, data.Stats)` (se semeou, avisa `notifyChanged` de `xp_total`).
  - `LifeService.endLife`: `local xp = LevelRules.earn(data.Xp, score, os.time())`; se `xp > 0`, `StatsService.add(player, "xp_total", xp)`; se `days > 0`, `StatsService.add(player, "days_total", days)`; resumo com `xp`.
  - `DeathService.kill`: `StatsService.add(player, "real_deaths", 1)`; `LifeEnded` com `Xp = clampInt(summary.xp, MAX_U32)` e `XpTotal = clampInt(StatsService.get(player, "xp_total"), MAX_U32)`. O resumo vazio (`or {...}`) ganha `xp = 0`.
- [ ] **Step 4: Run** `bash scripts/check.sh` — Expected: exit 0 (Blink regenera `src/*/Net.luau`).
- [ ] **Step 5: Verificar no Studio:** Play; no Server, dar pontos (`Score` 30000.5) e matar o personagem; `LifeEnded` com `Xp = 30000`; `StatsService.get(player, "xp_total")` subiu 30000; `days_total`/`real_deaths` somaram. Perfil de teste sem `Seeded` recebe `score_total` uma vez.
- [ ] **Step 6: Commit** `feat: XP no fim da vida com teto por hora, dias sobrevividos e mortes de verdade`

### Task 3: Estatísticas publicadas para o cliente

**Files:**
- Modify: `src/shared/StatNames.luau` (`StatPrefix = "Stat_"`)
- Modify: `src/shared/Data/StatsRules.luau` (+ `StatsRules.total(stats, def): number`)
- Modify: `src/server/Services/StatsService.luau` (publica no onLoaded e a cada mudança)
- Test: `tests/stats.spec.luau` (casos novos de `StatsRules.total`)

**Interfaces:**
- Produces: atributo `Stat_<id>` (número) no Player para todo `Defs.Stats`; `StatsRules.total` = valor do counter/max, ou a soma das chaves do keyed (0 se vazio/ inválido).

- [ ] **Step 1: Failing test:** `total` de counter 5 → 5; max 12 → 12; keyed `{wolf=3, bear=2}` → 5; keyed ausente → 0; chave com valor não numérico é ignorada.
- [ ] **Step 2: Run** — Expected: FAIL (`total` nil).
- [ ] **Step 3: Implement** `total` e a publicação (`player:SetAttribute(StatNames.StatPrefix .. id, StatsRules.total(...))` para todas no onLoaded, depois do seed; e no listener de mudança, recalculando o total da estatística que mudou).
- [ ] **Step 4: Run** `bash scripts/check.sh` — Expected: exit 0.
- [ ] **Step 5: Verificar no Studio:** no Client, `Players.LocalPlayer:GetAttribute("Stat_xp_total")` e `Stat_resources_gathered` aparecem e mudam ao coletar/morrer.
- [ ] **Step 6: Commit** `feat: estatísticas do perfil publicadas como atributos Stat_`

### Task 4: Placa de nível real no menu

**Files:**
- Modify: `src/client/Menu/MenuShell.luau` (`levelPod`)

**Interfaces:**
- Consumes: `LevelRules.progress`, atributo `Stat_xp_total`.

- [ ] **Step 1:** `levelPod` lê `Sources.attribute(Players.LocalPlayer, StatNames.StatPrefix .. "xp_total", 0)` e usa `LevelRules.progress` para o número do selo, o texto `menu.level`, a largura da barra (`into / need`) e o texto `menu.xp` (`{xp = into, max = need}`, com separador de milhar). Remove o `MockupBadge` e o "(falsos, selo MOCKUP)" do comentário do topo.
- [ ] **Step 2: Run** `bash scripts/check.sh` — Expected: exit 0.
- [ ] **Step 3: Verificar no Studio:** placa mostra o nível real; muda depois de morrer com pontos.
- [ ] **Step 4: Commit** `feat: placa de nível do menu com o nível e o XP reais`

### Task 5: Perfil rústico com os números reais

**Files:**
- Create: `src/shared/UIFlow/ProfileFormat.luau`
- Test: `tests/profileformat.spec.luau`
- Rewrite: `src/client/Menu/ProfilePanel.luau` (janela)
- Modify: `src/client/Menu/MenuShell.luau` (o "profile" sai de `PANELS`/`CONTENT`; a janela é filha do MenuShell, visível quando `MenuState.panel() == "profile"`)
- Modify: `src/shared/UIFlow/MockStore.luau` (sai `PROFILE` e o tipo `Stat` se ficar sem uso), `tests/mockstore.spec.luau`, `src/shared/Strings/ptBR.luau` (saem `mock.stat.*`; entram `profile.title` "Perfil", `profile.total_xp` "XP total: {xp}", `profile.others` "Outros"; renomear os textos para bater com o design: `stat.players_killed` "Jogadores mortos", `stat.mobs_killed` "Criaturas mortas", `stat.score_best` "Recorde de pontos numa vida", `stat.days_best` "Recorde de dias", `stat.deaths` "Vidas terminadas" — o "Mortes" passa a ser `stat.real_deaths`)

**Interfaces:**
- Produces: `ProfileFormat.thousands(n: number): string` ("18.300"; floor; inválido → "0"); `ProfileFormat.playtime(seconds: number): string` ("12h 30min", "1h 0min", "45min", "0min"; inválido → "0min"). `ProfilePanel.build(): Instance` (a janela).

- [ ] **Step 1: Failing tests:** `thousands(0)`, `(999)`, `(1000)` "1.000", `(18300.7)` "18.300", `(1234567)` "1.234.567", `(0/0)` "0"; `playtime(45*60)` "45min", `(3600)` "1h 0min", `(45000)` "12h 30min", `(59)` "0min", `(-3)` "0min".
- [ ] **Step 2: Run** — Expected: FAIL.
- [ ] **Step 3: Implement** `ProfileFormat`.
- [ ] **Step 4: Run** — Expected: PASS.
- [ ] **Step 5: Janela** no visual das Configurações (`SettingsScreen.luau`: corpo `#2B2018`, borda `woodShadow` 4, placa `Rustic.plate` com o título, `Rustic.button` ember "Fechar" que faz `MenuState.open("play")`), **sem fundo escuro**, no centro, `UISizeConstraint` máx. ~560×600, parte de baixo num `ScrollingFrame`. Conteúdo e ordem como em Global Constraints; números de `Sources.attribute(LocalPlayer, "Stat_<id>", 0)` com `ProfileFormat`; nível/barra com `LevelRules.progress`.
- [ ] **Step 6: Run** `bash scripts/check.sh` — Expected: exit 0.
- [ ] **Step 7: Verificar no Studio:** PC e celular (`Setting_ui_scale` = 2 no Server): ordem certa, rola no celular com o Fechar à vista, números batem com os atributos, menu visível atrás.
- [ ] **Step 8: Commit** `feat: Perfil rústico com nível, XP e estatísticas reais`

### Task 6: XP na tela de morte

**Files:**
- Modify: `assets/ui/Death.model.json` (novos: `XpLabel` TextLabel, `XpBar` Frame com filho `XpFill` Frame, `LevelUpLabel` TextLabel; abaixo de Points/Currency; descer `KitsTitle`, `KitPointsLabel`, `KitList` para caber)
- Modify: `src/client/Screens/DeathScreen.luau`, `src/shared/Strings/ptBR.luau` (`death.xp` "+{xp} XP", `death.levelup` "Subiu para o nível {level}!")
- Modify: `docs/guia/telas.md` (nomes combinados do molde Death)

**Interfaces:**
- Consumes: `LifeEnded.Xp`, `LifeEnded.XpTotal` (Task 2), `LevelRules.progress`.

- [ ] **Step 1:** No mesmo tempo da contagem (2 s), o XP mostrado vai de `XpTotal − Xp` até `XpTotal`; a cada quadro `XpFill` = `progress(x).into / need` (passa de nível → recomeça do zero sozinho). `XpLabel` = `death.xp`. `LevelUpLabel` visível só se `progress(XpTotal).level > progress(XpTotal − Xp).level`, com o nível final. `Xp == 0`: barra parada, sem "Subiu".
- [ ] **Step 2: Run** `bash scripts/check.sh` — Expected: exit 0.
- [ ] **Step 3: Verificar no Studio:** morrer com 30000 pontos num perfil em 0 XP → "+30.000 XP", barra enche várias vezes, "Subiu para o nível 8!".
- [ ] **Step 4: Commit** `feat: tela de morte mostra o XP ganho e a subida de nível`

### Task 7: Documentação

**Files:**
- Modify: `docs/guia/telas.md` (Perfil, placa de nível, tela de morte), `docs/guia/dados.md` (XP, `data.Xp`, estatísticas novas, atributos `Stat_`, teto por hora)

- [ ] **Step 1:** Atualizar os guias; rodar `bash scripts/check.sh` (exit 0) e o `graphify update`.
- [ ] **Step 2: Commit** `docs: guia do Perfil, do nível e do XP`
