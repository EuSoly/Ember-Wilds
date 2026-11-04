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
| `menu` | Menu: nível, logo, saldo, coluna de botões, o boneco do jogador com o livro, Kits e JOGAR. Sem personagem; a câmera passeia pelo mapa atrás | `spawned`: o personagem nasceu (o jogador clicou Jogar) |
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
| `src/client/Screens/` | Uma tela por arquivo: `DeathScreen`, `SettingsScreen`, `RecipeBookScreen` e a lista de kits de pontos `KitList` (usada pela morte; a escolha é compartilhada com o menu) |
| `src/client/Menu/` | O menu inteiro, em código (Vide): veja "Menu" abaixo |
| `src/client/Controllers/ScreenController.luau` | Monta as telas e mostra/esconde conforme o estado |
| `src/client/ScreenState.luau` | O estado de tela |
| `src/client/AudioSettings.luau` | Grupos de som e volumes |
| `src/shared/UIFlow/` | Lógica pura das telas: `ScreenFlow`, `KitRules`, `KitOffer`, `MenuLayout`, `CountUp`, `SettingsFormat` |
| `src/shared/UiImages.luau` | Ids das imagens da interface num lugar só: logo, sol, lua, árvore, galho, moeda e placa de madeira. Para trocar uma: envie o PNG novo, cole o id aqui (a árvore, o galho e a placa têm a proporção/corte anotados ao lado) |
| `assets/ui/brand/` | PNGs da marca (logo, sol, lua), fonte das imagens enviadas ao Roblox |

## Como trocar o visual de uma tela

### No Studio

1. Com o `rojo serve` conectado, abra `ReplicatedStorage.UITemplates` e escolha o molde (ex. `Death`).
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
- **Linhas repetidas** (`KitRow`, `RecipeRow`) são um `Frame` simples. O código clona uma por item dentro da lista da tela. A lista deve ter um `UIListLayout` e, se for rolar, ser um `ScrollingFrame` com `AutomaticCanvasSize = Y`.
- **Use Scale, não pixels**, em tamanho e posição, para funcionar do celular ao PC. Limite o texto com `UITextSizeConstraint`.
- **Moldes não têm scripts.** Toda lógica e animação ficam no código.
- Telas que cobrem tudo (menu, morte, configurações) usam `ScreenInsets = None` e `IgnoreGuiInset = true`, para cobrir também a faixa da barra do Roblox. Por isso, deixe os botões longe da borda de cima.

### Elemento faltando

Se um nome combinado sumir ou for renomeado, o jogo **não quebra**. Aparece **um** aviso no Output com o molde e o nome, por exemplo: `[Template] o molde "MainMenu" não tem o elemento "PlayButton" (GuiButton)`. Só aquela parte deixa de funcionar. O mesmo vale para um elemento com a classe errada (ex. um `Frame` no lugar de um botão).

## Nomes combinados de cada molde

"Botão" aceita `TextButton` ou `ImageButton`. "Lista" aceita `Frame` ou `ScrollingFrame`.

**`LoadingScreen`** (em `src/first`, roda antes de tudo). Um sol anda junto com a ponta da barra; na metade vira lua, o céu escurece e a barra fica azul-noite. As contas (ritmo da barra, metade, textos) ficam em `src/first/LoadingMath.luau` (testado). Todos os nomes são opcionais: o que faltar só deixa de animar.

| Nome | Classe | Para quê |
|---|---|---|
| `Root` | CanvasGroup | Fade ao sumir |
| `Sky` | Frame | Céu provisório (degradê). Pode apagar quando a arte entrar |
| `Art` | ImageLabel | **A arte de fundo**: troque só a propriedade `Image` |
| `Night` | CanvasGroup | Céu da noite com estrelas; o código o faz aparecer depois da metade |
| `Logo` | ImageLabel | Logo (id escrito no molde) |
| `Track` | Frame | Trilho de madeira (o código escurece à noite) |
| `Fill` | Frame | A barra: o código muda a largura `Size.X.Scale` de 0 a 1 e a cor (brasa → noite) |
| `Sun`, `Moon` | ImageLabel | Andam na ponta do `Fill`; sem imagem viram um círculo |
| `StatusLabel` | TextLabel | "Carregando o mundo…" → "Acendendo as fogueiras…" → "Pronto!" |
| `TipLabel` | TextLabel | Dica fixa |

