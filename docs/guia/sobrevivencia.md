# Sobrevivência

As quatro barras do HUD (vida, fome, temperatura e sede) são calculadas no servidor pelo `SurvivalService` e vão de **0 a 100** (a vida, desde a G6, vai de **0 a 200**; veja `combate.md`). Ele atualiza duas vezes por segundo, então os anéis descem de forma contínua. Cada vida nova começa com tudo cheio.

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
| Vida regenera | 0,5 por segundo (com 200 de vida, enche na metade da velocidade em proporção) | só com fome, frio e sede **≥ 35** e sem tomar dano |
| Fome vazia | −1,5 de vida por segundo | |
| Frio, sede ou fôlego vazios | −1 de vida por segundo cada (somam) | tudo vazio = morte em ~30 s |
| Em cima do fogo (até 3 studs do centro) | esquenta 20 por segundo: enche o frio e, cheio, enche o **calor** | calor cheio em ~5 s |
| Fora do fogo, com calor | o calor esfria 5 por segundo; o frio só volta a cair depois | |
| Calor cheio | −1,2 de vida por segundo | a vida só regenera com o calor abaixo de 65 |
| Frutinha | +10 de fome | |

Vida zerada é morte (a mesma do resto do jogo: pontos viram Golden Ember, e o inventário, a mochila e a armadura vão para uma **caixa** no lugar da morte, que qualquer um pode saquear; veja `combate.md`). A vida tem teto próprio (`StatNames.HealthMax` = 200); as outras barras continuam em `StatNames.StatusMax` = 100, e a comida e a regeneração curam os mesmos pontos de antes. A tela de morte mostra a causa: **Fome**, **Frio**, **Calor**, **Sede** ou **Afogado** (a barra que mais tirou vida no fim).

## Temperatura: frio + calor por cima

A barra de temperatura tem duas partes, uma por cima da outra:

- **Frio** (anel azul): 100 = quentinho, 0 = congelando. Cai com o tempo (mais de noite e na água); perto da fogueira enche.
- **Calor** (o mesmo anel fica **laranja**): só começa a encher quando o frio já está cheio e você **continua esquentando**: em cima do fogo hoje; no deserto de dia e na lava no futuro (`BIOME_HEAT` em `SurvivalConfig`, hoje 0 na floresta). Ficar perto da fogueira só enche o frio, nunca passa do topo.
- Saindo do calor, ele esfria primeiro; o anel volta a ficar azul quando o calor zera.
- Com o calor alto (≥ 65) o anel pulsa; cheio, pisca e tira vida.

## Fogo

Qualquer modelo com a tag **`HeatSource`** e o atributo **`HeatRadius`** (em studs) esquenta quem está dentro do raio (medido vista de cima). Com o atributo **`BurnRadius`**, quem está dentro desse raio menor está "em cima do fogo" e enche o calor. A fogueira (`src/shared/Models/CampfireModel.luau`) já sai assim: raio 12 e queima a 3. A fogueira construível (ver `construcao.md`) usa esse mesmo modelo (`CampfireModel`, via `StructureModel`), com o raio de calor vindo dos dados da peça: 12 na pequena e 18 na grande.

## Comida

Com uma comida na mão (slot selecionado), **clique** (ou segure o joystick direito no celular) para comer. A comida aparece na mão do boneco (o ícone em relevo de `Assets.Icons/<id>`).

Comer leva tempo (decisões do Elizeu, 09/11):
- Cada mordida dura **1,2 s** (`SurvivalConfig.EAT_DURATION`). A comida só sai do inventário e repõe as barras **no fim** da mordida.
- Segurando o botão, a próxima mordida emenda na hora. Uma mordida começada termina mesmo soltando o botão.
- Dá para andar comendo, a **70%** da velocidade (`EAT_SPEED_FACTOR`, aplicado no `WaterSim`).
- **Trocar de item** no meio (ou morrer) cancela sem gastar a comida. Levar dano **não** interrompe.
- Se tudo o que a comida repõe já estiver cheio, a mordida nem começa.
- O boneco leva a comida à boca, dá duas mordidas com farelos na cor da comida e fecha os olhos "^ ^". Números da animação em `BonecoConfig` (`EAT_*`, `FOOD_HAND_*`).

Por dentro: o `FoodService` grava no personagem o atributo `EatUntil` (instante do servidor em que a mordida termina); o boneco anima por ele (`EatRules.progress` + `BonecoAnim.eatCurve`) e a simulação deixa mais lento enquanto vale.

Comida nova: um item com `category = "food"` e o bloco `food = { hunger = ?, thirst = ?, health = ? }` (pelo menos um) em `src/shared/Defs/Items.luau`; opcional `crumbColor = "#RRGGBB"` (cor dos farelos; sem ela, cor de pão). Para aparecer na mão, precisa do ícone em `Assets.Icons/<id>`. Veja `adicionar-item.md`.

## Armaduras (preparadas)

Já existe a base; **ainda não existe nenhum item de armadura**, nem tela para vestir, nem a armadura aparecendo no boneco.

- Uma armadura vestida por vez (como o item de cabeça do Starve), guardada no atributo `Armor` do jogador.
- Um item de armadura tem `category = "armor"` e o bloco `armor`:
  - `defense`: quanto do **dano de combate** ela corta (0,2 = 20%; máximo 0,9). Fome, frio e sede vazios **não** são cortados.
  - `coldFactor`, `hungerFactor`, `thirstFactor`: quanto mais devagar a barra cai (0,5 = metade da velocidade; de 0 a 2).
  - `heatFactor`: quanto mais devagar o calor sobe (para as proteções de calor do deserto/lava).
- Exemplos: capacete de madeira `armor = { defense = 0.2 }`; casaco `armor = { coldFactor = 0.5 }`.
- A morte tira a armadura (como a mochila): ela vai **para a caixa** do morto, como item, e outro jogador pode pegá-la.
- Quem veste é o `ArmorService.wear(player, itemId)` no servidor. Ele não tira o item do inventário: a tela de equipamento, quando existir, cuida disso.

## Testar no Studio

Na barra de comandos, lado servidor (com o jogo rodando e o boneco vivo):

```lua
local p = game.Players:GetPlayers()[1]
game.ServerStorage.DevBar:Invoke(p, "Hunger", 0)      -- zera a fome (morre em ~67 s)
game.ServerStorage.DevBar:Invoke(p, "Cold", 20)       -- quase congelando
game.ServerStorage.DevBar:Invoke(p, "Heat", 90)       -- quase queimando (anel laranja)
game.ServerStorage.DevGive:Invoke(p, "campfire", 1)    -- dá a fogueira; coloque no chão (esquenta)
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
