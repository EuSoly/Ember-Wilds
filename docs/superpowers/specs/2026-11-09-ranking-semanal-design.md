# Ranking semanal (UI 6) — design

Data: 2026-11-09. Combinado com o Elizeu no chat, com rascunho no navegador (aprovado: "está muito bom"). Branch `ui-jogo`.

## Por quê

O painel Ranking do menu ainda é o mockup da G7a (dez nomes falsos do `MockStore.RANKING`, visual antigo). O Elizeu quer o ranking **funcionando de verdade** e **semanal**, porque no futuro vai dar **premiações** para os melhores da semana. É a última UI do menu da ordem combinada; depois vêm "todas as UIs funcionando" (compras reais) e o HUD.

## O que é

Um ranking **global** (todos os servidores) que **zera toda semana**, com **5 categorias** em abas:

| Aba | Ícone (asset) | O que conta na semana |
|---|---|---|
| Pontos | chama com estrela | **Melhor vida** da semana: os pontos de uma vida só (como no Starve). Decisão do Elizeu. |
| XP | escudo com estrela | XP ganho na semana (soma; o mesmo XP que sobe o nível, com o teto por hora do `LevelRules`). |
| Dias | sol e lua | Melhor vida da semana em dias sobrevividos (ciclos completos). |
| Jogadores | espadas cruzadas | Jogadores abatidos na semana (soma; golpe final, como a estatística `players_killed`). |
| Criaturas | pata | Criaturas abatidas na semana (soma de todos os mobs, como `mobs_killed`). |

- **Semana:** termina **domingo às 23:59 (horário de Brasília**, UTC−3, sem horário de verão) — decisão do Elizeu — e a seguinte começa na segunda 00:00. A tela mostra quanto falta: "termina em 3d 5h".
- **Só vale o que acontece dentro da semana:** uma vida que começou no domingo e terminou na segunda conta na semana em que **terminou** *(escolha minha: os pontos/dias/XP só existem no fim da vida)*. Abates contam na hora em que acontecem.
- **Semanas passadas ficam guardadas** (cada semana é um placar separado, nunca apagado), para a premiação ler o top da semana anterior depois. A premiação em si **não** faz parte desta fase.

## A tela (layout aprovado no rascunho)

Abre como hoje: botão Ranking da coluna esquerda do menu → painel à direita da coluna (`MenuState` `"ranking"`).

- **Fundo:** quadro de papel com moldura de madeira, esticado em 9 partes.
- **Título:** taça + "RANKING SEMANAL" no topo; à direita, a pílula "termina em Xd Yh".
- **Abas:** as 5 categorias, cada uma com o ícone e o nome; a selecionada fica laranja e levantada. Começa em Pontos.
- **Pódio (esquerda):** a imagem do pódio de três degraus (2º, 1º, 3º). Em cima de cada degrau: o avatar do Roblox do jogador (headshot) dentro da moldura redonda, com a medalha (1/2/3) no canto; nome e valor logo acima/abaixo do avatar sem cobrir o degrau vizinho. As plaquinhas do pódio mostram "1º", "2º", "3º" escritos por código.
- **Lista (direita):** do 4º ao 50º, rolando; faixas de papel clara e escura alternadas; cada linha: posição, avatar pequeno, nome, valor (com a unidade da categoria: "pts", "XP", "dias"; abates sem unidade).
- **Sua linha:** fixa embaixo da lista, na faixa vermelha com moldura, com a seta-marcador apontando para ela: sua posição, avatar, nome "(você)" e valor. Fora do top 100 mostra "100+" no lugar da posição *(escolha minha: o DataStore ordenado não dá a posição de qualquer jogador barato)*. Sem nada na semana: "—" e valor 0.
- **Vazio:** categoria sem ninguém na semana mostra o pódio sem avatares e uma linha "Ninguém ainda nesta semana".
- **Carregando / falha:** enquanto os dados não chegam, "Carregando…"; se a leitura falhar, "Ranking indisponível agora" e tenta de novo ao reabrir.

### Resoluções (pedido explícito do Elizeu)

Tem que ficar alinhado em qualquer tela (PC largo, celular deitado, janelas baixas, escala de interface 0,8–1,25):
- Tudo do pódio é posicionado **em proporção à imagem do pódio** (que mantém a proporção com `UIAspectRatioConstraint`): avatares em cima de cada degrau e os números nas plaquinhas usam posições relativas medidas na imagem, nunca pixels fixos.
- O quadro de papel, as faixas e a faixa vermelha usam 9 partes com cantos que não esticam.
- Em tela compacta (regra do design system: largura < 900 ou altura < 500), o pódio diminui e a lista ocupa o resto; se não couber lado a lado, o pódio vai para cima da lista. Alvos de toque ≥ 44 px depois da escala.
- Verificar no Studio em pelo menos: 1920×1080, 1280×720 e o emulador de celular deitado.

