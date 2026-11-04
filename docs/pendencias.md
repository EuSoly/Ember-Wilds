# Pendências pequenas (para mexer no fim)

Arestas que as revisões e os testes acharam e que não bloquearam o merge da fase. Nenhuma quebra o jogo; são acabamento. Quando resolver uma, apague a linha (ou marque a data).

## Estruturas da floresta (G8, 03/11)

- **Item `testOnly` e o inventário:** `equipBag` não passa pelo `ItemAccess`; os caminhos de devolução (reembolso) podem perder um item indisponível (só no Studio); o `Validate` de kit com `testOnly` não derruba o `allValid`; testes finos de `give`, `place` e início; `IsStudio()` é chamado a cada uso.
- **Importação:** peças invisíveis contam no tamanho do template.
- **Portas e visual:** os ramos da porta e do fogo no `StructureModel` são fixos por kind; folhas aninhadas não deslizam; os tweens não são guardados; o atributo `PanelClosed` replica; o colisor da parede (4 de altura) é maior que o visual (2); a porta aberta entra um pouco na parede vizinha; o tween da porta é no servidor.
- **`StructureFx`:** a cada quadro faz `IsDescendantOf`/`GetAttribute` mesmo em peça sem partes móveis; `Visual` trocado não limpa os movers antigos; o rotor mantém o ângulo ao parar; checagem redundante (~linha 150).
- **Ícones 3D:** o `ViewportFrame` e a câmera nascem mesmo sem template; sem cache de clones; ícone criado antes do `Assets` chegar fica com as iniciais; modelos achatados ocupam ~70% do slot.
- **`Validate`:** `extractor.output` não é conferido contra `Items`.
- **`StructureService.hit`:** o toggle de aliado só vale para os kinds de porta (conferir se vem de `isDoor` em tudo).
- **Painel de interação:** repete as alturas do painel do baú e da caixa (pode divergir); a janela de taxa é fixa e aceita rajada; o alcance do cliente (pivô) e o do servidor (entrada x/z) diferem um pouco a 8 studs; `interact.symbol` não é usada; o painel de símbolos não tem título e usa `LayoutOrder` fixo; esconde botões dos aliados mesmo o servidor aceitando.
- **Máquinas:** `MachineService.step` refaz as tabelas a cada tick; extrator parado zera o progresso do ciclo; extrator e fornalha: qualquer um põe madeira, só o dono pega (aliados só com os times); `Station` fica na fornalha apagada (a tag sai); sem teste automático do serviço.
- **Poço e balde:** ramos do `InventoryService.swapAt` sem teste; `isWaterAt` repete trecho do `isWet`; o laço de encher consulta todos os jogadores.
- **Cama:** pular ou andar contra uma parede não levanta (só XZ > 0,5); a janela de 0,6 s de acomodação reamostra; o boneco não deita (cai pelo chão da cama); queda de vida que não é dano pode levantar sem querer; dano de sobrevivência (`HurtAt`) levanta.
- **Placa:** reordenar `SYMBOLS` muda as placas já colocadas; sem testes de serviço e painel.
- **Ponte e telhado:** ponte no meio do lago vira lugar seguro dos mobs; bater no ar sob o próprio telhado o machuca; `RoofFade` só cobre as partes que já existem; sem testes do `TaggedCircles`; `r` x `radius` no nome; linha de comentário longa no `GatherService`.
- **Porta com espinhos:** sem teste Lune da recusa do toggle nem do dono ignorado (código de serviço).
- **Bancada das estruturas:** cópia de atributo repetida (`structure-bench.luau` ~linhas 275-277); sem aviso para template com `PrimaryPart`; `difference()` compara por índice (falha para o lado seguro).

## Mockups do menu (G7a, 02/11)

