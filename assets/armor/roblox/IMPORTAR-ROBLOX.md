# Armaduras — pacote para Roblox Studio

32 equipamentos aprovados, incluindo as três coroas refinadas e os sete capacetes reforçados, do ouro à lava. A máscara ninja e o chapéu de bruxa também mantêm os refinamentos aprovados (v02).

## O que importar

- **armaduras-32.fbx**: todos os equipamentos, separados e organizados em uma grade.
- **individual/<id>.fbx**: um equipamento por arquivo, com a origem no centro do corpo do personagem.
- **armaduras_palette.png**: cores compartilhadas; também estão embutidas nos FBXs.
- **armaduras_roughness.png** e **armaduras_metalness.png**: mapas compartilhados para o acabamento PBR.
- **armaduras-export.blend**: cópia limpa das malhas exportadas, sem alterar o Blender editável aprovado.
- **manifest.json**: nomes, medidas locais, peças, triângulos e materiais.
- **validation.json**: resultado da reimportação dos 33 arquivos FBX.

O pacote contém apenas os equipamentos: sem personagens de referência, luzes, câmeras, textos de apresentação ou versões antigas. São 34 malhas: 32 peças principais e 2 partes luminosas separadas.

## Importação

1. Extraia o ZIP inteiro para uma pasta.
2. No Roblox Studio, use **File > Import** e selecione `armaduras-32.fbx` ou um arquivo da pasta `individual`.
3. Configure **Scale Unit = Stud**, escala 1, **World Forward = Front** e **World Up = Top**. As coordenadas foram modeladas em studs, não em metros.
4. Mantenha a hierarquia dos modelos; habilite a importação como Model para agrupar as peças. Evite mesclar os 32 itens numa única malha.
5. Confira a textura na prévia e importe. Para um FBX individual, ative **Set Pivot to Scene Origin** para manter o encaixe no centro do corpo.
6. Nos arquivos com peças `_neon` (dragão e lava), aplique **Material = Neon** nessas peças após importar. A intensidade do brilho depende da iluminação do jogo.

O FBX inclui as imagens. Se o acabamento PBR não for aplicado pelo importador, use SurfaceAppearance com `armaduras_palette.png` no ColorMap, `armaduras_roughness.png` no RoughnessMap e `armaduras_metalness.png` no MetalnessMap. Os três mapas usam a mesma UV. Não aplique o material Neon às peças principais.

Referências oficiais: [Importador](https://create.roblox.com/docs/studio/importer) e [configuração Blender → Studio](https://create.roblox.com/docs/art/blender).

## Encaixe no personagem deste jogo

O pivô de cada equipamento é o **centro do Body visual**, não a Head invisível usada para o chat.

- 1 unidade de modelagem = 1 stud.
- Blender: +Y para frente e +Z para cima.
- Arquivo FBX: forward -Z, up Y.
- A posição da grade existe apenas no arquivo com os 32 modelos; os individuais estão na origem.
- As dimensões em `manifest.json` estão no espaço local do Blender, antes da conversão de eixos.
- O corpo de referência tem 3,6 × 3,6 de largura/profundidade e 2 de altura; a madeira tem cerca de 4,08 studs de largura.

As peças são modelos rígidos próprios para o boneco do jogo. O pacote não contém o código de equipar; a ligação com ArmorService/BonecoRenderer é a próxima etapa após importar. Não são roupas em camadas de avatar Roblox.

## Conferências realizadas

- Reimportação do FBX completo e dos 32 individuais.
- Nomes, contagem de malhas e triângulos, UVs, imagens, dimensões e origem.
- Todas as malhas exportadas têm menos de 20.000 triângulos.
- Coroas da vida, do anjo e da sorte usam a revisão com dentes regulares e gemas alinhadas; as asas do anjo foram remodeladas.
- Ouro, diamante, ametista, reidite, dragão, caranguejo e lava usam a revisão com blindagem reforçada.
- Modelos ninja e bruxa mantêm as revisões v02 aprovadas.
- O arquivo editável original permanece em `assets/armor/capacete-madeira-v01.blend`.

As conferências acima são de exportação/reimportação no Blender.

## No place (importado em 10/11/2026)

O `armaduras-32.fbx` foi importado no Studio e organizado em `ReplicatedStorage.Assets.Armor/<id>` (32 modelos, mesmo id dos itens em `Defs/Items.luau`).

- **A frente veio em +Z, não em -Z.** No Studio, o Blender +Y (frente) caiu em +Z e o X ficou espelhado (Roblox = −x, z, y do Blender), ao contrário do que diz o `axis_forward` acima. É o mesmo giro de 180° que o `SkinAssets` aplica nas skins de corpo e mochila.
- Cada modelo tem o **WorldPivot no centro do corpo, já girado 180°** (frente do pivô = frente do boneco, −Z). Para vestir: `modelo:PivotTo(corpo.CFrame)`.
- Conta usada: centro do corpo = pivô comum do FBX + posição `gallery` do manifest convertida (−gx, 0, gy). Conferida nas 34 malhas (desvio < 0,0001 stud).
- Peças `_neon` (dragão, lava): `Material = Neon`, TextureID = ColorMap e sem SurfaceAppearance. As outras: SmoothPlastic com SurfaceAppearance.
- Todas ancoradas, sem colisão, consulta, toque nem sombra (`CastShadow = false`, como nas skins).

