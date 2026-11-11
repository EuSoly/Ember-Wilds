# Construção: fantasma com o modelo e encaixe em grade (design)

Data: 11/11/2026 · Branch: `melhorias`

## Por quê

Hoje o fantasma de construção é um bloco translúcido, e todas as peças se colocam soltas. O Elizeu quer duas coisas:
- ver a peça de verdade antes de colocar;
- peças de chão e teto se encaixando umas nas outras em grade, como no Starve. Isso já fica pronto para os canteiros de plantação do futuro.

## Decisões do Elizeu (11/11)

- O fantasma é o **modelo do item**, translúcido, verde quando dá para colocar e vermelho quando não dá.
- **Só peças de chão e teto se encaixam:** telhado, ponte e, no futuro, canteiros. Paredes, espinhos, portas e o resto continuam livres.

## Como funciona

- **Fantasma:** o cliente monta o modelo com o `StructureModel.build`, o mesmo que o servidor usa. Todas as partes ficam translúcidas e sem colisão, consulta ou toque. Um `Highlight` pinta o modelo de verde ou vermelho, e a posição e o giro são exatamente os que o servidor vai usar. Sem template do Elizeu aparece o modelo provisório (o mesmo do servidor); o bloco de hoje só volta se o modelo falhar. O fantasma não leva luz, efeitos, som nem clique (revisão: a fogueira acendia luz).
- **Encaixe:** a peça com `snap = true` no `structure` do item (telhado e ponte agora) procura a peça vizinha mais perto da **mesma camada** que também tenha `snap`. Se a vizinha estiver ao alcance (centro a até `2 × raio + SNAP_RANGE` do ponto onde a peça sairia), a peça vai para a casa mais próxima da grade dessa vizinha, inclusive nos cantos (revisão: tirada a zona morta):
  - o lado da casa é o diâmetro da vizinha (`2 × radius`);
  - os eixos são os da vizinha, então a peça copia o giro dela;
  - se a casa mais próxima for a própria vizinha, a peça vai para a casa ao lado na direção em que o jogador olha.
  
  Sem vizinha perto, a colocação continua livre, como hoje.
- **Mesma regra nos dois lados:** a conta é uma função pura, `BuildRules.snapPlacement`. O servidor (`StructureService.place`) e o cliente (`BuildGhost`) chamam a mesma função com as peças próximas, então o fantasma mostra exatamente onde a peça sai. A checagem de lugar livre (`canPlace`) continua a mesma. Casas vizinhas só se encostam, e encostar já é aceito.

## Números (minhas escolhas)

- `SNAP_RANGE = 3` studs de folga além do diâmetro da vizinha.
- Busca de vizinhas: até `2 × radius + SNAP_RANGE` do ponto livre.

## Fora do escopo

Encaixe de paredes, rotação livre de peça encaixada, canteiros (só o flag fica pronto).

## Testes

`BuildRules.snapPlacement`:
- sem vizinha, a posição fica igual;
- com vizinha a 6 studs à frente, encaixa na casa ao lado;
- respeita o giro da vizinha (45°);
- a casa ocupada pela própria vizinha vai para a casa ao lado;
- vizinha longe demais não puxa;
- peça sem `snap` não encaixa.
