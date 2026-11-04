# Cosméticos — design (UI 5)

Data: 04/11. Decisões do Elizeu marcadas como **(Elizeu)**; as minhas, como **(minha decisão)**.

## Por quê

O painel Cosméticos do menu é mockup: a aba Skins pinta uma prévia, mas nada é salvo, e as outras abas são itens inventados. O Elizeu quer os cosméticos **funcionando de verdade**, num layout inspirado numa tela de referência que ele gosta (vitrine do personagem com tudo equipado no meio e as categorias em volta). É a próxima UI da ordem combinada (Perfil → **Cosméticos** → Ranking).

## Objetivos

1. Tela dos cosméticos com a vitrine do personagem e as categorias em volta.
2. Ao abrir uma categoria, escolher a skin numa grade, da Comum à Mítica; equipar salva no perfil e aparece para todo mundo no jogo (onde o item aparece no jogo).
3. Skins que a pessoa não tem aparecem com cadeado e só mostram como ficariam.
4. Ter skins de exemplo suficientes para a tela nascer cheia e testável.

## Fora do escopo

- Ganhar skin pelos giros da loja: os giros continuam simulados (**Elizeu**: dar skin de verdade em giro grátis deixaria todo mundo pegar tudo). Para testar, o comando de dev que já existe dá a posse.
- Skins de livro além do modelo que já existe (**Elizeu**: por enquanto o livro é só o modelo `Assets.Tools.book`).
- Acessórios de verdade (não existe nenhum modelo): o cartão aparece como "em breve".
- Mochila aparecendo no personagem durante o jogo (hoje a mochila não tem visual nenhum no jogo; ela só aparece nas vitrines do menu).
- Artes finais das skins (as de exemplo são troca de cores).
- Usar qualquer imagem da pasta `assets/skins/reference/` (são imagens de outro jogo, só referência).

## O que não pode acontecer

- Equipar uma skin que a pessoa não tem (o servidor valida; o cliente nunca decide posse).
- Copiar textos, ícones ou artes da tela de referência: o layout se inspira nela, o visual é o rústico do Ember Wilds.
- Perder o que está equipado ao sair e voltar.

## Categorias (Elizeu)

Cinco categorias. **A caixa é uma só** (a mesma skin vale para a caixa de saque e a de morte, como já decidido na loja).

| Lado | Categoria | O que é hoje |
|---|---|---|
| Esquerda | **Skins** (corpo) | Real: cores do boneco, já aparecem no jogo para todos |
| Esquerda | **Acessórios** | "Em breve" (sem modelo) |
| Esquerda | **Caixa** | Real: a caixa que nasce quando o jogador morre (a de quem matou, se houver) |
| Direita | **Mochila** | Só nas vitrines do menu (sem visual no jogo ainda) |
| Direita | **Livro** | O livro que o boneco segura no menu. **Uma skin só por enquanto: o modelo que já existe (Elizeu)** |

Mochila e Livro viram slots novos de cosmético (hoje só existem `body` e `crate`), cada um com uma skin padrão que todo mundo tem.

## Tela principal (Elizeu)

- **No meio, uma vitrine grande:** o boneco do jogador com tudo equipado (skin, mochila nas costas, livro na mão). Embaixo da vitrine, a caixa equipada.
- **Dos lados, os cartões:** Skins, Acessórios e Caixa à esquerda; Mochila e Livro à direita. Cada cartão: nome numa placa, uma frase curta nossa e uma amostra das skins que a pessoa tem naquela categoria. Acessórios mostra "Em breve" e não abre.
- Visual rústico do jogo (placas de madeira, corpo escuro como as Configurações e o Perfil).

## Tela da categoria (Elizeu)

