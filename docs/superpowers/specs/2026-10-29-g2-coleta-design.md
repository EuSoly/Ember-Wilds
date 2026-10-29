# G2 — Coleta (design)

Data: 2026-10-29. Conversado com o Elizeu em chat ("somente isso mesmo, pode escrever").

## Intenção

Fazer o jogador ganhar recursos batendo no mundo, como no Starve.io: segurar o botão de usar na frente de uma árvore, rocha, jazida de ouro ou arbusto e ver o recurso entrar no inventário. É o loop base do jogo: tudo o que vem depois (crafting, construção) depende disso.

O que o Elizeu disse que faz a coleta ser gostosa:
- um **"poing"** visível no que está sendo coletado;
- **efeitos sonoros**;
- picaretas melhores **pegam mais** recurso, tier a tier;
- recursos **não somem**: avisam que acabou e **regeneram aos poucos** (como no Starve);
- o **arbusto mostra quantas frutinhas tem** (como no Starve).

## Objetivos

- Bater (segurar o botão de usar, que já existe e já anima o boneco) coleta o recurso à frente do boneco, 2 golpes por segundo.
- Ferramenta mínima e rendimento por golpe vindos de dados (tabela abaixo), prontos para os tiers futuros.
- Cada recurso tem uma reserva que diminui a cada golpe e regenera com o tempo. Vazio: o modelo fica, e o jogador vê "Este recurso acabou".
- Arbusto mostra as frutinhas que ainda tem (peças `Berry` do modelo).
- Feedback no cliente: tranco do recurso na direção do golpe, lasquinhas da cor do material e som por material, para todos que estão perto.
- Pontos de verdade por coleta (Score) e ranking real do servidor (Rank); estatística `resources_gathered` por item.

## Não-objetivos

- Crafting, construção, dano em jogadores/mobs (outras fases G). Com arma na mão, por enquanto, bate como mão.
- Pá, terra, sementes, plantio.
- Tiers acima de ouro (diamante etc. entram como dados no inverno).
- Ferramenta quebrando / durabilidade (o Starve não tem).

## Números

### Ferramenta e rendimento (catálogo do Starve)

Cada picareta tem um **nível** (madeira 1, pedra 2, ouro 3; a mão e qualquer outro item = 0). Cada recurso mineral tem uma **dureza** (madeira 0, pedra 1, ouro 2). Rendimento por golpe = `nível − dureza + 1`; nível menor que a dureza = não coleta e avisa qual picareta precisa.

| Na mão | Madeira | Pedra | Ouro | Frutinha |
|---|---|---|---|---|
| Mão | 1 | — | — | 1 |
| Picareta de madeira | 2 | 1 | — | 1 |
| Picareta de pedra | 3 | 2 | 1 | 1 |
| Picareta de ouro | 4 | 3 | 2 | 1 |

Frutinha: sempre 1 por golpe, com qualquer coisa na mão (rendimento fixo).

### Reserva e regeneração

| Recurso | Reserva | Volta |
|---|---|---|
| Árvore | 20 a 80 de madeira, conforme o tamanho do exemplar (o menor = 20, o maior = 80) | +2 a cada 10 s |
| Rocha | 40 de pedra | +2 a cada 10 s |
| Jazida de ouro | 20 de ouro | +1 a cada 10 s |
| Arbusto | 7 frutinhas (uma por bolinha do modelo do Elizeu) | +1 a cada 10 s |

Origem: wiki do Starve (carvalho pequeno 20 / grande 80, regeneração de 6 a 10 s, arbusto +1 a cada 10 s). O 7 do arbusto é decisão minha (o Starve usa 5): com uma frutinha por bolinha, o número visível é exato.

### Ritmo, alcance e pontos

- 2 golpes por segundo (sugestão minha).
- O golpe acerta o recurso cuja peça de colisão encosta num círculo de raio 2,5 studs centrado 3,5 studs à frente da raiz do boneco (na direção em que ele olha). Mais de um: o mais perto do centro do círculo.
- Pontos por unidade coletada: madeira 1, pedra 2, frutinha 2 (Starve), ouro 3 (chute meu).

## Como funciona (decisões)

### Dados

