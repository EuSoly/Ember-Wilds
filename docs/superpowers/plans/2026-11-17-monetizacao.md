# Monetização (VIP, gamepasses, revive, check-in, bônus) — Plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deixar funcionando, ainda sem cobrar Robux, o VIP por assinatura, as gamepasses 2× Golden Ember e Nascer com livro, os bônus do Premium, a Golden Ember sem teto com multiplicador, o revive pago, o check-in de 7 dias, o boost de XP e a regra de item aleatório pago, com as telas de cada um.

**Architecture:** As regras ficam em módulos puros em `src/shared` (testados no Lune) e os serviços em `src/server/Services` só aplicam. Um módulo único (`Shop/Perks`) responde "quem tem o quê", lendo o perfil e o Premium. Na fase seguinte, ele passa a ler também a assinatura e as gamepasses do Roblox, sem mexer em regra de jogo. O revive se encaixa na morte por um gancho do `DeathService`. A caixa trancada guarda os itens para o assassino, e uma cópia exata do inventário fica com o `ReviveService` para devolver.

**Tech Stack:** Luau `--!strict`, Rojo, Blink (`net/game.blink`), Vide (UI), ProfileStore (`Reconcile` acrescenta campos novos do template sem migração), Lune (testes), MCP do Roblox Studio (teste no Play).

**Spec:** `docs/superpowers/specs/2026-11-17-monetizacao-design.md` · Artes: `docs/game-design/assets-ui-monetizacao.md`

## Global Constraints

