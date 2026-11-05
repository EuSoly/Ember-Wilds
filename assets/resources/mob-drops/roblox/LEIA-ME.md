# Mob Drops para Roblox

## Importar

No Roblox Studio, use **File > Import 3D** e selecione `mob-drops.fbx`. O arquivo contém os 19 itens com os nomes do catálogo (`rabbit_fur`, `hawk_feather`…), na disposição da galeria. Confira a prévia de escala e textura no importador antes de confirmar.

Para importar um item por vez, use os FBXs em `individual/`. Neles a origem fica no centro do item, com a base em Y = 0, sem o deslocamento da galeria.

Os itens vêm deitados: a face de cima aponta para +Y. Num ViewportFrame, a câmera olha de cima para baixo, com uma leve inclinação (~65°, como no jogo).

## Conteúdo

- `mob-drops.fbx`: os 19 itens, uma malha (um MeshPart) por item.
- `individual/*.fbx`: 19 arquivos independentes.
- `mob_drops_palette.png`: textura de cores 256 × 256 (65 cores, um quadrado 16 × 16 por cor), também embutida nos FBXs.
- `mob-drops-export.blend`: Blender limpo, só com as 19 malhas de exportação e a textura embutida.
- `manifest.json`: ids, nomes, triângulos, dimensões e peças de origem.
- `validation.json`: resultado da reimportação dos 20 FBXs no Blender.
- `preview.png`: conferência visual da cópia exportada.

As peças de cada item (uma por cor no `../mob-drops.blend`) foram unidas só na cópia de exportação, e as faces foram trianguladas. As cores sólidas viraram a textura de paleta compartilhada, porque o MeshPart do Roblox aceita um material só. O arquivo editável não é alterado.

## Configuração e validação

FBX Unit Scale, escala 1, Z Forward, Y Up, textura embutida, sem animação. Total: 5.256 triângulos, de 139 a 486 por item. Os 20 arquivos foram reimportados no Blender e conferidos quanto a nomes, triângulos, material único, UV, textura, dimensões e origem (erro máximo de limites: 0,0000005). Ainda não houve validação dentro do Roblox Studio.

## Refazer a exportação

Depois de mudar o `../mob-drops.blend`:

1. Salve uma cópia em `../export-work/live-snapshot.blend`.
2. `blender -b ../export-work/live-snapshot.blend --python ../export_roblox.py`
3. `blender -b mob-drops-export.blend --python ../validate_roblox_export.py`
