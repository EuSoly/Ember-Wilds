# Loja e kits funcionando (sem cobrar Robux) — plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Toda compra da Loja e dos kits passa pelo servidor, entrega de verdade e fica salva no perfil; preço em Robux sai de graça, preço em Golden Ember desconta; pacotes viram dados fáceis de criar.

**Architecture:** Tudo que se compra é um **produto** (`src/shared/Shop/`), com preço, limite, datas e **recompensas** de tipos registrados num lugar só. Regras puras (catálogo, datas, compra, sorteio, escolha de kit, dados do perfil) ficam em `src/shared` com testes Lune; um `ShopService` no servidor aplica compra e giro e publica o estado numa pasta do Player; o cliente lê essa pasta e só manda pedidos.

**Tech Stack:** Luau `--!strict`, Vide (UI), Blink (`net/game.blink`), ProfileStore (`DataService`), Lune (testes em `tests/*.spec.luau`, `lune run tests/run`), `bash scripts/check.sh`.

**Spec:** `docs/superpowers/specs/2026-11-09-loja-funcional-design.md`

## Global Constraints

- Nada do cliente é confiado além do id do produto, do tipo de roleta, do saldo escolhido e do kit escolhido; preço, conteúdo, sorteio, saldo e posse são do servidor.
- Compra é tudo-ou-nada: confere tudo, depois cobra e entrega.
- Preço `robux` = grátis por enquanto (um único ponto, `ShopService.charge`, onde o `MarketplaceService` entra depois). Preço `ember` = `CurrencyService.spend`.
- Listas que crescem (kits possuídos, saldo por kit, compras `once`) vão em **pastas com objetos**, nunca atributos no Player (limite ~1 KB).
- Skin só por `CosmeticService.grantOwnership`; moeda de compra por `CurrencyService.grant` (sem teto).
- Repetida na roleta devolve Golden Ember: normal **50**, especial **150**.
- Datas de pacote: texto `"AAAA-MM-DD HH:MM"` em horário de Brasília (UTC−3 fixo).
- Pacote: compra uma vez por jogador; skin já possuída é ignorada e o resto entra; recompensa `kit` = para sempre.
- Kit 1 vida = saldo por kit (`kitOnce`, acumula); um kit por vida; escolha = kit + origem (`points` ou `balance`); sem escolha → permanente ativo → nenhum.
- `DataConfig.SCHEMA_VERSION` sobe para 2; o passo v1→v2 zera `Cosmetics.Owned`. Sai o laço "todas as skins liberadas" do `CosmeticService.publishOwned`.
- O Iniciante deixa de começar permanente (`KIT_STARTS_OWNED` sai).
- Textos novos em `src/shared/Strings/ptBR.luau`; `bash scripts/check.sh` passa ao fim de cada tarefa (com `export PATH="$HOME/.rokit/bin:$PATH"`).
- Depois de mudar código: `& (Get-Content graphify-out\.graphify_python) -m graphify update .`.

## Review Focus

- **Clique duplo / pedidos em rajada** no comprar ou girar: só um é atendido (taxa mínima por jogador) e o saldo nunca fica negativo. → teste em Task 4 (`PurchaseRules`) e checagem manual na Task 9.
- **Comprar giro sem Golden Ember suficiente**: recusa sem mudar nada e o botão diz quanto falta. → Task 4.
- **Pacote fora da data** (antes do começo, depois do fim) pedido por um cliente com o relógio errado: o servidor recusa; a loja não mostra. → Task 2 e Task 4.
- **Girar uma roleta sem skins** (Acessórios) ou com tipo inventado: recusa sem gastar giro. → Task 3.
- **Kit escolhido de saldo que acabou** (gastou em outra aba/morte): nasce sem esse kit, não cobra pontos no lugar. → Task 5.

---

### Task 1: Datas da loja

**Files:**
- Create: `src/shared/Shop/ShopDates.luau`
- Test: `tests/shopdates.spec.luau`

