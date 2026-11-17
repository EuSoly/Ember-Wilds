# UIs no celular: caber na tela sem rolar (17/11/2026)

Branch `ui-celular` (saiu da `fazenda`, com as mudanças do HUD de 12/11 ainda sem commit).

## Por quê

O Elizeu não está gostando das telas no celular: foram pensadas para o PC e, no celular deitado (área útil de ~330 px de altura no emulador 749×330, ver [auditoria](../../game-design/auditoria-ui-celular.md)), cortam conteúdo ou obrigam a rolar. A meta é **cada tela caber inteira no celular, sem rolagem**, sem trocar a identidade visual (madeira, papel, cores).

## Metas

1. **Menu:** os 6 botões da coluna e o cartão do jogador cabem em 330 px sem rolar (botões menores).
2. **Saldo + galho:** o galho atrás do card da Golden Ember encosta de verdade no canto superior direito da tela (hoje para antes, na área segura).
3. **Loja:** no celular, cada aba é uma página do tamanho da tela; Pacotes, Gamepasses, Giros e Golden Ember cabem inteiros, sem mostrar pedaço de outra seção.
4. **Ranking:** no celular, o logo e o card da Golden Ember somem enquanto o ranking está aberto, e o painel sobe até o topo.
5. **Configurações:** no celular, todas as opções à vista sem rolar (2 colunas, X no canto).
6. **Coluna de receitas do HUD:** não encosta mais no selo de pontos/ranking ("0 pts · #1").
7. **Livro de receitas:** layout próprio no celular; nada cobre a descrição nem os ingredientes.
8. **Zoom:** nova opção "Zoom da câmera" nas Configurações (celular e PC). No celular a pinça deixa de dar zoom. No PC a roda do mouse continua.

## Fora do escopo

- PC: tudo continua como está (exceto a nova opção de zoom, que aparece lá também).
- Perfil, Cosméticos, Missões, Kits, tela do giro, mochila, baú, HUD de baixo (este já foi feito em 12/11).
- Itens 9–15 da auditoria que não estão nesta lista (ex.: X por cima do saldo em Perfil/Cosméticos).
- Celular em pé e tablet: não pioram, mas não são o alvo.

## Anti-metas

- Encolher a tela inteira (UIScale) para caber: a regra da seção 8 do design system é mudar a composição, não reduzir tudo.
- Texto abaixo de 12 px para fazer caber.
- Mudar algo no PC sem querer: os layouts puros têm testes para a tela de PC e eles continuam passando.

## Regras e restrições

- "Compacto" = largura < 900 ou altura < 500 (MenuLayout/ShopLayout/RankingLayout já usam). As telas de janela usam `ScreenMetrics.short()`.
- Medidas vêm de módulos puros em `src/shared/UIFlow/` testados no Lune (`tests/*.spec.luau`); a UI só desenha. Mudança de medida = teste junto.
- Alvo de toque: 44 px é o padrão. **Exceção decidida:** os botões da coluna do menu ficam com 40 de altura no compacto (são largos, 144 px), porque o Elizeu pediu botões menores para caber.
- Testar no emulador do Studio (749×330 deitado) pelo MCP, com capturas antes/depois em `docs/game-design/auditoria-celular/`. Ver [[reference-emulador-celular-studio]]: só o 1º clique funciona pelo MCP; abrir as telas por um LocalScript temporário no Play, como na auditoria.

## Abordagens consideradas

**Loja no celular**
- **A, escolhida:** cada aba é uma página. Só a seção da aba ativa aparece, e os cartões são dimensionados para caberem na altura livre. No PC a lista contínua fica como está. Escolhida porque não depende de quantos itens existem: um item novo encolhe os cartões, não volta a mostrar a seção de baixo.
- B: lista contínua com cada seção da altura exata da tela. Quebra quando muda o número de itens.

**Livro no celular**
- **A, escolhida:** o livro ocupa a tela toda, com abas só de ícone, a grade à esquerda (células menores) e a ficha à direita. A ficha tem texto que rola e uma faixa fixa embaixo com Pegar/Fixar. Escolhida porque dá para ver a grade e a ficha ao mesmo tempo.
- B: grade e ficha em telas separadas, com botão de voltar. Sobra mais espaço, mas custa um toque a mais.