Os textos e os ids das imagens ficam escritos no molde e no script: os textos e o `UiImages` do jogo ainda não chegaram ao cliente nessa hora. Para trocar a arte de fundo: no Studio, ponha o id da imagem em `Art.Image` e salve o molde (veja "Como trocar o visual de uma tela").

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

**`RecipeBook`** (livro de crafting): molde `ScreenGui` com `Root` (`CanvasGroup`), `List` (`ScrollingFrame`) e `CloseButton`. O botão do livro fica na HUD ao lado da engrenagem.

**`RecipeRow`** (uma linha por receita): `Icon` (Frame para o `ItemIcon`), `NameLabel`, `IngredientsLabel` e `InfoLabel`. Os ingredientes ausentes ficam em vermelho; o texto de tempo e estação mostra quando a receita pode ser iniciada. Para editar o visual, salve os moldes em `assets/ui/RecipeBook.model.json` e `assets/ui/RecipeRow.model.json`. Veja `crafting.md`.

## O atributo `TextKey`

Qualquer `TextLabel` ou `TextButton` de um molde com o atributo **`TextKey`** recebe automaticamente `Strings.get(TextKey)`. Ex.: um botão com `TextKey = "death.playAgain"` mostra "Jogar de novo". No Studio: Properties → Attributes → `+`, nome `TextKey`, tipo `string`.

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

### Os três jeitos de levar um kit (UI 1)

No menu, o botão **Kits** (embaixo do boneco) abre o painel "ESCOLHA SEU KIT". Cada kit pode ir de três jeitos:

1. **Pontos, 1 vida**: o de verdade, descrito acima. A escolha fica em `KitList.selected` (a mesma da tela de morte).
2. **Robux, 1 vida** (mockup).
3. **Robux, para sempre** (mockup): depois de comprado, o botão vira **Usar**; ativado, o kit vem sozinho em toda vida (botão **Ativo**; clicar de novo desativa). Só um permanente ativo por vez.

Vai **um kit por vida**. Quem vale: escolha de pontos → compra de 1 vida com Robux → permanente ativo → nenhum. Escolher de pontos limpa a compra de 1 vida com Robux e vice-versa. Ao nascer, a compra de 1 vida é gasta; o permanente continua. O botão Kits mostra embaixo o kit desta vida.

**Robux ainda é mockup:** comprar só mostra o aviso "compra simulada" e muda um estado local (`src/client/Menu/KitShop.luau`), que volta ao início ao sair do jogo. O JOGAR só leva ao servidor o kit de **pontos**; por isso um kit de Robux aparece como "Explorador (simulado)". As regras puras ficam em `src/shared/UIFlow/KitOffer.luau` (teste `tests/kitoffer.spec.luau`). Os preços provisórios (`KIT_ROBUX`) e o kit que já começa permanente (`KIT_STARTS_OWNED`, hoje o Iniciante) ficam no `MockStore`. Kit novo em `Defs.Kits` precisa de preço em `KIT_ROBUX` (o teste avisa).

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

Janela no estilo rústico, feita em código (`src/client/Screens/SettingsScreen.luau`, sem molde). Abre pelo botão do menu e pela engrenagem da HUD, **por cima** do menu (que fica escurecido atrás) ou do jogo. Fecha no **Fechar** ou tocando fora da janela.

As linhas saem de `src/shared/Defs/Settings.luau`, separadas em grupos (**Som**, **Tela**, **Controles**: campo `group`, títulos `setting.group.<id>`) e, dentro do grupo, na ordem do campo `order`. Configuração nova aparece sozinha (veja "Adicionar uma configuração" em `dados.md`). O controle depende do tipo:

- número → **barrinha de arrastar**, de 5 em 5%. Os volumes mudam enquanto arrasta (dá para ouvir); o tamanho da interface só muda ao soltar (senão a tela mexeria embaixo do dedo);
- liga/desliga → **chave**;
- escolha → **setas** `<` `>` com o nome da opção no meio.

Cada mudança é um pedido ao servidor (`Net.SetSetting`), e a tela mostra sempre o valor do atributo `Setting_<id>` (menos durante o arraste). A conta da barrinha e os grupos ficam em `src/shared/UIFlow/SettingsFormat.luau` (teste: `tests/settingsformat.spec.luau`).

