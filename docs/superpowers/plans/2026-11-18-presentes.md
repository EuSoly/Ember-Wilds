# Presentes na loja — plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** comprar qualquer um dos 22 itens da loja com Robux de presente para outro jogador do mesmo servidor, com entrega garantida e o pop-up da caixa para quem recebe.

**Architecture:** regra pura em `Shop/GiftRules` (testada no Lune); servidor `GiftService` (pedido, pendente no perfil de quem paga, entrega no recibo pelo `RobuxService`, mensagem do ProfileStore para quem saiu, caixa de entrada no perfil); cliente `GiftPanel` (janela Presentear) e `GiftPopup` (caixa que abre). Ids dos 22 produtos "Presente: X" em `RobloxIds.GIFT`.

**Tech Stack:** Luau (--!strict), Vide (UI), Blink (`net/game.blink`), ProfileStore, Lune (testes), Rojo; MarketplaceService; Open Cloud pelo MCP do Studio (criar produtos).

**Spec:** `docs/superpowers/specs/2026-11-18-presentes-design.md`

## Global Constraints

- Branch `ui-ajustes`, worktree `.worktrees/monetizacao` (é ela que o Rojo do Studio serve). Verificação: `bash scripts/check.sh` (StyLua, selene, Rojo, luau-lsp, Lune) tem de terminar com `N passed, 0 failed`.
- Server Authority: o cliente só pede; o servidor confere, cobra e entrega.
- Nada de atributo novo no `Player` (limite de ~1 KB); estado novo vai no perfil (`data.Shop`) e na pasta `Player.Shop` só se for pequeno.
- Textos em `src/shared/Strings/ptBR.luau`; nenhum texto nas artes.
- Celular: tela cabe em 749×330 sem rolar; a lista de jogadores pode rolar com a barra visível. PC intacto.
- VIP (`vip_30d`) e revive (`revive_*`) **não** são presenteáveis; giro normal (Golden Ember) também não (não está em `RobloxIds.GIFT`).
- Giros e pacotes com giros: recusados se `ShopService.randomBlocked` de **quem paga ou de quem recebe** for true.
- Item de uma vez que quem recebe já tem na entrega → Golden Ember = `math.floor(robux * 3.75 + 0.5)`.
- Arquivos editados por Python no Windows: abrir com `newline=''` (o repo é LF).
- Ids das artes (de `assets/ui/presentes/*.model.json`):
  45 ícone `rbxassetid://96738139747983` · 46 laço `rbxassetid://116391810918683` · 47 janela `rbxassetid://114195747576252` (1000×700, Slice 60,60,940,640) · 48 linha normal `rbxassetid://103763320529638` / selecionada `rbxassetid://88490061554704` / apagada `rbxassetid://83371964058561` (700×110, Slice 26,26,674,84) · 49 moldura `rbxassetid://116900478087271` · 50 marca `rbxassetid://120551909763558` · 51 caixa fechada `rbxassetid://91976544732836` · 52 caixa aberta `rbxassetid://127942085655500` · 53 painel `rbxassetid://88798671009225` (800×600, Slice 52,52,748,548) · 54 raios `rbxassetid://123743852967589` · 55 lista vazia `rbxassetid://83385295410199`.

## Review Focus

1. **Quem recebe sai do servidor entre a escolha e o pagamento** → o presente vai por `ProfileStore:MessageAsync` e aparece quando ele voltar (Task 4: teste manual no Studio + caminho coberto no `GiftService`).
2. **Recibo reprocessado** (servidor caiu depois de entregar e antes do `PurchaseGranted`) → quem recebe não ganha duas vezes: `ShopData.rememberGift` recusa o mesmo `PurchaseId` (Task 1, teste `rememberGift ignores a repeated purchase id`).
3. **Duas janelas Presentear para o mesmo item e pessoas diferentes** → o pendente é por produto e o último vence; o recibo entrega para o destinatário gravado no momento do pedido do prompt que pagou (Task 4: o pedido grava antes do prompt; Task 1 teste `setGiftPending replaces the previous recipient`).
4. **Jogador sozinho no servidor / presenteando a si mesmo** → lista vazia com o ícone 55; o servidor recusa `RecipientUserId == player.UserId` (Task 1 teste `cannot gift to yourself`).
5. **Presente chegando no meio da luta** → só aviso (`Notifications`), sem modal; a caixa espera o menu (Task 6, teste manual).

---

### Task 1: Regras puras e dados do perfil