- Server Authority: o cliente só **pede**. Preço, posse, revive, check-in e multiplicador são decididos no servidor.
- Conteúdo é dado: preços, prêmios, degraus e bônus ficam em `src/shared/Shop/ShopConfig.luau`, nunca no código das telas.
- Robux continua **grátis**: `ShopService.charge` devolve `true` para `currency == "robux"`. Nada nesta branch chama `MarketplaceService` para cobrar.
- Golden Ember: `floor(pontos / 1000 × multiplicador)`, **sem teto** por vida nem por hora. Multiplicador = `1 + 1 (2×) + 0,5 (VIP) + 0,2 (Premium)`, somado, máximo 2,7. Só no fim de vida; prêmios fixos não multiplicam.
- VIP: 99 Robux por 30 dias (`Shop.VipUntil`). Benefícios: +3 espaços, ícone no nome, +50% GE, Kit VIP e 1 revive grátis por vida. São lidos **ao nascer** e valem até o fim daquela vida.
- Gamepasses novas: `ember2x` = 199 e `book` = 99. O passe `vip` antigo sai de `ShopConfig.PASSES`.
- Premium (`Enum.MembershipType.Premium`): +20% GE e `kit_starter` liberado enquanto for Premium. Não grava no perfil.
- Revive: degraus 25 / 49 / 99 / 199 (para no 199), contados da entrada pelo menu até a morte final. O grátis do VIP ocupa o 1º degrau. Limite escondido de 30 s, pausado durante uma compra pendente (até 60 s). Volta no totem do time ou em ponto aleatório da floresta, com 3 s de proteção.
- Check-in: 100 GE / 1 giro normal / 150 GE / Kit Explorador 1 vida / 200 GE / 2 giros normais / 5 giros especiais. Um por dia de Brasília (`RankRules.dayIndex`), sem precisar ser seguido. Depois do 7, volta ao 1.
- Boost de XP: 49 Robux, +1 h a cada compra. Dobra o XP na proporção da vida com boost. O ranking soma o XP **sem** boost.
- Kit VIP (`kit_vip`): 20 `berry`, 120 `wood`, 80 `stone`, 1 `stone_pickaxe`, 1 `big_campfire`, 8 `wood_wall`.
- Item aleatório pago: chances visíveis antes da compra. Onde `ArePaidRandomItemsRestricted`, ou se o `PolicyService` falhar, fica proibido comprar giros (normal e especial) e os pacotes com giros não aparecem. Giros ganhos de graça continuam valendo.
- Textos em `src/shared/Strings/ptBR.luau`. Artes por `src/shared/MonetizationImages.luau`; id vazio = desenho por código.
- Não acrescentar botão na coluna do menu (6 botões cabem no celular).
- Cada tarefa termina com `bash scripts/check.sh` verde e um commit em pt-BR terminando com `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Depois de mexer em código: `graphify update .`.
- Rojo duplica arquivo novo no place: depois de criar arquivos, conferir e apagar as cópias antes de testar no Studio.

## Review Focus

1. **Jogador sai do jogo com o revive pendente:** vira morte final. A caixa destranca, as construções somem e nenhum item é duplicado (nada volta para o inventário). → teste em Task 7 (`ReviveRules` "leaving resolves as decline") e roteiro no Studio da Task 8.
2. **REVIVER clicado duas vezes ou REVIVER + Não, obrigado ao mesmo tempo:** um só desfecho, uma só cobrança, os itens voltam uma vez. → teste em Task 7 ("second answer is ignored").
3. **Cópia do inventário com mais slots que a capacidade de agora** (mochila vestida, VIP): o restore recria a capacidade antes de pôr os itens, e nada se perde. → teste em Task 6 (`InventorySnapshot` "restore keeps slots beyond base capacity").
4. **Check-in pedido duas vezes no mesmo dia, ou logo depois da meia-noite de Brasília:** o segundo pedido do mesmo dia é recusado, e o dia seguinte libera. → testes em Task 9.
5. **Multiplicador com pontos enormes ou estranhos** (NaN, negativos, 10⁹): nunca entra NaN nem negativo no saldo, e o `LifeEnded.Currency` (agora `u32`) não estoura. → testes em Task 1.

---

### Task 1: Golden Ember sem teto, com multiplicador

**Files:**
- Modify: `src/shared/Data/CurrencyRules.luau`, `src/shared/Data/DataConfig.luau` (remover `MAX_CURRENCY_PER_LIFE` e `MAX_CURRENCY_PER_HOUR`), `src/server/Services/CurrencyService.luau`, `src/server/Services/LifeService.luau:95`, `net/game.blink:166` (`Currency: u16` → `u32`), `src/server/Services/DeathService.luau` (clamp do Currency para `MAX_U32`)
- Test: `tests/currency.spec.luau`

**Interfaces:**
- Produces: `CurrencyRules.pointsToCurrency(points: number, multiplier: number): number` (sem teto; multiplicador inválido ou < 1 conta como 1). `CurrencyRules.earn(data, amount, now)` deixa de ter teto (soma tudo; os campos `HourWindowStart`/`HourEarned` ficam no tipo, sem uso). `CurrencyService.earnFromGameplay(player, amount, reason): number` mantém a assinatura.

- [ ] **Step 1: Testes que falham** em `tests/currency.spec.luau` (troque os que esperam teto):
  - `"points convert without per-life cap"`: `pointsToCurrency(9_000_000, 1) == 9000`.
  - `"multiplier is applied before flooring"`: `pointsToCurrency(1500, 2.7) == 4` (1,5 × 2,7 = 4,05) e `pointsToCurrency(999, 2.7) == 2`.
  - `"bad multiplier counts as 1"`: `pointsToCurrency(5000, 0/0) == 5`, `pointsToCurrency(5000, -3) == 5`.
  - `"bad points give zero"`: `pointsToCurrency(0/0, 2) == 0`, `pointsToCurrency(-10, 2) == 0`.
  - `"earn has no hourly cap"`: dois `earn(d, 10_000, t)` no mesmo `t` deixam `d.Balance == 20_000`.
- [ ] **Step 2:** `lune run tests/run` → os novos falham.
- [ ] **Step 3:** Implementar. Em `LifeService.endLife`, passar o multiplicador da vida: por enquanto `1`. A Task 3 troca para `PerkService.emberMultiplier(player)`.
- [ ] **Step 4:** `bash scripts/check.sh` verde (o Blink regenera com `u32`).
- [ ] **Step 5:** Commit `feat(moeda): Golden Ember sem teto e com multiplicador`.

### Task 2: Dados da loja, catálogo e `Shop/Perks`

**Files:**
- Modify: `src/shared/Shop/ShopData.luau`, `src/shared/Shop/ShopConfig.luau`, `src/shared/Shop/Types.luau`, `src/shared/Shop/Rewards.luau`, `src/shared/Shop/Products.luau`, `src/shared/Defs/Kits.luau`, `src/shared/Defs/Types.luau` (campo `vipOnly: boolean?` no KitDef), `src/shared/UIFlow/KitRules.luau`, `src/shared/Strings/ptBR.luau`
- Create: `src/shared/Shop/Perks.luau`, `src/shared/MonetizationImages.luau` (ids vazios + `has(id)`, no molde de `ShopImages`)
- Test: `tests/shopdata.spec.luau`, `tests/shopcatalog.spec.luau`, `tests/perks.spec.luau` (novo), `tests/kits.spec.luau`

**Interfaces:**
- Produces, em `ShopData.ShopData` (novos campos, todos no `empty()`):
  `VipUntil: number` (unix, 0 = nunca), `BoostStart: number`, `BoostUntil: number`, `ReviveCredits: number`, `CheckIn: { Day: number, LastDay: number }` (Day = próximo prêmio 1..7; LastDay = `dayIndex` do último resgate, 0 = nunca).
  `ShopData.addVipDays(d, days: number, now: number)` (soma a partir de `max(now, VipUntil)`) e `ShopData.addBoost(d, seconds: number, now: number)` (se `BoostUntil <= now`, então `BoostStart = now`; `BoostUntil = max(now, BoostUntil) + seconds`).
- `ShopConfig`: `PASSES = { ember2x = {nameKey, descKey, robux = 199}, book = {…, robux = 99} }`; `VIP = { robux = 99, days = 30 }`; `PERK_BONUS = { ember2x = 1, vip = 0.5, premium = 0.2 }`; `REVIVE_ROBUX = { 25, 49, 99, 199 }`; `XP_BOOST = { robux = 49, seconds = 3600 }`; `CHECKIN = { {kind="ember",amount=100}, {kind="spins",spin="normal",count=1}, {kind="ember",amount=150}, {kind="kitOnce",id="kit_explorer",count=1}, {kind="ember",amount=200}, {kind="spins",spin="normal",count=2}, {kind="spins",spin="paid",count=5} }`.
- Recompensas novas em `Rewards.KINDS`: `vip` (`count` = dias ≥ 1), `xpBoost` (`count` = segundos ≥ 1) e `reviveCredit` (`count` ≥ 1).
- Produtos novos em `Products`: `vip_30d` (kind `"vip"`, `once = false`, reward `{kind="vip", count=30}`), `xpboost_1h` (kind `"boost"`, reward `{kind="xpBoost", count=3600}`) e `revive_1`..`revive_4` (kind `"revive"`, `hidden = true`, rewards `{}`; só o `ReviveService` usa, e a loja não lista nem vende pelo `RequestPurchase`). Campo novo `hidden: boolean?` no `Product`. `ProductKind` ganha `"vip" | "boost" | "revive"`.
- `Perks` (puro):
  ```lua
  export type PerkSet = { vip: boolean, ember2x: boolean, book: boolean, premium: boolean }
  Perks.resolve(d: ShopData, isPremium: boolean, now: number): PerkSet -- vip = VipUntil > now; ember2x/book = Passes
  Perks.emberMultiplier(set: PerkSet): number
  Perks.unlockedKits(set: PerkSet, kits: { [string]: KitDef }): { [string]: boolean } -- premium → kit_starter; vip → todo kit com vipOnly
  ```
- `Defs.Kits.kit_vip`: `vipOnly = true`, `exclusive = true` (fora da venda), `price = 0`, `order = 7`, com os itens das Global Constraints.

- [ ] **Step 1: Testes que falham:**
  - `perks.spec`: `"multiplier sums bonuses"`: todos ligados → `2.7`; nenhum → `1`; só VIP → `1.5`. `"vip expires by date"`: `VipUntil = 100` → `resolve(d,false,99).vip == true` e `resolve(d,false,100).vip == false`. `"premium unlocks starter, vip unlocks vipOnly kits"`.
  - `shopdata.spec`: `"vip days stack from the later of now and VipUntil"` (`addVipDays(d,30,1000)` → `1000+30*86400`; de novo em `2000` → `1000+60*86400`). `"boost restarts after expiring"` (`addBoost(d,3600,0)` → Start 0, Until 3600; `addBoost(d,3600,5000)` → Start 5000, Until 8600; `addBoost(d,3600,8000)` → Start 5000, Until 12200).
  - `shopcatalog.spec`: `"vip pass is gone, ember2x and book exist"` (`Products.get("pass_vip") == nil`, `pass_ember2x.price.amount == 199`, `pass_book.price.amount == 99`); `"revive products are hidden and priced by step"` (`revive_3.hidden == true`); `"checkin rewards are valid"` (cada item de `ShopConfig.CHECKIN` passa em `Rewards.validate`, e `#CHECKIN == 7`).
  - `kits.spec`: `"kit_vip is vipOnly and not sold"` (`Products.get("kit_kit_vip") == nil`, `KitRules.canBuy(Defs.Kits.kit_vip, 999999) == false`).
  - `exclusivekits.spec`: `"vipOnly kit is visible without ownership"`. `KitRules.visible(Defs.Kits, {})` inclui `kit_vip` (diferente dos de conquista, que continuam escondidos; mudar `KitRules.visible` para isso).