## Assets

Arte do Elizeu (gerada por IA) em `Downloads/UI Assets/UI dos rankings` (9 arquivos, já revisados): quadro de papel, taça, medalhas 1/2/3, faixas clara/escura, faixa vermelha lisa, pódio com plaquinhas vazias, moldura do avatar + seta, 5 ícones das abas. Preparo:
- Recortar cada peça (algumas vêm juntas no mesmo arquivo), limpar respingos soltos (a faixa vermelha tem pontinhos acima da moldura), reduzir para no máximo 1024 px e salvar as fontes em `assets/ui/ranking/`.
- Enviar ao Roblox **na conta do Elizeu, com a confirmação dele antes** (como as artes da loja), e guardar os ids num módulo `RankingImages` (mesmo jeito de `ShopImages`: id vazio = desenho de reserva por código, a tela continua funcionando).
- Medidas de 9 partes e posições relativas do pódio ficam no módulo junto dos ids.

## Dados e regras

- **Onde fica o placar:** um DataStore ordenado por categoria e semana (ex. `Rank_points_2026-W46`). No Studio usa o prefixo de dev já usado pelo `DataService` (`Dev_`), para testes nunca sujarem o placar do jogo.
- **Valor da semana de cada jogador** fica salvo no perfil (ProfileStore), junto com a semana a que se refere: ao virar a semana, zera. O placar ordenado recebe o valor do perfil (não soma direto no DataStore), para não perder nem duplicar se a gravação falhar.
- **Quando grava no placar:** só quando o valor da semana muda, e no máximo de tempos em tempos por jogador (dentro dos limites do DataStore); sempre ao fim da vida e ao sair.
- **Leitura:** o servidor lê o top 100 de cada categoria com cache (alguns minutos) e manda para o cliente quando ele abre a tela ou troca de aba; o cliente nunca lê DataStore.
- **De onde vêm os números:** fim de vida (pontos, dias e XP da vida, já calculados pelo `LifeService`) e abates (jogador: golpe final; mob: morte do mob) — as mesmas fontes das estatísticas do Perfil.
- **Quem entra:** todo jogador com valor > 0 na semana. Bonecos de teste (DevCrowd) não entram.
- **Abates de jogador:** contam no golpe final (`DeathService.kill` com `killer`). Hoje a estatística `players_killed` do Perfil **nunca é somada** (bug achado na revisão): ligar ali a estatística do Perfil e a contagem da semana.

## Contra trapaça (decisões do Elizeu, 09/11)

- **Servidores privados (VIP) não gravam no placar.** Ainda não existem no jogo, mas a regra já fica pronta (servidor privado não grava; o resto do jogo funciona igual).
- **Limite de abates no mesmo alvo:** implementado e **desligado** por enquanto (pouca gente jogando). Um número na configuração (ex. máximo de abates do mesmo jogador por dia que contam no ranking); 0 = sem limite. Vale só para o ranking (o Perfil conta tudo).
- **Comando de moderação:** tirar um jogador do placar de uma semana (zera os valores dele naquela semana em todas as categorias). Comando de dev, como os `ServerStorage.Dev*` (Studio), pelo id do jogador; a versão para o jogo publicado fica para quando houver painel de admin.
- **Mockup:** `MockStore.RANKING` e os textos `mock.rank.*` saem quando o ranking real estiver pronto.

## Fora desta fase

- Premiação (o que, quando e como entregar).
- Ranking do servidor atual ou de todos os tempos.
- Tela de "campeões da semana passada".
- HUD e as compras reais (próximas etapas da branch `ui-jogo`).

## Decisões do Elizeu (09/11)

Semanal (não global de sempre); categorias = pontos (melhor vida), XP, dias, jogadores, criaturas; arte dele; alinhamento correto em todas as resoluções; layout do rascunho aprovado.

## Escolhas minhas (para o Elizeu conferir)

Virada da semana na segunda 00:00 de Brasília; vida conta na semana em que termina; top 50 na lista e posição própria só até o 100º ("100+" depois); cache de alguns minutos (o placar não é ao vivo).