- **Esquerda:** a mesma vitrine (mostrando o que está selecionado agora) e, embaixo, o nome da skin selecionada e a raridade, na cor da raridade.
- **Direita:** placa com o nome da categoria e uma **grade 3×3** com setas para passar as páginas.
- **Ordem: da Comum até a Mítica** (dentro da mesma raridade, uma ordem fixa). Cada quadradinho com o fundo na cor da raridade — as mesmas 5 raridades e cores da loja (`MockStore.RARITIES`: Comum #9CA3AF, Raro #3B9DFF, Épico #A855F7, Lendário #FFBD38, Mítico #FF4545).
- **Skin que a pessoa tem:** clicar **equipa** (pedido ao servidor, salva no perfil) e a vitrine mostra; a equipada fica destacada.
- **Skin que a pessoa não tem (Elizeu):** fica escurecida com um **cadeadinho**; clicar **só mostra como ficaria** na vitrine (não equipa).
- **Botão de voltar** para a tela principal (volta a vitrine para o que está equipado).

## Skins de exemplo (Elizeu aprovou)

Feitas trocando cores dos modelos que já existem, espalhadas da Comum à Mítica, para cada categoria real ter pelo menos uma página cheia ou quase:

- **Skins (corpo):** cor do corpo + cor do contorno (como as duas que já existem).
- **Livro:** nenhuma de exemplo. A única skin é o modelo que já existe (**Elizeu**).
- **Mochila:** cor de uma mochila provisória feita de peças (não há modelo), usada só nas vitrines.
- **Caixa:** cores do corpo e das faixas da caixa provisória que o jogo já monta.

Cada skin ganha uma **raridade** (1 Comum … 5 Mítico) nos dados. As skins padrão de cada categoria são Comuns. Os nomes são nossos, em pt-BR. Quando as artes de verdade chegarem, elas substituem as de exemplo (mesmo id ou ids novos).

## A loja usa as skins reais (Elizeu)

O carrossel, as amostras dos cartões e o prêmio dos giros da loja passam a usar as **mesmas skins** dos Cosméticos (com as raridades delas), no lugar dos itens inventados do `MockStore`. O giro continua simulado: mostra o prêmio, mas não dá a skin.

- **(minha decisão)** Categoria sem nenhuma skin real (Acessórios) mostra "Em breve" também na loja e não abre o giro. Livro tem uma skin só: o giro de livro sempre "sorteia" ela, até existirem outras.

## Fácil de personalizar (Elizeu)

Todas as skins ficam **num arquivo só** de dados (`src/shared/Defs/Cosmetics.luau`), que alimenta os Cosméticos **e** o carrossel/giros da loja. Cada skin tem, num lugar só: id, nome (texto em pt-BR), categoria, **raridade**, as cores e, opcional, a **imagem** do quadradinho (quando existir a arte, ela substitui a cor) e se **aparece nos giros da loja** (sim por padrão; a skin padrão de cada categoria não aparece). Mudar a ordem, a raridade, tirar do carrossel ou acrescentar uma skin = editar só essa entrada. O guia ganha um passo a passo "como adicionar ou mudar uma skin", e a validação dos dados avisa erro de digitação (raridade fora de 1–5, categoria inexistente, texto faltando).

## Posse e equipar (minha decisão, por ser o necessário para "de verdade")

- O servidor já guarda posse e equipado no perfil (`Cosmetics.Owned` / `Cosmetics.Equipped`) e já publica o equipado de cada slot como atributo (`Cosmetic_<slot>`, no personagem e no Player).
- **Novo:** o cliente passa a saber **quais skins a pessoa tem** (publicado pelo servidor) e passa a poder **pedir para equipar** uma skin (evento de rede novo). O servidor só equipa se a pessoa tiver a skin e se ela existir; pedido inválido é ignorado em silêncio, com um limite de pedidos por segundo.
- A skin padrão de cada slot conta sempre como possuída.
- O boneco do menu (centro do menu) passa a mostrar também a mochila e o livro equipados.

## Partes deixadas para quem implementar

- Como a posse chega ao cliente (atributos, evento) e o formato.
- As frases dos cartões, os nomes e as cores exatas das skins de exemplo (quantas por categoria, desde que cubram as 5 raridades onde fizer sentido).
- Medidas da tela no PC e no celular (seguir o padrão das outras janelas; no celular, a tela pode empilhar ou rolar).
- A mochila provisória (forma simples de peças, nas costas do boneco).
