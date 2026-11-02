# G6 Combate e caixas — Plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Objetivo:** jogadores brigam entre si, todo mundo que morre (jogador ou mob) vira uma caixa de itens que qualquer um abre e saqueia, a vida do jogador vai a 200 e os mobs mordem a cada 1,5 s.

**Arquitetura:** a vida ganha teto próprio; o golpe do `GatherService` passa a acertar jogadores e caixas; o dano carrega quem bateu até o `DeathService`, que paga o bônus de pontos e cria a caixa; um `CrateService` (no molde do baú da G4) é dono das caixas e do saque, com regras puras em `CrateRules`; o cliente mostra o painel da caixa mais perto.

**Stack:** Luau `--!strict`, Rojo, Blink, Vide, Lune. Verificar: `bash scripts/check.sh` (Git Bash).

**Spec:** `docs/superpowers/specs/2026-11-02-g6-combate-caixas-design.md`.

**Branch:** `g6-combate`, a partir da `main`.

**Modelo sugerido por tarefa:** marcado no título.

## Regras globais

- pt-BR em código, comentários, textos e commits; commit por tarefa; sem push; terminar commits com `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Conteúdo é dado (`Defs`); nada de `if id == "wolf"`. Atributos e tags por `StatNames`; rede por Blink, o servidor valida cada pedido.
- Server Authority: o servidor decide; o cliente pede e mostra. Atributos do personagem local previsto: ler por polling.
- Atributos replicados: strings ≤ 50 caracteres (conteúdo de caixa vai por evento Blink, não por atributo).
- A lança **nunca** empurra jogador; mobs sem barra de vida.
- Antes de ler código: `& (Get-Content graphify-out\.graphify_python) -m graphify query "<pergunta>"` (PowerShell) e ler só o que ele apontar.
- `.gitignore` tem `build/` (pega pastas `Build` no Windows): conferir `git status` em arquivo novo.

## Foco de revisão

1. Dois jogadores pegando o mesmo slot da caixa ao mesmo tempo, ou pegando enquanto ela é quebrada/some: ninguém ganha item duplicado nem item de caixa que já não existe.
2. Inventário cheio: pegar leva só o que cabe, e o resto fica na caixa.
3. Quem matou saiu do jogo ou morreu no mesmo instante: bônus só para jogador ainda no jogo; skin cai para a do morto.
4. Morto com mochila cheia e capacete: tudo vai para a caixa uma vez só (nada fica no inventário zerado e nada é copiado duas vezes).
5. O golpe nunca acerta quem bate; entre recurso, peça, mob, jogador e caixa, o mais perto à frente leva.

---

### Tarefa 1 (Sonnet): Vida 200 e mordida a 1,5 s

**Arquivos:** `src/shared/StatNames.luau`, `src/shared/Survival/SurvivalRules.luau`, `src/server/Services/CharacterService.luau`, `src/client/UI/StatusRings.luau`, `src/server/Services/DevDataService.luau`, `src/shared/Mobs/MobRules.luau`; testes `tests/survival.spec.luau` (e os que dependerem de vida 100).

**Produz:** `StatNames.HealthMax = 200` (as outras barras seguem `StatusMax = 100`); `MobRules.BITE_INTERVAL = 1.5`.

- A vida nasce em 200, a regeneração para em 200, o padrão do `CharacterService.hurt` é 200, o anel de vida do HUD usa 200 como cheio, o comando de dev limita a vida em 200.
- [ ] Testes que falham: vida inicial 200; regenerar não passa de 200; comer comida com `health` não passa de 200; fome/frio/sede continuam com teto 100.
- [ ] Implementar; check verde; commit `feat: vida do jogador 200 e mordida a 1,5 s`.

### Tarefa 2 (Sonnet): Dados — carne, peles, loot dos mobs, skin de caixa, regras da caixa

**Arquivos:** `src/shared/Defs/Items.luau`, `Recipes.luau`, `Mobs.luau`, `Types.luau`, `Validate.luau`, `CosmeticSlots.luau`, `Cosmetics.luau`, `src/shared/Strings/ptBR.luau`; criar `src/shared/Crate/CrateRules.luau`; testes `tests/defs.spec.luau`, criar `tests/craterules.spec.luau`.

**Produz:**
```lua
-- Itens: raw_meat (food, hunger 15), cooked_meat (food, hunger 35), rabbit_fur,
-- wolf_fur, boar_fur, hawk_feather, thread (resource) — todos maxStack 255.
-- Receita: cooked_meat = 1 raw_meat, 3 s, station "fire" (order logo após as existentes).
-- MobDef ganha loot: { { id: string, count: number } }? — só os 5 da floresta:
--   rabbit {raw_meat 1, rabbit_fur 1}; wolf {raw_meat 2, wolf_fur 1}; spider {thread 2};
--   boar {raw_meat 4, boar_fur 1}; hawk {raw_meat 2, hawk_feather 4}
-- CosmeticSlots: crate = { default = "crate_default" }; Cosmetics: crate_default (slot "crate").
CrateRules.PLAYER_LIFETIME = 180   CrateRules.MOB_LIFETIME = 60
CrateRules.HEALTH = 600            CrateRules.OPEN_RANGE = 8
CrateRules.RADIUS = 1.5            CrateRules.KILL_BONUS = 0.25
CrateRules.killBonus(score: number): number   -- floor(score * KILL_BONUS); 0 para inválido/negativo
CrateRules.skinFor(killerSkin: string?, ownSkin: string): string  -- killerSkin se houver, senão ownSkin
```
- Textos pt-BR: "Carne crua", "Carne assada", "Pele de coelho", "Pele de lobo", "Pele de javali", "Pena de falcão", "Linha", "Caixa padrão" (e o nome do slot "Caixa").
- [ ] Testes que falham: os 5 mobs têm o loot acima e os outros 18 não; `Validate` recusa loot com item inexistente ou contagem não inteira/≤ 0; receita da carne assada existe na fogueira; cosmético de caixa padrão existe; `killBonus(1000) == 250`, `killBonus(3) == 0`, `killBonus(-5) == 0`, `killBonus(0/0) == 0`; `skinFor(nil, "a") == "a"`, `skinFor("b", "a") == "b"`.
- [ ] Implementar; check verde; commit `feat: carne, peles, loot dos mobs e regras da caixa`.

### Tarefa 3 (Opus): Golpe em jogador, quem matou e bônus

**Arquivos:** `src/server/Services/CharacterService.luau`, `src/server/Services/DeathService.luau`, `src/server/Services/GatherService.luau`, `net/game.blink`, `src/client/Screens/DeathScreen.luau`, `src/shared/Strings/ptBR.luau` (se precisar de texto).

**Consome:** `CrateRules.killBonus` (Tarefa 2), `MobRules.damageOf`, `ScoreService.add`, `BuildRules.PLAYER_RADIUS`, `GatherRules.pickTarget`.

**Produz:**
```lua
CharacterService.hurt(character: Model, amount: number, causeKey: string, kind: HurtKind, attacker: Player?)
DeathService.kill(player: Player, causeKey: string, killer: Player?)
DeathService.onDeath(listener: (player: Player, character: Model, killer: Player?) -> ())  -- antes de zerar o inventário
-- LifeEnded ganha KillerName: string? (a tela mostra "Causa: <nome>")
```
- Golpe: o `GatherService` põe como candidatos os **outros** jogadores vivos (raio `PLAYER_RADIUS`); acertando jogador, `CharacterService.hurt(alvo, MobRules.damageOf(item), <causa de jogador>, "combat", quem bateu)`. Sem empurrão. Quem bate nunca é candidato.
- Quem matou = `attacker` do dano que zerou a vida (golpe final). O `DeathService.kill` com `killer` válido (no jogo, não é o próprio) soma `CrateRules.killBonus(Score do morto antes do fim de vida)` ao `Score` de quem matou e manda o nome dele na tela. Qualquer outra morte segue como hoje.
- `onDeath`: chamado com o inventário ainda intacto (a Tarefa 4 usa para criar a caixa).
- [ ] Check verde; commit `feat: golpe em jogador, quem matou e bônus de pontos`.

### Tarefa 4 (Opus): Servidor das caixas

**Arquivos:** criar `src/server/Services/CrateService.luau`, `src/shared/Models/CrateModel.luau`; `net/game.blink`; `src/server/Services/GatherService.luau`; `src/shared/StatNames.luau`.

**Consome:** `DeathService.onDeath` (T3), `MobService.onDeath` (G5), `CrateRules` e `Defs.Mobs[id].loot` (T2), `InventoryService.get/give/reset`, a mochila e a armadura vestidas (atributo/serviço da G3: descobrir no código), `CosmeticService.equipped(player, "crate")`, `src/shared/World/SpatialGrid.luau`, `BuildRules.damageOf`.

**Produz:**
```
-- Blink
event CrateWatch { From: Client, Type: Reliable, Call: SingleAsync, Data: Instance? }    -- caixa que o cliente está olhando (nil = nenhuma)
event CrateTake  { From: Client, Type: Reliable, Call: SingleAsync, Data: struct { Crate: Instance?, Slot: u8 } }
event CrateContents { From: Server, Type: Reliable, Call: SingleAsync, Data: struct { Crate: Instance, Slots: Slot[] } }
CrateService.spawn(x: number, z: number, slots: { { id: string, count: number } }, modelId: string, lifetime: number): Model?
CrateService.near(x: number, z: number, radius: number): { Entry }
CrateService.hit(entry: Entry, attacker: Player, item: ItemDef?)
```
- Caixa: modelo `CrateModel.build(modelId)` = clone de `ReplicatedStorage.Assets.Crates.<modelId>` se existir, senão uma caixa provisória simples feita de peças (cor por `modelId` do mob ou padrão); tag `StatNames.CrateTag`; atributos de vida no mesmo formato das construções para a barrinha da G4 aparecer; índice espacial.
- Morte do jogador (`onDeath`): todos os slots do inventário (inclui os da mochila), a mochila vestida e a armadura vestida viram slots da caixa, no lugar da morte; skin = `CrateRules.skinFor(skin de caixa de quem matou, a dele)`; vida `HEALTH`; some em `PLAYER_LIFETIME`. Sem item nenhum: não cria caixa.
- Morte do mob (`MobService.onDeath`): caixa com o `loot` do mob, modelo = id do mob, some em `MOB_LIFETIME`.
- Saque: `CrateTake` confere distância (`OPEN_RANGE`), caixa viva e slot existente; dá o que couber (`InventoryService.give` devolve a sobra) e deixa o resto; tudo sem pausa no meio; limite de pedidos como o baú. Vazia → some. Mudou → `CrateContents` para quem está olhando.
- Golpe: `GatherService` põe caixas como candidatas (raio `CrateRules.RADIUS`); vida 0 → some com os itens.
- Studio: `ServerStorage.DevCrate:Invoke(player)` cria uma caixa com alguns itens na frente do jogador.
- [ ] Check verde; commit `feat: caixas de itens no servidor`.
- [ ] PARADA (Studio, controlador): matar mob deixa caixa com o loot certo; morrer deixa caixa com inventário + mochila + capacete; abrir e pegar; inventário cheio leva só o que cabe; caixa some vazia e no tempo; quebrar a golpes some com os itens; bater em jogador tira vida (capacete reduz) e matar dá 1/4 dos pontos e mostra o nome.

### Tarefa 5 (Sonnet): Painel da caixa

**Arquivos:** criar `src/client/CrateState.luau`, `src/client/UI/CratePanel.luau`; montar no `src/client/UI/App.luau`; ligar o `CrateState` como os outros estados.

**Consome:** `CrateWatch`, `CrateTake`, `CrateContents` (T4), `CrateRules.OPEN_RANGE`, `StatNames.CrateTag`, `ItemIcon`/`SlotButton` existentes.

- `CrateState`: acha a caixa mais perto a até `OPEN_RANGE` (por quadro, como o `ChestState`), avisa o servidor quando muda (`CrateWatch`), guarda os slots recebidos.
- `CratePanel`: aparece sozinho com uma caixa perto, acima da hotbar (ao lado do painel do baú, sem sobrepor), com os slots da caixa em grade; clicar/tocar num slot manda `CrateTake`. Some longe da caixa.
- [ ] Check verde; commit `feat: painel da caixa`.
- [ ] PARADA (Studio, controlador): painel aparece/some, pegar funciona, dois slots iguais, inventário cheio.

### Tarefa 6 (Sonnet): Documentação

- Criar `docs/guia/combate.md` (vida 200, golpe em jogador, quem matou, bônus, caixas: conteúdo, skin, saque, quebra, tempos, comandos Dev, onde mudar os números, como pôr o loot de um mob novo); atualizar `mobs.md` (mordida 1,5 s, loot), `sobrevivencia.md` (vida 200), `hud.md` (painel da caixa), `adicionar-item.md` (itens novos e loot), `boneco.md` ou o guia de cosméticos (slot `crate`).
- [ ] check verde; `& (Get-Content graphify-out\.graphify_python) -m graphify update .`; commit `docs: combate e caixas`.
