# Armaduras: 32 itens de cabeça do Starve no boneco (design)

Data: 10/11/2026 · Branch: `armaduras` · Modelos: `ReplicatedStorage.Assets.Armor/<id>` (já no place; guia em `assets/armor/roblox/IMPORTAR-ROBLOX.md`).

## Por quê

O Elizeu modelou no Blender os 32 itens de cabeça do Starve.io (capacetes, roupas, proteções, coroas, chapéus). Agora eles viram itens de verdade: aparecem no boneco, têm a receita e os status do Starve e funcionam no jogo. O que o jogo ainda não tem (biomas, mobs, quests) fica **pronto e programado, só para teste** (`testOnly`): no futuro o Elizeu só tira a marca para liberar.

## Decisões do Elizeu (10/11)

1. **Visual mescla com a skin.** A peça vai por cima do boneco, no centro do corpo, sem esconder nada. Skin gorda esconde um pouco da armadura; skin magra mostra inteira. Sem ajuste por skin.
2. **Todas as 32 são de cabeça:** um item vestido por vez (já é assim: `Armor` no Player, `WearService`).
3. **Receitas e status do Starve.** Fonte: a configuração oficial do servidor (`https://starve.io/commands.html`, JSON com `*_defense`, `*_mob_defense`, `*_warm_*`, `*_loss_oxygen`, `*_blizzard` e as receitas), conferida com a wiki do Fandom. Números brutos em `docs/game-design/armaduras-starve.md` (tabela gerada para esta fase).
4. **Defesa do jeito do Starve:** número fixo subtraído do golpe, um valor **contra jogador** e outro **contra mob** (no lugar da porcentagem atual).
5. **Tudo pronto agora; o que não existe no jogo fica `testOnly`** (materiais de mob que não têm Def, minérios acima do ouro, itens de quest, efeitos de biomas futuros).
6. **Capuz:** só **esconde o nick** do jogador (sem roubo). O capuz de inverno faz o mesmo (e é `testOnly`).
7. **Túnica de camponês:** entra liberada; o efeito na fazenda fica guardado no dado para quando a fazenda existir.
8. **Itens de quest** (gemas, cubos, óculos, peles especiais, vaga-lume) viram itens `testOnly` sem modelo, para as receitas já serem as do Starve.
9. Implementação feita aqui mesmo, sem aprovações no meio; revisão da branch no fim.

## Objetivos

- As 32 peças nas Defs com receita, estação, tempo e status do Starve.
- A peça vestida aparece no boneco de todos (jogo, menu não precisa).
- Ícone 3D da peça nos slots, no livro e nas dicas, usando o mesmo modelo.
- Efeitos que já têm sistema funcionando: defesa jogador/mob, frio (dia/noite/água), calor do fogo nas proteções, oxigênio e nado (mergulho), regeneração (Coroa da Vida), esconder o nick (capuzes), explorador (mobs ignoram), espera de 5 s para trocar de peça.
- Efeitos sem sistema ficam **só como dado** nas Defs (com comentário), prontos para quando o sistema existir.

## Fora do escopo (anti-objetivos)

- Roubo (capuz), fazenda (túnicas), domar/sorte (Coroa da Sorte), ressurreição (Coroa do Anjo), nevasca, tempestade de areia, lava, bônus de conjunto de armas de dragão/lava, aceleração do avião (piloto), vassoura (bruxa), caranguejos seguindo (capacete de caranguejo), quests que dão os itens de quest. Tudo isso só fica guardado como dado.
- Não mexer no visual das skins nem dar ajuste de tamanho por skin.
- Não mudar o dano dos mobs nem das armas.
- Não ligar nada de loja/Robux.

## O que já existe (não refazer)

- `ArmorService.wear/modifiers`, `WearService` (segurar e usar veste, devolve a anterior), morte manda a peça para a caixa (`CrateService`), `DevArmor` (Studio).
- `ArmorRules` (puro, testado em `tests/armor.spec.luau`) e `SurvivalRules.step` usam `mods`.
- Itens `wood_helmet`, `stone_helmet`, `gold_helmet`, `earmuffs` (status e receita do `earmuffs` provisórios; trocar).
- O livro já tem a aba `armor` (`BookInfo.TABS`) e o texto `book.station.water` ("Perto da água").
- Ícones dos drops já estão em `Assets.Icons` (pele de inverno, mamute, pinguim, abutre, kraken, escama, garra, palito de caranguejo, chama, corações, diamante, ametista, esmeralda).

## Modelo de dados

Tudo em **unidades do Starve** dentro do bloco `armor` do item; a conversão para os nossos números fica nas regras (`ArmorRules`/`SurvivalRules`/config), não espalhada nos dados. Assim, um item novo é só copiar os números da config do Starve.

