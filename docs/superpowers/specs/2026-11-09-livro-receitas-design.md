# Livro de receitas (guia de craft e recursos) — design

Data: 09/11/2026 · Branch: `ui-jogo` · Rascunho visual aprovado: `.superpowers/brainstorm/9399-1794237875/content/livro-v1.html`

## Por quê

O livro atual (`src/client/Screens/RecipeBookScreen.luau`, molde `RecipeBook`) é uma lista de receitas. O jogador não descobre **como conseguir** as coisas: de onde vem cada recurso, o que precisa por perto para craftar, quanto tempo leva, nem o que o item faz (dano, defesa, vida). O Elizeu se inspirou na tela de receitas do Starve.io (categorias → grade → ingredientes ao lado), mas quer mais informação e **a identidade visual do Ember Wilds** (couro, madeira e papel do HUD). Não é cópia 1:1 da tela do Starve.

## O que é

Uma tela só, aberta pelo botão redondo do livro (`RecipeBookButton`), com:

- **Abas em cima**: Ferramentas, Armas, Armaduras, Comida, Construções, Recursos.
- **Grade de itens à esquerda** (slots de couro com o ícone 3D do `ItemIcon`, sem moldura de tier, como na hotbar). Item selecionado com a borda dourada (`SLOT_SELECTED`).
- **Ficha à direita**, num papel (texto escuro, fonte do HUD), com o item selecionado.

O livro **só mostra informação**. Craftar continua sendo pela coluna de receitas do HUD (`CraftColumn`).

### Ficha de item de craft

1. Nome e material (tier, na cor escurecida como na dica do item) e a categoria.
2. **Como fazer**: os ingredientes com ícone e quantidade (um ingrediente pode ser outro item, ex. Espada de Pedra; clicar nele abre a ficha dele).
3. **Precisa de**: estação (o campo `station` da receita: hoje bancada ou fogo; **água** vem depois, ver abaixo) e o **tempo** do craft (`CraftRules.duration`; sem item na mão).
4. **Dados**, conforme o tipo, lidos dos campos do item em `Defs/Items`:
   - arma/ferramenta: dano em mob, dano em construções, nível de picareta, velocidade ao segurar, tempo presa na mão (`equipLock`), alcance;
   - armadura: defesa (%), frio mais devagar (%);
   - construção: vida, dano dos espinhos;
   - comida: repõe fome / sede / vida;
   - mochila: espaços.
   Reaproveita a lógica de `UIFlow/ItemInfo` (que hoje limita a 3 linhas para a dica; a ficha mostra todas).

### Ficha de recurso (aba Recursos)

1. Nome.
2. **Onde conseguir**, montado dos Defs (nada escrito à mão):
   - mobs que deixam o item ao morrer (`Defs/Mobs` → `loot`): retrato do mob (3D do `Assets.Mobs/<id>`, em ViewportFrame) + nome + quantidade;
   - recursos do mapa que dão o item na coleta (`Defs/Resources` → `gather`): ícone do recurso (árvore, rocha, veio de ouro, arbusto, pedrinha) + a ferramenta mínima;
   - receita, se o recurso também é craftável (ex. carne assada no fogo).
3. **Serve para**: os itens cujas receitas usam este recurso (clicar abre a ficha).

Itens "primários" = tudo que não tem receita (categoria `resource`, carne crua, frutinha, peles, pena, linha...). Um item com receita **e** loot mostra as duas coisas.

### Que item vai em que aba (decisão do Claude, para o Elizeu conferir)

Um item pode aparecer em **mais de uma aba**; a ficha é a mesma nas duas.

| Aba | Itens |
|---|---|
| Ferramentas | categoria `tool` + `misc` (livro, balde) |
| Armas | `weapon` |
| Armaduras | `armor` + `bag` (mochila: é o que se veste) |
| Comida | `food` (inclui frutinha e carne crua, que também estão em Recursos) |
| Construções | `placeable` |
| Recursos | categoria `resource` (inclusive os feitos, ex. papel, que mostram a receita) + a comida crua (`food` sem receita). Construção/ferramenta sem receita não entra (ajuste de 09/11) |

A pedrinha do mapa (`pebble`) é decorativa e não dá item: **não aparece** em "onde conseguir" (decisão do Claude). Se um dia ela ganhar `gather`, entra sozinha.

### Regras

- Itens fora do jogo (`ItemAccess.isAvailable` falso fora do Studio) não aparecem.
- Itens que o jogador ainda não pode fazer agora (falta material ou estação) aparecem **apagados**, mas clicáveis: a ficha abre igual.
- Abre na última aba usada (na sessão); a primeira vez, Ferramentas, com o primeiro item selecionado.
- Funciona no celular: slots ≥ 44 px, a grade rola se não couber, a ficha rola se o texto for grande.
- Sem a arte nova (ids vazios), cai no visual por código (painel, slots e papel que já existem), como o resto do HUD.

