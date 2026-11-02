# Telas (carregamento, menu, morte, configurações)

As telas fora da HUD são **moldes**: o visual é um arquivo de instâncias (frames, textos, botões) e o código só liga o funcionamento, achando cada elemento pelo **nome**. Trocar o visual de uma tela = trocar o molde, sem mexer em código.

## O fluxo

O cliente tem um único estado de tela (`src/client/ScreenState.luau`):

```
loading ──ready──▶ menu ──spawned──▶ playing ──died──▶ dead
                    ▲                   ▲               │
                    └──────toMenu───────┼───────────────┤
                                        └───spawned─────┘
```

| Estado | O que aparece | Quando muda |
|---|---|---|
| `loading` | Tela de carregamento | `ready`: o perfil está pronto (atributo `DataReady` do Player). A tela de carregamento também espera o jogo carregar e cobre a espera até lá |
| `menu` | Menu: logo, saldo, kits, Jogar, Configurações. Sem personagem; a câmera passeia pelo mapa | `spawned`: o personagem nasceu (o jogador clicou Jogar) |
| `playing` | HUD | `died`: chegou o resumo da vida (`Net.LifeEnded`) |
| `dead` | Tela de morte: causa, dias, pontos virando Golden Ember, kits, Jogar de novo, Menu | `spawned` (Jogar de novo) ou `toMenu` (Menu) |

**Configurações** não é um estado: é uma janela por cima. Abre no `menu` (botão) e no `playing` (engrenagem da HUD). Só fecha sozinha quando o estado novo não permite a janela: na prática, ao morrer com ela aberta (`dead`). De `menu` para `playing` ela continua aberta.

As transições ficam em `src/shared/UIFlow/ScreenFlow.luau` (testado no Lune). Evento que não vale no estado atual é ignorado (ex. `died` no menu).

## Onde fica cada coisa

| Arquivo | O que é |
|---|---|
| `assets/ui/*.model.json` | Os moldes (no jogo: `ReplicatedStorage.UITemplates`) |
| `src/first/LoadingScreen.model.json`, `Loading.client.luau` | Molde e script da tela de carregamento (em `ReplicatedFirst`, roda antes de tudo) |
| `src/client/UITemplates/Template.luau` | Liga os moldes: `clone`, `find`, `bind`, `show` |
| `src/client/Screens/` | Uma tela por arquivo: `MainMenu`, `DeathScreen`, `SettingsScreen` e a lista de kits `KitList` |
| `src/client/Controllers/ScreenController.luau` | Monta as telas e mostra/esconde conforme o estado |
| `src/client/ScreenState.luau` | O estado de tela |
| `src/client/AudioSettings.luau` | Grupos de som e volumes |
| `src/shared/UIFlow/` | Lógica pura das telas: `ScreenFlow`, `KitRules`, `CountUp`, `SettingsFormat` |

## Como trocar o visual de uma tela

### No Studio

1. Com o `rojo serve` conectado, abra `ReplicatedStorage.UITemplates` e escolha o molde (ex. `MainMenu`).
2. Para ver enquanto edita, copie o molde para `StarterGui` e ligue `Enabled`. Edite à vontade: cores, fontes, imagens, posições, enfeites novos.
3. **Mantenha os nomes combinados** (tabela abaixo). Pode mudar onde eles ficam: o código procura em qualquer profundidade dentro do molde.
4. Terminou: apague a cópia do `StarterGui`, clique com o botão direito no molde editado → **Save to File** e salve como `assets/ui/Nome.rbxmx` (mesmo nome do molde).
5. **Apague o `assets/ui/Nome.model.json` antigo.** Se os dois existirem, o Rojo reclama de nome repetido.
6. Commit.

Para a tela de carregamento, o arquivo é `src/first/LoadingScreen.rbxmx` (apagando `src/first/LoadingScreen.model.json`).

### Vindo do Figma

Importe o design para o Studio com um plugin (FigBloxUI, Framewisp, UILint ou Figma Importer Assistant). Depois siga o mesmo caminho: renomeie os elementos para os nomes combinados, ponha tudo dentro de um `CanvasGroup` chamado `Root` e salve por cima do molde.

