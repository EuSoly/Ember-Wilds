# Loja de verdade (pacotes, giros, kits, Golden Ember)

Desde 09/11/2026 a Loja e os kits por Robux **funcionam de verdade**: o servidor confere, entrega e salva no perfil. Só uma coisa ainda não é real: **o Robux não é cobrado**. Tudo que custa Robux é entregue de graça, no jogo aberto. Antes de ligar a cobrança, o plano é zerar todos os perfis (veja `docs/pendencias.md`). O que custa **Golden Ember** (o giro normal) desconta de verdade.

Design: `docs/superpowers/specs/2026-11-09-loja-funcional-design.md`.

## Como funciona

Tudo que se compra é um **produto**: um id, um preço (`robux` ou `ember`), um limite (`once` = uma vez por jogador), datas opcionais e a lista de **recompensas** que ele entrega.

| Produto | Id | Preço | Limite |
|---|---|---|---|
| Pacote em destaque | `bundle_<id>` | Robux | uma vez |
| Pacote de Golden Ember | `pack_<quantidade>` | Robux | sem limite |
| Giros normais | `spins_normal_<qtd>` | Golden Ember | sem limite |
| Giros especiais | `spins_paid_<qtd>` | Robux | sem limite |
| Kit de 1 vida | `kitonce_<kit>` | Robux | sem limite (soma no saldo do kit) |
| Kit para sempre | `kit_<kit>` | Robux | uma vez |
| Passe (2× Golden Ember, Livro) | `pass_<passe>` (`ember2x`, `book`) | Robux | uma vez |
| VIP por 30 dias | `vip_30d` | Robux | sem limite (soma ao renovar) |
| Boost de XP (+1 h) | `xpboost_1h` | Robux | sem limite (soma) |
| Degraus do revive | `revive_1`…`revive_4` | Robux | escondido (só o `ReviveService` usa; veja `revive.md`) |

1. O cliente só **pede** (`Net.RequestPurchase { ProductId }`).
2. O servidor (`ShopService.purchase`) ignora pedido rápido demais (0,3 s), confere com `PurchaseRules.check` (produto existe, está na data, não foi comprado se é `once`, tem Golden Ember), **cobra** (`ShopService.charge`: Robux = grátis por enquanto) e **entrega cada recompensa** (`ShopService.grant`). Depois marca a compra `once`, republica e salva.
3. A resposta vai só para quem comprou (`Net.PurchaseResult`) e vira o aviso do menu ("Comprado!", "Golden Ember insuficiente"…).

### Giros e roleta

Os giros são **dois saldos**, `normal` e `paid` (especial), que servem em **qualquer roleta** (Skins, Mochila, Livro, Caixa). GIRAR manda `Net.RequestSpin { TypeId, Paid }`. O servidor confere o saldo, desconta 1, sorteia (`Shop/SpinRoll`, com as chances de `ShopConfig.SPIN_ODDS`) entre as skins da roleta e entrega a skin. Se o jogador **já tem** a skin, ele recebe Golden Ember no lugar (`ShopConfig.DUPLICATE_REFUND`: 50 no normal, 150 no especial). O cliente anima o carrossel até o prêmio que o servidor mandou (`Net.SpinResult`); os efeitos e os sons do giro (impulso, tiques, suspense, destaque do prêmio e comemoração por raridade) estão em `telas.md`, na Loja, e em `sons.md`, "Sons da roleta".

### Kits

- **Pontos** (como antes): os pontos da última vida pagam o kit.
- **1 vida (Robux):** cada compra soma 1 no **saldo daquele kit**. Com saldo, o painel mostra **Usar** (como o do kit para sempre), o número de usos no canto ("×3") e um **+** que troca o Usar pelas opções de compra. Nascer com ele gasta 1.
- **Para sempre (Robux):** a posse fica salva; **Usar** ativa (vem em toda vida), **Ativo** desativa.
- **Qual vai:** o jogador escolhe o kit e de onde ele sai (pontos ou saldo). Sem escolha, vem o kit para sempre ativo. Um kit por vida (`UIFlow/KitChoice`, igual no cliente e no servidor).

### Posse: a verdade é o perfil

Kits para sempre e passes valem pelo que está **no perfil** (`Shop.KitsOwned`, `Shop.Passes`), não pelo histórico de compras. Comprou, ganhou num pacote ou de presente: está lá. Tiraram: some, e o kit volta a poder ser comprado. `Shop.Purchased` só serve para os pacotes (cada jogador compra uma vez). Ao carregar, `ShopData.clean` apaga marcas que não sejam `true`.

**Dar ou tirar (Studio, barra de comandos do servidor):**

