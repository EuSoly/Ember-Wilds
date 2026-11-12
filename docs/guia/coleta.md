# Coleta

Segure o clique (no celular, o joystick direito) com o boneco virado para uma árvore, rocha, jazida de ouro ou arbusto: a cada golpe o recurso dá um tranco, solta lasquinhas, faz barulho e o que você pegou entra no inventário. São **2 golpes por segundo**, e o primeiro sai na hora em que você aperta.

Com **comida na mão**, o mesmo botão come em vez de coletar.

## O que cada coisa na mão pega

Cada picareta tem um **nível** e cada recurso uma **dureza**. Rendimento por golpe = `nível − dureza + 1`. Com nível menor que a dureza, nada é coletado e aparece "Precisa de Picareta de …".

| Na mão | Madeira (dureza 0) | Pedra (1) | Ouro (2) | Frutinha |
|---|---|---|---|---|
| Mão ou qualquer item (nível 0) | 1 | — | — | 1 |
| Picareta de madeira (nível 1) | 2 | 1 | — | 1 |
| Picareta de pedra (nível 2) | 3 | 2 | 1 | 1 |
| Picareta de ouro (nível 3) | 4 | 3 | 2 | 1 |
| Picareta de diamante (nível 4) | 5 | 4 | 3 | 1 |
| Picareta de ametista (nível 5) | 6 | 5 | 4 | 1 |
| Picareta de reidite (nível 6) | 7 | 6 | 5 | 1 |

A frutinha rende sempre 1 por golpe (`fixedYield`), com qualquer coisa na mão.

## Cavar com a pá (12/11)

Com uma **pá** na mão, o golpe que não acerta nada cava o chão onde ele cai (o mesmo ponto à frente do boneco). Golpe que acerta árvore, rocha ou arbusto continua sendo coleta normal (com a pá, rocha pede picareta).

| Onde | O que sai |
|---|---|
| Chão da floresta | **Terra** (`ground`) |
| Margens do rio, dos lagos e a praia da baía | **Areia** (`sand`) |
| Água ou fora do mapa | nada |

Por golpe: pá de pedra 1, pá de ouro 2 (config do Starve; diamante 3 e ametista 4 seguem só de teste). Cada golpe também sorteia achados de sorte, um de cada: pedra 5%, ouro 1,5%, diamante 0,17% (`dig_items` do Starve). Cada unidade cavada vale 1 ponto e conta em `resources_gathered`.

**Onde é areia:** as peças do mapa com o atributo `Sand = true` (na peça ou na pasta dela), vistas de cima. Hoje estão marcadas em `Map/NoSpawn/Floresta2026`: as `RiverBank` (88), `Lake1Bank` a `Lake8Bank` e a `BayBeach`. A margem é mais larga que a água (a `RiverBank` tem 48 de largura, o rio 36), então a areia é a faixa de 6 studs de cada lado. A água ganha da areia. Para marcar uma margem nova, ponha `Sand = true` nela no Studio.

Terra e areia ainda não têm ícone (aparecem como "Te" e "Ar"). A terra entra na receita do poço; a areia fica guardada para as receitas que vierem.

## Reserva, regeneração e pontos

| Recurso | Reserva | Volta | Pontos por unidade |
|---|---|---|---|
| Árvore | 20 (a menor) a 80 (a maior), conforme o tamanho | +2 a cada 10 s | 1 |
| Rocha | 40 | +2 a cada 10 s | 2 |
| Jazida de ouro | 20 | +1 a cada 10 s | 3 |
| Arbusto | 5 frutinhas (uma por baga do modelo) | +1 a cada 10 s | 2 |

- O modelo **nunca some**: vazio, ele fica e aparece "Este recurso acabou". A reserva volta aos poucos.
- Inventário cheio: aparece "Inventário cheio" e o recurso não perde nada. Se só couber uma parte, só essa parte sai da reserva.
- Os pontos vão para a sua pontuação da vida (canto superior esquerdo) e viram Golden Ember quando a vida acaba. O ranking (#1, #2…) é a sua posição entre os jogadores vivos do servidor.
- Cada coleta conta na estatística salva "recursos coletados" (por item).

Os números ficam no bloco `gather` de cada recurso em `src/shared/Defs/Resources.luau` e no `pickaxe` das picaretas em `src/shared/Defs/Items.luau`.

## Recurso coletável novo

No `Defs/Resources.luau`, o recurso ganha o bloco `gather`:

```lua
gather = gather({
	item = "diamond",          -- id em Defs/Items que o golpe dá
	points = 4,                -- pontos por unidade
	material = "stone",        -- som e lasquinhas: "wood", "stone", "gold" ou "leaves"
	hardness = 3,              -- dureza (picareta de nível 3+); OU fixedYield = 1
	amount = { min = 10, max = 30 }, -- reserva (min ≠ max: cresce com o tamanho)
	regen = { amount = 1, every = 10 },
}),
```

Picareta nova: em `Defs/Items.luau`, `category = "tool"`, `tier` e `pickaxe = { level = n }`. O nível também precisa ser compatível com as durezas dos recursos.

## Frutinhas que aparecem e somem

Num modelo de recurso, as peças chamadas **`Berry`** mostram quanto ele ainda tem: com a reserva cheia todas aparecem; conforme é colhido, elas somem (em proporção) e voltam quando regenera. O `berry_bush_1` tem 5 frutinhas `Berry`, uma por unidade da reserva (5). Vale para qualquer modelo novo: é só dar o nome `Berry` às peças.

## Sons e lasquinhas

A cor das lasquinhas de cada material fica em `src/shared/GatherFxConfig.luau`. O som do golpe fica com os outros sons, em `src/shared/Audio/SoundConfig.luau` (`hit_wood`, `hit_stone`, `hit_gold`, `hit_leaves`, `hit_diamond`; material sem som próprio usa o da pedra). Veja `docs/guia/sons.md`.

## Onde fica no código

| Arquivo | O que faz |
|---|---|
| `src/shared/Gather/DigRules.luau` | cavar com a pá: o que sai em cada chão e os achados de sorte (testado em `tests/dig.spec.luau`) |
| `src/shared/Gather/GatherRules.luau` | rendimento, picareta mínima, reserva, regeneração, alvo do golpe, frutinhas visíveis (testadas em `tests/gather.spec.luau`) |
| `src/shared/World/SpatialGrid.luau` | grade para achar o alvo sem olhar os 1.600 recursos |
| `src/shared/Gather/Ranking.luau` | posição no ranking |
| `src/server/Services/ResourceService.luau` | reserva de cada recurso (atributos `Amount`/`AmountMax`) e regeneração |
| `src/server/Services/GatherService.luau` | o golpe (e o cavar, quando não há alvo) |
| `src/server/Services/ScoreService.luau` | pontos (`Score`) e ranking (`Rank`) |
| `src/client/World/GatherFx.luau` | tranco, lasquinhas, som e avisos |
| `src/client/World/BerryDisplay.luau` | frutinhas visíveis |
