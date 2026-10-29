# G1 Sobrevivência — Plano de implementação

> **Para quem implementa (Cline ou outro agente):** siga as tarefas na ordem, uma por vez. Cada tarefa termina com `bash scripts/check.sh` passando e um commit. Passos com caixinha (`- [ ]`). **Pare nos pontos marcados "PARADA"** e avise: o Claude valida no Studio antes de continuar.

**Objetivo:** fazer vida, fome, frio e sede funcionarem de verdade (como no Starve.io), com comer frutinha, fogueira esquentando, morte por barra vazia e as armaduras preparadas (dados + regras + vestir no servidor, sem conteúdo).

**Arquitetura:** regras puras em `src/shared/Survival/` (testadas no Lune) + serviços no servidor que leem o mundo, chamam as regras e gravam os atributos que o HUD já lê. Todos os números em `src/shared/SurvivalConfig.luau`.

**Stack:** Luau `--!strict`, Rojo, Lune (testes), StyLua, selene. Rodar tudo: `bash scripts/check.sh` (no PowerShell: `& "C:\Program Files\Git\bin\bash.exe" scripts/check.sh`).

**Spec:** `docs/superpowers/specs/2026-10-29-g1-sobrevivencia-design.md` (leia antes).

## Regras globais

- Respostas, comentários e commits em **português do Brasil**. Commit por tarefa, **sem push**. Mensagem termina com `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Requires: em `src/shared` use string requires (`require("../StatNames")`); no servidor, `ReplicatedStorage.Shared.X` e `script.Parent.X`. Veja os arquivos vizinhos.
- Todo ModuleScript em `src/server/Services` é carregado sozinho (`Init`/`Start`). Não precisa registrar.
- Conteúdo é dado: nenhum código pode testar o id de um item (`if id == "berry"`). Use `def.food`, `def.armor`, `def.category`.
- Atributos sempre pelos nomes de `StatNames`, nunca strings soltas.
- Antes de explorar o código, rode `graphify query "<pergunta>"` (regra do CLAUDE.md). Depois de terminar cada tarefa: `graphify update .`.
- Não mexa em `Workspace`/`ServerStorage` do place (não são do Rojo).

## Foco de revisão (o que os testes não pegam)

1. Jogador no menu (sem personagem) não pode ter barras caindo nem tomar dano.
2. Duas mortes no mesmo instante (barra zerou + queda): `DeathService.kill` já é idempotente; o `hurt` não pode chamar `kill` de um personagem que não é mais o atual.
3. Fogueira apagada/destruída no meio do tick (instância sem `Parent`) não pode quebrar o laço.
4. Comer com o inventário mudando ao mesmo tempo: só come se `InventoryService.take` devolver true.
5. Valores estranhos nos atributos (nil, NaN): tratar como cheio (100) e nunca gravar NaN.

---

### Tarefa 1: Números, comida e armadura nos dados

**Arquivos:**
- Criar: `src/shared/SurvivalConfig.luau`
- Modificar: `src/shared/Defs/Types.luau`, `src/shared/Defs/Validate.luau`, `src/shared/Defs/Items.luau`, `src/shared/Defs/init.luau` (exportar os tipos novos)
- Testar: `tests/defs.spec.luau`

**Interfaces produzidas:**
```lua
-- Types.luau
export type FoodEffect = { hunger: number?, thirst: number?, health: number? }
export type ArmorStats = { defense: number?, coldFactor: number?, hungerFactor: number?, thirstFactor: number? }
-- ItemDef ganha:
food: FoodEffect?,   -- só category "food" (obrigatório nela)
armor: ArmorStats?,  -- só category "armor" (obrigatório nela)
```

`SurvivalConfig.luau` (tabela congelada, com um comentário por linha dizendo a unidade). Valores exatos:

```lua
TICK = 0.5,                  -- segundos entre atualizações das barras
HUNGER_DRAIN = 0.6,          -- por segundo
THIRST_DRAIN = 0.5,
COLD_DRAIN_DAY = 0.4,
COLD_DRAIN_NIGHT = 1.6,
WATER_COLD_FACTOR = 2,       -- na água o frio cai 2× mais rápido
WATER_THIRST_REFILL = 5,     -- na água a sede SOBE isso por segundo
FIRE_WARMTH = 5,             -- perto do fogo o frio SOBE isso por segundo
CAMPFIRE_RADIUS = 12,        -- studs (vai no atributo HeatRadius da fogueira)
REGEN_MIN = 35,              -- fome, frio e sede >= isso para regenerar
REGEN_RATE = 0.5,            -- vida por segundo
HUNGER_EMPTY_DAMAGE = 1.5,   -- vida por segundo com a barra zerada
COLD_EMPTY_DAMAGE = 1,
THIRST_EMPTY_DAMAGE = 1,
OXYGEN_EMPTY_DAMAGE = 1,
HURT_FLASH_EVERY = 2,        -- segundos mínimos entre caretas do dano de sobrevivência
EAT_INTERVAL = 0.5,          -- segurando o botão, come uma a cada isso
MAX_DEFENSE = 0.9,           -- teto do armor.defense
MAX_FACTOR = 2,              -- teto dos fatores da armadura
BIOME_COLD_FACTOR = { forest = 1 }, -- reservado para o inverno (N2)
```

- [ ] **Passo 1: testes que falham** em `tests/defs.spec.luau` (use os helpers que já existem: `validItem`, `alwaysHas`, `containsError`):
  - `["berry restores hunger"]`: `Defs.Items.berry.food.hunger == 10`.
  - `["food item without food effect is an error"]`: item `category = "food"` sem `food` → erro contendo `"food"`.
  - `["food effect only on food"]`: item `resource` com `food = { hunger = 5 }` → erro `"food"`.
  - `["food effect out of range is an error"]`: `food = { hunger = 0 }` e outro com `food = { hunger = 150 }` → erro `"food"` (cada valor presente precisa estar em `(0, 100]`; e pelo menos um campo presente).
  - `["armor item without armor stats is an error"]`: `category = "armor"`, `maxStack = 1`, sem `armor` → erro `"armor"`.
  - `["armor stats only on armor"]`: item `resource` com `armor = { defense = 0.2 }` → erro `"armor"`.
  - `["armor stats out of range is an error"]`: `defense = 0.95` → erro `"defense"`; `coldFactor = 3` → erro `"coldFactor"`; `coldFactor = -1` → erro.
  - `["valid armor passes"]`: `{ category = "armor", maxStack = 1, armor = { defense = 0.25, coldFactor = 0.5 } }` → sem erros.
- [ ] **Passo 2:** `bash scripts/check.sh` → esses testes FALHAM.
- [ ] **Passo 3:** implementar: tipos em `Types.luau` (comentados como os vizinhos), exportar em `Defs/init.luau`, regras em `Validate.luau` logo depois da regra de `bagSlots` (mesmo estilo; faixas: `defense` em `[0, SurvivalConfig.MAX_DEFENSE]`, fatores em `[0, SurvivalConfig.MAX_FACTOR]`, use `isFiniteNumber`), `berry` ganha `food = { hunger = 10 }` (congele o bloco `food`/`armor` no laço de freeze de `Items.luau`, como as Expressions fazem com `flash`).
- [ ] **Passo 4:** `bash scripts/check.sh` → tudo passa.
- [ ] **Passo 5:** commit `feat: números da sobrevivência e comida/armadura nos dados`.

---

### Tarefa 2: Regras puras (sobrevivência e armadura)

**Arquivos:**
- Criar: `src/shared/Survival/ArmorRules.luau`, `src/shared/Survival/SurvivalRules.luau`
- Testar: `tests/armor.spec.luau`, `tests/survival.spec.luau`

**Interfaces produzidas:**
```lua
-- ArmorRules
export type Modifiers = { defense: number, coldFactor: number, hungerFactor: number, thirstFactor: number }
ArmorRules.NONE: Modifiers                      -- { defense = 0, coldFactor = 1, hungerFactor = 1, thirstFactor = 1 } (congelado)
ArmorRules.modifiers(def: Types.ItemDef?): Modifiers   -- nil ou sem armor → NONE; campos ausentes → neutros
ArmorRules.reduce(amount: number, mods: Modifiers): number -- amount * (1 - defense)