**Files:**
- Create: `src/shared/Shop/GiftRules.luau`
- Modify: `src/shared/Shop/ShopData.luau` (tipo + `empty` + funções novas)
- Modify: `src/shared/Shop/RobloxIds.luau` (tabela `GIFT` vazia por ora + `fromProduct` com 2º retorno)
- Test: `tests/giftrules.spec.luau`, `tests/shopdata.spec.luau`, `tests/robloxids.spec.luau`

**Interfaces:**
- Produces:
  - `ShopData` ganha `GiftPending: { [string]: { to: number, name: string } }`, `GiftInbox: { { from: string, productId: string } }`, `GiftIds: { string }` (no `empty()`: `{}`, `{}`, `{}`).
  - `ShopData.setGiftPending(d, productId: string, toUserId: number, toName: string)`, `ShopData.takeGiftPending(d, productId: string): { to: number, name: string }?` (lê e apaga), `ShopData.rememberGift(d, purchaseId: string): boolean` (false se já estava; guarda no máximo 100, tira o mais velho), `ShopData.pushInbox(d, from: string, productId: string)`, `ShopData.popInbox(d): { from: string, productId: string }?` (tira o primeiro).
  - `GiftRules.giftable(productId: string): boolean` = `RobloxIds.GIFT[productId] ~= nil`.
  - `GiftRules.check(product: Product?, recipient: ShopData, now: number, payerBlocked: boolean, recipientBlocked: boolean, selfGift: boolean): GiftRules.Refusal?` com `Refusal = PurchaseRules.Refusal | "self" | "notGiftable"`; ordem: nil/hidden → "unknown"; `selfGift` → "self"; não presenteável → "notGiftable"; giros com `payerBlocked or recipientBlocked` → "restricted"; o resto = `PurchaseRules.check(product, recipient, now, math.huge, false)`.
  - `GiftRules.emberFallback(robux: number): number` = `math.floor(robux * 3.75 + 0.5)`.
  - `GiftRules.alreadyHas(product: Product, d: ShopData): boolean` = `PurchaseRules.check(product, d, now, math.huge, false) == "bought"` ignorando datas (use `product.startsAt or 0` como now).
  - `RobloxIds.GIFT: { [string]: number }` (vazia nesta task); `RobloxIds.fromProduct(robloxId: number): (string?, boolean)` — 2º valor true quando é id de presente.

- [ ] **Step 1: Testes que falham** em `tests/giftrules.spec.luau` (use um `GIFT` injetado: exponha `GiftRules._setGiftable(set: { [string]: boolean }?)` só para teste, nil volta ao `RobloxIds.GIFT`):
  - `cannot gift to yourself`: `check(pack_300, empty, 0, false, false, true) == "self"`.
  - `vip and revive are not giftable`: com `_setGiftable({ pack_300 = true })`, `check(Products.get("vip_30d"), ...) == "notGiftable"`; `revive_1` → `"unknown"` (é hidden).
  - `spins blocked for payer or recipient`: `spins_paid_3` com `(true,false)` e `(false,true)` → `"restricted"`; `(false,false)` → nil.
  - `recipient who owns a forever kit refuses`: perfil com `KitsOwned.kit_veteran = true` → `check(kit_kit_veteran, ...) == "bought"`.
  - `ember fallback rounds by the 300 pack`: `emberFallback(80) == 300`, `emberFallback(399) == 1496`.
  - Em `tests/shopdata.spec.luau`: `rememberGift ignores a repeated purchase id` (2ª chamada false), `rememberGift keeps 100` (101 ids → `#d.GiftIds == 100` e o 1º saiu), `setGiftPending replaces the previous recipient` (to 1 depois to 2 → `takeGiftPending` dá 2 e a 2ª leitura dá nil), `inbox is first in first out`.
  - Em `tests/robloxids.spec.luau`: `gift ids map back with the gift flag` (com um id de produto normal o 2º retorno é false).
- [ ] **Step 2:** `bash scripts/check.sh` → FAIL (GiftRules não existe).
- [ ] **Step 3:** implementar as funções acima; `ShopData.clean` não mexe nos campos novos.
- [ ] **Step 4:** `bash scripts/check.sh` → `0 failed`.
- [ ] **Step 5:** commit `feat(presentes): regras e dados do perfil dos presentes`.

### Task 2: Os 22 produtos "Presente: X" no Roblox

**Files:**
- Create: `assets/ui/presentes/capas/presente_<productId>_512.png` (22, gerados)
- Modify: `src/shared/Shop/RobloxIds.luau` (preencher `GIFT`; cabeçalho: tirar "TODOS FORA DE VENDA", dizer que a venda é ligada no Creator Hub ou pela API)
- Modify: `tests/robloxids.spec.luau`

