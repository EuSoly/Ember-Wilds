# Armaduras Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** As 32 peças de cabeça do Starve viram itens com receita e status oficiais, aparecem no boneco e funcionam (defesa jogador/mob, frio, calor do fogo, oxigênio, nado, regen, capuz, explorador, trava de troca); o que o jogo ainda não tem fica `testOnly`.

**Architecture:** Os números ficam em unidades do Starve no bloco `armor` de cada item (`Defs/Items.luau`); a conversão para o nosso jogo mora em regras puras (`Survival/ArmorRules.luau`) usadas por `SurvivalRules`, `CharacterService`, `WaterService`, `WaterSim` e `MobBrain`. O visual é um clone de `ReplicatedStorage.Assets.Armor/<id>` soldado no Body do boneco pelo `BonecoRenderer`.

**Tech Stack:** Luau `--!strict`, Rojo, Vide (UI), Blink (rede), testes em Lune (`lune run tests/run`), `bash scripts/check.sh` (StyLua, selene, build, luau-lsp, testes; precisa `export PATH="$HOME/.rokit/bin:$PATH"`).

**Spec:** `docs/superpowers/specs/2026-11-10-armaduras-design.md` (números brutos: `docs/game-design/armaduras-starve.md`).

## Global Constraints

- Mensagens de commit em pt-BR, terminando com `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; sem push.
- Conteúdo = dados: nenhum código conhece item pelo id (exceto testes e a lista de ids da Task 2).
- Números do Starve sem escala (decisão do Elizeu). Defesa: `max(golpe − defesa, 0)`.
- Liberados (sem `testOnly`): `wood_helmet`, `stone_helmet`, `gold_helmet`, `earmuffs`, `coat`, `turban`, `explorer`, `hood`, `peasant`. Todas as outras peças e todos os materiais novos: `testOnly = true`.
- Textos de jogador em pt-BR com acentos, em `src/shared/Strings/ptBR.luau`.
- Antes de cada commit: `bash scripts/check.sh` verde (787 testes hoje + os novos).
- Atributos do personagem previsto: ler por polling, nunca `GetAttributeChangedSignal` no cliente (Server Authority).

## Review Focus

- Peça vestida cujo id sumiu das Defs ou sem modelo em `Assets.Armor` → neutro, sem erro, um `warn` só (Task 1 testa o neutro; Task 7 o `warn` único).
- Golpe menor que a defesa (aranha 16 × lava 30) → 0 de dano, nunca negativo nem cura (Task 1).
- Peça trocada/tirada/morte → modelo antigo some do boneco, sem duas peças ao mesmo tempo (Task 7).
- Capuz no jogador local → ele continua vendo o próprio nick; os outros não (Task 7).
- Bater em recurso/estrutura/caixa com o explorador → efeito desliga 10 s (Task 6 testa a regra; o hook cobre todos os alvos do `GatherService`).

---

### Task 1: Regras da armadura em unidades do Starve

**Files:**
- Modify: `src/shared/Defs/Types.luau` (bloco `ArmorStats`, novo `ArmorWarm`)
- Modify: `src/shared/Survival/ArmorRules.luau`
- Modify: `src/shared/SurvivalConfig.luau`
- Modify: `src/shared/Defs/Validate.luau:713-740` (`ARMOR_LIMITS`, `validateArmor`)
- Modify: `src/shared/Defs/Items.luau` (4 peças atuais no formato novo, valores do spec)
- Test: `tests/armor.spec.luau` (reescrever)

**Interfaces:**
- Produces:
  - `Types.ArmorStats` exatamente como no spec ("Modelo de dados"), sem `coldFactor`/`heatFactor`.
  - `ArmorRules.Modifiers = { defense: number, mobDefense: number, warm: ArmorWarm (campos ausentes = 0), fireHeatFactor: number, oxygenLoss: number, swimSpeed: number, regenHeal: number?, hidesName: boolean, explorer: boolean, hungerFactor: number, thirstFactor: number }`
  - `ArmorRules.NONE` (defesas 0, warm todo 0, `fireHeatFactor` 1, `oxygenLoss` 0, `swimSpeed` 1, `regenHeal` nil, booleanos false, fatores 1).
  - `ArmorRules.modifiers(def: ItemDef?): Modifiers`
  - `ArmorRules.reduce(amount: number, mods: Modifiers, source: "player" | "mob"): number`
  - `export type ColdPlace = "forest" | "water" | "winter"`
  - `ArmorRules.coldMultiplier(mods: Modifiers, place: ColdPlace, isNight: boolean): number` = `(B − warm)/B` com `B = SurvivalConfig.STARVE_COLD_LOSS[place][day|night]`; pode ser negativo.
  - `ArmorRules.oxygenFactor(mods): number` = `(STARVE_OXYGEN_LOSS − oxygenLoss) / STARVE_OXYGEN_LOSS`, piso 0.
  - `ArmorRules.regenFactor(mods): number` = `(regenHeal or STARVE_REGEN_HEAL) / STARVE_REGEN_HEAL`.
  - `SurvivalConfig`: remove `MAX_DEFENSE`; adiciona `MAX_ARMOR_DEFENSE = 100`, `STARVE_COLD_LOSS = { forest = { day = 2, night = 18 }, water = { day = 5, night = 25 }, winter = { day = 25, night = 50 } }`, `STARVE_OXYGEN_LOSS = 25`, `STARVE_REGEN_HEAL = 12`, `ARMOR_SWAP_LOCK = 5`, `EXPLORER_OFF = 10`.

- [ ] **Step 1: Reescrever `tests/armor.spec.luau`** com os casos (cada um um `["..."] = function()`):
  - `no armor is neutral`: `modifiers(nil) == NONE`; `reduce(10, NONE, "player") == 10`; `coldMultiplier(NONE, "forest", true) == 1`; `oxygenFactor(NONE) == 1`; `regenFactor(NONE) == 1`.
  - `defense subtracts by source`: peça `{ defense = 4, mobDefense = 13 }`: `reduce(22, m, "player") == 18`, `reduce(24, m, "mob") == 11`.
  - `defense never heals`: `{ mobDefense = 30 }`: `reduce(16, m, "mob") == 0`.
  - `coat keeps cold at day`: warm `{ day = 2, night = 13 }`: `coldMultiplier(m, "forest", false) == 0`; noite `≈ 5/18` (tolerância 1e-9).
  - `fur hat warms by day`: warm `{ day = 3, night = 17 }`: dia `== -0.5`; noite `≈ 1/18`.
  - `water uses water warm`: warm `{ waterDay = 2, waterNight = 15 }`: `coldMultiplier(m, "water", false) ≈ 3/5`, noite `≈ 10/25`.
  - `diving mask oxygen`: `{ oxygenLoss = 14 }` → `oxygenFactor ≈ 11/25`; `{ oxygenLoss = 30 }` → `0`.
  - `life crown regen`: `{ regenHeal = 40 }` → `regenFactor ≈ 40/12`.
  - `item without armor block is neutral` (manter o atual).
- [ ] **Step 2:** `lune run tests/run` → FAIL nos casos novos.
- [ ] **Step 3: Implementar** tipos, `ArmorRules`, `SurvivalConfig`; `Validate`: limites `defense`/`mobDefense` 0..`MAX_ARMOR_DEFENSE`, cada campo de `warm` −200..200, `fireHeatFactor`/`swimSpeed`/`hungerFactor`/`thirstFactor` 0..`MAX_FACTOR`, `oxygenLoss` 0..`STARVE_OXYGEN_LOSS`, `regenHeal` 0..200; booleanos/dados futuros só checam tipo. Atualizar as 4 peças de `Items.luau` com os valores do spec (madeira 1/4, pedra 2/8, ouro 4/13, protetor warm 1/10, 0/0, 4/10, −4/−10, blizzard 8). Ajustar todo uso de `armor.defense` como fração e de `coldFactor`/`heatFactor` (`SurvivalRules`, `ItemInfo`, `defs.spec`, `iteminfo.spec`, `survival.spec`) só o suficiente para compilar e passar; o comportamento novo do frio vem na Task 4 (nesta task `SurvivalRules` usa `ArmorRules.coldMultiplier(mods, "forest", isNight)` no lugar de `mods.coldFactor`, e `mods.fireHeatFactor` no lugar de `mods.heatFactor`). `CharacterService.hurt` passa `"player"` por enquanto (Task 3 troca).
- [ ] **Step 4:** `bash scripts/check.sh` → tudo verde.
- [ ] **Step 5: Commit** `feat(armaduras): defesa e status em unidades do Starve`.

### Task 2: As 32 peças, materiais e textos

**Files:**
- Modify: `src/shared/Defs/Items.luau`, `src/shared/Defs/Tiers.luau` (só se faltar tier usado), `src/shared/Strings/ptBR.luau`
- Test: `tests/defs.spec.luau`

**Interfaces:**
- Consumes: `Types.ArmorStats` (Task 1).
- Produces: itens com ids exatamente: `wood_helmet stone_helmet gold_helmet diamond_helmet amethyst_helmet reidite_helmet dragon_helmet crab_helmet lava_helmet earmuffs coat winter_hat fur_hat turban ninja pilot diamond_protection amethyst_protection reidite_protection explorer hood winter_hood peasant winter_peasant diving_mask diving_suit witch santa elf life_crown angel_crown luck_crown`; materiais `diamond amethyst winter_fur mammoth_fur penguin_feather vulture_feather kraken_skin piranha_scales flame dragon_heart lava_heart crab_claws crab_sticks blue_thread green_gem blue_gem orange_gem blue_cube lava_cube pilot_glasses black_wolf_fur white_wolf_fur firefly`.

- [ ] **Step 1: Testes em `tests/defs.spec.luau`:**
  - `armor pieces match the Blender pack`: a lista de 32 ids acima (constante no teste) é exatamente o conjunto de itens com `category == "armor"`; todos `maxStack == 1`.
  - `armor release list`: `testOnly ~= true` exatamente para os 9 liberados; todos os outros 23 e todos os 23 materiais novos com `testOnly == true`.
  - `starve numbers spot check`: `lava_helmet.armor.defense == 9 and mobDefense == 30`; `angel_crown.armor.defense == 2 and mobDefense == 16`; `fur_hat.armor.warm.day == 3 and warm.night == 17`; `diving_suit.armor.oxygenLoss == 19 and swimSpeed == 1.2`; `diamond_protection.armor.fireHeatFactor == 0`; `hood.armor.hidesName == true`; `explorer.armor.explorer == true`; `life_crown.armor.regenHeal == 40`.
  - `crab food`: `crab_sticks.food.hunger == 20`, `crab_claws.food.hunger == 10`.
  - Todo item tem `Strings` para `nameKey` (o teste geral existente já cobre; confirmar que passa).
- [ ] **Step 2:** rodar → FAIL.
- [ ] **Step 3: Escrever os dados** com a tabela do spec (todas as colunas; "—" = campo ausente; `witch` = números do protetor; dados futuros com os nomes do tipo: `blizzard`, `sand = { damage, every }`, `cropGrowth`, `stealImmune`, `tameLuck`, `digLuck`, `resurrect`, `crabFriend`, `spiderImmune`, `pilotAcceleration`, `gearSet`). `tier` nos capacetes de tier existentes em `Tiers`. Nomes pt-BR (`item.<id>`): Capacete de madeira/pedra/ouro/diamante/ametista/reidite/dragão/caranguejo/lava, Protetor de orelha, Casaco, Gorro e cachecol, Chapéu de pele, Turbante, Roupa ninja, Chapéu de piloto, Proteção de diamante/ametista/reidite, Chapéu de explorador, Capuz, Capuz de inverno, Túnica de camponês, Túnica de camponês de inverno, Máscara de mergulho, Roupa de mergulho, Chapéu de bruxa, Gorro de Natal, Gorro de elfo, Coroa da Vida, Coroa do Anjo, Coroa da Sorte; Diamante, Ametista, Pele de inverno, Pele de mamute, Pena de pinguim, Pena de abutre, Pele de kraken, Escama de piranha, Chama, Coração de dragão, Coração de lava, Garra de caranguejo, Palito de caranguejo, Linha azul, Gema verde, Gema azul, Gema laranja, Cubo azul, Cubo de lava, Óculos de piloto, Pele de lobo negro, Pele de lobo branco, Vaga-lume. Comidas: `crab_claws` `food = { hunger = 10 }`, `crab_sticks` `food = { hunger = 20 }`.
- [ ] **Step 4:** `bash scripts/check.sh` verde.
- [ ] **Step 5: Commit** `feat(armaduras): 32 peças e materiais do Starve nas Defs`.

### Task 3: Receitas e estações combinadas (fogo e água)

**Files:**
- Modify: `src/shared/Defs/Types.luau` (`CraftStation`, `RecipeDef.alsoNear`), `src/shared/Defs/Recipes.luau`, `src/shared/Defs/Validate.luau:650-660`
- Modify: `src/shared/Craft/CraftRules.luau`, `src/server/Services/CraftService.luau:29-45,100-102`, `src/client/CraftState.luau:41-75`, `src/shared/Simulation/WaterSim.luau` (consulta de proximidade)
- Modify: `src/shared/UIFlow/BookInfo.luau:97-120,198`, `src/client/UI/BookSheet.luau:303`, `src/client/UI/CraftColumn.luau:40-43`, `src/shared/Strings/ptBR.luau` (`craft.needWater`, `craft.station.water`)
- Test: `tests/craft.spec.luau`, `tests/bookinfo.spec.luau`, `tests/defs.spec.luau`

**Interfaces:**
- Produces:
  - `Types.CraftStation = "workbench" | "fire" | "water"`; `RecipeDef.alsoNear: { CraftStation }?` (estações exigidas além de `station`).
  - `CraftRules.stationsOf(recipe: RecipeDef): { CraftStation }` (todas, na ordem `station` + `alsoNear`); `canCraft` exige todas em `near`.
  - `CraftRules.missingStation(recipe, near): CraftStation?` (primeira faltando).
  - `WaterSim.isNearWater(x: number, z: number, radius: number): boolean` (mesma geometria do `isWet`, distância no plano XZ até a borda ≤ radius).
  - `BookInfo` craft devolve `stations: { string }` (no lugar de `station: string?`; atualizar `BookSheet` para desenhar todas).

- [ ] **Step 1: Testes:**
  - `craft.spec` → `combined stations need all`: receita `{ station = "workbench", alsoNear = { "fire", "water" } }`: `canCraft` false com `{ workbench = true, fire = true }`, true com os três; `missingStation` devolve `"water"` no primeiro caso.
  - `defs.spec` → `armor recipes`: toda peça, exceto `santa`/`elf`, tem receita com `result == id`; `reidite_helmet.alsoNear` = `{ "fire" }`; `life_crown.alsoNear` = `{ "fire", "water" }`; `explorer` = `paper 1, rabbit_fur 1, thread 2`, `station == "workbench"`, `time == 5`; `blue_thread` = `diamond 1, thread 1`, tempo 3; nenhum ingrediente aponta para item inexistente (o Validate já faz; o teste chama `Validate.all`).
  - `defs.spec` → `released recipes only use released items`: para cada receita cujo resultado não é `testOnly`, nenhum ingrediente é `testOnly`.
  - `bookinfo.spec`: ajustar para `stations`, e `crown shows three stations` (`#craft.stations == 3`).