### Regras dos moldes

- **Cada tela é um `ScreenGui`** com um **`CanvasGroup` chamado `Root`** contendo tudo. É por ele que o código faz o fade de abrir e fechar. Sem `Root`, a tela funciona, mas abre sem animação.
- **Linhas repetidas** (`KitRow`, `SettingRow*`) são um `Frame` simples. O código clona uma por item dentro da lista da tela. A lista deve ter um `UIListLayout` e, se for rolar, ser um `ScrollingFrame` com `AutomaticCanvasSize = Y`.
- **Use Scale, não pixels**, em tamanho e posição, para funcionar do celular ao PC. Limite o texto com `UITextSizeConstraint`.
- **Moldes não têm scripts.** Toda lógica e animação ficam no código.
- Telas que cobrem tudo (menu, morte, configurações) usam `ScreenInsets = None` e `IgnoreGuiInset = true`, para cobrir também a faixa da barra do Roblox. Por isso, deixe os botões longe da borda de cima.

### Elemento faltando

Se um nome combinado sumir ou for renomeado, o jogo **não quebra**. Aparece **um** aviso no Output com o molde e o nome, por exemplo: `[Template] o molde "MainMenu" não tem o elemento "PlayButton" (GuiButton)`. Só aquela parte deixa de funcionar. O mesmo vale para um elemento com a classe errada (ex. um `Frame` no lugar de um botão).

## Nomes combinados de cada molde

"Botão" aceita `TextButton` ou `ImageButton`. "Lista" aceita `Frame` ou `ScrollingFrame`.

**`LoadingScreen`** (em `src/first`): `Root` (CanvasGroup, fade ao sumir, opcional) e `Fill` (Frame, a barra: o código muda a largura `Size.X.Scale` de 0 a 1). Os textos ficam fixos no molde, porque os textos do jogo ainda não chegaram ao cliente nessa hora.

**`MainMenu`**

| Nome | Classe | Para quê |
|---|---|---|
| `BalanceLabel` | TextLabel | Saldo (`menu.balance`) |
| `PlayButton` | Botão | Nasce com o kit escolhido |
| `SettingsButton` | Botão | Abre as configurações |
| `KitList` | Lista | Onde entram as linhas de kit |
| `KitPointsLabel` | TextLabel | Pontos para kit (`kit.points`) |

**`Death`**

| Nome | Classe | Para quê |
|---|---|---|
| `CauseLabel` | TextLabel | Causa da morte (`death.cause`) |
| `DaysLabel` | TextLabel | Dias vividos (`death.days`) |
| `PointsLabel` | TextLabel | Pontos descendo até 0 (`death.points`) |
| `CurrencyLabel` | TextLabel | Golden Ember subindo (`death.currency`) |
| `KitList` | Lista | Linhas de kit |
| `KitPointsLabel` | TextLabel | Pontos para kit |
| `PlayAgainButton` | Botão | Nasce de novo com o kit escolhido |
| `MenuButton` | Botão | Volta ao menu |

**`KitRow`** (uma por kit)

| Nome | Classe | Para quê |
|---|---|---|
| `NameLabel` | TextLabel | Nome do kit |
| `PriceLabel` | TextLabel | Preço (`kit.price`) |
| `ItemsLabel` | TextLabel | Itens ("8× Frutinha, 20× Madeira") |
| `SelectButton` | Botão | Seleciona / tira a seleção (de preferência cobrindo a linha toda) |

O destaque do kit escolhido usa o `UIStroke` filho direto da linha (fica laranja e mais grosso). Sem `UIStroke`, o fundo fica laranja.

**`Settings`**: `List` (Lista; uma linha por configuração, na ordem do campo `order`) e `CloseButton` (Botão).

**Linhas de configuração**: todas têm `NameLabel` (nome) e `ValueLabel` (valor atual), os dois TextLabel.

