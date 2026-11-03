# G8 Estruturas e modelos novos da floresta — Plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Objetivo:** colocar no jogo os modelos do Elizeu (world-pack) para o que existe na floresta: trocar o visual das construções, estruturas e rochas atuais; criar portas com espinhos, extratores de pedra e ouro, fornalha, ponte, telhado, placa, poço com balde e cama, funcionando como no Starve mas só no Studio ("só para teste"); ícones 3D de madeira/pedra/ouro; e um plano escrito para o resto.

**Arquitetura:** templates no place (`ReplicatedStorage.Assets.Structures`, `.Icons`; `ServerStorage.Assets.Resources`), preparados por um script do Studio a partir de `Workspace["mundo-completo"]`; o `StructureModel` monta a peça com o colisor de hoje invisível + o visual do template; as estruturas interativas novas usam um painel único de "chegar perto e agir" (um evento Blink) com regras puras testadas no Lune; a marca `testOnly` nos itens é lida num módulo puro só.

**Stack:** Luau `--!strict`, Rojo, Blink (`net/game.blink`), Vide, Lune. Verificar: `bash scripts/check.sh` (Git Bash).

**Spec:** `docs/superpowers/specs/2026-11-03-g8-estruturas-floresta-design.md`.

**Branch:** `g8-estruturas`.

## Regras globais