- [ ] **Step 2:** rodar → FAIL.
- [ ] **Step 3: Implementar.** Receitas com os números da tabela "Receitas" do spec (ids nossos; ordem no livro continuando depois dos atuais, peças do mesmo grupo juntas). `earmuffs` e `leather_bag` mantêm `order`; trocar só a receita do `earmuffs`. `witch` = 5 `wolf_fur`, 2 `rabbit_fur`, 6 `thread`, 2 `firefly`, bancada, 30 s. `CraftService`: checar cada estação; aviso `craft.needWorkbench`/`craft.needFire`/`craft.needWater` conforme `missingStation`; "water" usa `WaterSim.isNearWater(pos.X, pos.Z, CraftRules.STATION_RADIUS)`. `CraftState.updateNear` marca `result.water` do mesmo jeito. Strings: `craft.needWater` = "Precisa estar perto da água", `craft.station.water` = "Água".
- [ ] **Step 4:** `bash scripts/check.sh` verde.
- [ ] **Step 5: Commit** `feat(armaduras): receitas do Starve e estações com fogo e água`.

### Task 4: Defesa por origem do golpe

**Files:**
- Modify: `src/server/Services/CharacterService.luau:27-60`, `src/server/Services/GatherService.luau:205`, `src/server/Services/MobService.luau:455`, `src/server/Services/SpikeService.luau:122`, `src/server/Services/DevBonecoService.luau:89,237`, `src/server/Services/SurvivalService.luau:141`
- Test: coberto pelo `armor.spec` (Task 1); aqui só compilação e checagem.

