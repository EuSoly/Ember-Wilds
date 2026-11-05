# Skins de corpo, livro e mochila para Roblox

Gerado por `assets/skins/export_roblox.py` a partir dos lotes aprovados (`assets/skins/lotes/`). Para refazer depois de mudar uma skin, rode na raiz do projeto:

```
blender -b --factory-startup --python assets/skins/export_roblox.py
```

O Blender aberto não é tocado. As três pastas (`corpo/`, `livros/` e `mochilas/`) são recriadas inteiras.

## Importar

No Roblox Studio, use **File > Import**:

- `corpo/skins-corpo.fbx`: as 100 skins de corpo, na disposição de galeria.
- `livros/skins-livros.fbx`: os 20 livros.
- `mochilas/skins-mochilas.fbx`: as 81 mochilas (50 modelos base + 31 variantes de cor).
- `*/individual/<id>.fbx`: uma skin por arquivo, com a origem no pivô dela. É o melhor jeito de importar para `Assets`.

A textura de paleta (`corpo_palette.png`, `livros_palette.png`, `mochilas_palette.png`) vai embutida nos FBX. Se o Studio não carregar a textura, importe o PNG como imagem e ponha o ID no `TextureID` das MeshParts.

## O que vem em cada skin

**Corpo**, id `body_<nome>`, por exemplo `body_lobo`:

| Malha | O que é | Origem (pivô) |
|---|---|---|
| `body_<nome>_corpo` | Corpo, contorno, silhueta e desenho do topo | Centro do corpo: 1 stud acima do chão, igual ao `BonecoConfig` |
| `body_<nome>_mao` | Mão **direita**: esfera, contorno e enfeites da mão | Centro da mão direita (`+X`) |
| `body_<nome>_mao_esq` | Mão **esquerda** já espelhada em X com normais corrigidas | Centro da mão esquerda (`-X`) |
| `..._neon` | Partes que brilham | Mesmo pivô da peça de origem |
| `..._translucido` | Partes semitransparentes | Mesmo pivô da peça de origem |

Os **olhos não vêm** no arquivo: continuam sendo do código (piscar, cara de dor).

**Livro**, id `book_<nome>`: a malha `book_<nome>_livro`, com origem no centro do livro, e mais as peças `_neon` quando houver. Tamanho e orientação são os do `Assets.Tools.book` (2,37 × 0,53 × 2,68, capa para cima).

**Mochila**, id `bag_<nome>`: a malha `bag_<nome>_mochila` (e `_neon` quando houver), com origem no centro do `root` do boneco (1 stud acima do chão), já posicionada nas costas (`+Z` no Roblox / `-Y` no Blender), pronta para o `BagModel.attach`. Os objetos `PREVIEW_*` do boneco fantasma são ignorados na exportação.

**Eixos:** a frente do boneco e o topo do livro (+Y no Blender) viram -Z no Roblox, que é a frente, e a mão direita fica em +X. O Z do Blender vira o Y do Roblox. A escala é 1 stud = 1 unidade.

## Ajustes no Studio depois de importar

O FBX não carrega material Neon nem transparência. Ajuste à mão, ou pelo script de import:

| Malha | Ajuste |
|---|---|
| `body_chama_corpo_neon`, `body_chama_mao_neon`, `body_chama_mao_esq_neon`, `body_anjo_corpo_neon`, `body_vela_corpo_neon`, `body_vela_mao_neon`, `body_vela_mao_esq_neon`, `body_bomba_corpo_neon`, `body_bomba_mao_neon`, `body_bomba_mao_esq_neon`, `body_fenix_corpo_neon`, `body_espirito_gelo_corpo_neon`, `body_espirito_gelo_mao_neon`, `body_espirito_gelo_mao_esq_neon`, `body_wyvern_gelo_corpo_neon`, `body_robo_corpo_neon`, `body_robo_mao_neon`, `body_robo_mao_esq_neon`, `book_lava_livro_neon`, `book_orbe_livro_neon`, `bag_vulcao_mochila_neon`, `bag_fornalha_mochila_neon`, `bag_cofre_metal_mochila_neon`, `bag_rocha_magma_mochila_neon` | `Material = Neon` |
| `body_abelha_corpo_translucido` | `Transparency = 0.25` |
| `body_slime_corpo_translucido` | `Transparency = 0.1` |
| `body_slime_mao_translucido`, `body_slime_mao_esq_translucido` | `Transparency = 0.3` |

O `manifest.json` também traz esses dados por peça: `tipo` e `alpha`.

## Números

| | Corpo | Livros | Mochilas |
|---|---|---|---|
| Skins | 100 | 20 | 81 (50 base + 31 variantes) |
| Malhas | 322 | 22 | 85 |
| Triângulos (total) | 627.212 | 41.530 | 85.168 |
| Média por skin | 6.272 | 2.076 | 1.051 |
| Maior skin | 12.816 | 3.000 | 2.264 |
| Cores / textura | 601 / 512 × 512 | 140 / 256 × 256 | 413 / 512 × 512 |

Para ficarem leves, as curvas saem com metade da resolução do arquivo editável (`RES_EXPORT = 4`). Peças acima de um teto passam por Decimate: 5.000 triângulos no corpo, 1.500 na mão e 3.000 no livro/mochila. Isso afetou 114 peças de corpo, 8 livros e 0 mochilas. O `manifest.json` guarda os triângulos antes e depois.

## Arquivos

- `skins-*-export.blend`: só as malhas de exportação, com a textura embutida. É igual ao FBX.
- `manifest.json`: ids, peças, papel, tipo, alpha, deslocamento de cada peça até o pivô da skin, triângulos e dimensões.
- `validation.json`: reimportação no Blender do FBX geral e de todos os individuais (204 arquivos no total), conferindo nomes, triângulos, UV, textura e dimensões. Tudo passou (`validacao_ok: true`).

Para usar estes modelos no jogo, importe-os para `ReplicatedStorage.Assets.Skins.<id>`, `Assets.Books.<id>` e `Assets.Bags.<id>`.

Referências oficiais: [Importador do Studio](https://create.roblox.com/docs/studio/importer) e [configuração do Blender para Roblox](https://create.roblox.com/docs/art/blender).
