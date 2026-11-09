# Skins no jogo (do Blender ao Roblox)

Como uma skin exportada do Blender (corpo, livro, mochila ou caixa) passa a funcionar no jogo. A modelagem está em `skins-modelagem.md`.

## Passo a passo de um lote novo

1. **Exportar** no Blender (`export_roblox.py`): sai uma pasta em `assets/skins/roblox/<categoria>/` com o FBX geral, os individuais, a paleta e o `manifest.json`.
2. **Gerar o manifest do jogo:** acrescente a pasta em `CATEGORIAS` no `scripts/gen-skin-manifest.py` e rode `python scripts/gen-skin-manifest.py` (depois `stylua src/shared/Defs/SkinManifest.luau`). Ele refaz o `src/shared/Defs/SkinManifest.luau` inteiro: o centro de cada malha nos eixos do Roblox, o papel (corpo, mão, livro, mochila, caixa, peça animada) e o tipo (sólido, neon, translúcido). Não editar o arquivo à mão.
3. **Cadastrar** cada skin em `src/shared/Defs/Cosmetics.luau` (id, `nameKey`, slot, raridade e as cores de reserva) e o nome em `src/shared/Strings/ptBR.luau` (`cosmetic.<id>`). O teste `tests/skinmanifest.spec.luau` acusa malha sem cadastro e skin de corpo ou caixa sem malha.
4. **Importar no Studio** o FBX geral (File > Import) e deixar no Workspace.
5. **Organizar:** ao dar Play no Studio o jogo organiza sozinho, mas para salvar no place rode `scripts/studio/import-skins.luau` na barra de comandos (modo Editar). As malhas vão para `ReplicatedStorage.Assets.Skins|Books|Bags|Crates/<id>/<peça>`, com neon e transparência acertados, e o modelo importado sai do Workspace.
6. **Salvar e publicar o place** (as malhas ficam no place, não no Rojo).

## Caixas (09/11)

As 64 caixas (`assets/skins/roblox/caixas/`, catálogo em `assets/skins/lotes/caixas_catalogo.py`) viram `Assets.Crates/<id>`, um modelo inteiro com o pivô no chão, no meio da caixa. O `CrateModel` clona esse modelo para a caixa do mundo (quando o jogador morre) e para as prévias do menu; sem o modelo, cai na caixa de cores antiga (`crate = { bodyColor, bandColor }` no cadastro). As caixas de mob (lobo, coelho...) continuam a de cores.

Diferente do corpo e da mochila, a caixa é montada uma vez só: o gerador soma o deslocamento do pivô de cada peça ao centro dela (`MONTADAS` no script) e o organizador já grava a correção de frente na peça (atributo `SkinCorrectionBaked`, para não girar de novo).

**Peças animadas:** as caixas Vento e Vórtice têm peças com papel `anim_*`. Quem diz como cada uma se mexe é `src/shared/Models/CrateMotion.luau` (testado em `tests/cratemotion.spec.luau`):

| Papel | Movimento |
|---|---|
| `anim_rotor`, `anim_espiral` | Giram no eixo vertical do meio da caixa (~1 volta a cada 5 s) |
| `anim_anel` | Gira mais devagar, ao contrário |
| `anim_pena_NN`, `anim_nuvem_NN`, `anim_cristal_NN` | Flutuam para cima e para baixo (0,1 stud), fora de compasso |

`src/client/World/CrateAnimator.luau` aplica isso só no cliente: nas caixas do mundo (tag `Crate`) e na prévia grande do menu (`CratePreview`). Os quadradinhos da grade ficam parados. Caixa nova com peça animada só precisa do papel `anim_<grupo>` (e, se for um movimento novo, de uma linha no `CrateMotion`).

**Raridades:** as 58 caixas novas estão como Comum (1); as 6 antigas mantiveram a delas. As 80 skins de corpo dos lotes 11 a 16 também estão Comum, até o Elizeu definir.

## Skins animadas e mochilas com efeito (09/11)

São as 9 skins dos pacotes do lançamento: **Gelo** (Dragão, Tomo de Gelo, Cubo de Gelo), **Abissal** (Polvo, Tomo Abissal, Mochila Caranguejo) e **Floresta** (Toco da Floresta, Tomo Trepadeira, Cubos de Esmeralda).