- `Defs/Items`: picaretas ganham `pickaxe = { level = n }`.
- `Defs/Resources`: cada recurso coletável ganha o bloco `gather`:
  - `item` (id em Items), `points` (por unidade), `material` (som e lasquinhas: "wood" | "stone" | "gold" | "leaves");
  - `hardness` (dureza) **ou** `fixedYield` (rendimento fixo, ex. frutinha);
  - `amount = { min, max }` (reserva; min ≠ max = cresce com o tamanho do exemplar);
  - `regen = { amount, every }`.
  - Enfeites (pedras do chão) não têm `gather`.
- Validação de tudo isso em `Validate`, como o resto das Defs.

### Regras puras (testáveis)

- Rendimento por golpe dado o item na mão e o recurso.
- Picareta mínima para uma dureza (para a mensagem).
- Reserva de um exemplar pelo tamanho.
- Regeneração (quanto voltou em X segundos, sem passar do máximo).
- Escolha do alvo do golpe (círculo à frente × peças de colisão, o mais perto).
- Quantas frutinhas mostrar (proporção da reserva × peças `Berry`, arredondando para cima enquanto houver alguma).
- Ranking (posição por pontos; empate = quem chegou antes no servidor).

### Servidor

- O `MapService` passa a guardar, para cada recurso montado: posição, raio de colisão do exemplar, def e reserva máxima. Um índice espacial (grade) acha rápido os recursos perto do golpe.
- Reserva atual no atributo `Amount` do modelo (o cliente lê para as frutinhas). Só os recursos não cheios entram na fila de regeneração (um laço a cada 1 s).
- `GatherService`: para quem está segurando o botão (`Using`), vivo e sem comida na mão, no máximo um golpe a cada 0,5 s: acha o alvo; sem alvo, nada; ferramenta fraca → aviso; vazio → aviso; senão tira da reserva o que der (rendimento, limitado pelo que tem e pelo espaço no inventário), dá o item, soma pontos e a estatística, e avisa os clientes perto.
- Avisos ao jogador (precisa de picareta X, este recurso acabou, inventário cheio) vão por rede, no máximo um igual a cada 2 s por jogador.
- `ScoreService`: dono do `Score` (soma pontos) e do `Rank` (recalcula a cada 1 s). O `DevStatsService` (pontos falsos) é apagado.

### Cliente

- `GatherFx`: ao receber o golpe, o modelo dá um tranco de ~0,3 stud na direção do golpe e volta (0,15 s), solta lasquinhas da cor do material no ponto do golpe e toca o som do material (`SoundGroup` de efeitos, que já obedece o volume das configurações).
- Sons ficam num arquivo de dados por material, com ids de áudio da loja do Roblox escolhidos na implementação; o Elizeu troca depois.
- Arbusto: um controlador mostra/esconde as peças `Berry` de cada arbusto conforme o atributo `Amount` (via `LocalTransparencyModifier`, só no cliente).
- Avisos usam o `Notifications` que já existe.

### Place (Studio)

- As 7 frutinhas do `ServerStorage.Assets.Resources.berry_bush_1` são renomeadas para `Berry` (eu faço pelo MCP; o Elizeu salva o place). O guia do mapa ganha a regra: peças `Berry` mostram a reserva.

## Restrições

- Server Authority: o servidor decide tudo (alvo, rendimento, reserva); o cliente só mostra.
- Conteúdo é dado: nenhum código conhece "tree" ou "berry" pelo nome.
- Comer continua igual: com comida na mão, o botão de usar come e não coleta.
- 1.600 recursos no mapa: nada pode varrer todos a cada golpe (por isso a grade).

## Decisões menores (minhas, depois da leitura do revisor)

- Reserva da árvore: linear com o tamanho do exemplar (`Scatter.sizeFactor`, de 0,85 a 1,15): o menor = 20, o maior = 80.
- O primeiro golpe sai na hora em que o jogador aperta; segurando, um a cada 0,5 s.
- A batida do braço do boneco passa de 0,45 s para 0,5 s (`BonecoConfig.SWING_PERIOD`), no mesmo compasso do golpe do servidor, para o "poing" cair junto com o braço.
- Efeito do golpe vai para os jogadores a até 100 studs.
- O ranking só conta quem está no jogo (vivo); quem está no menu fica sem posição.
- `Notifications.push` passa a aceitar valores no texto (ex. o nome da picareta).
- Risco técnico a testar logo no começo: o cliente mover localmente o modelo do recurso (do servidor) para o tranco, com Server Authority.

## O que fica para quem implementa

Forma exata da grade, nomes internos, curvas do tranco, quantidade de lasquinhas, ids de som.
