# Ferramentas e armas Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Os 33 modelos de `Assets.Tools` viram itens com números e receitas do Starve; escudo, martelo, chave inglesa e bônus de conjunto funcionam; o resto é `testOnly`; tabela de balanço armas × defesas.

**Architecture:** Dados novos nos itens (`shield`, `hammer`, `gearBonus`, `repair` e campos só-dado), regras puras em `ArmorRules` (escudo), `MobRules` (bônus) e `BuildRules` (martelo, conserto); o servidor só passa o que está na mão e na cabeça.

**Tech Stack:** Luau `--!strict`, Lune (`lune run tests/run`), `bash scripts/check.sh` com `export PATH="$HOME/.rokit/bin:$PATH"`.

**Spec:** `docs/superpowers/specs/2026-11-11-ferramentas-design.md`

## Global Constraints

- Commits em pt-BR com `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; sem push.
- Liberados (sem `testOnly`): `stone_hammer`, `gold_hammer`, `wood_shield`, `stone_shield`, `gold_shield`, `wrench`. Todo o resto novo é `testOnly`.
- `bash scripts/check.sh` verde antes de cada commit.

## Review Focus

- Escudo na mão de quem leva golpe de sobrevivência (fome etc.) → não reduz nada.
- Bônus de conjunto com peça sem `gearSet` ou arma sem bônus → dano normal.
- Martelo contra construção sem tier (fogueira, baú?) → dano cheio.
- Chave inglesa em construção cheia → não muda nada (nem dano).
- Chave inglesa numa porta aliada → conserta, não abre.

---

### Task 1: Regras de escudo, bônus, martelo e conserto

**Files:** `src/shared/Defs/Types.luau`, `src/shared/Defs/Validate.luau`, `src/shared/Survival/ArmorRules.luau`, `src/shared/Mobs/MobRules.luau`, `src/shared/Build/BuildRules.luau`; Test: `tests/toolrules.spec.luau` (novo)

**Interfaces (Produces):**
- `Types.ItemDef` ganha: `shield: { defense: number, mobDefense: number, arrowDefense: number? }?`, `hammer: { minDamage: number }?`, `gearBonus: { set: string, damage: number }?`, `repair: number?`, só-dado `dig: number?`, `harvest: number?`, `waters: boolean?`, `butcher: number?`, `crabCalm: boolean?`.
- `ArmorRules.reduce(amount, mods, source, held: ItemDef?)`: subtrai também `held.shield.defense`/`mobDefense` conforme `source`.
- `MobRules.damageOf(item: ItemDef?, armor: ItemDef?): number`: soma `item.gearBonus.damage` quando `armor.armor.gearSet == item.gearBonus.set`.
- `BuildRules.damageOf(item: ItemDef?, structureTierOrder: number?, itemTierOrder: number?): number`: martelo com `structureTierOrder > itemTierOrder` → `hammer.minDamage`.
- `BuildRules.repairAmount(item: ItemDef?, health: number, maxHealth: number): number` (0 sem `repair` ou cheia; nunca passa do máximo).

- [ ] Testes em `toolrules.spec`: escudo soma (capacete 4/13 + escudo 3/8: golpe 22 jogador → 15, mordida 24 → 3); escudo não vale sem `source` de combate (só testar que `reduce` sem `held` é igual ao antigo); bônus (+3 com set igual, 0 com set diferente/sem armadura); martelo (pedra 20 contra ouro → 5, contra pedra → 20, construção sem tier → 20); conserto (70 de 1000 com 900 → 70, com 980 → 20, cheia → 0, sem repair → 0).
- [ ] Rodar → FAIL; implementar; Validate dos campos novos (números ≥ 0, `set` texto); rodar → PASS; check; commit `feat(ferramentas): regras de escudo, bônus de conjunto, martelo e conserto`.

### Task 2: Itens, materiais, textos e receitas

**Files:** `src/shared/Defs/Items.luau`, `Recipes.luau`, `src/shared/Strings/ptBR.luau`; Test: `tests/toolitems.spec.luau` (novo)

- [ ] Testes: os 33 ids existem (lista no teste) com `category` `weapon`/`tool`; liberados exatamente os 6; spot-check (lava_sword 33 + gearBonus lava 3; reidite_hammer 70/70; gold_shield 3/8; wrench repair 70; super_hammer receita com water_bucket); receitas da config para os craftáveis (pirate_sword e materiais de quest sem receita).
- [ ] Rodar → FAIL; escrever dados (tabela do spec); nomes pt-BR; receitas (config; picaretas altas trocadas); check; commit `feat(ferramentas): 33 ferramentas e armas do Starve`.

### Task 3: Servidor

**Files:** `src/server/Services/CharacterService.luau` (escudo: item na mão do atingido), `GatherService.luau` (bônus contra jogador), `MobService.luau` (bônus contra mob em `hit`), `StructureService.luau` (martelo por tier; conserto aliado antes do toggle da porta)

- [ ] Implementar com as funções da Task 1; check; verificar no Studio (DevGive escudo de ouro + capacete de ouro e mordida; martelo de pedra numa parede de ouro; chave numa parede própria danificada); commit `feat(ferramentas): escudo, martelo, chave inglesa e bônus de conjunto no jogo`.

### Task 4: Dicas, balanço e documentação

**Files:** `src/shared/UIFlow/ItemInfo.luau`, `ptBR.luau`, `BookImages.luau`; Create: `docs/game-design/balanco-armas-defesa.md`, `docs/guia/ferramentas.md`; Modify: `docs/pendencias.md`; Test: `tests/iteminfo.spec.luau`

- [ ] Testes: gold_shield mostra as duas defesas; wrench `info.repair`; dragon_sword `info.gearBonus`. Rodar → FAIL; implementar; PASS.
- [ ] Tabela de balanço gerada dos dados; guia; pendências (escala de dano em construção das armas; dano mínimo em aberto). Check; graphify update; commit `docs(ferramentas): guia, balanço armas × defesas e pendências`.