-- SurvivalRules
export type Bars = { health: number, hunger: number, cold: number, thirst: number }
export type Context = {
	isNight: boolean, inWater: boolean, nearFire: boolean,
	oxygen: number,             -- 0..100 (WaterService)
	mods: ArmorRules.Modifiers,
	biomeColdFactor: number,    -- 1 na floresta
}
export type Cause = "hunger" | "cold" | "thirst" | "oxygen"
export type StepResult = { bars: Bars, damage: number, cause: Cause? }
SurvivalRules.full(): Bars                                  -- tudo 100
SurvivalRules.step(bars: Bars, ctx: Context, dt: number): StepResult
SurvivalRules.eat(bars: Bars, food: Types.FoodEffect): Bars?   -- nil = nada a repor (tudo que a comida dá já está cheio)
SurvivalRules.CAUSE_KEYS: { [Cause]: string }   -- hunger → "death.cause.hunger", cold → "death.cause.cold", thirst → "death.cause.thirst", oxygen → "death.cause.drown"
```

Algoritmo do `step` (a ordem importa; `C = SurvivalConfig`, máximo = `StatNames.StatusMax` = 100):

```lua
-- 1. Barras (clamp 0..100 no fim de cada uma)
hunger -= C.HUNGER_DRAIN * mods.hungerFactor * dt
thirst = if inWater then thirst + C.WATER_THIRST_REFILL * dt else thirst - C.THIRST_DRAIN * mods.thirstFactor * dt
if nearFire then
	cold += C.FIRE_WARMTH * dt
