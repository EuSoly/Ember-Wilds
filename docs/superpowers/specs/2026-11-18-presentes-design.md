# Presentes na loja — design

Data: 18/11/2026. Pedido do Elizeu: poder comprar itens da loja **de presente para outro jogador**. Branch `ui-ajustes` (worktree `.worktrees/monetizacao`), depois da cobrança real (`RobuxService`, commit fa68a1d).

## Por quê

Jogar com amigos é o centro do jogo (times, totem). Dar um kit ou Golden Ember para o amigo que está jogando junto é uma compra natural, e hoje não existe. É mais uma porta de receita sem vender poder novo (os itens são os mesmos da loja).

## Decidido com o Elizeu

- Só para quem está **no mesmo servidor** (lista dos jogadores presentes).
- **VIP e revive não se presenteiam.** Todo o resto da loja com Robux sim: 4 kits para sempre, 2× Golden Ember, Nascer com livro, 5 pacotes de Golden Ember, 3 de giros especiais, 4 kits de 1 vida, boost de XP 1 h e os 3 pacotes em destaque (22 itens).
- Caminho **A**: um produto de desenvolvedor "Presente: X" por item, com o destinatário guardado no perfil de quem paga antes de abrir a compra.
- Artes 45–55 entregues em `assets/ui/presentes/` (lista em `docs/game-design/assets-ui-presentes.md`); os `.model.json` de lá trazem os ids já enviados e o SliceCenter das peças 9-slice. A janela 47 só tem o `.model.json` (id 114195747576252, 1000×700, Slice 60,60,940,640).

## Abordagens consideradas

- **A. Produto de presente por item + destinatário no perfil de quem paga (escolhida).** Nome claro na janela de compra do Roblox; o pagamento atrasado (outra visita, servidor caiu) ainda sabe para quem é. Custo: 22 produtos novos.
- **B. Reaproveitar os produtos atuais com um aviso "é presente".** Não serve para as gamepasses (ficariam com quem pagou) e o pagamento atrasado perde o destinatário (cai em quem pagou).
- **C. Produtos genéricos por faixa de preço.** A janela do Roblox não diz o que se compra: confuso e arriscado com as regras do Roblox.

## Metas, não-metas, anti-metas

- Meta: comprar qualquer um dos 22 itens para alguém do servidor em poucos toques; quem recebe vê de quem veio; nunca se paga sem alguém receber.
- Não-meta: presentear quem está offline ou em outro servidor; lista de amigos; mensagem escrita; histórico de presentes.
- Anti-meta: presente que some (pago e ninguém recebe), presente que chega a quem pagou em vez do amigo, modal que cobre a tela no meio da luta.

## Como funciona

### Fluxo de quem dá

1. Na loja, os cartões dos 22 itens ganham um **botão de presente** pequeno (ícone 45) ao lado do preço. VIP, revive, Premium e o giro normal (Golden Ember) não têm.
2. O botão abre a janela **Presentear** (moldura 47): o ícone do item com o laço (46) no canto, o nome, e a lista de **jogadores do servidor menos você** (linha 48, foto do avatar do Roblox na moldura 49, nome). Linha escolhida = estado selecionado + marca 50.
3. Linha **apagada** com "Já tem" quando o item é de uma vez e a pessoa já tem (kit para sempre, 2×, livro, pacote em destaque comprado) — lido da pasta `Player.Shop` do outro jogador, que já replica para todos. Giros especiais e pacotes com giros: linha apagada com "Indisponível" quando o outro tem `PaidRandomBlocked` (o atributo já existe na pasta dele); e se **quem dá** tem `PaidRandomBlocked`, o botão de presente desses itens nem aparece (a lei vale para quem paga). *Chamada minha:* confere os dois lados, o lado seguro.
4. Lista vazia (sozinho no servidor): ícone 55 + texto "Ninguém para presentear".
5. Botão verde com o ícone de presente e o preço → pedido ao servidor → janela de compra do Roblox de "Presente: X".
6. Pago → aviso "Presente enviado para Fulano!". Cancelado → "Compra cancelada" (já existe).

### Servidor

