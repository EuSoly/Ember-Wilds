# Fazenda: canteiro, as 9 culturas, regador e forcados

Data: 12/11/2026. Branch: `fazenda`.

## Por quê

A fazenda é o que segura o jogador na base (catálogo, N1). Regra do Elizeu (12/11): **todo sistema é feito até o fim**. As 9 culturas funcionam já; o que ainda não vai ao público fica `testOnly`, e liberar depois é só tirar a marca. Os modelos das 9 culturas já vieram no lote `assets/farming`.

## Decisões do Elizeu (12/11)

- O canteiro se comporta como o piso e o telhado: encaixa em grade e fica na camada do chão.
- A terra do canteiro mostra se está molhada ou seca.
- Os tempos vêm da config oficial do Starve.
- Para o público: **só a semente de baga** (3 frutinhas perto do fogo), mais o canteiro, o regador e o forcado comum. O resto fica pronto e `testOnly`.
- A semente pode ir **no canteiro e no chão da floresta**, como no Starve.
- Rega com o **regador**.
- O **forcado comum** é liberado. O de ouro funciona, mas continua `testOnly`, porque pede a Peça do Forcado.

## Números (config oficial do Starve: JSON `server-data` em starve.io/commands.html)

Tempos em segundos (`grown_*`, `born_*`, `water_*`, `time_life_*` da config, que vêm em ms). O "máx." é o número de frutos que o modelo `stage_04` desenha (o LEIA-ME do lote).

| Cultura (`crop`) | Cresce | Fruto a cada | Rega dura | Vive | Máx. | Colhe | Semente (perto do fogo) | Público |
|---|---:|---:|---:|---:|---:|---|---|---|
| `berry` | 40 | 120 | 200 | 3840 | 5 | `berry` | 3 frutinhas (`seed`) | sim |
| `wheat` | 16 | 120 | 200 | 3840 | 3 | `wheat` | 3 trigos | teste |
| `pumpkin` | 50 | 160 | 250 | 3840 | 1 | `pumpkin` | 8 abóboras | teste |
| `carrot` | 30 | 240 | 200 | 3840 | 3 | `carrot` | 8 cenouras | teste |
| `tomato` | 30 | 240 | 200 | 3840 | 3 | `tomato` | 8 tomates | teste |
| `watermelon` | 180 | 240 | 200 | 2880 | 1 | `watermelon` | 16 melancias | teste |
| `garlic` | 120 | 240 | 200 | 3840 | 3 | `garlic` | 8 alhos | teste |
| `aloe_vera` | 200 | 240 | 200 | 3840 | 1 | `aloe_vera` | 16 babosas | teste |
| `thornbush` | 15 | 240 | 240 | 3840 | 1 | `thornbush` | 8 arbustos de espinho | teste |

As receitas de semente levam 5 s. Os pontos da config são 11 (baga e trigo), 18 (abóbora, alho, espinho, cenoura, tomate) e 26 (melancia, babosa).

**Frutos novos** (todos `testOnly`; os ícones já estão no Studio, menos o do arbusto de espinho):

| Fruto | Categoria | O que faz |
|---|---|---|
| `wheat` | recurso | vira farinha no moinho (sistema seguinte) e semente |
| `thornbush` | recurso | semente |
| `pumpkin` | comida | fome 30 |
| `carrot` | comida | fome 20 |
| `tomato` | comida | fome 16 |
| `watermelon` | comida | fome 15, sede 8 |
| `garlic` | comida | fome 14 |
| `aloe_vera` | comida | cura (efeito "heal" do Starve: 3 de vida a cada 2 s por 10 s, 15 no total) |

**Peças e ferramentas:**

| Item | Config | Aqui |
|---|---|---|
| Canteiro `plot` | 20 madeiras + 15 terras, bancada, 5 s, 14 pontos; vida 3500 | público |
| Regador `watering_can` | 50 madeiras, bancada, 5 s | público |
| Regador cheio `watering_can_full` | regador perto da água, 5 s | público. Aqui enche segurando o botão perto da água, como o balde |
| Forcado `pitchfork` | 100 madeiras + 50 pedras, bancada (já existe) | público, colhe 2 |
| Forcado de ouro `gold_pitchfork` | forcado + Peça do Forcado (já existe) | teste, colhe 3 |

**Túnicas** (`cropGrowth` 1,2 e 1,4, que hoje é "só dado"): passam a funcionar. Quem rega vestindo a túnica deixa a planta crescer mais rápido enquanto durar essa rega. Equivale ao `plant_speed` do Starve: camponês +25%, inverno +50%. Aqui ficam os números já gravados nas túnicas, 1,2 e 1,4.

## Decididos por mim (fonte: wiki ou escolha)

