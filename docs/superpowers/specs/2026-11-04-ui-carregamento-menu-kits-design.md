# UI 1: carregamento, menu e kits (design)

Data: 2026-11-04. Aprovado pelo Elizeu no chat (resumo e preview). Primeira fase da troca das telas para o [design system rústico](../../game-design/design-system/README.md). As outras telas (morte, HUD, loja, cosméticos…) vêm depois, uma de cada vez.

Preview aprovado: [docs/game-design/propostas/menu-v1/preview.html](../../game-design/propostas/menu-v1/preview.html) (abrir no navegador; animação do carregamento incluída). Logo: [assets/ui/brand/](../../../assets/ui/brand/).

## Intenção

O jogador abre o jogo pelo Roblox, vê uma tela de carregamento com a cara do jogo, cai num menu limpo com o **próprio boneco no centro** e decide rápido: escolher (ou não) um kit e apertar JOGAR. O menu atual mostra a lista de kits o tempo todo e tem visual provisório; o novo esconde os kits atrás de um botão, segue o design system e já prepara duas coisas futuras: **skins de livro** (o boneco aparece segurando um livro) e **kits pagos com Robux**.

## Decisões do Elizeu

### Logo
- O logo é o da prancha aprovada (tábuas + chama + "EMBER WILDS"). Extraído com fundo transparente em `assets/ui/brand/ember-wilds-logo.png` (1200×804, ampliado 4× da prancha; serve para menu e carregamento) e `ember-wilds-logo-original.png` (tamanho original ~300 px). Uma versão em alta resolução fica para quando o logo for usado grande (capa do jogo).

### Tela de carregamento
- Fundo = **arte do Elizeu**, que ele adiciona depois (imagem cobrindo a tela). Até lá, um fundo provisório.
- **Logo** em cima, **barra de carregamento** embaixo.
- Um **sol anda junto com a ponta da barra**, da esquerda para a direita. **Ao passar da metade vira lua e a barra escurece.**

### Menu
- **Botões das telas na coluna da esquerda** (madeira, do design system).
- **Boneco do jogador no centro, segurando um livro** (futuramente haverá skins de livro). O boneco usa a skin de corpo do jogador.
- **Nível continua onde está hoje** (canto de cima à esquerda, com a barra de XP); saldo no canto de cima à direita, como hoje.
- **Opção B**: embaixo do boneco, lado a lado, o botão **Kits** (couro) e o **JOGAR** (brasa). Kits **não** fica na coluna.

### Kits
- Os kits **não aparecem direto**: o botão Kits abre um painel de papel à direita, com o boneco ainda visível. Fechar volta ao menu.
- Cada kit pode ser obtido de **três jeitos**:
  1. **Pontos, 1 vida** (o que existe hoje: pontos da vida anterior, `KitPoints`).
  2. **Robux, 1 vida**.
  3. **Robux, permanente**.
- Kit **permanente** pode ser **ativado**: a partir daí vem sozinho em **toda vida**. O jogador fica livre para trocar: ativar outro permanente, ou comprar outro kit para uma vida.
- **Preços em Robux provisórios** (o Elizeu ajusta depois).

## Escolhas minhas (aprovadas no resumo)

- O fundo do carregamento também anoitece (estrelas) junto com a barra; o texto muda na metade ("Carregando o mundo…" → "Acendendo as fogueiras…"); uma dica curta embaixo.
- A barra só chega a 100% quando o jogo **e** o perfil estiverem prontos (`DataReady`), como o `Loading.client.luau` já faz hoje. A passagem pela metade (sol → lua) acontece naturalmente pelo avanço da barra.
- Logo pequeno no topo do menu, entre o nível e o saldo.
- **Um kit por vida**, como hoje.
- Kit de 1 vida (pontos ou Robux) escolhido com um permanente ativo: **nessa vida vai o de 1 vida**; o permanente volta na vida seguinte.
- O botão Kits mostra embaixo do nome qual kit vai junto ("Nenhum", "Explorador"…).
- **Compra com Robux continua simulada nesta fase**, como o resto da Loja (G7a): mostra o aviso "compra simulada", não chama `MarketplaceService`, não salva nada. Comprar Robux de verdade é a fase seguinte.

## Escolhas minhas (registradas aqui, ainda não vistas pelo Elizeu)

