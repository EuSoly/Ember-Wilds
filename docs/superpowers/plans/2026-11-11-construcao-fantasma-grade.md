# Construção: fantasma e grade — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fantasma com o modelo do item e encaixe em grade das peças de chão/teto (snap), igual no servidor e no cliente.
**Spec:** `docs/superpowers/specs/2026-11-11-construcao-fantasma-grade-design.md`
**Global:** commits pt-BR com Co-Authored-By; `bash scripts/check.sh` verde antes de cada commit.

## Review Focus
- Vizinha girada 45° → a peça nova sai na mesma inclinação, sem fresta.
- Duas vizinhas perto → gruda na mais perto do ponto livre.
- Casa da grade ocupada por outra peça → `canPlace` recusa (vermelho), não empilha.
- Modelo sem template → fantasma volta ao bloco.

### Task 1: Regra do encaixe
**Files:** `src/shared/Defs/Types.luau` (`StructureDef.snap: boolean?`), `src/shared/Defs/Validate.luau` (snap boolean), `src/shared/Build/BuildRules.luau`, `src/shared/Defs/Items.luau` (`snap = true` em `roof` e `bridge`); Test `tests/build.spec.luau`
**Produces:** `export type SnapNeighbor = { x: number, z: number, yaw: number, radius: number }`; `BuildRules.SNAP_RANGE = 3`; `BuildRules.snapPlacement(x: number, z: number, yaw: number, dirX: number, dirZ: number, neighbors: { SnapNeighbor }): (number, number, number)`.
- [ ] Testes (os 5 do spec + "peça sem snap": quem chama não passa vizinhas) → FAIL → implementar → PASS → check → commit.

### Task 2: Servidor e fantasma
**Files:** `src/server/Services/StructureService.luau` (`place`: com `def.snap`, monta as vizinhas da mesma camada com `snap` em `StructureService.near(x, z, 2*radius + SNAP_RANGE)` e usa `snapPlacement` antes do `canPlace`), `src/client/World/BuildGhost.luau` (vizinhas pelas peças com a tag, mesma conta; modelo do `StructureModel.build` translúcido + `Highlight`; volta ao bloco se falhar).
- [ ] Check; Studio: telhado ao lado de telhado gruda; parede continua livre; commit.
- [ ] Docs: `docs/guia/construcao.md` (fantasma e encaixe); commit.
