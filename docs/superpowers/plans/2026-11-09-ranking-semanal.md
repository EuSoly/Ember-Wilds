# Ranking semanal (UI 6) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Trocar o mockup do Ranking do menu por um ranking semanal global de verdade, com 5 abas, pódio, lista e a linha do jogador, na arte do Elizeu.

**Architecture:** Regras puras (semana, valores da semana, contagem) em `shared/Data` testadas no Lune; o valor da semana de cada jogador fica no perfil (ProfileStore) e é copiado para um DataStore ordenado por categoria e semana pelo `RankService`; o cliente pede o top por um evento Blink e monta a tela com Vide (`client/Menu/Ranking/`), posicionando o pódio por frações da imagem.

**Tech Stack:** Luau `--!strict`, Rojo, Vide, Blink, ProfileStore, `DataStoreService:GetOrderedDataStore`, Lune (testes), Python + Pillow (recorte dos assets).

**Spec:** `docs/superpowers/specs/2026-11-09-ranking-semanal-design.md`

## Global Constraints

- Semana termina **domingo 23:59 de Brasília (UTC−3, sem horário de verão)**; começa segunda 00:00.
- Categorias e ordem das abas: `points` (melhor vida), `xp` (soma), `days` (melhor vida), `players` (soma), `creatures` (soma).
- Lista até o **50º**; leitura do top **100**; fora do top 100 a posição mostra **"100+"**; sem valor na semana: **"—"** e 0.
- No Studio, stores com prefixo `Dev_` (como `DataConfig.DEV_STORE_PREFIX`).
- Servidor VIP (`game.PrivateServerOwnerId ~= 0`) **não grava** no placar.
- Limite de abates do mesmo alvo por dia: existe e vem **desligado (0)**.
- Comando de moderação de dev para tirar um jogador do placar de uma semana.
- Textos em pt-BR em `Strings/ptBR.luau`; números/tamanhos em módulo de config, nunca soltos no código.
- Alinhado em qualquer resolução: pódio por frações da imagem com `UIAspectRatioConstraint`; 9 partes nas faixas/quadro; alvos ≥ 44 px.
- Envio de imagens ao Roblox só com a confirmação do Elizeu no chat.
- `bash scripts/check.sh` verde ao fim de cada tarefa; commit em pt-BR com a linha `Co-Authored-By`.

## Review Focus

- Virada da semana com o jogador online (vida que termina depois de segunda 00:00 entra na semana nova; valores da semana anterior não somam na nova) — teste em Task 1.
- Perfil antigo sem o campo `Ranking` (Reconcile) e perfil com `Ranking.Week` de semanas atrás — teste em Task 1 (`RankRules.current`).
- DataStore falhando ou devolvendo jogador que saiu do Roblox (nome não encontrado) — tela mostra "Ranking indisponível agora" / usa "@id"; Task 3 trata e Task 6 verifica no Studio.
- Cliente pedindo ranking em rajada (troca de aba rápida) — limite por jogador no servidor (Task 3) e o cliente descarta resposta de aba que já não é a atual (Task 5).
- Tela compacta (celular deitado, 1280×720 com escala 1,25) sem sobreposição entre pódio, lista e linha "você" — Task 6.

---

### Task 1: Regras da semana (puras)

**Files:**
- Create: `src/shared/Data/RankConfig.luau`, `src/shared/Data/RankRules.luau`
- Test: `tests/rankrules.spec.luau`

**Interfaces:**
- Produces:
  - `RankConfig` (frozen): `CATEGORIES = { "points", "xp", "days", "players", "creatures" }`, `KIND = { points = "max", xp = "sum", days = "max", players = "sum", creatures = "sum" }`, `UTC_OFFSET = -3 * 3600`, `FIRST_MONDAY = 345600` (1970‑01‑05 00:00 UTC), `WEEK_SECONDS = 604800`, `LIST_SIZE = 50`, `READ_SIZE = 100`, `CACHE_SECONDS = 180`, `WRITE_MIN_INTERVAL = 60`, `SAME_VICTIM_DAILY_LIMIT = 0`, `STORE_PREFIX = "Rank_"`, `REQUEST_MIN_INTERVAL = 0.5`.
  - `export type WeekState = { Week: number, points: number, xp: number, days: number, players: number, creatures: number, Victims: { [string]: number }, VictimsDay: number }`
  - `RankRules.weekIndex(unixTime: number): number` = `floor((t + UTC_OFFSET - FIRST_MONDAY) / WEEK_SECONDS)`
  - `RankRules.weekEnd(week: number): number` = último segundo da semana (domingo 23:59:59 de Brasília, unix)
  - `RankRules.dayIndex(unixTime: number): number` (dia local de Brasília, para o limite de abates)
  - `RankRules.empty(week: number): WeekState`
  - `RankRules.current(state: any, week: number): WeekState` — devolve `state` se for da semana `week` e bem formado; senão um `empty(week)` novo (perfil antigo, semana velha, lixo).
  - `RankRules.applyLife(state: WeekState, life: { points: number, days: number, xp: number }): { string }` — max para points/days, soma para xp; devolve as categorias que mudaram.
  - `RankRules.applyKill(state: WeekState, category: "players" | "creatures", victimKey: string?, day: number, limit: number): boolean` — soma 1; com `limit > 0` e `victimKey`, conta no máximo `limit` por vítima por `day` (zera `Victims` quando `day ~= VictimsDay`); devolve se contou.
  - `RankRules.countdown(seconds: number): (string, { [string]: number })` — chave de texto e números: `"rank.ends.days"` `{d,h}` (≥ 1 dia), `"rank.ends.hours"` `{h,m}` (≥ 1 h), `"rank.ends.minutes"` `{m}` (≥ 1 min), `"rank.ends.soon"` `{}` (< 1 min).