**Interfaces:**
- Consumes: `ArmorRules.reduce(amount, mods, source)`.
- Produces: `CharacterService.HurtKind = "player" | "mob" | "survival"`; `"player"` e `"mob"` contam como combate (careta sempre, armadura protege com `defense`/`mobDefense`).

- [ ] **Step 1:** Trocar o tipo e o `if kind == "combat"` por `kind ~= "survival"`; chamar `reduce(amount, mods, kind)` quando `kind ~= "survival"`. Golpe reduzido a 0 → nada acontece (nem careta), igual ao `amount <= 0` de hoje (fazer a redução antes da guarda).
- [ ] **Step 2:** Chamadores: `GatherService` `"player"`; `MobService` `"mob"`; `SpikeService` `"player"`; `DevBonecoService` `"mob"` (linhas 89 e 237); `SurvivalService` continua `"survival"`.
- [ ] **Step 3:** `bash scripts/check.sh` verde (o luau-lsp acusa qualquer `"combat"` sobrando).
- [ ] **Step 4: Commit** `feat(armaduras): defesa contra jogador e contra mob como no Starve`.

### Task 5: Frio, calor do fogo, regen, oxigênio e nado

**Files:**
- Modify: `src/shared/Survival/SurvivalRules.luau` (Context, step), `src/server/Services/SurvivalService.luau:120-140`, `src/server/Services/WaterService.luau:33-44`, `src/shared/Simulation/WaterSim.luau:132`
- Test: `tests/survival.spec.luau`