```luau
export type ArmorStats = {
	defense: number?,      -- tirado do golpe de JOGADOR (Starve *_defense, positivo)
	mobDefense: number?,   -- tirado da mordida de MOB (Starve *_mob_defense)
	warm: ArmorWarm?,      -- Starve *_warm_*: soma na perda de frio por tick (positivo = esquenta)
	fireHeatFactor: number?, -- multiplica o calor que o fogo põe na barra de calor (proteções = 0)
	oxygenLoss: number?,   -- Starve *_loss_oxygen: quanto tira da perda de oxigênio (base 25)
	swimSpeed: number?,    -- multiplica a velocidade nadando (mergulho 0,18/0,15 = 1,2)
	regenHeal: number?,    -- Starve: cura por ciclo de regen (base 12; Coroa da Vida 40)
	hidesName: boolean?,   -- capuzes: o nick some para os outros
	explorer: boolean?,    -- mobs agressivos ignoram; atacar/coletar desliga por EXPLORER_OFF s
	-- Só dado (sistema futuro), comentado no tipo:
	blizzard: number?, sand: { damage: number, every: number }?, cropGrowth: number?,
	stealImmune: ("hood" | "all")?, tameLuck: number?, digLuck: number?, resurrect: boolean?,
	crabFriend: boolean?, spiderImmune: boolean?, pilotAcceleration: number?, gearSet: string?,
	hungerFactor: number?, thirstFactor: number?, -- já existentes (ficam; nenhum item do Starve usa)
}
export type ArmorWarm = {
	day: number?, night: number?, waterDay: number?, waterNight: number?,
	winterDay: number?, winterNight: number?, lavaDay: number?, lavaNight: number?,
}
```

- `defense` muda de significado (fração → número fixo). `coldFactor` e `heatFactor` saem (substituídos por `warm` e `fireHeatFactor`); procurar e trocar os usos (`ItemInfo`, `Validate`, testes, `docs/guia/sobrevivencia.md`).
- `Validate`: limites coerentes (defesas 0–100, warm −200..200, fatores 0–2, `oxygenLoss` 0–25); `armor` só em `category = "armor"`.
- `SurvivalConfig` ganha as bases do Starve usadas na conversão: `STARVE_COLD_LOSS = { forest = { day = 2, night = 18 }, water = { day = 5, night = 25 }, winter = { day = 25, night = 50 } }`, `STARVE_OXYGEN_LOSS = 25`, `STARVE_REGEN_HEAL = 12`, e `ARMOR_SWAP_LOCK = 5` (s), `EXPLORER_OFF = 10` (s).

## Regras (conversão Starve → nosso jogo)

- **Combate:** `dano final = max(golpe − defesa, 0)`. `CharacterService.hurt` passa a saber a origem: golpe de **jogador** usa `defense`; mordida de **mob** usa `mobDefense`. Espinhos são construção de jogador → `defense` (minha escolha; Starve não deixa claro). Dano de sobrevivência continua sem defesa. O tipo `HurtKind` vira `"player" | "mob" | "survival"` (ou equivalente) e todos os chamadores são atualizados (`GatherService` jogador, `MobService` mob, `SpikeService` jogador, `DevBonecoService` mob).
  - Nota: nossas armas já usam o dano do Starve contra jogador (espadas 12/19/22), mas as mordidas são mais fracas que no Starve (lobo 24 × 40). Por decisão do Elizeu os números do Starve entram sem escala; a defesa contra mob fica proporcionalmente mais forte aqui. Registrar em `docs/pendencias.md` para balancear depois.
