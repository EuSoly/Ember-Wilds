# G6 — Combate entre jogadores e caixas de itens (design)

Data: 2026-11-02. Conversado com o Elizeu em chat (respostas sobre a briga, as caixas, a skin, quem abre, duração, morte sem jogador, caixa quebrável, vida 200, mordida a 1,5 s, pontos 1/4; "está perfeito"). Números do Starve: wiki de fãs (starveiopro.fandom.com: Points, Player, Rabbit, Wolf Fur, Cord, Mobs, Resources) e changelog oficial, lidos por busca em 02/11 (a wiki recusa acesso direto).

## Intenção

Hoje o jogador só morre para a fome, o frio, os espinhos e os mobs, e quem morre perde tudo sem deixar nada; os mobs mortos também não deixam nada. A G6 fecha o ciclo do Starve: **jogadores brigam entre si**, e **todo mundo que morre — jogador ou mob — vira uma caixa de itens** que qualquer um pode abrir e saquear. Matar outro jogador rende o que ele carregava e parte dos pontos dele. As caixas também são vitrine: **a caixa de quem morre por outro jogador sai com a skin de caixa de quem matou** (cosmético, como as skins do boneco). E o jogador fica mais resistente, para sobreviver dá mais chance (decisão do Elizeu).

## Objetivos

### Vida e ritmo dos mobs (do Elizeu)

- **Vida do jogador: 200** (hoje 100). Os danos ficam como estão (mordidas e armas já estão na escala certa). Fome, frio, sede e calor continuam de 0 a 100; só a vida muda de teto. Os anéis do HUD mostram a porcentagem.
- **Mobs mordem a cada 1,5 s** (hoje 1 s).
- Conta de referência (sem capacete): matar um lobo de espada de pedra leva ~8 s; ele morde ~5 vezes (120 de 200). Dois lobos seguidos pedem capacete ou comida no meio.

### Briga entre jogadores

- **O mesmo golpe de sempre** (coleta/construção/mob) passa a acertar também **jogadores**: o que estiver mais perto à frente leva.
- **Dano do golpe em jogador = o mesmo do golpe em mob** (`mobDamage`, ou mão 5): espadas 12/19/22, lanças 10/14/15, picaretas 4 a 14 (escolha minha: o Starve usa o mesmo número; a vida 200 já é a escala do Starve). Um golpe a cada 0,5 s.
- **Capacete protege** (dano tipo combate, como mordida e espinho).
- **A lança alcança mais longe, mas nunca empurra jogador** (decisão do Elizeu).
- **Todos podem bater em todos** (ainda não há times; o gancho `areAllies` da G4 já existe).

### Morte por jogador

- **Quem matou** = o jogador que deu o **golpe final** (escolha minha). Se o último dano veio de outra coisa (fome, mob, espinho), não é morte por jogador, mesmo que alguém tenha batido antes.
- **Bônus de pontos (do Elizeu):** quem matou ganha **1/4 dos pontos que o morto tinha**. É bônus: o morto não perde nada a mais (os pontos dele continuam virando Golden Ember no fim da vida, como hoje). (O Starve já usou 1/3, 1/6 e hoje ~1/10; o Elizeu escolheu 1/4.)
- **Tela de morte:** "Causa: <nome de quem matou>" (escolha minha).

### Caixas de itens (do Elizeu, salvo onde marcado)

- **Jogador morto vira caixa** com **tudo** o que tinha: inventário, mochila (os itens dela e a própria mochila) e a armadura vestida (escolha minha: "todos os itens"). Vale para qualquer morte: por jogador, mob, fome, frio, espinho, queda.
- **Mob morto vira caixa** com o que ele deixa (wiki, abaixo). Cada mob tem o **seu modelo de caixa**.
- **Abrir:** qualquer jogador chega perto e abre o "inventário" da caixa — um painel com os itens dela — e pega o que quiser. **Qualquer um pode roubar** (não há reserva para quem matou).
- **Skin da caixa de jogador:** morto **por outro jogador** → a skin de caixa **de quem matou**; morto **de outro jeito** → a skin de caixa **dele mesmo**.
- **Quebrar:** a caixa pode ser quebrada a golpes (como uma construção), com **bastante vida**; quebrada, **os itens somem** junto.
- **Some sozinha** depois de um tempo, e **some na hora quando fica vazia** (escolha minha).

### Itens novos (o que os mobs deixam — wiki)

| Mob | Caixa |
|---|---|
| Coelho | 1 carne crua, 1 pele de coelho |
| Lobo | 2 carnes cruas, 1 pele de lobo |
| Aranha | 2 linhas |
| Javali | 4 carnes cruas, 1 pele de javali |
| Falcão | 2 carnes cruas, 4 penas de falcão |

