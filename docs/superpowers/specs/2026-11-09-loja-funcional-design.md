# Loja e kits funcionando (sem cobrar Robux) — design

Data: 2026-11-09
Branch: `ui-jogo`

## Intenção

A Loja e os kits por Robux hoje são **mockup**: o cliente finge a compra, mostra "compra simulada" e nada é entregue nem salvo. O Elizeu quer que **tudo funcione de verdade** (comprar, receber, ficar salvo no perfil, aparecer nas telas), só que **sem cobrar Robux**: o botão com preço em Robux entrega na hora, de graça. Isso vai para o **jogo aberto** (qualquer jogador). Antes de ligar a cobrança de verdade, o Elizeu vai **zerar todos os perfis**, então não há risco em dar tudo de graça agora.

Junto, os **pacotes** (ofertas da loja) precisam de um sistema em que **criar e atualizar pacotes seja fácil** (editar dados, sem mexer em tela), porque depois vamos trabalhar nos pacotes do lançamento.

## Objetivos

1. Toda compra da loja e dos kits passa pelo **servidor**, que confere, entrega e salva no perfil.
2. Preço em **Robux** → entrega grátis (ponto único onde a cobrança real vai entrar depois). Preço em **Golden Ember** → desconta de verdade.
3. **Giros viram dois saldos únicos** (decisão do Elizeu): **giros normais** (comprados com Golden Ember) e **giros especiais** (Robux). Cada saldo serve em **qualquer roleta** (Skins, Mochila, Livro, Caixa…); a tela de cada roleta mostra o mesmo saldo.
4. A roleta **sorteia no servidor** e **entrega a skin** de verdade (`CosmeticService.grantOwnership`).
5. **Pacotes** definidos em dados, com **conteúdo misto**: skins, Golden Ember, giros (normais ou especiais) e kits (Elizeu). **Fácil de adicionar novos tipos de item** no futuro (Elizeu).
6. Kits: **1 vida** (Robux) e **para sempre** (Robux, com "Usar/Ativo") de verdade e salvos.
7. Gamepasses: os kits para sempre e o **VIP** (+3 espaços, que o `InventoryService` já tem preparado) de verdade.
8. Pacotes de **Golden Ember** somam no saldo.

## Fora do escopo (não-objetivos)

- Cobrança real de Robux (`MarketplaceService`, `ProcessReceipt`, gamepasses criados no site). Fica um ponto único preparado para isso.
- O conteúdo final dos pacotes do lançamento (só os pacotes de exemplo de hoje, convertidos para o sistema novo).
- Redesenho visual da loja (o visual da UI 2 continua; muda o que os botões fazem e o card de pacote passa a listar o conteúdo real).
- Acessórios (slot ainda sem skins: continua "Em breve").

## O que não pode acontecer (anti-objetivos)

- O cliente decidir o que ganha: **nada** do que o cliente manda é confiado além do id do que ele quer comprar/girar. Sorteio, preço, conteúdo, saldo e posse são do servidor.
- Golden Ember gasta sem entregar, ou entregue sem gastar (compra pela metade). Uma compra é tudo-ou-nada.
- Lista que cresce virar atributo no Player (limite de ~1 KB de atributos por instância; ver `docs/guia/dados.md`). Posse de kits e compras feitas vão em **pastas com objetos**, como a posse das skins.
- Criar um pacote novo exigir mexer em tela ou em serviço.
- Quebrar o que já é de verdade: kit de pontos, cosméticos, saldo, perfil, ranking.

## Decisões

### Do Elizeu
- Grátis no jogo aberto; os perfis serão zerados antes do Robux real.
- Giros especiais = um saldo só, gasto em qualquer roleta. Giros normais também = um saldo só.
- Pacotes podem ter kits, giros e Golden Ember (além de skins); fácil adicionar tipos novos.
- Cada pacote: compra **uma vez por jogador** (depois mostra "Comprado"); skin já possuída dentro do pacote é ignorada e o resto entra; "kit" num pacote = **kit para sempre**. (Confirmado: "isso mesmo".)
- **Skins liberadas para teste saem agora, e as posses gravadas nos perfis são limpas** (opção "a"): cada perfil volta só com as skins padrão; skin equipada que deixar de ser possuída volta à padrão do slot.
- **Kit de 1 vida vira saldo por kit**: o jogador compra quantos quiser e fica com "N× Explorador" guardados, por exemplo. Cada nascimento com esse kit gasta 1. Pensado para **códigos de resgate** no futuro (um código entrega saldo de kit, giros, moeda…).

