# Pedra da ressurreição e fantasma

Como no Starve: quem morre com um **Coração de Dragão no inventário** ou **vestindo a Coroa do Anjo**, havendo alguma Pedra da Ressurreição no mundo, vira **fantasma** em vez de morrer. Design: `docs/superpowers/specs/2026-11-11-construcoes-design.md` (Parte D).

## Como funciona

- **Tempo:** 60 s para chegar a uma pedra, a até 6 studs da borda dela (`GhostRules.REVIVE_RADIUS`).
  - **Coroa:** o tempo cai pelo item mais forte segurado nos últimos 30 s. Diamante dá 35 s, ametista 25, reidite 15, dragão 8 e lava 5; até ouro, 60.
  - **Coração:** sempre 60 s, e o coração é gasto.
  - Com coração e coroa ao mesmo tempo, vale a coroa, que não é gasta (escolha nossa).
- **O fantasma:**
  - não leva dano;
  - as barras não mudam;
  - não bate, não coleta, não constrói, não come, não veste e não crafta;
  - os mobs não o veem;
  - aparece azul translúcido para todos.

  Ele **ainda colide** com construções e recursos (pendência).
- **Ressuscitar:** perto da pedra aparece o botão **Ressuscitar**, com o contador em cima. Ao clicar:
  - volta com a vida e as barras cheias e com **1/3 dos pontos**;
  - perde os itens da lista do Starve (`GhostRules.loses`). Com o coração: armas e escudos, picaretas, chave inglesa, forcados, martelo de reidite e super martelo. Com a coroa: armas e escudos, espinhos, portas com espinho e super martelo.

  **A pedra usada quebra** (pedido do Elizeu, 11/11), e qualquer jogador usa qualquer pedra. Cada jogador tem **uma pedra** no mundo por vez.
- **Tempo acabou:** morte normal, com caixa e tela de morte.
- **Quem matou:** ganha 10% dos pontos da vítima, em vez dos 15% de uma morte normal, e não conta abate.

## Testar no Studio

```lua
local p = game.Players:GetPlayers()[1]
game.ServerStorage.DevPlace:Invoke(p, "resurrection_stone") -- coloca a pedra à frente
game.ServerStorage.DevArmor:Invoke(p, "angel_crown")
game.ServerStorage.DevEndLife:Invoke(p) -- morre → vira fantasma
```

## Onde fica no código

| Arquivo | O que faz |
|---|---|
| `src/shared/Survival/GhostRules.luau` | tempos, itens perdidos e pontos (testes em `tests/ghost.spec.luau`) |
| `src/server/Services/GhostService.luau` | vira fantasma (`DeathService.kill` pergunta antes), timer, `Net.Resurrect` |
| `src/client/UI/GhostPanel.luau` | contador e botão |
| `BonecoRenderer` | brilho azul pelo atributo `GhostUntil` |
