# Construções: números do Starve, peças novas, máquina de esmeralda, ressurreição e times (design)

Data: 11/11/2026 · Branch: `melhorias`

## Por quê

O Elizeu quer as construções funcionando de verdade: extratores, revive (pedra da ressurreição) e o resto ("e tals"). As construções da G8 já funcionam, mas são só de teste e usam receitas provisórias. Faltam os modelos de diamante e ametista, a máquina de esmeralda, a pedra da ressurreição e o totem. Mesmo método das armaduras e das ferramentas: números e receitas da **config oficial do Starve** (`starve.io/commands.html`), comportamento pela wiki e pelos textos de ajuda do guia oficial, e `testOnly` no que depender de material que o jogo ainda não dá.

## Decisões do Elizeu

- Deixar as construções funcionando, inclusive extratores e revive (11/11).
- Pode seguir sem aprovações no meio; revisão no fim (combinado das fases anteriores).

## Parte A: números do Starve e liberação

| Peça | Starve (config) | Muda |
|---|---|---|
| Paredes, portas | vida 1000 / 1500 / 2000 / 2500 / 3500 / 4000 | diamante e ametista novos; resto já bate |
| Espinhos | vida 150 / 300 / 600 / 1200 / 2400 / 3000; encostar 10..60; bater 2/3/3/4/4/5 | novo `spikeHitDamage`; diamante e ametista novos |
| Portas com espinho | vida **100 / 200 / 400 / 800 / 1600 / 2000**; encostar **5 / 10 / 15 / 25 / 30 / 35**; bater 1/2/2/3/3/4 | vida e dano corrigidos (hoje 1000..3500 e 10..60) |
| Extratores | 2000 de vida; 1 minério a cada **10 s**; **2 madeiras** por minério; até **255** de madeira e de minério | números trocados; diamante e ametista novos |
| Fornalha | 150 madeira, 50 pedra, 15 ouro; vida 1000; 1 madeira a cada 5 s | receita e vida |
| Ponte, telhado, placa | 15 madeira / 30 madeira / 20 madeira | receitas |
| Cama | 100 madeira, 50 pedra, 5 pele de coelho, 5 pele de lobo, 6 linhas; vida 400 | vida |
| Poço | 100 pedra + 30 terra (bancada + fogo) | continua só de teste (terra vem da pá) |
| Totem | 50 madeira | novo (Parte E) |
| Pedra da ressurreição | 40 diamante, 45 pedra; vida 200 | nova (Parte D) |
| Máquina de esmeralda | pedra da ressurreição, 40 esmeraldas, 1 suco de verme (bancada + fogo + água); vida 1000 | nova (Parte C) |

Receitas de paredes, portas, espinhos e portas com espinho de diamante e ametista: a escada da config. Por exemplo, parede de diamante = parede de ouro + 11 diamantes; espinho = parede + 40 do material + 30 pedra.

**Bater no espinho:** quem bate num espinho alheio leva o `spikeHitDamage` como golpe de jogador. Encostar continua igual.

**Liberadas:**
- portas com espinho de madeira, pedra e ouro;
- extratores de pedra e ouro;
- fornalha, ponte, telhado, placa e cama;
- totem.

**Só para teste** (falta material):
- tudo de diamante para cima;
- poço (falta terra), pedra da ressurreição (falta diamante) e máquina de esmeralda (falta esmeralda e suco).

Os materiais novos `emerald` e `sandworm_juice` também ficam só para teste.

## Parte B: extratores

O `MachineService` já funciona e muda só nos dados:
- `woodPerCycle = 2`, `cycleSeconds = 10`, `yield = 1`, `maxWood = 255`, `maxStock = 255`;
- cada extrator produz o minério do nome dele.

Quem põe madeira e quem tira minério segue a regra de hoje: qualquer um põe, só o dono e os aliados tiram. Com os times (Parte E), "aliados" passa a valer.

## Parte C: máquina de esmeralda