- [ ] **Step 2:** `lune run tests/run` → falham.
- [ ] **Step 3:** Implementar. `PurchaseRules.check` recusa produto `hidden` com o motivo `"unknown"`. As telas que listam produtos (`Menu/Shop/*`) ignoram `hidden`.
- [ ] **Step 4:** `bash scripts/check.sh` verde.
- [ ] **Step 5:** Commit `feat(loja): VIP por 30 dias, gamepasses 2× e livro, produtos de revive e boost, Perks`.

### Task 3: `PerkService` e os benefícios no jogo

**Files:**
- Create: `src/server/Services/PerkService.luau`
- Modify: `src/server/Services/ShopService.luau` (GRANTS `vip`, `xpBoost`, `reviveCredit`; tirar o caso `id == "vip"` de `pass`; `onLoaded` sem `Passes.vip`), `src/server/Services/InventoryService.luau` (remover `checkVipPass` e `VIP_PASS.gamePassId`; o bônus vem do `PerkService`), `src/shared/InventoryConfig.luau` (tirar `gamePassId`), `src/server/Services/SpawnService.luau`, `src/server/Services/LifeService.luau`, `src/shared/StatNames.luau`, `src/server/Services/DevDataService.luau`
- Test: `tests/kitchoice.spec.luau`

**Interfaces:**
- Consumes: `Perks`, `ShopData` (Task 2), `CurrencyRules.pointsToCurrency` (Task 1).
- Produces:
  ```lua
  PerkService.current(player): Perks.PerkSet   -- agora (perfil + MembershipType)
  PerkService.forLife(player): Perks.PerkSet   -- foto tirada em LifeService.onStarted; sem foto = current
  PerkService.emberMultiplier(player): number  -- de forLife
  PerkService.unlockedKits(player): { [string]: boolean } -- de forLife
  PerkService.refresh(player)                  -- republica atributos (depois de compra/presente)
  ```
  Atributos no `Player` (StatNames): `Perk_vip`, `Perk_ember2x`, `Perk_book`, `Perk_premium` (bool), `VipUntil`, `XpBoostStart`, `XpBoostUntil` (number).
