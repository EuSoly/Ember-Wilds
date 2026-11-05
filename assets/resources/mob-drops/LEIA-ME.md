# Mob Drops: ícones em relevo para o inventário

19 itens da seção Mob Drops (https://starveiopro.fandom.com/wiki/Items), feitos como adesivo 2D em relevo baixo para mostrar em ViewportFrame no inventário. Guia completo: `docs/guia/icones-itens.md`.

## Arquivos

- `mob-drops.blend`: os 19 modelos (collection `Mob_Drops`) e a apresentação (`Mob_Drops_Presentation`: câmera, luzes, fundo e nomes).
- `mob-drops-preview.png`: catálogo renderizado.
- `manifest.json`: id, nome, número de malhas, triângulos e materiais de cada item.
- `roblox/`: FBX conjunto, FBXs individuais e textura de paleta para importar no Studio (ver `roblox/LEIA-ME.md`). Gerado por `export_roblox.py` e validado por `validate_roblox_export.py`. O zip `mob-drops-roblox.zip` tem a mesma pasta.
- `mob_drops_lib.py` e `wiki_shapes.py`: cópias dos text blocks do .blend que geram os modelos (funções de construção e contornos extraídos da wiki).

## Itens

rabbit_fur, wolf_fur, winter_fur, boar_fur, kraken_skin, thread, crab_claws, crab_sticks, piranha_scales, hawk_feather, penguin_feather, vulture_feather, flame, mammoth_fur, raw_meat, fish, dragon_heart, lava_heart, sandworm_juice.

Total: 84 malhas (uma por cor em cada item, de 3 a 6) e 5.256 triângulos (de 139 a 486 por item; as peles têm 202).