- **Configurações** sai do molde `MainMenu` e vira o **último botão da coluna** ("Configurações", com ícone de engrenagem). Coluna final: Perfil, Cosméticos, Loja, Tutorial, Ranking, Configurações. O botão "Jogar" sai da coluna (o JOGAR vive embaixo do boneco).
- **Câmera do menu continua** passeando pelo mapa (SpectateService) atrás de tudo. O boneco fica num `ViewportFrame` por cima, sobre uma sombra no chão, para não depender de onde a câmera está. A "cena" do preview é só ilustração.
- **Livro na mão do boneco:** usar o modelo que **já existe** do Elizeu, `ReplicatedStorage.Assets.Tools.book` (Tool com Handle, ~3,1×3,3×0,5; fonte em `assets/tools/roblox/individual/book.fbx`; vive só no place). O livro do preview (aberto) é só ilustração: vale o modelo dele como está, segurado na frente do boneco. O boneco do menu usa um **clone** desse modelo (não mexe no original nem no item `book` do jogo). Isso já deixa o lugar para o slot de cosmético "livro" no futuro (trocar qual modelo é clonado), mas **o slot não é criado nesta fase** (não há skins de livro ainda). Obs.: existe uma cópia solta `Workspace.book` no place, provavelmente sobra de bancada; não usar.
- **Tela de morte não muda** nesta fase: continua com a lista de kits de hoje (só pontos). Ela compartilha a seleção de kit de pontos com o menu (`KitList.selected`), então escolher na morte continua valendo no menu e vice-versa. O redesenho dela vem numa fase própria.
- **Kits de Robux e permanentes são estado de mockup**: posse e kit ativo ficam num estado local do cliente (junto do `MockStore`), não são salvos e **não mudam o que o servidor dá ao nascer**. Ao apertar JOGAR, só o kit de **pontos** (se escolhido) vai no `Net.RequestSpawn` como hoje. Para o desenho mostrar o estado "permanente", o mockup já começa com **um kit marcado como permanente** (sugestão: Iniciante), com o botão verde "Usar (grátis)"/"Ativo".
- **A compra simulada muda o estado local do mockup** (diferente do resto da Loja da G7a, que só avisa): além do aviso "compra simulada", comprar "1 vida" com Robux **escolhe** aquele kit para esta vida, e comprar "para sempre" o marca como permanente (pode ser ativado). Assim o fluxo inteiro pode ser testado no Studio. Nada é salvo; ao sair do jogo, volta ao início. Regras do estado:
  - Escolha de 1 vida é **uma só**: escolher um kit de pontos limpa a escolha de Robux de 1 vida e vice-versa. A escolha de pontos continua sendo `KitList.selected` (compartilhada com a tela de morte); a de Robux fica no estado do mockup.
  - Ativo permanente: no máximo um. Ativar outro troca; clicar em "Ativo" desativa.
  - Kit desta vida (o que o botão Kits mostra): escolha de 1 vida, senão o permanente ativo, senão "Nenhum".
  - A escolha de Robux de 1 vida é **gasta ao apertar JOGAR** (some depois de nascer), como uma compra de 1 vida faria. O permanente ativo continua.
  - Quando o kit desta vida não é de pontos, o botão Kits mostra o nome com "(simulado)", porque o JOGAR não leva esse kit ao servidor. A tela de morte continua mostrando só a lista de pontos.
- **Skin do boneco do menu**: hoje a skin de corpo equipada só existe como atributo `Cosmetic_body` no **personagem**, e no menu não há personagem. Pequena mudança no servidor: o `CosmeticService` passa a gravar também o mesmo atributo no **Player** (mesmo valor, sempre que o equipado mudar e ao carregar o perfil), e o boneco do menu lê dali. Sem atributo, usa a skin padrão (`CosmeticSlots.body.default`). A escolha de mentirinha do painel Cosméticos (mockup) **não** muda o boneco do menu.
- **Imagens** (logo, sol, lua, fundo provisório): o jogo é da conta do Elizeu (CreatorType User), então quem implementa envia as imagens pela ferramenta do Studio, **na conta dele, pedindo confirmação antes de enviar**, e grava os ids num só lugar do código/molde. Se uma imagem faltar, a tela continua funcionando (sol/lua podem cair para um círculo desenhado com Frame).
- **Ritmo da barra**: o progresso falso de hoje chega à metade em ~0,5 s, rápido demais para ver o sol. Quem implementa ajusta o ritmo para o sol aparecer por um tempo perceptível, sem atrasar o jogador quando o carregamento real termina (ao ficar pronto, a barra corre até o fim).
- Ícones de navegação e dos kits: enquanto os ícones finais do design system não existem, usar texto + os ícones de item que já existem (`ItemIcon`) nos kits. Nada de emoji no jogo.

## O que aparece em cada tela

### Carregamento (`src/first/LoadingScreen` + `Loading.client.luau`)
| Elemento | Comportamento |
|---|---|
| Fundo (`Art`, ImageLabel cobrindo a tela) | Provisório até o Elizeu enviar a arte; ele troca só a imagem |
| Céu da noite (`Night`, por cima do fundo) | Transparente de dia; aparece (escurece o fundo, estrelas) depois da metade |
| Logo (`Logo`, ImageLabel) | Imagem do logo enviada ao Roblox |
| Trilho de madeira (`Track`) e preenchimento (`Fill`) | `Fill` cresce de 0 a 1 em `Size.X.Scale` (já funciona assim). Brasa até a metade; depois da metade o trilho escurece e o preenchimento fica azul-noite |
| Sol (`Sun`) e lua (`Moon`) | Seguem a ponta do `Fill`. Até 0,5 mostra o sol; de 0,5 em diante, a lua |
| Texto de estado (`StatusLabel`) e dica (`TipLabel`) | Texto muda na metade. Textos fixos no código do carregamento (Strings ainda não chegou ao cliente nessa hora) |