| Configuração | O que faz hoje |
|---|---|
| Volumes (música, ambiente, efeitos) | Volume dos `SoundGroup` `Music`, `Ambient` e `Effects` em `SoundService` (criados pelo cliente). Som novo usa `SoundGroup` = um deles |
| Tamanho da interface | `UIScale` das telas e da HUD |
| Qualidade gráfica | Só salva: o Roblox não deixa o jogo mudar a qualidade do jogador. Vai controlar os nossos efeitos quando existirem |
| Modo canhoto | Só salva: trocar os controles de toque de lado exige mexer no joystick do PlayerModule |

## Câmera do menu

Sem personagem (menu e tela de morte), o servidor (`SpectateService`) escolhe um jogador vivo aleatório a cada 8 s e grava o UserId no atributo `SpectateTarget` (0 = ninguém). Também aponta o foco de streaming (`ReplicationFocus`) para ele, para o mapa em volta chegar ao cliente. O `CameraController` segue esse jogador um pouco mais alto; sem ninguém vivo, gira devagar sobre o centro do mapa. Bonecos de teste não contam (não são jogadores).

## Menu (UI 1)

O menu é todo feito em código (Vide), no visual do [design system rústico](../game-design/design-system/README.md). O antigo molde `MainMenu` foi aposentado.

| Parte | O que é |
|---|---|
| Topo | Esquerda: nível e XP (falsos, com o selo MOCKUP), na copa da árvore. Meio: logo (120 px de altura no PC, 64 no compacto, 56 com um painel aberto). Direita: o **saldo de verdade** com o ícone da Golden Ember e um "+" que abre a **Loja já na seção Golden Ember**, apoiados num galho |
| Árvore | Imagem atrás da coluna, num ScreenGui próprio (`MenuBackdrop`) em tela cheia: vai do topo (por trás dos botões do Roblox) até embaixo, com a largura proporcional à altura. Tronco, copa (onde fica o nível) e cogumelos; os botões ficam como placas pregadas no tronco |
| Coluna à esquerda | Perfil, Cosméticos, Loja, Ranking e Configurações (esta abre a janela de configurações por cima do menu). Rola se a tela for baixa |
| Centro | O **boneco do jogador** com a skin equipada, segurando o livro (`MenuBoneco`), sobre uma sombra. Embaixo, **Kits** e **JOGAR** |
| Painel de kits | Abre à direita do boneco. No celular, cobre a área do boneco |
| Painéis do mockup | Perfil, Cosméticos e Ranking abrem à direita da coluna, com o visual antigo (o redesenho deles é outra fase) |
| Loja | Abre em **tela cheia** (some coluna, nível, logo, boneco e árvore; só o card da Golden Ember fica). Veja "Loja (UI 2)" |

| Arquivo | O que é |
|---|---|
| `src/client/Menu/MenuShell.luau` | Monta tudo; só liga no estado `menu` e desliga com Configurações aberta. Recalcula as posições quando a tela ou o tamanho da interface muda |
| `src/client/Menu/MenuState.luau` | Qual painel está aberto: `"play"` (nenhum), `"kits"`, `"profile"`, `"cosmetics"`, `"shop"` ou `"ranking"`; o pedido de seção da loja (`openShop(seção)`, `shopSection`) e o aviso de compra simulada |
| `src/client/Menu/MenuBoneco.luau` | O boneco do menu num `ViewportFrame`. A skin vem do atributo `Cosmetic_body` do **Player** (o `CosmeticService` grava lá também, porque no menu não há personagem). O livro é um clone de `ReplicatedStorage.Assets.Tools.book`; a pose (livro e mãos) são constantes no topo do arquivo |
| `src/client/Menu/KitsPanel.luau`, `KitShop.luau` | Painel e estado dos kits (veja "Os três jeitos de levar um kit") |
| `src/client/UI/Rustic.luau` | Peças do design system: placa de madeira, papel e botões (`wood`, `leather`, `ember`, `green`, `success`, `disabled`). `wood` e `leather` usam a **imagem da placa** (veio e pregos) em 9 partes: as pontas não esticam (`UiImages.PLANK_SLICE`); `leather` é a mesma placa um pouco mais escura; `ember` (JOGAR, "+", botão selecionado) usa a imagem do botão laranja chanfrado (`UiImages.BUTTON_EMBER`); `green` (preços em Robux da loja) usa o mesmo botão em verde (`ShopImages.BUTTON_GREEN`). Sem a imagem, caem num degradê. Cores em `Palette.rustic` |
| `src/shared/UIFlow/MenuLayout.luau` | Todas as medidas em pixels lógicos: coluna (200 no PC, 144 no compacto), botões, boneco, Kits/JOGAR e painel de kits. **Compacto** = largura < 900 ou altura < 500. Teste: `tests/menulayout.spec.luau` (de 568×320 a 1920×1080) |

