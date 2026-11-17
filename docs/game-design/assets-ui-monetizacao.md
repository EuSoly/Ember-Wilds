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
| 24–27 | Ícones dos **4 kits para sempre** | os novos ícones 30–33 (seção 4), com fundo |
| 28 | Ícones dos **produtos** (Golden Ember, giros, kits de 1 vida, revive, boost) | o Roblox não obriga ícone em produto, mas fica mais bonito; os de Golden Ember podem vir das pilhas de moedas que já temos |

## 3. Fora da monetização (pedido junto, 17/11)

| # | Peça | Onde aparece | Estados / variações | Tamanho sugerido | Prioridade |
|---|---|---|---|---|---|
| 29 | **Pergaminho da receita fixada** | substitui o fundo atual do quadro da receita fixada pelo livro, na coluna da direita do HUD (nome do item em cima, uma linha por ingrediente embaixo) | 1 | ~400×600, em pé, com rolo em cima e embaixo e papel liso no meio | essencial |

O pergaminho **estica na altura**, porque a receita pode ter de 1 a 4 ingredientes. Por isso os **rolos de cima e de baixo** ficam fixos e o **papel do meio** precisa ser liso, sem mancha nem dobra que estique feio. Se quiser manchas ou queimadinhos de enfeite, mande como peça separada, que eu ponho por cima. Deixe uns 12% de margem nas laterais do papel para o texto não encostar na borda. O X de desafixar continua o mesmo.

## 4. Ícones dos kits (pedido junto, 17/11)

Os ícones de hoje (morango, picareta, mochila, medalha) são genéricos. A ideia é ter um ícone **trabalhado por kit**. *Chamada minha:* eles entram em três lugares: o cartão da gamepass na loja, a linha do kit no painel de kits do menu (hoje é o modelo 3D de um item) e, com fundo, o ícone da gamepass no site do Roblox (substituem as peças 24–27).

**Para os kits parecerem da mesma família:** todos com a mesma composição, um **recipiente aberto com os itens principais saindo dele**. O recipiente e o material sobem junto com o kit: pano → couro → baú de madeira → baú reforçado de ouro. Cada um tem um **brilho de fundo na cor do tier**, que já marca o valor antes de ler o nome. Mesmas regras de sempre: 512×512, fundo transparente, sem texto, silhueta que lê pequena no celular.

| # | Kit | O que vem nele | Ideia de ícone | Cor do brilho | Prioridade |
|---|---|---|---|---|---|
| 30 | **Inicial** (`kit_starter`) | 10 bagas, 20 madeiras, 20 pedras, picareta de madeira, fogueira | trouxa de pano amarrada num graveto, com a picareta de madeira atravessada, galhos e um raminho de bagas para fora | madeira clara | essencial |
| 31 | **Explorador** (`kit_explorer`) | 16 bagas, 40 madeiras, 40 pedras, picareta de pedra, 2 fogueiras | mochila de couro aberta, picareta de pedra presa na lateral, pedras e toras aparecendo; uma bússola pendurada de enfeite | cinza-pedra | essencial |
| 32 | **Sobrevivente** (`kit_survivor`) | 20 bagas, 140 madeiras, 80 pedras, picareta de ouro, 2 fogueiras grandes | baú de madeira aberto, cheio de toras e pedras, picareta de ouro por cima e uma chama da fogueira grande saindo de dentro | laranja-brasa | essencial |
| 33 | **Veterano** (`kit_veteran`) | 30 bagas, 200 madeiras, 200 pedras, 20 de ouro, picareta e espada de ouro, 4 fogueiras grandes | baú reforçado com cantos de metal, espada e picareta de ouro cruzadas na frente, pepitas de ouro transbordando | dourado | essencial |
| 34 | **VIP** (`kit_vip`) | 20 bagas, 120 madeiras, 80 pedras, picareta de pedra, fogueira grande, 8 paredes de madeira | baú nobre na **cor do VIP**, com uma coroa pequena ou brasão na tampa, uma parede de madeira encostada e a picareta saindo | dourado-brasa do VIP | essencial |
| 35 | **Caçador** (`kit_hunter`, conquista) | 15 carnes assadas, lança de pedra, 10 paredes, 2 fogueiras, 10 bagas | bolsa de caça de pele, lança de pedra atravessada e um pedaço de carne assada | vermelho-terra | bom ter |
| 36 | **Guardião** (`kit_guardian`, conquista) | 300 madeiras, 300 pedras, 60 de ouro, picareta, espada e capacete de ouro, 4 fogueiras grandes | capacete de ouro em cima de um baú, espada cravada ao lado | azul-real | bom ter |

As ideias são sugestões: pode mudar o recipiente ou os itens, desde que a família continue (mesmo enquadramento, mesmo ângulo, recipiente que sobe de nível). O bom ter são os kits de conquista, que só aparecem para quem já tem.

## 5. Fundos em camadas, para animar (pedido junto, 17/11)

Os efeitos dos fundos vêm **separados** para animar por código: os raios giram devagar, o brilho pulsa e as faíscas sobem e somem. **Os efeitos vêm em branco**, e eu tinjo por código (`ImageColor3`), então um jogo só de efeitos serve para todas as cores: tier do kit, VIP, raridade.

**Efeitos comuns (um jogo só, branco):**

| # | Camada | Como fazer | Tamanho |
|---|---|---|---|
| 37 | **Raios de luz** | raios saindo do **centro exato**, sumindo antes da borda (nada pode encostar na borda, senão os cantos aparecem quando girar) | 1024×1024 |
| 38 | **Brilho (halo)** | mancha redonda, mais forte no meio e sumindo suave até a borda | 1024×1024 |
| 39 | **Faíscas** | 4 desenhos soltos: estrela de 4 pontas, ponto redondo, cruz fina e brasinha | 128×128 cada |

**Por peça, o que muda (base e moldura separadas dos efeitos):**

| # | Peça | Camadas | Observação |
|---|---|---|---|
| 40 | **Cartão do VIP** (substitui a peça 2) | base (papel/madeira com a cor do VIP) + moldura por cima | os efeitos ficam entre a base e a moldura |
| 41 | **Cartões da loja** (os 5 de hoje: vermelho, roxo, verde, azul, laranja) | base **neutra** + moldura | com a base neutra tingida e os raios separados, os 5 viram 1 só |
| 42 | **Ícones dos kits** (30–36) | **só o kit, sem o brilho de fundo** | o brilho do tier vem das camadas 37/38 tingidas |
| 43 | **Cartão do dia 7** do check-in | base + moldura | raios e faíscas por código |
| 44 | **Cartão Premium** | base + moldura | bom ter |

**Regra de encaixe:** a base e a moldura de uma mesma peça vêm **do mesmo tamanho e alinhadas** (empilhadas, uma por cima da outra, se encaixam perfeito). A moldura tem o centro **vazio** (transparente).

## Já temos e vou reaproveitar

Moeda Golden Ember e pilhas de moedas, botões verde e laranja, fita, fundos dos cartões da loja, fundos das raridades, cadeado do HUD, moldura e bolinha das missões, símbolo do Robux e o ícone de giro especial.