**Corpo e livro: peças que se mexem.** O desenho aprovado não muda: `assets/skins/skin_animacao.py` só separa as peças que se mexem em grupos com um pivô (a junta), e o export as tira em malhas próprias `<id>_anim_<grupo>`.

| Skin | Peças | Parado | Andando |
|---|---|---|---|
| Dragão (`body_dragao`) | `asa_dir`, `asa_esq`, `rabo` | asas abrem e fecham devagar, rabo balança | asas batem a cada passo, rabo serpenteia |
| Polvo (`body_polvo`) | `tentaculo_01` a `07` | tentáculos ondulam um depois do outro | remam mais forte a cada passo |
| Toco da Floresta (`body_toco`) | `raiz_01` a `06`, `broto_esq`, `broto_dir` | brotos balançam com a brisa | raízes pisam como pernas (pares em diagonal), brotos chacoalham |
| Tomo de Gelo (`book_gelo`) | `floco`, `cristal_01` a `04` | floco gira, cristais pulsam para fora e torcem | igual |
| Tomo Abissal (`book_tentaculo`) | `espiral`, `ponta` | redemoinho gira, ponta do tentáculo se enrola | igual |
| Tomo Trepadeira (`book_trepadeira`) | `folha_01` a `12`, `flor_01`, `flor_02` | folhas tremulam, flores balançam | igual |

- **Movimento:** `src/shared/Models/SkinMotion.luau` (testado em `tests/skinmotion.spec.luau`): ondas por eixo, no tempo quando parado e na fase dos passos do `BonecoAnim` quando anda, trocando suave pela fração de velocidade.
- **No boneco:** `SkinAssets.clonePart` põe a peça no lugar pelo `pivot` do manifest, e `SkinAssets.attachPart` a prende num `Motor6D` (`SkinAnimJoint`) no pivô, no corpo (`BonecoModel`) ou no livro na mão (`ToolModel`). O `client/Boneco/SkinAnimator` escreve o `Transform` dessas juntas a cada quadro (`BonecoRenderer`). Nas prévias do menu (ViewportFrame) as peças ficam paradas na pose de descanso.
- **Exportar:** `blender -b --factory-startup --python assets/skins/export_roblox.py -- corpo_animado livros_animados` gera `assets/skins/roblox/corpo_animado/` e `livros_animados/` só com essas 6 skins. O `gen-skin-manifest.py` usa essas versões no lugar das paradas (`SUBSTITUTAS`) e grava o `pivot` de cada peça animada.
- **Importar no Studio:** os dois FBX gerais (`skins-corpo_animado.fbx`, `skins-livros_animados.fbx`) por cima do que já existe; o organizador troca `body_dragao_corpo` etc. pelas versões sem as peças soltas e põe as peças `_anim_` na mesma pasta.
- **Prévia no Blender:** `assets/skins/animadas/skins-animadas.blend` (quadros 1–144 parado, 145–240 andando). Refazer: `lune run scripts/skin-motion-preview` (amostra o `SkinMotion` em `animadas/movimentos.json`) e rodar `assets/skins/preview_animacao.py` no Blender aberto. Mexer no movimento = mexer no `SkinMotion.luau`; a prévia só copia.
- **Skin nova com peça animada:** grupo novo no `ANIM` do `skin_animacao.py` (peças pelo número do fim do nome e o pivô), a skin no `FILTRO` do export e o movimento no `SkinMotion`.

**Mochilas: efeitos ao andar.** `src/shared/BagFxConfig.luau` (testado em `tests/bagfx.spec.luau`) descreve os emissores de cada mochila e `client/Boneco/BagFx` os monta no meio da mochila. A quantidade acompanha a velocidade; parado, nada sai. As partículas ficam no mundo e viram rastro.

| Mochila | Efeito |
|---|---|
| Cubo de Gelo | flocos de neve girando, geada no chão, faíscas frias |
| Mochila Caranguejo | bolhas subindo, respingos de água |
| Cubos de Esmeralda | vaga-lumes verdes, faíscas místicas, folhinhas caindo, névoa verde no chão |

Texturas brancas (o emissor tinge) em `assets/skins/vfx/`, geradas por `gerar_texturas.py` e enviadas na conta do Elizeu (ids em `BagFxConfig.TEXTURES`).