- `KitChoice.State.owned` passa a receber a união de `KitsOwned` com `PerkService.unlockedKits`. `KitChoice` não muda; o `SpawnService.chooseKit` monta a união.

- [ ] **Step 1: Teste que falha** em `kitchoice.spec`: `"a perk-unlocked kit resolves as permanent"`. Com `owned = { kit_starter = true }` vindo só do Premium e `active = nil`, pedir `{kitId="kit_starter", source="permanent"}` resolve para `"kit_starter", "permanent"`. Um kit `vipOnly` fora de `owned` não resolve.
- [ ] **Step 2:** `lune run tests/run` → falha (ou passa, se o `KitChoice` já aceitar; aí o teste fica como trava).
- [ ] **Step 3:** Implementar:
  - Foto em `LifeService.onStarted`.
  - `InventoryService.setPassBonus(player, n)` vira `InventoryService.setPerkBonus(player, slots: number)`, que aceita **0** (tira o bônus). As duas chamadas em `ShopService.luau` (linhas ~164 e ~356) saem. É chamado ao nascer, com `forLife().vip`. Comprar VIP com o jogador vivo chama na hora com +3.
  - Premium: `Players.PlayerMembershipChanged` → `refresh`.
  - Livro: `SPAWN_ITEMS` só se `forLife(player).book`.
  - Multiplicador no `LifeService.endLife` → `PerkService.emberMultiplier(player)`.
  - `DevShopGrant` aceita `{kind="vip", count=30}` e `{kind="pass", id="ember2x"}`, e chama `refresh`.
- [ ] **Step 4:** `bash scripts/check.sh` verde. No Studio, pelo MCP: dar VIP com `DevShopGrant`, morrer (`DevEndLife`), nascer → 13 espaços e `Perk_vip = true`; com `DevShopRevoke`, o VIP continua até a próxima morte.
- [ ] **Step 5:** Commit `feat(perks): VIP, 2×, livro e Premium valendo no jogo`.

### Task 4: Boost de XP

**Files:**
- Create: `src/shared/Data/XpBoost.luau`
- Modify: `src/shared/Data/LevelRules.luau` (`earn` ganha `capFactor: number?`), `src/server/Services/LifeService.luau`, `src/server/Services/RankService.luau` (nada, se receber o XP base)
- Test: `tests/xpboost.spec.luau` (novo), `tests/levelrules.spec.luau`

**Interfaces:**
- Produces: `XpBoost.factor(lifeStart: number, lifeEnd: number, boostStart: number, boostUntil: number): number` (de 1 a 2 = 1 + fração da vida dentro do boost, em unix). `LifeService.LifeSummary` ganha `xpBase: number`.
- `LifeService` precisa do início da vida em unix: guardar `os.time()` junto do `LifeRules.start`.

- [ ] **Step 1: Testes que falham** em `xpboost.spec`: vida 0–100 com boost 50–200 → `1.5`; boost inteiro → `2`; sem interseção → `1`; vida de duração 0 → `1`; boost com `until <= start` → `1`. Em `levelrules.spec`: `"cap scales with factor"`: com teto `MAX_XP_PER_HOUR = 100000`, `earn(d, 250000, t, 2) == 200000`.
- [ ] **Step 2:** `lune run tests/run` → falham.
- [ ] **Step 3:** Implementar. XP concedido = `LevelRules.earn(xpData, floor(score × factor), now, factor)`; `RankService.addLife` recebe `xp = min(xpBase, concedido)`, com `xpBase = floor(score)`.
- [ ] **Step 4:** `bash scripts/check.sh` verde.
- [ ] **Step 5:** Commit `feat(xp): boost de XP proporcional à vida, fora do ranking`.

### Task 5: Quem matou = último que acertou em 10 s

**Files:**
- Create: `src/shared/Combat/CombatTag.luau`
- Modify: `src/server/Services/CharacterService.luau` (guarda o último atacante jogador por vítima e expõe `CharacterService.lastAttacker(player): (Player?, number?)`), `src/server/Services/DeathService.luau`
- Test: `tests/combattag.spec.luau` (novo)

**Interfaces:**
- Produces: `CombatTag.WINDOW = 10`; `CombatTag.resolve(killer: Player?, last: Player?, lastAt: number?, victim: Player, now: number): Player?`. Ordem: `killer` válido; senão `last`, se `now - lastAt <= WINDOW` e `last ~= victim`; senão `nil`. No teste, use tabelas falsas no lugar de `Player` (só identidade).

- [ ] **Step 1: Testes que falham:** killer direto vence; sem killer, `last` a 9 s conta e a 11 s não; `last == victim` não conta.
- [ ] **Step 2:** `lune run tests/run` → falham.
- [ ] **Step 3:** Implementar. Em `DeathService.kill`, `validKiller = CombatTag.resolve(...)` antes do resto (a regra de "ainda no jogo" continua). O registro do atacante é limpo quando o personagem troca.
- [ ] **Step 4:** `bash scripts/check.sh` verde.
- [ ] **Step 5:** Commit `feat(combate): queda ou afogamento no meio da luta dão o abate a quem bateu`.