**Interfaces:**
- Consumes: `ArmorRules.coldMultiplier`, `regenFactor`, `oxygenFactor`, `Modifiers.fireHeatFactor`, `Modifiers.swimSpeed`.
- Produces: `SurvivalRules.Context.coldPlace: ArmorRules.ColdPlace` (no lugar de `biomeColdFactor`; a base do nosso jogo por bioma continua em `BIOME_COLD_FACTOR`, agora indexada pelo `coldPlace` de terra; na água usa o `WATER_COLD_FACTOR` atual × `coldMultiplier(mods, "water", isNight)`).

- [ ] **Step 1: Testes em `survival.spec`:**
  - `coat keeps cold by forest day`: mods do casaco, dia, floresta, longe do fogo: frio igual depois de 10 s.
  - `fur hat warms by forest day`: mods do chapéu de pele, dia: frio sobe `0.4 × 0.5 × dt` (de 50 para 52 em 10 s).
  - `earmuffs slow night cold`: noite: queda = `1.6 × 8/18 × dt`.
  - `protection blocks fire heat`: `onFire`, frio cheio, `fireHeatFactor = 0`: calor fica 0.
  - `life crown regenerates faster`: regen = `REGEN_RATE × 40/12 × dt` (barras acima de `REGEN_MIN`).
  - `cold gain caps at full`: chapéu de pele de dia com frio 100 → continua 100 e calor 0 (aquecer pela roupa não enche o calor).
