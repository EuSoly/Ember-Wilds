# Ferramentas e armas

Os modelos de `ReplicatedStorage.Assets.Tools` viram itens com os números e as receitas da **configuração oficial do Starve** (`starve.io/commands.html`). Onde a config não traz número, o comportamento vem da wiki. Design: `docs/superpowers/specs/2026-11-11-ferramentas-design.md`. O balanço contra as armaduras está em `docs/game-design/balanco-armas-defesa.md`.

## Liberadas e só para teste

**Liberadas:** martelos de pedra e ouro, escudos de madeira, pedra e ouro, chave inglesa. Também as armas que já existiam: picaretas, espadas e lanças até o ouro.

**Só para teste (`testOnly`):**
- **Por falta de material:** espadas e lanças acima do ouro, inclusive dragão, lava, pirata e caranguejo; martelos e escudos de diamante para cima; Super Martelo.
- **Por falta de sistema:** pás (cavar), forcados e regador (fazenda), facão (caixa de mob em dobro).
- **Itens de quest:** Orbe Azul (`dragon_orb`), Orbe de Lava (`lava_orb`) e Peça do Forcado (`pitchfork_part`).

Para liberar, apague o `testOnly = true` do item em `src/shared/Defs/Items.luau` e dos materiais da receita.

## Como cada uma funciona

| Tipo | No jogo |
|---|---|
| Espada / lança | `mobDamage` = dano contra jogador e mob (o Starve usa o mesmo). Deixam lento (0,75) e ficam presas na mão 4 s; a lança alcança mais e empurra mob. |
| Bônus de conjunto | `gearBonus = { set, damage }`: com o capacete do mesmo conjunto (`armor.gearSet`), soma o dano. Espada de dragão/lava +3, lança +2. |
| Martelo | `structureDamage` alto (20 a 95) e `hammer.minDamage`: contra peça de **material acima** do martelo (ordem em `Defs/Tiers`), só o mínimo. Bate fraco em jogador e mob e não deixa lento. |
| Escudo | `shield = { defense, mobDefense }`: **na mão**, soma com a defesa da peça de cabeça (`golpe − capacete − escudo`). Bate com o dano do material (1 a 6) e não deixa lento. `arrowDefense` é só dado. |
| Animação na mão | `attackAnim`: `"swing"` (arco de lado: picaretas, espadas, martelos), `"thrust"` (estocada, mãos do lado do corpo: lanças e forcados) ou `"bash"` (escudos: seguro com as duas mãos à frente do corpo e de frente; o golpe avança as duas mãos com o escudo). Números em `BonecoConfig` (`SHIELD_HAND_X`, `SHIELD_HOLD_FORWARD`, `SHIELD_BASH_DISTANCE`). A pegada de cada modelo se ajusta na bancada (`scripts/studio/weapon-bench.luau`). |
| Chave inglesa | `repair = 70`: golpe numa construção **sua** danificada devolve até 70 de vida, sem passar do máximo, e não abre a porta. Em construção alheia, é golpe de mão. |
| Pá, forcado, regador, facão | `dig`, `harvest`, `waters`, `butcher`: só dado, até cavar, fazenda e caixa de mob em dobro existirem. |

O código fica em `ArmorRules.reduce` (escudo), `MobRules.damageOf` (bônus), `BuildRules.damageOf` e `BuildRules.repairAmount` (martelo e chave). No servidor, ficam em `CharacterService`, `GatherService`, `MobService` e `StructureService`. Os testes estão em `tests/toolrules.spec.luau` e `tests/toolitems.spec.luau`.

## Dano em construção das armas

As paredes têm a vida do Starve (madeira 1000), mas o nosso jogo já tinha uma escala própria para espadas, lanças e picaretas: espadas e lanças 5 / 7,5 / 10, picaretas 10 a 35. As armas novas continuam essa escala (+2,5 por material). Só os martelos usam o número do Starve. Veja `docs/pendencias.md`.

## Testar no Studio

Na vista do **servidor**, com o boneco vivo:

```lua
local p = game.Players:GetPlayers()[1]
game.ServerStorage.DevGive:Invoke(p, { gold_shield = 1, stone_hammer = 1, wrench = 1, lava_sword = 1 })
game.ServerStorage.DevArmor:Invoke(p, "lava_helmet") -- com a espada de lava: +3
```

## Regenerar o balanço

```bash
lune run scripts/balanco-armas > docs/game-design/balanco-armas-defesa.md
```
