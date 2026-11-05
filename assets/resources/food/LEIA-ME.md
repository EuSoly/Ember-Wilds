# Comidas (Food/Ingredients): ícones em relevo para o inventário

16 itens da seção Food/Ingredients (https://starveiopro.fandom.com/wiki/Items), no mesmo estilo dos Mob Drops: adesivo 2D em relevo baixo para ViewportFrame, contorno escuro `#1E2230`, silhueta extraída da wiki. Guia completo: `docs/guia/icones-itens.md`.

Raw Meat, Fish, Crab Sticks e Crab Claws também são comida na wiki, mas já estão em `../mob-drops/`.

## Arquivos

- `food.blend`: os 16 modelos (collection `Food`) e a apresentação (`Food_Presentation`).
- `food-preview.png`: catálogo renderizado.
- `manifest.json`: id, nome, malhas, triângulos e cores de cada item.
- `roblox/`: FBX conjunto, FBXs individuais e textura de paleta para importar no Studio (ver `roblox/LEIA-ME.md`). O zip `food-roblox.zip` tem a mesma pasta.
- `export_roblox.py` e `validate_roblox_export.py`: exportação e validação (rodam em Blender de fundo).
- `icons_lib.py` e `food_shapes.py`: cópias dos text blocks do .blend que geram os modelos.

## Itens

berry, wheat, flour, bread, sandwich, cookies, cake, cooked_meat, cooked_fish, pumpkin, tomato, carrot, watermelon, garlic, cactus, aloe_vera. `berry` e `cooked_meat` usam os ids que já existem em `src/shared/Defs/Items.luau`.

Total: 75 malhas (uma por cor em cada item) e 4.047 triângulos.
