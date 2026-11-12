# Fazenda

Plante sementes no chão da floresta ou num **canteiro**, regue com o **regador** e colha os frutos batendo na planta. Os números são os da config oficial do Starve (`docs/superpowers/specs/2026-11-12-fazenda-design.md`).

Para o público hoje: **semente de frutinha**, canteiro, regador e forcado. As outras 8 culturas funcionam por inteiro, mas são `testOnly`. Para liberar uma, apague o `testOnly = true` da semente e do fruto em `src/shared/Defs/Items.luau`. Não há código novo a fazer.

## Como jogar

1. **Semente:** 3 frutinhas perto do fogo (5 s). As outras sementes saem dos próprios frutos (3, 8 ou 16).
2. **Plantar:** com a semente na mão, solte o clique.
   - Dentro de um canteiro, ela vai para o centro dele (uma planta por canteiro).
   - Fora dele, só no chão da floresta: nem água, nem areia, nem fora do mapa.
3. **Regar:** a planta **nasce seca** e só cresce molhada. Com o regador **cheio** na mão, bata na planta (ou no canteiro).
   - A rega dura o tempo da cultura (200 s na frutinha).
   - Para encher, segure o botão com o regador vazio perto da água.
   - O cheio nunca esvazia.
4. **Crescer:** 4 estágios (os modelos `stage_01` a `stage_04`). Madura, ela dá um fruto a cada tanto, até o máximo, e os frutos aparecem no modelo.
5. **Colher:** bata na planta com fruto. A mão colhe 1, o forcado 2 e o de ouro 3. Sem fruto, o golpe bate nela como numa construção (vida 100).
6. **Velhice:** a planta morre depois de 8 dias de jogo (64 min; a melancia vive 48 min).

**Canteiro:**
- Custa 20 madeiras + 15 terras na bancada e tem vida 3500.
- Faz crescer e dar fruto **2x mais rápido**.
- Fica na camada do piso: encaixa em grade, anda-se por cima, e não vai na água nem em cima de piso.
- A terra escurece quando está regada.
- A rega fica no canteiro, então dá para regar o canteiro vazio antes de plantar.
- Quebrar o canteiro leva a planta junto.

**Planta no chão e seca:** as folhas ficam cor de palha (sem textura) e voltam ao normal ao regar.

**Túnicas:** quem rega vestindo a túnica de camponês faz a planta crescer 1,2x enquanto durar essa rega; com a de inverno, 1,4x (`cropGrowth`).

**Arbusto de espinho:** maduro, machuca quem encosta, como um espinho de pedra (20). Respeita dono, time e tutorial.

## Culturas

| Cultura | Cresce | Fruto a cada | Rega dura | Máx. | Fruto | Público |
|---|---:|---:|---:|---:|---|---|
| Frutinha (`berry`) | 40 s | 120 s | 200 s | 5 | frutinha | sim |
| Trigo | 16 s | 120 s | 200 s | 3 | trigo (recurso) | teste |
| Abóbora | 50 s | 160 s | 250 s | 1 | fome 30 | teste |
| Cenoura | 30 s | 240 s | 200 s | 3 | fome 20 | teste |
| Tomate | 30 s | 240 s | 200 s | 3 | fome 16 | teste |
| Melancia | 180 s | 240 s | 200 s | 1 | fome 15, sede 8 | teste |
| Alho | 120 s | 240 s | 200 s | 3 | fome 14 | teste |
| Babosa | 200 s | 240 s | 200 s | 1 | cura 15 | teste |
| Arbusto de espinho | 15 s | 240 s | 240 s | 1 | espinheiro (recurso) | teste |

No canteiro, os tempos de crescer e dar fruto caem pela metade. Cada fruto colhido vale os pontos da semente ÷ 3 (frutinha: 4).

## Assets

- `Assets.Structures.plot`: canteiro (`Frame` + `Soil`, atributo `SoilHeight`).
- `Assets.Farming.<cultura>.stage_01..04`: os estágios, com o mesmo pivô. As peças colhíveis têm `Harvestable` e `HarvestIndex` (na frutinha se chamam `Berry`).
- `Assets.Icons.<cultura>_seed`: sementes.
- `Assets.Icons.thornbush`: provisório, o modelo maduro.
- `Assets.Tools.watering_can_full`: cópia do regador vazio.

Tudo veio do lote `assets/farming` e foi instalado no Studio em 12/11 (escala 1,738, para o canteiro medir 6,3 studs como o telhado).

## Testar no Studio

`ServerStorage.DevFarm:Invoke(segundos)` avança todas as plantas, como se tivessem passado molhadas (se houver rega), e devolve um resumo: estágio, frutos, molhada, canteiro. Com 0, só mostra o resumo.

## Onde fica no código

| Arquivo | O que faz |
|---|---|
| `src/shared/Farm/PlantRules.luau` | crescer, rega, frutos, estágio, colher, velhice, canteiro sob a semente, chão permitido (testado em `tests/plant.spec.luau`) |
| `src/server/Services/FarmService.luau` | estado das plantas e canteiros, passo de 1 Hz, golpe (regar, colher), encher o regador, `DevFarm` |
| `src/server/Services/StructureService.luau` | `seedSpot`: a semente encaixa no canteiro ou exige chão da floresta |
| `src/shared/Models/StructureModel.luau` | estágio (`setPlantStage`), frutos (`setPlantFruit`), folha seca (`setPlantDry`), terra molhada (`setSoilWet`) |
| `src/server/Services/SpikeService.luau` | espinho do arbusto maduro (`FarmService.hurts`) |
| `src/client/World/BuildGhost.luau` | fantasma da semente no centro do canteiro |
| `src/shared/Defs/Items.luau` | `plot`, frutos, a tabela `CROPS` que gera as sementes, regadores e forcados |
