# Modelos dos mobs

Os 23 mobs foram modelados pelo Elizeu no Blender (`assets/npcs/rabbit/coelho-v1.blend`, cena `NPC_Catalog_23`) e importados no Studio em 01/11. São "adesivos" em camadas vistos de cima, no estilo do Starve: cada parte do corpo tem 2–3 camadas de cor (`_rim`, `_color`, `_edge`…).

## Onde ficam

`ReplicatedStorage.Assets.Mobs.<id>`, **só no place** (como `Assets.Tools`): o Rojo não mexe em `ReplicatedStorage.Assets`. Salve o place depois de mexer neles.

`ServerStorage.NpcsImportBackup` guarda a importação original, antes da limpeza. Não apague até as juntas estarem aprovadas.

| id | Mob | id | Mob |
|---|---|---|---|
| `rabbit` | Coelho | `crab` | Caranguejo |
| `wolf` | Lobo | `king_crab` | Caranguejo-rei |
| `spider` | Aranha | `gmo_piranha` | Piranha transgênica |
| `boar` | Javali | `kraken` | Kraken |
| `hawk` | Falcão | `lava_monster` | Monstro de lava |
| `penguin` | Pinguim | `baby_lava_dragon` | Filhote de dragão de lava |
| `arctic_fox` | Raposa-do-ártico | `lava_dragon` | Dragão de lava |
| `polar_bear` | Urso-polar | `vulture` | Abutre |
| `baby_mammoth` | Filhote de mamute | `sandworm` | Verme da areia |
| `mammoth` | Mamute | `golden_hen` | Galinha dourada |
| `baby_dragon` | Filhote de dragão | `golden_chick` | Pintinho dourado |
| `dragon` | Dragão | | |

## Como cada modelo está (limpeza de 01/11)

- **Eixos**: frente = −Z, cima = +Y, direita do mob = +X (`RightVector`). Não precisa girar nada.
- **Pivot do modelo**: centro da caixa do modelo em X/Z, no chão (Y do ponto mais baixo), sem rotação.
- **Peças**: todas `MeshPart`, cor sólida, sem textura, `Anchored = true`, `CanCollide`/`CanQuery`/`CanTouch = false`, `Massless = true`. São só visuais: o jogo move o modelo inteiro com `PivotTo`.
- **Nomes das peças**: os do Blender sem o prefixo do mob (`Rabbit__Ear_R_pink` → `Ear_R_pink`). Os `.001` do Blender continuam.
- **Tamanho**: o importador aumentou ~4,1× as medidas do Blender (o coelho tem 9,5 × 12,9 studs; o corpo do jogador, 3,6). O tamanho em jogo vai vir dos dados de cada mob (`Model:ScaleTo` ao criar), não de reescalar o modelo.

## Juntas (contrato para as animações)

As animações vão ser feitas em código, girando e movendo grupos de peças (como o `BonecoAnim` do jogador). Para isso, cada modelo segue esta estrutura:

```
Assets.Mobs.<id>            Model, pivot no chão (acima)
  Body                      Model, único filho; pivot = o do mob
    <camadas do corpo>      MeshParts que não mexem sozinhas
    Head                    Model, pivot no pescoço (se a cabeça for separada do corpo)
      <camadas da cabeça>   olhos, brilhos, focinho, dentes, chifres…
      Ear_L, Ear_R          Model, pivot na base da orelha
    Wing_L, Wing_R          Model, pivot no ombro
    Tail                    Model, pivot na base da cauda
    …
```

Regras:

1. **Toda MeshPart fica em exatamente um grupo** (um `Model`). O modelo do mob só tem `Body` como filho.
2. **Um grupo por parte que mexe sozinha**: orelha, asa, perna, pata, garra, nadadeira, cauda, tromba, mandíbula, braço, cabeça (quando separada do corpo). As camadas de cor dessa parte vão juntas no grupo. O que só acompanha (olho, brilho, dente, presa, chifre, ventosa) fica no grupo de quem carrega.
3. **Grupos encaixados**: o grupo fica dentro do grupo em que ele se prende (orelha dentro de `Head`, ventosa dentro do braço). Mexer o pai leva os filhos.
4. **Pivot do grupo = a junta**: em X/Z, o ponto onde a parte se prende no pai (base da orelha, ombro da asa, raiz da perna). Em Y, a meia altura das camadas do grupo. **Sem rotação** (alinhado aos eixos do mob): o código gira em volta do Y local.
5. **Nomes**: `PascalCase` em inglês; lado com `_L`/`_R`, sendo **R = +X** (direita do próprio mob, olhando para −Z). Os `L`/`R` do Blender seguem a imagem de cima e podem estar trocados (o `Ear_R_*` do coelho está em −X). Vários iguais: numerar a partir da frente, no sentido horário visto de cima (`Leg_L1`…`Leg_L4`, `Arm_1`…`Arm_8`).
6. **Nada se mexe**: agrupar e mudar pivot não muda posição, tamanho, cor nem malha de nenhuma peça.

