# O mapa

O mapa é **desenhado à mão no Studio**, dentro de `Workspace.Map`, e o jogo **espalha os recursos** (árvores, rochas, ouro, arbustos) dentro das zonas que você marca. O espalhamento usa uma semente fixa: o mapa sai **igual em toda partida**.

O `Workspace` não é controlado pelo Rojo. O que você desenha fica salvo **no place**: depois de mexer, pare o jogo e **salve (Ctrl+S)**. Para guardar uma cópia no git, veja "Backup" no fim.

## Tamanho e coordenadas

O mapa é um quadrado de **2.220 × 2.220 studs**, centrado na origem (no Studio, `-Z` é "para cima" na tela do jogo). Os biomas ficam nos cantos e o oceano em cruz no meio, como no Starve.io:

| Bioma | X | Z | No lançamento |
|---|---|---|---|
| Floresta | −1110 a −150 | +150 a +1110 (embaixo à esquerda) | **jogável** |
| Inverno | −1110 a −150 | −1110 a −150 (em cima à esquerda) | fechado |
| Lava | +150 a +1110 | −1110 a −150 (em cima à direita) | fechado |
| Deserto | +150 a +1110 | +150 a +1110 (embaixo à direita) | fechado |

- A floresta tem **960 × 960** e leva ~1 minuto para atravessar andando.
- O boneco nasce no **centro da floresta** (−630, 0, 630). A câmera do menu gira em volta desse ponto.
- O chão fica com o topo em **Y = 0**.
- Esses números estão em `src/shared/WorldConfig.luau`. Se mudar o tamanho, mude ali e no desenho.

## As pastas de `Workspace.Map`

| Pasta | O que vai dentro | O que o jogo faz |
|---|---|---|
| `Ground` | o chão de cada bioma (Parts planos, topo em Y = 0) | nada (é só o chão) |
| `Water` | córregos e lagos (Parts finos, **um pouco acima** do chão, ex. topo em Y = 0,05) | quem está dentro anda a 60% da velocidade, perde fôlego e (no Studio) enche a sede; nenhum recurso nasce ali; a água fica **opaca** no jogo |
| `NoSpawn` | Parts cobrindo caminhos e clareiras | nenhum recurso nasce ali; ficam invisíveis no jogo |
| `Zones` | Parts com o atributo **`ZoneType`** | o jogo espalha os recursos daquele tipo de zona dentro de cada uma; ficam invisíveis no jogo |
| `Resources` | Parts ou Models com o atributo **`ResourceId`** | cada um vira um recurso de verdade na mesma posição e rotação |
| `Borders` | paredes invisíveis em volta da área jogável | não deixam passar |

No Studio você pode deixar zonas e caminhos coloridos e meio transparentes para enxergar o desenho: o jogo os esconde sozinho.

### Formas aceitas (Water, NoSpawn e Zones)

- **Bloco** (`Part` com `Shape = Block`): pode girar à vontade **em volta do eixo vertical** (córrego em diagonal, por exemplo). Não incline.
- **Disco** (`Part` com `Shape = Cylinder` **deitado como uma moeda**, eixo para cima): bom para lago redondo e clareira. O diâmetro é o menor entre `Size.Y` e `Size.Z`.
- O jogo olha **de cima** (só X e Z): a altura não importa.
- Qualquer outra coisa (bloco inclinado, cunha, bola, união, MeshPart, Terrain) aparece como **aviso no Output** e é ignorada.

Dica para um córrego em curva: vários blocos em sequência, cada um girado, com as pontas se sobrepondo um pouco.

## Zonas de recurso

Cada peça em `Map/Zones` precisa do atributo `ZoneType` com um destes valores:

| `ZoneType` | O que tem (por 10.000 studs², ≈ um quadrado de 100 × 100) |
|---|---|
| `forest_dense` | 14 árvores, 2 rochas, 2 arbustos, 3 pedras do chão |
| `forest_open` | 6 árvores, 3 rochas, 3 arbustos, 0,3 de ouro, 5 pedras do chão |
| `quarry` (pedreira) | 8 rochas, 3 de ouro, 1 árvore, 10 pedras do chão |
| `berry_field` | 8 arbustos de frutinha, 1 árvore, 3 pedras do chão |

- Os números ficam em `src/shared/Defs/ResourceZones.luau`. Mudou um número, o mapa muda na próxima partida.
- Densidade quebrada (ex. 0,3 de ouro) é sorteada: uma zona pequena pode ganhar 0 ou 1, em vez de nunca ter nenhum.
- **Tipo de zona novo:** uma entrada em `ResourceZones.luau` (com as densidades) + o texto `zone.<id>` em `Strings/ptBR.luau`.
- O espalhador sempre deixa **pelo menos 5 studs de vão** entre as partes sólidas de dois recursos, para dar para passar mesmo na floresta densa. Se a zona não tiver espaço para a densidade pedida, ele coloca o que couber (sem erro).
- Zonas podem se sobrepor; recursos de uma não nascem em cima dos da outra.

## Recursos colocados à mão

Para um recurso num lugar exato: coloque uma Part (ou um Model) em `Map/Resources` com o atributo **`ResourceId`**:

| `ResourceId` | Recurso |
|---|---|
| `tree` | Árvore (3 variações) |
| `rock` | Rocha (3 variações) |
| `gold_vein` | Jazida de ouro (1 variação) |
| `berry_bush` | Arbusto de frutinha (1 variação) |
| `pebble` | Pedra do chão, só enfeite (10 variações) |