```lua
local SS, p = game.ServerStorage, game.Players:GetPlayers()[1]
SS.DevShopGrant:Invoke(p, { kind = "kit", id = "kit_veteran" })          -- kit para sempre
SS.DevShopGrant:Invoke(p, { kind = "kitOnce", id = "kit_starter", count = 3 }) -- 3 usos de 1 vida
SS.DevShopGrant:Invoke(p, { kind = "spins", spin = "paid", count = 5 })    -- giros especiais
SS.DevShopRevoke:Invoke(p, "kit", "kit_veteran")                            -- tira o kit para sempre
SS.DevShopReset:Invoke(p)                                                    -- zera a loja do perfil
```

No jogo, presentes e códigos de resgate devem entregar por `ShopService.give(player, recompensa, motivo)` (valida, entrega, publica e salva).

### VIP, passes e Premium

| Vantagem | Preço | O que dá |
|---|---|---|
| **VIP** (`vip_30d`) | 99 Robux por 30 dias | +3 espaços (`InventoryConfig.vipPass.bonusSlots`), ícone ao lado do nome, **Kit VIP** (`kit_vip`), +0,5 no multiplicador de Golden Ember e **1 revive grátis por corrida** |
| **2× Golden Ember** (`ember2x`, passe) | 199 Robux, uma vez | +1 no multiplicador |
| **Livro** (`book`, passe) | 99 Robux, uma vez | nasce com o livro de receitas |
| **Premium** do Roblox | (do Roblox) | +0,2 no multiplicador e libera o `kit_starter` enquanto for Premium; **não grava no perfil** |

O VIP é por tempo: a recompensa `{ kind = "vip", count = dias }` soma `count` dias em `Shop.VipUntil` (unix; comprar com o VIP ativo soma ao que resta). Hoje é um produto de Robux comum (`vip_30d`); a assinatura de verdade vem na fase 9 (`docs/pendencias.md`). O passe `vip` antigo saiu de `ShopConfig.PASSES`.

O `PerkService` tira uma **foto das vantagens quando a vida começa** (VIP, `ember2x`, `book`, Premium) e ela vale até o fim daquela vida, inclusive na tela de morte e no revive. Ganhar uma vantagem com a vida ativa vale na hora; perder (VIP vencido, `DevShopRevoke`) só na próxima vida. A regra pura é `Shared/Shop/Perks` (testada no Lune).

**Onde o cliente lê:** atributos da pasta `Player.Shop` (não do Player, por causa do limite de ~1 KB de atributos): `Perk_vip`, `Perk_ember2x`, `Perk_book`, `Perk_premium` (a foto da vida com vida ativa; o que vale agora quando morto ou no menu), `VipUntil`, `XpBoostStart`, `XpBoostUntil` (do perfil), `CheckInDay`, `CheckInReady` e `PaidRandomBlocked`. Os nomes estão em `StatNames`; o `src/client/ShopData.luau` lê tudo.

### Golden Ember sem teto

No fim da vida: `floor(pontos / 1000 × multiplicador)` (`CurrencyRules.pointsToCurrency`), **sem teto por vida nem por hora**. O multiplicador é **1 + bônus somados** (`Perks.emberMultiplier`, números em `ShopConfig.PERK_BONUS`):

| Vantagem | Bônus |
|---|---|
| (base) | 1 |
| 2× Golden Ember | +1 |
| VIP | +0,5 |
| Premium | +0,2 |

Tudo junto: **2,7**. Só vale no fim de vida; prêmios fixos (missão, check-in, devolução de skin repetida) **não** são multiplicados. A tela de morte mostra uma etiqueta por vantagem (`LifeEnded.EmberBonus`: bits 1 = 2×, 2 = VIP, 4 = Premium). O risco de farm de abates entre amigos sem o teto está em `docs/pendencias.md`.

### Boost de XP

`xpboost_1h` (49 Robux, `ShopConfig.XP_BOOST`) soma 1 hora em `Shop.BoostStart` / `BoostUntil`. O XP da vida dobra **na proporção da vida que aconteceu dentro da janela** (`Data/XpBoost.factor`, de 1 a 2; boost cobrindo metade da vida dá 1,5×) e o teto de XP por hora dobra junto (`LifeService.endLife`). O **ranking soma o XP sem boost**. O cliente mostra o selo `XpBoostBadge` e o cartão `Menu/Shop/BoostCard`.

### Check-in de 7 dias

Prêmios em `ShopConfig.CHECKIN` (dia 1 a 7: 100 Golden Ember, 1 giro normal, 150 Golden Ember, Kit Explorador de 1 vida, 200 Golden Ember, 2 giros normais, 5 giros especiais). Um prêmio por **dia de Brasília** (`RankRules.dayIndex`), não precisa ser em sequência, e depois do 7 volta ao 1. O cliente só pede (`Net.CheckInClaim`); o `CheckInService.claim` confere o dia (`Shared/Shop/CheckInRules`, puro), entrega por `ShopService.give` e salva (`Shop.CheckIn = { Day, LastDay }`). Na virada do dia o serviço republica `CheckInReady` para quem está com o jogo aberto. Tela: `src/client/Menu/CheckInPanel.luau`.

