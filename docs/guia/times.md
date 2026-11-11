# Times (totem)

Como no Starve: o **Totem** (50 madeira) cria um time. Design: `docs/superpowers/specs/2026-11-11-construcoes-design.md` (Parte E).

## Como funciona

- **Criar:** colocar um totem cria o time do dono, que vira o **líder**. Cada jogador tem **um totem**, e quem está no time de outro não cria o seu.
- **Entrar:** perto de um totem (até 10 studs da borda, `TeamRules.TOTEM_RADIUS`), quem não tem time vê **Entrar no time de X**. Só funciona se o time estiver destrancado e com vaga: **8 jogadores**, contando o líder.
- **Líder:** perto do próprio totem, pode **trancar e destrancar** o time e **expulsar** um membro (o X ao lado do nome).
- **Sair:** qualquer membro sai pelo botão. Quem sai ou é expulso **espera 20 s** para entrar em outro time.
- **O time acaba:**
  - se o **líder sair**, os membros saem e ele fica sozinho com o totem;
  - se o **totem sair do mundo** (destruído, o dono morreu ou saiu do jogo), o time acaba de vez.

  As duas regras são escolha nossa; a wiki não diz.
- **O que muda:**
  - colegas são **aliados**: abrem as portas uns dos outros, usam baús e máquinas, e os espinhos de um não machucam o outro;
  - o golpe entre colegas tira **30%** do dano;
  - os colegas veem o nick uns dos outros em verde;
  - o painel do time fica à esquerda do HUD, e a setinha (`<` / `>`) recolhe e abre.

## Por dentro

- **Quem são os aliados:** o `TeamService` informa o time de cada UserId pelo `BuildRules.setTeamResolver`. Assim o `BuildRules.areAllies`, usado por portas, baús, espinhos e máquinas, passa a valer para o time inteiro.
- **Atributos:** o Player recebe `Team` (UserId do líder). O modelo do totem recebe `TeamLeader`, `TeamLocked` e `TeamSize`.
- **Rede:** `TeamJoin`, `TeamLeave`, `TeamKick` e `TeamLock`. O servidor confere a distância e as regras (`TeamRules`, testes em `tests/team.spec.luau`).
- **Testar:** `game.ServerStorage.DevPlace:Invoke(player, "totem")`. Entrar e expulsar precisam de dois jogadores (Test → 2 Players).
