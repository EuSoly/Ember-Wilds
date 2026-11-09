# Ícones de itens em relevo (ViewportFrame)

Os itens aparecem no inventário como modelos 3D bem baixos, vistos de cima num ViewportFrame. Parecem ícones 2D, mas são malhas de verdade, então servem também como item caído no chão (a câmera do jogo fica a ~65°).

Cada seção da página Items da wiki tem a própria pasta, com o mesmo fluxo:

| Seção | Pasta | Itens |
|---|---|---|
| Mob Drops | `assets/resources/mob-drops/` | 19 |
| Food/Ingredients | `assets/resources/food/` | 16 (Raw Meat, Fish, Crab Sticks e Crab Claws ficam nos Mob Drops) |

Cada pasta tem o `.blend` editável, a prévia, o `manifest.json`, a subpasta `roblox/` com os FBXs e o próprio `LEIA-ME.md`. Os minérios do inventário são os modelos da coleção `viewport` do Elizeu (`assets/resources/minerios-trabalho.blend`).

## Fluxo de uma seção nova

1. Abrir a wiki no Chrome (Claude in Chrome), montar uma galeria com as imagens `Inv_*.png` da seção e extrair, no navegador, o contorno e as regiões de cor de cada ícone (as imagens só carregam pelo navegador; acesso direto ao CDN dá 403).
2. Copiar o `.blend` de uma seção pronta, apagar a collection de itens e manter o text block `icons_lib` (no `food.blend`; no `mob-drops.blend` ele se chama `mob_drops_lib`) e a apresentação. Definir `GROUP` com o nome da collection nova.
3. Montar cada item com `build` (silhueta + regiões), `pelt_item` (peles) ou `feather_set` (penas); detalhes à mão quando a separação de cores sai confusa. No fim: `strip_bottoms` e `optimize_item`.
4. Salvar uma cópia em `export-work/live-snapshot.blend` e rodar `export_roblox.py` e `validate_roblox_export.py` em Blender de fundo. Ao copiar esses scripts para uma pasta nova, troque o `BASE` à mão (o `sed` não lida bem com as barras invertidas do Windows).

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

## No jogo (08/11)

- Importação: `food.fbx` e `mob-drops.fbx` por File > Import 3D e depois `scripts/studio/import-icons.luau` (Edit), que transforma cada MeshPart em `ReplicatedStorage.Assets.Icons/<id>` (Model, pivô no centro da base, ancorado, sem colisão). Ícone antigo de mesmo nome vai para `ServerStorage.IconesAntigos`.
- O `ItemIcon` (slot do inventário, baú, caixa, craft, kits) procura o modelo em `Assets.Icons/<id>`, depois `Assets.Tools/<id>` (ferramentas e armas: vistas pelo lado largo, na diagonal, ponta em cima à direita) e depois `Assets.Structures/<id>` (construções, de cima como os ícones). Sem modelo, mostra as iniciais (hoje: capacetes, protetor de orelha, mochila de couro, papel, balde com água).

### Ajustar a vista de um item

Atributos opcionais no molde (`Assets.Icons/Tools/Structures/<id>`) ou numa peça direta dele (a MeshPart de dentro, o Handle), editados no Properties do Studio:

| Atributo | Tipo | Efeito |
|---|---|---|
| `IconeGiro` | Vector3 (graus) | X inclina (cima/baixo), Y vira (esq./dir.), Z gira no plano da tela |
| `IconeZoom` | número | 1 = enche o quadro; 1,3 = 30% maior; 0,8 = menor |
| `IconeDesloca` | Vector2 | move o modelo no quadro em frações dele (0,1, 0 = 10% para a direita) |

Para ver ao vivo, use a bancada (ModuleScript `ServerStorage.BancadaIcones`, cópia de `scripts/studio/icon-bench.luau`). Na barra de comando do Studio (Edit), cole:

```lua
require(game.ServerStorage.BancadaIcones)()      -- monta a bancada
require(game.ServerStorage.BancadaIcones)(true)  -- apaga a bancada
```

Ela monta `StarterGui.BancadaIcones` com todos os ícones e o id embaixo; o ícone muda na hora em que o atributo muda. A barra de comando roda código Luau, não caminho de arquivo. A bancada não é salva com o place nem vai para o Play (`Archivable = false`): ao reabrir o Studio, rode a linha de novo. Os atributos vivem no place: salve o place. Antes de publicar, apague a bancada.

## Pendências

- Modelos para capacetes, protetor de orelha, mochila de couro, papel e balde com água.
- Os outros itens da wiki que ainda não existem no jogo seguem o mesmo fluxo.