- **Carne crua** (comida) e **carne assada** (comida melhor, receita na fogueira: 1 carne crua → 1 carne assada) — a carne assada é do checklist do MVP. Valores de fome: escolha minha (abaixo).
- **Peles, linha e penas**: recursos, ainda sem receita (entram nas próximas receitas: roupas, cama, sela, livro).

## Não-objetivos

- Times/clãs, zona segura, nascimento aleatório na floresta (outra fase; o nascimento fixo continua, com o lobo de tocaia que já se conhece).
- Loja de verdade: a skin de caixa é um cosmético novo e um **padrão** existe para todos; a compra entra com a loja.
- Modelos finais das caixas e das skins (o Elizeu vai modelar): por enquanto **caixas provisórias** simples, uma por mob e uma padrão para jogador.
- Receitas que usam peles, linha e penas.
- Arco, flechas, escudo e outras armas.
- Rastro de "quem bateu por último" com tempo (assistência, kill steal): só o golpe final conta.

## Anti-objetivos

- Item duplicado ou sumido na caixa (dois jogadores pegando o mesmo item ao mesmo tempo, pedido forjado, caixa quebrada no meio de um saque).
- Bônus de pontos dado duas vezes, ou para quem não deu o golpe final.
- Jogador conseguindo bater em si mesmo, ou o golpe acertando o jogador quando havia um recurso/mob mais perto à frente.
- Caixas acumulando no mapa para sempre (servidor pesado).
- Lança empurrando jogador.
- Sistema que conhece mob ou item pelo nome: o que cada mob deixa e o modelo da caixa vêm dos dados.

## Números (escolhas minhas, provisórias, em dados)

- Caixa de jogador some em **3 min**; de mob em **1 min**; vazia some na hora.
- Vida da caixa: **600** (uma parede de madeira tem 1000; picareta de ouro = 30 golpes ≈ 15 s). Dano na caixa = o mesmo dano em construção (`structureDamage`, mão 5).
- Abrir: até **8 studs** do centro da caixa (o mesmo alcance do baú).
- Carne crua: fome +15. Carne assada: fome +35; receita na fogueira, 3 s. (Frutinha hoje: +10.)
- Raio da caixa (para golpe e colisão de construção): 1,5 stud.

## Como funciona (decisões)

- **Vida 200:** a vida ganha um teto próprio (não muda o `StatusMax` das outras barras); a cura de comida e a regeneração continuam iguais em pontos (curam proporcionalmente menos).
- **Golpe em jogador:** o `GatherService` passa a ter jogadores como candidatos (menos quem bate), com o raio do corpo do jogador. O dano usa o `CharacterService.hurt` tipo combate com **quem bateu** junto, para o `DeathService` saber quem matou (golpe final).
- **Caixas no servidor:** um serviço dono das caixas (como o baú da G4 e o `StructureService`): índice espacial, vida, tempo de vida, conteúdo em slots, e a troca "pegar este slot" sem pausa no meio (dois jogadores no mesmo item: um leva, o outro recebe o que sobrou). O cliente só pede "pegar slot X da caixa Y"; o servidor confere distância, se a caixa existe e se o item cabe (pega o que couber, o resto fica).
- **Morte do jogador** (`DeathService`): em vez de só zerar o inventário/mochila/armadura, move tudo para uma caixa no lugar da morte, com a skin certa; depois zera como hoje.
- **Morte do mob** (`MobService.onDeath`, o gancho da G5): cria a caixa do mob com os itens dos dados (`Defs.Mobs[id].loot`).
- **Skin de caixa:** novo espaço de cosmético (`crate`) com um padrão; o modelo da caixa sai de `Assets.Crates` pela skin (jogador) ou pelo id do mob.
- **Painel da caixa:** parecido com o painel do baú: aparece sozinho perto de uma caixa, mostra os slots dela; clicar/tocar num slot pega aquele item.
- **Pontos:** no `DeathService`, morte por jogador soma 1/4 do `Score` do morto (arredondado para baixo) ao `Score` de quem matou.

## Restrições

- Server Authority: o servidor decide tudo; o cliente pede e mostra. Atributos do personagem local previsto: ler por polling.
- Conteúdo é dado (drops, tempos, vida da caixa, skins); atributos e tags por `StatNames`; rede por Blink com o servidor validando cada pedido.
- Mobs sem barra de vida (decisão do Elizeu); a caixa também não precisa de barra de vida visível além da que as construções já mostram ao levar dano (escolha minha: mesma barrinha da G4).

## O que fica para quem implementa

A organização dos serviços e eventos; o visual das caixas provisórias e do painel; como o painel lida com várias caixas perto (a mais próxima); o arredondamento e o formato dos textos; a ordem em que os itens entram na caixa.
