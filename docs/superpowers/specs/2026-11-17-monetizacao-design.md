# Monetização: VIP, gamepasses, revive, check-in e bônus — design

Data: 17/11/2026. Branch `monetizacao` (worktree `.worktrees/monetizacao`), separada da `ui-celular`, onde o Elizeu está mexendo.
Conversa de origem: brainstorming de 17/11 com o Elizeu. Lista de artes: `docs/game-design/assets-ui-monetizacao.md`.

## 1. Intenção

O Elizeu quer que o jogo dê dinheiro no lançamento. Na visão dele, um jogo só de cosméticos não vende, então **um pouco de vantagem paga pode**. O limite é: **pagar ajuda a sobreviver, mas não pula o jogo**. Não vamos vender um kit com tudo, nem armas, armaduras ou itens raros, nem nada que dê dano ou defesa direto.

Boa parte da loja já existe e funciona sem cobrar (`docs/guia/loja.md`): pacotes de Golden Ember, giros especiais, kits de 1 vida e para sempre, VIP como passe e pacotes em destaque. Esta fase acrescenta os **sistemas e as telas** que faltam. A **cobrança de verdade** e a **criação dos produtos no Roblox** ficam para uma fase seguinte (seção 9).

## 2. Objetivos, não-objetivos e anti-objetivos

**Objetivos**
- VIP vira **assinatura mensal** (99 Robux por mês) com os benefícios da seção 4.1.
- Duas gamepasses novas: **2× Golden Ember** e **Nascer com livro**.
- **Premium do Roblox** ganha bônus automático.
- **Revive pago**: volta com todos os itens, e o preço sobe a cada uso na mesma vida.
- **Check-in de 7 dias.**
- **Boost de XP de 1 hora** (produto).
- **Golden Ember sem nenhum limite** de ganho.
- Giros especiais seguindo a regra do Roblox para item aleatório pago: mostrar as chances antes e bloquear onde a lei proíbe.
- Tudo funcionando no modo atual, em que o Robux sai de graça, para testar o fluxo inteiro antes de cobrar.

**Não-objetivos (agora)**
- Criar gamepasses, assinatura e produtos no Creator Hub, e ligar o `ProcessReceipt`: isso é a fase seguinte.
- Emotes, efeitos de matar e morrer, cor do nick, títulos e skins de construção: entram depois, em pacotes de update.
- Zerar os perfis: só antes de ligar a cobrança, como combinado.

**Anti-objetivos (falharia mesmo funcionando)**
- Vender arma, armadura, item raro ou um kit que pule a progressão.
- Revive que tire o prêmio de quem venceu a luta sem dar nada em troca: quem matou sempre ganha os pontos.
- O jogador pagar e não receber, ou receber duas vezes.

## 3. Abordagens consideradas

- **A. Por fases, cobrança primeiro:** liga o Robux de verdade com o que já existe e depois soma as vantagens, o revive e o check-in. A parte delicada (pagamento) teria tempo de uso real, mas cria produtos no Roblox antes do resto estar pronto.
- **B. Tudo de uma vez numa branch:** chega mais rápido no fim, mas só dá para testar tudo junto.
- **C. Sistemas e telas primeiro, cobrança depois. (Escolhida pelo Elizeu.)** Tudo funciona de graça como hoje, dá para testar o fluxo inteiro no Studio e com amigos, e a configuração no Roblox vem no fim, com a lista pronta. O cuidado é deixar **um único ponto** para trocar quando a cobrança for ligada (`ShopService.charge` e a fonte dos benefícios, seção 4.5), para a fase seguinte não mexer em regra de jogo.

## 4. O que foi decidido

### 4.1 VIP (assinatura mensal, 99 Robux)