- [ ] **Step 2:** rodar → FAIL.
- [ ] **Step 3: Implementar.** No ramo "longe do fogo": `drain = base(isNight) × BIOME_COLD_FACTOR[coldPlace] × coldMultiplier(mods, place, isNight) × drainFactor`, com `place = if inWater then "water" else coldPlace` e o `WATER_COLD_FACTOR` atual na água; `cold = clamp(cold − drain × dt)` (drain negativo esquenta, `clamp` segura em 100). Calor: `heat + max(warmed − MAX, 0) × mods.fireHeatFactor`. Regen: `REGEN_RATE × regenFactor(sleep) × ArmorRules.regenFactor(mods)`. `SurvivalService` passa `coldPlace = "forest"`. `WaterService`: na água `rate × ArmorRules.oxygenFactor(ArmorService.modifiers(player))`. `WaterSim`: na água `speed *= ArmorRules.modifiers(Defs.Items[player:GetAttribute(StatNames.Armor)]).swimSpeed` (atributo do Player, lido a cada passo).
- [ ] **Step 4:** `bash scripts/check.sh` verde.
- [ ] **Step 5: Commit** `feat(armaduras): frio por contexto, proteções contra o fogo, coroa da vida, mergulho`.

### Task 6: Trava de troca e explorador