- **Frio:** a nossa perda por segundo no contexto (floresta dia/noite, água) é multiplicada por `(B − warm) / B`, onde `B` é a perda base do Starve no mesmo contexto (`STARVE_COLD_LOSS`) e `warm` é o valor da peça no contexto. Resultado negativo = esquenta nessa taxa (o Chapéu de Pele esquenta de dia na floresta, como no Starve). Sem peça, fator 1 (nada muda). Água usa `waterDay/waterNight` e a base da água; perto do fogo e em cima do fogo, nada muda.
- **Calor do fogo:** a parte que passa do frio cheio para a barra de calor é multiplicada por `fireHeatFactor` (proteções de diamante/ametista/reidite = 0: "anulam o calor do fogo"). `warm.lava*` fica só como dado (lava não existe).
- **Oxigênio:** na água o fôlego cai `× (25 − oxygenLoss) / 25` (`WaterService`). Máscara 14 → 0,44; roupa 19 → 0,24.
- **Nado:** na água a velocidade × `swimSpeed` (`WaterSim`, que roda na simulação; lê o atributo `Armor` do Player).
- **Regeneração:** `REGEN_RATE × regenHeal / 12` enquanto a peça está vestida (Coroa da Vida: × 3,33). Soma com a cama do jeito que já multiplica (`regenFactor`).
- **Capuz:** a etiqueta de nome (`BonecoModel` `NameTag`) some para os **outros** jogadores enquanto o dono veste peça com `hidesName`; o próprio dono continua vendo o seu (minha escolha).
- **Explorador:** mob **agressivo** não escolhe como alvo quem veste `explorer` e está com o efeito ligado; mob que já apanhou dele (neutro irritado/vingança) ataca normalmente. Bater em qualquer coisa (mob, jogador, recurso, construção, caixa) desliga o efeito por `EXPLORER_OFF` s (atributo no Player com o instante, servidor). Mob agressivo que já estava perseguindo solta o alvo quando o efeito liga de novo (minha escolha; o Starve diz "se acalmam 2× mais rápido", sem número).
- **Troca:** depois de vestir, só dá para vestir outra peça após `ARMOR_SWAP_LOCK` s (Starve `helmet_delay` 5000 ms). A morte limpa.

## Estações das receitas

O Starve pede, em algumas, **bancada + fogo** ou **bancada + fogo + água**. O `RecipeDef` ganha estações extras (ex. `alsoNear: { "fire" | "water" }?`, mantendo `station` como está) e `CraftStation` aceita `"water"`. Perto da água = a menos de `CraftRules.STATION_RADIUS` de uma peça de `Workspace.Map.Water` (borda, no plano XZ). `CraftRules.canCraft`, `CraftService` (aviso `craft.needWater`), `BookInfo`/`BookSheet` (mostrar todas as estações) e `CraftColumn` passam a considerar todas. Só as receitas `testOnly` usam isso hoje.

## Itens

Ids dos 32 = nomes dos modelos em `Assets.Armor` (iguais ao `manifest.json`). Nomes em pt-BR em `Strings/ptBR.luau` (`item.<id>`). Todos `category = "armor"`, `maxStack = 1`. `tier` nos capacetes de tier (madeira…reidite) quando o tier existir em `Defs/Tiers`; os outros sem tier.

**Liberados para o jogador** (materiais e sistemas existem): `wood_helmet`, `stone_helmet`, `gold_helmet`, `earmuffs`, `coat`, `turban`, `explorer`, `hood`, `peasant`. **Todo o resto `testOnly`.**

Tabela de status (unidades do Starve; config oficial):

| id | def jog. | def mob | warm dia/noite | água dia/noite | inverno dia/noite | lava dia/noite | outros |
|---|---|---|---|---|---|---|---|
| wood_helmet | 1 | 4 | — | — | — | — | |
| stone_helmet | 2 | 8 | — | — | — | — | |
| gold_helmet | 4 | 13 | — | — | — | — | |
| diamond_helmet | 5 | 19 | — | — | — | — | |
| amethyst_helmet | 6 | 23 | — | — | — | — | |
| reidite_helmet | 7 | 25 | — | — | — | — | |
| dragon_helmet | 8 | 27 | — | — | — | — | gearSet "dragon" |
| crab_helmet | 5 | 19 | — | — | — | — | crabFriend |
| lava_helmet | 9 | 30 | — | — | — | — | gearSet "lava", spiderImmune |
| earmuffs | 0 | 0 | 1/10 | 0/0 | 4/10 | −4/−10 | blizzard 8 |
| coat | 0 | 0 | 2/13 | 0/0 | 8/15 | −8/−15 | blizzard 12 |
| winter_hat | 0 | 0 | 2/16 | 0/0 | 16/35 | −18/−35 | blizzard 16 |
| fur_hat | 0 | 0 | 3/17 | 0/0 | 20/42 | −22/−42 | blizzard 20 |
| turban | 0 | 0 | 1/10 | 0/0 | 4/10 | 5/5 | sand 7 a cada 4 s |
| ninja | 0 | 0 | 1/10 | 0/0 | 4/10 | 10/10 | sand 2 a cada 8 s |
| pilot | 0 | 0 | 2/16 | 0/0 | 13/28 | −18/−35 | blizzard 12, pilotAcceleration 2,5 |
| diamond_protection | 2 | 8 | −5/−5 | −5/−5 | −5/−5 | 10/10 | fireHeatFactor 0 |
| amethyst_protection | 4 | 13 | −5/−5 | −5/−5 | −5/−5 | 15/15 | fireHeatFactor 0 |
| reidite_protection | 6 | 19 | −5/−5 | −5/−5 | −5/−5 | 25/25 | fireHeatFactor 0 |
| explorer | 0 | 0 | 0/3 | 0/0 | 0/3 | 0/−3 | explorer |
| hood | 0 | 0 | 1/10 | 0/0 | 4/10 | −4/−10 | blizzard 8, hidesName |
| winter_hood | 0 | 0 | 2/16 | 0/0 | 14/28 | −18/−35 | blizzard 12, hidesName |
| peasant | 0 | 0 | 1/10 | 0/0 | 4/10 | −4/−10 | blizzard 8, cropGrowth 1,2, stealImmune "hood" |
| winter_peasant | 0 | 0 | 2/16 | 0/0 | 14/28 | −18/−35 | blizzard 12, cropGrowth 1,4, stealImmune "all" |
| diving_mask | 2 | 8 | 0/0 | 2/15 | 4/10 | −4/−10 | oxygenLoss 14, swimSpeed 1,2 |
| diving_suit | 4 | 16 | 0/0 | 4/20 | 8/15 | −8/−15 | oxygenLoss 19, swimSpeed 1,2 |
| witch | 0 | 0 | 1/10 | 0/0 | 4/10 | −4/−10 | (sem config oficial: wiki "aquece como protetor") |
| santa | 0 | 0 | 2/15 | 0/0 | 13/28 | −15/−30 | |
| elf | 0 | 0 | 2/14 | 0/0 | 10/20 | −10/−20 | |
| life_crown | 4 | 16 | — | — | — | — | regenHeal 40 |
| angel_crown | 2 | 16 | — | — | — | — | resurrect |
| luck_crown | 4 | 16 | — | — | — | — | tameLuck 5, digLuck 8 |

