# Tutorial da primeira partida — design

Data: 10/11/2026 · Branch: `qol`

## Por quê

Hoje o jogador novo cai na floresta sem saber o que fazer primeiro: de onde vem a madeira, como se faz uma picareta, que a fogueira esquenta, onde beber água. O Elizeu quer um tutorial curto **dentro da primeira partida de verdade**, sem uma fase separada, que ensine as necessidades básicas na ordem em que o jogador vai sentir cada uma. No fim, ele ganha giros e é levado à roleta, para conhecer a loja usando o prêmio.

## Objetivos

- O jogador novo aprende, fazendo: coletar, craftar, ler o livro de receitas, construir uma fogueira e beber água.
- Ele não morre nem atrapalha ninguém enquanto aprende.
- No fim, recebe **2 giros normais** e, depois que essa vida acabar, é convidado a girar na roleta.

## Não objetivos

- Não ensina combate, base, baús, armadura nem a loja em si (a roleta só é mostrada).
- Não é uma fase ou mapa separado.
- Não tem tutorial repetível nem menu "rever tutorial".

## Antiobjetivos (o que seria um fracasso mesmo funcionando)

- Um tutorial que dá para pular: **é obrigatório** (decisão do Elizeu).
- Jogador em tutorial que morre, ou que é usado para atrapalhar outros (bater em jogador ou bicho, quebrar construção).
- Texto comprido ou janela que tampa o jogo: a missão é um quadrinho pequeno.

## Decisões do Elizeu

1. **Começa na primeira partida normal**: aperta Jogar e já está no tutorial, no mapa de sempre, com outros jogadores.
2. **Rastros** saem do personagem e vão até o recurso que ele precisa pegar agora.
3. **A missão fica num quadrinho embaixo do minimapa**, com "Tutorial N/6" e o que fazer.
4. **As etapas** (a 4ª foi ideia dele no meio da conversa):
   1. Pegar 10 madeiras.
   2. Fazer a picareta de madeira.
   3. Pegar frutinhas.
   4. Abrir o livro de receitas e ver o que a fogueira pede.
   5. Pegar madeira e pedra e fazer a fogueira.
   6. Tomar água.
5. **Protegido**: ninguém causa dano a ele, e **ele também não causa dano a jogadores nem a bichos (NPCs)**.
6. **Tem um sinal visível** de que ele está em tutorial.
7. **Recompensa: 2 giros normais** (`ShopData.Spins.normal`) ao completar.
8. **Depois que essa vida do tutorial acabar** (quando ele morrer), aparece um pop-up para ir à loja girar os cosméticos.
9. **Se cair no meio** (sair, conexão cair), na próxima vez o tutorial **começa do zero**. Só vale como feito quando completa.
10. **Obrigatório**: não tem botão de pular.
11. **A proteção dura no máximo 10 minutos**; depois disso o tutorial segue sem proteção.

## As etapas em detalhe

Números e nomes conferidos no código em 10/11/2026.

| # | Texto do quadrinho (rascunho) | Completa quando | O que guia |
|---|---|---|---|
| 1 | Pegue madeira nas árvores (x/10) | tem 10 `wood` no inventário | rastro até a árvore (`tree`) mais perto |
| 2 | Faça uma Picareta de Madeira | tem 1 `wood_pickaxe` (receita: 10 madeiras, 5 s) | a receita pisca na coluna de receitas do HUD (`UI/CraftColumn`) |
| 3 | Pegue frutinhas nos arbustos (x/5) | tem 5 `berry` | rastro até o `berry_bush` mais perto |
| 4 | Abra o livro e veja a receita da Fogueira | a ficha da Fogueira aparece no livro (`Screens/RecipeBookScreen`) | pisca o botão do livro (`UI/RecipeBookButton`), depois a aba Construções e depois a Fogueira na grade |
| 5 | Faça uma Fogueira e coloque no chão | uma `campfire` dele é colocada no mundo (receita: 25 madeiras + 5 pedras, 10 s) | rastro até a árvore ou a rocha (`rock`), conforme o que falta; a receita pisca na coluna de receitas quando dá para fazer |
| 6 | Vá até a água e beba | entra na água e a sede enche um pouco | rastro até a água mais perto (`Map/Water`, via `WaterSim`) |

Observações:

- **Craftar é pela coluna de receitas do HUD**, não pelo livro: o livro só mostra informação (ver `docs/superpowers/specs/2026-11-09-livro-receitas-design.md`).
- A pedra precisa da picareta (a rocha tem `hardness = 1`), então a etapa 2 abre a etapa 5.
- Na etapa 5, a madeira da etapa 1 já foi gasta na picareta, por isso o rastro volta para as árvores.
- "x/10" e "x/5" contam o que ele tem no inventário, ao vivo.

## Como o jogador vê