else
	local drain = (if isNight then C.COLD_DRAIN_NIGHT else C.COLD_DRAIN_DAY) * biomeColdFactor * mods.coldFactor
	if inWater then drain *= C.WATER_COLD_FACTOR end
	cold -= drain * dt
end
-- 2. Dano das barras vazias (depois do passo 1), cada um * dt, somados
-- hunger <= 0 → HUNGER_EMPTY_DAMAGE; cold <= 0 → COLD_EMPTY_DAMAGE;
-- thirst <= 0 → THIRST_EMPTY_DAMAGE; oxygen <= 0 → OXYGEN_EMPTY_DAMAGE
-- cause = a parcela maior; empate na ordem hunger, cold, thirst, oxygen
-- 3. Regeneração: só se damage == 0 e hunger, cold, thirst >= C.REGEN_MIN
health = min(health + C.REGEN_RATE * dt, 100)
-- O dano NÃO é tirado de bars.health aqui: quem tira é o CharacterService.hurt.
```

Entrada com `nil`/NaN em qualquer barra conta como 100 (normalize no começo do `step`). `dt` negativo ou NaN = 0.

`eat`: soma cada campo presente da comida na barra correspondente (clamp 100). Se nenhum campo presente aumentou alguma barra → `nil`.

- [ ] **Passo 1: testes que falham.** `tests/armor.spec.luau`:
  - `["no armor is neutral"]`: `modifiers(nil)` igual a NONE; `reduce(10, NONE) == 10`.
  - `["armor fills missing fields"]`: def com `armor = { defense = 0.25 }` → `defense 0.25`, fatores 1; `reduce(20, m) == 15`.
  
  `tests/survival.spec.luau` (use `math.abs(a - b) < 1e-6` para comparar; contexto base = dia, seco, sem fogo, fôlego 100, `ArmorRules.NONE`, fator 1):
  - `["config keeps the approved numbers"]`: assert de cada valor da tabela da Tarefa 1 (fixa o que o Elizeu aprovou).
  - `["day drains hunger thirst and cold"]`: de `full()`, `dt = 10` → fome 94, sede 95, frio 96, vida 100, dano 0.
  - `["night cold drains four times faster"]`: noite, `dt = 10` → frio 84.
  - `["water refills thirst and doubles cold"]`: sede 50, na água, dia, `dt = 2` → sede 60, frio 100 − 1,6 = 98,4.
  - `["fire warms even at night in water"]`: frio 50, noite, água, fogo, `dt = 2` → frio 60.
  - `["armor factors slow the drain"]`: `coldFactor = 0.5`, `hungerFactor = 0.5`, dia, `dt = 10` → frio 98, fome 97.
  - `["empty hunger hurts and names the cause"]`: fome 0, `dt = 2` → dano 3, causa `"hunger"`, vida continua 100 (não tira).
  - `["empty bars add up"]`: fome 0, frio 0, sede 0, fôlego 0, `dt = 1` → dano 4,5, causa `"hunger"`.
  - `["cold wins the cause tie order after hunger"]`: frio 0 e sede 0 (fome cheia), `dt = 1` → dano 2, causa `"cold"`.
  - `["no oxygen hurts"]`: fôlego 0, `dt = 1` → dano 1, causa `"oxygen"`.
  - `["regen needs all bars at 35"]`: vida 50, fome 60, frio 60, sede 60, `dt = 10` → vida 55 (a conferência dos 35 é feita depois da queda do passo: 54/56/55). Com fome 38 (cai para 32) e o resto 60 → vida 50.
  - `["no regen while taking damage"]`: vida 50, fôlego 0 → vida 50, dano > 0.
  - `["bars never leave 0..100"]`: fome 1, `dt = 100` → fome 0; vida 99,9 com regen e `dt = 100` → 100.
  - `["nil or NaN bars count as full"]`: `{ health = 0/0, hunger = nil :: any, ... }` → barras finitas, sem NaN.
  - `["eating adds and caps"]`: fome 95 + `{ hunger = 10 }` → 100; fome 100 → `nil`; `{ hunger = 10, thirst = 5 }` com fome 100 e sede 50 → sede 55.
  - `["cause keys exist in strings"]`: para cada valor de `CAUSE_KEYS`, a chave existe em `src/shared/Strings` (use o `has` do módulo Strings, como em `strings.spec.luau`). **Este teste só passa depois do Passo 3 da Tarefa 3** — pode deixá-lo para lá se preferir.
- [ ] **Passo 2:** `bash scripts/check.sh` → FALHAM.
- [ ] **Passo 3:** implementar os dois módulos (`--!strict`, sem nenhum serviço do Roblox, como `src/shared/DayCycle.luau`).
- [ ] **Passo 4:** check passa.
- [ ] **Passo 5:** commit `feat: regras puras de sobrevivência e armadura`.

---

### Tarefa 3: Dano único, morte com causa, armadura vestida e fogo como fonte de calor

**Arquivos:**
- Modificar: `src/shared/StatNames.luau`, `src/shared/Models/CampfireModel.luau`, `src/server/Services/CharacterService.luau`, `src/server/Services/DeathService.luau`, `src/server/Services/DevBonecoService.luau` (2 chamadas de `hurt`), `src/shared/Strings/ptBR.luau`
- Criar: `src/server/Services/ArmorService.luau`

**Interfaces:**
```lua
-- StatNames (com comentário como os vizinhos)
Armor = "Armor",               -- atributo no Player: id do item de armadura vestido (ArmorService), ou nil
HeatSourceTag = "HeatSource",  -- tag (CollectionService) de modelos que esquentam (fogueira)
HeatRadius = "HeatRadius",     -- atributo no modelo da fonte de calor: raio em studs

