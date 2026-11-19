# Armaduras (itens de cabeça)

São as 32 peças de cabeça do Starve: capacetes, roupas de frio, proteções de calor, chapéus especiais, mergulho, eventos e coroas. O jogador veste **uma por vez** e ela aparece no boneco. As receitas e os status são os do Starve.io, tirados da configuração oficial do servidor. Os números brutos e as fontes estão em `docs/game-design/armaduras-starve.md`; o design, em `docs/superpowers/specs/2026-11-10-armaduras-design.md`.

## Como o jogador usa

- Segura a peça na mão e usa (clique ou toque): veste. Se já tinha uma, ela volta para o inventário. Precisa caber.
- Depois de vestir, só dá para trocar de novo depois de **5 s** (`SurvivalConfig.ARMOR_SWAP_LOCK`, igual ao `helmet_delay` do Starve).
- Ao morrer, a peça vai para a caixa do morto, como item.
- **Craft com a peça vestida:** a peça da cabeça conta como ingrediente (o capacete de pedra pede o de madeira etc.). Se o inventário já tiver outra igual, usa a do inventário; senão, a da cabeça sai no início do craft (cancelar devolve ao inventário). A peça nova vai para o inventário, como todo craft (`CraftRules.withWorn`/`split`).
- A peça fica **por cima da skin**, no centro do corpo, sem esconder nada. Numa skin gorda ela entra um pouco no corpo; numa magra aparece inteira.

## O que cada número faz

Os números ficam no bloco `armor` do item (`src/shared/Defs/Items.luau`), **em unidades do Starve**. Quem converte para o nosso jogo é `src/shared/Survival/ArmorRules.luau`.

| Campo | O que faz no jogo |
|---|---|
| `defense` | Tirado do golpe de **jogador** (inclui espinhos). `golpe − defesa`, nunca abaixo de 0. |
| `mobDefense` | Tirado da mordida de **mob**. |
| `warm = { day, night, waterDay, waterNight, ... }` | Quanto a peça soma no frio por tick do Starve. A nossa perda de frio é multiplicada por `(base − warm) / base`, com a base do Starve no lugar (floresta dia 2 / noite 18; água 5 / 25; inverno 25 / 50). Ex.: o casaco de dia na floresta não perde frio; o chapéu de pele esquenta. `winter*` e `lava*` ficam guardados para quando esses biomas existirem. |
| `fireHeatFactor` | Multiplica o calor que o fogo põe na barra de calor. As proteções têm 0 (anulam). |
| `oxygenLoss` | Tirado da perda de fôlego do Starve (25): o fôlego cai `× (25 − oxygenLoss) / 25`. Máscara 14 → 0,44; roupa 19 → 0,24. |
| `swimSpeed` | Multiplica a velocidade nadando (mergulho 1,2). |
| `regenHeal` | Cura por ciclo do Starve (base 12). A regeneração vai `× regenHeal / 12` (Coroa da Vida: 40). |
| `hidesName` | O nick (e o selo do tutorial) some para os **outros** jogadores. Quem veste continua vendo o seu. |
| `explorer` | Mobs que caçam não escolhem o jogador como alvo e largam a perseguição. Qualquer golpe dele (em mob, jogador, recurso, construção ou caixa) desliga o efeito por **10 s** (`EXPLORER_OFF`). |
| `hungerFactor`, `thirstFactor` | Multiplicam a queda da fome e da sede. Nenhuma peça do Starve usa. |

**Fazenda (12/11):** `cropGrowth` das túnicas funciona: a planta regada por quem veste a túnica cresce 1,2x (camponês) ou 1,4x (inverno) enquanto durar essa rega (`fazenda.md`).

**Só dado (nada lê ainda):** `blizzard` (nevasca), `sand` (tempestade de areia), `stealImmune` (roubo), `tameLuck` e `digLuck` (Coroa da Sorte), `resurrect` (Coroa do Anjo), `crabFriend` (capacete de caranguejo), `spiderImmune` (capacete de lava), `pilotAcceleration` (avião). Quando o sistema chegar, ele lê esses campos.

`gearSet` (dragão, lava) já funciona: a espada ou a lança do mesmo conjunto bate mais forte com o capacete vestido (veja `ferramentas.md`).

> As mordidas dos nossos mobs são mais fracas que no Starve (lobo 24 contra 40), mas a defesa contra mob entrou sem escala (decisão do Elizeu). Por isso o capacete protege proporcionalmente mais aqui. Está em `docs/pendencias.md`.

