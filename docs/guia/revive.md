# Revive (voltar da morte)

Ao morrer, o jogador pode **reviver na hora**: volta com **todos os itens** e vida e barras cheias. Hoje a cobrança em Robux **não é real** (entrega de graça, como o resto da loja); o que vale é o fluxo. Design: `docs/superpowers/specs/2026-11-17-monetizacao-design.md` (seção 4.6).

## Como funciona

1. **A oferta** aparece por cima do resumo da tela de morte (`src/client/UI/ReviveOffer.luau`): ícone, preço em Robux (ou a fita **GRÁTIS**), botão **REVIVER** e **Não, obrigado**. Sem contador na tela.
2. **A caixa cai trancada.** Enquanto a oferta está aberta, a caixa da morte não abre, não se pega nada e não leva dano (`CrateService.setLocked`). As peças construídas e o totem do time **ficam de pé** e o `real_deaths` espera.
3. **Limite escondido de 30 s** (`ReviveRules.DECISION_SECONDS`): passou, vale como "não". O tempo **pausa** durante uma compra do Roblox aberta ou pendente (até 60 s somados, `PURCHASE_PAUSE_MAX`); hoje ninguém pausa porque a cobrança é instantânea.
4. **Só a 1ª resposta vale:**
   - **Aceitar:** cobra, nasce, **tira a caixa do mundo**, devolve a foto do inventário e enche vida e barras. Os itens nunca duplicam: a caixa some antes de a foto voltar. Se o nascimento falhar, a cobrança volta (revive guardado, ou o grátis do VIP) e conta como "não".
   - **Recusar, o tempo acabar ou sair do jogo:** destranca a caixa para qualquer um, as peças somem e conta a morte de verdade (`DeathService.finalize`).
   - **Nascer pelo menu** com a oferta aberta também conta como "não".
5. **Volta** perto do **totem do time** (se está de pé) ou num **ponto aleatório da floresta**, longe da água, das áreas sem nascimento, das construções e de outros jogadores vivos (`SpawnService.reviveSpot`); sem mapa desenhado, no `WorldConfig.SPAWN`.
6. **3 s de proteção** (`ReviveRules.SHIELD_SECONDS`, atributo `SpawnShieldUntil` no Player).

Quem **não** vê a oferta (`ReviveRules.eligible`): modo criativo, vida de tutorial, perfil não carregado ou sem nenhum item (slots, mochila ou armadura).

## Preço

Os degraus ficam em `ShopConfig.REVIVE_ROBUX`: **25, 49, 99, 199** (para no 199). Contam da **entrada pelo menu até a morte final** (a "corrida"), e o grátis também ocupa degrau:

| Situação | Preço |
|---|---|
| Tem **revive guardado** (crédito no perfil, `Shop.ReviveCredits`) | grátis, gasta o crédito (vem primeiro) |
| **VIP**, ainda sem o grátis da corrida | grátis (1 por corrida); ocupa o degrau 1 |
| Senão | degrau `min(revives usados na corrida + 1, 4)`: 25, 49, 99, 199 |

A contagem e o grátis do VIP zeram quando o jogador **nasce pelo menu**, não no revive. O VIP vale pela foto da vida (`PerkService.forLife`).

**Revive guardado:** um pagamento confirmado depois que a janela fechou (ou um revive que falhou depois de cobrado) vira 1 crédito no perfil (`ReviveService.lateRevive`, recompensa `reviveCredit`). Nunca se paga sem receber.

## Quem fica com o abate

O abate de jogador vale na **hora da morte**, tenha revive ou não: o golpe final ou o **último que acertou nos últimos 10 s** (`CombatTag`/`LastAttacker`), se ainda está no jogo, ganha o bônus de pontos e o `players_killed` (`DeathService.kill`). Reviver não desfaz.

## Onde fica o código

| Arquivo | O que faz |
|---|---|
| `src/shared/Survival/ReviveRules.luau` | Regras puras: oferta e preço, janela de decisão, pausa, 1ª resposta, elegibilidade, proteção, bits do bônus de Golden Ember |
| `src/server/Services/ReviveService.luau` | Gancho da morte, cobrança, aceitar/recusar, tempo, crédito guardado, escudo |
| `src/server/Services/DeathService.luau` | `setReviveHook` (depois do fantasma, antes dos ouvintes) e `finalize` (peças somem, `real_deaths`) |
| `src/server/Services/CrateService.luau` | Caixa trancada (`setLocked`, `lastPlayerCrate`, `removeModel`) |
| `src/server/Services/SpawnService.luau` | `spawnAt`, `reviveSpot` e `onSpawned` (zera a corrida ao nascer pelo menu) |
| `src/server/Services/InventoryService.luau` + `src/shared/InventorySnapshot.luau` | `snapshot` e `restore` do inventário |
| `src/client/UI/ReviveOffer.luau` | A oferta na tela de morte |

Rede: `Net.RequestRevive { Accept }` (cliente → servidor), `Net.ReviveClosed { Revived }` e a oferta em `LifeEnded.Revive { Robux, Free }`. Preços e degraus ficam só em `ShopConfig`; o cliente nunca decide nada.

Testes no Lune: `tests/revive.spec.luau` (regras) e `tests/inventorysnapshot.spec.luau` (foto).

## Como testar no Studio

Não há comando de dev só do revive. Use a barra de comandos do servidor (Play):

```lua
local SS, p = game.ServerStorage, game.Players:GetPlayers()[1]
SS.DevGive:Invoke(p, { wood = 20 })                              -- precisa de algum item
SS.DevShopGrant:Invoke(p, { kind = "vip", count = 30 })          -- 1º revive grátis (vale na PRÓXIMA vida)
SS.DevShopGrant:Invoke(p, { kind = "reviveCredit", count = 1 })  -- revive guardado
SS.DevEndLife:Invoke(p)                                          -- morte de verdade: abre a oferta
```

Depois, na tela de morte: **REVIVER** (volta no totem ou na floresta, com os itens e 3 s de proteção), **Não, obrigado** (a caixa fica no chão, destrancada) ou esperar 30 s. Para ver os degraus, morra várias vezes sem pelo menu: 25, 49, 99, 199. `DevShopReset` zera crédito e VIP. Fora do teste: criativo e tutorial não mostram a oferta, e sem itens também não.

## Fase 9 (cobrança real)

`ReviveService.purchaseStarted` / `purchaseEnded` (pausam a janela) e `lateRevive` já existem, mas ninguém os chama: ligar quando o `MarketplaceService` entrar. Veja `docs/pendencias.md`.
