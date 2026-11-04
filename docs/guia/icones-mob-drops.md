# Ícones de Mob Drops (relevo para ViewportFrame)

Os drops de mob aparecem no inventário como modelos 3D bem baixos, vistos de cima num ViewportFrame. Parecem ícones 2D, mas são malhas de verdade, então servem também como item caído no chão (a câmera do jogo fica a ~65°).

Arquivos em `assets/resources/mob-drops/` (ver o `LEIA-ME.md` de lá).

## Estilo

- **Silhueta igual à da wiki.** O contorno de cada item foi extraído dos pixels do ícone original (70×75 px) e simplificado. Rabbit, Wolf, Winter, Boar Fur e Kraken Skin usam a mesma silhueta de pele, só mudam as cores.
- **Contorno escuro `#1E2230`** em volta de tudo, como pede `docs/game-design/identidade-visual.md`. Ele substitui o contorno branco ou vermelho da wiki.
- **Relevo baixo:** altura total de 0,12 a 0,17 para ~1 unidade de largura. Camadas: contorno (0–0,06), corpo (0,03–0,10) e detalhes empilhados por cima, 0,02 mais altos cada.
- **2 ou 3 tons por item**, com as cores da wiki. Nas peles, a sombra fica embaixo à direita e o brilho em cima à esquerda (a luz vem de cima à esquerda).

## Poucos polígonos

- Contornos com ~20 vértices, sem chanfro e sem subdivisão.
- As faces de baixo foram apagadas, porque nunca aparecem no ViewportFrame. Por isso as malhas não são fechadas. Se algum item precisar ser visto por baixo, basta recriar a face (F no modo de edição).
- **Uma malha por cor em cada item:** as peças da mesma cor foram unidas (`optimize_item` no `mob_drops_lib`), com limpeza de vértices duplicados e colineares. Cada malha vira um MeshPart no Roblox, então isso reduz direto o número de partes no ViewportFrame: 131 malhas viraram 84 (de 3 a 6 por item).
- De 139 a 486 triângulos por item (5.256 no total); os Piranha Scales são o mais pesado (8 hexágonos).
- As penas (Hawk, Penguin, Vulture) não usam o contorno da wiki como corpo: são montadas com `feather_set`, uma lâmina por pena (com borda clara fina e canudo central), tufo e canudos, nas posições da wiki.

## Estrutura de cada item

- Collection com o id do item (ex.: `rabbit_fur`) dentro de `Mob_Drops`.
- Vazio `<id>_root` com as propriedades `item_id`, `label`, `category = mob_drop` e `purpose = inventory_viewport_icon`. O pivot fica no centro do item, com a base em Z = 0. A posição do root é só a do catálogo; zere a localização para trabalhar na origem.
- Malhas, uma por cor: `<id>_outline`, `<id>_body` (ou `_shade` + `_body` nas peles) e as peças de detalhe (`_part`, `_blade`, `_rim`, `_rachis`, `_hl`…). Cada malha tem o próprio material, então dá para trocar cor sem mexer na forma.
- Ao criar um item novo, rode `optimize_item(collection)` no fim, depois de `strip_bottoms`.

## Como refazer ou ajustar

O `.blend` traz dois text blocks: `mob_drops_lib` (funções `slab`, `offset`, `build`, `pelt_item`…) e `wiki_shapes` (contornos em pixels da wiki). Para regenerar um item, rode no console do Blender:

```python
g={}; exec(bpy.data.texts['mob_drops_lib'].as_string(), g); exec(bpy.data.texts['wiki_shapes'].as_string(), g)
g['pelt_item']('rabbit_fur','Rabbit Fur',0,0,('#D8729F','#EF96BE','#FFC9E0'))
```

`item()` apaga e recria a collection do item, então ajustes manuais nessa collection se perdem ao regenerar.

## Desempenho no celular

O doc de identidade visual recomenda evitar ViewportFrame ao vivo na hotbar. Com modelos deste tamanho o custo é baixo, desde que o modelo fique parado (sem girar a câmera a cada frame) e os ViewportFrames do inventário só sejam montados quando ele abrir. Se pesar, renderize o mesmo modelo como PNG transparente e troque só a exibição.

## Exportação para o Roblox

Pasta `assets/resources/mob-drops/roblox/` (ver o `LEIA-ME.md` de lá). Segue o mesmo fluxo das armas (`assets/weapons/export_roblox.py`):
- `export_roblox.py` roda num Blender de fundo sobre uma cópia, `export-work/live-snapshot.blend`;
- cada item vira um MeshPart com um único material;
- as 65 cores viram a textura `mob_drops_palette.png`;
- a saída é `mob-drops.fbx` mais `individual/<id>.fbx`, com a origem no centro do item e a base em Y = 0.

`validate_roblox_export.py` reimporta todos os FBXs e confere triângulos, material, UV, textura, dimensões e origem.

## Pendências

- Importar no Studio, guardar os modelos (ex.: `ReplicatedStorage.Assets`) e montar o ViewportFrame do inventário.
- Os outros itens da wiki que ainda não existem no jogo seguem o mesmo fluxo.
