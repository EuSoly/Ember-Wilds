# Auditoria das UIs no celular (12/11/2026)

Emulador do Studio, celular deitado: tela de 749×388, área útil de 330 de altura (barra do Roblox de 58), toque ligado, UIScale 1. Capturas em [auditoria-celular/](auditoria-celular/). Gabarito: seção 8 do [design system](design-system/README.md): alvo de toque ≥ 44×44, margem ≥ 12 no compacto, centro do HUD livre, zonas de baixo reservadas para movimento e mira.

Como as telas foram abertas: um LocalScript temporário criado no Play (some ao parar) chama `MenuState`, `SettingsScreen`, `ScreenState` etc. de verdade. Medidas tiradas de `AbsoluteSize`/`AbsolutePosition`, em pixels da área útil.

## Quebrado (some conteúdo ou não dá para tocar)

| # | Tela | Problema | Medida |
|---|---|---|---|
| 1 | Menu | O botão **Configurações** sai pela borda de baixo. O cartão do jogador e os 6 botões não cabem em 330 de altura | `Nav_settings` em y 314–358 |
| 2 | HUD / baú | O painel do baú fica **embaixo dos anéis de status** | baú 64×64 em y 190–254; anéis em y 216–271 |
| 3 | HUD / máquinas | O painel do extrator e das máquinas também fica embaixo dos anéis, e cobre o personagem | `InteractPanel` 298×164 em y 90–254 |
| 4 | HUD / baú | O "+" de guardar no baú, em cada slot da hotbar, é pequeno demais para o dedo | 17×17 |
| 5 | HUD / tutorial | O quadrinho do tutorial passa por baixo do analógico de mira e o texto fica cortado | quadrinho em y 142–212; analógico a partir de y 182 |
| 6 | HUD / avisos | A área das notificações cai em cima do analógico (com tutorial) ou do botão Missões (sem tutorial) | 194×52 em y 215 ou y 142 |
| 7 | HUD | O slot 10 da hotbar encosta no analógico de mira | ~7 px de sobreposição |
| 8 | Livro | **Pegar/Fixar** cobrem o "Como fazer" (os ingredientes), e só aparecem 2 linhas da grade | livro 674×288 |

**Itens 2–7 corrigidos em 12/11** (faixa de baixo do HUD no toque; ver "Celular" em [docs/guia/hud.md](../guia/hud.md)). Medido no emulador depois da mudança:
- **Hotbar:** linha de 10, de x 136 a 612; o analógico de mira começa em 627.
- **Anéis:** y 216–271.
- **Painéis:** o do baú fica em y 144–208 e o do extrator em y 44–208.
- **Baú no celular:** o botão Guardar cobre o slot inteiro (44×44).

Capturas: `depois-16-hud.jpg`, `depois-19-bau-guardar.jpg`, `depois-20-extrator.jpg`.

Não verificado pelo MCP: o toque no slot com o Guardar ligado. O clique do MCP vira mouse no emulador, e no modo criativo o baú recusa itens de propósito.

## Corrigido em 17/11 (branch `ui-celular`)

Pedido do Elizeu: no celular, cada tela cabe inteira, sem rolar. Design em [2026-11-17-ui-celular-design.md](../superpowers/specs/2026-11-17-ui-celular-design.md), plano em [2026-11-17-ui-celular.md](../superpowers/plans/2026-11-17-ui-celular.md). Conferido no emulador (749×330, "Tamanho da interface" 95%); capturas `1711-*` em [auditoria-celular/](auditoria-celular/).

| Tela | Como ficou no celular |
|---|---|
| Menu (1) | Botões da coluna de 40 (exceção aos 44 de toque, pedida pelo Elizeu) e cartões do topo de 48: os 6 botões cabem sem rolar |
| Saldo | O galho fica no fundo sem área segura (`MenuBackdrop`) e encosta no canto de cima e na borda direita da tela |
| Loja (12) | Uma página por aba. Pacotes, Gamepasses (5 numa fileira) e Giros cabem sem rolar. A Golden Ember rola: a fileira de cima ocupa a página e a de baixo aparece um pouco, e a barra de rolagem fica laranja quando há o que rolar. Com fita (POPULAR...), o número desce para baixo dela. Lados do giro sem rolar; janela "Você ganhou" cabe na tela; o aviso "Comprado!" vira um toast embaixo |
| Ranking (13) | Sobe até o topo, sem logo, saldo, galho nem cartão do nível; textos das abas e do pódio com no mínimo 12 px |
| Kits (9) | Sobem até o topo como o ranking, em duas colunas de cartões: os 4 kits cabem sem rolar |
| Configurações (11) | Duas colunas (Som \| Tela + Controles), título, Resetar e X na mesma linha; nova opção **Zoom da câmera** |
| HUD | A coluna de receitas não encosta mais no selo de pontos |
| Livro (8) | Ocupa a tela, abas só com ícone, grade de 48; Pegar e Fixar embaixo da grade, a ficha usa a altura toda |
| Câmera | Pinça desligada no toque; zoom pelas Configurações (no PC a roda continua) |