- pt-BR em código, comentários, textos (`Strings`) e commits; commit por tarefa; sem push; terminar commits com `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Nunca commitar `assets/` (arquivos do Elizeu).
- Server Authority: o servidor decide; atributo de **personagem** se lê por polling (AttributeChanged não dispara no personagem previsto); strings replicadas ≤ 50 caracteres.
- Conteúdo = dados em `Defs` (nada de código que conhece item pelo nome, salvo onde a tarefa disser). Texto novo = chave em `src/shared/Strings/ptBR.luau`.
- **Só para teste**: item com `testOnly = true` não existe para o jogador fora do Studio (`RunService:IsStudio()` falso). Números sem fonte na wiki ficam com comentário `-- provisório`.
- Colisão = círculo da peça (regras da G4); o modelo do Elizeu é só visual (`CanCollide/CanQuery/CanTouch = false`).
- Antes de ler código: `& (Get-Content graphify-out\.graphify_python) -m graphify query "<pergunta>"` (PowerShell) e ler só o que ele apontar.
- Studio (MCP) é com o controlador: as tarefas escrevem scripts e código; rodar no Studio é nas PARADAS.

## Foco de revisão

1. Um item `testOnly` chegando ao jogador fora do Studio por qualquer caminho (craft, kit, caixa/loot, baú, `InventoryService.give`).
2. Porta (e porta com espinhos) fechando em cima de um jogador; porta com espinhos ferindo o dono.
3. Estrutura destruída/removida com alguém usando o painel (extrator, fornalha, poço, cama): nada fica preso, estado some com a peça, fornalha sem madeira não esquenta.
4. Ponte: jogador em cima quando a ponte some (volta a estar na água); colocar outra peça "na água" continua proibido; jogador nadando não "pisa" em ponte que não existe.
5. Fogueiras e fornalha com o modelo novo: calor, estação de craft e tempo de vida iguais aos de hoje.

---

### Tarefa 1 (Sonnet): Marca "só para teste"

**Arquivos:** `src/shared/Defs/Types.luau` (`ItemDef.testOnly: boolean?`); criar `src/shared/ItemAccess.luau`; `src/shared/Defs/Validate.luau`; `src/server/Services/InventoryService.luau` (give), `CraftService.luau` (start), `StructureService.luau` (place); cliente: listas de receitas (`src/client/CraftState.luau`, `src/client/Screens/RecipeBookScreen.luau`); teste `tests/itemaccess.spec.luau` e casos em `tests/defs.spec.luau`.

**Produz:** `ItemAccess.isAvailable(itemId: string, inStudio: boolean): boolean` (false se o item não existe ou é `testOnly` fora do Studio); `ItemAccess.recipeAvailable(recipe: Types.RecipeDef, inStudio: boolean): boolean` (o resultado e cada ingrediente disponíveis).
- [ ] Testes que falham: item normal disponível nos dois; item `testOnly` só com `inStudio = true`; id inexistente indisponível; receita cujo resultado é `testOnly` indisponível fora do Studio; Validate: kit (`Defs.Kits`) ou loot de mob (`Defs.Mobs[*].loot`) com item `testOnly` é erro.
- [ ] Implementar e ligar: `InventoryService.give` recusa item indisponível (devolve tudo como sobra); `CraftService.start` recusa receita indisponível; `StructureService.place` recusa; listas do cliente escondem receitas indisponíveis.
- [ ] Check verde; commit `feat: marca de item só para teste`.

### Tarefa 2 (Sonnet): Script de templates do world-pack e rochas novas

**Arquivos:** criar `scripts/studio/import-world.luau`; `src/shared/Defs/Resources.luau` (rock: `variants = 1`); `docs/guia/mapa.md` (nota).

**Produz (no place, quando o controlador rodar em Edit):** para cada `Model` `<id>_root` em `Workspace["mundo-completo"]`, um template com o pivô no **centro da base** (centro X/Z da caixa, Y mínimo), peças `Anchored`, `CanCollide/CanQuery/CanTouch = false`, nome sem `_root`, em:
- `ReplicatedStorage.Assets.Structures/<itemId>`: construções, estruturas (renomear `big_fire` → `big_campfire`, o id do jogo);
- `ServerStorage.Assets.Resources`: `stone_deposit_icon` → `rock_1`, `gold_deposit_icon` → `gold_vein_1` (os antigos de mesmo nome e `rock_2`/`rock_3` vão para `ServerStorage.ResourcesAntigos`); os de diamante/ametista/reidite/esmeralda ficam com o nome original (para o futuro);
- `ReplicatedStorage.Assets.Icons/<itemId>`: `wood_viewport` → `wood`, `stone_viewport` → `stone`, `gold_viewport` → `gold`, os outros com o id do minério (`diamond`, `amethyst`, `reidite`, `emerald`).
- Idempotente (rodar de novo substitui); imprime a lista do que fez. Não apaga `Workspace["mundo-completo"]`.
- [ ] Escrever o script; `rock` com 1 variação; check verde; commit `feat: script dos templates do world-pack`.
- [ ] PARADA (controlador, Studio Edit): rodar o script, conferir as pastas, o Elizeu salva o place.

### Tarefa 3 (Opus): Construções com o modelo do Elizeu

**Arquivos:** `src/shared/Models/StructureModel.luau`, `src/shared/Models/CampfireModel.luau` (se preciso), `src/server/Services/StructureService.luau` (só se `setOpen` mudar de assinatura).

**Consome:** templates `ReplicatedStorage.Assets.Structures/<itemId>` (T2).
**Produz:** `StructureModel.build(itemId, def)` mantém a assinatura: monta o colisor de hoje (o builder do tipo) **invisível** e, se houver template, clona o visual por cima (pivô do template no pivô da peça); sem template, o provisório de hoje. Fogo: as chamas do template (`*_flames`) recebem o `FireLight`; tags/atributos de calor e estação iguais aos de hoje. `StructureModel.setOpen(model, open)`: com template de porta, as folhas `*_panel_left`/`*_panel_right` deslizam para fora (cada uma na direção do seu centro em relação ao centro da porta, a largura da folha) e o colisor perde/ganha colisão; sem template, o comportamento de hoje.
- [ ] Teste (Lune, puro) se houver conta nova (ex. deslocamento da folha) num helper puro; senão justificar no relatório.
- [ ] Check verde; commit `feat: construções com os modelos do Elizeu`.

### Tarefa 4 (Sonnet): Animações do cliente (tampa, rotor, chamas)

**Arquivos:** criar `src/client/World/StructureFx.luau`; ligar no controlador do cliente que inicia o mundo.

**Consome:** `ChestState.near` (tampa); atributos `Working: boolean` (extrator, T9) e `Lit: boolean` (fornalha, T9) nos modelos.
- Tampa do baú (`chest_lid`) gira −105° na dobradiça enquanto `ChestState.near()` é aquele baú; volta ao sair. Rotor (`*_rotor`) gira no eixo vertical enquanto `Working`. Chamas (`*_flames`) visíveis só com `Lit ~= false`. Só visual no cliente (não replica); um loop só para todas as peças com tag `StructureTag`.
- [ ] Check verde; commit `feat: animações das estruturas no cliente`.

### Tarefa 5 (Sonnet): Ícones 3D no inventário

**Arquivos:** `src/client/UI/ItemIcon.luau`.
- Com template em `ReplicatedStorage.Assets.Icons/<itemId>`: `ViewportFrame` com o modelo e câmera própria enquadrando (de cima, levemente inclinada), no lugar das iniciais; quantidade igual a hoje. Sem template: as iniciais de hoje. O ícone reage à troca de item do slot sem acumular modelos nem `ViewportFrame`.
- [ ] Check verde; commit `feat: ícones 3D no inventário`.
- [ ] PARADA (controlador, Studio Play): construções com modelo novo, porta abrindo as folhas, baú abrindo a tampa, fogueiras, rochas novas, ícones de madeira/pedra/ouro.

### Tarefa 6 (Sonnet): Dados das estruturas novas

**Arquivos:** `src/shared/Defs/Types.luau`, `Items.luau`, `Recipes.luau`, `Validate.luau`, `Strings/ptBR.luau`; testes em `tests/defs.spec.luau`.

**Produz:** `StructureKind` += `"spike_door" | "extractor" | "furnace" | "bridge" | "roof" | "sign" | "well" | "bed"`; `StructureDef` += `extractor: { output: string, woodPerCycle: number, cycleSeconds: number, yield: number, maxWood: number, maxStock: number }?`, `furnace: { burnEvery: number, maxWood: number }?` (calor por `heatRadius`), `well: { drinksPerBucket: number, maxDrinks: number, thirstPerDrink: number }?`, `bed: { regenFactor: number, drainFactor: number }?`. Validate: cada campo só no seu tipo e obrigatório nele; `spike_door` exige `spikeDamage`.
Itens (todos `testOnly = true`, `category = "placeable"` salvo o balde; vida provisória):

| id | estrutura | receita (bancada) |
|---|---|---|
| `wood_spike_door` / `stone_spike_door` / `gold_spike_door` | `spike_door`, vida da porta do tier (1000/1500/2000), `spikeDamage` do espinho do tier (10/20/30) | 1 porta + 1 espinho do tier (provisório) |
| `stone_extractor` / `gold_extractor` | `extractor`: output `stone`/`gold`, woodPerCycle 2, cycleSeconds 10 (wiki), yield 1, maxWood 100, maxStock 100, vida 300 (provisórios) | 200 madeira + 50 pedra / + 30 ouro (provisório) |
| `furnace` | `furnace`: burnEvery 6 (wiki), maxWood 200, heatRadius 24, vida 500, `station = "fire"` | 100 pedra + 30 ouro (provisório) |
| `bridge` | `bridge`, radius 2.1, vida 300 | 30 madeira (provisório) |
| `roof` | `roof`, radius 2.1, vida 300 | 25 madeira (provisório) |
| `sign` | `sign`, vida 100 | 20 madeira (wiki) |
| `well` | `well`: drinksPerBucket 12 (wiki), maxDrinks 48, thirstPerDrink 20, vida 500 | 60 pedra (provisório) |
| `bed` | `bed`: regenFactor 2, drainFactor 0.5, vida 300 | 100 madeira, 50 pedra, 5 `wolf_fur`, 5 `rabbit_fur`, 6 `thread` (wiki) |
| `bucket`, `water_bucket` | itens `misc`, maxStack 1 (sem estrutura) | balde: 15 madeira (provisório); o cheio não tem receita |

- [ ] Testes: os 13 itens novos existem, são `testOnly`, receitas batem com a tabela; Validate recusa `extractor` sem campo, campo em tipo errado, `spike_door` sem `spikeDamage`.
- [ ] Implementar; check verde; commit `feat: dados das estruturas novas (só para teste)`.

### Tarefa 7 (Sonnet): Porta com espinhos

**Arquivos:** `src/shared/Build/BuildRules.luau`, `src/server/Services/StructureService.luau`, `src/server/Services/SpikeService.luau`, `src/shared/Models/StructureModel.luau`; teste `tests/build.spec.luau`.

**Produz:** `BuildRules.isDoor(kind: string): boolean` (`door`, `spike_door`) e `BuildRules.hurts(kind: string): boolean` (`spike`, `spike_door`). Porta com espinhos abre/fecha para o dono como a porta (mesma recusa de fechar com alguém dentro) e fere quem não é aliado como o espinho (aberta ou fechada); modelo = colisor da porta + template.
- [ ] Testes de `isDoor`/`hurts`; implementar; check verde; commit `feat: porta com espinhos`.

### Tarefa 8 (Opus): Painel de interação com estruturas

**Arquivos:** criar `src/shared/Build/InteractRules.luau`, `src/server/Services/InteractService.luau`, `src/client/InteractState.luau`, `src/client/UI/InteractPanel.luau`; `net/game.blink`; ligar no cliente; teste `tests/interactrules.spec.luau`.

**Produz:**
- `InteractRules.ACTIONS = { put_wood = 1, take = 2, drink = 3, sleep = 4, symbol = 5, fill = 6 }`; `InteractRules.RANGE = 8`; `InteractRules.actionsFor(kind: string): { number }` (`extractor`: put_wood, take; `furnace`: put_wood; `well`: drink, fill; `bed`: sleep; `sign`: symbol); `InteractRules.allowed(kind, action, isOwner): boolean` (placa: só o dono; o resto: qualquer jogador, como o baú).
- Blink: `event StructureAction { From: Client, Type: Reliable, Call: SingleAsync, Data: struct { Target: Instance?, Action: u8, Arg: u8 } }`.
- Servidor: `InteractService.register(kind: string, handler: (player: Player, entry: StructureService.Entry, action: number, arg: number) -> ())`; valida limite de taxa (10/s), jogador vivo, `StructureService.entryOf`, distância ≤ RANGE, `allowed`, e chama o handler do tipo.
- Cliente: `InteractState.near: Model?` (estrutura interativa mais perto, polling 0,25 s pela tag `StructureTag`, como `ChestState`); `InteractPanel` (acima da hotbar, empilhado com o painel do baú/caixa sem sobrepor) mostra o nome, o estado lido de atributos do modelo (`Wood`, `Stock`, `Drinks`) e um botão por ação; `InteractState.act(action, arg)`.
- [ ] Testes de `actionsFor`/`allowed`; implementar; check verde; commit `feat: painel de interação com estruturas`.

### Tarefa 9 (Opus): Extrator e fornalha

**Arquivos:** criar `src/shared/Build/MachineRules.luau`, `src/server/Services/MachineService.luau`; teste `tests/machinerules.spec.luau`.

**Consome:** `InteractService.register` (T8), defs (T6). **Produz:** atributos `Wood`, `Stock`, `Working` (extrator) e `Wood`, `Lit` (fornalha) no modelo.
- `MachineRules.extractorStep(state: { wood: number, stock: number, timer: number }, def, dt): state` — a cada `cycleSeconds` com `wood >= woodPerCycle` e `stock < maxStock`: `wood -= woodPerCycle`, `stock += yield`; parado sem madeira ou cheio. `MachineRules.furnaceStep(state: { wood: number, timer: number }, def, dt): state` — 1 madeira a cada `burnEvery`; `lit = wood > 0`. `MachineRules.putWood(wood, have, max): number` (quanto entra, até 10 por ação).
- `put_wood`: tira do inventário e põe (não volta); `take` (extrator): dá o estoque ao jogador (o que couber). Fornalha acesa = tag de calor (`HeatSourceTag`, `HeatRadius` = def.heatRadius, sem `BurnRadius`) e estação `fire`; apagada = sem tag de calor. Estado some com a peça (`StructureService.onRemoved`).
- [ ] Testes: ciclo do extrator (2 madeiras → 1 pedra a cada 10 s), para sem madeira e com estoque cheio; fornalha queima 1 a cada 6 s e apaga em 0; `putWood` respeita o máximo. Implementar; check verde; commit `feat: extrator e fornalha`.

### Tarefa 10 (Sonnet): Poço e balde

**Arquivos:** criar `src/shared/Build/WellRules.luau`, `src/server/Services/WellService.luau`; `src/shared/Simulation/WaterSim.luau` (consulta "água perto", se preciso); teste `tests/wellrules.spec.luau`.

**Consome:** T8, T6. **Produz:** atributo `Drinks` no poço.
- Encher o balde: com `bucket` na mão e usando (`Using`) com água a ≤ 3 studs → troca por `water_bucket`. `fill` no poço com `water_bucket` na mão → `Drinks += drinksPerBucket` (até `maxDrinks`) e volta a `bucket`. `drink` → se `Drinks > 0`: `Drinks -= 1` e `SurvivalService.applyFood(player, { thirst = def.well.thirstPerDrink })` (como a comida; recusa se a sede já está cheia). Do balde não se bebe.
- `WellRules.fill(drinks, def): number?` (nil se cheio), `WellRules.drink(drinks): number?` (nil se vazio).
- [ ] Testes de `fill`/`drink` (12 por balde, teto 48, vazio não bebe); implementar; check verde; commit `feat: poço e balde`.

### Tarefa 11 (Sonnet): Cama

**Arquivos:** `src/shared/Survival/SurvivalRules.luau` (contexto `sleeping` + fatores), `src/server/Services/SurvivalService.luau`, criar `src/server/Services/BedService.luau`; `src/shared/Defs/Expressions.luau` (olhos fechados dormindo); teste `tests/survival.spec.luau`.

**Produz:** atributo de personagem `Sleeping: boolean`.
- `sleep` na cama: `Sleeping = true` e o jogador fica na cama; levanta ao andar (qualquer movimento, lido por polling), ao levar dano ou se a cama sumir. Dormindo: regeneração × `regenFactor`, queda de fome/sede/frio × `drainFactor`; soma com o calor da fogueira; pode ser atacado. Olhos fechados (expressão por condição `Sleeping`).
- [ ] Testes: `SurvivalRules.step` com `sleeping` regenera o dobro e gasta a metade. Implementar; check verde; commit `feat: cama`.

### Tarefa 12 (Sonnet): Placa

**Arquivos:** criar `src/shared/Build/SignRules.luau`, `src/server/Services/SignService.luau`; visual da placa (`SurfaceGui` na frente do modelo, lado −Z local, ou `BillboardGui` se o template não tiver face boa); teste `tests/signrules.spec.luau`.

**Produz:** `SignRules.SYMBOLS: { string }` (8 a 12 símbolos fixos: setas, perigo, coração, caveira, estrela, casa, ponto de exclamação, interrogação…) e atributo `Symbol: number` no modelo. `symbol` (só o dono) com `Arg` = índice válido grava o símbolo; o painel mostra os botões dos símbolos.
- [ ] Teste de índice válido/inválido; implementar; check verde; commit `feat: placa`.

### Tarefa 13 (Opus): Ponte e telhado

**Arquivos:** `src/shared/Simulation/WaterSim.luau`, `src/shared/Build/BuildRules.luau`, `src/server/Services/StructureService.luau`, `src/server/Services/MobService.luau`, `src/shared/Models/StructureModel.luau`, criar `src/client/World/RoofFade.luau`; testes em `tests/build.spec.luau`.

**Produz:**
- `BuildRules.insideAny(x: number, z: number, circles: { { x: number, z: number, r: number } }): boolean`.
- Ponte: `canPlace` aceita a ponte **só** onde é água e sem outra ponte no círculo; as outras peças continuam proibidas na água (água "de verdade", sem contar ponte). `WaterSim.isWet(x, z)` = água e **não** sobre uma ponte (pontes via tag e raio no modelo, lidas no servidor e no cliente); `WaterSim.isWaterAt(x, z)` = água bruta (usada pelo `canPlace` e pelo balde). Ponte não colide (anda por cima, no nível do chão).
- Telhado: `canPlace` do telhado só confere contra outros telhados; as outras peças ignoram telhados; telhado sem colisão, visual na altura das paredes. Mob com `stats.flies` não morde alvo sob telhado. Cliente: telhado sobre o jogador local fica translúcido.
- [ ] Testes de `insideAny`; implementar; check verde; commit `feat: ponte e telhado`.

### Tarefa 14 (Sonnet): Bancada das estruturas no Edit

**Arquivos:** criar `scripts/studio/structure-bench.luau` (modos `montar`/`captar`/`apagar`, como `weapon-bench.luau`).
- `montar`: em `Workspace.BancadaEstruturas`, cada template de `Assets.Structures` sobre um disco no tamanho do círculo da peça (`BuildRules.radiusOf(def)`), travado; o template (`Visual`) selecionável. `captar`: grava no template a escala e o deslocamento/giro do `Visual` em relação ao disco (só os que mudaram) e confere remontando.
- [ ] Escrever; check verde; commit `feat: bancada das estruturas`.
- [ ] PARADA (controlador + Elizeu): bancada; ele ajusta; captar; salvar o place; Play com todas as estruturas novas pelo `DevGive`.

### Tarefa 15 (Sonnet): Documentação e plano do futuro

- `docs/guia/construcao.md`: modelos novos, portas com espinhos, estruturas interativas, ponte/telhado, marca `testOnly` (como liberar num update), `import-world.luau` e a bancada. `docs/guia/telas.md` ou `hud.md`: o painel de interação e os ícones 3D.
- Criar `docs/futuro-estruturas.md`: o que já está pronto e o que falta para diamante, ametista, reidite (construções, portas com espinhos, extratores, depósitos, ícones), esmeralda (depósito, ícone, máquina), pedra de ressurreição, totem e times (próxima etapa), com as regras da wiki da spec.
- [ ] Check verde; `& (Get-Content graphify-out\.graphify_python) -m graphify update .`; commit `docs: estruturas da floresta e plano do futuro`.