Mobs que no Starve são quase só uma cabeça (lobo, raposa, urso-polar) podem ter poucos grupos: a animação deles é do corpo inteiro (balançar, inclinar, investir, piscar no dano).

## Juntas por mob

Montadas no Studio e **aprovadas pelo Elizeu em 01/11/2026**, com as ressalvas abaixo. Backup anterior ao agrupamento: `ServerStorage.MobsAntesDasJuntas` (23 modelos / 618 MeshParts). `ServerStorage.NpcsImportBackup` foi preservado.

Todos têm apenas `Body` na raiz. Na tabela, os grupos são filhos de `Body`, exceto quando o caminho indica outro pai. `Body` mantém o pivot original no chão; os demais usam a meia altura das suas camadas. Os números abaixo são X/Z em studs, relativos ao pivot do mob; `±` corresponde a L negativo e R positivo. A relação completa de peças e pivôs XYZ está em [`mob-joints-plan.json`](../../scripts/studio/mob-joints-plan.json).

| Mob | Grupos além de Body | Local das juntas / composição |
|---|---|---|
| `rabbit` | `Ear_L`, `Ear_R` | Bases das orelhas: (±2,400; 0,320). Rim, color e pink juntos. O grupo L contém as peças originais `Ear_R_*`, pois estão em −X. |
| `wolf` | Nenhum | A silhueta da cabeça inclui as orelhas; os interiores são detalhes da mesma cabeça. |
| `spider` | `Head`, `Leg_L1`…`Leg_L4`, `Leg_R1`…`Leg_R4` | Pescoço (0; −2,100). Raízes das pernas: X ±2,300, Z −1,695 / −0,667 / 0,361 / 1,389, da frente para trás. Olhos em Head; marca vermelha em Body. |
| `boar` | `Head`, `Head/Ear_L`, `Head/Ear_R` | Pescoço (0; 0,050); orelhas (±2,900; −0,100). Focinho, presas e olhos acompanham Head; crina acompanha Body. |
| `hawk` | `Head`, `Wing_L`, `Wing_R`, `Tail` | Pescoço (0; −3,857), ombros (±2,284; −1,686), leque da cauda (0; 2,677). Cada asa leva suas penas superiores e do ombro. |
| `penguin` | `Wing_L`, `Wing_R` | Bases das nadadeiras/asas (±2,450; −0,450). Rosto e bico integram Body. |
| `arctic_fox` | Nenhum | Orelhas incorporadas à silhueta da cabeça, como no lobo. |
| `polar_bear` | `Ear_L`, `Ear_R` | Bases (±3,500; 3,800); todas as camadas e interior juntos. Cabeça, focinho e nariz em Body. |
| `baby_mammoth` | `Ear_L`, `Ear_R`, `Trunk` | Orelhas (±1,287; 1,398), tromba (0; −0,367). As três dobras seguem a tromba; presas ficam em Body. |
| `mammoth` | `Ear_L`, `Ear_R`, `Trunk` | Orelhas (±2,233; 2,741), tromba (0; −0,644). Presas e franja acompanham Body. |
| `baby_dragon` | `Head`, `Tail` | Pescoço (0; −2,904), cauda (0; 2,460). Faixa dorsal e espinhos em Body; não há malhas de asas. |
| `dragon` | `Head`, `Wing_L`, `Wing_R`, `Tail` | Pescoço (0; −4,278), ombros (±4,501; −1,499), cauda (0; 3,505). Chifres, dentes e focinho em Head; membrana junto de cada asa. |
| `crab` | `Leg_L1`…`Leg_L3`, `Leg_R1`…`Leg_R3`, `Claw_L`, `Claw_R` | Pernas de frente para trás: (±2,420; 0,242), (±2,279; 1,347), (±2,164; 2,453). Pinças aproximadamente (±2,841; −1,586), no lado interno voltado à carapaça. |
| `king_crab` | `Leg_L1`…`Leg_L3`, `Leg_R1`…`Leg_R3`, `Claw_L`, `Claw_R` | Pernas: (±3,293; 0,334), (±3,097; 1,865), (±2,939; 3,396). Pinças aproximadamente (±3,934; −2,196). Crista e espinhos da carapaça em Body. |
| `gmo_piranha` | `Fin_L`, `Fin_R`, `DorsalFin`, `Tail`, `Jaw` | Nadadeiras (±2,824; −1,897), dorsal (0; −0,548), cauda (0; 1,615), placa da boca (0; −3,282). Os sete dentes acompanham Jaw. |
| `kraken` | `Arm_1`…`Arm_8`, `Mouth` | Raízes dos braços em círculo de raio 3,900; Arm_1 na frente (−Z), seguindo em direção a +X, +Z, −X. Cada braço leva suas três ventosas. Boca (0; −1,378), com placa, borda e dez dentes. |
| `lava_monster` | Nenhum | Chamas e rosto são camadas sobrepostas, sem pescoço ou membros separados. |
| `baby_lava_dragon` | `Head`, `Tail` | Mesmas juntas do baby_dragon. Não há asas separadas. |
| `lava_dragon` | `Head`, `Wing_L`, `Wing_R`, `Tail` | Pescoço (0; −4,487), ombros (±4,711; −1,597), cauda (0; 3,665). Faixa dorsal e espinhos em Body. |
| `vulture` | `Head`, `Wing_L`, `Wing_R`, `Tail` | Pescoço (0; −3,016), ombros (±1,787; −1,319), cauda (0; 2,094). As penas seguem a asa correspondente. |
| `sandworm` | `Jaw_1`…`Jaw_4` | Raízes no raio 2,850, na ordem −Z, +X, +Z, −X. Cada mandíbula leva rim/color, triângulo, oito dentes e três escamas. Boca central e seus 14 dentes em Body. |
| `golden_hen` | `Head`, `Wing_L`, `Wing_R`, `Tail` | Pescoço (0; −2,651), ombros (±1,570; −1,159), cauda (0; 1,840). O leque inteiro da cauda acompanha Tail. |
| `golden_chick` | `Head`, `Wing_L`, `Wing_R`, `Tail` | Pescoço (0; −1,803), ombros (±1,067; −0,788), cauda (0; 1,251). Y medido nas camadas deste modelo, sem presumir a proporção do adulto. |

