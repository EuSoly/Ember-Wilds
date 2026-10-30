# G3 — Crafting (design)

Data: 2026-10-30. Conversado com o Elizeu em chat ("perfeito, pode fazer o plano"), com prints do Starve.io como referência.

## Intenção

Transformar os recursos da coleta em ferramentas, armas, armaduras e peças de base, **do jeito do Starve.io**: o canto da tela mostra o que dá para fazer agora, um clique começa, o item fica com uma barra enchendo, uma engrenagem gira em cima da cabeça e, no fim, o item entra no inventário. É o que dá sentido à coleta e prepara a construção (próxima fase).

## Objetivos

- **Coluna de receitas** (HUD, esquerda, abaixo dos pontos): só as receitas que dá para fazer **agora** (materiais + estação perto, quando pede). Clique/toque começa. Passar o mouse/segurar o dedo mostra nome, materiais e tempo.
- **Livro de receitas**: botão na HUD abre uma janela (molde editável no Studio) com **todas** as receitas, o que cada uma pede, onde se faz e quanto tempo leva; o que falta aparece marcado.
- **Craftando**:
  - os materiais saem na hora;
  - o ícone da receita fica na coluna com uma barra enchendo por cima até o fim;
  - **engrenagem girando em cima da cabeça** com um arco de progresso em volta (como no print do Starve), visível para todos;
  - o boneco **anda e come normalmente, mas não ataca nem coleta**; um craft por vez;
  - **botão direito cancela** e devolve os materiais (no celular: tocar de novo no ícone que está craftando).
- **Livro (item)**: segurado na mão ao começar o craft, deixa 3× mais rápido.
- **Estações**: algumas receitas pedem estar perto de uma **bancada** ou de um **fogo**. Nesta fase bancada e fogueira aparecem por comando de teste; colocar no chão é da construção.
- **Vestir**: com um capacete, o protetor de orelha ou a mochila na mão, apertar o botão de usar veste (a armadura/mochila anterior volta para o inventário). Assim os capacetes já protegem e o protetor já segura o frio (armadura da G1).
- Estatística `items_crafted` (por item) a cada craft concluído.

## Não-objetivos

- Colocar no chão bancada, fogueira, paredes, portas, espinhos e baú (fase de construção, logo depois). Aqui eles só são craftados e ficam no inventário.
- Dano das espadas e lanças (fase de combate). Aqui só são craftadas.
- Mobs e seus drops (pele, linha, carne).
- Tirar a armadura sem pôr outra, armadura aparecendo no boneco.

## Receitas

"Bancada" = precisa estar perto de uma bancada; "fogo" = perto de uma fogueira. Tempos sem o livro.

| Item | Receita | Tempo | Onde |
|---|---|---|---|
| Picareta de madeira | 10 madeira | 5 s | — |
| Picareta de pedra | 50 madeira, 15 pedra, picareta de madeira | 15 s | bancada |
| Picareta de ouro | 40 madeira, 30 pedra, 20 ouro, picareta de pedra | 20 s | bancada |
| Espada de madeira | 30 madeira | 5 s | — |
| Espada de pedra | 50 madeira, 25 pedra, espada de madeira | 15 s | bancada |
| Espada de ouro | 60 madeira, 50 pedra, 40 ouro, espada de pedra | 20 s* | bancada |
| Lança de madeira | 40 madeira | 5 s | — |
| Lança de pedra | 60 madeira, 10 pedra, lança de madeira | 15 s | bancada |
| Lança de ouro | 80 madeira, 30 pedra, 30 ouro, lança de pedra | 20 s* | bancada |
| Capacete de madeira | 50 madeira | 5 s | — |
| Capacete de pedra | 75 madeira, 75 pedra, capacete de madeira | 20 s | bancada |
| Capacete de ouro | 90 madeira, 90 pedra, 90 ouro, capacete de pedra | 20 s* | bancada |
| Bancada | 30 madeira, 10 pedra* | 10 s* | — |
| Fogueira | 25 madeira, 5 pedra | 10 s | — |
| Fogueira grande | 35 madeira, 10 pedra, fogueira | 15 s | — |
| Parede de madeira / pedra / ouro | 20 madeira / 17 pedra / 14 ouro | 5 s | bancada |
| Porta de madeira | 30 madeira | 8 s | bancada |
| Porta de pedra | 27 pedra, porta de madeira | 8 s | bancada |
| Porta de ouro | 24 ouro, porta de pedra | 8 s | bancada |
| Espinho de madeira | 40 madeira, 30 pedra, parede de madeira | 20 s | bancada |
| Espinho de pedra | 70 pedra, parede de pedra | 20 s | bancada |
| Espinho de ouro | 40 ouro, 30 pedra, parede de ouro | 20 s | bancada |
| Baú | 25 madeira, 2 ouro | 20 s | bancada |
| Papel | 20 madeira | 5 s* | fogo |
| Livro | 4 papel, 10 ouro (provisória**) | 30 s | bancada |
| Protetor de orelha | 30 madeira, 5 ouro (provisória**) | 10 s* | bancada |
| Mochila de couro | 60 madeira, 20 pedra, 5 ouro (provisória**) | 15 s* | bancada |