Continua valendo: tudo dentro do `CanvasGroup` `Root` (fade ao sair), o molde segue sendo editável no Studio, e elemento faltando não quebra (o script procura pelo nome e ignora o que não existe).

### Menu (casca `MenuShell` + painel "play")
- **Topo esquerdo**: placa de nível + XP (dados ainda falsos, com a etiqueta MOCKUP, como hoje).
- **Topo centro**: logo pequeno.
- **Topo direito**: saldo real de Golden Ember + "+" (abre o painel de compra, como hoje).
- **Coluna esquerda**: Perfil, Cosméticos, Loja, Tutorial, Ranking, Configurações. Abrir um painel funciona como hoje (`MenuState.open`); Configurações abre a janela de configurações existente.
- **Centro**: boneco com a skin de corpo do jogador, segurando o livro, sobre uma sombra.
- **Embaixo do boneco**: `Kits` (couro, com o kit escolhido embaixo do nome) e `JOGAR` (brasa).
- Com outro painel aberto (Perfil, Loja…), o boneco e os botões Kits/JOGAR se escondem, como o painel "play" faz hoje.

### Painel de kits
- Folha de papel à direita, título "ESCOLHA SEU KIT", fechar no canto. Mostra "Seus pontos: N".
- Uma linha por kit (ordem de `Defs.Kits`): ícone, nome, itens, e os botões:
  - **Pontos · 1 vida**: preço real de `Defs.Kits`. Sem pontos suficientes: cinza, "faltam N", sem clique. Clicar escolhe (de novo, desfaz), igual ao `KitList` de hoje.
  - **Robux · 1 vida** e **Robux · para sempre**: preços provisórios; clicar mostra "compra simulada" e muda o estado local (veja as regras acima).
  - Kit permanente: os botões viram um só, verde: **"Usar"** (ativar) ou **"Ativo"** (já ativado; clicar desativa).
- Kit escolhido/ativo ganha a borda de brasa.
- O botão Kits embaixo do boneco mostra o kit que vai nesta vida, pela regra: de 1 vida, se houver; senão o permanente ativo; senão "Nenhum".
- No compacto (celular), o painel ocupa a área à direita da coluna e o boneco pode ficar escondido atrás dele.

### Preços em Robux provisórios
| Kit | 1 vida | Permanente |
|---|---|---|
| Iniciante | 15 | 99 |
| Explorador | 25 | 199 |
| Sobrevivente | 49 | 399 |
| Veterano | 99 | 799 |

Ficam no `MockStore` (são dados de mockup), não em `Defs.Kits`, até a fase da compra real.

## Restrições

- Seguir o [design system](../../game-design/design-system/README.md): materiais, cores (tokens), chanfros, botões de 44 px de toque, ritmo de espaçamento, regras de compacto (largura < 900 ou altura < 500). Layout conferido nas resoluções da seção "Critérios de aceite visual" do design system.
- Textos novos no `src/shared/Strings/ptBR.luau` (exceto o carregamento, que tem textos fixos).
- Mockup continua sem rede, sem atributos escritos e sem `MarketplaceService` (regra da G7a).
- No servidor, só a mudança da skin no Player (acima). `SpawnService` continua recebendo só o kit de pontos.
- Imagens (logo, sol, lua, fundo provisório) precisam ser enviadas ao Roblox e referenciadas por id; o código não pode quebrar se a imagem ainda não carregou.
- Código legível para nível médio, comentários do porquê em pt-BR, identificadores em inglês, `--!strict`; `bash scripts/check.sh` verde.
- Atualizar `docs/guia/telas.md` (nomes combinados novos do carregamento, casca nova, painel de kits) e rodar a atualização do graphify.

## Fora desta fase (não fazer)

- Compra real com Robux (gamepass/dev product), salvar posse de kit e kit ativo, servidor dar kits de Robux.
- Slot de cosmético "livro" e skins de livro.
- Redesenho da tela de morte, HUD, loja, cosméticos, perfil, ranking, tutorial, configurações.
- Nível/XP de verdade.
- Arte final do fundo do carregamento (é do Elizeu) e versão em alta resolução do logo.

## Deixado para quem implementa

- Se a casca continua em Vide (como a G7a) ou parte vira molde do Studio; a única exigência é que o carregamento continue molde (roda no `ReplicatedFirst`) e que o Elizeu consiga trocar a arte de fundo só trocando uma imagem.
- Como desenhar as molduras (9-slice com imagem, ou Frames + `UIStroke`/`UIGradient` imitando os materiais) enquanto a arte final dos componentes não existe.
- Ângulo de câmera e pose do boneco com o livro no `ViewportFrame` (referência: o preview e a prévia do `CosmeticsPanel`).
- Desenho do sol e da lua (referência: preview).
- Animação suave do sol → lua e da troca de cor (tempos do design system: ~120–180 ms).