| Molde | Tipo | Botões |
|---|---|---|
| `SettingRowNumber` | número (volumes, tamanho da interface) | `MinusButton`, `PlusButton` (passo 0,1) |
| `SettingRowBoolean` | liga/desliga | `ToggleButton` |
| `SettingRowChoice` | escolha (qualidade) | `PrevButton`, `NextButton` |

**`RecipeBook`** (livro de crafting): molde `ScreenGui` com `Root` (`CanvasGroup`), `List` (`ScrollingFrame`) e `CloseButton`. O botão do livro fica na HUD ao lado da engrenagem.

**`RecipeRow`** (uma linha por receita): `Icon` (Frame para o `ItemIcon`), `NameLabel`, `IngredientsLabel` e `InfoLabel`. Os ingredientes ausentes ficam em vermelho; o texto de tempo e estação mostra quando a receita pode ser iniciada. Para editar o visual, salve os moldes em `assets/ui/RecipeBook.model.json` e `assets/ui/RecipeRow.model.json`. Veja `crafting.md`.

## O atributo `TextKey`

Qualquer `TextLabel` ou `TextButton` de um molde com o atributo **`TextKey`** recebe automaticamente `Strings.get(TextKey)`. Ex.: um botão com `TextKey = "menu.play"` mostra "Jogar". No Studio: Properties → Attributes → `+`, nome `TextKey`, tipo `string`.

Textos com dados (saldo, pontos, dias) são escritos pelo código nos elementos combinados. O que vier escrito no molde é só exemplo para o design.

## O que o código anima

- **Abrir/fechar tela:** fade do `Root` com leve escala (0,15 s).
- **Botões:** todo botão do molde encolhe um pouco ao apertar (95%, ~0,08 s). Não precisa fazer nada no molde.
- **Tamanho da interface:** a configuração `ui_scale` vira um `UIScale` em cada tela e na HUD, na hora.
- **Morte:** o mundo perde a cor (saturação até −1 em 1 s; volta ao sair da tela de morte), e os pontos descem até 0 enquanto a Golden Ember sobe, em 2 s.
- **Kits:** o que custa mais que os pontos fica apagado e sem clique; o escolhido ganha destaque.

## Kits iniciais

Como no Starve.io: antes de nascer, o jogador pode comprar **um** kit com os **pontos da vida que acabou** (não com Golden Ember). Esses pontos ficam no atributo `KitPoints` do Player, só em memória (ao sair do jogo, perde). Os mesmos pontos também viram Golden Ember normalmente na morte: são duas coisas independentes.

O servidor (`SpawnService`) confere o kit e os pontos, desconta e dá os itens depois de nascer; uma mochila no kit é vestida primeiro. Kit inexistente ou caro demais faz nascer sem kit, sem descontar nada. Se algum item não couber (não deveria, por causa da validação abaixo), aparece um `warn` no Output.

### Como adicionar um kit

1. Uma entrada em `src/shared/Defs/Kits.luau`:

```lua
kit_miner = {
	id = "kit_miner",
	nameKey = "kit.kit_miner",
	order = 5, -- posição na lista
	price = 3000, -- em pontos
	items = {
		{ id = "stone_pickaxe", count = 1 },
		{ id = "berry", count = 10 },
	},
},
```

2. O nome em `src/shared/Strings/ptBR.luau`: `["kit.kit_miner"] = "Minerador",`.

Pronto: o kit aparece no menu e na tela de morte. A validação no boot recusa:
- item que não existe;
- quantidade que não seja inteira ≥ 1;
- kit que **não cabe num inventário novo**: os slots base (10) mais os da mochila do próprio kit, se tiver uma (o bônus do gamepass não conta, porque nem todo jogador tem). Cada item ocupa `ceil(quantidade / maxStack)` slots, somando as entradas repetidas do mesmo item. Ex.: sem mochila, 2.550 de madeira (maxStack 255) já ocupam os 10 slots;
- preço negativo ou quebrado;
- `order` repetida;
- mais de uma mochila por kit (e a mochila precisa ter `count = 1`).

## Configurações

