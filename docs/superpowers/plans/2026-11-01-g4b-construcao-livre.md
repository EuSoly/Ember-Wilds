# G4b Construção livre — Plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Objetivo:** trocar a grade da G4 por construção livre do jeito do Starve: peça a distância fixa na direção da mira, virada para o jogador, R/botão gira 45°, peças como círculos que podem ficar coladas mas não sobrepostas — para todas as peças.

**Arquitetura:** `BuildRules` perde as funções de célula e ganha ponto/giro/círculos; o `StructureService` troca a grade por um `SpatialGrid` (já usado pelos recursos) e recebe o giro por um evento Blink; o cliente mostra o fantasma girado e manda o giro (R e botão no celular). O resto da G4 (vida, dano, dono, porta, espinho, fogo, baú) fica igual.

**Stack:** Luau `--!strict`, Rojo, Blink, Vide, Lune. Verificar: `bash scripts/check.sh` (Git Bash).

**Spec:** `docs/superpowers/specs/2026-11-01-g4-construcao-design.md` (seções "Colocar peças", "Rotação", "Posição livre", "Forma das peças", "Rotação na rede" — revisão de 01/11).

**Branch:** continuar em `g4-construcao` (ainda não mergeada).

**Modelo sugerido por tarefa:** marcado no título.

## Regras globais