### Água como requisito de craft (futuro, decidido pelo Elizeu)

Vão existir receitas que precisam de **água por perto**. Isso não é feito agora (é regra de jogo: o tipo `CraftStation` ganha `"water"`, o servidor confere a distância da água no `CraftService`/`CraftRules`, o `Validate` aceita, e o `CraftState` do cliente mostra a receita só perto da água). O livro já deve nascer pronto para isso:

- a ficha monta "Precisa de" a partir de uma tabela **estação → ícone e texto** (não um `if` por estação), com `water` já na tabela (ícone de água + "Perto da água");
- quando a primeira receita com `station = "water"` existir, o livro mostra sozinho, sem mudar a tela.

## Fora do escopo

- Craftar pelo livro, fila de craft, favoritos.
- Busca por texto.
- Mapa de onde fica cada bioma (o minimapa é outra tarefa, adiada).
- Textos de lore/descrição livre dos itens.

## Seria um fracasso se

- A informação ficasse escrita à mão e saísse do sincronia com os Defs (tem que vir dos Defs).
- Parecesse a tela do Starve (cores, formas, botões) em vez do HUD do Ember Wilds.
- Ficasse ilegível no celular ou com texto saindo do papel.

## Como fazer (decidido)

- Lógica pura e testada (Lune) em `src/shared/UIFlow/` — ex. `BookInfo`: itens por aba, ficha de um item (seções e linhas), "onde conseguir" e "serve para". A tela só desenha.
- Tela em Vide, como o resto do HUD, usando `Kit.panel`, `HudArt` e `ItemIcon({ bare = true })`; textos em `Strings/ptBR.luau`.
- Ids da arte nova em `HudImages` (id vazio = desenho por código).

## Deixado para quem constrói

- Se o livro novo substitui o molde `RecipeBook` (UITemplates) ou é só código Vide — preferência: só código, como o HUD novo.
- Ordem dos itens em cada aba (sugestão: pela ordem/tier das receitas).
- Medidas exatas e animações (troca de aba, seleção).

## Assets para o Elizeu criar

Estilo: o mesmo da arte do HUD (madeira com contorno escuro grosso, couro, papel creme), vista chapada, PNG com fundo transparente. Já existem e serão reaproveitados: painel de couro, slot e slot selecionado, cadeado, papel do balão, placa de madeira do título, botão redondo, ícones de status (vida, fome, frio, calor, sede, fôlego), ícone de mochila.

| # | Asset | Tamanho | Como deve ser |
|---|---|---|---|
| 1 | Aba normal | 256×96 | Plaquinha de madeira para o nome da aba, cantos chanfrados; esticável no meio (cantos não podem ter detalhe no centro). |
| 2 | Aba selecionada | 256×96 | A mesma aba, mais clara/dourada (como o slot selecionado), parecendo "puxada" para frente. |
| 3–8 | Ícones das abas (6) | 128×128 cada | Ferramentas (picareta + martelo cruzados), Armas (espada), Armaduras (capacete), Comida (carne/pão), Construções (parede de madeira ou fogueira), Recursos (tora + pedra). Silhueta clara com contorno escuro, para ler em cima da madeira. |
| 9 | Papel da ficha | 512×640 | Folha de papel creme com borda escura (como o balão de dica, sem a pontinha), cantos que não deformam ao esticar. |
| 10–13 | Ícones "Precisa de" (4) | 64×64 cada | Bancada, Fogo, Água (para as receitas futuras perto da água), Relógio (tempo). |
| 14–20 | Ícones dos dados (7) | 64×64 cada | Dano (espada), Dano em construções (martelo batendo numa parede), Velocidade (bota), Presa na mão (ampulheta ou cadeado), Defesa (escudo), Alcance (seta), Nível de picareta (picareta pequena). Frio, vida, fome, sede e mochila usam os ícones que já existem. |
| 21–24 | Ícones dos recursos do mapa (4) | 128×128 cada | Árvore, Rocha, Veio de ouro, Arbusto de frutinhas — vistos de cima/3⁄4, no estilo dos ícones dos itens. (Os mobs usam o próprio modelo 3D, não precisam de arte.) |
| 25 | Ícone de fechar | 128×128 | Um "X" para o botão redondo de madeira (mesmo estilo dos ícones de engrenagem e livro). |

Prioridade se for fazer em partes: 1, 2, 9, 25 (estrutura) → 3–8 (abas) → 10–20 (ícones de informação) → 21–24.