As linhas saem de `src/shared/Defs/Settings.luau`, na ordem do campo `order` (inteiro ≥ 1, sem repetir). Configuração nova aparece sozinha (veja "Adicionar uma configuração" em `dados.md`). Cada mudança é um pedido ao servidor (`Net.SetSetting`), e a tela mostra sempre o valor do atributo `Setting_<id>`.

| Configuração | O que faz hoje |
|---|---|
| Volumes (música, ambiente, efeitos) | Volume dos `SoundGroup` `Music`, `Ambient` e `Effects` em `SoundService` (criados pelo cliente). Som novo usa `SoundGroup` = um deles |
| Tamanho da interface | `UIScale` das telas e da HUD |
| Qualidade gráfica | Só salva: o Roblox não deixa o jogo mudar a qualidade do jogador. Vai controlar os nossos efeitos quando existirem |
| Modo canhoto | Só salva: trocar os controles de toque de lado exige mexer no joystick do PlayerModule |

## Câmera do menu

Sem personagem (menu e tela de morte), o servidor (`SpectateService`) escolhe um jogador vivo aleatório a cada 8 s e grava o UserId no atributo `SpectateTarget` (0 = ninguém). Também aponta o foco de streaming (`ReplicationFocus`) para ele, para o mapa em volta chegar ao cliente. O `CameraController` segue esse jogador um pouco mais alto; sem ninguém vivo, gira devagar sobre o centro do mapa. Bonecos de teste não contam (não são jogadores).

## Mockups do menu e da loja (G7a)

O menu ganhou uma **casca** com painéis de mentirinha: Perfil, Cosméticos, Loja, Comprar Golden Ember, Tutorial e Ranking. É só para ver e testar o visual e o fluxo. **Nada é de verdade:** não compra, não salva, não muda o saldo. As fases seguintes tornam cada painel real, uma de cada vez: primeiro comprar Golden Ember com Robux (e o menu), depois cosméticos (ter e equipar), depois giros e kit, depois ranking e nível.

### A casca e os painéis

| Arquivo (`src/client/Menu/`) | O que é |
|---|---|
| `MenuState.luau` | Qual painel está aberto (`panel`: "play", "profile", "cosmetics", "shop", "buy", "tutorial" ou "ranking"; abrir com `open(painel)`) e o aviso de "compra simulada" (`notice`, `notify(texto)`) |
| `MenuShell.luau` | A casca: um `ScreenGui` do Vide (`DisplayOrder` 1) que só liga no estado `menu` e desliga com Configurações aberta. Coluna rolável de 6 botões à esquerda (Perfil, Jogar, Cosméticos, Loja, Tutorial, Ranking); dois cantinhos em cima (esquerda: nível e XP falsos e a etiqueta MOCKUP; direita: o **saldo de verdade** e um "+" que abre "buy"); a área do painel; o aviso no título |
| `src/shared/UIFlow/MenuLayout.luau` | As medidas da casca em pixels (margens, pods de 56 px, coluna de 120 px, botões de 44 px, linha do título de 52 px). A casca usa offsets, então cabe de ~800x400 a 1920x1080 (a coluna rola se faltar altura). Teste: `tests/menulayout.spec.luau` |
| `CosmeticsPanel.luau` | Cosméticos: abas, grade de itens e a prévia do boneco (o `ViewportFrame` fica; só o boneco é criado ao abrir e destruído ao fechar). A aba Skins pinta a prévia com as skins de corpo de verdade, mas nada é salvo |
| `ShopPanel.luau` | Loja: giros (skin e personalizado) e kit. O detalhe do giro mostra a **tabela de chances antes de girar** (as regras do Roblox exigem isso para item aleatório pago). A animação do giro é cancelada ao sair do painel |
| `BuyPanel.luau` | Pacotes de Golden Ember (5) |
| `RankingPanel.luau`, `ProfilePanel.luau`, `TutorialPanel.luau` | Ranking, perfil e tutorial |