O `MenuShell` tem uma tabela `CONTENT` (painel do mockup → função que monta o conteúdo). É nela que cada painel é ligado.

### Loja (UI 2)

Loja em tela cheia, toda **simulada** (visual e fluxo completos; comprar só mostra o aviso e nunca cobra nem salva). Design: `docs/superpowers/specs/2026-11-04-loja-design.md`. Quatro seções, com abas no topo que rolam até cada uma (a aba da seção visível fica destacada):

1. **Pacotes em destaque**: um pacote por vez, com setas, bolinhas, contador e lista do que vem; troca sozinho a cada 6 s.
2. **Gamepasses**: os 4 kits para sempre (o mesmo estado do painel de kits: comprar aqui libera o "Usar" lá) e o VIP.
3. **Giros**: um cartão por tipo de skin (Skins, Acessórios, Mochila, Livro, Caixa) com a roleta girando; **Escolher** abre a **tela do giro**: carrossel passando devagar, giro com Golden Ember × giro especial (Robux), chances visíveis, comprar +1/+3/+10 (o giro com Golden Ember exige saldo, mas não desconta), contador "Você tem N giros" e **GIRAR**. O carrossel freia e para no prêmio (5,2 s) e abre a janelinha "VOCÊ GANHOU!". O giro pago tem efeitos (raios, brilho, borda colorida, faíscas, clarão, tremida e confete).
   **Sons da roleta**: um tique a cada quadradinho que passa pelo marcador (vai espaçando conforme freia); no fim, um chiado e um rufar de tambores sobem de volume **na medida da raridade que vai sair** (Comum: nada; Raro: quase nada; Épico: um pouco; Lendário: chiado forte + tambor baixo; Mítico: tudo no máximo, e os tiques ficam mais agudos); ao parar, um som de revelação por raridade (do "ding" do Comum à orquestra do Mítico). O giro pago começa com um "vupt".
4. **Golden Ember**: os 5 pacotes de moeda (3 em cima, 2 largos embaixo).

Raridades (tabela do Elizeu): Comum, Raro, Épico, Lendário e Mítico (o mais raro), com cores próprias em `MockStore.RARITIES`.

| Arquivo (`src/client/Menu/Shop/`) | O que é |
|---|---|
| `ShopScreen.luau` | Topo (voltar, LOJA, abas) e a lista que rola com as seções |
| `Featured.luau`, `Passes.luau`, `SpinTypes.luau`, `EmberPacks.luau` | As quatro seções |
| `SpinScreen.luau`, `Reel.luau`, `SpinTile.luau` | Tela do giro, carrossel e o quadradinho de cada skin (placeholder por tipo até os ícones reais) |
| `SpinFx.luau` | Efeitos do giro pago e a comemoração do prêmio |
| `SpinSounds.luau` | Sons da roleta (tique, suspense, revelação), no grupo `Effects` |
| `ShopState.luau` | Giros comprados (por tipo e normal/pago), tela do giro aberta, girando |
| `ShopParts.luau` | Peças repetidas: título de seção, cartão (fundo de arte `ShopImages.CARD` ou degradê), botão de preço, fita, selo, grade |

| Regras e dados | O que é |
|---|---|
| `src/shared/UIFlow/SpinRules.luau` | Sorteio por peso, item pela raridade (desce se faltar), contadores de giros, saldo suficiente, confete, curva do suspense (`tensionRamp`) e quadradinho sob o marcador (`markerTile`). Teste: `tests/spinrules.spec.luau` |
| `src/shared/SpinSoundConfig.luau` | **Ids e volumes dos sons da roleta** (para trocar um som, troque o número) e quanto suspense cada raridade tem (`tension`). Teste: `tests/spinsoundconfig.spec.luau` |
| `src/shared/UIFlow/ShopLayout.luau` | Medidas da loja e colunas das grades (menos no celular). Teste: `tests/shoplayout.spec.luau` |
| `src/shared/UIFlow/MockStore.luau` | `RARITIES`, `SPIN_ODDS` (normal 30/40/23/6/1; especial 5/25/40/25/5), `SHOWCASE_WEIGHTS`, `SPIN_TYPES` (itens de mentirinha), `SPIN_PRICES`, `BUNDLES`, `PASSES`, `PACKS`. Teste: `tests/mockstore.spec.luau` |
| `src/shared/ShopImages.luau` | Ids das artes da loja (fontes em `assets/ui/shop/`): roleta em 3 camadas, fundos de cartão, ícone do Robux, botão verde, fita, pilhas de moedas e ícones. Id vazio = desenho feito por código |

