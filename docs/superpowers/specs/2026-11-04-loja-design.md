# UI 2: Loja (design)

Data: 2026-11-04. Combinada com o Elizeu no chat, com previews no navegador (aprovado na v4). Primeira das telas do menu a ser refeita depois da UI 1 (carregamento, menu e kits). Ordem combinada das próximas: Tutorial sai + Configurações → Perfil → Cosméticos → Ranking.

Preview aprovado: [docs/game-design/propostas/loja-v1/preview.html](../../game-design/propostas/loja-v1/preview.html) (abrir no navegador; tudo clicável, carrossel e efeitos inclusos). As artes finais estão sendo geradas pelo Elizeu numa IA; até chegarem, o jogo usa placeholders feitos por código no mesmo layout.

## Intenção

Uma loja vistosa, no estilo das lojas de jogos Roblox populares, mas com o visual rústico do Ember Wilds: pacotes em destaque, gamepasses, giros de skin com carrossel no estilo CS:GO e compra de Golden Ember. **Nesta fase tudo é simulado** (como os mockups da G7a): visual e fluxo completos rodando, sem cobrar e sem salvar. Depois o Elizeu liga cada produto no Creator Hub.

## Decisões do Elizeu

### Geral
- Ao abrir a Loja, o **menu lateral some e a loja ocupa a tela toda**; só o **card da Golden Ember** continua visível.
- Seções, nesta ordem: **Pacotes**, **Gamepasses**, **Giros**, **Golden Ember**. Abas coloridas no topo levam a cada seção (referência: abas tipo "Crates / Passes / Cash").
- Tudo simulado: comprar mostra o aviso de "compra simulada"; nada é cobrado nem salvo. Os produtos ficam num arquivo só para ligar depois.

### Pacotes (bundles)
- Só com Robux. Cada pacote é um **conjunto temático**: skin de corpo, livro, mochila e caixa.
- **Um pacote em destaque por vez**, num banner grande; setas trocam quando houver mais de um (referência: "FEATURED" com contador, lista de itens e preço).

### Gamepasses
- Ficam aqui os **kits permanentes** (os mesmos do painel de kits do menu). O resto das gamepasses o Elizeu ainda vai decidir.

### Giros
- **Um giro para cada tipo de skin**: Skins (corpo), Acessórios, Mochila, Livro e **Caixa** (a caixa de saque e a de morte usam as **mesmas** skins: um tipo só).
- Fluxo: o jogador **escolhe o tipo** (cartões com uma **roleta girando**, no lugar das caixas da referência) → abre a **tela do giro** daquele tipo.
- Na tela do giro:
  - **Carrossel no alto, passando devagar o tempo todo**, mostrando as skins que podem vir; **o fundo de cada skin é a cor da raridade**.
  - Dois lados: **giro com Golden Ember** (chances baixas de raridade alta) e **giro pago com Robux** (chances bem mais altas).
  - **Primeiro compra os giros, depois gira**: botões de comprar (+1, +3, +10), **contador "Você tem N giros"** e botão **GIRAR**.
  - Girar acontece **na mesma tela**: o carrossel acelera, freia e para no prêmio (estilo CS:GO); depois abre **só uma janelinha** mostrando a skin que saiu.
  - **Giro pago tem efeitos** no carrossel e na tela.

### Golden Ember
- Os 5 pacotes de moeda, no estilo dos cartões de dinheiro da referência: **3 em cima e 2 maiores embaixo** (com uma frase), valor grande, pilha de moedas e brilho.

## Escolhas minhas (vistas no preview e aprovadas)