**Configurações no celular:** 2 colunas foi a única forma de caber sem rolar. Abas ou rolagem iam contra a meta.

**Zoom:** a opção nas Configurações é o ponto de partida nas duas plataformas, e no PC a roda ajusta a partir dela. Ficar só com a roda no PC e só com a opção no celular deixaria os dois com padrões diferentes.

## Como cada parte fica

### 1. Menu (MenuLayout + MenuShell)
No compacto: cartão do topo de 48 (era 56), botões da coluna com 40 de altura e 3 de espaçamento (eram 44 e 4). Em 330 de altura: o corpo começa em 8+48+8 = 64; os botões ocupam 6×40 + 5×3 = 255; cabem até 64+255 = 319 < 322. A coluna continua sendo um ScrollingFrame como reserva para telas ainda menores. O cartão do jogador (nível, XP, avatar) se ajusta à altura de 48: avatar e textos menores proporcionalmente. O PC não muda.

### 2. Saldo + galho (MenuShell)
O galho sai do ScreenGui do menu (que respeita `CoreUISafeInsets`) e vai para uma camada sem a área segura. Pode ser o `MenuBackdrop` da árvore, que já é `IgnoreGuiInset` + `ScreenInsets.None`, mas precisa ficar acima da árvore e abaixo do card. A borda direita do galho fica na borda direita real da tela, e o topo encosta no topo da tela (as folhas passam por trás da barra do Roblox, como a árvore). O tamanho continua relativo ao card. O card do saldo fica na área segura (para continuar tocável), encostado na borda direita dela com a margem de sempre (8). A posição do card na tela inteira se lê do `AbsolutePosition` do ScreenGui do menu. O galho continua escondido na loja, como hoje.
**Só no compacto** (decisão do Elizeu, 17/11): no PC o galho fica como está hoje.

### 3. Loja paginada no celular (ShopLayout + ShopScreen + Passes/EmberPacks/Featured)
- `ShopLayout` ganha `paged = compact` e a altura livre da página (`pageHeight = height - contentTop - m`).
- Paginado: o ScrollingFrame mostra só a seção da aba ativa (as outras ficam com `Visible = false`). Tocar na aba troca a seção, sem animação de rolagem. `MenuState.openShop(section)` abre já na página certa. O título da seção continua em cima.
- Cada seção calcula seus cartões para caber em `pageHeight − título da seção`:
  - **Pacotes:** o banner do pacote em destaque usa a altura toda da página (hoje `bannerHeight` é 42% da altura). O estado "Nenhum pacote em destaque" também ocupa a página.
  - **Gamepasses:** hoje são cerca de 4 cartões (kits para sempre + passes de `ShopConfig.PASSES`). No compacto ficam numa fileira só, se couberem com largura mínima legível. Se não, vão em 2 fileiras. A altura do cartão é a altura livre dividida pelo número de fileiras. O conteúdo do cartão (arte, nome, "Para sempre", preço) se ajusta à altura, e a arte encolhe primeiro.
  - **Giros:** já cabe (`spinCardHeight` sai da altura livre). Só confirmar.
  - **Golden Ember:** os 5 pacotes numa fileira no compacto (hoje são 2 + 3), com a altura toda da página.
- Se o conteúdo ainda passar da página (tela menor que o previsto), a página rola. É reserva, não o normal.
- PC: lista contínua como hoje.

### 4. Ranking no celular (MenuShell + RankingScreen + RankingLayout)
Com o ranking aberto no compacto, o logo e o card da Golden Ember (com o galho) ficam escondidos. O painel começa em `podTop` (8), em vez de `bodyTop`, e vai até a borda direita com a margem de sempre. O cartão do jogador e a coluna à esquerda continuam. O `RankingLayout` recebe a altura maior e redistribui o pódio e a lista. Os textos minúsculos da auditoria (abas Jogadores/Criaturas, pódio de 10 px) sobem para no mínimo 12 px, aproveitando o espaço novo.