- [ ] **Step 1: Write the failing tests** (`tests/rankrules.spec.luau`)
  - `weekIndex(1794193199) == 2965` (dom 08/11 23:59:59 BRT), `weekIndex(1794193200) == 2966` (seg 09/11 00:00), `weekIndex(1794797999) == 2966`, `weekIndex(1794798000) == 2967`; `weekEnd(2966) == 1794797999`.
  - `current(nil, 2966)` e `current({ Week = 2965, points = 9 }, 2966)` dão `empty(2966)`; `current(empty(2966) com points = 5, 2966).points == 5`.
  - `applyLife`: pontos 100 depois 40 ⇒ `points == 100`, devolve `{"points","xp","days"}` só para as que mudaram; xp 30 + 20 ⇒ 50; days max.
  - `applyKill`: limite 0 conta sempre; limite 3, mesma vítima 4× no mesmo dia ⇒ só 3 contam; dia seguinte volta a contar; `creatures` ignora a vítima.
  - `countdown(3*86400 + 5*3600 + 10)` ⇒ `"rank.ends.days"`, `{d=3,h=5}`; `countdown(2*3600+7*60)` ⇒ `"rank.ends.hours"`, `{h=2,m=7}`; `countdown(125)` ⇒ `"rank.ends.minutes"`, `{m=2}`; `countdown(59)` ⇒ `"rank.ends.soon"`.
- [ ] **Step 2:** `bash scripts/check.sh` → FAIL (módulos não existem).
- [ ] **Step 3:** Implementar `RankConfig` e `RankRules` com as assinaturas acima.
- [ ] **Step 4:** `bash scripts/check.sh` → PASS.
- [ ] **Step 5:** Commit `feat: regras da semana do ranking`.

### Task 2: Contagem no perfil e nas fontes (fim de vida, abates)

**Files:**
- Modify: `src/shared/Data/ProfileTemplate.luau` (campo `Ranking = RankRules.empty(0)` — o `current` troca na primeira leitura), `src/server/Services/LifeService.luau` (fim da vida), `src/server/Services/DeathService.luau` (abate de jogador: também `StatsService.add(validKiller, "players_killed", 1)` — a estatística do Perfil hoje nunca é somada), `src/server/Services/MobService.luau:561` (abate de mob)
- Create: `src/server/Services/RankService.luau` (só a parte de contagem nesta tarefa)
- Test: `tests/rankrules.spec.luau` (caso novo do template).

**Interfaces:**
- Consumes: Task 1.
- Produces (`RankService`):
  - `RankService.addLife(player: Player, life: { points: number, days: number, xp: number })`
  - `RankService.addKill(killer: Player, category: "players" | "creatures", victimKey: string?)` — `victimKey = tostring(victim.UserId)` para jogador, `nil` para mob.
  - Internos usados pela Task 3: `state(player): WeekState?` (via `DataService.data(player).Ranking` + `RankRules.current`, regravando no perfil) e um conjunto de categorias "sujas" por jogador.
- Bonecos de teste (sem `Player`) nunca chegam aqui (só `Player` é aceito).

- [ ] **Step 1:** Teste: `ProfileTemplate.build(Defs).Ranking` existe com as 5 categorias em 0.
- [ ] **Step 2:** check → FAIL.
- [ ] **Step 3:** Implementar o campo no template, `RankService.addLife/addKill` (marca suja; sem DataStore ainda) e as chamadas em `LifeService.endLife` (com `score`, `days`, `xp` da vida), `DeathService.kill` (com `validKiller`, logo depois do bônus) e `MobService` (onde já soma `mobs_killed`).
- [ ] **Step 4:** check → PASS. No Studio (Play): morrer com pontos, matar um mob; `ServerStorage.DevProfile:Invoke(player)` mostra `Ranking` com os valores da semana 2966+ e `players_killed` sobe ao matar outro jogador (teste com 2 jogadores no Studio, se der; senão anotar em pendências).
- [ ] **Step 5:** Commit `feat: valores da semana do ranking no perfil e contagem de abates de jogador`.