Árvores de referência (as MeshParts de cada grupo foram omitidas):

```text
rabbit
└─ Body
   ├─ Ear_L
   └─ Ear_R

spider
└─ Body
   ├─ Head
   ├─ Leg_L1, Leg_L2, Leg_L3, Leg_L4
   └─ Leg_R1, Leg_R2, Leg_R3, Leg_R4

dragon
└─ Body
   ├─ Head
   ├─ Wing_L
   ├─ Wing_R
   └─ Tail

boar
└─ Body
   └─ Head
      ├─ Ear_L
      └─ Ear_R
```

### Verificação das juntas

[`validate-mob-joints.luau`](../../scripts/studio/validate-mob-joints.luau) é um script de leitura para executar no MCP/Command Bar em Edit. Compara os templates com `MobsAntesDasJuntas`, verifica peças, propriedades, hierarquia, lados, rotação e distância às caixas. O resultado de 01/11 está em `build/previews/mob-joints/validation.json` (artefato local).

- **23/23 passaram na verificação estrutural e nas caixas de Model**: 109 grupos e 618 MeshParts; nenhum grupo vazio nem peça perdida.
- Erro máximo de CFrame, tamanho, cor e rotação dos pivôs: **0**. Malha, material, textura e propriedades físicas também preservados.
- Distância máxima do pivot à própria caixa: **0,000238 stud**; à caixa do grupo pai: **0** (limite 0,3). Erro máximo da meia altura: **0,000351 stud** (limite 0,001).
- O teste de caixa do pai usa `GetBoundingBox`, que inclui os filhos. O script também mede as camadas diretamente no pai: somente as quatro mandíbulas do sandworm excedem 0,3 nesse diagnóstico adicional, por **1,295487 stud em Y**. A boca central está acima delas. Isso está separado das verificações estruturais e precisa de revisão visual, não deve ser interpretado como contato entre superfícies.
- Fotos de cima dos 23 antes do agrupamento e dos 23 clones de teste foram conferidas. Cada grupo móvel recebeu +30° em Y ao redor do próprio pivot, pais antes dos filhos; Body não girou. Lobo, raposa e monstro de lava só têm Body e não têm junta independente a girar. Clones removidos ao fim.

