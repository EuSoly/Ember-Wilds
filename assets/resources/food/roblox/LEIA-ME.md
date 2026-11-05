# Comidas (Food/Ingredients) para Roblox

## Importar

No Roblox Studio, use **File > Import 3D** e selecione `food.fbx`. O arquivo contém os 16 itens com os nomes do catálogo (`berry`, `cooked_meat`…), na disposição da galeria. Confira a prévia de escala e textura no importador antes de confirmar.

Para importar um item por vez, use os FBXs em `individual/`. Neles a origem fica no centro do item, com a base em Y = 0, sem o deslocamento da galeria.

Os itens vêm deitados: a face de cima aponta para +Y. Num ViewportFrame, a câmera olha de cima para baixo, com uma leve inclinação (~65°, como no jogo).

## Conteúdo

- `food.fbx`: os 16 itens, uma malha (um MeshPart) por item.
- `individual/*.fbx`: 16 arquivos independentes.
- `food_palette.png`: textura de cores 256 × 256 (60 cores, um quadrado 16 × 16 por cor), também embutida nos FBXs.
- `food-export.blend`: Blender limpo, só com as 16 malhas de exportação e a textura embutida.
- `manifest.json`: ids, nomes, triângulos, dimensões e peças de origem.
- `validation.json`: resultado da reimportação dos 17 FBXs no Blender.
- `preview.png`: conferência visual da cópia exportada.

As peças de cada item (uma por cor no `../food.blend`) foram unidas só na cópia de exportação, e as faces foram trianguladas. As cores sólidas viraram a textura de paleta compartilhada, porque o MeshPart do Roblox aceita um material só. O arquivo editável não é alterado.

## Configuração e validação

FBX Unit Scale, escala 1, Z Forward, Y Up, textura embutida, sem animação. Total: 4.047 triângulos, de 145 a 371 por item. Os 17 arquivos foram reimportados no Blender e conferidos quanto a nomes, triângulos, material único, UV, textura, dimensões e origem (erro máximo de limites: 0,0000005). Ainda não houve validação dentro do Roblox Studio.

## Refazer a exportação

Depois de mudar o `../food.blend`:

1. Salve uma cópia em `../export-work/live-snapshot.blend`.
2. `blender -b ../export-work/live-snapshot.blend --python ../export_roblox.py`
3. `blender -b food-export.blend --python ../validate_roblox_export.py`