- O atributo opcional **`Variant`** (número) escolhe a variação; sem ele, é a 1.
- O que vale é a **posição e a rotação** da peça: ela fica invisível e o jogo põe o modelo padrão no lugar. (Recursos com modelo único, feito à mão, ficam para quando precisarmos.)
- Os recursos à mão entram antes do espalhamento e ocupam espaço: nada nasce colado neles.

## Os modelos dos recursos

Os modelos ficam no Studio, em **`ServerStorage.Assets.Resources`**, com o nome **`<id>_<variação>`**:

| Nome | O que é |
|---|---|
| `tree_1`, `tree_2`, `tree_3` | árvores |
| `rock_1`, `rock_2`, `rock_3` | rochas |
| `gold_vein_1` | jazida de ouro |
| `berry_bush_1` | arbusto de frutinha |
| `pebble_1` … `pebble_10` | pedras do chão (enfeite) |

- **Trocar um modelo:** substitua o modelo com o mesmo nome. **Mais uma variação:** coloque `tree_4` (por exemplo) e suba o `variants` do recurso em `src/shared/Defs/Resources.luau`. Se faltar a variação pedida, o jogo usa a `_1`; se faltar o modelo inteiro, usa um provisório feito por código.
- **Tamanho:** modele em qualquer escala. Cada recurso tem um **tamanho padrão** (`size`, a maior largura vista de cima, em studs) em `Defs/Resources.luau`, e o jogo redimensiona o modelo para ele. Cada exemplar ainda varia (`sizeJitter`: árvores, rochas, ouro e arbustos ±15%; pedras do chão ±40%) e sai **girado** aleatoriamente (o giro vem do sorteio do espalhador; nos recursos colocados à mão, é o giro do marcador). Tudo é sorteado com semente fixa: o mapa continua igual em toda partida.
- **Largura ou altura:** o `size` mede a largura (maior medida vista de cima), a não ser que o recurso tenha `sizeAxis = "height"`. As **árvores** usam a altura (`size = 14`): a câmera fica a uns 30 studs de altura, e copas com proporções diferentes não deixam nenhuma árvore minúscula. Rocha e ouro têm 9 de largura, arbusto 7.
- **Enterrar:** `sink` diz quanto da altura fica abaixo do chão (as pedras do chão têm `sink = 0.5`, metade enterradas).
- **Colisão:** você não precisa fazer nada. O jogo deixa todas as peças do seu modelo sem colisão e cria uma peça invisível no pé (o tronco, nas árvores; a base nos outros), com o raio `collisionRadius` de `Defs/Resources.luau`, que cresce e diminui junto com o exemplar. As pedras do chão não têm colisão nenhuma e podem ficar coladas nas rochas e árvores.
- **Transparência:** a árvore inteira (copa e tronco) fica transparente quando o boneco passa embaixo ou atrás dela.
- **Peças:** quanto menos peças por modelo, mais leve no celular (uma união ou MeshPart em vez de dezenas de Parts).
- Outros modelos guardados: `ServerStorage.Assets.Future` (minério de diamante, para o inverno) e `ServerStorage.Assets.Unused`.

`ServerStorage` também não é do Rojo: os modelos ficam salvos no place (salve com Ctrl+S).

## Avisos no Output

Ao dar Play, o servidor imprime quantos recursos montou e em quanto tempo, por exemplo `[MapService] 1599 recursos (2 à mão + 1597 espalhados) em 1421 ms` (com os modelos do Studio; redimensionar cada um é o que mais pesa). E avisa, com o caminho da peça:
- forma não aceita ou inclinada;
- `ZoneType` que não existe;
- `ResourceId` que não existe.

A peça com problema é ignorada e o resto do mapa funciona.

## Sem mapa

Num place sem `Workspace.Map`, o jogo cria um chão de teste de 256 × 256 em volta do ponto de nascer, sem recursos. Serve para testes rápidos.

## Dia e noite

O relógio é o mesmo da HUD (4 min de dia + 4 de noite). A luz de cada um está em `src/shared/LightingConfig.luau` (brilho, luz ambiente, tom de cor, névoa). A troca leva 10 s. A luz da fogueira é a de `src/shared/Models/FireLight.luau`.

Para testar a noite com fogo no Studio:

```lua
-- Barra de comandos, lado servidor:
local p = game.Players:GetPlayers()[1]
game.ServerStorage.DevCampfire:Invoke(p)                          -- fogueira 6 studs à frente
workspace:SetAttribute("CycleStart", workspace:GetServerTimeNow() - 238) -- anoitece em 2 s
```

## Câmera livre no Studio

Com o jogo rodando no Studio, **Shift + P** liga a câmera livre do Roblox (WASD/Q/E move, botão direito gira, roda dá zoom) e pausa a câmera do jogo. Shift + P de novo volta. Jogadores não têm isso.

## Backup do mapa no git

O mapa vive no place. Para guardar uma cópia com histórico:

1. No Studio, **Arquivo → Salvar em arquivo como…** e salve um `.rbxl` (ex. `C:\temp\ember-wilds.rbxl`).
2. No Git Bash, na pasta do projeto:
   ```bash
   rojo syncback map.project.json --input /c/temp/ember-wilds.rbxl
   ```
   Isso escreve `Workspace.Map` na pasta `map/` do repositório.
3. Commite a pasta `map/`.

O `map.project.json` é separado do `default.project.json` de propósito: o `rojo serve` do dia a dia **não** toma conta do mapa, então você continua desenhando livre no Studio.