-- ArmorService
ArmorService.wear(player: Player, itemId: string?): boolean
	-- itemId precisa ser category "armor" (senão false). nil tira. Grava o atributo Armor.
	-- Como InventoryService.equipBag: NÃO tira nem devolve itens do inventário.
ArmorService.modifiers(player: Player): ArmorRules.Modifiers  -- lê o atributo; id sumido das Defs → NONE

-- CharacterService (substitui a assinatura antiga)
export type HurtKind = "combat" | "survival"
CharacterService.hurt(character: Model, amount: number, causeKey: string, kind: HurtKind)
```

Regras do novo `hurt`:
1. `not (amount > 0)` ou sem Humanoid → nada (mantém a proteção contra NaN).
2. Jogador (`Players:GetPlayerFromCharacter`) e `kind == "combat"` → `amount = ArmorRules.reduce(amount, ArmorService.modifiers(player))`.
3. `HurtAt`: em `"combat"` sempre; em `"survival"` só se o `HurtAt` atual for nil ou mais velho que `SurvivalConfig.HURT_FLASH_EVERY`.
4. Tira de `Health` (como hoje). Se o jogador chegou a 0 **e** `player.Character == character` → `DeathService.kill(player, causeKey)`.
5. Bonecos de teste (sem jogador) continuam só com a careta.

- `DeathService.kill`: depois do `InventoryService.reset(player)`, chamar `ArmorService.wear(player, nil)` (a morte perde tudo). Atualize o comentário do topo.
- `DevBonecoService`: as chamadas passam `"death.cause.dev", "combat"`.
- `CampfireModel.build()`: o modelo ganha a tag `StatNames.HeatSourceTag` e o atributo `StatNames.HeatRadius = SurvivalConfig.CAMPFIRE_RADIUS`. Atualize o comentário do topo.
- `ptBR.luau`, junto das outras causas: `death.cause.hunger = "Fome"`, `death.cause.cold = "Frio"`, `death.cause.thirst = "Sede"`, `death.cause.drown = "Afogado"`.

- [ ] **Passo 1:** implementar tudo acima (são ligações do Roblox, sem teste no Lune; o teste da Tarefa 2 sobre as chaves de causa passa a valer agora).
- [ ] **Passo 2:** `bash scripts/check.sh` passa (sem avisos do selene).
- [ ] **Passo 3:** commit `feat: dano único com causa e armadura, fogueira como fonte de calor`.

---

### Tarefa 4: SurvivalService (as barras de verdade)

**Arquivos:**
- Criar: `src/server/Services/SurvivalService.luau`
- Modificar: `src/server/Services/DevStatsService.luau`, `src/server/Services/WaterService.luau` (só o comentário do topo)

**Interfaces:**
```lua
SurvivalService.applyFood(player: Player, food: Types.FoodEffect): boolean
	-- lê as barras do jogador, SurvivalRules.eat; nil → false; senão grava e devolve true
