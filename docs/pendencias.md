# Pendências pequenas (para mexer no fim)

Arestas que as revisões e os testes acharam e que não bloquearam o merge da fase. Nenhuma quebra o jogo; são acabamento. Quando resolver uma, apague a linha (ou marque a data).

## Atributos do Player (04/11)

- **Morte do mob frágil:** no `MobService.die`, o `ScoreService.add` roda fora do `pcall`; se falhar, a caixa (aviso `onDeath`) não sai. Foi assim que o limite de atributos derrubou os drops.
- **Folga no Player:** ainda são ~23 atributos lá (`Setting_*`, `Cosmetic_*`, barras...). Se as configurações crescerem muito, levar `Setting_*` para uma pasta também.

## Ranking semanal (UI 6, 09/11)

- **Abates no ranking não vistos no Studio:** a aba Criaturas (mob morto) e Jogadores (golpe final; também o "Jogadores mortos" do Perfil, que antes nunca somava) só foram conferidas pelo código. Testar jogando: matar um mob e abrir o Ranking (a gravação leva até 1 min; o cache do top, 3 min — ou `DevRankRefresh`). Jogadores precisa de 2 jogadores (teste multiplayer do Studio).
- **Tela empilhada (pódio em cima):** só em área estreita e em pé; coberta pelos testes do `RankingLayout`, não vista no Studio (o jogo é deitado).
- **Moderação só no Studio e desfeita no próximo abate:** `DevRankRemove` zera o perfil só se o jogador está online no mesmo servidor; offline, ele volta ao placar na próxima gravação. Antes da versão para o jogo publicado (painel de admin), guardar um marcador de banido por semana num DataStore comum e conferir antes de gravar.
- **Arestas da revisão (menores):** cache não guarda leitura que falhou (instabilidade lê de novo a cada troca de aba); nome "@id" fica para sempre se a busca de nomes falhar uma vez; resposta enviada a quem saiu no meio da leitura; nome cortado por bytes (`string.sub`) pode partir acento; `DevRankRemove` não valida a semana; Studio sem acesso às APIs avisa a cada minuto; tela aberta na virada mostra a semana velha até trocar de aba; comentário antigo em `ptBR.luau` (bloco mock) ainda cita o ranking.
- **Faixa clara da lista quase some no papel:** é a arte (`row_light.png`); se quiser mais contraste, pedir uma faixa um pouco mais escura ou com borda.

## Skins 3D (08/11)

- **Raridades das skins de corpo:** as 101 skins 3D estão todas com `rarity = 1` (Comum), então o giro de Skins só sorteia Comum. O Elizeu vai definir as raridades; depois religar a checagem "body: sem item de raridade" em `tests/mockstore.spec.luau` (giro do corpo, do livro e do acessório).
- **Kits sem mochila:** `kit_survivor` e `kit_veteran` não dão mais `leather_bag` (rebalanceio de 08/11); conferir se foi de propósito.

## Cosméticos (UI 5, 04/11)

- **Aparência em 3D a conferir quando os modelos das skins chegarem:** tamanho e posição da mochila nas costas (`BagModel`), enquadramento dos itens nos quadradinhos (`ItemViewport`), nomes pequenos nas amostras dos cartões da loja no celular.
- **Uma travadinha (~40 ms) no começo do giro:** os ~40 quadradinhos 3D novos nascem no mesmo quadro (`Reel`). Dá para espalhar a criação em alguns quadros.
- **Pacotes em destaque da loja** ainda usam a arte provisória (não são itens de giro).
- **Validação:** `inSpins` não tem o tipo conferido; faltam testes de caixa sem `crate` e de cor inválida em mochila/caixa; os três laços de cores do `Validate` são quase iguais.
- **Equipar:** reequipar a mesma skin salva de novo (os saves já são juntados); clique dentro de 0,2 s é ignorado (clique de novo); `selected` da grade não acompanha troca feita por fora da tela.
- **Miudezas:** cache do `ItemViewport` vive a sessão toda (comentar); `CratePreview` não usa o cache; o cabeçalho do `BagModel` fala de solda no mundo (a mochila só aparece no menu); prévia da caixa da tela principal fica viva com a janela fechada; `pageCount` com `perPage <= 0`; celular em pé (o jogo é deitado) deixa os quadradinhos pequenos; id de skin com mais de 48 letras num pacote forjado gera uma linha de erro no Output (igual a todos os eventos do Blink).

