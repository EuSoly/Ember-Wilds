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
| Passe (VIP) | `pass_<passe>` | Robux | uma vez |

1. O cliente só **pede** (`Net.RequestPurchase { ProductId }`).
2. O servidor (`ShopService.purchase`) ignora pedido rápido demais (0,3 s), confere com `PurchaseRules.check` (produto existe, está na data, não foi comprado se é `once`, tem Golden Ember), **cobra** (`ShopService.charge`: Robux = grátis por enquanto) e **entrega cada recompensa** (`ShopService.grant`). Depois marca a compra `once`, republica e salva.
3. A resposta vai só para quem comprou (`Net.PurchaseResult`) e vira o aviso do menu ("Comprado!", "Golden Ember insuficiente"…).

### Giros e roleta

Os giros são **dois saldos**, `normal` e `paid` (especial), que servem em **qualquer roleta** (Skins, Mochila, Livro, Caixa). GIRAR manda `Net.RequestSpin { TypeId, Paid }`. O servidor confere o saldo, desconta 1, sorteia (`Shop/SpinRoll`, com as chances de `ShopConfig.SPIN_ODDS`) entre as skins da roleta e entrega a skin. Se o jogador **já tem** a skin, ele recebe Golden Ember no lugar (`ShopConfig.DUPLICATE_REFUND`: 50 no normal, 150 no especial). O cliente anima o carrossel até o prêmio que o servidor mandou (`Net.SpinResult`).

### Kits

- **Pontos** (como antes): os pontos da última vida pagam o kit.
- **1 vida (Robux):** cada compra soma 1 no **saldo daquele kit** ("3 guardados"). Nascer com ele gasta 1.
- **Para sempre (Robux):** a posse fica salva; **Usar** ativa (vem em toda vida), **Ativo** desativa.
- **Qual vai:** o jogador escolhe o kit e de onde ele sai (pontos ou saldo). Sem escolha, vem o kit para sempre ativo. Um kit por vida (`UIFlow/KitChoice`, igual no cliente e no servidor).

### VIP

O passe `vip` fica salvo no perfil e dá `InventoryConfig.vipPass.bonusSlots` (+3) espaços. O gamepass real (quando existir) continua funcionando pelo caminho antigo do `InventoryService`.

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

Hoje existem `cosmetic`, `ember`, `spins`, `kit`, `kitOnce` e `pass`. Para criar outro (um título, um item de jogo…), mexa em **três lugares**:

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
| Passes (VIP) | `PASSES` |

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
| `src/server/Services/ShopService.luau` | Compra, giro, kits e a pasta `Player.Shop` |
| `src/client/ShopData.luau` | Lê a pasta `Player.Shop` (fontes Vide para as telas) |
| `src/client/Menu/Purchase.luau` | Pede a compra e mostra a resposta |
| `src/client/Menu/Shop/RewardView.luau` | Como cada recompensa aparece no card |

Testes: `tests/shopdates.spec.luau`, `tests/shopcatalog.spec.luau`, `tests/spinroll.spec.luau`, `tests/shopdata.spec.luau`, `tests/kitchoice.spec.luau`.

## Ligar o Robux de verdade (depois)

1. Zerar todos os perfis (decisão do Elizeu).
2. Criar os produtos de desenvolvedor e gamepasses no site e guardar os ids junto dos produtos.
3. Trocar o `ShopService.charge` de Robux pelo `MarketplaceService:PromptProductPurchase` e entregar no `ProcessReceipt` (usando `PurchaseIdCache` do perfil para não entregar duas vezes), respondendo `PurchaseGranted` só depois que o perfil guardou.
4. Gamepasses (kits para sempre, VIP): entregar pelo `UserOwnsGamePassAsync` / `PromptGamePassPurchaseFinished`.
