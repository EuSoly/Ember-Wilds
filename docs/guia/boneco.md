# Boneco

O jogador não é mais o avatar do Roblox: é um **boneco próprio** no estilo Starve.io (corpo arredondado com contorno, dois olhos no topo, mãos soltas). Todo mundo tem o mesmo tamanho e o mesmo hitbox.

## Como funciona: dois corpos

| Corpo | Onde existe | O que é |
|---|---|---|
| **Simulado** | servidor (e previsto no cliente pelo Server Authority) | O personagem do Roblox: `Humanoid` + `HumanoidRootPart` (o colisor) + uma `Head` invisível (só para o balão do chat). Tudo invisível. É ele que anda, gira para a mira e guarda os atributos. Montado por `src/shared/Models/CharacterBody.luau` e colocado em `StarterPlayer.StarterCharacter` pelo `CharacterService`. |
| **Visual** | só no cliente, um para cada personagem que ele enxerga | O boneco que aparece na tela, numa pasta local `Workspace.BonecoVisuals`. Segue o `HumanoidRootPart` a cada quadro, anima e faz expressões. Não entra na simulação e não replica nada. |

Por que dois: é o jeito oficial de fazer visual com Server Authority. O visual nunca sofre rollback nem gera correção, e todos veem a mesma coisa porque cada cliente desenha a partir do **mesmo estado replicado**.

### O estado (atributos no personagem)

| Atributo | O que é | Quem escreve |
|---|---|---|
| `Using` | `true` enquanto segura o botão de bater | `UseSim` (simulação) |
| `Equipped` | id do item na mão, ou nada | `EquipService` |
| `HurtAt` | instante (`GetServerTimeNow`) do último dano | `CharacterService.hurt` |
| `Cosmetic_body` | id da skin do corpo | `CosmeticService` |

Os nomes ficam em `src/shared/StatNames.luau`. A tag `Boneco` (CollectionService) marca os personagens que ganham um boneco visual (`CharacterService.prepare`).

> O cliente lê esses atributos **a cada quadro** (não usa `GetAttributeChangedSignal`). Com Server Authority, o sinal não dispara no personagem do jogador local. Veja `arquitetura.md`.

### Onde fica cada coisa

| Arquivo | O que é |
|---|---|
| `src/shared/BonecoConfig.luau` | Todos os números: medidas, corpo simulado, animações |
| `src/shared/BonecoAnim.luau` | Matemática das animações (testada em `tests/bonecoanim.spec.luau`) |
| `src/shared/ExpressionState.luau` | Escolha da expressão e do flash (testada em `tests/expressions.spec.luau`) |
| `src/shared/Cosmetic.luau` | Escolhe a skin de um slot (cai no padrão se o id não existir) |
| `src/shared/Defs/CosmeticSlots.luau`, `Cosmetics.luau`, `Expressions.luau` | Skins e expressões como dados |
| `src/shared/Models/CharacterBody.luau` | O corpo simulado |
| `src/client/Boneco/BonecoModel.luau` | Monta o boneco visual (peças, cores, olhos, ferramenta, nome) |
| `src/client/Boneco/BonecoRenderer.luau` | O loop que segue, anima e troca expressões de todos os bonecos |
| `src/server/Services/CharacterService.luau` | `StarterCharacter`, tag, `hurt` (a função única de dano) |
| `src/server/Services/CosmeticService.luau` | Skin equipada de cada jogador |
| `src/server/Services/DevBonecoService.luau` | Comandos de teste (só no Studio) |
| `src/character/` | `Animate` e `Health` vazios, para o Roblox não colocar os scripts padrão |

## Ajustar tamanho e animações

Tudo fica em `src/shared/BonecoConfig.luau`. Mudou um número, salvou, e o Rojo sincroniza.

**Visual (studs)**

| Campo | O que muda |
|---|---|
| `BODY_WIDTH`, `BODY_HEIGHT`, `BODY_DEPTH` | Tamanho do corpo |
| `CORNER_RADIUS` | Quanto os cantos são arredondados (vista de cima) |
| `OUTLINE` | Espessura do contorno |
| `OUTLINE_DROP` | Quanto o topo do contorno fica abaixo do topo do corpo |
| `EYE_DIAMETER`, `EYE_X`, `EYE_Z` | Tamanho e posição dos olhos (`EYE_Z` negativo = para a frente) |
| `SHINE_FRACTION` | Tamanho do brilho branco do olho (fração do olho) |
| `HAND_DIAMETER`, `HAND_X`, `HAND_Y`, `HAND_Z` | Tamanho e posição das mãos |
| `HAND_OUTLINE_DROP` | Quanto o contorno da mão fica abaixo da mão |
| `NAME_HEIGHT` | Altura do nome acima do centro do corpo |

**Corpo simulado (studs)**

| Campo | O que muda |
|---|---|
| `ROOT_WIDTH`, `ROOT_HEIGHT`, `ROOT_DEPTH` | Tamanho do colisor (o hitbox) |
| `HIP_HEIGHT` | Altura do colisor acima do chão |
| `HEAD_HEIGHT` | Altura da `Head` invisível: é onde o balão do chat aparece |
| `VISUAL_OFFSET_Y` | Desloca o boneco visual para cima/baixo em relação ao colisor |

Com os valores atuais o centro do colisor fica a `HIP_HEIGHT + ROOT_HEIGHT / 2 = 1` stud do chão, que é o centro do corpo visual. Se mudar `HIP_HEIGHT` ou `ROOT_HEIGHT`, ajuste `VISUAL_OFFSET_Y` para o boneco continuar encostando no chão.

**Andar e parado**