## Perfil e nível (UI 4, 04/11)

- **XP inicial avisa como ganho:** o `StatsService` chama `notifyChanged` de `xp_total` ao copiar o total de pontos. Quando o passe de batalha escutar `xp_total`, ignorar essa primeira cópia (ou trocar por só publicar o atributo).
- **Tempo de jogo no Perfil não anda ao vivo:** `playtime_seconds` só soma no save (autosave ou fim de vida); com o Perfil aberto o número fica parado até o próximo save.
- **`real_deaths` entra num save depois:** é somado depois do `endLife` (que já salvou); se o servidor cair antes do próximo autosave, essa morte se perde (o XP não). Basta somar antes do `endLife` (`DeathService`).
- **Texto sem uso:** `menu.mockup` em `ptBR.luau`.
- **Comentário antigo:** `DeathService` (~linha 51) lista só Days, Points e Currency nos limites do `LifeEnded`.
- **Janela do teto no futuro:** se `HourWindowStart` vier maior que `now` (relógio de servidores diferente), o teto de XP fica travado até o relógio alcançar. Recomeçar a janela também quando `now < HourWindowStart` (`LevelRules`; a Golden Ember tem o mesmo jeito).
- **Atualização com servidores antigos abertos:** quem já recebeu o XP inicial e joga uma vida num servidor antigo não ganha XP por essa vida (só pontos). Janela curta; aceito.

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

## Loja (UI 2, 04/11)

- **Fechar a loja no meio de um giro perde o giro:** pela tela não dá (o X fica travado e a tela do giro cobre o voltar), mas se a loja fechar por outro motivo o contador já desceu e não sai prêmio (`SpinScreen`, reset ao fechar).
- **Relógio do destaque roda a sessão toda:** uma volta por segundo, também durante o jogo (não vaza; para quando o menu desmonta). Ideal: só contar com a loja aberta (`Featured`).
- **Roletas giram com a loja aberta mesmo fora da tela:** o spec pedia só com a seção visível (`SpinTypes`).
- **Tamanho do quadradinho do carrossel fixo ao abrir o giro:** girar o celular (entrar/sair do compacto) com a tela aberta deixa o tamanho antigo (`SpinScreen`).
- **Efeitos com posição tirada uma vez:** se a tela mudar de tamanho durante o giro pago, os raios e a tremida usam a posição antiga (`SpinFx`).
- **Aviso de compra simulada no celular cobre o carrossel por 2,5 s** (posição vem do `MenuLayout`).

## Carregamento, menu e kits (UI 1, 04/11)

- **Tela mínima com interface no máximo:** em 568x320 com o tamanho da interface em 1,25 (tela lógica 454x256), os pods do topo (mínimo 200) encostam no logo e a linha Kits/JOGAR fica 12 px mais larga que a área do boneco. Ideal: deixar o pod encolher ou esconder o logo quando não couber (`MenuLayout`, `MenuShell`).
- **Pontos do kit dependem do molde da morte:** a fonte de pontos do `KitList` só nasce no `KitList.mount`, chamado pela tela de morte. Sem o molde `Death`, escolher kit de pontos no menu não faz nada. Ideal: criar a fonte no `KitShop`/`MenuShell`.
- **Imagem com id que não carrega:** sol e lua só viram círculo quando o id está vazio; se o Roblox recusar a imagem, eles somem (a tela continua funcionando). Ideal: conferir `IsLoaded` depois de um tempo (`Loading.client.luau`).

## Mockups do menu (G7a, 02/11)

- **Celular pequeno em paisagem:** o menu novo (UI 1) cabe de 568x320 a 1920x1080 (teste do `MenuLayout`) e foi visto no Studio com o tamanho da interface em 2 (tela lógica 577x367), mas ainda não num aparelho de verdade.

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
