# Bots que parecem jogadores — design

Data: 20/11/2026. Branch `npc`. Conversa com o Elizeu (aprovado em partes na conversa; este documento junta tudo).

## Por quê

O jogo acabou de lançar e os servidores ficam vazios ou com 1–2 pessoas. Quem entra e não vê ninguém sai. Bots que vivem o jogo como um jogador fazem o mundo parecer habitado até a base de jogadores crescer.

**Sucesso:** um jogador novo não percebe de cara que são bots: vê gente coletando, craftando, com fogueira à noite, no placar, e pode lutar com eles.

## Objetivos

- **Quantos:** `bots = clamp(20 − jogadores reais, 0, 10)`. Até 10 jogadores, 10 bots; com 11, 9; com 20 ou mais, nenhum (decisão do Elizeu).
- **Sobreviver de verdade** (decisão do Elizeu): cada bot tem inventário, vida, fome, frio (e o que mais o `SurvivalRules` tiver valendo na floresta) calculados com as **mesmas regras e números** do jogador (`SurvivalRules`, `SurvivalConfig`, `CraftRules`, `GatherRules`, `Defs.Recipes`, `Defs.Items`). Ele:
  - coleta recursos reais (a árvore perde madeira de verdade, `ResourceService.take`);
  - crafta ferramentas, armas e armadura subindo de nível com o tempo, **até no máximo pedra** (ferramentas e armas de pedra, armadura básica) — minha decisão, para a caixa não virar loot farto e o revide não matar novato de um golpe — indo até a estação que a receita pedir;
  - coloca fogueira real à noite (estrutura de verdade, que o jogador vê e pode usar) e fica perto dela; coloca mesa de trabalho quando a receita pedir;
  - come frutinha e carne quando tem fome (caça mob fraco para carne);
  - morre de fome, frio, mob ou jogador.