- **Prévia do boneco sem `vide.cleanup`:** se a raiz do Vide fosse desmontada com Cosméticos aberto, o boneco ficaria. Na prática a raiz nunca desmonta.
- **Nome sobrando no modelo da prévia:** o modelo carrega o `BillboardGui` de nome, que não é usado.
- **Código repetido nos 5 painéis:** botão, rolagem e painel são reescritos em cada um (ex. o `actionButton` da `ShopPanel` e o Comprar da `BuyPanel`); e o `actionButton` devolve `any`.
- **`MockStore.roll` recebe `{ Odd }`:** o luau-lsp não aceitou uma versão genérica.
- **Celular pequeno em paisagem:** o menu novo (UI 1) cabe de 568x320 a 1920x1080 (teste do `MenuLayout`) e foi visto no Studio com o tamanho da interface em 2 (tela lógica 577x367), mas ainda não num aparelho de verdade.
- **`Spin.kind` do `MockStore` é `string`:** podia ser a união `"skin" | "custom"`.
- **`MockStore.roll` com lista vazia devolve 0:** índice que não existe; hoje nenhum giro tem a lista vazia.
- **`elseif preview ~= nil` redundante na `CosmeticsPanel` (~linha 100):** o `if` logo acima já trata o mesmo caso.

## Caixas e combate (G6, 02/11)

- **Inventário cheio ao saquear:** clicar num item da caixa com o inventário cheio não faz nada e não mostra aviso. Ideal: um aviso como o "inventário cheio" da coleta (`CrateService` ~linha 352).
- **Caixa depois de cair do mapa:** quem morre caindo pode deixar a caixa numa posição velha (sem a raiz do personagem, ela usa o pivô do modelo). Raro (`CrateService` ~linha 398).
- **Painel da caixa vazio com ping muito alto:** o cliente só avisa qual caixa está olhando quando a caixa mais perto muda; se o servidor recusar esse aviso, o painel fica vazio até se afastar e voltar. Ideal: reenviar a cada ~1 s enquanto o painel estiver vazio (`CrateState`). Também mostra a grade vazia por um instante antes do conteúdo chegar.
- **Caixa não impede construir em cima:** o raio da caixa só vale para o golpe; uma peça pode ser colocada em cima de uma caixa (o `StructureService.canPlace` não olha as caixas).
- **Conteúdo da caixa para quem já foi embora:** o servidor continua mandando o conteúdo para quem olhou a caixa e não avisou que parou (só informação; pegar continua conferindo a distância).
- **Teste automático do saque:** a lógica de pegar da caixa podia ir para `CrateRules` com um teste no Lune.
- **Validação do loot dos mobs:** o `Validate` não confere se cada entrada do `loot` é uma tabela com `id` texto (dado nosso; um erro aparece na hora mesmo assim).
- **Comida com cura acima de 100:** o `Validate` ainda limita `food.health` a 100; se um dia uma comida curar mais que 100 (vida agora é 200), mudar o limite.
- **Texto da regeneração** em `docs/guia/sobrevivencia.md` está confuso.

## Mobs (G5, 02/11)

- **Lobo de tocaia no nascimento:** como o jogador sempre renasce no mesmo ponto, um mob pode ficar esperando ali. Some quando entrar o nascimento aleatório na floresta.
- **Hotbar depois de morrer:** o cliente continua marcando o slot da vida anterior e apertar esse número não faz nada até trocar para outro slot.
- **Matar fugindo de lança é lento:** o empurrão (4 studs) joga o mob para fora do alcance (lobo ≈ 30 s). Ajuste: `knockback` das lanças em `Defs/Items.luau` (até 3,5 ainda segura o falcão).
- **Testes pequenos que faltam:** escorregar começando colado, `blocked` junto com círculos, noite de javali/falcão, troca de alvo `target` nil → `nearest`.
- **Pequenos detalhes de código:** `RESOURCE_SEARCH` fixo no `MobService`; raycast do `DevSpawnMob` não ignora os recursos; `TELEPORT_DISTANCE` local no `MobRenderer`; `WebVisual` refaz a lista de peças a cada quadro.

## Construção (G4, 01/11)

- Limite de quão rápido dá para colocar peças.
- Desempenho da barrinha de vida das peças com bases muito grandes.
- Porta abre e fecha a cada golpe enquanto o clique fica segurado.
- Cantos de blocos girados se cruzando um pouco na tela (até os modelos finais).
- Apertar R e soltar o clique quase juntos pode construir com o giro anterior.
- Caso raro do botão "+" do baú segurado.