**Interfaces:**
- Produces: `ShopDates.parse(text: string): number?` (unix UTC; nil se mal escrito), `ShopDates.UTC_OFFSET_HOURS = -3`, `ShopDates.isOpen(startsAt: number?, endsAt: number?, now: number): boolean`.

- [ ] **Step 1: Testes**
  - `parse("2026-11-09 00:00") == 1794193200` (00:00 em Brasília = 03:00 UTC).
  - `parse("2026-02-28 23:59")` vale `parse("2026-03-01 00:00") - 60`; ano bissexto: `parse("2028-02-29 12:00") ~= nil`.
  - `nil` para `"2026-13-01 00:00"`, `"2026-02-30 10:00"`, `"2026-11-09"`, `"09/11/2026 10:00"`, `"2026-11-09 24:00"`.
  - `isOpen(nil, nil, t) == true`; `isOpen(a, b, a) == true`; `isOpen(a, b, b) == false`; `isOpen(a, nil, a - 1) == false`.
- [ ] **Step 2:** `lune run tests/run` → os novos falham (módulo não existe).
- [ ] **Step 3:** Implementar sem `DateTime`/`os.time` de data (precisa rodar no Lune e no Roblox): conta de dias desde 1970 por ano/mês.
- [ ] **Step 4:** `lune run tests/run` → passam.
- [ ] **Step 5:** Commit `feat(loja): datas dos pacotes em horário de Brasília`.

### Task 2: Recompensas, produtos e pacotes (catálogo)

**Files:**
- Create: `src/shared/Shop/Rewards.luau` (registro de tipos), `src/shared/Shop/Bundles.luau` (dados dos pacotes, o arquivo que o Elizeu edita), `src/shared/Shop/Products.luau` (monta e valida todos os produtos), `src/shared/Shop/ShopConfig.luau` (preços, chances, devolução)
- Modify: `src/shared/UIFlow/MockStore.luau` (sai `PACKS`, `KIT_ROBUX`, `KIT_STARTS_OWNED`, `SPIN_ODDS`, `SPIN_PRICES`, `BUNDLES`, `PASSES`; ficam `RARITIES`, `SHOWCASE_WEIGHTS`, `SPIN_TYPES`), `tests/mockstore.spec.luau` (move os testes de preço/chance para o novo)
- Test: `tests/shopcatalog.spec.luau`

**Interfaces:**
- Produces:
  - `export type Reward = { kind: string, id: string?, amount: number?, count: number?, spin: ("normal" | "paid")? }`
  - `Rewards.KINDS: { [string]: { validate: (reward: Reward, defs: Defs) -> string? } }` com `cosmetic {id}`, `ember {amount}`, `spins {spin, count}`, `kit {id}`, `kitOnce {id, count}`, `pass {id}` (passes válidos: `ShopConfig.PASSES = { vip = { bonusSlots = 3 } }`).
  - `Rewards.validate(reward: Reward, defs): string?` (tipo desconhecido → erro).
  - `export type Price = { currency: "robux" | "ember", amount: number }`
  - `export type Product = { id: string, kind: "bundle" | "pack" | "spins" | "kitOnce" | "kit" | "pass", price: Price, once: boolean, startsAt: number?, endsAt: number?, rewards: { Reward }, nameKey: string, order: number }`
  - `export type BundleDef = { id: string, nameKey: string, theme: string, rarity: number, robux: number, startsAt: string?, endsAt: string?, art: string?, rewards: { Reward } }` em `Bundles.luau` (tabela `{ BundleDef }`, comentário no topo com um exemplo para copiar).
  - `Products.all(): { Product }`, `Products.get(id: string): Product?`, `Products.bundles(now: number): { Product }` (só os abertos, na ordem), `Products.validate(defs, strings): { string }` (lista de erros).
  - Ids: `bundle_<id>`, `pack_<amount>`, `spins_normal_<qty>`, `spins_paid_<qty>`, `kitonce_<kitId>`, `kit_<kitId>`, `pass_vip`.
  - `ShopConfig.SPIN_ODDS = { normal = {30,40,23,6,1}, paid = {5,25,40,25,5} }`, `ShopConfig.DUPLICATE_REFUND = { normal = 50, paid = 150 }`, `ShopConfig.SPIN_PACKS` (normal: 1/100, 3/280, 10/850 em Ember; paid: 1/49, 3/129, 10/399 Robux), `ShopConfig.EMBER_PACKS` (300/80, 600/150, 2600/600 popular, 7000/1500 off30, 20000/3500 best), `ShopConfig.KIT_ROBUX` (os quatro de hoje).
