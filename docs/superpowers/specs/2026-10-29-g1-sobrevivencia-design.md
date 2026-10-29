# G1 — Sobrevivência (design)

Data: 2026-10-29. Fase seguinte à base F0–F6. Aprovado pelo Elizeu em chat ("de resto pode ser tudo isso mesmo"), com o pedido extra de deixar as **armaduras** preparadas.

## Intenção

Fazer as quatro barras do HUD (vida, fome, frio, sede) valerem de verdade, como no Starve.io: o jogador precisa comer, beber e se esquentar, e morre se descuidar. É o primeiro sistema de gameplay e define o ritmo do jogo (comer a cada 2–3 min; de noite, precisar de fogo).

## Objetivos

- Barras 0–100 calculadas no servidor, atualizadas 2× por segundo (anéis descem lisos, não aos pulos).
- Fome, sede e frio caem com o tempo; frio depende de dia/noite e água; fogueira esquenta; água enche a sede.
- Vida regenera só com fome, frio e sede acima de 35%; barra vazia (e fôlego zerado) tira vida.
- Vida zerada = morte pela função única `DeathService.kill`, com a causa certa na tela de morte.
- Comer frutinha (item na mão + clicar) repõe fome.
- **Armaduras preparadas** (pedido do Elizeu): o item pode ter proteção (corta dano de combate) e modificadores de barras (ex. casaco segura o frio). Existe o "vestir" no servidor e as regras; ainda não existe nenhum item de armadura, tela de vestir nem visual no boneco.
- Todos os números num arquivo de dados (`src/shared/SurvivalConfig.luau`), para ajustar sem mexer em código.

## Não-objetivos (ficam para outras fases)

- Fogueira construível (fase de construção). Na G1 a fogueira de teste do Studio (`DevCampfire`) já esquenta; a de verdade só precisa da mesma marca de fonte de calor.
- Cozinhar carne, garrafa d'água, roupas e armaduras de verdade (conteúdo), telas/arrasto para vestir, armadura aparecendo no boneco.
- Dano de combate (jogadores e mobs): a G1 só deixa o `hurt` pronto para o combate usar (com a redução da armadura).
- Bioma de inverno: só fica o fator de frio por bioma reservado (floresta = 1).
- Expressão de frio no boneco (o sistema de expressões já aceita; fica para depois).

## Números aprovados

| Regra | Valor | Origem |
|---|---|---|
| Fome cai | 0,6/s (cheia → vazia ~2 min 47 s) | Starve: −3 a cada 5 s |
| Sede cai | 0,5/s (~3 min 20 s) | sugestão (sem número público) |
| Frio cai de dia | 0,4/s (~4 min 10 s) | Starve: −2 a cada 5 s na floresta |
| Frio cai de noite | 1,6/s (~1 min) | wiki: "esvazia em ~1 min sem fogo" |
| Na água | frio cai 2× mais rápido; sede enche +5/s | Starve |
| Fogueira | dentro de 12 studs, frio **sobe** +5/s (no lugar de cair) | sugestão |
| Frutinha | +10 de fome | catálogo do Starve |
| Regeneração | +0,5/s, só com fome, frio e sede ≥ 35 e sem dano no momento | regra dos 35% do Starve |
| Fome vazia | −1,5 vida/s | Starve: −15 de 200 a cada 5 s |
| Frio, sede ou fôlego vazios | −1 vida/s cada (somam) | Starve: −10 de 200 a cada 5 s |

Tudo vazio = morte em ~30 s; só a fome vazia = ~67 s.

## Como funciona (decisões)

### Regras puras + serviço

- `Survival/SurvivalRules.luau` (shared, sem Roblox, testável no Lune): recebe as barras, o contexto (noite, água, perto de fogo, fôlego, modificadores da armadura, fator de frio do bioma) e `dt`, e devolve as barras novas, o dano do passo e a causa.
- `SurvivalService` (servidor): a cada 0,5 s monta o contexto de cada jogador vivo, chama as regras, grava os atributos (`Health`, `Hunger`, `Cold`, `Thirst`, já lidos pelo HUD) e manda o dano para `CharacterService.hurt`.
- No nascimento, as quatro barras voltam a 100.

