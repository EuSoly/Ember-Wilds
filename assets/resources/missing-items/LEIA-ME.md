# Itens restantes + arbusto de frutas

Criados em 12/11/2026. Escopo final: **16 itens (incluindo balde vazio), sem mochila de couro**, mais um
arbusto com **5 frutas separadas**, nas cores do item `berry` segurado pelo jogador.
Os arquivos estão prontos para importação; este lote ainda não foi instalado no place.

## Arquivos

- `missing-items.blend`: catálogo editável dos 15 itens, com peças e materiais separados.
- `berry-bush.blend`: arbusto editável, coleção `BushParts`, folhagem + cinco frutas.
- `empty-bucket.blend`: versão editável do mesmo balde, sem a malha de água.
- `empty-bucket-preview.png`: prévia do balde vazio.
- `missing-items-preview.png` e `berry-bush-preview.png`: prévias renderizadas.
- `roblox/items/missing-items.fbx`: os 15 ícones juntos.
- `roblox/items/individual/<id>.fbx`: um FBX por item, na origem e com a base no chão.
- `roblox/bush/berry-bush.fbx`: arbusto completo em 6 MeshParts, com posições relativas preservadas.
- `roblox/empty-bucket/empty-bucket.fbx`: balde vazio, com o ID `bucket`.
- Cada pasta de exportação inclui textura de paleta, `.blend` de exportação, manifesto e validação.
- `missing-items-roblox.zip`: pacote de importação com FBXs, texturas e documentação.
- `import-roblox.luau`: instalador para a Command Bar do Studio, com backup dos moldes anteriores.

## Importação rápida no Roblox Studio

1. Extraia `missing-items-roblox.zip`.
2. Em modo Edit, use **Import 3D** para importar estes três arquivos:
   - `roblox/items/missing-items.fbx`
   - `roblox/empty-bucket/empty-bucket.fbx`
   - `roblox/bush/berry-bush.fbx`
3. Preserve as malhas separadas. O preview do arbusto deve conter exatamente
   **6 malhas: Foliage e Berry_01 a Berry_05**. Não use uma opção que una malhas.
4. Selecione os três Models importados no Explorer. Abra `import-roblox.luau`,
   copie o conteúdo inteiro e execute na **Command Bar** do Studio.
5. O instalador confere as 22 peças antes de substituir moldes; cria os 16
   ícones em `ReplicatedStorage.Assets.Icons` e o arbusto em
   `ServerStorage.Assets.Resources.berry_bush_1`. As cinco frutas passam a se
   chamar `Berry`, com atributo `HarvestIndex` de 1 a 5.
6. Os moldes anteriores ficam em `ServerStorage.MissingItemsBackup_<id>`. O
   arbusto novo recebe os atributos do anterior e a mesma largura máxima.
7. Confira o resultado e salve o place. O molde novo aparece na próxima geração
   do mapa / próximo Play. Os Models de importação permanecem no Workspace para
   conferência; mova-os para fora do mapa ou remova-os depois.

O script instala o balde vazio como **ícone** `Icons.bucket`; o Tool existente
em `Assets.Tools.bucket` continua intacto. O arquivo FBX também pode ser usado
separadamente para editar o visual desse Tool.

## Itens

| ID | Nome |
|---|---|
| `paper` | Papel |
| `blue_thread` | Linha azul |
| `black_wolf_fur` | Pele de lobo negro |
| `white_wolf_fur` | Pele de lobo branco |
| `blue_cube` | Cubo azul |
| `lava_cube` | Cubo de lava |
| `dragon_orb` | Orbe azul |
| `lava_orb` | Orbe de lava |
| `blue_gem` | Gema azul |
| `green_gem` | Gema verde |
| `orange_gem` | Gema laranja |
| `firefly` | Vaga-lume |
| `pilot_glasses` | Óculos de piloto |
| `pitchfork_part` | Peça do forcado |
| `water_bucket` | Balde com água |
| `bucket` | Balde vazio |

