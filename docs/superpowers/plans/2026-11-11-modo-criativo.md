# Modo criativo Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Marca `Creative` no perfil libera todos os itens no livro com botão Pegar, e quem está no criativo não soma pontos, ranking nem estatísticas.

**Architecture:** `CreativeService` (servidor) copia a marca do perfil para o atributo `Creative` do Player, atende o `CreativeGive` e cria o `DevCreative`. Regras puras em `src/shared/Creative/CreativeRules.luau` e `ItemAccess.allowsTest`. Os serviços de pontos perguntam `CreativeService.isOn(player)`.

**Tech Stack:** Luau, Blink (`net/game.blink`), Vide (livro), Lune.

**Spec:** `docs/superpowers/specs/2026-11-11-modo-criativo-design.md`

## Global Constraints
- Commits em pt-BR com `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; `bash scripts/check.sh` verde antes de cada commit.
- Só o servidor escreve o atributo `Creative`; a entrega confere a marca **no perfil**.

## Review Focus
- Perfil ainda não carregado → não é criativo (nada entregue, pontos normais).
- Pedido de item sem personagem vivo → recusa.
- Jogador normal mata jogador criativo → sem ranking/estatística de abate.
- Desligar o criativo no meio da vida → volta a somar dali em diante.

---

### Task 1: Regras e acesso
**Files:** Create `src/shared/Creative/CreativeRules.luau`; Modify `src/shared/ItemAccess.luau`; Test `tests/creative.spec.luau`
**Produces:** `ItemAccess.allowsTest(inStudio: boolean, creative: boolean): boolean`; `CreativeRules.giveCount(def: ItemDef): number` (= `math.min(def.maxStack, 100)`); `CreativeRules.GIVE_EVERY = 0.2`; `CreativeRules.canGive(last: number?, now: number): boolean`.
- [ ] Testes (allowsTest 4 combinações; giveCount ferramenta 1, madeira 100, item com maxStack 10 → 10; canGive nil/antes/depois) → FAIL → implementar → PASS → commit.

### Task 2: Perfil, atributo, DevCreative e entrega
**Files:** `src/shared/Data/ProfileTemplate.luau` (`Creative = false`), `src/shared/StatNames.luau` (`Creative`), `net/game.blink` (`event CreativeGive { From: Client, Type: Reliable, Call: SingleAsync, Data: struct { Id: string(1..48) } }`), Create `src/server/Services/CreativeService.luau` (`isOn(player): boolean` lê o perfil; `set(player, on)`; atributo no `DataService.onLoaded`; `Net.CreativeGive.On`; `DevCreative` no Studio), `InventoryService`/`CraftService`/`StructureService` (`ItemAccess.isAvailable(id, ItemAccess.allowsTest(RunService:IsStudio(), CreativeService.isOn(player)))`).
- [ ] Check verde; commit.

### Task 3: Sem pontos, ranking nem estatísticas
**Files:** `ScoreService.add`, `RankService.addLife`/`addKill`, `StatsService.add`/`record` (retornam cedo no criativo); `DeathService` (vítima no criativo: sem ranking/estatística para quem matou).
- [ ] Check verde; commit.

### Task 4: Livro com Pegar
**Files:** `src/client/CraftState.luau`, `src/client/Screens/RecipeBookScreen.luau`, `src/client/UI/BookSheet.luau` (`allowsTest` com o atributo do LocalPlayer; botão Pegar na ficha quando criativo; título "Modo criativo"), `src/shared/Strings/ptBR.luau` (`book.creative.give` = "Pegar", `book.creative.title` = "Modo criativo", `creative.full` = "Inventário cheio").
- [ ] Check verde; Studio: `DevCreative`, abrir livro, Pegar espada de lava; commit.
- [ ] Docs: `docs/guia/modo-criativo.md`; `docs/guia/dados.md` (campo Creative); graphify update; commit.