### Item aleatório pago

As **chances ficam visíveis antes de comprar** (`SPIN_ODDS`). Onde a lei proíbe item aleatório pago, não se compram giros (normal e especial) nem pacotes com giros: o `ShopService` consulta `PolicyService:GetPolicyInfoForPlayerAsync` ao carregar o perfil e guarda `randomBlocked` por jogador (`ArePaidRandomItemsRestricted ~= false`, ou **consulta que falhou ou ainda sem resposta = bloqueado**). O `PurchaseRules.check` recusa com `"restricted"` e publica `PaidRandomBlocked` na pasta `Player.Shop`; a loja esconde o que tem giros. **Giros ganhos de graça** (check-in, prêmios, devolução) continuam valendo.

**Dar ou tirar o resto (Studio):** `DevShopGrant` aceita qualquer recompensa (`Rewards.KINDS`), por exemplo:

```lua
SS.DevShopGrant:Invoke(p, { kind = "vip", count = 30 })           -- VIP por 30 dias
SS.DevShopGrant:Invoke(p, { kind = "pass", id = "ember2x" })      -- passe (ou "book")
SS.DevShopGrant:Invoke(p, { kind = "xpBoost", count = 3600 })     -- boost de XP (segundos)
SS.DevShopGrant:Invoke(p, { kind = "reviveCredit", count = 2 })   -- revives guardados
SS.DevShopRevoke:Invoke(p, "vip")                                  -- tira o VIP (vale na próxima vida)
SS.DevShopRevoke:Invoke(p, "pass", "ember2x")                      -- tira um passe
```

O `DevShopGrant` já chama `PerkService.refresh`. Não há comando para forçar Premium nem o `PolicyService` (no Studio a consulta pode falhar e deixar o jogador bloqueado).

## Como criar um pacote

Edite **`src/shared/Shop/Bundles.luau`**: uma entrada por pacote, na ordem do carrossel.

```lua
{
	id = "outono",                     -- único; vira o produto "bundle_outono"
	nameKey = "shop.bundle.outono",    -- texto em Strings/ptBR.luau
	theme = "#C8641E",                 -- cor do card
	rarity = 4,                        -- moldura: 1 Comum … 5 Mítico
	robux = 299,                       -- preço (ainda não é cobrado)
	startsAt = "2026-11-20 18:00",     -- horário de Brasília; sem = já começou
	endsAt = "2026-11-27 18:00",       -- sem = não acaba
	rewards = {
		{ kind = "cosmetic", id = "body_cervo" },
		{ kind = "ember", amount = 500 },
		{ kind = "spins", spin = "paid", count = 2 },          -- "normal" ou "paid" (especial)
		{ kind = "kit", id = "kit_explorer" },                -- kit para sempre
		{ kind = "kitOnce", id = "kit_survivor", count = 3 }, -- saldo de 1 vida
	},
},
```

Depois:

1. O nome em `src/shared/Strings/ptBR.luau`: `["shop.bundle.outono"] = "Pacote Outono",`.
2. Opcional: um fundo de card com a cor do tema em `BUNDLE_ART` (`src/client/Menu/Shop/Featured.luau`); sem ele, o card usa um degradê.
3. **`bash scripts/check.sh`**. Ele recusa: id repetido ou com caractere inválido, nome sem texto, cor fora de `#RRGGBB`, raridade fora de 1–5, preço não inteiro, data fora do formato `"AAAA-MM-DD HH:MM"`, fim antes do começo, pacote sem recompensas e recompensa errada (skin ou kit que não existe, quantidade que não é inteira ≥ 1, tipo desconhecido).

A loja mostra só os pacotes **dentro da data**, com o contador até o fim. Cada jogador compra um pacote **uma vez**; depois o botão mostra "Comprado". Skin que ele já tem é pulada e o resto entra.

**Mudar um pacote que já está no ar:** pode mudar preço, datas, cores e recompensas. Não mude o `id`: ele marca quem já comprou (`Shop.Purchased`).

## Como criar um tipo de item de pacote

Hoje existem `cosmetic`, `ember`, `spins`, `kit`, `kitOnce`, `pass`, `vip`, `xpBoost` e `reviveCredit`. Para criar outro (um título, um item de jogo…), mexa em **três lugares**:

