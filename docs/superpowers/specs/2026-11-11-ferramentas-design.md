# Ferramentas e armas: os modelos do Elizeu viram itens (design)

Data: 11/11/2026 · Branch: `armaduras` (o balanço das armas depende das defesas das peças de cabeça) · Modelos: `ReplicatedStorage.Assets.Tools/<id>` (todos com `Handle` + `Grip`, conferido no place).

## Por quê

O Elizeu já pôs no place os modelos de 33 ferramentas e armas que ainda não são itens. Ele quer que funcionem no jogo, para ver se o equilíbrio com as defesas das armaduras (fase anterior) quebra quando as armas fortes existirem. Mesmo método das armaduras: números e receitas da **config oficial do Starve** (`starve.io/commands.html`), comportamento da wiki quando a config não diz, e o que o jogo ainda não sustenta fica `testOnly`.

## Decisões do Elizeu

- Esta fase é só **ferramentas e armas** (11/11). Construções novas (paredes de diamante/ametista, máquina de esmeralda, pedra da ressurreição, totem) e comidas novas ficam para as próximas.
- Pode seguir sem aprovações no meio; revisão da branch no fim (mesmo combinado das armaduras).
- O que não existe no jogo fica `testOnly` (vale para materiais, itens de quest e sistemas que faltam).

## Itens

Ids = nomes dos modelos em `Assets.Tools`.

| Grupo | Ids | Liberado? |
|---|---|---|
| Espadas | `diamond_sword`, `amethyst_sword`, `reidite_sword`, `dragon_sword`, `lava_sword`, `pirate_sword` | não (materiais) |
| Lanças | `diamond_spear`, `amethyst_spear`, `reidite_spear`, `dragon_spear`, `lava_spear`, `crab_spear` | não |
| Martelos | `stone_hammer`, `gold_hammer` | **sim** |
| | `diamond_hammer`, `amethyst_hammer`, `reidite_hammer`, `super_hammer` | não |
| Escudos | `wood_shield`, `stone_shield`, `gold_shield` | **sim** |
| | `diamond_shield`, `amethyst_shield`, `reidite_shield` | não |
| Chave inglesa | `wrench` | **sim** |
| Pás | `stone_shovel`, `gold_shovel`, `diamond_shovel`, `amethyst_shovel` | não (cavar não existe) |
| Fazenda | `pitchfork`, `gold_pitchfork`, `watering_can` | não (fazenda não existe) |
| Facão | `machete` | não (dobrar caixa de mob não existe) |

Materiais novos (`testOnly`, sem modelo, `category = "misc"`): `dragon_orb` (Orbe Azul, quest), `lava_orb` (Orbe de Lava, quest), `pitchfork_part` (Peça do Forcado, quest). A garrafa d'água do Super Martelo (`bottle_full`) vira o `water_bucket` que já existe (minha escolha).

As picaretas de diamante, ametista e reidite (já existem, `testOnly`) trocam a receita provisória pela do Starve.

## Números (config oficial; wiki onde a config não tem)

Dano por golpe = `damage` da config, igual contra jogador e mob (`damage_pve` é igual em todos).