- **+3 espaços** (já existe: `InventoryConfig.vipPass.bonusSlots`).
- **Ícone no nome**, na etiqueta do boneco, visível para todos.
- **+50% de Golden Ember** (seção 4.4).
- **Kit VIP** exclusivo: só pode ser usado enquanto a pessoa assina. Entra em `Defs.Kits` com uma marca nova (`vipOnly = true`), sem preço em Robux nem em pontos. O painel de kits mostra o kit para todos, com o cadeado "Só VIP" para quem não assina. **Conteúdo** (o Elizeu deixou a meu critério): 20 bagas, 120 madeiras, 80 pedras, picareta de pedra, 1 fogueira grande e 8 paredes de madeira. Fica entre o Explorador e o Sobrevivente, ajuda a começar uma base e não traz arma nem armadura.
- **1 revive grátis por vida** (seção 4.6).
- No modo de hoje, sem cobrança, "assinar" grava no perfil uma data de fim (`Shop.VipUntil = agora + 30 dias`). Comprar de novo soma 30 dias. Quando a assinatura real entrar, a fonte passa a ser o Roblox (seção 9). A loja mostra "VIP ativo até DD/MM".
- A assinatura em Robux existe no Roblox (mínimo de 49 por mês, com 70% para o criador; DevForum, "Let Your Players Pay for Subscriptions within Experiences in Robux"). Os 99 por mês cabem.
- **VIP que vence no meio de uma vida** (*chamada minha*): os benefícios são lidos **ao nascer** e valem até o fim daquela vida (espaços, revive grátis, multiplicador). Assim nenhum item cai dos espaços extras no meio do jogo. Na próxima vida, sem VIP, os espaços voltam ao normal.
- O passe `vip` antigo sai do `ShopConfig.PASSES` e da aba de gamepasses. O VIP ganha um cartão próprio na loja (seção 6).
- Cuidado com o nome: "servidor VIP" no `RankService` e no `RankRules` é o servidor privado do Roblox, não o nosso VIP. Isso não muda; só vale um comentário para não confundir.

### 4.2 Gamepasses

| Gamepass | Efeito |
|---|---|
| 2× Golden Ember | +1 no multiplicador de Golden Ember (seção 4.4) |
| Nascer com livro | nasce sempre com o livro de craft (`book`, `craftSpeed = 3`) |
| Kit Inicial, Explorador, Sobrevivente e Veterano para sempre | já existem |

**Livro:** hoje todo mundo nasce com o livro (`SpawnService.SPAWN_ITEMS`, marcado como provisório). Com esta fase, **só quem tem a gamepass** nasce com ele. Os outros craftam: a receita já existe (4 papéis + 10 de ouro; papel = 20 madeira na fogueira). Se o kit escolhido já tem livro, ele não vem em dobro (a regra `kitHasItem` continua).

### 4.3 Premium do Roblox

- **+20% de Golden Ember.**
- **Kit Inicial liberado**, como se tivesse comprado o kit para sempre, só enquanto for Premium (`player.MembershipType == Enum.MembershipType.Premium`). Não grava no perfil: é lido na hora, e `Players.PlayerMembershipChanged` atualiza.
- Quem não é Premium vê um cartão de "Benefícios Premium" na loja. *Chamada minha:* o botão desse cartão abre `MarketplaceService:PromptPremiumPurchase`.

### 4.4 Golden Ember: sem limite, com multiplicador

- **Saem todos os limites:** `MAX_CURRENCY_PER_LIFE` (500) e `MAX_CURRENCY_PER_HOUR` (300). Os campos `HourWindowStart`/`HourEarned` do perfil ficam sem uso; não precisa migração.
- **Multiplicador somado**, não multiplicado: `1 + (2× ? 1 : 0) + (VIP ? 0,5 : 0) + (Premium ? 0,2 : 0)`, ou seja, **2,7× no máximo**. O ganho é `floor(pontos / 1000 × multiplicador)`.
- *Chamada minha:* o multiplicador vale **só para o que se ganha jogando**, a conversão de pontos no fim da vida (`LifeService.endLife`). Prêmios fixos (missões, check-in, devolução de skin repetida) e compras não multiplicam. Assim cada prêmio vale o número que está escrito na tela.
- A tela de morte mostra o ganho e as etiquetas do que multiplicou ("2×", "VIP +50%", "Premium +20%").
- O campo `Currency` do `LifeEnded` (`net/game.blink`) é `u16` e passa a `u32`, já que não há mais teto.
- **Risco aceito:** sem teto, dois amigos podem farmar abates combinados. Nada entra agora. Vamos acompanhar pelas estatísticas e, se precisar, criar uma regra invisível (ex.: matar a mesma pessoa várias vezes em 10 minutos não dá bônus).