- **Quadrinho da missão**: embaixo do minimapa (`UI/Minimap`), no estilo rústico do HUD (`UI/Rustic`, couro/madeira/papel). Mostra "Tutorial N/6", o texto da etapa e o contador quando há. Ao completar uma etapa, dá um retorno curto (um brilho ou um "✓") e passa para a próxima.
- **Rastro**: uma trilha no chão do personagem até o alvo, refeita conforme ele anda e quando o alvo muda (ex. a árvore acabou). Some nas etapas sem alvo no mapa (2 e 4) e quando ele está em cima do alvo.
- **Destaque na interface**: um brilho dourado pulsando no que é para clicar (receita na coluna, botão do livro, aba, item da grade). É o mesmo destaque em todas as etapas, para o jogador reconhecer o "clique aqui".
- **Sinal de tutorial**: um selo "Tutorial" junto do nome dele (`NameTag` de `Boneco/BonecoModel`), visível para todos.
- **Fim**: uma mensagem de parabéns com os 2 giros; o quadrinho some e a proteção acaba.
- **Pop-up da roleta**: na volta ao menu depois que a vida do tutorial acaba, um pop-up do tipo "Você tem 2 giros! Ir para a roleta", que abre a tela de girar (`Menu/Shop/SpinScreen`). Aparece uma vez.

## Regras

- **Quem faz**: todo perfil que ainda não completou o tutorial. Fica salvo no perfil (DataService/ProfileStore) só ao completar. As datas serão zeradas antes do lançamento, então todo mundo passa por ele.
- **Começa do zero** a cada vida enquanto não estiver completo, inclusive depois de sair do jogo no meio.
- **Proteção** (do servidor, que é quem decide dano):
  - não leva dano de nada: jogador, bicho, espinho, armadilha;
  - não causa dano a jogador nem a bicho (o golpe não tira vida);
  - coletar recursos funciona normal.
- **Fim da proteção**: ao completar a etapa 6, ou **10 minutos depois de nascer** na vida do tutorial, o que vier primeiro (decisão do Elizeu, para ninguém ficar invencível a partida inteira; o tutorial leva uns 3 a 5 minutos). Se o tempo acabar, o tutorial **continua** (quadrinho, rastro, destaques) e ainda dá os 2 giros ao completar; só a proteção e o selo "Tutorial" do nome somem. A partir daí é uma vida normal, sem reiniciar nada.
- **Giros**: soma 2 em `Spins.normal` uma vez só, no servidor, quando o tutorial é completado.

## Escolhas do Claude (o Elizeu pode trocar)

- Etapa 3 pede **5** frutinhas.
- Fome, sede e frio **continuam descendo** no tutorial (é o que dá sentido às etapas das frutinhas, da fogueira e da água), mas **não matam**: param num mínimo (ex. 1) até o tutorial acabar.
- Os **bichos não perseguem** quem está em tutorial (senão um lobo fica colado nele o tempo todo sem poder ser morto).
- Quem está em tutorial **também não estraga construção** de outros jogadores.
- A vida do tutorial **ignora o kit** escolhido (um kit com picareta pularia a etapa 2). Jogador novo não tem kit mesmo; isso só pesa em perfil de teste.
- O pop-up da roleta só aparece se ele **ainda tiver giros normais** (se já gastou, não faz sentido).
- Quem está em tutorial **não abre baú nem caixa de outro jogador** (`ChestService`, `CrateService`). Pegar item caído do chão e colocar construções é normal; o que ele colocar (ex. espinho) também não causa dano enquanto ele estiver em tutorial.
- O pop-up da roleta fica **salvo no perfil** como pendente quando o tutorial é completado. Aparece na próxima vez que ele estiver no menu (depois de morrer ou numa sessão nova, se saiu vivo) e então é marcado como mostrado.
- **Kit na vida do tutorial**: enquanto o tutorial não estiver completo, o botão de kit do menu não aparece e nada é aplicado nem gasto. O saldo de kits fica intacto.
- A vida do tutorial **conta normal** para pontos e ranking: é a primeira vida de verdade dele, e é curta.
- A etapa 6 vale só para a **água do mapa** (`Map/Water`), não para poço: o poço é uma construção que ele ainda não sabe fazer.
- **Comando de dev** para zerar e para dar como feito o tutorial de um perfil (no padrão de `DevDataService`), para testar.
- Textos em `Strings/ptBR` (nada escrito no código).
- Etapas como **dados** (uma tabela de etapas com alvo, condição e texto), no espírito "conteúdo = dado" do projeto, para mudar a ordem ou os números sem mexer na lógica.

## Deixado para quem constrói

- O formato exato do rastro (pontinhos, setas, linha tracejada) e da animação de "etapa completa".
- Como o servidor e o cliente dividem o acompanhamento das etapas (o servidor decide proteção, conclusão e giros; o cliente desenha quadrinho, rastro e destaques).
- Onde a regra pura das etapas mora e como é testada (o projeto testa regras puras no Lune: `tests/*.spec.luau`).
- A arte do selo "Tutorial" no nome e do pop-up da roleta, no padrão rústico do jogo.