**Files:**
- Modify: `src/shared/StatNames.luau` (`ArmorLockUntil`, `ExplorerOffUntil`), `src/server/Services/WearService.luau`, `src/server/Services/ArmorService.luau`, `src/server/Services/DeathService.luau` (limpar atributos), `src/server/Services/GatherService.luau` (marcar golpe), `src/shared/Mobs/MobBrain.luau` (Seen.stealth), `src/server/Services/MobService.luau:200-260,535`
- Create: nada (regra pura em `ArmorRules`)
- Test: `tests/armor.spec.luau`, `tests/mobbrain.spec.luau`

**Interfaces:**
- Produces:
  - `ArmorRules.canSwap(lockUntil: number?, now: number): boolean`
  - `ArmorRules.isStealthy(mods: Modifiers, offUntil: number?, now: number): boolean` (explorer e `now >= (offUntil or -inf)`)
  - `MobBrain.Seen.stealth: boolean?`: em `thinkHunter`, agressivo não começa perseguição em quem tem `stealth`; perseguindo, alvo visto com `stealth` → `giveUp`.
  - `MobService.closest(list, x, z, skipStealth: boolean)` — mobs não passivos ignoram `stealth` ao escolher o mais perto.

- [ ] **Step 1: Testes:**
  - `armor.spec` → `swap lock`: `canSwap(nil, 0)`; `not canSwap(10, 9)`; `canSwap(10, 10)`.
  - `armor.spec` → `explorer stealth`: com `explorer = true`: `isStealthy(m, nil, 5)`, `not isStealthy(m, 20, 15)`, `isStealthy(m, 20, 20)`; sem explorer sempre false.
  - `mobbrain.spec` → `aggressive ignores stealthy`: lobo parado, `nearest = { who = "p", x = 1, z = 0, stealth = true }` → continua `wander`.
  - `mobbrain.spec` → `chase drops stealthy target`: em perseguição, alvo visto com `stealth = true` → `mode == "wander"` depois do `think`.
- [ ] **Step 2:** rodar → FAIL.
- [ ] **Step 3: Implementar.** `WearService`: ao vestir, recusa se `not canSwap(player:GetAttribute(ArmorLockUntil), now)`; depois de vestir grava `now + ARMOR_SWAP_LOCK`. `DeathService` (onde já zera `Armor`) zera `ArmorLockUntil` e `ExplorerOffUntil`. `GatherService`: todo golpe que acerta algo (mob, jogador, caixa, estrutura, recurso) grava `ExplorerOffUntil = now + EXPLORER_OFF` no Player que bateu (só se a peça tiver `explorer`). `MobService.livingBodies` preenche `stealth` com `isStealthy`.
- [ ] **Step 4:** `bash scripts/check.sh` verde.
- [ ] **Step 5: Commit** `feat(armaduras): espera de 5 s para trocar e chapéu de explorador`.

### Task 7: Peça no boneco e nick escondido

**Files:**
- Create: `src/client/Boneco/ArmorModel.luau`
- Modify: `src/client/Boneco/BonecoRenderer.luau:205-255` (Entry, `syncAttributes`, `build`, `remove`)
- Modify: `docs/guia/boneco.md` (seção curta)

**Interfaces:**
- Produces:
  - `ArmorModel.build(itemId: string): Model?` — clona `ReplicatedStorage.Assets.Armor/<id>`; nil + `warn` uma vez por id se faltar.
  - `ArmorModel.attach(model: Model, boneco: BonecoModel.Boneco)` — `PivotTo(boneco.bodyJoint.Part1.CFrame)`, `WeldConstraint` de cada BasePart ao Body, `Anchored/CanCollide/CanQuery/CanTouch = false`, `Massless = true`, parent `boneco.model`. Mesmo padrão do `BagModel.attach`.
  - `Entry.armorId: string?`, `Entry.armorModel: Model?`, `Entry.nameHidden: boolean`.