**Interfaces:**
- Consumes: Task 1 (`RobloxIds.GIFT`, `fromProduct`).
- Produces: `RobloxIds.GIFT` com exatamente estas 22 chaves: `kit_kit_starter, kit_kit_explorer, kit_kit_survivor, kit_kit_veteran, pass_ember2x, pass_book, pack_300, pack_600, pack_2600, pack_7000, pack_20000, spins_paid_1, spins_paid_3, spins_paid_10, kitonce_kit_starter, kitonce_kit_explorer, kitonce_kit_survivor, kitonce_kit_veteran, xpboost_1h, bundle_mar, bundle_gelo, bundle_floresta`.

- [ ] **Step 1: Teste que falha** `every giftable item has a gift product`: as 22 chaves acima existem em `GIFT`, nenhuma de `vip_30d`/`revive_*`, e nenhum id de `GIFT` repete id de `PRODUCT`/`GAME_PASS`.
- [ ] **Step 2:** `bash scripts/check.sh` → FAIL.
- [ ] **Step 3:** gerar as capas com Pillow (Python 3.11 da Store, sem `-I`, rodando do scratchpad): ícone do item que o produto normal já usa (`assets/ui/monetizacao/creator-hub/gamepass_kit_*_512.png`, `22_…`, `23_…`, `assets/ui/loja/golden-ember/pacote_N.png` / `giro_N.png`, `28_produto_kit_uma_vida…` → use as capas dos kits, `28_produto_boost_xp_512.png`, `28_produto_golden_ember_512.png` para os pacotes) + laço `46_laco_canto.png` colado por cima no canto de cima à direita, 512×512.
- [ ] **Step 4:** criar os 22 com `open_cloud_invoke` `POST /developer-products/v2/universes/10773601314/developer-products` (scope `developer-product:write`), `name = "Presente: <nome>"` (nomes de `Strings`: "Presente: Kit Veterano", "Presente: 300 Golden Ember", "Presente: 3 Giros especiais", "Presente: Kit Veterano (1 vida)", "Presente: Boost de XP (1 h)", "Presente: Pacote Mar"...), `price` = o do produto normal, `isForSale = "true"`, `description` = a do produto normal + " (de presente para outro jogador)". Se o `isForSale=true` for bloqueado, criar com `"false"` e anotar para o Elizeu ligar no Creator Hub. Gravar os `productId` em `GIFT`.
- [ ] **Step 5:** `bash scripts/check.sh` → `0 failed`; commit `feat(presentes): 22 produtos de presente no Roblox`.

### Task 3: DataService — mensagens do ProfileStore e save com espera

**Files:**
- Modify: `src/server/Services/DataService.luau`

**Interfaces:**
- Produces:
  - `DataService.messageAsync(userId: number, message: { [string]: any }): boolean` — `store:MessageAsync(DataConfig.KEY_PREFIX .. userId, message)` em `pcall`; false se falhar.
  - `DataService.onMessage(listener: (player: Player, message: { [string]: any }) -> boolean)` — no `loadProfile`, depois de `profiles[player] = profile`, `profile:MessageHandler(function(message, processed) ... end)`: chama os ouvintes (sem `task.spawn`, protegido por `pcall`); se algum devolver true, `processed()`.
  - `DataService.saveAsync(player: Player): boolean` — grava já e espera o próximo `OnAfterSave` (até `profile:IsActive()` cair → false). Mesmo cast `(profile.OnAfterSave :: any):Wait()` do `receiptAsync`.

- [ ] **Step 1:** implementar (sem teste Lune: depende do ProfileStore; o teste é o da Task 7).
- [ ] **Step 2:** `bash scripts/check.sh` → `0 failed`; commit `feat(dados): mensagens entre perfis e save com espera`.

### Task 4: GiftService no servidor + rede

**Files:**
- Create: `src/server/Services/GiftService.luau`
- Modify: `src/server/Services/RobuxService.luau` (recibo e cancelamento de presente)
- Modify: `src/server/Services/ShopService.luau` (expor entrega num jogador qualquer)
- Modify: `net/game.blink`
- Modify: `src/shared/Strings/ptBR.luau`