- [ ] **Step 1: Testes** (`tests/shopcatalog.spec.luau`, com o `Defs` real e `Strings` reais):
  - `Products.validate` dos dados reais → lista vazia.
  - Cada tipo de recompensa: válida passa; `cosmetic` com id inexistente, `kit` inexistente, `ember` com `amount = 0`/`1.5`, `spins` com `spin = "x"`, `kitOnce` sem `count`, `pass` desconhecido, `kind = "pet"` → erro com o nome do campo.
  - Pacote com `endsAt` antes de `startsAt`, data mal escrita, id repetido, `nameKey` sem texto em ptBR → erro.
  - `Products.get("kit_kit_explorer").rewards[1]` = `{ kind = "kit", id = "kit_explorer" }`; `get("kitonce_kit_explorer")` tem `once = false` e recompensa `kitOnce count 1`; `get("bundle_brasa").once == true`; `get("spins_normal_3").price` = `{ currency = "ember", amount = 280 }`; `get("pass_vip").price.currency == "robux"`.
  - `Products.bundles(now)` não lista pacote com `endsAt <= now`.
- [ ] **Step 2:** Rodar → falham.
- [ ] **Step 3:** Implementar. Os três pacotes de exemplo (Brasa, Geada, Musgo) apontam para skins reais (`Defs.Cosmetics`) de corpo, livro, mochila e caixa do tema (escolher por cor/nome), um deles com `ember` e `spins` para exercitar os tipos; `startsAt` hoje e `endsAt` 2, 5 e 1 dia depois. Textos `shop.bundle.<id>` já existem; os `shop.bundle.<id>.<tipo>` saem. `Products.validate` roda no boot do servidor e do cliente (como o `Defs`: `error` com a lista).
- [ ] **Step 4:** `bash scripts/check.sh` → passa.
- [ ] **Step 5:** Commit `feat(loja): catálogo de produtos e pacotes com tipos de recompensa`.

### Task 3: Sorteio da roleta no servidor (regra pura)

**Files:**
- Create: `src/shared/Shop/SpinRoll.luau`
- Test: `tests/spinroll.spec.luau`

**Interfaces:**
- Consumes: `SpinRules.pickIndex`, `SpinRules.pickItem`, `MockStore.SPIN_TYPES`, `ShopConfig.SPIN_ODDS`, `ShopConfig.DUPLICATE_REFUND`.
- Produces: `export type Roll = { itemId: string, rarity: number, duplicate: boolean, refund: number }`; `SpinRoll.roll(typeId: string, kind: "normal" | "paid", owns: (string) -> boolean, r1: number, r2: number): Roll?` (nil = tipo inexistente ou sem skins).
- [ ] **Step 1: Testes:** `roll("accessory", ...) == nil`; `roll("nada", ...) == nil`; com `owns = false` → `duplicate == false`, `refund == 0`, item é do tipo `body`; com `owns = true` → `duplicate`, `refund == 50` (normal) / `150` (paid); `r1 = 0` cai na raridade 1 e `r1 = 0.999` na 5 nas chances `paid`.
- [ ] **Step 2–4:** falha → implementa → passa.
- [ ] **Step 5:** Commit `feat(loja): sorteio da roleta como regra pura`.

### Task 4: Dados da loja no perfil e regra de compra