\* Decisão minha: a wiki não traz o número (usei o vizinho do mesmo tier) ou as fontes divergem.
\*\* Provisória até os mobs (Starve: livro = 4 papel, 4 pele de lobo, 4 linha; protetor = 1 pele de coelho, 2 linhas; mochila = 5 pele de lobo, 6 linhas). Trocar = mudar só os dados.

### Itens novos e seus efeitos

- Espadas e lanças: `category = "weapon"`, tier do material, `maxStack = 1`. (Dano na fase de combate.)
- Capacetes: `category = "armor"`, `maxStack = 1`, `armor.defense` provisório (madeira 0,1; pedra 0,2; ouro 0,3 — fração do dano de combate; o combate ajusta).
- Protetor de orelha: `armor = { coldFactor = 0.7 }` (frio cai 30% mais devagar; decisão minha).
- Bancada, fogueira, fogueira grande, paredes, portas, espinhos, baú: `category = "placeable"`, empilham (`maxStack` 255).
- Papel: recurso. Livro: `category = "misc"`, `craftSpeed = 3`, `maxStack = 1`.

### Números do sistema (decisões minhas)

- Estar "perto" de uma estação = até 10 studs (vista de cima) do centro dela.
- A estação só é conferida **ao começar**; andar para longe no meio não cancela (o boneco pode andar enquanto crafta).
- Se o resultado não couber no inventário (contando o espaço que os materiais liberam), o craft nem começa: aviso "Inventário cheio".
- Cancelar devolve tudo; morrer no meio perde tudo (a morte já zera o inventário).

## Como funciona (decisões)

- **Dados**: `Defs/Recipes` (uma entrada por receita: resultado, quantidade, materiais, tempo, estação, ordem no livro), validados em `Validate` como o resto.
- **Regras puras** (testáveis): pode craftar (materiais + estações perto)? quanto tempo (livro)? cabe no inventário? lista das receitas possíveis em ordem.
- **Servidor**: `CraftService` recebe pedidos (Blink: começar com o id da receita, cancelar), confere tudo, tira os materiais, marca no personagem o que está craftando e até quando (atributos), entrega no fim. O golpe de coleta e o swing do boneco param enquanto há craft.
- **Estações**: modelos com a tag `CraftStation` e o atributo `Station` ("workbench" ou "fire"). A fogueira já ganha; a bancada é um modelo provisório de peças, criado pelo comando de teste `DevWorkbench`.
- **Cliente**:
  - coluna de receitas na HUD (componente Vide, como a hotbar, usando o ícone provisório de item);
  - livro de receitas como molde (`assets/ui`), aberto por um botão de livro ao lado da engrenagem de configurações;
  - a engrenagem em cima da cabeça de cada boneco que está craftando (BillboardGui), girando, com o arco de progresso no estilo dos anéis da HUD;
  - botão direito → cancelar.
- **Vestir**: um serviço pequeno escuta o botão de usar com armadura ou mochila na mão e veste (tira 1 do inventário, devolve a anterior).

## Restrições

- Server Authority: o servidor decide tudo; o cliente só pede e mostra.
- Conteúdo é dado: receita nova = uma entrada em `Defs/Recipes` (+ o item em `Defs/Items` e o texto).
- UI de tela inteira em molde (o Elizeu e o amigo redesenham); HUD em código como o resto.

## O que fica para quem implementa

Visual exato da coluna e do tooltip, posição fina da engrenagem, ícones provisórios, ordem das receitas no livro.