### 5. Configurações no celular (SettingsScreen + layout puro novo)
No `short()`, a janela usa quase a tela toda (`SHORT_WINDOW_SHARE`). O título continua em cima, com um X no canto superior direito (o Fechar de baixo sai). O "Resetar" vira um botão pequeno na linha do título, à esquerda do X. O corpo tem 2 colunas: **Som** à esquerda (3 linhas) e **Tela + Controles** à direita (tamanho da interface, qualidade, canhoto, zoom = 4 linhas + 2 títulos de grupo). As linhas têm 40 px de altura, a barrinha, a chave e as setas encolhem para caber na meia largura, e o texto fica em no mínimo 12 px. A distribuição sai de um módulo puro (ex.: `SettingsLayout`), que recebe os grupos e devolve coluna/posição de cada linha, com teste. Assim, uma opção nova entra na coluna com menos linhas. No PC fica como hoje.

### 6. Coluna de receitas do HUD (CraftColumn)
Hoje ela fica a 12% da altura, e o selo de pontos tem no mínimo 38 px a partir de 2%. No celular os dois se sobrepõem ~5 px. A coluna passa a começar logo abaixo do selo (base real do selo + 8 px), lida do selo ou calculada pela mesma regra. No PC a posição visual quase não muda.

### 7. Livro no celular (RecipeBookScreen + BookSheet)
No `short()`:
- O livro ocupa a área segura toda, com uma margem pequena. O título ("Livro de receitas" / "Modo criativo") vira uma placa baixa, e o X fica no canto.
- As abas mostram só o ícone (sem texto), com 44 px de altura.
- A grade fica à esquerda, com células de 48 (eram 58) e quantas colunas couberem em ~45% da largura. A ficha fica à direita.
- A ficha tem uma área de texto que rola (nome, descrição, "Como fazer", "Precisa de"). Embaixo fica uma **faixa fixa** com Pegar e/ou Fixar, e a área que rola termina acima dela, sem nada por cima do texto. Sem botões, a faixa some.
- No PC fica como hoje.

### 8. Zoom (Defs.Settings + CameraController)
- Nova opção `camera_zoom` (number, de 0 a 1, padrão 0,5, grupo "controls", texto "Zoom da câmera"). A barrinha vai de "perto" (0) a "longe" (1) e mapeia linearmente para a distância de 28 a 40. O padrão 0,5 fica em 34, que é o `DEFAULT_DISTANCE` de hoje, então ninguém sente diferença. O servidor valida como as outras opções.
- `CameraController` lê o atributo `Setting_camera_zoom` do Player e usa como distância-alvo, mudando quando o atributo muda.
- Celular: a conexão do `TouchPinch` sai. **Decisão do implementador:** ela sai para todo aparelho de toque, tablets inclusive. Lá também os dois polegares ficam nos analógicos e viram "pinça" sem querer, e o zoom continua disponível pelas Configurações.
- PC: a roda continua ajustando dentro de 28 a 40, a partir do valor da opção. Mexer na opção leva o zoom de volta ao valor dela. A roda não salva nada.

## Fica com o implementador

- Os números finos (altura exata do cartão de gamepass, colunas da grade do livro, larguras das barrinhas na meia coluna), desde que cumpram as metas e os mínimos (toque de 44, exceto a coluna do menu, e texto de 12).
- Se o galho vai para o `MenuBackdrop` ou para um ScreenGui novo.
- Como a coluna de receitas descobre a base do selo.
- A ordem dos commits (sugestão: um por tela). Antes de tudo, as mudanças do HUD de 12/11 que estão sem commit entram num commit próprio, para que este trabalho e as capturas de antes/depois partam de um ponto fixo (se o Elizeu autorizar o commit).

## Como saber que deu certo

- Testes do Lune passam, incluindo os novos para os layouts compactos (menu cabe em 330, loja paginada, settings em 2 colunas, livro) e para os de PC sem mudança.
- Capturas no emulador 749×330 de cada tela: nada cortado, nada rolando e nada sobreposto. O galho encosta no canto.
- Captura no PC (1280×720) das mesmas telas, igual ao antes.