Fotos locais do teste de 30°: [coelho](../../build/previews/mob-joints/after-rabbit.jpg), [aranha](../../build/previews/mob-joints/after-spider.jpg), [dragão](../../build/previews/mob-joints/after-dragon.jpg), [kraken](../../build/previews/mob-joints/after-kraken.jpg), [verme](../../build/previews/mob-joints/after-sandworm.jpg). São poses de inspeção, não animações finais.

### Dúvidas e limites visuais para aprovação

| Mobs | Ponto a revisar |
|---|---|
| `crab`, `king_crab` | As pinças são duas camadas de uma peça inteira, sem dedos separados nem braço ligando à carapaça. Já existe um vão na silhueta original, que continua perceptível no giro de 30°. Os pivôs passam no teste de caixas, mas isso não representa uma ligação contínua de malha. A animação possível é balançar a pinça inteira. Fotos antes/depois: `build/previews/mob-joints/{before,after}-crab.jpg` e `{before,after}-king_crab.jpg`. |
| Os quatro dragões | A faixa dorsal é uma malha contínua. Ela e os espinhos ficaram em Body, enquanto Tail leva apenas as camadas da cauda; giros grandes deixam a ponta da faixa sem acompanhar a cauda. Cabeça, asas existentes e cauda continuam presas nas fotos. |
| `sandworm` | A malha representa uma boca com quatro mandíbulas radiais, não um verme segmentado. Não há segmentos para cumprir a ondulação citada no contrato de animações. As mandíbulas permanecem sobrepostas à boca em X/Z no giro, mas há a diferença de altura documentada acima. Mantive Y na meia altura exigida; mover as malhas ou inventar segmentos alteraria o escopo. |
| `gmo_piranha`, `kraken` | Jaw/Mouth são placas inteiras com dentes; girá-las não abre ou fecha uma boca articulada. A pose de ataque precisará respeitar essa composição. |
| `wolf`, `arctic_fox`, `lava_monster` | Somente Body: orelhas incorporadas à silhueta nos dois primeiros e rosto sobreposto às chamas no último. Movimento será do conjunto; separar a malha exigiria outra etapa. |

Nenhuma animação ou número de gameplay foi implementado na etapa de juntas. Parte 2 autorizada pelo Elizeu; manter os modelos salvos no place (Ctrl+S).

## Animações (contrato)

Mesmo caminho do boneco do jogador (`boneco.md`): o **servidor** só tem uma raiz invisível por mob (posição, direção e alguns atributos); **cada cliente** clona o modelo de `Assets.Mobs`, segue a raiz e anima. Ainda não há IA nem dano de mobs: isso é de outra fase. Por enquanto, um comando de teste do Studio cria raízes que andam, atacam, levam dano e morrem, só para ver as animações.

### Arquivos

| Arquivo | O que é |
|---|---|
| `src/shared/Mobs/MobAnim.luau` | Matemática pura das animações (sem APIs do Roblox), testada no Lune como o `BonecoAnim`: `newState()`, `step(state, dt, input) → Pose` |
| `src/shared/Mobs/MobAnimConfig.luau` | Números: gerais (durações, `MAX_DT`, `ANIM_RANGE`) e por mob (`scale` e o jeito de mexer cada grupo). **Mob novo = uma entrada aqui**, sem `if id == "rabbit"` no código |
| `src/client/Mobs/MobVisual.luau` | Um mob na tela: clona `Assets.Mobs.<id>`, aplica `scale` (`Model:ScaleTo`), guarda a posição de repouso de cada grupo e transforma a `Pose` em CFrames |
| `src/client/Mobs/MobRenderer.luau` | O loop (como o `BonecoRenderer`): acha as raízes pela tag, cria/apaga os `MobVisual`, segue a raiz a cada quadro, calcula a velocidade e lê os atributos |
| `src/server/Services/DevMobService.luau` | Só no Studio (como o `DevBonecoService`): `ServerStorage.DevMobs:Invoke(true)` cria as raízes dos 23 mobs numa galeria perto do spawn, em ciclo de parado → andando em círculo → ataque → dano → morte → renasce; `Invoke(false)` apaga |

### Raiz no servidor

- `Part` ancorada, invisível, `CanCollide`/`CanQuery`/`CanTouch = false`, pivot no chão, frente = `LookVector`.
- Tag `StatNames.MobTag` (`"Mob"`) e atributos (nomes em `StatNames`):
  - `MobId` (string): o id em `Assets.Mobs`;
  - `MobAttack` (número): contador, sobe 1 a cada ataque;
  - `MobHurt` (número): contador, sobe 1 a cada dano;
  - `MobDead` (booleano): morreu (a raiz some logo depois).
