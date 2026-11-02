# G5 — Mobs (design)

Data: 2026-11-01. Conversado com o Elizeu em chat ("pode fazer", "perfeito isso mesmo", respostas sobre perseguição, passivos, voadores, drops, biomas, teia, construções e noite). Números: wiki de fãs do Starve.io (starveiopro.fandom.com, páginas Mobs, Wolf, Spider, Rabbit, Hawk, Swords, Spears; NamuWiki para comparar) e changelog oficial (starve.io/changelog.html), lidos por busca em 01/11 (a wiki recusa acesso direto). Podem estar desatualizados, por isso ficam em dados.

## Intenção

Os 23 mobs já existem como visual: modelos com juntas, animações, piscar, cara de brava, borda vermelha quando querem atacar (`docs/guia/mobs-modelos.md`). Mas ninguém os cria no mundo e eles não fazem nada. A G5 põe os mobs da **floresta** para viver: nascem, andam à toa, fogem, perseguem, mordem, apanham, morrem e renascem. É o que transforma a floresta num lugar perigoso, dá sentido às armas, ao capacete e às paredes e espinhos da G4, e prepara o combate/PvP.

## Objetivos

- **Os 5 mobs da floresta**: coelho (passivo), lobo e aranha (agressivos), javali (neutro) e falcão (neutro e voador). Os outros 18 entram depois, bioma por bioma, só com dados (o sistema já deve servir para todos).
- **Nascer e renascer** espalhados pela floresta, longe dos jogadores, mantendo uma população por tipo. **À noite há menos coelhos e mais mobs agressivos** (decisão do Elizeu).
- **Comportamentos** (do Elizeu, salvo onde marcado):
  - **Agressivo** (lobo, aranha): percebe o jogador só **num raio pequeno**. Depois que começa a perseguir, **não desiste por distância**: corre atrás por bastante tempo. **Desiste quando o jogador passa um tempo sem bater nele**; cada golpe do jogador reinicia esse tempo.
  - **Passivo** (coelho): **foge quando o jogador chega perto e quando apanha**.
  - **Neutro** (javali, falcão): tranquilo até apanhar; depois age como o agressivo (persegue, desiste do mesmo jeito). A borda vermelha (`MobHostile`) acende quando fica bravo e apaga quando desiste.
  - **Sem ninguém por perto**: anda devagar à toa perto de onde nasceu.
  - **Ao desistir**: volta a andar à toa e não ataca de novo logo em seguida (escolha minha, aprovada na conversa).
- **Voadores** (falcão; o abutre também quando o deserto entrar): **alternam ao acaso entre voar e andar no chão**. Voando: ficam **mais altos e meio translúcidos**, passam por cima de paredes, recursos e água, **não acertam nem são acertados** por quem está no chão. **Para morder, pousam** (do Elizeu).
- **Vida e dano**: cada mob tem vida e mordida (dos dados). O jogador bate com o mesmo golpe de coletar e quebrar construções. A mordida machuca como combate (o capacete protege) e a morte mostra o mob ("Morto por: Lobo"). **Mobs não têm barra de vida** (decisão do Elizeu): a reação ao golpe é a que já existe (pisca em vermelho, recua, fecha os olhos).
- **Teia da aranha** (do Elizeu): quando a aranha ataca, prende o jogador no lugar por um tempo com uma teia. Ele continua podendo bater. Teia nova só renova o tempo, não soma. Modelo provisório simples até o Elizeu modelar.
- **Construções** (do Elizeu): paredes e portas fechadas seguram os mobs (eles só batem de frente nelas, sem quebrar); **espinhos machucam os mobs** como machucam jogadores.
- **Pontos**: matar um mob dá pontos a quem matou (escolha minha, aprovada na conversa).

## Não-objetivos

- **Drops**: por enquanto o mob morto não deixa nada. Mais tarde vai cair uma **caixa** que o jogador quebra para pegar os itens (do Elizeu). Aqui só o gancho: uma função única "mob morreu (quem matou)" onde a caixa vai entrar.
- **Domesticar e montar** (sela, falcão/filhotes de dragão/javali voando montados): futuro. Só um campo nos dados dizendo se o mob voa quando montado.
- Mobs dos outros biomas, bosses, cavernas (dragões voando de volta para a caverna).
- Mobs quebrando construções; telhado (o "telhado protege de voadores" do Starve entra com o telhado).
- PvP e dano de armas em jogadores (fase de combate).
- Barra de vida dos mobs (nunca: decisão do Elizeu).
- Busca de caminho inteligente: o mob vai reto e contorna pela beirada; um lobo atrás de uma parede fica empurrando a parede (como no Starve).

## Anti-objetivos