| Campo | O que muda |
|---|---|
| `WALK_SPEED_REF` | Velocidade (studs/s) considerada "andando a toda" |
| `STEP_RATE` | Ritmo dos passos (rad por stud andado) |
| `BOB_HEIGHT` | Altura do quique ao andar |
| `HAND_SWAY` | Quanto as mãos balançam para frente e para trás ao andar |
| `BREATHE_HEIGHT`, `BREATHE_PERIOD` | Sobe e desce das mãos parado, e o tempo de uma respiração (s) |
| `SPEED_SMOOTHING` | Rapidez da troca entre parado e andando (maior = mais rápido) |

**Golpe e soco**

| Campo | O que muda |
|---|---|
| `SWING_PERIOD` | Duração de um golpe, ida + volta (s) |
| `SWING_ATTACK_FRACTION` | Parte do golpe gasta na ida (o resto é a volta, mais lenta) |
| `SWING_REST_ANGLE` | Ângulo (graus) da ferramenta para fora, em repouso |
| `SWING_ARC` | Quanto (graus) a mão da ferramenta gira no golpe |
| `OTHER_HAND_RECOIL` | Quanto a outra mão recua durante o golpe |
| `PUNCH_DISTANCE` | Alcance do soco de mão vazia |

**Desempenho e expressões**

| Campo | O que muda |
|---|---|
| `ANIM_RANGE` | Bonecos mais longe que isso da câmera só seguem a posição, sem animar (e o nome some) |
| `HURT_RECENT` | Um `HurtAt` mais velho que isso (s) não mostra a careta (ex.: chegou pelo streaming) |
| `MAX_DT` | Limite do passo de tempo: um quadro travado não faz a animação pular |

Depois de mexer em animação, rode `bash scripts/check.sh`: os testes de `BonecoAnim` conferem que as curvas continuam certas.

## Adicionar uma skin de corpo

1. Uma entrada em `src/shared/Defs/Cosmetics.luau`:

```lua
body_frost = {
	id = "body_frost",
	nameKey = "cosmetic.body_frost",
	slot = "body",
	body = {
		bodyColor = "#EAF4FB",
		outlineColor = "#5B6C8F",
		handColor = "#A8D8F0", -- opcional; sem ele, as mãos usam bodyColor
		eyeColor = "#1B2A4A", -- opcional; sem ele, os olhos são #111111
	},
},
```

2. O texto em `src/shared/Strings/ptBR.luau`: `["cosmetic.body_frost"] = "Geada",`.

Pronto. A validação no boot confere o id, o slot, as cores (`#RRGGBB`) e o texto. Ids de cosmético têm no máximo 50 caracteres (vão num atributo).

Se uma skin for removida num update e alguém ainda estiver com ela, o boneco usa a skin padrão do slot (`CosmeticSlots.body.default`) e aparece um aviso no Output.

## Adicionar uma expressão

Uma entrada em `src/shared/Defs/Expressions.luau`. Fica ativa a de **maior prioridade** entre as que estão valendo agora (`hurt` 100 > `blink` 10 > `neutral` 0).

| `trigger` | Quando vale | Campos |
|---|---|---|
| `"always"` | sempre (a base; existe exatamente uma) | — |
| `"periodic"` | de tempos em tempos (cada boneco sorteia o seu) | `duration`, `intervalMin`, `intervalMax` |
| `"event"` | por `duration` segundos depois do evento | `event`, `duration` |
| `"condition"` | enquanto um atributo está abaixo/acima de um limiar | `condition = { attribute, below?, above? }` |

Estilos de olho (`eyes`): `"open"`, `"closed"`, `"squeeze"` ("> <"). Opcional: `flash = { color = "#RRGGBB", duration = s }` pinta corpo e mãos nessa cor (só funciona em expressões de evento).

Exemplo: olhos fechados quando o frio fica abaixo de 35:

```lua
cold = {
	id = "cold",
	priority = 50, -- ganha do piscar, perde do dano
	eyes = "closed",
	trigger = "condition",
	condition = { attribute = "Cold", below = 35 },
},
```

O atributo da condição é lido no **Player** do personagem (onde ficam as barras de status) ou, nos bonecos de teste, no próprio modelo.

Hoje o único evento é `"hurt"` (disparado pelo `HurtAt`). Um evento novo precisa de código no `BonecoRenderer`. Um estilo de olho novo (ex. `"wink"`) também: o nome em `Validate.EYE_STYLES` e o desenho em `BonecoModel` (`buildEye`).

## Comandos de teste (Studio)

O `DevBonecoService` cria três comandos em `ServerStorage` (só no Studio). Use na barra de comandos do **servidor**:

```lua
local SS = game:GetService("ServerStorage")
local player = game.Players:GetPlayers()[1]

SS.DevHurt:Invoke(player, 10) -- dano: "> <", flash vermelho e -10 de vida
print(SS.DevCosmetic:Invoke(player, "body_ember")) -- troca a skin (false se o id não existe)
SS.DevCosmetic:Invoke(player, "body_default") -- volta à padrão
print(SS.DevCrowd:Invoke(30)) -- 30 bonecos de teste em círculo em volta de (0, 0, 40)
SS.DevCrowd:Invoke(0) -- apaga os bonecos de teste
```

Os bonecos do `DevCrowd` andam em círculo, alternam o golpe (1,5 s batendo, 1,5 s parado), trocam a picareta a cada 6 s e levam dano de vez em quando. São criados no servidor, então testam a replicação de verdade. Para medir o custo, abra o MicroProfiler (Ctrl+F6) com 30 bonecos.

Para testar com dois jogadores: aba Test → Clients and Servers → 2 Players.