- `RobloxIds.GIFT[productId] = id do produto de presente` (22 entradas). `RobloxIds.fromProduct` também reconhece os ids de presente e diz que é presente. O teste de ids passa a cobrir os 22.
- Pedido novo do cliente `RequestGift { ProductId, RecipientUserId }` (Blink). O servidor confere: produto existe, é presenteável (`RobloxIds.GIFT` tem o id), destinatário está no servidor, não é o próprio jogador, perfis dos dois carregados, e as regras da compra (`PurchaseRules.check`) **contra o perfil de quem recebe** (já tem / fechado / giros bloqueados para ele), mais o bloqueio de giros **de quem paga** (`ShopService.randomBlocked` dos dois). Recusa volta pelo `PurchaseResult` com o motivo (strings novas: "Ele já tem isso", "Este jogador saiu", "Indisponível para este jogador").
- Antes de abrir a compra, grava no perfil de quem paga `Shop.GiftPending[productId] = { to = userId, name = nome }` e salva (um pendente por produto; um novo para o mesmo produto substitui). Compra cancelada apaga o pendente.
- Recibo de um produto de presente (`ProcessReceipt`, dentro do `DataService.receiptAsync` de quem pagou): lê `GiftPending[productId]` de quem pagou e apaga.
  - Destinatário **neste servidor** com perfil ativo: entrega direto no perfil dele (mesma entrega do `ShopService.deliver`, mas no outro jogador), marca o "uma vez", publica a pasta dele, salva o perfil dele, avisa os dois. O `PurchaseId` também vai para uma lista no perfil de **quem recebe** (sem entregar duas vezes se o recibo voltar) e o `PurchaseGranted` só sai depois que os **dois** perfis salvaram.
  - Destinatário **saiu**: `ProfileStore:MessageAsync(chave dele, { kind = "gift", productId, from = nome })`. Quem recebe trata a mensagem ao carregar o perfil (`profile:MessageHandler`), entrega e mostra o presente. Se a mensagem falhar, o recibo fica `NotProcessedYet` e o Roblox tenta de novo.
  - **Sem pendente** (não deveria acontecer): o item vai para quem pagou, com aviso no Output. Nunca se perde.
- Item de uma vez que o destinatário já tem **na hora da entrega** (comprou no meio): vira Golden Ember para ele no valor do preço, pela taxa do pacote de 300 (3,75 GE por Robux, arredondado). *Chamada minha:* raro, e assim ninguém perde o que pagou.
- Revive guardado, VIP e o giro normal ficam de fora (não estão em `RobloxIds.GIFT`).

### Quem recebe

- Os presentes ainda não abertos ficam numa fila **no perfil** de quem recebe (`Shop.GiftInbox`, com de quem e o quê), para sobreviver a sair do jogo; abrir tira da fila.
- **No menu:** pop-up central (painel 53) com a caixa fechada (51); um toque abre: troca pela caixa aberta (52), raios/confete (54, tingidos e girando atrás), o ícone do item saindo da caixa, "Fulano te deu de presente" e o nome do item. Botão "Obrigado!" fecha. Vários presentes = fila, um por vez.
- **Jogando:** só um aviso na tela ("Fulano te deu Kit Veterano!", com o ícone 45), sem modal; o pop-up da caixa fica na fila para a próxima vez que ele estiver no menu. *Chamada minha:* modal no meio da luta mata o jogador.
- Presente que chegou offline (mensagem do ProfileStore): mesmo pop-up ao entrar no menu.

### Produtos no Roblox

- 22 produtos de desenvolvedor "Presente: <nome do item>", mesmo preço do item, criados pela API do Open Cloud pela ferramenta do Roblox Studio (como os 20 de 18/11; precisa da pasta do projeto liberada para upload), e **à venda** junto com os outros. Pôr à venda pela API foi bloqueado pelas permissões do Claude Code em 18/11: se continuar, o Elizeu liga a venda no Creator Hub. Ids gravados em `RobloxIds.GIFT` (o cabeçalho "fora de venda" do `RobloxIds` é atualizado). Capa: o ícone que o item já usa com o laço (46) no canto de cima à direita, montado por script (Pillow), como as capas dos kits.
- Preço mudou no código: mudar também no Creator Hub (vale para os presentes).

## Restrições

- Server Authority: o cliente só pede; quem confere, cobra e entrega é o servidor.
- Limite de ~1 KB de atributos por instância: nada de atributo novo no Player; o pendente fica no perfil, não em atributo.
- UI no celular cabe em 749×330 sem rolar (a lista de jogadores pode rolar, com a barra visível). PC intacto.
- Textos em `Strings/ptBR.luau`; sem texto nas artes.
- Testes Lune para o que é regra pura (presenteável, quem pode receber, conversão em Golden Ember, ids).

## O que fica com quem constrói

- Onde exatamente o botão de presente entra em cada cartão (Passes, EmberPacks, SpinScreen, KitShop, Featured, BoostCard), desde que não quebre o layout do celular nem do PC.
- Tamanhos da janela e das linhas, animação da caixa, cores dos raios.
- Nome do serviço/módulos novos (ex.: `GiftService` no servidor, `GiftPanel` e `GiftPopup` no cliente, `Shop/GiftRules` puro).
- O `PurchaseResult` precisa separar resultado de presente de compra normal (para o aviso certo).
- Teste no Studio com 2 jogadores (Test → Players: 2): dar, cancelar, já tem, destinatário sai antes de pagar, presente chegando jogando e no menu.
