# Tutorial da primeira partida

Desenho: `docs/superpowers/specs/2026-11-10-tutorial-design.md` · Plano: `docs/superpowers/plans/2026-11-10-tutorial.md`

Todo perfil que ainda não completou o tutorial faz o tutorial na partida (é obrigatório, não tem pular). Ele acontece no mapa de sempre, com os outros jogadores: o jogador aperta Jogar e já está na etapa 1.

## As etapas

Ficam como dados em `src/shared/Tutorial/TutorialSteps.luau`. Para mudar a ordem, um número ou o texto, mexa só lá e nas chaves `tutorial.step.<id>` de `Strings/ptBR`.

| # | id | Completa quando | O que guia |
|---|---|---|---|
| 1 | `wood` | tem 10 madeiras | rastro até a árvore |
| 2 | `pickaxe` | tem a Picareta de Madeira | a receita pisca na coluna de receitas |
| 3 | `berries` | tem 5 frutinhas | rastro até o arbusto |
| 4 | `book` | a ficha da Fogueira aparece no livro | pisca o botão do livro, depois a aba Construções, depois a Fogueira |
| 5 | `campfire` | coloca uma Fogueira no chão | rastro até a árvore ou a rocha (o que faltar) e a receita pisca |
| 6 | `water` | fica 1,5 s na água do mapa | rastro até a água |

Tipos de meta (`goal.kind`):
- `have`: ter N do item no inventário. Se ele já tiver, a etapa passa sozinha, uma por vez.
- `view`: ver a ficha do item no livro.
- `place`: colocar o item no mundo.
- `drink`: ficar na água.

Em `sources` fica de onde sai cada item (o `ResourceId` do mapa), e é para lá que o rastro aponta; em `recipe`, a receita que pisca quando dá para fazer. As regras puras estão em `TutorialRules` (e `TrailRules` para os pontos do rastro), testadas em `tests/tutorialrules.spec.luau` e `tests/trailrules.spec.luau`.

## Proteção (10 minutos)

Enquanto está protegido, o jogador:
- não leva dano de nada (jogador, bicho, espinho, fome, sede, frio e fôlego). As barras descem normalmente, mas não machucam. O portão é `CharacterService.hurt`;
- não causa dano a jogador, bicho, caixa nem construção de outro dono (`GatherService`). Coletar recursos e mexer nas próprias peças é normal. O espinho dele também não machuca ninguém (`SpikeService`);
- não é visto pelos bichos (`MobService`, `viewOf`);
- só abre os próprios baús (`ChestService`) e não abre caixas de loot (`CrateService`);
- tem o selo **"Tutorial"** em cima do nome, que todos veem.

A proteção acaba ao completar a etapa 6 ou `TutorialRules.PROTECTION_SECONDS` (600 s) depois de nascer, o que vier primeiro. Se o tempo acabar, o tutorial **continua**, sem proteção, e ainda dá o prêmio.

## Começo, fim e o que fica salvo

- O `SpawnService` chama `TutorialService.begin` a cada vida. Se o perfil não completou, a vida é de tutorial e começa da etapa 1. **O progresso não é salvo**: cair ou sair no meio recomeça do zero.
- A vida de tutorial **não usa kit**: nada é aplicado nem gasto. No menu e na tela de morte, os kits ficam escondidos enquanto o tutorial está pendente, e o JOGAR fica no centro.
- **Ao completar:** `Tutorial.Done = true`, mais **2 giros normais** (`ShopService.give`), e o pop-up da roleta fica pendente (`Tutorial.SpinPopup = true`). Aparece um aviso de parabéns.
- **Pop-up da roleta:** na primeira vez no menu depois disso (ao morrer, ou numa sessão nova), "Você tem N giros!". "Ir para a roleta" abre a Loja na seção de giros, "Depois" fecha, e os dois avisam o servidor (`TutorialPopupSeen`), que apaga o pendente. Sem giros normais, não aparece.
- **No perfil** (`ProfileTemplate`): `Tutorial = { Done, SpinPopup }`.
- **Atributos do Player** (lidos pelo cliente em `TutorialState`):
  - `TutorialStep`: 0 = fora, 1..6;
  - `TutorialProtected`;
  - `TutorialPending`;
  - `SpinPopupPending`.

## Onde está cada parte

| O quê | Arquivo |
|---|---|
| Servidor (etapas, proteção, prêmio, perfil) | `src/server/Services/TutorialService.luau` |
| Estado no cliente | `src/client/TutorialState.luau` |
| Quadrinho da missão (embaixo dos botões redondos) | `src/client/UI/TutorialPanel.luau` |
| Rastro no chão | `src/client/World/TutorialTrail.luau` |
| Destaque dourado (receita, livro, aba, item) | `src/client/UI/TutorialGlow.luau` |
| Selo no nome | `Boneco/BonecoModel` (`TutorialBadge`) + `Boneco/BonecoRenderer` |
| Pop-up da roleta | `src/client/Menu/TutorialSpinPopup.luau` |
| Rede | `net/game.blink`: `TutorialBookViewed`, `TutorialPopupSeen`, `TutorialDone` |

## Testar no Studio

- `ServerStorage.DevTutorialReset:Invoke(player)`: o perfil volta a ter o tutorial pendente, sem pop-up. Vale a partir da próxima vida (aperte Jogar).
- `ServerStorage.DevTutorialDone:Invoke(player)`: dá como feito, sem prêmio, e encerra o tutorial desta vida.
- Na vida de tutorial, o `DevItemsService` **não dá o kit de teste**: ele completaria as etapas 1 a 3 sozinho. Para jogar com o kit, use `DevTutorialDone`.
- Para testar o fim da proteção sem esperar 10 minutos, baixe `PROTECTION_SECONDS` só no teste e volte para 600.