Receitas (config oficial; B = bancada, F = fogo, A = água; tempo em segundos como os nossos):

| id | ingredientes | estação | tempo |
|---|---|---|---|
| wood_helmet | 50 madeira | — | 5 |
| stone_helmet | 75 pedra, 75 madeira, capacete de madeira | B | 10 |
| gold_helmet | 90 pedra, 90 madeira, 90 ouro, capacete de pedra | B | 20 |
| diamond_helmet | 100 pedra, 100 ouro, 100 diamante, capacete de ouro | B | 30 |
| amethyst_helmet | 80 ametista, 150 ouro, 120 diamante, capacete de diamante | B | 60 |
| reidite_helmet | 80 reidite, 150 diamante, 120 ametista, capacete de ametista | B+F | 90 |
| dragon_helmet | 30 linha azul, 1 cubo azul, 150 ametista, 3 corações de dragão | B+F+A | 120 |
| crab_helmet | capacete de ouro, 10 garras, 10 palitos de caranguejo, 10 linhas | B | 60 |
| lava_helmet | capacete de dragão, 1 cubo de lava, 150 reidite, 2 corações de lava | B+F+A | 180 |
| earmuffs | 1 pele de coelho, 2 linhas | B | 5 |
| coat | protetor de orelha, 5 pele de lobo, 4 linhas | B | 12 |
| winter_hat | casaco, 5 pele de inverno, 4 linha azul | B | 30 |
| fur_hat | gorro e cachecol, 5 pele de inverno, 10 pele de mamute, 4 linha azul | B | 50 |
| turban | 4 linhas, 2 pele de javali | B | 15 |
| ninja | turbante, 6 linhas, 4 pele de javali, 12 penas de abutre, 4 penas de pinguim | B | 150 |
| pilot | óculos de piloto, 8 penas de falcão, 8 de abutre, 8 de pinguim, 6 linhas | B | 60 |
| diamond_protection | 5 chamas, 50 diamante, 5 linha azul | B+F | 20 |
| amethyst_protection | proteção de diamante, 10 chamas, 50 ametista | B+F | 60 |
| reidite_protection | proteção de ametista, 15 chamas, 50 ametista, 50 reidite | B+F | 90 |
| explorer | 1 papel, 1 pele de coelho, 2 linhas | B | 5 |
| hood | 10 pele de lobo, 5 pele de coelho, 6 linhas | B | 10 |
| winter_hood | capuz, 1 pele de lobo negro, 15 pele de inverno, 5 linha azul, 8 penas de pinguim | B | 60 |
| peasant | 3 pele de coelho, 2 linhas | B | 10 |
| winter_peasant | túnica, 1 pele de lobo branco, 10 pele de inverno, 5 linha azul, 8 penas de pinguim | B | 60 |
| diving_mask | 2 escamas de piranha, 40 diamante, 4 linhas | B | 20 |
| diving_suit | máscara, 80 ouro, 1 pele de kraken, 20 ametista | B | 90 |
| witch | 5 pele de lobo, 2 pele de coelho, 6 linhas, 2 vaga-lumes (wiki; sem config) | B | 30 (minha escolha) |
| santa, elf | sem receita (presente de Natal); só `DevGive` | — | — |
| life_crown | 1 gema verde, 200 ouro | B+F+A | 60 |
| angel_crown | 1 gema azul, 200 ouro, 1 coração de dragão | B+F+A | 60 |
| luck_crown | 1 gema laranja, 200 ouro | B+F+A | 60 |
| blue_thread | 1 diamante, 1 linha | B | 3 |