| Item | Dano | Dano em construção | Outros |
|---|---|---|---|
| Espada diamante / ametista / reidite | 24 / 27 / 30 | 12,5 / 15 / 17,5 (nossa escala, ver abaixo) | lenta 0,75, presa 4 s, como as atuais |
| Espada dragão / lava | 30 / 33 | 17,5 / 20 | +3 com capacete de dragão / de lava (`gear_sets`) |
| Espada pirata | 24 | 12,5 | sem receita (baú do tesouro) |
| Lança diamante / ametista / reidite | 17 / 18 / 22 | 12,5 / 15 / 17,5 | alcance e empurrão das lanças atuais |
| Lança dragão / lava | 22 / 24 | 17,5 / 20 | +2 com capacete de dragão / de lava |
| Lança de caranguejo | 14 | 7,5 | acalma caranguejos (só dado) |
| Martelo pedra → reidite | 2 / 3 / 4 / 5 / 6 | 20 / 30 / 40 / 50 / 70 | mínimo contra parede de material acima: 5 / 10 / 20 / 40 / 70; não deixa lento |
| Super Martelo | 12 | 95 (mínimo 95) | |
| Escudo madeira → reidite | 1 → 6 | — | defesa na mão: jogador 1/2/3/4/5/6, mob 2/4/8/12/16/18, flecha 13..33 (dado); não deixa lento |
| Chave inglesa | — (mão) | — | conserta 70 de vida da construção aliada danificada |
| Pá pedra → ametista | 2 / 3 / 4 / 5 (wiki) | — | `dig` 1..4 (só dado) |
| Forcado / de ouro | 0 | — | colheita ×2 / ×3 (só dado); alcance maior |
| Regador | — | — | rega plantas (só dado) |
| Facão | 5 | — | caixa de mob dá o dobro (só dado) |

- **Dano em construção das armas:** o nosso jogo já usa uma escala própria (espadas e lanças 5 / 7,5 / 10, picaretas 10..35) e as paredes têm a vida do Starve. As armas novas continuam essa escala (+2,5 por material). Martelos usam o `building_damage` do Starve. Minha escolha; está em pendências para balancear.
- **Martelo contra material acima do dele:** usa o `building_min_damage` (é a leitura que bate com o changelog "um martelo inferior sempre dá dano, mas muito pouco"). Mesmo material ou abaixo: dano cheio.

## Regras novas

- **Escudo:** enquanto está na mão (`Equipped` do personagem), a defesa dele soma com a da peça de cabeça (`golpe − capacete − escudo`, nunca abaixo de 0). Bate com o próprio dano (1..6).
- **Bônus de conjunto:** arma com `gearBonus = { set, damage }` soma o dano quando a peça de cabeça vestida tem o mesmo `gearSet` (já gravado nas armaduras de dragão e lava). Vale contra jogador e mob.
- **Martelo:** `hammer = { minDamage }`; o dano em construção cai para `minDamage` quando o tier da construção é maior que o do martelo (ordem em `Defs/Tiers`).
- **Chave inglesa:** `repair = 70`. Golpe numa construção aliada (`BuildRules.areAllies`) danificada devolve até 70 de vida (sem passar do máximo) e não abre porta. Construção alheia: golpe normal (dano de mão).
- **Só dado:** `dig`, `harvest`, `waters`, `butcher`, `crabCalm`, `arrowDefense` do escudo. Ficam nos itens, comentados no tipo.

## Interface

- Ícone: as ferramentas já saem de `Assets.Tools` (vista diagonal das armas). Escudo é arma.
- Dicas e livro: escudo mostra as duas defesas (mesmas linhas das armaduras); chave inglesa mostra "Conserta {value} de vida"; arma com bônus mostra "+{value} com o capacete do conjunto". O martelo mostra o "Dano em construções" que já existe.

## Balanço (o motivo da fase)

Gerar `docs/game-design/balanco-armas-defesa.md` com a tabela de dano por golpe e golpes para matar (vida 200) de todas as armas contra: sem peça, capacetes de madeira a lava, e capacete + escudo do mesmo material. Ela responde à pergunta do Elizeu sobre o jogador "imortal" e vai junto da recomendação do dano mínimo (decisão dele, fora desta fase).

## Fora do escopo

Cavar, fazenda, rega, caixa de mob em dobro, caranguejos, baú do tesouro, montaria, flechas; construções e comidas novas; o dano mínimo garantido.

## Testes

- Regras puras: escudo somando defesa, bônus de conjunto, martelo contra tier acima, conserto sem passar do máximo.
- Dados: os 33 ids existem com `Assets.Tools` correspondente na lista do teste; liberados exatamente os 6; receitas da config; receita liberada só com material liberado (teste que já existe).