### Task 3: Placar no DataStore, leitura e rede

**Files:**
- Modify: `src/server/Services/RankService.luau`, `net/game.blink` (2 eventos), `src/server/Services/DevDataService.luau` (comando de moderação)
- Generated: `blink net/game` (o check já roda)

**Interfaces:**
- Consumes: Tasks 1–2.
- Produces (rede, em `net/game.blink`):
  - `event RequestRanking { From: Client, Type: Reliable, Call: SingleAsync, Data: u8(1..5) }` (índice em `RankConfig.CATEGORIES`)
  - `event RankingData { From: Server, Type: Reliable, Call: SingleAsync, Data: struct { Category: u8, Ok: boolean, EndsAt: f64, Entries: struct { UserId: f64, Name: string(0..40), Value: u32 }[], MyValue: u32, MyPosition: u16 } }` — `MyPosition` 0 = fora do top 100; `Entries` até 50.
  - `ServerStorage.DevRankRemove:Invoke(userId: number, week: number?) -> string` (semana atual se nil): `RemoveAsync` nas 5 stores da semana e zera o perfil se o jogador estiver online.
- Store: `DataStoreService:GetOrderedDataStore(prefix .. STORE_PREFIX .. category, "W" .. week)`, chave `tostring(UserId)`, valor inteiro ≥ 0; `prefix = DataConfig.DEV_STORE_PREFIX` só no Studio.

- [ ] **Step 1:** Gravação: loop a cada `WRITE_MIN_INTERVAL` grava as categorias sujas de cada jogador (`SetAsync` em `pcall`; falha mantém suja); grava na hora ao fim da vida e ao sair (`PlayerRemoving`/`BindToClose`). Não grava se `game.PrivateServerOwnerId ~= 0`.
- [ ] **Step 2:** Leitura: `top(category)` com cache de `CACHE_SECONDS` por categoria; `GetSortedAsync(false, READ_SIZE)`; nomes por `UserService:GetUserInfosByUserIdsAsync` (DisplayName; falha = `"@" .. id`), também em cache. Posição do jogador = índice no top 100 lido; o valor dele vem do próprio perfil (sempre atual).
- [ ] **Step 3:** `RequestRanking` com limite de `REQUEST_MIN_INTERVAL` por jogador (pedido dentro do intervalo é ignorado); responde `RankingData` (`Ok = false` se a leitura falhou; `EndsAt = RankRules.weekEnd(semana atual)`).
- [ ] **Step 4:** `DevRankRemove` no `DevDataService` (só Studio, como os outros).
- [ ] **Step 5:** check → PASS. Studio (Play, API de DataStore ligada): matar mobs e esperar o flush; no Client, ouvir `Net.RankingData.On` e disparar `Net.RequestRanking.Fire(5)` — o jogador aparece em 1º em "creatures"; depois `ServerStorage.DevRankRemove:Invoke(userId)` no Server e, passado o cache (ou com o cache zerado no Studio), ele some.
- [ ] **Step 6:** Commit `feat: placar semanal no DataStore ordenado, leitura com cache e comando de moderação`.

### Task 4: Assets do ranking

**Files:**
- Create: `assets/ui/ranking/prepare_ranking.py`, `assets/ui/ranking/*.png` (saídas), `src/shared/RankingImages.luau`

**Interfaces:**
- Produces `RankingImages` (frozen, mesmo jeito de `ShopImages`; id `""` = reserva por código): `FRAME`, `TROPHY`, `MEDAL = {[1],[2],[3]}`, `ROW_LIGHT`, `ROW_DARK`, `ROW_ME`, `PODIUM`, `AVATAR_RING`, `ARROW`, `TAB = { points, xp, days, players, creatures }`; tamanhos e `Rect` de 9 partes de `FRAME`, `ROW_*`; `PODIUM_SIZE` e `PODIUM_SPOTS = { [1|2|3] = { x: number, top: number, plaqueY: number } }` em frações da imagem (x = centro do degrau, top = altura do tampo, plaqueY = centro da plaquinha, medidas a partir da esquerda/de cima). `has(id): boolean`.