**Files:**
- Create: `src/shared/Shop/ShopData.luau`, `src/shared/Shop/PurchaseRules.luau`
- Modify: `src/shared/Data/ProfileTemplate.luau` (campo `Shop = ShopData.empty()`), `src/shared/Data/DataConfig.luau` (`SCHEMA_VERSION = 2`), `src/shared/Data/Migrations.luau` (`STEPS[1]` zera `data.Cosmetics.Owned = {}`)
- Test: `tests/shopdata.spec.luau`, `tests/migrations.spec.luau` (novo caso)

**Interfaces:**
- Produces:
  - `export type ShopData = { Spins: { normal: number, paid: number }, Purchased: { [string]: boolean }, KitsOwned: { [string]: boolean }, KitBalance: { [string]: number }, KitActive: string, Passes: { [string]: boolean } }` (`KitActive = ""` = nenhum; ProfileStore não guarda nil).
  - `ShopData.empty(): ShopData`, `ShopData.addSpins(d, kind, n)`, `ShopData.useSpin(d, kind): boolean`, `ShopData.addKitBalance(d, kitId, n)`, `ShopData.useKitBalance(d, kitId): boolean`, `ShopData.ownKit(d, kitId)`, `ShopData.setActive(d, kitId: string?): boolean` (só kit possuído; nil desativa), `ShopData.setPass(d, passId)`, `ShopData.markPurchased(d, productId)` — mutam `d` (é a tabela do perfil).
  - `export type Refusal = "unknown" | "closed" | "bought" | "balance"`; `PurchaseRules.check(product: Product?, d: ShopData, now: number, emberBalance: number): Refusal?`.
- [ ] **Step 1: Testes:** `useSpin` com 0 → false e continua 0; `useKitBalance` com 1 → true e vai a 0, com 0 → false; `setActive` de kit não possuído → false; `check(nil) == "unknown"`; pacote fora da data → `"closed"`; `once` já comprado → `"bought"`; `ember` 280 com saldo 279 → `"balance"`, com 280 → nil; `robux` com saldo 0 → nil. Migração: perfil v1 com `Cosmetics = { Owned = { body_lobo = true }, Equipped = { body = "body_lobo" } }` → v2 com `Owned` vazio e `Equipped` intacto.
- [ ] **Step 2–4:** falha → implementa → passa.
- [ ] **Step 5:** Commit `feat(loja): dados da loja no perfil e regra de compra; limpa skins de teste (schema v2)`.

### Task 5: Escolha do kit da vida (regra pura)

**Files:**
- Create: `src/shared/UIFlow/KitChoice.luau`
- Delete: `src/shared/UIFlow/KitOffer.luau`, `tests/kitoffer.spec.luau`
- Test: `tests/kitchoice.spec.luau`

**Interfaces:**
- Produces: `export type Source = "points" | "balance" | "permanent"`; `KitChoice.resolve(request: { kitId: string?, source: Source? }, state: { points: number, balance: { [string]: number }, owned: { [string]: boolean }, active: string? }, kits): (string?, Source?)`; `KitChoice.auto(kitId, points, balance, kits): Source?` (pontos se der, senão saldo se > 0, senão nil).
- [ ] **Step 1: Testes:** pontos suficientes → `(kit, "points")`; pontos insuficientes com origem `points` → cai no permanente ativo (não usa saldo sozinho); origem `balance` com saldo 0 → permanente ativo; origem `balance` com saldo 2 → `(kit, "balance")`; sem pedido e `active = "kit_veteran"` possuído → `(kit_veteran, "permanent")`; `active` não possuído → `(nil, nil)`; kit inexistente → ignora o pedido. `auto` cobre as três saídas.
- [ ] **Step 2–4:** falha → implementa → passa.
- [ ] **Step 5:** Commit `feat(kits): escolha do kit por origem (pontos, saldo, permanente)`.

### Task 6: Rede e ShopService (compra, giro, publicação)