- **Por fora idêntico a um jogador:** mesmo boneco (tag Boneco), nome em cima, skin de corpo e mochila, item na mão, golpe, careta de dano, comer. Os atributos que o `BonecoRenderer` lê no personagem são os mesmos.
- **Relação com o jogador** (opção 3, escolhida pelo Elizeu): pode levar golpe e morrer; **só revida quem atacou primeiro** (e só enquanto essa briga durar); nunca caça jogador.
- **"Atacou primeiro"** (minha decisão): o golpe do jogador é em área (desde 19/11), então bater numa árvore ao lado acerta o bot sem querer. Vira briga só se o bot levar **2 golpes do mesmo jogador em poucos segundos**, ou se o bot for o **único alvo** daquele golpe. O dano do golpe acidental vale normalmente; só não provoca revide.
- **Bot que mata jogador** (minha decisão): a tela de morte mostra o nome do bot como matador ("morto por Lucas_2011"), como num jogador. Mudança pequena e aditiva no `DeathService`/`Net.LifeEnded` (nome do matador vindo de fora de um `Player`); revive, fantasma e `CombatTag` tratam como morte por mob (sem as regras de PvP).
- **Mobs:** atacam bots como atacam jogadores, e o bot se defende/foge (minha proposta; "idêntico a jogador").
- **Placar da partida:** bots aparecem na lista (`Leaderboard`) com pontos ganhos pelas mesmas regras (coleta, craft, mob morto) e entram na posição (#N) de todos.
- **Morte do bot:** deixa a caixa com o que carregava (`CrateService.spawn`, como a do jogador), quem matou ganha os pontos de sempre por matar um jogador (`CrateRules.killBonus`: 25% dos pontos do morto, que no fim da vida viram Golden Ember, XP e Ranking pelo `LifeService.endLife`); o bot volta depois em outro ponto da floresta (como vaga nova), **do zero** (sem itens).
- **Teto de pontos do bot** (decisão do Elizeu, opção 1 de 3): a pontuação de um bot para de subir num teto "de jogador médio" (`BOT_SCORE_CAP`, número único). Assim matar bot vale como matar um jogador comum, sem virar farm de moeda/XP, e o placar fica com cara de normal. Descartadas: sem bônus de kill (some o "matei e ganhei pontos", o jogador percebe) e sem teto (bot velho vale muito, vira farm).
- **Leve:** ver "Desempenho".

## Fora do escopo (não-objetivos)

- Base: paredes, portas, espinhos, baú, cama (decisão do Elizeu: "não precisa de base").
- Time, chat, loja, Robux, missões, check-in, códigos, revive pago, fantasma.
- Ranking global, perfil salvo, DataStore: nada do bot é salvo (o bot em si não tem perfil). O que o **jogador** ganha matando bot (bônus de kill, limitado pelo teto) segue o caminho normal dele; nenhuma missão ou conquista conta "matar jogador" com bot (**minha proposta**).
- Aparecer na lista de jogadores do Roblox (menu do Roblox) ou na contagem do servidor da página do jogo: impossível e não é o objetivo.

## Antiobjetivos (falharia mesmo funcionando)

- **Pesar:** queda de FPS no celular ou do servidor perceptível com 10 bots. Medir antes de lançar.
- **Atrapalhar quem joga:** bot caçando novato, matando gente no tutorial, cercando recurso, travando passagem, ou espinho/estrutura que machuca.
- **Mexer no jogador de verdade:** nenhum sistema do jogador pode mudar de comportamento para acomodar bot (risco logo após o lançamento).
- **Parecer robô:** andar em linha reta sem parar, girar no lugar, ficar preso em pedra, todos fazendo a mesma coisa ao mesmo tempo, nomes iguais/sequenciais.
- **Fazenda de loot:** bot morto não pode ser uma fonte farta de itens raros. A caixa só tem o que ele coletou/craftou.

## Restrições do projeto

- No servidor, coleta, craft, inventário, fome, morte e spawn são feitos para `Player` (rede `Net`, atributos no `Player`, perfil). Bot não é `Player`. **Não** adaptar esses serviços para "jogador ou bot" (abordagem 2 descartada).
- Regras puras já existem e são a fonte dos números: `Survival/SurvivalRules`, `Craft/CraftRules`, `Gather/GatherRules`, `Mobs/MobBrain`, `Mobs/MobMove`/`MobSteer`, `Inventory`, `Defs/*`.
- O boneco é desenhado no cliente para qualquer modelo com tag Boneco + `HumanoidRootPart`; o nome vem de `Players:GetPlayerFromCharacter` ou, sem jogador, do nome do modelo (`BonecoRenderer` ~L255/L338). `DevBonecoService.DevCrowd` já cria bonecos no servidor com `CharacterBody.build()`.
- Mobs são raízes ancoradas movidas em lote (`Workspace:BulkMoveTo`) com cérebro a `MobRules.TICK` e "longe de todos" a `FAR_EVERY`; ~100 mobs vivos de dia hoje.
- Placar: `Leaderboard` (cliente) lê `Players:GetPlayers()` e o atributo `Score`; posições em `ScoreService.updateRanks`.
- Pontos: `ScoreService.add(player, …)`; morte por jogador: `DeathService` (killer/`CombatTag`).
- Golpe do jogador: `GatherService.hit` monta candidatos (recursos, peças, caixas, mobs, outros jogadores) e aplica golpe em área.
- Limite de ~1 KB de atributos por instância (memória do projeto): não pendurar listas em atributos.
- Tamanho do servidor precisa ser ≥ 20 para a conta 20 − jogadores fazer sentido (conferir no Creator Hub; se for menor, a conta usa o máximo do servidor — ver "Decisões minhas").

## Abordagens consideradas

1. **Bot com cérebro próprio usando as mesmas regras (escolhida pelo Elizeu).** Um serviço novo (`BotService` + regras puras) roda os bots: estado próprio (inventário, barras, receita em andamento), decisões por objetivos, e mexe no mundo por **portas pequenas e explícitas** nos serviços existentes (tirar recurso, colocar fogueira com dono "bot", ser alvo do golpe do jogador e dos mobs, entrar no placar). Convincente e não toca no caminho do jogador.
2. **Generalizar todos os serviços para "jogador ou bot".** O mais fiel, mas reforma quase todo o servidor logo após o lançamento; alto risco para quem joga. Descartada.
3. **Bot "ator" com roteiro**, sem fome/frio/inventário de verdade. Rápido, mas não "tenta sobreviver", que é o pedido. Descartada.

## Como funciona (o que foi decidido)

### Quantidade e troca
- Conta: `alvo = clamp(20 − #Players, 0, 10)`, conferida de tempos em tempos (e ao entrar/sair jogador).
- **Sobrando bot:** sai primeiro o que está mais longe de todos os jogadores (some sem ninguém ver; se todos estiverem à vista, espera ele sair da vista ou morrer). **Faltando:** nasce um em ponto da floresta pelo mesmo sorteio do spawn/revive do jogador (`SpawnService`, longe de jogadores).
- Bot que morre volta como vaga nova depois de um tempo parecido com o de um jogador voltando do menu.

### Cara de jogador
- Modelo `CharacterBody.build()` com tag Boneco, nome = nome do bot; atributos de personagem iguais aos do jogador (`Equipped`, `Using`, `HurtAt`, `EatUntil`, `Cosmetic_body`, mochila, armadura…).
- Skin de corpo e mochila sorteadas entre as que estão nos giros (não as Limitadas/exclusivas, para não desvalorizar o que se compra ou se ganha no grupo).
- **Nomes:** gerados no estilo dos nomes do Roblox (`Lucas_2011`, `xXDarkWolfXx`, `NoobMaster_88`), sem copiar contas reais; sem repetir no mesmo servidor.

### Cérebro (objetivos, em ordem de urgência)
Exemplo de prioridade (o builder ajusta os limites):
1. Em briga (alguém bateu nele há pouco) → revidar o atacante ou fugir se a vida estiver baixa.
2. Mob perigoso perto → lutar se tiver arma e vida, senão fugir.
3. Noite / frio baixo → ir para a fogueira (a própria ou uma perto) ou colocar uma se tiver material.
4. Fome baixa → comer o que tem; sem comida, ir a um arbusto de frutinha ou caçar mob fraco.
5. Progresso → próximo item da "escada" (picareta de madeira, espada, picareta de pedra, armadura…): juntar ingredientes, ir à estação se precisar, craftar (com o tempo de craft da receita, item "em uso" no boneco).
6. Nada urgente → coletar o recurso que falta para o próximo passo, ou andar à toa.
- Pausas e variação por bot (cada um com um "jeito": mais lenhador, mais caçador) para não andarem em sincronia.
- Coleta e golpe com a mesma cadência e alcance do jogador (`GatherRules.nextHit`, `HIT_REACH`, item na mão); o bot vira para o alvo antes de golpear.

### Tocando o mundo (portas novas, pequenas)
- **Recursos:** golpe do bot usa `ResourceService.take` + `GatherRules.yield` (mesmo rendimento por ferramenta) e o mesmo efeito de golpe que os outros veem.
- **Fogueira e mesa:** colocadas via `StructureService` com dono "bot" (não um `Player`); somem como as de um jogador que sai quando o bot sai/morre (a fogueira já apaga sozinha pelo tempo dela).
- **Ser atingido pelo jogador:** `GatherService.hit` inclui bots como candidatos (mesma regra de golpe em área, tutorial protegido não acerta bot); o dano vai para o `BotService`.
- **Mobs:** os mobs veem bots como alvos (o `MobBrain` aceita qualquer `who`); mordida tira vida do bot pelo `BotService`. O bot acerta mob por `MobService.damage`/`hit` sem `Player` (atacante bot).
- **Placar:** bots entram na lista e nas posições. O cliente precisa receber nome e pontos dos bots (ex.: uma pasta replicada com uma entrada por bot), e `ScoreService.updateRanks` conta os dois.
- **Morte:** caixa com o inventário (`CrateService.spawn`), pontos ao matador como num kill de jogador.

### Desempenho
- Movimento como o dos mobs (raiz ancorada movida pelo servidor, sem física de personagem), em lote.
- Cérebro ~2× por segundo; bot sem jogador por perto pensa bem menos (como o mob longe). Barras a cada `SurvivalConfig.TICK`, como no jogador.
- Atributos só quando mudam.
- Quantidade num número só (`MAX_BOTS = 10`, `TARGET_TOTAL = 20`) fácil de trocar.
- **Medir no Studio antes de lançar** (MicroProfiler servidor e cliente, emulador de celular) com 10 e com 20 bots.

## Decisões minhas (o Elizeu pode mudar)
- Escada até pedra + armadura básica; renasce do zero.
- "Atacou primeiro" = 2 golpes do mesmo jogador em poucos segundos, ou o bot como único alvo.
- Tela de morte mostra o nome do bot matador; o resto como morte por mob.
- Mobs atacam bots e bots lutam com mobs.
- Skins dos bots só das que estão nos giros.
- Matar bot dá os pontos de kill do placar, mas **não** conta em missões, conquistas, estatísticas salvas nem analytics.
- Se o servidor tiver menos de 20 vagas, a conta usa `vagas do servidor` no lugar de 20.
- Bot nunca ataca quem está protegido pelo tutorial, nem perto do ponto de nascimento nos primeiros segundos de alguém.
- Studio: comandos `Dev*` para forçar N bots, ver o objetivo atual de cada um e matar um bot.

## Fica com quem constrói
- Nomes dos módulos, a "escada" exata de itens, limites de fome/frio/vida para cada objetivo, tempos de pausa.
- Formato da pasta replicada dos bots e como o `Leaderboard` mistura as duas listas.
- Como o bot escolhe o caminho (reaproveitar `MobMove`/`MobSteer`).
- Lista de nomes e o gerador.
- Testes: regras puras do cérebro (escolha de objetivo, escada, conta de quantidade) no Lune.