- [ ] **Step 1:** `syncAttributes` lê `owner:GetAttribute(StatNames.Armor)` (Player); mudou → destrói o modelo antigo, monta o novo. `nameHidden = ArmorRules.modifiers(def).hidesName and owner ~= Players.LocalPlayer` → `boneco.nameLabel.Visible = not nameHidden` (e o selo do tutorial também some quando escondido). Bonecos de teste sem Player: sem armadura.
- [ ] **Step 2:** Verificar no Studio (Play): `ServerStorage.DevArmor:Invoke(p, "wood_helmet")` na vista do servidor → capacete no centro do corpo, frente para onde o boneco olha; trocar para `hood` com um segundo jogador (Test → 2 Players) → o nick some para o outro e fica para o dono; `DevArmor(p, nil)` → some. Print/`screen_capture` da vista de cima.
- [ ] **Step 3:** `bash scripts/check.sh` verde.
- [ ] **Step 4: Commit** `feat(armaduras): peça vestida aparece no boneco; capuz esconde o nick`.

### Task 8: Ícone, dicas e livro

**Files:**
- Modify: `src/client/UI/ItemIcon.luau:70-80` (fonte `Armor`, `kind = "armor"` com vista de frente levemente de cima), `src/shared/UIFlow/ItemInfo.luau:60-80`, `src/shared/Strings/ptBR.luau`
- Test: `tests/iteminfo.spec.luau`

**Interfaces:**
- Produces: linhas do `ItemInfo` com chaves `info.defensePlayer` ("Defesa contra jogadores: {n}"), `info.defenseMob` ("Defesa contra criaturas: {n}"), `info.warm` ("Protege do frio"), `info.fireproof` ("Anula o calor do fogo"), `info.oxygen` ("Fôlego dura mais na água"), `info.swim` ("Nada mais rápido"), `info.regen` ("Vida volta mais rápido"), `info.hidesName` ("Esconde seu nome"), `info.explorer` ("Criaturas não atacam você (até você bater em algo)").

- [ ] **Step 1: Testes `iteminfo.spec`:** gold_helmet → linhas `info.defensePlayer` 4 e `info.defenseMob` 13; coat → `info.warm`; diamond_protection → `info.fireproof`; diving_mask → `info.oxygen` e `info.swim`; hood → `info.hidesName`; explorer → `info.explorer`; life_crown → `info.regen`. Item sem armadura → nenhuma dessas.
- [ ] **Step 2:** rodar → FAIL.
- [ ] **Step 3: Implementar** (`info.warm` quando `warm.night > 0`; `info.fireproof` quando `fireHeatFactor == 0`; `info.oxygen` quando `oxygenLoss > 0`; `info.swim` quando `swimSpeed > 1`; `info.regen` quando `regenHeal > STARVE_REGEN_HEAL`). Remover as chaves antigas sem uso (`info.defense` em %, `coldFactor`).
- [ ] **Step 4:** `bash scripts/check.sh` verde; no Studio, abrir o livro na aba Armaduras e conferir os ícones 3D (ajustar `IconeGiro/IconeZoom` só se alguma peça sair cortada).
- [ ] **Step 5: Commit** `feat(armaduras): ícones 3D e dicas das peças`.

### Task 9: Documentação e fechamento

**Files:**
- Create: `docs/guia/armaduras.md`
- Modify: `docs/guia/sobrevivencia.md` (seção "Armaduras (preparadas)" → resumo + link), `docs/guia/combate.md` (defesa), `docs/guia/adicionar-item.md` (peça de cabeça), `docs/pendencias.md` (seção "Armaduras (10/11)")

- [ ] **Step 1:** `armaduras.md`: o que são, unidades do Starve e conversão (frio `(B − warm)/B`, oxigênio, regen), liberadas × `testOnly` e como liberar, como adicionar peça (modelo em `Assets.Armor` com pivô no centro do corpo girado 180°, Def, receita, texto), comandos de teste (`DevGive`, `DevArmor`), efeitos só-dado.
- [ ] **Step 2:** `pendencias.md`: mordidas mais fracas que no Starve × defesa contra mob sem escala; efeitos só-dado (roubo, fazenda, sorte, ressurreição, nevasca, areia, lava, bônus de conjunto, piloto, bruxa, caranguejos); Chapéu de pele esquentando não enche o calor; o `armaduras-32` original no Workspace pode ser apagado; gemas/cubos/óculos/peles especiais/vaga-lume sem modelo.
- [ ] **Step 3:** `bash scripts/check.sh` verde; `& (Get-Content graphify-out\.graphify_python) -m graphify update .` (PowerShell).
- [ ] **Step 4: Commit** `docs(armaduras): guia das armaduras e pendências`.
