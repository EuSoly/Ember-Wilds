# Fazenda — modelos, sementes e crescimento

Lote de arte de 12/11/2026. **49 modelos editáveis**, seguindo o catálogo do
projeto e a preferência por **sementes soltas com cores por cultura**.

Este pacote contém modelos e um instalador de assets. Ainda não implementa
receitas, consumo de água, tempos de crescimento ou recompensas da colheita.
Nenhum arquivo de gameplay foi alterado por este lote.

**Para conferir tudo no Blender:** abra `fazenda-completa.blend`. O seletor de
cena no topo permite alternar entre a fazenda pronta, os 36 estágios, os ícones
e a caixa de plantação. Esse arquivo reúne as quatro cenas editáveis.

## Conteúdo

| Grupo | Quantidade | Arquivo editável |
|---|---:|---|
| Caixa de plantação, madeira e terra separadas | 1 | `planter-box.blend` |
| Nove culturas com quatro estágios cada | 36 | `farming-plants.blend` |
| Ícones de sementes soltas | 9 | `farming-icons.blend` |
| Garrafa vazia, garrafa com água e cubo de gelo | 3 | `farming-icons.blend` |

`farming-preview.blend` é uma cena de apresentação com as nove plantas maduras
encaixadas no canteiro. Os modelos individuais ficam nos arquivos acima.

Culturas: frutinha (`berry`), trigo (`wheat`), abóbora (`pumpkin`), arbusto de
espinho (`thorn`), cenoura (`carrot`), tomate (`tomato`), melancia (`watermelon`),
babosa (`aloe_vera`) e alho (`garlic`). O alho é representado por dentes de alho.

O cacto já possui ícone de alimento, mas não aparece como cultura no catálogo
de plantações do projeto; por isso não está neste lote. Doce de Natal, moinho
e forno de pão também não fazem parte deste pedido.

## Estágios e encaixe

| Estágio | Visual |
|---|---|
| `stage_01` | Broto inicial |
| `stage_02` | Planta jovem, folhas e caules menores |
| `stage_03` | Planta em formação; frutos verdes onde se aplica |
| `stage_04` | Planta madura e pronta para colher |

São quatro modelos discretos, não uma animação de crescimento interpolada.
Todos compartilham o mesmo pivô no nível do solo. O sistema pode trocar o modelo
mantendo o mesmo CFrame. Não recalcular o pivô pelo bounding box a cada estágio:
isso deslocaria as culturas assimétricas.

O canteiro mede aproximadamente 4 × 4 unidades. O atributo `SoilHeight` indica
a altura da terra (0,54 na escala de criação). Para encaixar uma planta:

```lua
plant:PivotTo(planter:GetPivot() * CFrame.new(0, planter:GetAttribute("SoilHeight"), 0))
```

Mantenha a mesma escala de importação para canteiro e plantas. Os modelos de
plantas não incluem a caixa: ela pode ser reutilizada em todos os estágios.

## Colheita por partes

| Planta madura | Partes colhíveis independentes |
|---|---|
| Frutinha | 5 frutas roxas; mesma geometria e cores do arbusto aprovado, em escala de cultivo |
| Trigo | 3 espigas; caules e folhas ficam separados |
| Abóbora | 1 fruto; ramas ficam separadas |
| Tomate | 3 frutos; planta fica separada |
| Melancia | 1 fruto; ramas ficam separadas |
| Cenoura | 3 conjuntos de raiz + folhas, para arrancar cada planta inteira |
| Alho | 3 conjuntos de bulbo + folhas |
| Babosa | 1 conjunto de folhas colhível |
| Espinho | Planta inteira; sem fruto separado |

No FBX as peças usam sufixos `__Harvest_01`, etc. O instalador as nomeia `Harvest`
e aplica `Harvestable = true` e `HarvestIndex`. As frutas do arbusto são chamadas
`Berry`, mantendo a convenção do projeto. As peças são MeshParts independentes:
ocultar uma não oculta as demais. O controle de quantidade será feito pela
lógica de fazenda, não pelo número de sementes desenhadas no ícone.

As cores dos frutos vêm dos alimentos existentes. Frutinhas usam `#4A3A8C` e
`#8565C4`, como o item segurado pelo jogador. Modelos volumétricos podem parecer
mais claros ou escuros conforme a luz, mantendo as mesmas cores de material.

## Importar no Roblox

1. Extraia `farming-roblox.zip`.
2. No Studio, em modo Edit, use **Import 3D** para `roblox/farming-pack.fbx`.
3. **Não una as malhas.** Preserve os nomes das peças e importe todo o lote.
   Há pequenos cubos `__Origin`, usados somente para preservar os pivôs.
4. Selecione o Model importado no Explorer. Copie e execute o conteúdo inteiro
   de `import-farming.luau` na Command Bar.
5. O instalador confere todas as peças antes de instalar e guarda modelos
   anteriores em `ServerStorage.FarmingBackup_<id>`. As importações originais
   permanecem no Workspace para conferência.
6. Confira os modelos e salve o place. Depois remova ou mova os Models usados
   apenas para importação para fora do mapa.

Destinos:

```text
ReplicatedStorage.Assets
  Structures.planter_box
  Farming.<crop>.stage_01 ... stage_04
  Icons.<crop>_seeds
  Icons.bottle_empty
  Icons.bottle_full
  Icons.ice_cube
```

Os cubos `__Origin` não são copiados para os moldes instalados. O atributo
`AssetId` mantém o ID completo. Os nomes dos novos itens são IDs propostos para
integração futura; o instalador não os adiciona a `Defs.Items` ou `Recipes`.

O pacote também inclui 49 FBXs individuais em `roblox/individual/`, todos com
origem comum e componentes colhíveis preservados. O instalador fornecido espera
o lote completo; os individuais servem para revisão/importação manual.

## Verificação

O exportador reimporta o arquivo combinado e cada um dos 49 individuais.
Confere nomes, contagem de peças, triângulos, material único por peça, UV,
textura, posição dos limites geométricos e origem. Nos modelos colhíveis também
confere que ocultar uma peça não oculta as outras. Resultados em
`roblox/validation.json`; contagens finais em `roblox/manifest.json`.

As prévias foram inspecionadas. O instalador teve a sintaxe Luau compilada,
mas não foi executado neste lote no Studio. A integração de gameplay permanece
para a etapa de programação.

## Prévias

- `farming-preview.png`: culturas maduras no canteiro.
- `growth-1.png`: frutinha, trigo e abóbora.
- `growth-2.png`: espinho, cenoura e tomate.
- `growth-3.png`: melancia, babosa e alho.
- `seeds-water-ice.png`: sementes, garrafas e gelo.
- `planter-preview.png`: caixa vazia.

## Reproduzir no repositório

```powershell
& 'C:\Program Files (x86)\Steam\steamapps\common\Blender\blender.exe' -b --factory-startup --python assets/farming/build_farming.py
& 'C:\Program Files (x86)\Steam\steamapps\common\Blender\blender.exe' -b --factory-startup --python assets/farming/export_farming.py
```

O processo usa Blender em segundo plano e não altera documentos abertos.
`geometry.py` contém os auxiliares de malha. O gerador lê os assets anteriores
para reutilizar o arbusto e as convenções visuais; não os sobrescreve.