### 4.5 De onde vem cada benefício (um ponto só)

Um módulo puro (`Shop/Perks`, *nome meu*) responde "este jogador tem X?" para `vip`, `ember2x`, `book`, `premium` e para os kits liberados por benefício. Ele lê de uma fonte por benefício:

| Benefício | Fonte agora (sem cobrança) | Fonte depois (fase 9) |
|---|---|---|
| VIP | `Shop.VipUntil` no perfil | status da assinatura no Roblox (com a data do perfil como reserva para presente e código) |
| 2× e livro | `Shop.Passes` no perfil (como o VIP antigo) | perfil + `UserOwnsGamePassAsync` |
| Premium | `MembershipType` | igual |

O servidor publica os benefícios ativos como atributos do `Player` (*proposta:* `Perk_vip`, `Perk_ember2x`...) para as telas.

### 4.6 Revive

**Quando aparece:** em toda morte final de jogador fora do modo criativo e fora da vida de tutorial. Se ele virar fantasma (Coração de Dragão ou Coroa do Anjo), a oferta só aparece quando o tempo de fantasma acabar e a morte for de verdade.

**A decisão (Elizeu: sem contador na tela):**
- A tela de morte abre com a oferta: preço em Robux e dois botões, **REVIVER** e **Não, obrigado**. Para VIP com o revive grátis da vida sobrando, aparece o selo **GRÁTIS VIP**. Não aparece contador.
- *Chamada minha:* existe um **limite escondido de 30 s**. Sem ele, quem ficasse parado na oferta deixaria a caixa trancada para sempre e quem matou nunca saquearia. Passados os 30 s sem resposta, conta como "Não, obrigado".
- A caixa de morte cai **trancada** com os itens dentro: ninguém abre nem quebra, e um cadeado aparece em cima dela.
- As construções dele **ficam** durante a janela. `StructureService.removeOwned` só roda se a morte for final.
- O fim de vida roda na hora, como hoje: pontos viram Golden Ember, estatísticas e ranking são gravados, e quem matou ganha o bônus de 1/4 e o abate.

**Se ele revive:**
- Os itens voltam da caixa para o inventário, com a mochila e a armadura que ele vestia, e a caixa some.
- Nasce no **totem do time** se o time tiver um de pé; senão, num **ponto aleatório da floresta** (seção 4.7).
- Vida e barras cheias, pontos em 0 e **3 s de proteção**: não leva dano, e a proteção acaba antes se ele bater. Os mobs também não o veem.
- Começa uma vida nova para pontos, missões da Partida e ranking (`LifeService`). Os kits não entram: ele já está com os próprios itens.

**Se não revive** (Não, obrigado, passou dos 30 s ou saiu do jogo): morte normal. A caixa destranca para qualquer um, as construções somem e ele volta ao menu.

**Preço:** 25 → 49 → 99 → 199 Robux, e para no 199. Cada degrau é um produto: `revive_1` a `revive_4`. A contagem de revives vai da entrada pelo menu até a morte final. O revive grátis do VIP ocupa o primeiro degrau (depois dele, o próximo custa 49) e vale 1 por vida.

**Quem matou, mesmo com queda ou água** (*chamada minha*): o Reset é só para os testes do Elizeu e sai antes do lançamento, mas ainda dá para fugir pulando do mapa ou morrendo afogado no meio da luta, negar os pontos ao outro e reviver com tudo. Por isso, **o último jogador que acertou o morto nos últimos 10 s conta como quem matou**, em qualquer causa de morte (queda, afogamento, fome, mob). Ele ganha o bônus de 1/4 e o abate. Vale para toda morte, com ou sem revive.