**Com "Tamanho da interface" em 125%** (varredura automática de tudo que sai da tela, sem contar o que está dentro de listas que rolam): menu, kits, ranking, loja, giro, configurações e livro sem nada para fora. Rolam como reserva: a coluna do menu e as colunas das Configurações.

## Ruim (funciona, mas atrapalha)

| # | Tela | Problema |
|---|---|---|
| 9 | Kits | O "+" de saldo tem 24×24; só aparece um kit por vez; o painel cobre o boneco |
| 10 | Missões | As abas têm 38 de altura (< 44). Não deu para ver o conteúdo: o Studio está em modo criativo e as missões ficam desligadas |
| 11 | Configurações | Só aparecem 2 opções por vez; Resetar e Fechar ocupam a parte de baixo (o padrão de tela baixa era trocar o Fechar por um X); o interruptor de canhoto tem 64×32 |
| 12 | Loja | Os cartões são enormes: em Gamepasses e Golden Ember aparece uma linha cortada por vez. No pacote em destaque, a lista de itens tem 10 px e fica cortada pelo botão de preço. Os textos das abas "Gamepasses" e "Golden Ember" ficam minúsculos |
| 13 | Ranking | O texto das abas Jogadores e Criaturas fica minúsculo; o pódio tem textos de 10 px; o meio da lista fica vazio; a janela passa da borda de baixo |
| 14 | Janelas do menu | Em Perfil, Cosméticos, Missões e Configurações, o X fica em cima do saldo de Golden Ember |
| 15 | Geral | Textos de 9 a 10 px: nomes das skins e das amostras do giro, chances do giro, selo "Tutorial" |

## Bom no celular

Carregamento, popup "Você tem 6 giros", tela de morte, tela do giro (fora os textos pequenos), mochila, HUD básico (status, hotbar de 44, botões de 44, relógio, pontos, minimapa) e as Skins (grade 3×3 com páginas).

## Não coberto ainda

Celular pequeno (iPhone SE) e tablet; modo canhoto; escala de UI 1,25; conteúdo das Missões fora do criativo; tela de prêmio do giro; painel da caixa de morte; notificação de verdade na tela; equipe; banner de missão.

## Proposta

Não precisa refazer a identidade visual: madeira, papel e cores funcionam no celular. O que falta é uma **composição compacta** (a seção 8 já pede isso: "muda a composição; não reduz a tela inteira"):

1. **Faixa de baixo do HUD (itens 2–7).** Os painéis do baú e das máquinas sobem para acima dos anéis. No celular, tocar no slot inteiro guarda no baú, em vez do "+" de 17 px. O tutorial e as notificações saem da coluna do analógico e vão para o topo central, embaixo do relógio. A hotbar respeita a borda do analógico (ou usa as duas linhas de 5 previstas na seção 8).
2. **Menu compacto (1, 14).** A coluna rola ou fica mais baixa (botões de 40 + espaçamento menor não bastam com 44 mínimo, então rolar ou levar Configurações para uma engrenagem no topo). Com uma janela aberta, o saldo esconde ou a janela começa abaixo dele.
3. **Livro (8).** As ações vão para baixo do texto rolável da receita; a grade ganha altura.
4. **Loja e Ranking (12, 13).** Cartões mais baixos no compacto (2 a 3 por linha), texto mínimo de 12 px e abas com rótulo legível.
5. **Mínimos globais (9–11, 15).** Alvo ≥ 44 e texto ≥ 12 em toda tela compacta. Vale criar uma checagem automática no Play (a mesma varredura desta auditoria).