### Minhas (marcadas para conferência)
- **Skin repetida na roleta devolve Golden Ember**: giro normal → 50 (metade do giro normal de 100); giro especial → 150. Constantes num lugar só, fáceis de mudar.
- **Datas dos pacotes** escritas como texto `"AAAA-MM-DD HH:MM"` no **horário de Brasília** (UTC−3, sem horário de verão), convertidas por uma função pura testada. Sem `startsAt` = já começou; sem `endsAt` = não acaba.
- O kit "Iniciante já começa como permanente" (`KIT_STARTS_OWNED`) era só para mostrar o botão "Usar" no mockup: **sai**. Ninguém começa com kit permanente.
- Os dados de produto deixam de chamar "mock": viram definições de verdade em `src/shared/Defs/` (os preços em Robux continuam provisórios, só não cobrados).
- Comprar giros, pacote de moeda, kit 1 vida e passe são **produtos** como os pacotes: um único caminho de compra no servidor.

## Como funciona (o que foi decidido do "como")

### Produtos e recompensas

Tudo que se compra é um **produto**: um id, um **preço** (`robux` ou `ember`, com valor), um **limite** (`once` = uma vez por jogador, ou sem limite), uma janela de datas opcional e a lista de **recompensas** que ele entrega. Pacotes em destaque, pacotes de moeda, giros (+1/+3/+10 de cada saldo), kits 1 vida, kits para sempre e VIP são todos produtos.

Uma **recompensa** é `{ kind = "<tipo>", ... }`. Tipos de hoje:

| kind | Campos | Entrega |
|---|---|---|
| `cosmetic` | `id` (Defs.Cosmetics) | posse da skin (repetida = ignorada) |
| `ember` | `amount` | soma no saldo (sem teto, como compra) |
| `spins` | `spin` (`"normal"`/`"special"`), `count` | soma no saldo de giros |
| `kit` | `id` (Defs.Kits) | kit para sempre (posse) |
| `kitOnce` | `id`, `count` | soma no saldo daquele kit (cada vida com ele gasta 1) |
| `pass` | `id` (ex. `"vip"`) | liga o passe no perfil |

**Tipo novo = registrar num lugar só**: uma entrada no registro de tipos com (1) a validação dos campos (roda no boot e no teste, como o `Validate` dos Defs), (2) a entrega no servidor e (3) como o card mostra o item (ícone/texto). Compra, checagem e tela usam o registro e não precisam mudar.

### Pacotes em destaque (dados)

Um arquivo de dados, uma entrada por pacote, no formato dos outros Defs (ex. `Defs.Kits`): id, nome (chave de Strings), cor do tema, raridade (moldura), preço em Robux, `startsAt`/`endsAt`, recompensas. A loja mostra só os pacotes dentro da data, com o contador real até o fim. A validação recusa: id repetido, recompensa de tipo desconhecido ou com campo errado, skin/kit que não existe, quantidade não inteira ou ≤ 0, data mal escrita, fim antes do começo, nome sem texto em português. O guia ganha "Como criar um pacote" com um exemplo para copiar.

Os três pacotes de exemplo de hoje (Brasa, Geada, Musgo) viram pacotes de verdade apontando para skins reais do catálogo (o construtor escolhe skins do tema), com datas a partir de hoje.

### Compra (servidor)

O cliente pede `comprar <produtoId>`. O servidor:
1. ignora pedido rápido demais, perfil não carregado, produto inexistente ou fora da data, limite `once` já usado;
2. confere o preço: `ember` → precisa de saldo; `robux` → **grátis por enquanto** (aqui entra o `MarketplaceService` depois);
3. confere se todas as recompensas podem ser entregues (ex.: kit/skin existem) e só então cobra e entrega **tudo**;
4. marca a compra (`once`), salva o perfil e responde só ao dono com o resultado (ok ou o motivo), para a tela mostrar "Comprado!", "Saldo insuficiente" etc.

### Giros e roleta

