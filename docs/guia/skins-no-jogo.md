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