Para ligar à cobrança real depois: cada compra passa por `ShopState.buySpins`, `KitShop.buyForever` ou pelo `onClick` dos cartões (`Featured`, `Passes`, `EmberPacks`); é aí que entra o `MarketplaceService`.

### Mockups do menu (G7a)

Os painéis Perfil, Cosméticos e Ranking são **mockups**: só para ver e testar o visual e o fluxo. **Nada é de verdade:** não compra, não salva, não muda o saldo. As fases seguintes tornam cada painel real, uma de cada vez.

| Arquivo (`src/client/Menu/`) | O que é |
|---|---|
| `CosmeticsPanel.luau` | Cosméticos: abas, grade de itens e a prévia do boneco. A aba Skins pinta a prévia com as skins de corpo de verdade, mas nada é salvo |
| `RankingPanel.luau`, `ProfilePanel.luau` | Ranking e perfil |

### O que é falso e o que é de verdade

- **De verdade:** o saldo (só leitura do atributo `Currency` do Player, ao vivo) e a lista de skins de corpo (vem dos `Defs`).
- **Falso:** todo o resto. Nenhum evento de rede, nenhuma escrita em atributo e nenhuma chamada a `MarketplaceService` em lugar nenhum dos mockups. Comprar só mostra o aviso "compra simulada" e **nunca** muda o saldo.

### Onde ficam os números e nomes falsos

Tudo em `src/shared/UIFlow/MockStore.luau`:

- os dados da Loja (veja "Loja (UI 2)");
- `CATEGORIES`: as abas de cosméticos (skins usa as skins de corpo de verdade; acessórios, mochila, livro e caixa são inventados);
- `RANKING`, `PROFILE`.

Teste: `tests/mockstore.spec.luau`. Os textos ficam nos blocos `mock.*` e `shop.*` de `src/shared/Strings/ptBR.luau`.

### Como mexer nos valores

- **Preço, chance, quantidade, nome de item:** edite `MockStore.luau`. As chances dos giros são em % e têm de somar 100, com 5 valores (um por raridade); o teste confere. Todo tipo de giro precisa de pelo menos um item de cada raridade.
- **Texto:** edite a chave `mock.*` ou `shop.*` correspondente em `ptBR.luau`.
- Rode `bash scripts/check.sh` depois.

### Como trocar um mockup por algo real (ou por um molde)

Dois caminhos, por painel:

1. **Trocar a função do painel.** Em `CONTENT` (no `MenuShell`), aponte o painel para uma função nova (a versão real). O resto da casca não muda.
2. **Virar molde do Studio**, como as outras telas: crie o molde em `assets/ui/` com nomes combinados, ligue pelo nome (`Template.find` / `Template.bind`, veja acima) e, na `CONTENT`, devolva o molde ligado no lugar da função do Vide. Documente os nomes combinados na tabela da seção "Nomes combinados de cada molde".

Quando um painel ficar real, apague o que ele usava do `MockStore` (e as chaves `mock.*` dele).

### Como apagar um mockup

O menu (coluna, boneco, Kits, JOGAR) é de verdade e fica. Para tirar um painel do mockup (ex. Ranking):

1. Em `src/client/Menu/MenuShell.luau`, tire o id do painel de `NAV` e de `PANELS`, a entrada dele em `CONTENT` e o `require` do arquivo do painel.
2. Apague o arquivo do painel em `src/client/Menu/` e o que só ele usava no `MockStore` (e o teste correspondente em `tests/mockstore.spec.luau`).
3. Em `src/shared/Strings/ptBR.luau`, apague as chaves `menu.nav.<painel>`, `menu.panel.<painel>` e as `mock.*` dele. Se o painel sair de vez, tire também o id do tipo `Panel` em `MenuState.luau`.
4. Rode `bash scripts/check.sh`.

Quando a compra de kits com Robux ficar real, apague `KIT_ROBUX` e `KIT_STARTS_OWNED` do `MockStore` (os preços vão para `Defs.Kits`) e troque o estado local do `KitShop` pelo que vier do servidor.