**Pagamento demorado** (*chamada minha*): o limite de 30 s **pausa** enquanto a janela de compra do Roblox está aberta ou a compra está pendente, até 60 s no máximo. Se a confirmação chegar depois que a morte já virou final, o jogador ganha um **revive guardado** (salvo no perfil), usado de graça na próxima morte. Nunca se paga sem receber.

**Estatísticas:** *chamada minha:* a morte com revive conta em `deaths`, porque a vida acabou para os pontos, mas **não** em `real_deaths`, o "Mortes" do Perfil, que é só a morte em que se perde tudo.

### 4.7 Nascimento aleatório na floresta

Hoje todo mundo nasce no `SpawnLocation` do centro (`WorldConfig.SPAWN`). O revive precisa de um ponto aleatório: dentro da zona da floresta, fora d'água, fora de `NoSpawn` e longe de construções e de outros jogadores (*distâncias: chamada do construtor*). O nascimento normal pelo menu **continua no centro**; trocar isso não foi pedido.

### 4.8 Check-in de 7 dias

- 7 prêmios em sequência, **um por dia em que o jogador entra**. Os dias não precisam ser seguidos, e faltar não volta para o começo. Depois do dia 7, recomeça no 1.
- O dia vira à meia-noite de Brasília, como as missões diárias (`MissionService`).

| Dia | Prêmio |
|---|---|
| 1 | 100 Golden Ember |
| 2 | 1 giro normal |
| 3 | 150 Golden Ember |
| 4 | Kit Explorador, 1 vida (`kitOnce`) |
| 5 | 200 Golden Ember |
| 6 | 2 giros normais |
| 7 | **5 giros especiais** |

- Os prêmios são recompensas da loja (`Shop/Rewards`) e são entregues por `ShopService.give`. Mudar a tabela é só mexer em dados.
- **Onde fica:** ao entrar no menu com prêmio disponível, a janela abre sozinha. *Chamada minha:* também fica acessível por um botãozinho de calendário ao lado do saldo, no canto, já que a coluna do menu está com 6 botões que cabem no celular sem rolar.

### 4.9 Boost de XP

- Produto de 1 hora de **XP em dobro**, contando no relógio real desde a compra. Comprar de novo soma mais 1 hora. O teto de XP por hora (`MAX_XP_PER_HOUR`) dobra junto enquanto o boost estiver ativo.
- **O que dobra** (*chamada minha*): o XP é calculado no fim da vida, então dobra **na proporção do tempo da vida que passou com boost**. Com metade da vida com boost, o XP é ×1,5. Isso evita comprar o boost um segundo antes de morrer para dobrar uma vida inteira.
- **Ranking** (*chamada minha*): a aba XP do ranking semanal soma o XP **sem o boost**. Pagar sobe o nível, mas não o ranking, no mesmo espírito do "servidor privado não conta".
- Um selo com o tempo restante aparece no HUD e no menu.
- Preço proposto: 49 Robux.

### 4.10 Giros e a regra do Roblox

Pela regra do Roblox, "item aleatório pago" inclui o que se compra com Robux **ou com uma moeda do jogo que se compra com Robux**. A Golden Ember se compra com Robux, então **o giro normal também conta** (*chamada minha, pelo lado seguro*):
- A tela do giro mostra as chances dos dois tipos (`ShopConfig.SPIN_ODDS`) **antes** de comprar.
- `PolicyService:GetPolicyInfoForPlayerAsync(player).ArePaidRandomItemsRestricted` (no servidor, com pcall; se falhar, conta como restrito): onde é proibido, **comprar** giros (especial com Robux e normal com Golden Ember) fica bloqueado, com aviso, e os pacotes em destaque que trazem giros não aparecem.
- Giros **ganhos de graça** (check-in, missões, prêmios) continuam podendo ser usados em qualquer país.

## 5. Produtos e preços (para a fase 9)