**Files:**
- Modify: `net/game.blink`
- Create: `src/server/Services/ShopService.luau`
- Modify: `src/server/Services/CosmeticService.luau` (sai o laço de liberar todas), `src/server/Services/InventoryService.luau` (`InventoryService.setPassBonus(player, slots: number)` + aplicar VIP do perfil no `DataService.onLoaded`), `src/shared/StatNames.luau` (nomes da pasta)

**Interfaces:**
- Blink (novos):
  - `RequestPurchase` (Client): `struct { ProductId: string(1..48) }`
  - `PurchaseResult` (Server, só ao dono): `struct { ProductId: string(1..48), Ok: boolean, Reason: string(1..16)? }`
  - `RequestSpin` (Client): `struct { TypeId: string(1..16), Paid: boolean }`
  - `SpinResult` (Server): `struct { TypeId: string(1..16), Paid: boolean, Ok: boolean, ItemId: string(1..48)?, Duplicate: boolean, Refund: u16 }`
  - `SetActiveKit` (Client): `struct { KitId: string(1..32)? }`
  - `RequestSpawn` ganha `Source: string(1..8)?` (`"points"`/`"balance"`).
- Publicação (pasta `Player.Shop`, criada no `onLoaded`, preenchida antes de ir ao Player): atributos `SpinsNormal`, `SpinsPaid`, `KitActive` (string, `""` = nenhum); subpastas `KitsOwned` (BoolValue por kit), `KitBalance` (IntValue por kit, some quando 0), `Purchased` (BoolValue por produto `once`), `Passes` (BoolValue).
- Produces (servidor): `ShopService.purchase(player, productId): (boolean, string?)`, `ShopService.spin(player, typeId, paid): Roll?`, `ShopService.kitState(player): { balance, owned, active }`, `ShopService.useKitBalance(player, kitId): boolean`, `ShopService.charge(player, price): boolean` (robux → true; ember → spend), `ShopService.grant(player, reward)` (um tratador por `kind`; tipo novo = um tratador aqui + o `validate` em `Rewards`).
- [ ] **Step 1:** Editar o Blink e rodar `bash scripts/check.sh` (gera `Net.luau`).
- [ ] **Step 2:** `ShopService`: taxa mínima 0,3 s por jogador para os três pedidos; `purchase` usa `PurchaseRules.check` → `charge` → `grant` de cada recompensa (`cosmetic` → `grantOwnership`, ignora se já tem; `ember` → `CurrencyService.grant`; `spins` → `ShopData.addSpins`; `kit` → `ownKit`; `kitOnce` → `addKitBalance`; `pass` → `setPass` + `InventoryService.setPassBonus`) → `markPurchased` se `once` → republica → `DataService.save` → `PurchaseResult`. `spin`: tipo válido e `useSpin` → `SpinRoll.roll` com `Random.new()` → `grantOwnership` ou `CurrencyService.grant(refund)` → republica → save → `SpinResult` (Ok=false sem gastar se o tipo não tem skins ou sem saldo). `SetActiveKit` → `ShopData.setActive`.
- [ ] **Step 3:** `bash scripts/check.sh` → passa (tipos e lint).
- [ ] **Step 4:** Commit `feat(loja): ShopService com compra, giro e estado no Player`.

### Task 7: Nascer com o kit escolhido

**Files:**
- Modify: `src/server/Services/SpawnService.luau`, `src/client/Screens/KitList.luau` (`KitList.source` = fonte `"points" | "balance"`, `KitList.toggle` usa `KitChoice.auto`), `src/client/Screens/DeathScreen.luau` e `src/client/Menu/MenuShell.luau` (o pedido manda `Source`)

**Interfaces:**
- Consumes: `KitChoice.resolve`, `ShopService.kitState`, `ShopService.useKitBalance`.
- [ ] **Step 1:** `SpawnService.spawn(player, kitId, source)`: `KitChoice.resolve` → `points` cobra pontos (como hoje); `balance` → `useKitBalance` (se falhar, nasce sem kit); `permanent` → grátis; entrega os itens como hoje.
- [ ] **Step 2:** Linhas de kit da morte mostram "N guardados" quando há saldo e ficam clicáveis mesmo sem pontos (origem `balance`).
- [ ] **Step 3:** `bash scripts/check.sh` → passa. Commit `feat(kits): nascer com kit de pontos, de saldo ou permanente`.

