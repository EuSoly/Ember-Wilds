# G7a — Mockups do menu, cosméticos, loja e ranking (design)

Data: 2026-11-02. Conversado com o Elizeu em chat (imagens de referência do Starve: menu lateral, loja de spins/kit, tela de cosméticos, compra de moeda; "UIs simples", "todas as telas, com mocks funcionais, botões e tals", "unificar essas 2 caixas").

## Intenção

A próxima fase grande é a monetização e a progressão (loja, cosméticos, compra de Golden Ember com Robux, ranking, nível). Antes de fazer de verdade, o Elizeu quer **ver como tudo fica no jogo**: todas as telas como **mockups funcionais** — a navegação e os botões respondem, mas nada cobra, sorteia, salva ou equipa de verdade. Ele vai desenhar as telas definitivas depois; aqui elas são **simples**, no visual do HUD atual. A parte de verdade (produtos do Roblox, sorteio, posse e equipar, nível) vira fases seguintes, uma por vez: compra de Golden Ember e menu → cosméticos → spins e kit → ranking e nível.

## Objetivos

- **Menu principal novo** (no estado "menu", como hoje): uma **coluna de botões** — Perfil, Jogar, Cosméticos, Loja, Tutorial, Ranking (o "acesso a servidor" da referência fica de fora: escolha minha). No topo: **nível** com barra de experiência (falsos) e o **saldo de Golden Ember real** (o atributo de hoje) com um **"+"** que abre a compra de Golden Ember. A engrenagem de configurações continua.
- **Jogar** faz o que o menu faz hoje: escolher kit inicial (lista de kits com os pontos para kit) e entrar no jogo.
- **Cosméticos:** categorias **Skins, Acessórios, Mochila, Livro, Caixa** — a referência tinha "caixa de saque" e "caixa de morte"; o Elizeu **unificou numa só** ("Caixa": a skin que aparece quando você mata alguém ou quando morre de outro jeito, como a G6 já faz). Prévia do boneco no meio. Clicar num item marca ele como selecionado na prévia/cartão. Nada é salvo.
- **Loja (Golden Ember):** **spins** em três faixas (skin e "custom", como na referência) e **kit inicial temporário** (nasce com livro e mochila por 1 h ou 24 h). Comprar mostra **"compra simulada"**. O spin roda uma animação simples e mostra um **resultado falso** — e a **tabela de chances** aparece antes de girar (regra do Roblox para item aleatório pago; já fica no lugar certo).
- **Comprar Golden Ember (Robux):** 5 pacotes (do Elizeu, provisórios): 300 = 80 R$, 600 = 150 R$, 2.600 = 600 R$ ("Popular"), 7.000 = 1.500 R$ ("30% off"), 20.000 = 3.500 R$ ("Melhor oferta"). Comprar mostra "compra simulada".
- **Ranking, Perfil, Tutorial:** listas e textos de exemplo (ranking com nomes e pontos falsos; perfil com nível e algumas estatísticas falsas; tutorial com alguns passos de texto).
- **Fechar/voltar** em toda tela; tudo marcado visivelmente como **mockup**.

## Não-objetivos

- Produtos do Roblox de verdade (developer products, `ProcessReceipt`), gastar Golden Ember, sortear de verdade, posse e equipar de cosméticos, kit temporário de verdade, nível e experiência de verdade, ranking global de verdade (DataStore ordenado). Cada um é uma fase seguinte.
- Arte definitiva (o Elizeu faz depois, como moldes).
- Mudar a HUD de jogo, a tela de morte ou as configurações.

## Anti-objetivos

- Mockup que mexe em dado de verdade (saldo, posse, inventário, perfil salvo) ou que chama compra do Roblox.
- Números e nomes falsos espalhados pelo código: ficam **num arquivo só** de dados de mockup, fácil de editar e de apagar depois.
- Quebrar o fluxo atual de entrar no jogo (Jogar e kits continuam funcionando).

## Como funciona (decisões)

- As telas novas são montadas **em código com Vide** (como o HUD), não como moldes do Studio: são provisórias; quando o Elizeu desenhar as definitivas, elas viram moldes ligados por nome (o padrão de `docs/guia/telas.md`). Escolha minha.
- Navegação no próprio menu (painéis que trocam no lado direito da coluna); o estado de tela "menu" continua sendo o único.
- Um módulo de dados de mockup (`MockStore` ou parecido) com os pacotes, spins, preços, chances, itens de cosmético falsos, ranking e perfil falsos.
- Textos por `Strings` (pt-BR), cores do `Theme`, tamanhos que funcionam no celular (mínimos de toque), como o HUD.
- **O menu atual (molde `MainMenu`: saldo, Jogar, kits, engrenagem) fica como está** e vira o painel **Jogar**, aberto por padrão; a coluna de botões e a barra do topo são um `ScreenGui` novo em Vide, visível só no estado "menu"; os outros botões abrem o painel deles por cima da área do menu atual (que se esconde enquanto outro painel está aberto) e "Jogar" volta a ele. Assim o fluxo de entrar no jogo não muda (escolha minha).
- **Saldo de Golden Ember real e ao vivo** na barra do topo e nas telas de Loja e Compra (lê o atributo `Currency` do Player, como o menu atual); nível, experiência, ranking e perfil são falsos (escolha minha).
- **Prévia do boneco nos Cosméticos:** o boneco de verdade (`BonecoModel`) num `ViewportFrame`; na categoria **Skins**, os itens são as skins de corpo que já existem (`Defs.Cosmetics`, slot `body`) e clicar troca a cor da prévia; nas outras categorias, cartões falsos que só marcam "selecionado" (escolha minha). Nada é salvo.
- **Marca de mockup:** um selo "MOCKUP" na barra do topo, visível em todas as telas do menu (escolha minha).

## O que fica para quem implementa

O layout exato de cada painel, os nomes dos itens falsos, a animação do spin, como marcar "mockup" na tela, a organização dos arquivos.