O painel "Jogar" é o molde `MainMenu` de sempre (`src/client/Screens/MainMenu.luau`). O `Root` dele se esconde quando outro painel está aberto, e o `BalanceLabel` dele fica escondido, porque agora quem mostra o saldo é a casca.

O `MenuShell` tem uma tabela `CONTENT` (painel → função que monta o conteúdo). É nela que cada painel é ligado.

### O que é falso e o que é de verdade

- **De verdade:** o saldo (só leitura do atributo `Currency` do Player, ao vivo) e a lista de skins de corpo (vem dos `Defs`).
- **Falso:** todo o resto. Nenhum evento de rede, nenhuma escrita em atributo e nenhuma chamada a `MarketplaceService` em lugar nenhum dos mockups. Comprar só mostra o aviso "compra simulada" e **nunca** muda o saldo.

### Onde ficam os números e nomes falsos

Tudo em `src/shared/UIFlow/MockStore.luau`:

- `PACKS`: os 5 pacotes de Golden Ember;
- `SPINS`: os giros (skin/personalizado), preços e chances (60/25/12/3%);
- `KIT`: livro + mochila (1 h por 300, 24 h por 600);
- `CATEGORIES`: as abas de cosméticos (skins usa as skins de corpo de verdade; acessórios, mochila, livro e caixa são inventados);
- `RANKING`, `PROFILE`, `TUTORIAL`;
- `roll(odds, r)`: sorteia um resultado a partir das chances.

Teste: `tests/mockstore.spec.luau`. Os textos ficam no bloco `mock.*` de `src/shared/Strings/ptBR.luau`.

### Como mexer nos valores

- **Preço, chance, quantidade, nome de item:** edite `MockStore.luau`. Se mexer nas chances de um giro, elas têm de continuar somando 1 (aparecem como %; o teste confere).
- **Texto:** edite a chave `mock.*` correspondente em `ptBR.luau`.
- Rode `bash scripts/check.sh` depois.

### Como trocar um mockup por algo real (ou por um molde)

Dois caminhos, por painel:

1. **Trocar a função do painel.** Em `CONTENT` (no `MenuShell`), aponte o painel para uma função nova (a versão real). O resto da casca não muda.
2. **Virar molde do Studio**, como as outras telas: crie o molde em `assets/ui/` com nomes combinados, ligue pelo nome (`Template.find` / `Template.bind`, veja acima) e, na `CONTENT`, devolva o molde ligado no lugar da função do Vide. Documente os nomes combinados na tabela da seção "Nomes combinados de cada molde".

Quando um painel ficar real, apague o que ele usava do `MockStore` (e as chaves `mock.*` dele).

### Como apagar tudo

1. Apague `src/shared/UIFlow/MockStore.luau`, `src/shared/UIFlow/MenuLayout.luau`, `tests/mockstore.spec.luau` e `tests/menulayout.spec.luau`.
2. Em `src/shared/Strings/ptBR.luau`, apague o bloco `mock.*` e as chaves do menu novo: `menu.nav.*`, `menu.panel.*`, `menu.close`, `menu.level`, `menu.xp` e `menu.mockup`. Mantenha `menu.play`, `menu.settings`, `menu.balance` e `menu.kits` (o molde usa).
3. Apague a pasta `src/client/Menu/`.
4. Em `src/client/Controllers/ScreenController.luau`, tire os `require` de `MenuShell` e `MenuState`, a chamada `MenuShell.mount(...)` e o bloco inteiro `if screen ~= "menu" then MenuState.open("play") end` (com o comentário dele), sem deixar um `if` vazio.
5. Em `src/client/Screens/MainMenu.luau`, tire o `require` do `MenuState`, o `if balance then balance.Visible = false end` (com o comentário; sem ele o `BalanceLabel` do molde volta a aparecer, e o texto dele já é escrito pelo `vide.effect` logo abaixo, então nada precisa ser reescrito) e o trecho inteiro que esconde o `Root` conforme o painel (o `if root ... else warn(...) end`).
6. Apague esta seção do guia (e o item "Mockups" do índice, se houver).
7. Rode `bash scripts/check.sh`.