| Tipo no Roblox | Produto | Preço |
|---|---|---|
| Assinatura | VIP | 99/mês |
| Gamepass | 2× Golden Ember | 199 |
| Gamepass | Nascer com livro | 99 |
| Gamepass | 4 kits para sempre | 99 / 199 / 399 / 799 |
| Produto | Golden Ember (5) | 80 / 150 / 600 / 1500 / 3500 |
| Produto | Giros especiais (3) | 49 / 129 / 399 |
| Produto | Kits de 1 vida (4) | 15 / 25 / 49 / 99 |
| Produto | Revive (4 degraus) | 25 / 49 / 99 / 199 |
| Produto | Boost de XP 1 h | 49 |
| Produto | Pacotes em destaque | um por pacote |

Os preços das duas gamepasses novas estão em aberto (seção 10). Ficam em `ShopConfig`, como os outros.

## 6. Telas

- **Loja, aba de gamepasses:** entram 2× Golden Ember e Nascer com livro, e sai o cartão do VIP.
- **Loja, VIP:** cartão próprio e maior, com os benefícios, "99 por mês" e o estado ("VIP ativo até DD/MM"). *Chamada minha:* fica no topo da aba de gamepasses.
- **Loja, Premium:** cartão "Benefícios Premium" (seção 4.3).
- **Loja, giros especiais:** chances visíveis e aviso de bloqueio (seção 4.10).
- **Tela de morte:** oferta de revive com preço ou selo grátis, REVIVER e Não, obrigado, e Golden Ember com as etiquetas do multiplicador.
- **No mundo:** cadeado em cima da caixa trancada; ícone VIP no nome; bolha de proteção de 3 s (efeito por código).
- **Painel de kits:** Kit VIP com "Só VIP" e Kit Inicial com "Premium" para quem tem Premium.
- **Check-in:** janela com os 7 dias, botão de calendário no canto e abertura automática.
- **HUD e menu:** selo do boost de XP.

Até as artes chegarem, cada tela usa o desenho feito por código, como o resto da loja faz (`ShopImages.has`).

## 7. Restrições

- **Server Authority:** o cliente só pede. Revive, check-in e benefícios são decididos no servidor.
- **Conteúdo é dado:** prêmios do check-in, degraus do revive, multiplicadores e preços ficam em config, nunca no código das telas.
- A posse continua sendo o perfil (`Shop.KitsOwned`, `Shop.Passes`), menos o Premium e, depois, a assinatura, que vêm do Roblox.
- `--!strict`, regras puras testadas no Lune (`tests/*.spec.luau`), `bash scripts/check.sh` verde.
- **Celular:** a coluna do menu tem 6 botões que cabem sem rolar (branch `ui-celular`). Esta fase não acrescenta botão nela.
- O jogo agora pertence a um **grupo do Roblox**. Gamepasses, assinatura e produtos vão ser criados no grupo (fase 9).

## 8. Fica com o construtor

- Nomes de módulos, atributos e mensagens de rede.
- Como a caixa trancada guarda e devolve os itens (reaproveitando o `CrateService`).
- Regras de distância do nascimento aleatório.
- Ordem das tarefas e divisão em commits.

## 9. Fase seguinte (fora desta branch)

1. Zerar os perfis.
2. Criar no grupo do Roblox: 1 assinatura, 6 gamepasses e cerca de 25 produtos, com ícones. Os ids ficam junto dos produtos.
3. `ShopService.charge` → `PromptProductPurchase` / `PromptGamePassPurchase` / `PromptSubscriptionPurchase`, com entrega no `ProcessReceipt` (`PurchaseIdCache` no perfil) e `PurchaseGranted` só depois de salvar.
4. `Shop/Perks` passa a ler a assinatura (`GetUserSubscriptionStatusAsync` + `UserSubscriptionStatusChanged`) e as gamepasses.
5. Conferir se as imagens enviadas na conta pessoal do Elizeu continuam aparecendo no jogo do grupo.

## 10. Junto, fora da monetização

- **Pergaminho da receita fixada** (asset 29): troca o fundo do `PinnedRecipe`. *Chamada minha:* entra **no fim** desta branch, porque o arquivo está sendo mexido na `ui-celular`.

## 11. Ordem de trabalho

O Elizeu cria as artes pela lista (`docs/game-design/assets-ui-monetizacao.md`), e a implementação começa quando elas chegarem.