Saldos `normal` e `special` no perfil. Comprar giros = produto com recompensa `spins`. Girar: o cliente pede `girar <tipoDeRoleta> <normal|special>`; o servidor confere o saldo, desconta 1, sorteia com `SpinRules` e as chances de cada saldo (as de hoje: normal 30/40/23/6/1, especial 5/25/40/25/5), entre as skins de `CosmeticCatalog.spinItems(tipo)`; entrega a skin ou, se repetida, a devolução em Golden Ember; salva; responde ao dono com a skin sorteada, se foi repetida e quanto voltou. O carrossel anima **até o prêmio que o servidor mandou** (`Reel:spinTo`). Segue o checklist "Ligar a roleta de verdade" do `docs/guia/dados.md`.

### Kits

- **Pontos (já é de verdade)**: não muda.
- **1 vida (Robux)**: produto `kitOnce`; soma 1 no **saldo daquele kit** no perfil (pode comprar quantos quiser). O painel de kits mostra o saldo de cada kit ("Você tem 3").
- **Para sempre (Robux) / gamepass de kit**: produto `kit`; posse no perfil. "Usar/Ativo" vira pedido ao servidor e é salvo; o ativo vem em toda vida.
- **Escolha para a próxima vida (minha decisão):** o jogador escolhe **um kit e de onde ele sai**: pontos (como hoje) ou saldo (gasta 1). A escolha vai no pedido de nascer; o servidor confere (pontos suficientes / saldo ≥ 1), cobra e entrega. Sem escolha, vem o permanente ativo; sem ativo, nenhum. Vai **um kit por vida**. Escolher de pontos não mexe no saldo (nada se perde). A regra pura de "qual kit vai e de onde" substitui o `KitOffer` de mockup e tem teste.

### VIP

Produto `pass` `vip`: grava no perfil; o `InventoryService` soma os slots extras se o perfil tem o VIP **ou** se o jogador tem o gamepass real (o caminho atual continua).

### O que o cliente vê

Saldos de giros e kit ativo publicados para o cliente; kits possuídos, saldo de cada kit e compras `once` feitas em **pastas com objetos** (como `OwnedCosmetics`). As telas da loja e de kits leem dali (somem os estados locais `ShopState.counts` e `KitShop` de mockup). O aviso "compra simulada" sai; no lugar, a resposta do servidor ("Comprado!", motivo da falha). O selo "MOCKUP" sai dos fluxos que viraram de verdade.

## Restrições

- Rede pelo Blink (`net/game.blink`): eventos novos de pedido (cliente → servidor) e resultado (servidor → só o dono), com faixas de tamanho como os outros.
- Perfil: campos novos pelo template (`ProfileTemplate`) — o `Reconcile` completa perfis antigos; sem migração se só acrescenta.
- Lógica pura (preço, limite, datas, validação de recompensas, sorteio/repetida, ordem do kit) em `src/shared` com testes Lune; serviços só aplicam.
- `bash scripts/check.sh` passando; textos novos em `Strings/ptBR.luau`.
- Guias atualizados: `docs/guia/telas.md` (Loja, kits), `docs/guia/dados.md` (perfil, roleta), e o passo a passo "Como criar um pacote" e "Como criar um tipo de item de pacote".

## Deixado para quem constrói

- Nomes exatos de arquivos, módulos e eventos; onde fica o registro de tipos.
- Formato exato no perfil e na publicação para o cliente (respeitando "listas em pastas").
- Visual do card de pacote com conteúdo variável (reusar `ItemViewport` para skins, ícone da moeda, ícone de giro, ícone do item do kit).
- Taxa mínima entre pedidos.
- Quais skins entram nos três pacotes de exemplo.

### Limpeza das skins de teste

Sai o laço "todas as skins liberadas para teste" do `CosmeticService.publishOwned`, e os perfis que já têm as skins gravadas são limpos **uma vez**: uma migração (subindo `DataConfig.SCHEMA_VERSION`) zera `Cosmetics.Owned`; o `loadEquipped` já devolve a skin padrão do slot quando a equipada não é mais possuída. O comando de dev de dar skin (`DevGrantCosmetic`) continua para testes no Studio. Atualizar `docs/pendencias.md`/`docs/guia/dados.md` onde citam as skins liberadas.