### Task 6: Cópia do inventário, ponto de nascimento e totem

**Files:**
- Create: `src/shared/InventorySnapshot.luau`, `src/shared/Survival/SpawnPoint.luau`
- Modify: `src/server/Services/InventoryService.luau`, `src/server/Services/TeamService.luau`, `src/server/Services/SpawnService.luau`
- Test: `tests/inventorysnapshot.spec.luau`, `tests/spawnpoint.spec.luau` (novos)

**Interfaces:**
- Produces:
  ```lua
  export type Snapshot = { capacity: number, slots: { [number]: { id: string, count: number } }, bag: string?, armor: string?, selected: number }
  InventorySnapshot.copy(inv: Inventory.Inventory, bag: string?, armor: string?, selected: number): Snapshot -- cópia funda
  InventoryService.snapshot(player): Snapshot?
  InventoryService.restore(player, snap: Snapshot) -- equipa a mochila, põe capacidade >= snap.capacity, recoloca cada slot no MESMO índice, seleciona; manda snapshot ao cliente
  SpawnPoint.pick(rng: Random, zone: { minX: number, maxX: number, minZ: number, maxZ: number }, blocked: (x: number, z: number) -> boolean, tries: number): (number?, number?)
  TeamService.totemPositionOf(player): Vector3? -- totem do time do jogador, se de pé
  SpawnService.spawnAt(player, position: Vector3): boolean -- LoadCharacterAsync e PivotTo; sem kit nem SPAWN_ITEMS
  SpawnService.reviveSpot(player): Vector3 -- totem ou SpawnPoint.pick na floresta; se 30 tentativas falharem, WorldConfig.SPAWN
  ```
  A armadura volta por `ArmorService.wear(player, snap.armor)`, dentro do `restore`. `blocked` (no servidor) = dentro de `Map.Water` ou `Map.NoSpawn`, a menos de 12 studs de uma construção (`StructureService.near`) ou a menos de 30 studs de outro jogador vivo. Esses números são chamada minha, ficam no topo do `SpawnService`.

- [ ] **Step 1: Testes que falham:**
  - `inventorysnapshot.spec`: `"copy is deep"` (mexer no original não muda a cópia); `"restore keeps slots beyond base capacity"` (cópia com `capacity = 23` e slot 22 preenchido → o inventário recriado com `Inventory.setCapacity(inv, 23)` tem o slot 22). Teste a parte pura: `InventorySnapshot.apply(inv, snap)`, usada pelo `restore`.
  - `spawnpoint.spec`: `"avoids blocked points"` (`blocked` recusa x < 0 → todo ponto devolvido tem x ≥ 0); `"gives up after tries"` (`blocked` sempre true → `nil, nil`); mesmo `Random.new(1)` → mesmo ponto.
- [ ] **Step 2:** `lune run tests/run` → falham.
- [ ] **Step 3:** Implementar. A zona da floresta vem do `WorldConfig` (se não houver constante, criar `WorldConfig.FOREST_BOUNDS = { minX = -1110, maxX = -150, minZ = 150, maxZ = 1110 }`, os limites do mapa F6).
- [ ] **Step 4:** `bash scripts/check.sh` verde.
- [ ] **Step 5:** Commit `feat(revive): cópia do inventário, nascimento aleatório na floresta e no totem`.

### Task 7: Revive no servidor

**Files:**
- Create: `src/shared/Survival/ReviveRules.luau`, `src/server/Services/ReviveService.luau`
- Modify: `src/server/Services/DeathService.luau`, `src/server/Services/CrateService.luau`, `src/server/Services/CharacterService.luau` e `src/server/Services/MobService.luau` (proteção de nascimento), `src/shared/StatNames.luau`, `net/game.blink`
- Test: `tests/revive.spec.luau` (novo)