- Topo: placa "◀ Menu" (volta ao menu), placa "LOJA", as 4 abas e o card da Golden Ember. A aba da seção visível fica destacada enquanto rola; o "+" do card leva à seção Golden Ember.
- Página única que rola, com título de seção ("PACOTES EM DESTAQUE", "GAMEPASSES", "GIROS · ESCOLHA O TIPO", "GOLDEN EMBER").
- Destaque: contador de tempo, raridade, lista do que vem com ícones, preço; troca sozinho a cada 6 s (pausa com a tela do giro aberta); bolinhas de página.
- Gamepasses: os 4 kits permanentes (preços de `MockStore.KIT_ROBUX`) + **VIP (+3 espaços)**, que já está preparado no jogo; marcados como **provisórios**.
- **Raridades (decisão do Elizeu depois do preview): os 6 níveis do jogo, com as cores dos tiers** (pilar "tier é cor" da identidade visual; `Defs/Tiers`, `Palette.tier`, textos `rarity.*`): Comum (madeira #8B5A2B), Incomum (pedra #8A8F98), Raro (ouro #F2B632), Épico (diamante #3FD0E0), Mítico (ametista #9B5DE5), Lendário (reidite #D63384). O preview de 4 raridades fica só como referência de layout.
- Chances provisórias: **normal 60 / 25 / 10 / 4 / 0,9 / 0,1 %**, **pago 30 / 25 / 20 / 15 / 7 / 3 %** (de comum a lendário). A tabela de chances fica **sempre visível antes de girar** (regra do Roblox para item aleatório pago).
- O carrossel ocioso mostra as raridades misturadas (pesos 30 / 25 / 18 / 13 / 9 / 5, só visual).
- Preços provisórios dos giros: normal **100 / 280 / 850** Golden Ember (1 / 3 / 10); pago **49 / 129 / 399** Robux.
- Contadores de giros: **separados por tipo e por giro normal/pago**.
- Efeitos do giro pago: raios de luz girando atrás da janela, brilho pulsando, borda colorida correndo no carrossel, faíscas atravessando, marcador piscando; ao parar, clarão e tremida. Janelinha do prêmio: raios na cor da raridade e confete (20 / 30 / 50 / 80 / 110 / 140 peças de comum a lendário; no giro normal só a partir de raro, com 20).
- Golden Ember: fitas "POPULAR", "-30%", "MELHOR" (as tags que já existem em `MockStore.PACKS`); frase dos cartões grandes "Receba na hora N Golden Ember".

## Escolhas minhas (aprovadas pelo Elizeu no chat: "está tudo certinho")

- **O painel "Comprar Golden Ember" deixa de existir**: o "+" do card abre a Loja já na seção Golden Ember (o `BuyPanel` sai). O painel de kits do menu continua (é a escolha de kit antes de jogar; os kits permanentes aparecem nos dois lugares e usam o mesmo estado de mockup do `KitShop`: comprar "para sempre" na loja libera o "Usar" no painel de kits).
- **Comprar giros com Golden Ember não desconta o saldo** (mockup: o saldo continua só leitura, regra da G7a). A compra simulada só soma no contador. **Mas exige saldo suficiente** (decisão minha depois da revisão): sem saldo, o botão fica apagado mostrando "faltam N", como os kits de pontos; assim o fluxo já é o da compra real.
- **O prêmio não é salvo nem equipado** (Cosméticos de verdade é a próxima fase). A janelinha só mostra o que saiu.
- **Itens dos giros e dos pacotes são de mentirinha**, num lugar só (`MockStore`), com nome, raridade e cor; o carrossel desenha cada skin como um quadradinho (corpo: carinha do boneco na cor da skin; os outros tipos: um ícone simples por tipo) até existirem os modelos/ícones reais.
- **Placeholders das artes**: madeira e botões já existem (placa e botão laranja). Roleta, fundos de cartão com raios, banner, ícones das abas, botão verde do Robux, pilhas de moedas e fita são desenhados por código (UIGradient, UIStroke, Frames). Cada arte nova entra no `UiImages` com fallback, como no menu.
- No celular (compacto), a loja continua em tela cheia; as grades viram menos colunas (Gamepasses 5 → 3, Giros 5 → 3, Golden Ember 3+2 → 2+2+1) e o banner encolhe; a tela do giro empilha os dois lados se não couber lado a lado.
- O carrossel e os efeitos só rodam com a tela do giro aberta (nada animando no fundo à toa); a roleta dos cartões gira só com a seção visível.

## O que existe e muda

| Hoje | Depois |
|---|---|
| `ShopPanel.luau` (giros e kit do G7a, painel ao lado da coluna) | Loja nova em tela cheia (pasta `src/client/Menu/Shop/`) |
| `BuyPanel.luau` (pacotes de Golden Ember) | Sai; vira a seção Golden Ember da loja |
| `MockStore.SPINS`, `MockStore.KIT` (giros e kit antigos) | Saem; entram o catálogo novo (pacotes, gamepasses, tipos de giro e seus itens, chances, preços) |
| `MenuState` painel `"buy"` | Sai; o "+" abre `"shop"` na seção Golden Ember |
| `MenuShell` | Com `"shop"` aberto esconde coluna, nível, logo, boneco/Kits/JOGAR e a árvore; mantém o card da Golden Ember |

## Restrições

- Mockup: nenhum evento de rede, nenhum atributo escrito, nenhum `MarketplaceService`; o saldo nunca muda.
- Regras puras (sorteio, carrossel, contadores) em `src/shared/UIFlow`, testadas no Lune.
- Design system rústico + as artes já enviadas (placa, botão laranja, moeda); textos em `ptBR.luau`; alvos de toque ≥ 44 px; compacto = largura < 900 ou altura < 500.
- Código legível para nível médio, `--!strict`, comentários do porquê em pt-BR; `bash scripts/check.sh` verde; atualizar `docs/guia/telas.md` e o graphify.

## Fora desta fase

- Cobrança real (gamepasses, dev products), salvar posse e equipar prêmios.
- Skins reais de acessório, mochila, livro e caixa (vêm na fase de Cosméticos).
- Aba de códigos, gamepasses além dos kits e do VIP.
- As artes finais (o Elizeu está gerando; entram quando chegarem).

## Deixado para quem implementa

- Divisão dos arquivos da loja e como animar (RenderStepped/TweenService) mantendo leve.
- Desenho exato dos placeholders.
- Tempo exato da freada do carrossel (referência: 5,2 s, desaceleração forte no fim) e quanto o prêmio pode parar fora do centro (referência: até 35% de um quadradinho).