- pt-BR em código, comentários, textos e commits; commit por tarefa; sem push; terminar commits com `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Conteúdo é dado; atributos e tags por `StatNames`; Server Authority (o cliente só pede).
- Atributos do personagem local previsto: ler por polling (AttributeChanged não dispara com Server Authority).
- `.gitignore` tem `build/`, que no Windows pega pastas `Build`: conferir `git status` em arquivo novo.
- Não mexer no que a G4 já validou além do necessário (vida, dano, dono, fogo, baú, painel).

## Foco de revisão

1. Giro forjado (fora de 0–7, fracionário, NaN) ou mandado com item que não é peça: ignorado; o giro do jogador volta a 0 ao trocar de item.
2. Construir colado em outra peça (tocando) é aceito; sobreposto, recusado — inclusive com peças giradas.
3. Fantasma e servidor usam o mesmo ponto, a mesma rotação e os mesmos raios (constantes compartilhadas em `BuildRules`).
4. Espinho, porta "com alguém dentro" e golpe passam a usar o círculo da peça; nada sobra da grade (nenhuma chave de célula, nenhum `cellOf`).
5. Peça removida (vida 0, fogo, dono, apagada por fora) sai do índice espacial.

---

### Tarefa 8 (Sonnet): Regras e dados sem grade

**Arquivos:** `src/shared/Build/BuildRules.luau`, `src/shared/Defs/Types.luau`, `src/shared/Defs/Items.luau`, `src/shared/Defs/Validate.luau`; testes `tests/build.spec.luau`, `tests/defs.spec.luau`.

**Produz:**
```lua
-- StructureDef: `size` sai; entra
radius: number?              -- raio do círculo da peça no chão (studs); padrão BuildRules.PIECE_RADIUS
BuildRules.PIECE_RADIUS = 2           -- meia largura do bloco provisório
BuildRules.PLAYER_RADIUS = 1.5        -- (já existe)
BuildRules.PLACE_DISTANCE = BuildRules.PIECE_RADIUS + BuildRules.PLAYER_RADIUS + BuildRules.PIECE_RADIUS  -- 5.5
BuildRules.ROTATE_STEP = 45           -- graus por aperto
BuildRules.ROTATE_STEPS = 8           -- giros válidos: 0..7
BuildRules.placePoint(x: number, z: number, dirX: number, dirZ: number): (number, number)   -- centro + dir * PLACE_DISTANCE
BuildRules.facingYaw(px: number, pz: number, fromX: number, fromZ: number, steps: number): number  -- graus: frente da peça virada para (fromX, fromZ) + steps*45
BuildRules.validSteps(steps: any): boolean   -- inteiro 0..7
BuildRules.radiusOf(def: StructureDef): number
BuildRules.circlesOverlap(ax, az, ar, bx, bz, br): boolean   -- dist < ar + br (encostar NÃO é sobrepor)
BuildRules.touchesCircle(px, pz, cx, cz, r, margin): boolean -- dist <= r + margin
```
Sai: `CELL`, `REACH`, `cellOf`, `cellCenter`, `targetCell`, `key`, `cellsOf`, `touches` (e seus testes). Fica: `HAND_DAMAGE`, `SPIKE_INTERVAL`, `MAX_PER_PLAYER`, `damageOf`, `areAllies`, `underLimit`.

- [ ] Testes que falham: `placePoint` nas 4 direções e numa diagonal (distância 5.5 do centro); `facingYaw` com 0 passos aponta para quem constrói e soma 45 por passo (comparar ângulos módulo 360); `validSteps` (0, 7 ok; 8, -1, 1.5, NaN, "2" não); `circlesOverlap` (encostando exatamente = false, 0.1 dentro = true); `touchesCircle` com margem; a peça em `placePoint` nunca encosta no corpo de quem constrói (`touchesCircle(x, z, px, pz, PIECE_RADIUS, PLAYER_RADIUS)` = false para 16 direções); Defs: `radius` > 0 se presente; `size` não existe mais.
- [ ] Implementar; check verde **(o servidor e o cliente ainda usam a grade: a Tarefa 9/10 trocam; se o check quebrar por isso, deixe as funções antigas até a Tarefa 9 e anote)**; commit `feat: regras da construção livre`.

### Tarefa 9 (Opus): Servidor da construção livre

**Arquivos:** `StructureService.luau`, `SpikeService.luau`, `GatherService.luau` (se usa algo da grade), `src/shared/Models/StructureModel.luau` (girar), `net/game.blink`, `StatNames.luau`.

**Produz:**
```
-- Blink
event SetBuildRotation { From: Client, Type: Reliable, Call: SingleAsync, Data: u8 }   -- 0..7
-- StructureService.Entry: sai cx/cz; ficam x, z, radius (de BuildRules.radiusOf) e ganha yaw
StructureService.near(x, z, radius): { Entry }   -- via SpatialGrid (src/shared/World/SpatialGrid.luau)
```
- Giro por jogador no servidor: `SetBuildRotation` só aceita `validSteps`; volta a 0 quando o `Equipped` do personagem muda; limpar no PlayerRemoving.
- Colocar (mesma descida de `Using` com peça na mão): ponto = `placePoint` da raiz + LookVector achatado; yaw = `facingYaw(ponto, raiz, giro)`; recusa calado se `circlesOverlap` com outra peça, recurso (raio de colisão do recurso) ou jogador (`PLAYER_RADIUS`), água no ponto, ou limite. Cria a peça girada (`StructureModel.build` + `PivotTo` com o yaw).
- Remoção tira do índice espacial em todos os caminhos.
- Porta "com alguém dentro" e espinho usam `touchesCircle` com o raio da peça (espinho: margem do corpo como hoje, `SPIKE_MARGIN`); o golpe já usa `x, z, radius`.
- [ ] Implementar; check verde; commit `feat: servidor da construção livre`.
- [ ] PARADA (Studio, controlador): construir em várias direções (peça girada de frente para o jogador), R gira 45°, colado aceita / sobreposto recusa, espinho e porta funcionando, morte apaga.

### Tarefa 10 (Sonnet): Cliente da construção livre

**Arquivos:** `src/client/World/BuildGhost.luau`; criar `src/client/BuildRotation.luau` (estado local do giro) e o botão de girar no celular (componente em `src/client/UI/`, montado no `App.luau`, visível só com peça na mão e em toque).

- `BuildRotation`: giro 0..7; tecla R (UserInputService, ignorar `gameProcessed`) e o botão somam 1 (módulo 8) e mandam `Net.SetBuildRotation`; volta a 0 quando o `Equipped` local muda (polling).
- `BuildGhost`: ponto = `placePoint`, yaw = `facingYaw` com o giro local; bloco translúcido do tamanho do bloco provisório, girado; vermelho/verde com `circlesOverlap` contra peças/recursos/jogadores perto (aproximação; o servidor decide). Fica no chão (Y fixo, como hoje).
- [ ] Implementar; check verde; commit `feat: fantasma girado e botão de girar`.

### Tarefa 11 (Sonnet): Documentação

- Atualizar `docs/guia/construcao.md` (sem grade, distância fixa, rotação R/botão, círculos colados/sobrepostos, constantes), `hud.md` (botão de girar), `arquitetura.md` se citar a grade.
- [ ] check verde; `& (Get-Content graphify-out\.graphify_python) -m graphify update .`; commit `docs: construção livre`.