## Materiais novos (todos `testOnly`, `category = "resource"` salvo indicação)

Com ícone em `Assets.Icons`: `diamond`, `amethyst`, `winter_fur`, `mammoth_fur`, `penguin_feather`, `vulture_feather`, `kraken_skin`, `piranha_scales`, `flame`, `dragon_heart`, `lava_heart`; `crab_claws` (food: fome 10) e `crab_sticks` (food: fome 20) como comida, igual ao Starve. Sem modelo (a grade mostra a sigla, como o papel hoje): `blue_thread` (craftável), `green_gem`, `blue_gem`, `orange_gem`, `blue_cube`, `lava_cube`, `pilot_glasses`, `black_wolf_fur`, `white_wolf_fur`, `firefly`. Nomes em pt-BR. Não colocar nenhum deles em loot de mob nem no mapa nesta fase (só `DevGive`).

## Visual no boneco

- `BonecoRenderer` lê o atributo `Armor` do Player dono do personagem (polling, como os outros atributos — ver memória do SA: atributo do personagem previsto não dispara sinal) e monta/troca a peça: clona `Assets.Armor/<id>`, ancoragem desligada, sem massa/colisão/consulta, `PivotTo(corpo.CFrame)` e solda no corpo visual (o mesmo corpo em que a skin e a mochila se apoiam). Sem modelo → nada (e um `warn` uma vez).
- Mescla com a skin: nada é escondido nem escalado.
- Acompanha giro, andar, dano (flash), morte (some com o boneco) e a careta normalmente; não entra no flash de cor se isso pintar a peça (minha escolha: a peça não pisca).
- Menu (`MenuBoneco`) não mostra armadura.

## Ícones

`ItemIcon` procura o modelo também em `Assets.Armor` (depois de `Icons`, antes de `Tools`), com câmera de frente levemente de cima. Ajustes por peça pelos atributos `IconeGiro/IconeZoom/IconeDesloca` já suportados, se precisar.

## Livro e dicas

- `ItemInfo` mostra "Defesa contra jogadores N", "Defesa contra criaturas N", "Protege do frio" (quando warm.night > 0), "Anula o calor do fogo", "Fôlego dura mais", "Nada mais rápido", "Regenera mais", "Esconde o nome", "Criaturas ignoram você". Textos em `Strings/ptBR.luau`.
- Receita com várias estações mostra todas.

## Testes (Lune, `tests/*.spec.luau`)

- `ArmorRules`: defesa jogador × mob, mínimo 0, sem armadura = neutro, fator de frio pela fórmula (inclui negativo = esquenta), oxigênio, regen.
- `SurvivalRules.step` com `warm` (coat de dia na floresta não perde frio; fur_hat esquenta) e `fireHeatFactor = 0`.
- `CraftRules` com estações extras e água.
- `Validate`: os 32 itens e materiais passam; limites novos.
- `defs.spec`: toda peça de `Assets.Armor` (lista dos 32 ids) existe nas Defs com receita, exceto `santa`/`elf` (sem receita).

## Documentação

- `docs/guia/armaduras.md` (novo): como as peças funcionam, unidades do Starve, como liberar (tirar `testOnly`), como adicionar uma peça nova (modelo em `Assets.Armor` + Def + receita + texto), comandos de teste (`DevGive`, `DevArmor`).
- Atualizar `docs/guia/sobrevivencia.md` (seção "Armaduras (preparadas)"), `docs/guia/combate.md` (defesa), `docs/pendencias.md` (balanço mob × defesa; estações com água; efeitos só-dado).
- `docs/game-design/armaduras-starve.md`: tabela bruta da config oficial e onde cada número veio.
- Rodar `graphify update .` no fim.

## Deixado ao implementador

- Nome exato dos campos novos, organização dos módulos e onde mora a checagem de água.
- Ângulo da câmera do ícone e ajustes finos por peça.
- Como o servidor guarda o instante do explorador e da trava de troca (atributo do Player é o caminho óbvio).