- [ ] **Step 1:** Script Python (Pillow; roda fora do repo sobre `C:/Users/Elize/Downloads/UI Assets/UI dos rankings`, sem `-I` porque precisa do Pillow do usuário) recorta pela transparência (peças separadas por linhas/colunas vazias), limpa respingos fora do maior bloco (faixa vermelha), reduz para ≤ 1024 px e salva em `assets/ui/ranking/` com nomes `frame.png, trophy.png, medal_1..3.png, row_light.png, row_dark.png, row_me.png, podium.png, avatar_ring.png, arrow.png, tab_points|xp|days|players|creatures.png`; imprime as medidas do pódio (tampo e plaquinhas por coluna) para preencher `PODIUM_SPOTS`.
- [ ] **Step 2:** Pedir ao Elizeu a confirmação para enviar as 15 imagens à conta dele; enviar (MCP do Studio `upload_image` ou Asset Manager) e preencher os ids.
- [ ] **Step 3:** check → PASS.
- [ ] **Step 4:** Commit `feat: artes do ranking (fontes recortadas e ids)`.

### Task 5: Tela do Ranking

**Files:**
- Create: `src/shared/UIFlow/RankingLayout.luau` (puro), `src/client/Menu/Ranking/RankingScreen.luau`, `src/client/Menu/Ranking/RankingPodium.luau`, `src/client/Menu/Ranking/RankingList.luau`, `src/client/Menu/Ranking/RankingState.luau`
- Modify: `src/client/Menu/MenuShell.luau` (sai o painel de mockup `ranking` de `PANELS`/`CONTENT`; entra `RankingScreen.build()` como o `ProfilePanel`), `src/shared/Strings/ptBR.luau` (textos `rank.*`; saem `mock.rank.*`), `src/shared/UIFlow/MockStore.luau` (sai `RANKING` e o tipo `RankRow`)
- Delete: `src/client/Menu/RankingPanel.luau`
- Test: `tests/rankinglayout.spec.luau`

**Interfaces:**
- Consumes: `RankingImages` (Task 4), eventos da Task 3, `RankRules.countdown`.
- Produces:
  - `RankingLayout.compute(width: number, height: number, scale: number): { compact: boolean, stacked: boolean, podiumWidth: number, listWidth: number, rowHeight: number, tabHeight: number }` — `compact` = largura < 900 ou altura < 500 (design system); `stacked` quando pódio + lista não cabem lado a lado; `rowHeight * scale ≥ 44` e `tabHeight * scale ≥ 44`.
  - `RankingLayout.spot(spot, podiumW, podiumH): (Vector2, Vector2)` — centro do avatar (em cima do tampo) e centro da plaquinha, em pixels do quadro do pódio, a partir das frações de `RankingImages.PODIUM_SPOTS`.
  - `RankingState`: `category: vide.Source<number>`, `data: vide.Source<RankingData?>`, `status: vide.Source<"loading"|"ok"|"error">`; `request(category)` dispara `RequestRanking` ao abrir e ao trocar de aba; resposta de outra categoria é descartada.

- [ ] **Step 1:** Testes de `RankingLayout`: 1920×1080 escala 1 ⇒ lado a lado, não compacto; 1280×720 escala 1,25 ⇒ alvos ≥ 44; 844×390 (celular deitado) ⇒ compacto; `spot` em 410×231 bate com as frações (ex. 1º: x ≈ 0,512·410).
- [ ] **Step 2:** check → FAIL.
- [ ] **Step 3:** Implementar `RankingLayout`, os 4 módulos de tela e a troca no `MenuShell`, conforme a seção "A tela" do spec: quadro (9 partes), taça + "RANKING SEMANAL", pílula "termina em…", abas (ícone + nome; selecionada laranja e levantada), pódio (avatar `rbxthumb://type=AvatarHeadShot&id=<id>&w=150&h=150` na moldura, medalha no canto, nome e valor acima do avatar, "1º/2º/3º" nas plaquinhas), lista 4º–50º com faixas alternadas, linha "você" fixa na faixa vermelha com a seta, estados vazio/carregando/erro. Sem imagem (`id == ""`): desenho de reserva com as cores do `Theme.rustic`.
- [ ] **Step 4:** check → PASS.
- [ ] **Step 5:** Commit `feat: tela do ranking semanal`.

### Task 6: Verificação no Studio, docs e pendências

**Files:**
- Create: `docs/guia/ranking.md` (como funciona, onde mudar números, comando de moderação, como testar)
- Modify: `docs/guia/telas.md` (Ranking deixa de ser mockup), `docs/pendencias.md` (o que sobrar)

- [ ] **Step 1:** Studio, Play: abrir o Ranking em 1920×1080, 1280×720 e no emulador de celular deitado; conferir pódio alinhado (avatares nos tampos, números nas plaquinhas), abas trocando, linha "você", "termina em…" correto, estados vazio/erro (desligar a API de DataStore ou forçar falha). Prints de cada resolução para o Elizeu.
- [ ] **Step 2:** Escrever os docs e atualizar o grafo (`graphify update .`).
- [ ] **Step 3:** check → PASS; commit `docs: guia do ranking semanal`.