### Task 8: Telas da loja e dos kits lendo o servidor

**Files:**
- Create: `src/client/Menu/ShopData.luau` (fontes Vide da pasta `Player.Shop`: `spins(kind)`, `kitBalance(kitId)`, `kitOwned(kitId)`, `kitActive()`, `purchased(productId)`, `hasPass(id)`), `src/client/Menu/Purchase.luau` (`Purchase.buy(productId)` dispara `RequestPurchase`; `PurchaseResult` → `MenuState.notify` com `shop.result.ok` / `shop.result.<reason>`)
- Modify: `src/client/Menu/KitShop.luau` (vira fachada fina sobre `ShopData`/`Purchase`/`SetActiveKit`; sem estado local), `src/client/Menu/KitsPanel.luau` (1 vida = `Purchase.buy("kitonce_<id>")` + "Você tem N" + "Usar 1"; para sempre = `Purchase.buy("kit_<id>")`; Usar/Ativo = `SetActiveKit`), `src/client/Menu/Shop/{Featured,Passes,EmberPacks,SpinScreen,SpinTypes,ShopState}.luau` (dados de `Products`/`ShopConfig`; comprar = `Purchase.buy`; Featured lista as recompensas reais com `ItemViewport`/ícone da moeda/ícone de giro/ícone do kit, contador até `endsAt`, "Comprado" se `purchased`; SpinScreen mostra o saldo único de cada lado, GIRAR manda `RequestSpin` e anima `Reel:spinTo` até o `ItemId` do `SpinResult`; popup diz "Repetida: +50 Golden Ember" quando `Duplicate`); `ShopState.counts` sai
- Modify: `src/shared/Strings/ptBR.luau` (`shop.result.*`, `shop.bundle.bought`, `shop.spin.duplicate`, `kit.balance`, `kit.useOne`); sai `mock.simulated` dos fluxos ligados e o selo MOCKUP deles
- [ ] **Step 1:** Implementar `ShopData` e `Purchase`.
- [ ] **Step 2:** Ligar KitsPanel/KitShop.
- [ ] **Step 3:** Ligar Featured, Passes, EmberPacks.
- [ ] **Step 4:** Ligar SpinScreen (pedido → resultado → animação; trava enquanto espera; destrava se `Ok = false`).
- [ ] **Step 5:** `bash scripts/check.sh` → passa. Commit `feat(loja): telas da loja e dos kits ligadas ao servidor`.

### Task 9: Teste no Studio, guias e grafo

**Files:**
- Modify: `docs/guia/telas.md` (Loja, kits: o que é de verdade), `docs/guia/dados.md` (perfil `Shop`, schema v2, roleta ligada: o checklist vira descrição), `docs/pendencias.md` (skins liberadas: resolvido), novo `docs/guia/loja.md` ("Como criar um pacote" com exemplo, "Como criar um tipo de item de pacote": `Rewards.KINDS` + tratador em `ShopService.grant` + ícone no card, "Onde mudar preços e chances")
- [ ] **Step 1:** Rojo conectado; Play: comprar 1 giro normal (desconta 100), 1 especial (grátis), girar nas duas roletas (skin aparece sem cadeado nos Cosméticos; repetida devolve), comprar um pacote (itens chegam, card mostra "Comprado", segundo clique recusa), pacote de Ember (saldo sobe), VIP (capacidade +3), kit 1 vida ×2 (saldo 2), nascer com saldo (vai a 1), kit para sempre + Usar (nasce com ele), clique duplo rápido em comprar (um só atendido). Console sem erros.
- [ ] **Step 2:** `bash scripts/check.sh` → passa; `graphify update .`.
- [ ] **Step 3:** Commit `docs(loja): guias da loja de verdade e de como criar pacotes`.