### Dano e morte

- `CharacterService.hurt(character, amount, causeKey, kind)` passa a ser a função única de dano para tudo:
  - `kind = "combat"`: a defesa da armadura corta o dano; a careta/flash vermelho aparece sempre.
  - `kind = "survival"`: a armadura **não** protege; a careta aparece no máximo a cada 2 s (senão o boneco piscaria sem parar).
  - Vida chegou a 0 → `DeathService.kill(player, causeKey)`.
- Causas novas na tela de morte: Fome, Frio, Sede, Afogado. Quando mais de uma barra está vazia, a causa é a que tirou mais vida no passo (empate: fome, frio, sede, fôlego).

### Fogo

- Fonte de calor = qualquer modelo com a tag `HeatSource` e o atributo `HeatRadius` (studs). O `CampfireModel` já sai com os dois (raio 12). A fogueira construível só precisa usar o mesmo modelo/tag.
- Perto do fogo o frio sobe +5/s, mesmo de noite ou na água.

### Comida

- Item de comida tem o bloco `food = { hunger?, thirst?, health? }` em `Defs/Items` (frutinha: `{ hunger = 10 }`).
- Com comida na mão (atributo `Equipped`), apertar o botão de usar (o mesmo de bater) come uma unidade; segurar continua comendo a cada 0,5 s.
- Não come se todas as barras que a comida repõe já estão cheias (não desperdiça).

### Armaduras (preparadas)

- Item com `category = "armor"` tem o bloco `armor = { defense?, coldFactor?, hungerFactor?, thirstFactor? }`:
  - `defense`: fração do dano de **combate** cortada (0 a 0,9);
  - `coldFactor`/`hungerFactor`/`thirstFactor`: multiplicam quanto a barra cai (0,5 = cai na metade da velocidade; até 2).
- Uma armadura vestida por vez (como no Starve, um item de cabeça), guardada no atributo `Armor` do Player (id do item). `ArmorService.wear(player, itemId?)` veste/tira; como o `equipBag`, não mexe no inventário (quem chamar no futuro cuida disso).
- A morte tira a armadura (como tira a mochila).
- Comando de dev `DevArmor` para testar quando existir um item.

## Restrições

- Server Authority, `--!strict`, conteúdo = dados validados em `Validate`, textos em `Strings`.
- O `DevStatsService` deixa de mexer nas barras (continua só com os pontos/ranking falsos até a pontuação existir).
- O `WaterService` continua dono do `Oxygen` e do `InWater`; a sobrevivência só lê.

## O que fica para quem implementa

Nomes internos de variáveis, formato exato das mensagens de aviso, e os testes extras além dos listados no plano.

## Adendo (29/10): temperatura = frio + calor por cima

Pedido do Elizeu durante a implementação: "a barra não é só de frio, é de temperatura, então precisa ter dano por calor também". Ele escolheu o modelo **"frio + calor por cima"** (no lugar de uma barra única com faixa confortável no meio):

- O frio continua como aprovado (100 = quentinho, 0 = congelando).
- Uma segunda barra, **calor** (atributo `Heat`, 0 a 100, começa em 0), só enche quando o jogador **continua esquentando com o frio já cheio**: em cima do fogo (perto da fogueira só enche o frio, não passa do topo) e, no futuro, deserto de dia e lava (`BIOME_HEAT`, hoje 0 na floresta).
- Fora disso o calor esfria sozinho, e o frio só volta a cair depois que o calor zera.
- Calor cheio tira vida (causa "Calor"). A vida só regenera com o calor abaixo de 65 (regra do Starve na lava).
- O anel do frio no HUD vira laranja e mostra o calor enquanto o calor for maior que 0.
- Armaduras ganham `heatFactor` (multiplica quanto o calor sobe), preparando as proteções de calor (N4).

Números (minha sugestão, ajustáveis em `SurvivalConfig`): em cima do fogo = até 3 studs do centro da fogueira; esquenta +20/s (calor cheio em ~5 s depois do frio cheio); esfria −5/s; calor cheio = −1,2 de vida/s (Starve: −12 de 200 a cada 5 s).