- Mob atravessando parede, porta fechada, recurso, água (os que não voam) ou outro mob.
- Floresta vazia (população que não volta) ou lotada (mobs nascendo em cima do jogador ou dentro da base).
- Lobo impossível de largar: o jogador que para de bater tem que conseguir se livrar.
- Jogador no chão acertando o falcão em pleno voo, ou falcão voando mordendo.
- Teia que prende para sempre ou que soma até travar o jogador.
- Sistema que conhece mob pelo nome (`if id == "wolf"`): tudo vem dos dados (`Defs.Mobs`).
- Servidor travando com muitos mobs e 30 jogadores.

## Números

### Mobs da floresta

Vida e dano do jogador nesta tabela já estão na escala do Ember Wilds: a vida do jogador aqui vai de 0 a 100 e a do Starve de 0 a 200, então **a mordida é a metade da wiki** (escolha minha). A vida dos mobs fica igual à wiki, porque o dano das armas também vem da wiki.

| Mob | Comportamento | Vida | Mordida (vida do jogador) | Velocidade (jogador = 16) | Fonte |
|---|---|---|---|---|---|
| Coelho | passivo | 60 | — | 15 | vida: wiki; velocidade: escolha minha ("foge de quem está armado": um pouco mais lento que o jogador desarmado, dá para encurralar) |
| Lobo | agressivo | 300 | 24 (wiki 48) | 14 | wiki ("mais lento que o jogador, fácil de despistar") |
| Aranha | agressivo | 120 | 16 (wiki 33) + teia | 20 | wiki ("muito mais rápida que o lobo") |
| Javali | neutro | 400 | 25 | 15 | escolha minha (a wiki não traz números; "bem forte") |
| Falcão | neutro, voador | 300 | 24 (wiki 48) | 18 | wiki (vida e dano iguais ao lobo); velocidade: escolha minha |

Escolhas minhas (provisórias, em dados):
- **Raio de percepção** do agressivo: 18 studs. **Fuga** do passivo: começa com jogador a 14 studs, foge por 3 s depois de apanhar.
- **Desistir**: 10 s sem apanhar. **Pausa depois de desistir**: 5 s sem perseguir ninguém.
- **Mordida**: alcance = raio do mob + 2 studs; uma mordida a cada 1 s.
- **Teia**: prende **2 s** (wiki: "cerca de 2 s"). A aranha só atira teia de novo depois de 6 s.
- **Voo** (falcão): voa 4–10 s e anda no chão 4–10 s, ao acaso; voando fica 6 studs acima do chão e com transparência 0,4 no visual. Perseguindo, pousa quando está a até 8 studs do alvo.
- **Pontos por abate**: coelho 20, aranha 40, lobo 60, javali 80, falcão 60.

### Dano em mob (o golpe do jogador)

Cada item ganha um **dano em mob** opcional nos dados (vale depois para o PvP). Um golpe a cada 0,5 s, como a coleta.

| Na mão | Dano | Fonte |
|---|---|---|
| Nada / item sem número | 5 | escolha minha (igual ao dano de mão em construção) |
| Espada de madeira / pedra / ouro | 12 / 19 / 22 | wiki |
| Lança de madeira / pedra / ouro | 10 / 14 / 15 | wiki |
| Picareta de madeira / pedra / ouro / diamante / ametista / reidite | 4 / 6 / 8 / 10 / 12 / 14 | escolha minha (a wiki não traz; ferramenta bate menos que arma) |

Ex.: lobo (300) com espada de pedra = 16 golpes ≈ 8 s. Espinho em mob: o mesmo dano e o mesmo compasso do espinho em jogador.

### População da floresta

Escolha minha (provisória, em dados), para a floresta inteira (~960 × 960 studs):

| | Coelho | Lobo | Aranha | Javali | Falcão |
|---|---|---|---|---|---|
| Dia | 40 | 10 | 8 | 8 | 6 |
| Noite | 15 | 20 | 16 | 8 | 6 |

- Nasce em ponto aleatório da floresta: fora da água, sem encostar em recurso ou outro mob, **a pelo menos 60 studs de qualquer jogador e a pelo menos 30 studs de qualquer construção** (escolha minha: assim nunca nasce dentro de uma base cercada com o dono longe).
- Morreu: o lugar dele volta a ficar livre depois de **30 s**, e então nasce outro.
- Na troca dia/noite, os tipos acima do novo limite **somem aos poucos, só os que estão longe de todos os jogadores** (ninguém vê sumir); os abaixo do limite nascem aos poucos.

### Revisão de 02/11 (Elizeu): arma na mão e velocidades

Depois de testar, o Elizeu explicou como se mata cada mob no Starve: de mão ou picareta o jogador alcança o coelho e foge do lobo e da aranha; armado (espada, lança) o coelho foge e o lobo e a aranha alcançam; de lança dá para matar recuando, de espada se mata tomando dano. Wiki (Weapons, Swords, Spears, por busca): espada e lança deixam o jogador "bem mais lento"; a lança dá menos dano mas alcança mais longe; a arma recém-equipada só pode ser trocada depois de "alguns segundos" (relógio no canto). Decidido:

- Espada e lança na mão: velocidade × 0,75 (16 → 12); presas na mão por 4 s depois de equipadas, com relógio no HUD; lança alcança 3 studs mais longe (números meus, a wiki não traz).
- Velocidades: coelho 14, lobo 13, aranha 14 (substituem 15, 14 e 20 da tabela acima).
- Depois do teste: com lança o mob da floresta não pode morder quem foge batendo para trás. O golpe de lança empurra o mob 4 studs (`knockback`). **Só mob**: a lança nunca empurra jogador, nem quando o PvP entrar (seria forte demais).

## Como funciona (decisões)

- **Dados**: `Defs.Mobs` (já existe com `behavior`) ganha vida, mordida, velocidade, raio de percepção, se voa, se voa montado (só o campo), teia (só a aranha), pontos e população por bioma e período. `ItemDef` ganha o dano em mob. `Validate` confere tudo. Um bioma novo = população nos dados; um mob novo = uma entrada (o visual já é dado).
- **Servidor é dono de tudo**: cada mob é uma raiz invisível ancorada (o contrato que já existe em `mobs-modelos.md`: tag `Mob`, `MobId`, `MobAttack`, `MobHurt`, `MobDead`, `MobHostile`). O servidor move a raiz sem física, num passo fixo (como `SpikeService`/`SurvivalService`), e escreve os atributos. O cliente só desenha (o `MobRenderer` atual), **suavizando** entre as atualizações do servidor para não ficar travado.
- **Novo atributo `MobFlying`** (booleano) na raiz: o servidor decide; o cliente põe o visual mais alto e translúcido.
- **Corpo no chão = círculo** (como as peças da G4), raio por mob nos dados. Colide com: construções (paredes, portas **fechadas**, espinhos, bancada, baú, fogueira) pelo índice do `StructureService`, recursos pelo raio de colisão do `ResourceService`, água (não entra) e outros mobs (não se sobrepõem). Voando, ignora tudo isso. Movimento: vai reto até o alvo e escorrega pela beirada do obstáculo.
- **Jogadores** também são obstáculo (o mob para encostado e morde dali).
- **Bioma**: o mob nunca sai do bioma dele (escolha minha). Perseguindo, para na borda e solta o alvo ali, como se tivesse desistido. Hoje só a floresta é jogável, então isso só importa quando os outros biomas entrarem.
- **Golpe do jogador**: o mesmo golpe da coleta (`GatherService`) acerta o que estiver mais perto à frente: recurso, peça ou **mob** (mob voando não conta para quem está no chão). Com uma peça `placeable` na mão continua construindo.
- **Mordida**: `CharacterService.hurt(..., "combat")` (capacete protege), com causa de morte própria por mob (o nome em `Strings`, `mob.<id>`).
- **Teia**: o servidor marca o jogador preso até um instante. O movimento é simulado no cliente e no servidor (Server Authority), e o lugar que já controla a velocidade do jogador (`WaterSim`, `WalkSpeed`) passa a zerar a velocidade enquanto ele estiver preso. Visual: modelo provisório em volta do jogador enquanto durar.
- **Espinhos**: o `SpikeService` passa a ferir também os mobs que encostam (mesmo dano e intervalo). Mob morto por espinho não dá pontos.
- **Morte**: `MobDead` na raiz, a raiz some depois da animação de morte (~0,5 s), pontos para quem deu o último golpe, e a chamada única "mob morreu" (gancho da caixa futura).
- **Desempenho**: o passo de IA roda em frequência baixa (alguns por segundo); índice espacial para os mobs (como recursos e peças); mob longe de todos os jogadores pode pensar menos vezes.
- **Teste no Studio**: comandos para criar um mob perto do jogador e para ver a população (como os `Dev*` atuais). O `DevMobs` da galeria continua.

## Restrições

- Server Authority: o servidor decide tudo; o cliente pede e mostra. Atributos do personagem local previsto: ler por polling.
- Conteúdo é dado; atributos e tags por `StatNames`; rede por Blink se precisar de evento novo.
- O visual dos mobs (`MobVisual`, `MobAnim`, `MobRenderer`) já está pronto: a G5 só alimenta a raiz e acrescenta o voo.
- O jogo vai crescer (18 mobs, biomas, caixa de drop, montaria, telhado, PvP): cada um entra mudando dados ou uma função de gancho.

## O que fica para quem implementa

A organização dos serviços; o algoritmo exato de "escorregar pela beirada"; como o cliente suaviza a raiz; a frequência do passo de IA; o modelo provisório da teia; o andar à toa (raio, pausas); o sorteio dos pontos de nascimento; como some/aparece na troca dia/noite (desde que ninguém veja).
