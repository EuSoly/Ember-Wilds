# Modo criativo (design)

Data: 11/11/2026 · Branch: `criativo`

## Por quê

O Elizeu quer testar e mostrar os itens sem farmar: um modo criativo ligado **pelo perfil salvo do jogador**, que libera todos os itens no livro de receitas e entrega o item quando ele pede.

## Decisões do Elizeu (11/11)

- Vale **também no jogo publicado** (para quem tiver a marca no perfil).
- **Todos os itens livres**, inclusive os `testOnly`.
- Com o criativo ligado, o jogador **não recebe pontos nem ranking**.

## Como funciona

- **Marca no perfil:** `Creative = false` no `ProfileTemplate` (perfil antigo ganha o campo pelo Reconcile, sem subir o SchemaVersion). Quando o perfil carrega, o servidor copia a marca para o atributo `Creative` do Player (só o servidor escreve; o cliente só lê para a tela).
- **Ligar e desligar:** no jogo publicado, editando o perfil no DataStore (`Creative = true`). No Studio, com o comando `ServerStorage.DevCreative:Invoke(player, true/false)`, que grava no perfil e no atributo.
- **Itens de teste:** quem está no criativo é tratado como se estivesse no Studio pelo `ItemAccess` (inventário, craft, construção, livro). Um lugar só decide: `ItemAccess.allowsTest(inStudio, creative)`.
- **Pegar item:** o livro mostra todos os itens das abas (com os de teste). Com o criativo ligado, a ficha ganha o botão **Pegar**. O clique manda o evento `CreativeGive { Id }`. O servidor confere três coisas: a marca no perfil, o personagem vivo e que o item existe. Aí entrega `min(maxStack, 100)` unidades: ferramenta 1, recurso 100. Se não couber, avisa que o inventário está cheio. Os pedidos são limitados a um a cada 0,2 s.
- **Sem pontos e sem ranking:**
  - **Bloqueado no criativo:** `ScoreService.add`, `RankService.addLife`, `RankService.addKill` e `StatsService.add`/`record`.
  - **Golden Ember e XP:** saem dos pontos, então ficam zerados também.
  - **Abate de jogador no criativo:** quem mata não ganha ranking nem estatística, para não farmar com amigo.
  - **Escolha minha:** as estatísticas do perfil também não mudam no criativo. Mortes, coletas, tempo jogado e o resto ficam como estavam.
- **Aviso na tela:** o livro mostra "Modo criativo" no topo quando estiver ligado (escolha minha; HUD sem mudança).

## Fora do escopo

Voar, ficar invencível, construir de graça, desligar fome e frio. Dá para acrescentar depois com a mesma marca.

## Testes

Regras puras: `ItemAccess.allowsTest`, a quantidade entregue (`CreativeRules.giveCount`) e o intervalo entre pedidos (`CreativeRules.canGive`). O resto, que é a ligação no servidor e a tela, se confere no Studio.
