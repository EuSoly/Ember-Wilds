# Pendências pequenas (para mexer no fim)

Arestas que as revisões e os testes acharam e que não bloquearam o merge da fase. Nenhuma quebra o jogo; são acabamento. Quando resolver uma, apague a linha (ou marque a data).

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