```

Comportamento:
- `Start`: para cada jogador, ao nascer (`CharacterAdded`, e o personagem que já existir) grava `SurvivalRules.full()` nos atributos `Health`, `Hunger`, `Cold`, `Thirst`.
- Um laço único (`task.spawn` + `task.wait(SurvivalConfig.TICK)`, medindo `dt` com `os.clock()` como o `WaterService`). Para cada jogador **vivo** (tem `player.Character` com Humanoid e `HumanoidRootPart`):
  - contexto: `isNight` = `DayCycle.at(Workspace:GetServerTimeNow() - CycleStart).isNight` (CycleStart ausente → dia); `inWater` = atributo `InWater == true`; `oxygen` = atributo `Oxygen` (ausente → 100); `nearFire` = alguma instância com a tag `HeatSource`, com `Parent`, cuja posição (`GetPivot()` se Model, `Position` se BasePart) está a até `HeatRadius` no plano XZ da raiz; `mods` = `ArmorService.modifiers(player)`; `biomeColdFactor = SurvivalConfig.BIOME_COLD_FACTOR.forest` (comentário: o inverno vai escolher pelo bioma da posição).
  - `SurvivalRules.step` → grava as barras arredondadas a 1 casa, só se mudaram (copie o `setIfChanged`/`round1` do `WaterService`).
  - `damage > 0` → `CharacterService.hurt(character, damage, SurvivalRules.CAUSE_KEYS[cause], "survival")`.
  - Cada jogador dentro de `pcall`/`task.spawn` isolado não é necessário, mas um erro de um jogador não pode parar o laço: use `pcall` por jogador e `warn` com o nome.
- `DevStatsService`: tira tudo das barras (INITIAL de Health/Hunger/Cold/Thirst, DRAINING, STATUS, a sede na água, o laço). Fica só pondo `Score` e `Rank` falsos ao entrar. Atualize o comentário do topo ("as barras são do SurvivalService desde a G1").
- `WaterService`: comentário do topo diz que o dano do fôlego e a sede na água são do `SurvivalService`.

- [ ] **Passo 1:** implementar.
- [ ] **Passo 2:** check passa.
- [ ] **Passo 3:** commit `feat: SurvivalService com fome, frio, sede e vida de verdade`.
- [ ] **PARADA A:** avise. O Claude testa no Studio: barras caindo, noite, água, fogueira (`DevCampfire`), morte por fome com a causa certa.

---

### Tarefa 5: Comer

**Arquivos:**
- Criar: `src/server/Services/FoodService.luau`

Comportamento:
- Para cada personagem de jogador, escuta `character:GetAttributeChangedSignal(StatNames.Using)`: ficou `true` → `tryEat(player)`.
- Laço único a cada 0,1 s: para quem está com `Using == true`, `tryEat(player)` (é o "segurar continua comendo").
- `tryEat(player)`:
  1. Sem personagem vivo → nada. Último "comer" deste jogador há menos de `SurvivalConfig.EAT_INTERVAL` → nada.
  2. `itemId = character:GetAttribute(StatNames.Equipped)`; `def = Defs.Items[itemId]`; sem `def.food` → nada.
  3. Se `SurvivalRules.eat(barras atuais, def.food)` daria `nil` → nada (não desperdiça). Para isso, peça ao `SurvivalService` sem gravar: adicione `SurvivalService.canEat(player, food): boolean` ou faça o `applyFood` só gravar depois do `take` (escolha uma; a ordem certa é: conferir que repõe algo → `InventoryService.take(player, itemId, 1)` → se true, `applyFood`).
  4. Guarda o instante do último comer (tabela por jogador, limpa em `PlayerRemoving`).
- Comentário no topo: a fase de combate/coleta deve ignorar o golpe quando o item na mão é comida.

- [ ] **Passo 1:** implementar.
- [ ] **Passo 2:** check passa.
- [ ] **Passo 3:** commit `feat: comer comida da mão (frutinha repõe fome)`.

---

### Tarefa 6: Comandos de teste e documentação

**Arquivos:**
- Modificar: `src/server/Services/DevDataService.luau`, `docs/guia/hud.md`, `docs/guia/arquitetura.md`, `docs/guia/adicionar-item.md`
- Criar: `docs/guia/sobrevivencia.md`

- `DevDataService` (lista no comentário do topo, como os outros):
  - `DevBar:Invoke(player, "Hunger", 0)`: grava um dos atributos `Health`/`Hunger`/`Cold`/`Thirst` (recusa outro nome; valor com clamp 0..100).
  - `DevArmor:Invoke(player, itemId?) -> boolean`: `ArmorService.wear`.
- `docs/guia/sobrevivencia.md` (pt-BR, para o Elizeu, no estilo de `docs/guia/mapa.md`): a tabela dos números e onde mudar (`SurvivalConfig.luau`); como a fogueira esquenta (tag + `HeatRadius`); como criar uma comida (`food`) e uma armadura (`armor`, o que cada campo faz, exemplos: capacete com `defense = 0.2`, casaco com `coldFactor = 0.5`); o que ainda não existe (vestir pela tela, armadura no boneco); comandos de teste (`DevBar`, `DevArmor`, `DevCampfire`, anoitecer com `CycleStart`).
- `hud.md`: trocar o parágrafo do `DevStatsService` (agora só pontos/ranking falsos; barras = `SurvivalService`).
- `arquitetura.md`: uma linha dizendo que `CharacterService.hurt` é a função única de dano (com causa e tipo) e que o `SurvivalService` é dono das 4 barras.
- `adicionar-item.md`: mencionar os blocos `food` e `armor`.

- [ ] **Passo 1:** implementar.
- [ ] **Passo 2:** check passa; `graphify update .`.
- [ ] **Passo 3:** commit `docs: guia da sobrevivência e comandos de teste`.
- [ ] **PARADA FINAL:** avise. O Claude valida no Studio e faz a revisão final.

---

### Tarefa 7 (adendo): calor por cima do frio

**Spec:** seção "Adendo (29/10)" do design.

**Interfaces:**
- `SurvivalConfig`: `BURN_RADIUS = 3`, `ON_FIRE_HEAT = 20`, `HEAT_COOL = 5`, `HEAT_FULL_DAMAGE = 1.2`, `REGEN_MAX_HEAT = 65`, `BIOME_HEAT = { forest = 0 }`.
- `SurvivalRules.Bars` ganha `heat: number` (nil/NaN = 0; `full()` tem `heat = 0`); `Context` ganha `onFire: boolean` e `biomeHeat: number`; `Cause` ganha `"heat"` (`CAUSE_KEYS.heat = "death.cause.heat"`); ordem de desempate: hunger, cold, heat, thirst, oxygen.
- Regra: `heating = (onFire and ON_FIRE_HEAT or 0) + biomeHeat`. Com `heating > 0`: o frio sobe até 100 e o que sobra (×`mods.heatFactor`) enche o calor; o frio não cai. Sem: calor > 0 esfria `HEAT_COOL`/s e o frio fica parado; calor 0 → frio como antes. Calor ≥ 100 → `HEAT_FULL_DAMAGE`/s. Regen exige calor < `REGEN_MAX_HEAT`.
- `ArmorStats`/`Modifiers` ganham `heatFactor` (0 a `MAX_FACTOR`, padrão 1).
- `StatNames.Heat = "Heat"`, `StatNames.BurnRadius = "BurnRadius"` (atributo na fonte de calor; a fogueira sai com `BURN_RADIUS`).
- `UIMath.temperatureRing(cold, heat) -> (value: number, hot: boolean)`: com calor > 0 mostra o calor (`hot = true`), senão o frio.
- HUD: o anel do frio usa `temperatureRing`; em modo quente, cor `Theme.status.heat`, pulso com calor ≥ 65 e pisca com calor cheio.

Testes: survival.spec (fogo enche frio e transborda no calor; calor esfria e o frio fica; calor cheio tira 1,2/s com causa "heat"; sem regen com calor ≥ 65; heatFactor; calor do bioma; calor nil = 0; números aprovados), armor.spec (heatFactor), defs.spec (heatFactor fora da faixa), uimath.spec (temperatureRing).