**Interfaces:**
- Consumes: Task 1 (GiftRules, ShopData), Task 2 (`RobloxIds.GIFT`), Task 3 (`messageAsync`, `onMessage`, `saveAsync`), `RobuxService`, `ShopService.grant`, `ShopService.randomBlocked`, `DataService.receiptAsync`.
- Produces:
  - Blink: `event RequestGift { From: Client, ..., Data: struct { ProductId: string(1..48), RecipientUserId: f64 } }`; `event GiftResult { From: Server, ..., Data: struct { ProductId: string(1..48), Ok: boolean, Reason: string(1..16)?, To: string(0..40)? } }`; `event GiftInbox { From: Server, ..., Data: struct { Gifts: GiftEntry[] } }` com `struct GiftEntry { From: string(0..40), ProductId: string(1..48) }`; `event RequestOpenGift { From: Client, ..., Data: struct { ProductId: string(1..48) } }` (abre o primeiro da fila se o `ProductId` bate). Todos `Type: Reliable, Call: SingleAsync`.
  - `ShopService.deliverTo(player: Player, productId: string, reason: string): boolean` — entrega as recompensas do produto no perfil de `player` (sem disparar `PurchaseResult`), marca o "uma vez", publica; se `GiftRules.alreadyHas` → dá `GiftRules.emberFallback(product.price.amount)` de Golden Ember; false sem perfil. `deliver` (compra normal) passa a usar `deliverTo` + o `PurchaseResult`.
  - `RobuxService.onGift(handler: (payer: Player, productId: string, purchaseId: string) -> ())` e `RobuxService.onGiftCancelled(handler: (payer: Player, productId: string) -> ())`; `RobuxService.promptGift(player: Player, productId: string): boolean` (`PromptProductPurchase` com `RobloxIds.GIFT[productId]`). No `processReceipt`, `fromProduct` com flag de presente → `receiptAsync(payer, purchaseId, function() giftHandler(payer, productId, purchaseId) end)`; no `onProductFinished` de presente não comprado → `giftCancelHandler` (sem o `PurchaseResult` "cancelled" normal).
  - `GiftService`: `RequestGift` (throttle 0,3 s como o ShopService) → valida com `GiftRules.check` (recipient pelo `Players:GetPlayerByUserId`, perfis dos dois carregados; senão Reason `"gone"`) → `ShopData.setGiftPending` no pagador → `DataService.saveAsync(payer)` → `RobuxService.promptGift`. Recusa → `GiftResult { Ok = false, Reason }`.
  - Entrega (`onGift`): `pending = ShopData.takeGiftPending(payerShop, productId)`; sem pendente → `ShopService.deliverTo(payer, ...)` + `warn`. Destinatário no servidor com perfil: se `ShopData.rememberGift(recipientShop, purchaseId)` → `deliverTo(recipient, ...)` + `pushInbox(recipientShop, payer.DisplayName, productId)` + `DataService.saveAsync(recipient)` (false → `error`, para o recibo voltar) + envia `GiftInbox` a ele; senão (saiu) → `DataService.messageAsync(pending.to, { kind = "gift", productId, from = payer.DisplayName, purchaseId })` (false → `error`). Sempre: `GiftResult { Ok = true, To = pending.name }` ao pagador.
  - `onMessage`: `kind == "gift"` → `rememberGift` + `deliverTo` + `pushInbox` + `DataService.save` + `GiftInbox`; devolve true.
  - Ao carregar o perfil e depois de cada mudança: `GiftInbox` com a fila inteira. `RequestOpenGift` → `popInbox` se bate, `DataService.save`, novo `GiftInbox`.
  - Cancelado → `takeGiftPending`, `DataService.save`, `GiftResult { Ok = false, Reason = "cancelled" }`.
  - Strings novas: `gift.result.sent` ("Presente enviado para {name}!"), `gift.result.self`, `gift.result.gone` ("Este jogador saiu"), `gift.result.bought` ("Ele já tem isso"), `gift.result.restricted` ("Indisponível para este jogador"), `gift.result.notGiftable`, `gift.result.cancelled`, `gift.result.error`.

- [ ] **Step 1:** Blink + `GiftService` + mudanças no `RobuxService`/`ShopService` (a entrega de produto normal continua igual: rode os testes atuais).
- [ ] **Step 2:** `bash scripts/check.sh` → `0 failed` (o Blink regenera `src/*/Net.luau`).
- [ ] **Step 3:** commit `feat(presentes): pedido, entrega e caixa de entrada no servidor`.

### Task 5: Janela Presentear e botões de presente na loja

**Files:**
- Create: `src/shared/GiftImages.luau` (ids e slices da seção Global Constraints)
- Create: `src/client/Menu/Shop/GiftPanel.luau`
- Modify: `src/client/Menu/Shop/ShopParts.luau` (`ShopParts.giftButton`)
- Modify: `Passes.luau`, `EmberPacks.luau`, `SpinScreen.luau` (só compra paga), `Featured.luau`, `BoostCard.luau`, `src/client/Menu/KitShop.luau`
- Modify: `src/client/Menu/Shop/ShopScreen.luau` ou `MenuShell.luau` (montar o `GiftPanel` por cima da loja)
- Modify: `src/client/Menu/Purchase.luau` (receber `GiftResult`)
- Modify: `src/shared/Strings/ptBR.luau`