- Dá **750 pontos por minuto** ao dono (o número da floresta; outros biomas ainda não existem), como pontos da vida, contando de um em um segundo.
- Os bônus de craft, coleta, abate e domar ficam só como dado (todos 1 na config).
- **Só uma colocada por jogador**: o servidor recusa a segunda.
- **Se for destruída, o dono morre** (causa "Máquina destruída"). Peça removida porque o dono saiu ou morreu não conta.
- Não pode ser colocada na água.

## Parte D: pedra da ressurreição e fantasma

- **Quando:** o jogador morre (`DeathService.kill`) com **Coração de Dragão no inventário** ou **vestindo a Coroa do Anjo**. Se existir alguma pedra da ressurreição no mundo, ele vira **fantasma** em vez de morrer.
- **Tempo de fantasma:** 60 s. Com a coroa, o tempo cai pelo item mais forte que ele segurou nos últimos 30 s (diamante 35, ametista 25, reidite 15, dragão 8, lava 5; até ouro 60). Com o coração, sempre 60 s, e o coração é gasto.
- **O fantasma:**
  - as barras não mudam;
  - não leva dano;
  - atravessa construções e recursos;
  - não bate, não coleta, não constrói, não come e não veste;
  - aparece translúcido azulado para todos.
- **Ressuscitar:** a até `REVIVE_RADIUS` (6 studs) de uma pedra da ressurreição, aparece o botão **Ressuscitar**. Ao clicar:
  - volta com a vida cheia e as outras barras cheias;
  - fica com **1/3 dos pontos** da vida;
  - perde os itens da lista do Starve. Com o coração: espadas, lanças, escudos, picaretas, chave inglesa, forcados, super martelo e martelos de reidite para cima. Com a coroa: espadas, lanças, escudos, espinhos, portas com espinho, ferramentas acima de reidite e super martelo.
  
  A pedra não some. Qualquer jogador usa qualquer pedra (a wiki não restringe).
- **Tempo acabou:** morte normal, com a caixa e a tela de morte de sempre.
- **Quem matou:** quem tirou a vida de alguém que virou fantasma ganha **10% dos pontos** da vítima, em vez dos 15% de uma morte normal, e **não conta abate**.

## Parte E: totem e times

- **Criar:** colocar um totem cria o time do dono, que vira líder. **Um totem por jogador**; ele só pode estar num time.
- **Entrar:** perto de um totem (até `TOTEM_RADIUS`, 10 studs), aparece o botão **Entrar no time** se o time não estiver trancado e tiver vaga (**máximo 8**, contando o líder).
- **Líder:** perto do próprio totem, pode **trancar ou destrancar** e **expulsar** um membro.
- **Sair:** qualquer membro sai a qualquer momento. Quem sai ou é expulso espera **20 s** para entrar em outro time. O líder sair, morrer ou ter o totem destruído **desfaz o time** (minha escolha; a wiki não diz).
- **Efeitos:** `BuildRules.areAllies` passa a perguntar ao time. Isso vale para portas, baús, espinhos (não machucam colegas) e máquinas. Golpe entre colegas tira **30%** do dano.
- **Na tela:** um painel pequeno do time (membros, Sair e, para o líder, Trancar e o X de expulsar) e um ícone verde no nick dos colegas, só para o time.

## Ordem de entrega

A → B → C → D → E, cada uma com commits e testes. D e E são as maiores.

## Fora do escopo

- Ponte e telhado de pedra (sem modelo).
- Cadeado e chave.
- Biomas e bônus da máquina.
- Minimapa com colegas.
- Domar.

## Testes

Regras puras para:
- vida, dano e receitas (dados);
- números dos extratores;
- pontos por minuto da máquina e a regra de uma por jogador;
- tempo de fantasma pelo item mais forte, itens perdidos, pontos ao ressuscitar e pontos de quem matou;
- regras do time: vaga, trava, espera de 20 s, aliados e dano de 30%.