## Liberadas e só para teste

**Liberadas:** capacetes de madeira, pedra e ouro, protetor de orelha, casaco, turbante, chapéu de explorador, capuz e túnica de camponês. Os materiais e os sistemas delas já existem.

**Só para teste (`testOnly = true`):** as outras 23 peças e todos os materiais novos:
- minérios: diamante e ametista;
- drops de mobs que ainda não existem: peles de inverno e de mamute, penas de pinguim e de abutre, pele de kraken, escama de piranha, chama, corações de dragão e de lava, garra e palito de caranguejo;
- linha azul;
- itens de quest, ainda sem modelo: gemas verde, azul e laranja, cubos azul e de lava, óculos de piloto, peles de lobo negro e branco, vaga-lume.

`testOnly` quer dizer que o item só existe no Studio (`ItemAccess`). **Para liberar uma peça**, apague a linha `testOnly = true` dela em `Items.luau`. Faça o mesmo nos materiais da receita, ou o teste `released recipes only use released items` acusa.

Os gorros de Natal e de elfo não têm receita, porque no Starve saem do presente de Natal. Por enquanto, só com `DevGive`.

## Receitas e estações

As receitas estão em `src/shared/Defs/Recipes.luau`, com os números da config oficial. Algumas pedem mais de uma estação ao mesmo tempo (campo `alsoNear`):
- **Bancada + fogo:** capacete de reidite e as proteções.
- **Bancada + fogo + água:** as três coroas e os capacetes de dragão e de lava.

"Perto da água" quer dizer a até `CraftRules.STATION_RADIUS` (10 studs) da borda de uma peça de `Workspace.Map.Water` (`WaterSim.isNearWater`). O livro e a coluna de craft mostram todas as estações.

## Adicionar uma peça nova

1. **Modelo:** em `ReplicatedStorage.Assets.Armor/<id>` (salvo no place, fora do Rojo). O `WorldPivot` vai no centro do corpo do boneco e virado para a frente dele (−Z). Os FBX do Blender chegam com a frente em +Z: gire 180° no pivô, como explica `assets/armor/roblox/IMPORTAR-ROBLOX.md`. Peças sem colisão nem sombra.
2. **Item:** em `Items.luau`, com `category = "armor"`, `maxStack = 1` e o bloco `armor` com os números do Starve.
3. **Receita:** em `Recipes.luau`.
4. **Nome:** `item.<id>` em `Strings/ptBR.luau`.
5. **Teste:** acrescente o id à lista `PIECES` em `tests/armorpieces.spec.luau`.

O ícone sai do próprio modelo, visto de frente. Para ajustar, use `IconeGiro`, `IconeZoom` e `IconeDesloca` no modelo (veja `icones-itens.md`).

## Testar no Studio

Na barra de comandos, na vista do **servidor**, com o boneco vivo:

```lua
local p = game.Players:GetPlayers()[1]
game.ServerStorage.DevGive:Invoke(p, { hood = 1, lava_helmet = 1 }) -- dá peças (testOnly também funciona no Studio)
game.ServerStorage.DevArmor:Invoke(p, "lava_helmet")     -- veste direto, sem trava
game.ServerStorage.DevArmor:Invoke(p, nil)               -- tira
```

## Onde fica no código

| Arquivo | O que faz |
|---|---|
| `src/shared/Defs/Items.luau`, `Recipes.luau` | peças, materiais e receitas |
| `src/shared/Survival/ArmorRules.luau` | conversão dos números do Starve (testes em `tests/armor.spec.luau`) |
| `src/server/Services/ArmorService.luau` | peça vestida (atributo `Armor`), trava de troca, explorador |
| `src/server/Services/WearService.luau` | segurar e usar para vestir |
| `src/server/Services/CharacterService.luau` | dano com a defesa de jogador ou de mob |
| `src/shared/Survival/SurvivalRules.luau`, `WaterService`, `WaterSim` | frio, fogo, regen, fôlego e nado |
| `src/shared/Mobs/MobBrain.luau`, `MobService` | mobs ignorando o explorador |
| `src/client/Boneco/ArmorModel.luau`, `BonecoRenderer` | peça no boneco e nick escondido |
| `src/client/UI/ItemIcon.luau`, `src/shared/UIFlow/ItemInfo.luau` | ícone e dicas |