O carretel vem do `thread` existente, as peles usam a biblioteca de Mob Drops e
o balde reutiliza a geometria do catálogo de ferramentas, incluindo sua água.
Os demais desenhos foram modelados para este lote, seguindo o relevo baixo,
contorno `#1E2230` e materiais simples do projeto. São interpretações no estilo
do catálogo; não foram extraídos pixel a pixel da wiki.

## Arbusto e cor das frutas

As cores foram lidas diretamente dos materiais da coleção `berry` em
`assets/resources/food/food.blend`, origem do ícone `Assets.Icons.berry`.
`src/client/Boneco/BonecoModel.luau`, função `holdFood`, usa esse ícone na mão.

- Fruta: **`#4A3A8C`**.
- Brilho da fruta: **`#8565C4`**.
- Base das folhas: **`#118A57`**, também do ícone, com tons auxiliares para o volume.
- Cinco malhas: `Berry_01` a `Berry_05`; folhagem em `Foliage`.
- 880 triângulos no arbusto inteiro; 80 por fruta.
- Pivô compartilhado no centro horizontal, na altura da base do arbusto.

Para instalar no jogo, importe o FBX completo **sem unir as malhas**. Mantenha
um Model `berry_bush_1` e renomeie **cada uma das cinco malhas de fruta para `Berry`** (o instalador faz isso):
o `BerryDisplay` procura esse nome para esconder as frutas conforme a colheita.
Não deixe `Berry_01`, etc., como nomes finais no Roblox.

A quantidade visual de cinco frutas não muda a quantidade de recursos definida
no jogo. Ajuste a escala do Model ao espaço ocupado pelo arbusto atual antes de
substituí-lo em `ServerStorage.Assets.Resources`; preserve os atributos do molde
atual e guarde uma cópia dele. Este lote não altera coleta ou balanceamento.

## Ícones no Roblox

Importe o FBX do lote ou os individuais. Cada item exporta uma malha com um
material e textura de paleta embutida, também fornecida em PNG. No catálogo
editável, as cores continuam em peças separadas.

Destino esperado: `ReplicatedStorage.Assets.Icons/<id>`, com cada MeshPart dentro
de um Model com o mesmo ID. São visuais: `Anchored = true`, `CanCollide = false`,
`CanTouch = false`, `CanQuery = false`. Os individuais têm origem no centro da
base. O balde mantém volume completo; os outros 14 usam relevo baixo.

Use o `import-roblox.luau` deste pacote. O script antigo
`scripts/studio/import-icons.luau` contém apenas os lotes anteriores.

## Verificação e reprodução

- 15 ícones: **2.599 triângulos** no total, 56 cores na paleta.
- Balde vazio adicional: **340 triângulos**, 6 cores na paleta.
- Arbusto: **6 malhas**, **880 triângulos**, 5 cores na paleta.
- Os três FBXs conjuntos e os 22 individuais foram reimportados no Blender.
- Verificados: IDs, número de malhas, triângulos, material único, UV, textura,
  dimensões e pivôs. Erro máximo de limites geométricos inferior a 0,000001 unidade.
- Resultados: `roblox/items/validation.json`, `roblox/bush/validation.json` e
  `roblox/empty-bucket/validation.json`.
- Prévias inspecionadas visualmente. Ainda sem teste dentro do Roblox Studio.

Rode no Blender em segundo plano, a partir do repositório:

```powershell
& 'C:\Program Files (x86)\Steam\steamapps\common\Blender\blender.exe' -b --factory-startup --python assets/resources/missing-items/build_assets.py
& 'C:\Program Files (x86)\Steam\steamapps\common\Blender\blender.exe' -b --factory-startup --python assets/resources/missing-items/export_assets.py
```

O gerador lê os catálogos originais sem salvá-los. A exportação reaproveita o
pipeline de paleta e validação já existente em `assets/resources/food/`.