- **Canteiro 2x mais rápido** (wiki: trigo 16 s → 8 s). Vale para crescer e para dar fruto.
- **A planta nasce seca:** precisa regar para começar a crescer ("precisa ser regada", catálogo).
- **Planta seca só para:** não cresce nem dá fruto. Morre só de velhice ou quebrada.
- **Golpe na planta:**
  - Com fruto: colhe 1 (`harvest` do item, ou seja, forcado 2 e de ouro 3), até o que ela tiver.
  - Cada fruto vale os pontos de semente da cultura ÷ 3, arredondado (baga: 4).
  - Sem fruto: bate como numa construção (vida 100), para o dono poder tirar.
- **Regador cheio nunca esvazia** (catálogo).
- **Arbusto de espinho maduro machuca** quem encosta, como um espinho de pedra (20 de dano no encosto; wiki: "dá 20 de dano"). Respeita dono e time, como os espinhos.
- **Babosa:** a cura vai de uma vez, 15 de vida (o total do efeito "heal"), porque ainda não temos efeitos que duram.

## Como funciona

**Canteiro (`plot`)**
- `structure.kind = "plot"`, `snap = true`, raio de grade 3,2.
- Fica na camada do chão (a do piso): não colide, jogador em cima não impede colocar, e não sobrepõe piso nem outro canteiro.
- Diferente do piso, **não vai na água**.
- Modelo: `planter_box` → `Assets.Structures.plot`. A peça `planter_box__Soil` é a terra: fica escura molhada e clara seca (cores novas na `Palette`).

**Semente (`<crop>_seed`; a de baga é `berry_seed`)**
- `structure.kind = "plant"` com o bloco `plant`: cultura, fruto, tempos, máximo, dano de espinho.
- Dentro de um canteiro: vai para o centro dele (uma planta por canteiro), ganha o 2x e a rega fica no canteiro.
- Fora de canteiro: precisa de chão da floresta (não água, não areia, não fora do mapa), e a rega fica na planta.
- É sólida, como o arbusto.

**Crescimento (regra pura `PlantRules`, testada no Lune)**
- **Estado:** quanto cresceu (0 a 1), frutos, progresso do próximo fruto, até quando está molhada, o bônus da rega e quando nasceu.
- **Passo de 1 Hz:** se está molhada, avança `dt / cresce × velocidade`. Depois de madura, conta para o próximo fruto.
- **Velocidade:** 2 no canteiro × `cropGrowth` de quem regou.
- **Estágio:** até 1/3 é `stage_01`, até 2/3 é `stage_02`, abaixo de 1 é `stage_03`, madura é `stage_04`. A troca é feita no servidor, com o mesmo pivô.
- **Frutos visíveis:** as peças `Harvest`/`Berry` do `stage_04` aparecem conforme o número de frutos.
- **Morte:** depois de `vive` segundos.
- **Planta no chão e seca:** folhas amareladas (não tem terra de canteiro para mostrar).

**Regador:** com o vazio na mão, segurar o botão perto da água troca pelo cheio, como o balde. O golpe do cheio numa planta ou num canteiro rega por `rega dura` a partir de agora. O cheio usa o modelo do vazio (o Elizeu ajusta depois).

## Fora desta parte (sistemas seguintes, sem modelo ainda)

- Moinho, farinha, forno de pão, pão, sanduíche e bolo de abóbora: o próximo sistema, que dá uso ao trigo.
- Trigo selvagem no mapa.
- Janelas de estufa.
- Garrafa de areia.
- Chrono quests de fazenda.
- Salvar a fazenda: construções não persistem.
- O efeito de frio do alho (só a wiki fala; a config não tem número).

## Assets

- **No Studio (eu):**
  - `Assets.Structures.plot`.
  - `Assets.Farming.<crop>.stage_01..04`.
  - Ícones das 9 sementes (`<crop>_seeds` → `<crop>_seed`).
  - `Assets.Tools.watering_can_full`.
- **Faltam (Elizeu):**
  - Ícone do fruto `thornbush`. Até lá, uso o `thorn_stage_04`.
  - Um regador cheio diferente do vazio (opcional).

## Ordem de implementação

1. **Assets no Studio** (conferindo que nada veio com script).
2. **Dados:**
   - Itens.
   - Receitas.
   - Tipos e validação do bloco `plant`.
   - Strings.
   - Testes de dados (o que é público e o que é teste).
3. **Regras puras:** `PlantRules` e as regras de colocar (canteiro fora da água; semente no canteiro ou no chão da floresta), com testes.
4. **Servidor:**
   - `FarmService`: estado, passo de 1 Hz, estágio, frutos, terra.
   - Golpe: colher, regar e bater.
   - Encher o regador.
   - Espinho do arbusto.
   - Cura da babosa.
   - O `StructureService` aceita canteiro e semente.
5. **Teste no Studio:**
   - Canteiro e semente.
   - Regar e ver a terra.
   - Crescer pelos 4 estágios.
   - Frutos aparecerem e serem colhidos, com o forcado dando 2.
   - Secar.
   - Uma cultura de teste de cada tipo de fruto (1 e 3 frutos) e o espinho.
6. **Fechamento:**
   - Docs: `guia/fazenda.md`, construção, ferramentas, armaduras (túnica) e pendências.
   - Check, graphify e commit.
