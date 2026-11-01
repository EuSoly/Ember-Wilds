# G4 Construção — Plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Objetivo:** colocar no chão as peças craftadas na G3 (paredes, portas, espinhos, bancada, fogueiras, baú), com vida, dono, porta, espinho, fogo que some e baú do jeito do Starve.io.

**Arquitetura:** os dados ganham o bloco `structure` nos itens `placeable`; as regras puras (grade, alvo, dano, baú) ficam em `src/shared/Build/` e são testadas no Lune; o `StructureService` é dono da grade e das peças no servidor, o golpe da coleta passa a acertar peças também, e o `ChestService` guarda o conteúdo dos baús; o cliente mostra o fantasma, a barrinha de vida e o painel do baú.

**Stack:** Luau `--!strict`, Rojo, Blink, Vide, Lune. Verificar: `bash scripts/check.sh` (Git Bash).

**Spec:** `docs/superpowers/specs/2026-11-01-g4-construcao-design.md` (fonte dos números).

**Branch:** criar `g4-construcao` a partir da atual antes da Tarefa 1.

**Modelo sugerido por tarefa:** marcado no título (Sonnet = mecânica com testes já ditados; Opus = segurança/concorrência no servidor).

## Regras globais

- pt-BR em código, comentários, textos e commits; commit por tarefa; sem push; terminar commits com `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Conteúdo é dado: nenhum sistema testa id de item (`if id == "wood_wall"`); tudo vem de `Defs`. Atributos e tags por `StatNames`.
- Server Authority: o cliente só pede; o servidor revalida tudo. Rede por Blink (`net/game.blink`; o check gera `src/*/Net.luau`).
- Depois de criar arquivos novos, conferir duplicatas no Studio (o Rojo já aplicou arquivos novos 2×).
- O craft é segredo do dono (G3): não expor estado de craft em atributos.

## Foco de revisão

1. Dois jogadores mexendo no mesmo baú no mesmo instante, ou pedido forjado (baú longe, slot vazio, item de outro tipo, quantidade 0/negativa/fracionária): nada duplica nem some.
2. Construir longe, em célula ocupada, em cima de jogador/recurso/água, com a peça fora da mão ou o inventário mudando no meio: nada é gasto e nada aparece.
3. Dono morre ou sai com porta aberta, baú cheio, fogueira acesa: todas as peças dele somem e a grade libera as células.
4. Porta: o dono fecha com alguém dentro → não fecha; quem não é dono bate → só tira vida, nunca abre.
5. Espinho: o dono e seus aliados não tomam dano; vítima entre três espinhos toma dos três, cada um no máximo 1×/s.

---

### Tarefa 1 (Sonnet): Dados das peças

**Arquivos:** `src/shared/Defs/Types.luau`, `src/shared/Defs/Items.luau`, `src/shared/Defs/Validate.luau`, `src/shared/Strings/ptBR.luau`; teste `tests/defs.spec.luau`.

**Interfaces — Produz:**
```lua
export type StructureKind = "wall" | "door" | "spike" | "station" | "chest" | "fire"
export type StructureDef = {
	kind: StructureKind,
	health: number,            -- vida máxima (> 0)
	size: number?,             -- células por lado; padrão 1 (só 1 nesta fase)
	spikeDamage: number?,      -- só kind "spike" (obrigatório nele)
	lifetime: number?,         -- segundos até sumir; só kind "fire" (obrigatório nele)
	heatRadius: number?,       -- studs; só kind "fire" (obrigatório nele)
	station: CraftStation?,    -- estação oferecida: "workbench" (kind station) ou "fire" (kind fire)
}
-- ItemDef ganha:
structure: StructureDef?       -- só (e obrigatório) para category "placeable"
structureDamage: number?       -- dano do golpe em peça; > 0; ausente = mão
```
Valores (spec): paredes e portas 1000/1500/2000; espinhos 150/300/600 com `spikeDamage` 10/20/30; `workbench` station 300 (`station = "workbench"`); `chest` 500; `campfire` fire 150, `lifetime` 120, `heatRadius` = `SurvivalConfig.CAMPFIRE_RADIUS` (12), `station = "fire"`; `big_campfire` fire 300, `lifetime` 360, `heatRadius` 18, `station = "fire"`. `structureDamage`: ferramentas `wood..reidite` 10/15/20/25/30/35; espadas e lanças metade do tier (madeira 5, pedra 7.5, ouro 10). Texto novo `death.cause.spike` = "Espinho".

- [ ] Testes que falham: `["structures match the design"]` (parede de pedra 1500, espinho de ouro 600/30, fogueira 120 s e raio 12, fogueira grande 360 s, bancada station workbench, baú 500); `["every placeable has a structure"]` nas Defs reais; `["structure only on placeable"]`; `["structure with bad numbers is an error"]` (health 0, spike sem spikeDamage, fire sem lifetime, size 0, station "forge", kind "tower"); `["structure damage must be positive"]`.
- [ ] Implementar no estilo do `validateRecipes`; check verde; commit `feat: dados das construções`.

### Tarefa 2 (Sonnet): Regras puras da construção e do baú

**Arquivos:** criar `src/shared/Build/BuildRules.luau`, `src/shared/Build/ChestRules.luau`; testes `tests/build.spec.luau`, `tests/chest.spec.luau`.

**Interfaces — Produz:**
```lua
BuildRules.CELL = 4                      -- studs
BuildRules.HAND_DAMAGE = 5
BuildRules.SPIKE_INTERVAL = 1            -- s por par espinho/vítima
BuildRules.MAX_PER_PLAYER = nil :: number?   -- nil = sem limite
BuildRules.cellOf(x: number, z: number): (number, number)          -- célula inteira que contém o ponto
BuildRules.cellCenter(cx: number, cz: number): (number, number)
BuildRules.targetCell(x: number, z: number, dirX: number, dirZ: number): (number, number)  -- 1 célula à frente (ponto x+dir*CELL)
BuildRules.key(cx: number, cz: number): string                     -- "cx,cz"
BuildRules.cellsOf(cx: number, cz: number, size: number): { string }   -- chaves ocupadas (size×size, canto em cx,cz)
BuildRules.damageOf(item: ItemDef?): number                        -- structureDamage ou HAND_DAMAGE
BuildRules.areAllies(a: Player | number, b: Player | number): boolean  -- hoje: mesmo jogador/UserId. Gancho dos times
BuildRules.underLimit(count: number): boolean                      -- respeita MAX_PER_PLAYER (nil = sempre true)
BuildRules.touches(px: number, pz: number, cx: number, cz: number, size: number, margin: number): boolean  -- ponto encosta na área da peça + margem

ChestRules.MAX = 9999
ChestRules.RANGE = 8   -- studs do centro do baú (XZ): meia célula + 1 célula + folga do corpo; servidor e cliente usam o mesmo
export type Contents = { id: string?, count: number }
ChestRules.canPut(c: Contents, id: string, count: number): number  -- quanto cabe (0 se outro tipo ou cheio)
ChestRules.put(c: Contents, id: string, count: number): number     -- põe e devolve o quanto entrou
ChestRules.take(c: Contents, count: number): (string?, number)     -- tira até count; esvaziou → id nil
```
- [ ] Testes que falham: célula de pontos negativos e na borda (`cellOf(-0.1, 0)` = `(-1, 0)`, `cellOf(4, 4)` = `(1, 1)`); `targetCell` para as 4 direções; `cellsOf(0,0,1)` = `{"0,0"}` e size 2 = 4 chaves; `damageOf(nil)` = 5, item com 20 = 20; `areAllies` mesmo/diferente; `underLimit` com nil; `touches` dentro/fora com margem; baú: vazio aceita qualquer, outro tipo = 0, teto 9999 corta, `take` parcial e total (id volta a nil), contagens 0/negativas/fracionárias = 0.
- [ ] Implementar; check verde; commit `feat: regras puras da construção e do baú`.

### Tarefa 3 (Opus): Servidor das peças (colocar, vida, dono, porta, espinho, fogo)

**Arquivos:** criar `src/server/Services/StructureService.luau`, `src/shared/Models/StructureModel.luau`; modificar `GatherService.luau`, `DeathService.luau`, `StatNames.luau`, `WaterSim.luau` (exportar `isWet(x, z)`), `DevDataService.luau` (tirar `DevWorkbench`/`DevCampfire`), apagar `src/shared/Models/WorkbenchModel.luau` se nada mais usar.

**Interfaces — Consome:** Tarefas 1–2; `InventoryService.take/selectedSlot/get`, `ResourceService.near`, `GatherRules.pickTarget`, `CharacterService.hurt(character, amount, causeKey, "combat")`, `CampfireModel.build()`.
**Produz:**
```lua
-- StatNames
StructureTag = "Structure", Owner = "Owner" (UserId), StructureHealth = "StructureHealth",
StructureHealthMax = "StructureHealthMax", DoorOpen = "DoorOpen"   -- atributos no modelo da peça
-- StructureService
export type Entry = { model: Model, itemId: string, def: StructureDef, owner: Player, cx: number, cz: number,
                      x: number, z: number, radius: number, health: number }
StructureService.near(x: number, z: number, radius: number): { Entry }
StructureService.hit(entry: Entry, attacker: Player, item: ItemDef?)    -- porta do aliado alterna; senão tira vida
StructureService.removeOwned(player: Player)                           -- some com tudo do dono (morte/saída; revive = não chamar)
StructureService.onRemoved(listener: (Entry) -> ())                     -- o ChestService limpa o conteúdo
```
- Colocar: na **descida** de `Using` (true → false) com item `placeable` na mão (`Equipped`) e vivo: célula = `targetCell` da raiz + `LookVector`; recusa calado se célula ocupada, `underLimit` falso, `WaterSim.isWet` no centro, recurso (`ResourceService.near`) ou jogador a encostar (`touches` com margem 1.5). Só então `InventoryService.take(id, 1)` (falhou = recusa) e cria a peça. Assim PC (soltar o clique) e celular (soltar o joystick) usam a mesma regra.
- Peça: `StructureModel.build(itemId, def): Model` (blocos genéricos 4×4 na cor do tier, altura por kind; fogo = `CampfireModel`); ancorada, `CanTouch = false`; atributos `Owner`, vida e vida máxima; tag `StructureTag`; estações e fogos com `CraftStation` + `Station`; fogos com `HeatSource` + `HeatRadius`/`BurnRadius`; some ao fim de `lifetime`.
- Golpe: `GatherService` pula o golpe com `placeable` na mão; no golpe, junta candidatos de `ResourceService.near` e `StructureService.near` e escolhe com `pickTarget`; peça → `StructureService.hit`. Vida ≤ 0 → remove (grade libera).
- Porta: aliado bate → alterna `DoorOpen` (aberta = `CanCollide` false nas peças); não fecha com jogador encostando na célula.
- Espinho: varredura a 5 Hz; jogador que `touches` (margem 1) um espinho de não-aliado toma `spikeDamage` via `hurt(..., "death.cause.spike", "combat")`, no máximo 1×/`SPIKE_INTERVAL` por par.
- Dono: `DeathService.kill` chama `StructureService.removeOwned(player)` junto do `InventoryService.reset`; `PlayerRemoving` também. (O spec fala em "id da vida"; aqui o gancho é essa chamada única: o revive futuro simplesmente não a faz, e as peças ficam.)
- [ ] Implementar; check verde; commit `feat: servidor das construções`.
- [ ] PARADA (Studio, eu via MCP): colocar parede/porta/espinho/bancada/fogueira; célula ocupada e água recusam sem gastar; bater tira vida e derruba; porta abre/fecha só pelo dono; espinho fere outro e não o dono; fogueira some em 2 min; morrer apaga tudo.

### Tarefa 4 (Opus): Servidor do baú

**Arquivos:** criar `src/server/Services/ChestService.luau`; modificar `net/game.blink`, `StatNames.luau`.

**Interfaces — Consome:** `ChestRules`, `StructureService.onRemoved`, `InventoryService.get/take/give`.
**Produz:**
```
-- Blink
event ChestPut { From: Client, Type: Reliable, Call: SingleAsync, Data: struct { Chest: Instance, Slot: u8, Count: u8 } }
event ChestTake { From: Client, Type: Reliable, Call: SingleAsync, Data: Instance }
-- StatNames: ChestItem = "ChestItem", ChestCount = "ChestCount" (atributos no modelo do baú; todos veem)
```
- Pôr: baú existe (tag + kind chest), jogador vivo a até `ChestRules.RANGE` (XZ), slot do inventário com item, `Count` ∈ {1, 10}; quantidade = `min(Count, slot.count, ChestRules.canPut)`; tira do slot e põe no baú **sem `yield` entre conferir e mudar**; atualiza os atributos.
- Tirar: mesma conferência; tira `min(conteúdo, o que cabe no inventário)`; dá ao jogador.
- Limite de taxa por jogador (ex. 10 pedidos/s, o resto ignora).
- Baú removido (vida 0 ou dono morto/saiu): conteúdo some (`onRemoved`).
- [ ] Teste puro extra em `tests/chest.spec.luau`: `["two puts never exceed max"]` (dois `put` seguidos perto do teto).
- [ ] Implementar; check verde; commit `feat: servidor do baú`.

### Tarefa 5 (Sonnet): Cliente da construção

**Arquivos:** criar `src/client/World/BuildGhost.luau`, `src/client/World/StructureHealth.luau`; modificar `WorldFxController.luau`.

- `BuildGhost`: com item `placeable` na mão (atributo `Equipped`, por polling), mostra um bloco translúcido do tamanho da célula em `BuildRules.targetCell` da raiz + direção para onde o boneco olha; verde se a célula parece livre (sem `StructureTag` na célula, sem recurso/jogador encostando), vermelho se não (o servidor decide de verdade).
- `StructureHealth`: barrinha acima da peça por 3 s quando a vida muda (lê os atributos da peça por polling; a peça entra pelo streaming).
- [ ] Implementar; check verde; commit `feat: fantasma da construção e vida das peças`.

### Tarefa 6 (Sonnet): Painel do baú

**Arquivos:** criar `src/client/UI/ChestPanel.luau`, `src/client/ChestState.luau`; modificar `UI/App.luau` e o componente de slot usado por `Hotbar`/`InventoryGrid` (botão "+").

- `ChestState`: baú com tag e kind chest mais perto a até `ChestRules.RANGE`, checado a cada 0,25 s; `put(slot, count)` e `take()` mandam a rede.
- `ChestPanel`: acima da hotbar, ícone do item guardado (`ItemIcon`) com a quantidade; clique/toque tira. Só aparece perto de um baú.
- "+": em cada slot com item, enquanto há baú perto; clique = 1, Shift+clique = 10; no celular, segurar 0,5 s = 10.
- [ ] Implementar; check verde; commit `feat: painel do baú`.
- [ ] PARADA (Studio, eu via MCP): pôr 1/10, tirar com inventário quase cheio, baú de outro tipo recusa, painel some ao se afastar, baú destruído leva o conteúdo.

### Tarefa 7 (Sonnet): Documentação

- Criar `docs/guia/construcao.md` (como colocar, vida e dano, porta, espinho, fogo, baú, dono e revive, limite, peça nova = dado). Atualizar `crafting.md` (estações agora colocadas; sem `DevWorkbench`/`DevCampfire`), `arquitetura.md` (StructureService/ChestService), `adicionar-item.md` (bloco `structure`, `structureDamage`).
- [ ] check verde; `& (Get-Content graphify-out\.graphify_python) -m graphify update .`; commit `docs: guia da construção`.
