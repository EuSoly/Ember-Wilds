# Estruturas utilitárias — 18 modelos

Referência visual: https://starveiopro.fandom.com/wiki/Structures

Modelos low-poly adaptados para 3D, seguindo as cores e silhuetas da wiki e o estilo das builds aprovadas. Os extratores de diamante, ametista e reidite possuem detalhes próprios na geometria.

## Arquivos

- `structures-editaveis.blend`: somente os 18 novos modelos e a apresentação.
- `structures-trabalho.blend`: cópia de trabalho com as cenas anteriores preservadas e a nova cena `Structures_Catalog_18`.
- `before-structures.blend`: cópia do estado anterior à criação.
- `structures-preview.png`: catálogo completo.
- `extratores.png`, `fogueiras.png`, `bau-aberto.png`: prévias de detalhe.
- `manifest.json`: IDs, peças, limites locais, contagem de triângulos e validação das malhas.
- `animation-validation.json`: verificação da hierarquia da tampa e dos rotores.

## Organização

Cada modelo possui uma collection com seu ID e um objeto vazio `<item_id>_root` no centro da base. Os modelos estão distribuídos no catálogo; para trabalhar na origem, coloque a localização do root em `(0, 0, 0)`. As peças acompanham o root.

| Collection | IDs |
|---|---|
| Extractors | stone_extractor, gold_extractor, diamond_extractor, amethyst_extractor, reidite_extractor |
| Fire_Structures | campfire, big_fire, furnace |
| Misc_Structures | workbench, chest, bridge, roof, sign, well, bed, totem, resurrection_stone, emerald_machine |

Selecione uma peça de malha e pressione **Tab** para editar vértices, arestas e faces. O objeto `_root` serve para mover o conjunto e não tem vértices. Os eixos auxiliares dos vazios estão ocultos no viewport. A collection `Structures_Presentation` contém chão, textos, luzes e câmera; ela está bloqueada para seleção e pode ser ocultada ao modelar.

## Partes preparadas para animação

- **Extratores:** `_rotor` é um pivot independente. Disco, espiral e eixo seguem a rotação em Z local.
- **Baú:** `_lid_hinge` está na borda traseira. A tampa, as faixas e a fechadura são filhos desse pivot. Fechado: X = 0°. Aberto na prévia: X = -105°. A caixa é oca e permanece parada. O arquivo editável é salvo fechado.
- **Fogo:** `_flame_anchor` separa as chamas da lenha ou da fornalha. As malhas de chama são uma representação low-poly; podem ser ocultadas e substituídas por efeitos do Roblox.
- **Pedras especiais:** `_core_anchor` agrupa o núcleo para efeitos ou rotação.
- **Placa:** `_text_anchor` identifica a área frontal para texto; frente = -Y local.
- **Ponte e telhado:** módulos de 4,2 × 4,2 unidades, com eixos alinhados para encaixe. O telhado deve ser posicionado na altura das paredes.

São hierarquias e pivôs de modelagem; não incluem scripts de gameplay nem animações programadas no Roblox. Os materiais são cores sólidas. A preparação de FBX e materiais para importação será feita após a revisão dos modelos.

## Verificação

18 modelos, 304 peças de malha, 12.150 triângulos no total. Todas as peças passaram na verificação de malha fechada, faces com área positiva e volume com orientação correta. Os pivôs foram normalizados para a base. A geometria, os materiais atribuídos e as transformações dos objetos anteriores foram comparados antes e depois da criação e permaneceram iguais.