**Interfaces:**
- Consumes: Task 4 (`RequestGift`, `GiftResult`), `GiftRules.giftable`, `GiftRules.alreadyHas`, pastas `Player.Shop` dos outros jogadores (`KitsOwnedFolder`, `PassesFolder`, `PurchasedFolder`, atributo `PaidRandomBlocked`).
- Produces: `GiftPanel.open(productId: string)` (fonte Vide `GiftPanel.current: Source<string?>`); `GiftPanel.build(): Frame`; `ShopParts.giftButton(productId: string, props: { [any]: any }): GuiButton` (ícone 45, some quando `not GiftRules.giftable(productId)` ou quando é giro e o próprio `PaidRandomBlocked` é true).
- Janela: moldura 47 (slice), título "Presentear", ícone do item com laço 46 no canto, lista (`ScrollingFrame` com barra visível) de `Players:GetPlayers()` menos o local, atualizada no `PlayerAdded/Removing`; linha 48 normal/selecionada/apagada, foto `Players:GetUserThumbnailAsync(userId, HeadShot, Size100x100)` na moldura 49, marca 50 na selecionada, "Já tem"/"Indisponível" nas apagadas; vazia → ícone 55 + "Ninguém para presentear"; botões "Cancelar" (madeira) e verde com ícone 45 + preço (`ShopParts.priceButton`) que envia `RequestGift` e fecha. Fecha só nos botões (como o check-in).
- `Purchase.luau`: `GiftResult` Ok → `MenuState.notify(Strings.format("gift.result.sent", { name = To }))`; recusa → `gift.result.<Reason>` (cai em `gift.result.error`).

- [ ] **Step 1:** implementar; conferir no Studio (PC e emulador 749×330) a janela com 0, 1 e 6 jogadores (2 jogadores pelo Test → Players; 6 dá para simular com linhas falsas só no teste visual, sem commitar).
- [ ] **Step 2:** `bash scripts/check.sh` → `0 failed`; commit `feat(presentes): janela Presentear e botões de presente`.

### Task 6: Pop-up do presente recebido

**Files:**
- Create: `src/client/Menu/GiftPopup.luau`
- Modify: `src/client/Menu/MenuShell.luau` (montar)
- Modify: `src/shared/Strings/ptBR.luau`

**Interfaces:**
- Consumes: Task 4 (`GiftInbox`, `RequestOpenGift`), Task 5 (`GiftImages`), `ScreenState.current()`, `Notifications.push`, `RewardView.text` / ícones que a loja já usa por produto.
- Produces: `GiftPopup.build(): Frame`.
- Comportamento: guarda a fila do `GiftInbox`. Fora do menu: cada presente novo vira `Notifications.push("gift.toast", { name, item })` uma vez, sem modal. No menu e com fila: painel 53 com a caixa fechada 51 ("Fulano te mandou um presente!" + "Toque para abrir"); toque → caixa aberta 52, raios 54 (tingidos de dourado, girando devagar, só com o painel aberto), ícone do item subindo de dentro da caixa, nome do item, botão "Obrigado!" → `RequestOpenGift { ProductId }` e próximo da fila. Não abre por cima do check-in nem do pop-up do tutorial (espera eles fecharem). Cabe em 749×330.

- [ ] **Step 1:** implementar; conferir no Studio com 2 jogadores (presente no menu, presente jogando, dois presentes em fila).
- [ ] **Step 2:** `bash scripts/check.sh` → `0 failed`; commit `feat(presentes): caixa do presente recebido`.

### Task 7: Teste conjunto no Studio, guia e grafo

**Files:**
- Modify: `docs/guia/loja.md` (seção "Presentes": o fluxo, `RobloxIds.GIFT`, item novo presenteável = produto "Presente: X" novo, regra dos giros, conversão em Golden Ember)
- Modify: `docs/pendencias.md` (o que não deu para testar)

- [ ] **Step 1:** Studio, Test → Players: 2 (os produtos precisam estar à venda): dar kit para sempre; dar Golden Ember; cancelar; "Já tem"; destinatário sai antes de pagar (presente chega ao voltar); presente jogando vira aviso e a caixa espera o menu.
- [ ] **Step 2:** guia e pendências; `& (Get-Content ..\..\graphify-out\.graphify_python) -m graphify update .` (PowerShell, na worktree).
- [ ] **Step 3:** `bash scripts/check.sh` → `0 failed`; commit `docs(presentes): guia da loja e pendências`.
