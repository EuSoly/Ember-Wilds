# Modo criativo

No modo criativo o livro de receitas mostra **todos** os itens, inclusive os só-de-teste. A ficha ganha o botão **Pegar**: um clique entrega uma ferramenta, ou uma pilha de até 100 de recurso e comida. Quem está no criativo **não ganha pontos, ranking nem estatísticas**. Vale também no jogo publicado. Design: `docs/superpowers/specs/2026-11-11-modo-criativo-design.md`.

## Ligar e desligar

A marca fica no perfil salvo do jogador, no campo `Creative` (`true` ou `false`). Ela vale a partir da próxima vez que o perfil carregar.

- **Jogo publicado:** edite o perfil `Player_<UserId>` no DataStore do jogo (Creator Hub → Data Stores, ou um editor de DataStore) e troque `Creative` para `true`. O jogador precisa entrar de novo.
- **Studio:** na vista do servidor, com o jogo rodando:

```lua
local p = game.Players:GetPlayers()[1]
game.ServerStorage.DevCreative:Invoke(p, true)  -- liga (grava no perfil e já vale)
game.ServerStorage.DevCreative:Invoke(p, false) -- desliga
```

## O que muda com ele ligado

- **Livro:** o título vira "Modo criativo", as abas mostram os itens de teste e cada ficha tem o botão **Pegar**, ao lado do Fixar. Se o inventário estiver cheio, aparece o aviso "Inventário cheio".
- **Itens de teste:** valem para esse jogador no inventário, no craft (a coluna também mostra essas receitas) e na construção, como se fosse o Studio.
- **Sem progresso:**
  - pontos da vida (`ScoreService`), e com eles o Golden Ember e o XP;
  - ranking semanal, vida e abates (`RankService`);
  - estatísticas do perfil (`StatsService`), incluindo mortes e tempo jogado.
- **Abate:** matar um jogador que está no criativo não conta abate para quem matou.
- **Itens não passam para os outros:** ao morrer, o jogador do criativo não deixa caixa (os itens somem com ele), e não consegue guardar em baú. Assim ninguém farma com os itens dele.

O resto do jogo é igual: fome, frio, dano, mobs e morte continuam valendo.

## Segurança

Só o servidor escreve a marca. O atributo `Creative` do Player é cópia do perfil e serve só para a tela. O pedido de item (`Net.CreativeGive`) confere a marca **no perfil**, o personagem vivo e o item, e aceita no máximo um pedido a cada 0,2 s (`CreativeRules.GIVE_EVERY`).

## Onde fica no código

| Arquivo | O que faz |
|---|---|
| `src/server/Services/CreativeService.luau` | marca, atributo, `DevCreative` e entrega |
| `src/shared/Creative/CreativeRules.luau` | quanto entrega e o intervalo (testes em `tests/creative.spec.luau`) |
| `src/shared/ItemAccess.luau` | `allowsTest`: Studio ou criativo liberam os itens de teste |
| `src/client/CreativeState.luau` | o cliente acompanha o atributo |
| `src/client/Screens/RecipeBookScreen.luau`, `UI/BookSheet.luau`, `CraftState.luau` | livro, Pegar e coluna de craft |
