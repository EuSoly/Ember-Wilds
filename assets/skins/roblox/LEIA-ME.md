# Skins de corpo e de livro para Roblox

Gerado por `assets/skins/export_roblox.py` a partir dos lotes aprovados (`assets/skins/lotes/`). Para refazer depois de mudar uma skin, rode na raiz do projeto:

```
blender -b --factory-startup --python assets/skins/export_roblox.py
```

O Blender aberto não é tocado. As duas pastas são recriadas inteiras.

## Importar

No Roblox Studio, use **File > Import**:

- `corpo/skins-corpo.fbx`: as 50 skins de corpo, na disposição de galeria.
- `livros/skins-livros.fbx`: os 20 livros.
- `*/individual/<id>.fbx`: uma skin por arquivo, com a origem no pivô dela. É o melhor jeito de importar para `Assets`.

A textura de paleta (`corpo_palette.png`, `livros_palette.png`) vai embutida nos FBX. Se o Studio não carregar a textura, importe o PNG como imagem e ponha o ID no `TextureID` das MeshParts.

## O que vem em cada skin

**Corpo**, id `body_<nome>`, por exemplo `body_lobo`:

| Malha | O que é | Origem (pivô) |
|---|---|---|
| `body_<nome>_corpo` | Corpo, contorno, silhueta e desenho do topo | Centro do corpo: 1 stud acima do chão, igual ao `BonecoConfig` |
| `body_<nome>_mao` | Mão **direita**: esfera, contorno e enfeites da mão | Centro da mão, para o código pôr em cada mão; para a esquerda, espelhar ou reaproveitar |
| `..._neon` | Partes que brilham | Mesmo pivô da peça de origem |
| `..._translucido` | Partes semitransparentes | Mesmo pivô da peça de origem |

**Pendente:** ainda não há mão esquerda. O Roblox não espelha MeshPart, então girar a direita deixa enfeites assimétricos apontando para o lado errado. O próximo export vai trazer `body_<nome>_mao_esq` já espelhada (veja `docs/guia/skins-modelagem.md`, "Pendente: mão esquerda").

Os **olhos não vêm** no arquivo: continuam sendo do código (piscar, cara de dor). A mão esquerda da prévia também não vem.

**Livro**, id `book_<nome>`: a malha `book_<nome>_livro`, com origem no centro do livro, e mais as peças `_neon` quando houver. Tamanho e orientação são os do `Assets.Tools.book` (2,37 × 0,53 × 2,68, capa para cima).

**Eixos:** a frente do boneco e o topo do livro (+Y no Blender) viram -Z no Roblox, que é a frente, e a mão direita fica em +X. O Z do Blender vira o Y do Roblox. A escala é 1 stud = 1 unidade. (A primeira exportação, de 05/11, saiu girada 180°; as cópias já importadas no Studio foram giradas por script, e o export foi corrigido para `axis_forward = -Z`.)

## Ajustes no Studio depois de importar

O FBX não carrega material Neon nem transparência. Ajuste à mão, ou pelo script de import:

| Malha | Ajuste |
|---|---|
| `body_chama_corpo_neon`, `body_chama_mao_neon`, `body_anjo_corpo_neon`, `body_vela_corpo_neon`, `body_vela_mao_neon`, `body_bomba_corpo_neon`, `body_bomba_mao_neon`, `body_fenix_corpo_neon`, `book_lava_livro_neon`, `book_orbe_livro_neon` | `Material = Neon` |
| `body_abelha_corpo_translucido` | `Transparency = 0.25` |
| `body_slime_corpo_translucido` | `Transparency = 0.1` |
| `body_slime_mao_translucido` | `Transparency = 0.3` |

O `manifest.json` também traz esses dados por peça: `tipo` e `alpha`.

## Números

| | Corpo | Livros |
|---|---|---|
| Skins | 50 | 20 |
| Malhas | 111 | 22 |
| Triângulos (total) | 271.268 | 41.530 |
| Média por skin | 5.425 | 2.076 |
| Maior skin | 11.160 | 3.000 |
| Cores / textura | 287 / 512 × 512 | 140 / 256 × 256 |

Para ficarem leves, as curvas saem com metade da resolução do arquivo editável (`RES_EXPORT = 4`). Peças acima de um teto passam por Decimate: 5.000 triângulos no corpo, 1.500 na mão e 3.000 no livro. Isso afetou 52 peças de corpo e 8 livros. O `manifest.json` guarda os triângulos antes e depois. A conferência visual da versão exportada está em `*/preview.png`.

## Arquivos

- `skins-*-export.blend`: só as malhas de exportação, com a textura embutida. É igual ao FBX.
- `manifest.json`: ids, peças, papel, tipo, alpha, deslocamento de cada peça até o pivô da skin, triângulos e dimensões.
- `validation.json`: reimportação no Blender do FBX geral e de todos os individuais (71 arquivos), conferindo nomes, triângulos, UV, textura e dimensões. Tudo passou.

Não houve importação de verdade no Roblox Studio nem upload. O `BonecoModel` ainda monta o boneco por cores. Para usar estes modelos, falta o passo de integração: importar para `ReplicatedStorage.Assets.Skins.<id>` e `Assets.Books.<id>`, e fazer o código usar o modelo quando ele existir.

Referências oficiais: [Importador do Studio](https://create.roblox.com/docs/studio/importer) e [configuração do Blender para Roblox](https://create.roblox.com/docs/art/blender).