- Contadores, e não "atacando = true", para o cliente não perder um ataque curto entre dois quadros.

### O que cada estado mostra

A câmera olha de cima, então quase tudo que aparece é **giro em volta do Y, deslocamento em X/Z e escala**. Subir e descer quase não se vê.

- **Parado**: respiração (escala leve) e um balanço pequeno de orelha, cauda e antena.
- **Andando** (pela velocidade da raiz): quique e ginga do corpo; pernas e patas alternando; asas batendo; braços do kraken em onda, com fase diferente em cada um; mandíbulas do verme abrindo e fechando em sequência (o modelo é uma boca com 4 mandíbulas, não tem segmentos). Cauda dos dragões com balanço pequeno: a faixa dorsal fica no corpo e não acompanha a cauda.
- **Ataque** (`MobAttack` subiu): investida curta para a frente e volta; mandíbula, garra ou boca fechando.
- **Dano** (`MobHurt` subiu): tranco para trás e piscar, como no boneco.
- **Morte** (`MobDead`): encolhe e some em ~0,5 s.

### Desempenho

- Um `Workspace:BulkMoveTo` por quadro com todas as peças, não `PivotTo` por grupo (são até 72 peças por mob).
- Mobs além de `ANIM_RANGE` da câmera só seguem a raiz, sem animar.
- `dt` limitado por `MAX_DT`, como no boneco.
- O tamanho (`Size`) das peças só é reescrito quando a escala do grupo anda `SIZE_STEP` (0,2%): a respiração não troca o tamanho de todas as peças a cada quadro.

### Ver no Studio

Play, entre no jogo e, na barra de comandos do **servidor**:

```lua
print(game.ServerStorage.DevMobs:Invoke(true)) -- 23: galeria ao sul do jogador
print(game.ServerStorage.DevMobs:Invoke(false)) -- 0: apaga
```

Cada mob repete um ciclo de 12 s: parado (3 s) → andando em círculo (5 s, ~5 studs/s) → ataque → dano → morte → renasce. Os tempos são só da galeria (`DevMobService`), não de gameplay. Testado em 01/11 com os 23 a 60 fps.

## Ajustar as animações

Tudo fica em `src/shared/Mobs/MobAnimConfig.luau`. Depois de mexer, rode `bash scripts/check.sh`: os testes de `tests/mobanim.spec.luau` conferem que a config bate com as juntas (`scripts/studio/mob-joints-plan.json`) e que as curvas continuam certas.

**Números gerais**

| Nome | O que faz |
|---|---|
| `IDLE_PERIOD`, `BREATHE_SCALE` | Ciclo (s) e tamanho da respiração parado |
| `WALK_PERIOD`, `WALK_SPEED_REF` | Duração de um passo e a velocidade (studs/s) em que a animação de andar chega ao máximo |
| `BODY_SWAY`, `BODY_SHIFT`, `BOB_HEIGHT` | Ginga, balanço lateral e quique do corpo andando |
| `ATTACK_DURATION`, `ATTACK_DISTANCE` | Duração e investida (studs, antes da escala) do ataque |
| `HURT_DURATION`, `HURT_DISTANCE`, `FLASH_COLOR` | Duração, recuo e cor do piscar no dano |
| `DEATH_DURATION` | Tempo para encolher e sumir |
| `ANIM_RANGE`, `MAX_DT`, `SIZE_STEP` | Desempenho (veja acima) |

**Por mob**: `scale` (tamanho em jogo sobre o modelo do place; **0,4 em todos é provisório**, o tamanho final é decisão do Elizeu) e `groups`, um jeito de mexer por grupo:

```lua
Ear_L = group("sway", idle, walk, attack, phase)
```

- `idle`, `walk`, `attack`: graus de giro em volta da junta parado, andando e no ataque.
- `phase`: atraso (radianos). Os lados são espelhados: o mesmo giro abre as duas orelhas, mas leva a pata esquerda para a frente e a direita para trás. Por isso pares simétricos (orelhas, asas) usam `math.pi` no lado R, e as pernas do mesmo par usam a mesma fase.
- Jeitos (`motion`): `sway` (balança), `stride` (perna), `flap` (asa, nadadeira), `wave` (braço do kraken, fase por braço), `radial` (mandíbula do verme: também se afasta do centro, `travel` studs na direção `x`/`z`) e `mouth` (encolhe `close` no ataque).

Mob novo: importar e montar as juntas como acima, depois uma entrada em `Mobs` com os grupos dele. O código não muda.
