# Primeira leva no Roblox Studio

Extraia o ZIP antes de importar. Há dois usos para os FBX: montar as 12 peças do catálogo e testar os movimentos em rigs com ossos.

## Modelos e movimento

1. Pelo importador 3D do Studio, abra `modelos/skins-primeira_leva.fbx`. O arquivo contém as 12 peças com nomes de malha do projeto. Mantenha a hierarquia, os nomes e a escala entre os itens. A paleta está embutida e acompanha o pacote em PNG.
2. Para integrar essa versão ao projeto Rojo, aplique o manifesto da primeira leva junto com as malhas revisadas. O pacote inclui `modelos/SkinManifest.luau` gerado nesta revisão. Se o catálogo avançou desde a exportação, acrescente `primeira_leva` ao fim de `SUBSTITUTAS` em `scripts/gen-skin-manifest.py` e rode o gerador sobre os arquivos atuais. Depois de sincronizar, execute o organizador `modelos/import-skins.luau` na barra de comandos do Studio em Edit.
3. Para avaliar um clipe, importe o FBX correspondente de `movimentos/` separadamente, preservando o rig. Use o Animation Editor no rig e importe a animação do mesmo FBX. Os dois clipes da Lula usam os mesmos ossos e podem ser testados no mesmo rig. Os tempos estão a 24 fps.
4. Os seis clipes contêm transformações de ossos. A Mochila Caranguejo (bag_caranguejo) e o Tomo Abissal (book_tentaculo) usam os efeitos e animações já existentes no jogo. No Bosque Desperto, preserve os itens animados existentes e sincronize os módulos CrateMotion e CrateAnimator incluídos em modelos/codigo para o efeito das flores da caixa. O arquivo pacotes.json lista as quatro recompensas de cada oferta e a raridade comum a suas quatro peças. Neon, poeira e pontos luminosos são efeitos do item e têm suas origens em `modelos/manifest.json` e seus tempos em `ANIMACOES.md`. Os clipes precisam de um rig compatível e de acionamento em jogo; os modelos estáticos do catálogo continuam usando a montagem própria do projeto.

## Banners

1. Importe as sete imagens de cada pasta em `vitrine/imagens/` pelo Asset Manager. O prefixo do arquivo identifica o bundle quando os PNGs estão juntos.
2. Insira `vitrine/ArteBundles.rbxmx` em ReplicatedStorage. Ele contém uma pasta por bundle. Em cada StringValue, preencha Value com o ID Roblox do PNG correspondente. O código aceita o número ou `rbxassetid://NUMERO`.
3. O campo ambiente recebe o PNG transparente do redemoinho, das folhas ou da rosa dos ventos, conforme o bundle. A versão atualizada de `Featured` do projeto usa `BundleBanner` para montar as camadas. Para uma cópia do projeto sem Rojo, o ZIP traz os dois módulos-fonte em `vitrine/codigo/` para o mesmo diretório de cliente, `Menu/Shop`. A arte aparece para a oferta de ID `mare_profunda`, `bosque_desperto` ou `norte_perdido` quando essa oferta estiver cadastrada e dentro da data. Preço, compra, textos e recompensas continuam definidos pelo sistema de loja.
4. Para testar a arte antes do cadastro comercial, inicie Play no Studio e execute no contexto **Client**:

```luau
local player = game:GetService("Players").LocalPlayer
local banner = require(player.PlayerScripts.Client.Menu.Shop.BundleBanner)
local screen = Instance.new("ScreenGui")
screen.Name = "PreviaPrimeiraLeva"
local holder = Instance.new("Frame")
holder.AnchorPoint = Vector2.new(0.5, 0.5)
holder.Position = UDim2.fromScale(0.5, 0.5)
holder.Size = UDim2.new(0.9, 0, 0, 260)
holder.Parent = screen
local art = assert(banner.build("mare_profunda", function() return true end), "Confira os IDs em ArteBundles")
art.Parent = holder
screen.Parent = player.PlayerGui
```

Troque o ID para conferir os demais. A prévia isolada mostra as camadas de arte; o carrossel da loja acrescenta os controles e textos. Encerrar a sessão de Play remove a tela de teste.