**Interfaces:**
- Consumes: Tasks 2, 3, 5 e 6.
- Produces:
  ```lua
  -- ReviveRules (puro)
  ReviveRules.DECISION_SECONDS = 30; ReviveRules.PURCHASE_PAUSE_MAX = 60; ReviveRules.SHIELD_SECONDS = 3
  export type Offer = { step: number, robux: number, free: boolean, credit: boolean } -- step 1..4
  ReviveRules.offer(paidThisRun: number, vipFreeLeft: boolean, credits: number): Offer
  -- crédito > 0 → free+credit; senão VIP com grátis → free no degrau 1; senão degrau min(paidThisRun+1, 4)
  export type Pending -- estado da janela (estado puro)
  ReviveRules.open(now: number): Pending
  ReviveRules.pause(p: Pending, now: number) / ReviveRules.resume(p: Pending, now: number)
  ReviveRules.expired(p: Pending, now: number): boolean -- 30 s fora das pausas; pausa conta no máximo 60 s
  ReviveRules.answer(p: Pending, accept: boolean): ("revive" | "decline")? -- só a 1ª resposta vale
  ReviveRules.eligible(creative: boolean, tutorial: boolean, hasProfile: boolean, hasItems: boolean): boolean
  ```
  - `DeathService.setReviveHook(hook: (player, character, killer) -> boolean)`: chamado depois do `GhostService.tryGhost` e **antes** dos ouvintes. `true` = revive pendente. `onDeath` passa a ter o 4º argumento `pending: boolean`.
  - `DeathService.finalize(player)`: `StructureService.removeOwned` + `real_deaths`. Na morte sem revive, roda dentro do `kill`, como hoje; com revive pendente, roda quando a resposta for "não".
  - `CrateService.lastPlayerCrate(player): Model?` (a caixa desta morte), `CrateService.setLocked(model, locked: boolean)` (atributo `CrateLocked` no modelo; trancada não abre no `onWatch`/`onTake` nem leva dano no `hit`) e `CrateService.removeModel(model)`.
  - `ReviveService`: contagem por "corrida" (zera no `SpawnService.spawn` normal, pelo menu; não zera no `spawnAt`); `vipFreeUsed` por corrida; usa `ShopData.ReviveCredits`.
  - Rede (`net/game.blink`): `LifeEnded` ganha `Revive: struct { Robux: u16, Free: boolean }?` e `EmberBonus: u8` (bits 1 = 2×, 2 = VIP, 4 = Premium). Eventos novos: `RequestRevive { Accept: boolean }` (Client) e `ReviveClosed { Revived: boolean }` (Server).
  - Proteção: atributo `SpawnShieldUntil` (servidor, `GetServerTimeNow`) no `Player`. `CharacterService.hurt` ignora o dano, e o `MobService` não mira (onde já pula fantasma). Some antes se ele bater: no `GatherService`, golpe em jogador/mob zera o atributo.
- Fluxo do aceite: `ShopService.charge(player, {currency="robux", amount=offer.robux}, "revive_<step>")` (grátis se `offer.free`; gasta 1 crédito se `offer.credit`) → `CrateService.removeModel` → `SpawnService.spawnAt(player, SpawnService.reviveSpot(player))` → `InventoryService.restore` → vida e barras cheias (as mesmas chamadas do nascimento normal) → `SpawnShieldUntil = agora + 3` → `ReviveClosed { Revived = true }`. Recusa, tempo ou `PlayerRemoving`: `CrateService.setLocked(model, false)`, `DeathService.finalize`, `ReviveClosed { Revived = false }`.
- Pausa da compra: `ReviveService.purchaseStarted(player)` / `purchaseEnded(player)` chamam `ReviveRules.pause`/`resume`. Nesta branch a cobrança é instantânea e ninguém chama; na fase 9, o `PromptProductPurchase` chama. Se o pagamento confirmar depois que a janela fechou, `ReviveService.lateRevive(player)` soma 1 em `ShopData.ReviveCredits`.
- `EmberBonus` vem de `PerkService.forLife(player)` lido **antes** do `endLife` (a foto da vida que acabou).

- [ ] **Step 1: Testes que falham** em `revive.spec`:
  - `"price climbs and caps"`: `offer(0,false,0).robux == 25`, `offer(1,…) == 49`, `offer(3,…) == 199`, `offer(9,…) == 199`.
  - `"vip free takes the first step"`: `offer(0,true,0)` → `free == true, step == 1`; depois de usado, `offer(1,false,0).robux == 49`.
  - `"credit is used first"`: `offer(2,false,1)` → `free == true, credit == true`.
  - `"window expires after 30s"`: `expired(open(0), 29.9) == false` e `expired(open(0), 30) == true`.
  - `"pause stops the clock up to 60s"`: abrir em 0, pausar em 10, retomar em 50 → não expira em 69, expira em 70. Pausar em 10 e nunca retomar → expira em 10 + 60 + 20 = 90.
  - `"second answer is ignored"`: `answer(p,true) == "revive"` e depois `answer(p,false) == nil`.
  - `"leaving resolves as decline"`: `ReviveRules.onLeave(p) == "decline"` se ainda sem resposta, e `nil` se já respondido.
  - `"not eligible in creative, tutorial, without profile or items"`.
- [ ] **Step 2:** `lune run tests/run` → falham.
- [ ] **Step 3:** Implementar `ReviveRules`, depois os ganchos no `DeathService`/`CrateService`, depois o `ReviveService` (um laço único confere `expired` a cada 0,5 s, como o `checkFalls`). O fantasma continua primeiro: o gancho só roda quando o `tryGhost` devolve `false`.
- [ ] **Step 4:** `bash scripts/check.sh` verde. No Studio, pelo MCP: matar com itens (`DevEndLife`) → caixa trancada e construções de pé; `RequestRevive {Accept=true}` → volta com os mesmos slots, mochila e armadura, longe do centro. Repetir com `Accept=false`, depois sem responder por 30 s → caixa abre e construções somem.
- [ ] **Step 5:** Commit `feat(revive): revive pago com caixa trancada, totem e proteção de 3 s`.

### Task 8: Telas do revive

**Files:**
- Modify: `src/client/Screens/DeathScreen.luau`, `src/client/ScreenState.luau`, `src/client/Net.luau` (gerado), `src/shared/Strings/ptBR.luau`
- Create: `src/client/UI/ReviveOffer.luau`, `src/client/World/CrateLock.luau` (cadeado em `BillboardGui` nas caixas com `CrateLocked`), `src/client/World/SpawnShieldFx.luau` (bolha enquanto `SpawnShieldUntil` estiver no futuro; atributo lido por polling, ver `reference-sa-atributos-sem-sinal`)
- Test: `tests/deathlayout.spec.luau` (se o layout da tela mudar)

