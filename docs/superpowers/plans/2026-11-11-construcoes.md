# Construções Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Construções com números do Starve, peças de diamante/ametista, extratores do Starve, máquina de esmeralda, pedra da ressurreição com fantasma e totem com times.
**Spec:** `docs/superpowers/specs/2026-11-11-construcoes-design.md` (números brutos na tabela da Parte A).
**Global:** commits pt-BR com Co-Authored-By; `bash scripts/check.sh` verde antes de cada commit; o que depende de material ausente é `testOnly`.

## Review Focus
- Espinho de aliado/dono não machuca quem bate nele (hit) nem quem encosta.
- Máquina de esmeralda removida porque o dono morreu/saiu não mata ninguém de novo.
- Fantasma: não leva dano, não ganha nem perde barras, não coleta/constrói/come/veste; tempo acaba → morte normal com caixa.
- Ressuscitar longe da pedra ou depois do tempo → recusado.
- Time: entrar cheio/trancado → recusado; espera de 20 s; líder sai → time desfeito; aliados por time em porta, baú, espinho, extrator.

### Task 1: Dados das construções (Parte A + B)
**Files:** `Types.luau` (`StructureKind` + "totem" | "resurrection" | "emerald_machine"; `StructureDef.spikeHitDamage: number?`), `Validate.luau` (kinds novos; `spikeHitDamage` > 0 só em spike/spike_door), `StructureModel.luau` (kinds novos usam o construtor de estação), `Items.luau`, `Recipes.luau`, `ptBR.luau`; Test `tests/structureitems.spec.luau`.
- [ ] Testes: vidas e danos da tabela do spec (espinho e porta com espinho de madeira a ametista; extratores 2000 e números `2/10/1/255/255`); peças novas existem (`diamond_wall`, `diamond_door`, `diamond_spike`, `diamond_spike_door`, `diamond_extractor` e os de ametista; `totem`, `resurrection_stone`, `emerald_machine`; materiais `emerald`, `sandworm_juice`); liberadas exatamente: portas com espinho madeira/pedra/ouro, extratores pedra/ouro, fornalha, ponte, telhado, placa, cama, totem (+ as que já eram); receitas da config (pedra extrator 50 madeira 100 pedra; totem 50 madeira; ressurreição 40 diamante 45 pedra; máquina com `alsoNear` fogo e água).
- [ ] FAIL → dados → PASS → check → commit.

### Task 2: Bater no espinho
**Files:** `StructureService.hit` (peça com `spikeHitDamage`, quem bate não é aliado → `CharacterService.hurt(attackerCharacter, spikeHitDamage, SPIKE_CAUSE, "player")`), regra pura `BuildRules.spikeHitDamage(def, allied): number`; Test `tests/build.spec.luau`.
- [ ] Teste da regra (aliado 0; sem campo 0; com campo = valor) → FAIL → implementar → PASS → check → commit.

### Task 3: Máquina de esmeralda (Parte C)
**Files:** Create `src/shared/Build/EmeraldRules.luau` (`POINTS_PER_MINUTE = 750`, `pointsFor(dt): number`, `canPlace(ownedCount): boolean`), `StructureService` (recusa a 2ª por dono; `onRemoved` com motivo: destruída → mata o dono com causa `death.cause.emerald`), Create `src/server/Services/EmeraldService.luau` (a cada 1 s soma pontos ao dono vivo via `ScoreService.add`); Test `tests/emerald.spec.luau`.
- [ ] Testes puros → FAIL → implementar → PASS → check → commit.

### Task 4: Ressurreição e fantasma (Parte D)
**Files:** Create `src/shared/Survival/GhostRules.luau` (`GHOST_SECONDS = 60`, `MEMORY = 30`, `crownSeconds(strongestTier): number`, `lostItems(source: "heart" | "crown", itemDefs): {id}`, `revivedScore(score): number` = floor(score/3), `ghostKillBonus(score)` = floor(score × 0,10), `canRevive(distance, now, ghostUntil): boolean`, `REVIVE_RADIUS = 6`); Create `src/server/Services/GhostService.luau` (estado por jogador; `DeathService.kill` pergunta antes `GhostService.tryGhost(player, killer)`; atributos `GhostUntil` no Player; fantasma: `CharacterService.hurt` ignora, `SurvivalService` pula, Gather/Structure/Food/Wear/Craft recusam; colisão: grupo `Ghost` sem colisão com peças e recursos; memória do item mais forte segurado); evento Blink `Resurrect`; cliente: `GhostState` + botão Ressuscitar e contador no HUD perto da pedra; `BonecoRenderer` translúcido azulado com `GhostUntil`. Test `tests/ghost.spec.luau`.
- [ ] Testes puros → FAIL → implementar → PASS → check → Studio → commit.

### Task 5: Totem e times (Parte E)
**Files:** Create `src/shared/Build/TeamRules.luau` (`MAX = 8`, `REJOIN_WAIT = 20`, `TOTEM_RADIUS = 10`, `TEAM_DAMAGE = 0.3`, `canJoin(team, now, waitUntil)`, funções puras sobre `{ leader, members, locked }`); Create `src/server/Services/TeamService.luau` (time por totem; join/leave/kick/lock via Blink; desfaz com líder fora/morto/totem destruído; atributo `Team` no Player com o UserId do líder); `BuildRules.areAllies` com resolvedor de time (`BuildRules.setTeamOf(fn)`), dano 30% entre colegas em `CharacterService.hurt` (golpe de jogador); cliente: painel do time e ícone no nick. Test `tests/team.spec.luau`.
- [ ] Testes puros → FAIL → implementar → PASS → check → Studio → commit.

### Task 6: Docs
`docs/guia/construcao.md` (números, máquina, ressurreição, times), `docs/guia/times.md`, `docs/guia/ressurreicao.md`, pendências; graphify update; commit.