1. **`src/shared/Shop/Rewards.luau`**, em `KINDS`: os campos válidos (a função `validate` devolve a mensagem de erro, ou `nil`). Roda no boot e nos testes. Se for algo "para sempre", acrescente também `owned` (o jogador já tem?): assim a loja não vende de novo o que ele ganhou por outro caminho.
2. **`src/server/Services/ShopService.luau`**, em `GRANTS`: como entregar (recebe o jogador, os dados da loja do perfil e a recompensa).
3. **`src/client/Menu/Shop/RewardView.luau`**: o texto na lista do card (`text`) e, se tiver figura, a peça da prévia (`tile`).

Compra, checagem dos pacotes e telas usam esse registro e não precisam mudar. Acrescente um caso nos testes de `tests/shopcatalog.spec.luau`.

`ShopService.grant(player, reward, reason)` é público: os **códigos de resgate** do futuro podem entregar qualquer recompensa por ele.

## Onde mudar preços e chances

Tudo em **`src/shared/Shop/ShopConfig.luau`**:

| O quê | Campo |
|---|---|
| Chances da roleta (normal / especial) | `SPIN_ODDS` |
| Devolução da skin repetida | `DUPLICATE_REFUND` |
| Pacotes de giros (+1/+3/+10) | `SPIN_PACKS` |
| Pacotes de Golden Ember | `EMBER_PACKS` |
| Preço dos kits (1 vida / para sempre) | `KIT_ROBUX` (todo kit de `Defs.Kits` precisa de uma entrada) |
| Passes (2× Golden Ember, Livro) | `PASSES` |
| VIP (preço e dias) | `VIP` |
| Bônus de Golden Ember (2×, VIP, Premium) | `PERK_BONUS` |
| Degraus do revive | `REVIVE_ROBUX` |
| Boost de XP | `XP_BOOST` |
| Prêmios do check-in (7 dias) | `CHECKIN` |

## Onde fica cada coisa

| Arquivo | O que é |
|---|---|
| `src/shared/Shop/Bundles.luau` | Os pacotes em destaque (o arquivo para editar) |
| `src/shared/Shop/ShopConfig.luau` | Preços, chances, devolução |
| `src/shared/Shop/Products.luau` | Monta e valida todos os produtos (boot e testes) |
| `src/shared/Shop/Rewards.luau` | Tipos de recompensa e a validação de cada um |
| `src/shared/Shop/ShopData.luau` | Os dados da loja no perfil (`data.Shop`) |
| `src/shared/Shop/PurchaseRules.luau` | Pode comprar? (motivos da recusa) |
| `src/shared/Shop/SpinRoll.luau` | Sorteio de um giro |
| `src/shared/Shop/ShopDates.luau` | Datas em horário de Brasília |
| `src/shared/UIFlow/KitChoice.luau` | Qual kit vai na vida e de onde sai |
| `src/shared/Shop/Perks.luau` | Vantagens (VIP, passes, Premium), multiplicador e kits liberados |
| `src/shared/Shop/CheckInRules.luau` | Regras do check-in de 7 dias |
| `src/shared/Data/XpBoost.luau` | Fator do boost de XP |
| `src/shared/MonetizationImages.luau` | Ids das artes da monetização (vazio = desenho por código) |
| `src/server/Services/ShopService.luau` | Compra, giro, kits, `randomBlocked` (PolicyService) e a pasta `Player.Shop` |
| `src/server/Services/PerkService.luau` | Foto das vantagens por vida e atributos das vantagens |
| `src/server/Services/CheckInService.luau` | Resgate do check-in e virada do dia |
| `src/client/ShopData.luau` | Lê a pasta `Player.Shop` (fontes Vide para as telas) |
| `src/client/Menu/Purchase.luau` | Pede a compra e mostra a resposta |
| `src/client/Menu/Shop/RewardView.luau` | Como cada recompensa aparece no card |

Testes: `tests/shopdates.spec.luau`, `tests/shopcatalog.spec.luau`, `tests/spinroll.spec.luau`, `tests/shopdata.spec.luau`, `tests/kitchoice.spec.luau`, `tests/monetizationimages.spec.luau` (ids e fatias das artes), `tests/xpboost.spec.luau`, `tests/revive.spec.luau`.

## Ligar o Robux de verdade (depois)

1. Zerar todos os perfis (decisão do Elizeu).
2. Criar os produtos de desenvolvedor e gamepasses no site e guardar os ids junto dos produtos.
3. Trocar o `ShopService.charge` de Robux pelo `MarketplaceService:PromptProductPurchase` e entregar no `ProcessReceipt` (usando `PurchaseIdCache` do perfil para não entregar duas vezes), respondendo `PurchaseGranted` só depois que o perfil guardou.
4. Gamepasses (kits para sempre, `ember2x`, `book`): entregar pelo `UserOwnsGamePassAsync` / `PromptGamePassPurchaseFinished`.
5. VIP: virar **assinatura** do Roblox (status lido ao entrar; `Shop.VipUntil` acompanha). Revive: veja `docs/guia/revive.md` e a fase 9 em `docs/pendencias.md`.