**Interfaces:**
- Consumes: `LifeEnded.Revive`, `LifeEnded.EmberBonus`, `RequestRevive`, `ReviveClosed` (Task 7); `MonetizationImages` (Task 2).

- [ ] **Step 1:** Se o painel mudar a altura da coluna de resumo, acrescente em `deathlayout.spec` o caso `"revive offer fits on phone width"`, no padrão dos casos que já existem.
- [ ] **Step 2:** Implementar:
  - O painel aparece por cima do resumo, com o ícone, o preço (Robux) ou o selo GRÁTIS VIP, **REVIVER** e **Não, obrigado**, sem contador.
  - Enquanto pendente, "Menu" e "Jogar de novo" ficam escondidos.
  - `ReviveClosed { Revived = false }` mostra a tela de morte normal; `true` fecha a tela, e a cor do mundo volta como no nascimento.
  - Etiquetas do `EmberBonus` ao lado da Golden Ember ("2×", "VIP +50%", "Premium +20%").
- [ ] **Step 3:** `bash scripts/check.sh` verde.
- [ ] **Step 4:** No Studio, pelo MCP: morrer com itens → captura da oferta; clicar REVIVER → volta com bolha; morrer de novo → preço 49; clicar Não, obrigado → tela normal e caixa sem cadeado.
- [ ] **Step 5:** Commit `feat(revive): oferta na tela de morte, cadeado da caixa e bolha de proteção`.

### Task 9: Check-in de 7 dias

**Files:**
- Create: `src/shared/Shop/CheckInRules.luau`, `src/server/Services/CheckInService.luau`, `src/client/Menu/CheckInPanel.luau`
- Modify: `net/game.blink` (`CheckInClaim` Client; `CheckInResult { Ok: boolean, Day: u8 }` Server), `src/client/Menu/MenuShell.luau` (botão de calendário ao lado do saldo, com bolinha quando há prêmio; abre sozinho ao entrar no menu se houver prêmio, uma vez por sessão), `src/shared/StatNames.luau`, `src/shared/Strings/ptBR.luau`, `src/shared/UIFlow/MenuLayout.luau` (posição do botão)
- Test: `tests/checkin.spec.luau` (novo)

**Interfaces:**
- Produces: `CheckInRules.canClaim(save: { Day: number, LastDay: number }, today: number): boolean` (`today ~= LastDay`); `CheckInRules.claim(save, today): Reward?` (devolve `ShopConfig.CHECKIN[Day]`, grava `LastDay = today`, `Day = Day % 7 + 1`; `nil` se não pode). Atributos no Player: `CheckInDay` (1..7) e `CheckInReady` (bool). O servidor entrega por `ShopService.give(player, reward, "checkin")`. O `today` vem de `RankRules.dayIndex(os.time())`.
- [ ] **Step 1: Testes que falham:** `"first claim gives day 1"`; `"second claim same day is refused"`; `"next day gives day 2 even after a gap"` (`LastDay = 10`, `today = 15` → dia 2); `"after day 7 comes day 1"`; `"midnight brasilia rolls the day"` (dois instantes, 23:59 e 00:01 de Brasília, dão `dayIndex` diferentes → o segundo pode resgatar).
- [ ] **Step 2:** `lune run tests/run` → falham.
- [ ] **Step 3:** Implementar o serviço (throttle como o `ShopService`, republica `CheckInDay`/`CheckInReady` ao carregar o perfil e na virada do dia) e o painel: 7 cartões com o dia 7 maior, estados resgatado / hoje / futuro.
- [ ] **Step 4:** `bash scripts/check.sh` verde. No Studio, pelo MCP: entrar → painel abre sozinho; resgatar → +100 GE; reabrir → dia 2 trancado até amanhã (mudar `LastDay` no perfil de dev para testar).
- [ ] **Step 5:** Commit `feat(check-in): sete prêmios, um por dia em que o jogador entra`.

### Task 10: Loja — VIP, gamepasses novas, Premium e boost

**Files:**
- Modify: `src/client/Menu/Shop/Passes.luau`, `src/client/Menu/Shop/ShopScreen.luau`, `src/client/Menu/Shop/RewardView.luau` (textos de `vip`, `xpBoost`, `reviveCredit`), `src/client/ShopData.luau` (fontes dos atributos `Perk_*`, `VipUntil`, `XpBoostUntil`), `src/shared/UIFlow/ShopLayout.luau`, `src/shared/Strings/ptBR.luau`
- Create: `src/client/Menu/Shop/VipCard.luau`, `src/client/Menu/Shop/PremiumCard.luau`, `src/client/UI/XpBoostBadge.luau` (HUD e menu)

