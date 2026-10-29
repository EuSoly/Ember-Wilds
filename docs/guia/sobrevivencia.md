# Sobrevivência

As quatro barras do HUD (vida, fome, frio e sede) são calculadas no servidor pelo `SurvivalService` e vão de **0 a 100**. Ele atualiza duas vezes por segundo, então os anéis descem de forma contínua. Cada vida nova começa com tudo cheio.

## Os números

Todos ficam em `src/shared/SurvivalConfig.luau`. Mudou um número, o jogo muda na próxima vez que der Play. (O teste `config keeps the approved numbers` em `tests/survival.spec.luau` guarda os valores aprovados: ao mudar de propósito, atualize o teste também.)

| O quê | Valor | Na prática |
|---|---|---|
| Fome cai | 0,6 por segundo | cheia → vazia em ~2 min 47 s |
| Sede cai | 0,5 por segundo | ~3 min 20 s |
| Frio cai de dia | 0,4 por segundo | ~4 min (um dia inteiro) |
| Frio cai de noite | 1,6 por segundo | ~1 min sem fogo |
| Na água | frio cai 2× mais rápido; sede **sobe** 5 por segundo | enche a sede em ~20 s |
| Perto do fogo | frio **sobe** 5 por segundo (mesmo de noite ou na água) | enche em ~20 s |
| Vida regenera | 0,5 por segundo | só com fome, frio e sede **≥ 35** e sem tomar dano |
| Fome vazia | −1,5 de vida por segundo | |
| Frio, sede ou fôlego vazios | −1 de vida por segundo cada (somam) | tudo vazio = morte em ~30 s |
| Frutinha | +10 de fome | |

Vida zerada é morte (a mesma do resto do jogo: perde tudo, pontos viram Golden Ember). A tela de morte mostra a causa: **Fome**, **Frio**, **Sede** ou **Afogado** (a barra que mais tirou vida no fim).

## Fogo

Qualquer modelo com a tag **`HeatSource`** e o atributo **`HeatRadius`** (em studs) esquenta quem está dentro do raio (medido vista de cima). A fogueira (`src/shared/Models/CampfireModel.luau`) já sai assim, com raio 12. Quando a fogueira construível existir, ela só precisa usar esse modelo.

## Comida

Com uma comida na mão (slot selecionado), **clique** (ou segure o joystick direito no celular) para comer uma. Segurando, continua comendo a cada meio segundo. Se tudo o que a comida repõe já estiver cheio, ela **não é gasta**.

Comida nova: um item com `category = "food"` e o bloco `food = { hunger = ?, thirst = ?, health = ? }` (pelo menos um) em `src/shared/Defs/Items.luau`. Veja `adicionar-item.md`.

## Armaduras (preparadas)

Já existe a base; **ainda não existe nenhum item de armadura**, nem tela para vestir, nem a armadura aparecendo no boneco.

- Uma armadura vestida por vez (como o item de cabeça do Starve), guardada no atributo `Armor` do jogador.
- Um item de armadura tem `category = "armor"` e o bloco `armor`:
  - `defense`: quanto do **dano de combate** ela corta (0,2 = 20%; máximo 0,9). Fome, frio e sede vazios **não** são cortados.
  - `coldFactor`, `hungerFactor`, `thirstFactor`: quanto mais devagar a barra cai (0,5 = metade da velocidade; de 0 a 2).
- Exemplos: capacete de madeira `armor = { defense = 0.2 }`; casaco `armor = { coldFactor = 0.5 }`.
- A morte tira a armadura (como a mochila).
- Quem veste é o `ArmorService.wear(player, itemId)` no servidor. Ele não tira o item do inventário: a tela de equipamento, quando existir, cuida disso.

## Testar no Studio

Na barra de comandos, lado servidor (com o jogo rodando e o boneco vivo):

```lua
local p = game.Players:GetPlayers()[1]
game.ServerStorage.DevBar:Invoke(p, "Hunger", 0)      -- zera a fome (morre em ~67 s)
game.ServerStorage.DevBar:Invoke(p, "Cold", 20)       -- quase congelando
game.ServerStorage.DevCampfire:Invoke(p)              -- fogueira 6 studs à frente (esquenta)
workspace:SetAttribute("CycleStart", workspace:GetServerTimeNow() - 238) -- anoitece em 2 s
game.ServerStorage.DevArmor:Invoke(p, "algum_item_armor") -- quando existir uma armadura
```

## Onde fica no código

| Arquivo | O que faz |
|---|---|
| `src/shared/SurvivalConfig.luau` | todos os números |
| `src/shared/Survival/SurvivalRules.luau` | as regras das barras (puras, testadas em `tests/survival.spec.luau`) |
| `src/shared/Survival/ArmorRules.luau` | efeitos da armadura (testadas em `tests/armor.spec.luau`) |
| `src/server/Services/SurvivalService.luau` | aplica as regras a cada jogador e grava as barras |
| `src/server/Services/FoodService.luau` | comer |
| `src/server/Services/ArmorService.luau` | vestir/tirar armadura |
| `src/server/Services/CharacterService.luau` | `hurt`: o dano único (combate e sobrevivência) |
