# Assets de UI da monetização (pedido ao Elizeu, 17/11)

Design: `docs/superpowers/specs/2026-11-17-monetizacao-design.md`.
Até cada arte chegar, a tela usa o desenho feito por código, então dá para mandar aos poucos, na ordem da prioridade.

## Regras para todas as peças

- PNG com **fundo transparente** e **sem texto**: preço, números, datas e nomes vão por código, para traduzir e mudar valores.
- Mesmo estilo rústico do menu, da loja e das missões: madeira nogueira, papel creme, laranja brasa, contorno escuro grosso.
- **Cor do VIP**, para tudo que for do VIP: dourado com brilho de brasa, para diferenciar do laranja comum da loja. Se quiser outra cor, me avisa, porque ela vira a cor do VIP em todo o jogo.
- Peças que **esticam** (janela, cartão, faixa, botão): bordas e cantos uniformes e centro liso, para cortar em 9 partes. Detalhe enfeitado no canto vem como peça separada, por cima.
- **Ícones:** quadrados, com pelo menos 512 px e silhueta clara, porque vão aparecer pequenos no celular.
- Pode mandar numa folha só, com espaço entre as peças; eu recorto.

## 1. Dentro do jogo

| # | Peça | Onde aparece | Estados / variações | Tamanho sugerido | Prioridade |
|---|---|---|---|---|---|
| 1 | **Ícone VIP do nome** | ao lado do nick, em cima do boneco, para todos | 1 | 512 px; precisa ler em 20 px (coroa ou brasa simples, sem detalhe fino) | essencial |
| 2 | **Cartão do VIP** na loja | topo da aba de gamepasses; maior que os outros cartões, com lugar para a lista de benefícios e o preço | normal e "ativo" (com brilho ou faixa) | proporção 2:1 deitado, ~1024×512 | essencial |
| 3 | **Ícone 2× Golden Ember** | cartão da gamepass | 1 | 512 px (moeda com "2×" desenhado é ok, porque é parte do ícone) | essencial |
| 4 | **Ícone Nascer com livro** | cartão da gamepass | 1 | 512 px (livro com brilho ou com berço/estrela) | essencial |
| 5 | **Ícone do revive** | tela de morte e produto | 1 | 512 px (coração com chama, pena de fênix ou algo assim) | essencial |
| 6 | **Painel da oferta de revive** | tela de morte, no centro, por cima do resumo da vida | 1 | ~800×500, estica em 9 partes | essencial |
| 7 | **Botão REVIVER** | dentro do painel | normal, apertado e desligado (cinza) | mesmo formato dos botões verdes/laranja da loja | essencial |
| 8 | **Botão Não, obrigado** | ao lado do REVIVER, mais discreto (madeira ou papel, não colorido) | normal e apertado | mesmo formato do REVIVER | essencial |
| 9 | **Selo GRÁTIS VIP** | em cima do botão quando o revive é o grátis do VIP | 1 (sem a palavra; eu escrevo) | faixa ou fita, ~300×100 | essencial |
| 10 | **Cadeado da caixa trancada** | em cima da caixa trancada, no mundo | 1 | 512 px | essencial |
| 11 | **Janela do check-in** | abre ao entrar no menu | 1 (pode ser a mesma moldura das missões; aí não precisa) | estica em 9 partes | bom ter |
| 12 | **Cartão de dia do check-in** | 7 na janela, dias 1 a 6 | 4 estados: resgatado (apagado + marca), hoje (brilhando), futuro (normal), ainda não liberado hoje (escuro) | ~240×300, retrato | essencial |
| 13 | **Cartão do dia 7** | o último, maior e mais especial (5 giros especiais) | os mesmos 4 estados | ~1,5× o cartão normal | essencial |
| 14 | **Carimbo de resgatado** | por cima do cartão do dia já pego | 1 | 256 px | essencial |
| 15 | **Ícone do check-in** (calendário) | botãozinho no canto do menu, ao lado do saldo | 1 | 512 px | essencial |
| 16 | **Bolinha de aviso** | no ícone do check-in quando tem prêmio | 1 (se a das missões servir, não precisa) | — | só se não existir |
| 17 | **Ícone do boost de XP** | selo no HUD e no menu com o tempo restante; cartão do produto | 1 | 512 px (raio, estrela com seta ou "XP" desenhado) | essencial |
| 18 | **Cartão Benefícios Premium** | loja, para quem não tem Premium | 1 | ~1024×400 | bom ter |
| 19 | **Etiquetas do multiplicador** | tela de morte, ao lado da Golden Ember ganha ("2×", "VIP +50%", "Premium +20%") | 1 fundo de etiqueta (o texto é meu) | ~200×64, estica | bom ter |
| 20 | **Aviso de bloqueio** dos giros especiais | tela do giro, onde a lei proíbe | 1 ícone (escudo ou cadeado com balança) | 512 px | bom ter |

Para o **Premium** não precisa arte: o Roblox tem o símbolo oficial do Premium, que eu uso como texto.

## 2. No site do Roblox (para a fase da cobrança)

Estes aparecem no Creator Hub e na página do jogo, não dentro dele. São **512×512**, com o desenho centralizado num círculo, porque o Roblox corta os cantos em alguns lugares. Pode ter fundo colorido.

| # | Peça | Observação |
|---|---|---|
| 21 | Ícone da **assinatura VIP** | pode ser o 1 maior e com fundo |
| 22 | Ícone da gamepass **2× Golden Ember** | pode ser o 3 com fundo |
| 23 | Ícone da gamepass **Nascer com livro** | pode ser o 4 com fundo |
| 24–27 | Ícones dos **4 kits para sempre** | já temos os ícones da loja (morango, picareta, mochila, medalha); basta pôr fundo |
| 28 | Ícones dos **produtos** (Golden Ember, giros, kits de 1 vida, revive, boost) | o Roblox não obriga ícone em produto, mas fica mais bonito; os de Golden Ember podem vir das pilhas de moedas que já temos |

## Já temos e vou reaproveitar

Moeda Golden Ember e pilhas de moedas, botões verde e laranja, fita, fundos dos cartões da loja, fundos das raridades, cadeado do HUD, moldura e bolinha das missões, símbolo do Robux e o ícone de giro especial.