**Interfaces:**
- Consumes: produtos `vip_30d`, `pass_ember2x`, `pass_book`, `xpboost_1h` (Task 2) e atributos da Task 3.
- [ ] **Step 1:** Implementar:
  - **VipCard:** no topo da aba de gamepasses, benefícios, "99 por mês" e o estado "VIP ativo até DD/MM", com a data de `VipUntil` no fuso de Brasília (`ShopDates`).
  - **Cartões** de `ember2x` e `book` em `Passes`, no lugar do VIP.
  - **PremiumCard:** só para quem não tem Premium; o botão chama `MarketplaceService:PromptPremiumPurchase(player)`.
  - **Boost:** cartão na aba de pacotes e selo com o tempo restante (mm:ss) enquanto `XpBoostUntil > agora`.
- [ ] **Step 2:** `bash scripts/check.sh` verde.
- [ ] **Step 3:** No Studio, pelo MCP: comprar cada um (grátis) e conferir os estados e os atributos; capturas no celular (749×330) e no PC.
- [ ] **Step 4:** Commit `feat(loja): cartão do VIP, gamepasses 2× e livro, Premium e boost de XP`.

### Task 11: Ícone VIP no nome e kits com cadeado

**Files:**
- Modify: `src/client/Boneco/BonecoModel.luau:224` (`buildNameTag`: ícone à esquerda do nome quando o dono tem `Perk_vip`; lido por polling), `src/client/Menu/KitsPanel.luau` (Kit VIP com "Só VIP" para quem não assina; `kit_starter` com selo "Premium" para quem tem Premium; o Kit VIP ativo pelo `SetActiveKit` como os permanentes), `src/shared/Strings/ptBR.luau`
- [ ] **Step 1:** Implementar.
- [ ] **Step 2:** `bash scripts/check.sh` verde.
- [ ] **Step 3:** No Studio, com 2 jogadores (Play com 2 clientes): o VIP vê e é visto com o ícone; o não-VIP vê o Kit VIP trancado.
- [ ] **Step 4:** Commit `feat(vip): ícone no nome e kits VIP/Premium no painel`.

### Task 12: Item aleatório pago

**Files:**
- Modify: `src/server/Services/ShopService.luau` (consulta `PolicyService:GetPolicyInfoForPlayerAsync` no `onLoaded`, com pcall; falhou = restrito; publica o atributo `PaidRandomBlocked`), `src/shared/Shop/PurchaseRules.luau`, `src/client/Menu/Shop/SpinScreen.luau` e `SpinTypes.luau` (chances por raridade visíveis antes de comprar; aviso de bloqueio), `src/client/Menu/Shop/Featured.luau` (esconde pacote com giros), `src/shared/Strings/ptBR.luau`
- Test: `tests/shopdata.spec.luau` (casos de `PurchaseRules`)

**Interfaces:**
- Produces: `PurchaseRules.check(product, d, now, balance, randomBlocked: boolean?)`. Com `randomBlocked`, o motivo é `"restricted"` para produtos `spins` e para `bundle` com recompensa `spins`. `Products.hasRandom(product): boolean`.
- [ ] **Step 1: Testes que falham:** `"restricted blocks spin packs of both kinds"` (`spins_normal_1` e `spins_paid_1` → `"restricted"`); `"restricted blocks bundles with spins only"` (pacote com `ember` passa; com `spins` → `"restricted"`); `"unrestricted buys normally"` (`randomBlocked = false` ou `nil` → sem recusa). O giro com saldo já ganho (`ShopService.spin`) não passa pelo `PurchaseRules` e não muda.
- [ ] **Step 2:** `lune run tests/run` → falham.
- [ ] **Step 3:** Implementar.
- [ ] **Step 4:** `bash scripts/check.sh` verde.
- [ ] **Step 5:** Commit `feat(loja): chances visíveis e bloqueio de giro pago onde a lei proíbe`.

### Task 13: Artes, guias e fechamento

Esta tarefa começa quando as artes do Elizeu chegarem (`docs/game-design/assets-ui-monetizacao.md`).

**Files:**
- Modify: `src/shared/MonetizationImages.luau` (ids), telas das Tasks 8–11, `src/client/UI/PinnedRecipe.luau` (pergaminho, asset 29; só **depois** que a `ui-celular` estiver junta nesta branch), `docs/guia/loja.md`, `docs/pendencias.md`
- Create: `docs/guia/revive.md`, `assets/ui/monetizacao/` (recortes)
- Test: `tests/monetizationimages.spec.luau` (no molde de `missionimages.spec`: todo id é `""` ou `rbxassetid://<número>`)
- [ ] **Step 1:** Recortar as artes (script em `assets/ui/monetizacao/`, como `prepare_ranking.py`) e enviar na conta/grupo **com a confirmação do Elizeu antes de cada lote**. Gravar os ids.
- [ ] **Step 2:** Encaixar nas telas (9 partes onde estica, `SliceScale` descontando o `UIScale`) e capturar celular e PC.
- [ ] **Step 3:** Guias: `loja.md` (VIP por 30 dias, gamepasses novas, check-in, boost, regra do aleatório, comandos de dev novos) e `revive.md` (fluxo, preços, caixa trancada, testes). Em `pendencias.md`: risco do farm de abates sem teto e fase 9 (cobrança real).
- [ ] **Step 4:** `bash scripts/check.sh` verde; `graphify update .`.
- [ ] **Step 5:** Commit `feat(monetizacao): artes, pergaminho da receita fixada e guias`.
