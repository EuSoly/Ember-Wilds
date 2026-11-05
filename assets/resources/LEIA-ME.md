# Minérios para mineração

13 depósitos low-poly: três de pedra e dois de ouro, diamante, ametista, reidite e esmeralda. As onze versões que já existiam foram refeitas com formas naturais e maior volume. A esmeralda recebeu duas versões novas.

Referência de cores e identidade: https://starveiopro.fandom.com/wiki/Resources#Emerald

## Arquivos

- `minerios-editaveis.blend`: somente os novos depósitos e o cenário de apresentação.
- `minerios-trabalho.blend`: arquivo de trabalho com a nova cena `Mining_Deposits_13` e as cenas anteriores preservadas.
- `before-minerals.blend`: cópia do estado anterior.
- `minerios-preview.png`: catálogo completo.
- `esmeralda-preview.png`: detalhe das duas esmeraldas.
- `manifest.json`: IDs, minério, variante, collection original correspondente, peças, dimensões e triângulos.

## Modelos

| Minério | IDs | Forma |
|---|---|---|
| Pedra | stone_deposit_01 a 03 | Rochas irregulares, massas partidas e lascas |
| Ouro | gold_deposit_01 a 02 | Blocos e pepitas grandes de contorno irregular |
| Diamante | diamond_deposit_01 a 02 | Cristais largos com quatro faces e pontas |
| Ametista | amethyst_deposit_01 a 02 | Cristais hexagonais alongados e pontiagudos |
| Reidite | reidite_deposit_01 a 02 | Lâminas minerais espessas e assimétricas |
| Esmeralda | emerald_deposit_01 a 02 | Cristais hexagonais com terminações planas chanfradas |

Cada depósito usa exclusivamente os tons do próprio minério. A base dos cristais também pertence à mesma paleta: não há pedras de outra cor, metais, aros, parafusos, gemas de outro minério ou suportes artificiais.

## Edição e programação

Cada collection usa o ID do depósito. O vazio `<id>_root` move o modelo completo. O pivot fica no centro da base, em Z = 0 local; para retirar o modelo do catálogo e trabalhar na origem, zere a localização do root.

As malhas são independentes e editáveis com Tab. Selecione uma peça, não o vazio `_root`, para editar vértices. Os vazios têm seus eixos ocultos no viewport. A collection `Deposits_Presentation` está bloqueada para seleção e contém apenas os elementos de apresentação.

Propriedades nos roots: `item_id`, `resource_type`, `variant` e `purpose`. Os modelos representam depósitos do mundo que o jogador atinge com uma ferramenta. Não incluem script de mineração, quantidade de recursos, hitbox separada ou configuração de colisão no Roblox. A preparação para exportação pode ser feita após aprovação visual.

## Verificação

- 13 modelos, 62 peças, 2.296 triângulos no total.
- Todas as peças são malhas fechadas com faces de área positiva e volume orientado corretamente.
- Todas as peças tocam o chão ou intersectam uma peça conectada ao chão.
- Todas as peças de cada minério utilizam exclusivamente materiais daquela família.
- Os objetos anteriores foram preservados, com comparação de geometria, transformações e materiais atribuídos.
