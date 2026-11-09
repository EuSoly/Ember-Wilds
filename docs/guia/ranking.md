# Ranking semanal (UI 6)

Ranking global (todos os servidores) que **zera toda semana**: termina **domingo às 23:59 de Brasília** e a semana seguinte começa segunda 00:00. Pensado para premiar os melhores da semana no futuro (a premiação ainda não existe). Design: `docs/superpowers/specs/2026-11-09-ranking-semanal-design.md`; plano: `docs/superpowers/plans/2026-11-09-ranking-semanal.md`.

## As 5 abas

| Aba | Conta na semana |
|---|---|
| Pontos | a **melhor vida** (pontos de uma vida só) |
| XP | o XP ganho (soma; o mesmo do nível, com o teto por hora) |
| Dias | a melhor vida em dias sobrevividos |
| Jogadores | jogadores abatidos (golpe final) |
| Criaturas | criaturas abatidas |

Uma vida conta na semana em que **termina**. Abates contam na hora.

## Como funciona

1. **Perfil:** o valor da semana de cada jogador fica no perfil (campo `Ranking`, regras em `src/shared/Data/RankRules.luau`). Ao virar a semana, zera sozinho na próxima leitura.
2. **Fontes:** `LifeService.endLife` (pontos, dias, XP da vida), `DeathService.kill` (golpe final em jogador; também soma o "Jogadores mortos" do Perfil) e `MobService` (mob morto) chamam o `RankService`.
3. **Placar:** `RankService` copia os valores para um DataStore ordenado por categoria (`Rank_<categoria>`, escopo `W<semana>`; no Studio `Dev_Rank_<categoria>`). Grava a cada minuto, no fim da vida e ao sair; uma gravação por jogador de cada vez, lendo o valor do perfil na hora (nada contado durante a espera se perde). Na virada da semana, o que a semana velha ainda devia é gravado no escopo dela antes de zerar. Servidor VIP não conta: nem soma nem grava. Semanas antigas ficam guardadas (a premiação lê de lá).
4. **Tela:** ao abrir o Ranking ou trocar de aba, o cliente pede (`Net.RequestRanking`) e o servidor responde (`Net.RankingData`) com o top 50 (lido do top 100 em cache de 3 min), o seu valor e a sua posição (até o 100º; depois "100+"). Quem pede sempre se vê na lista com o valor atual, mesmo com o top em cache (`RankRules.withPlayer`); os outros jogadores aparecem com até 3 min de atraso. Pedidos rápidos demais (troca rápida de aba) esperam a vez e o servidor responde o último. Em janela compacta (largura < 900 ou altura < 500) as abas sobem para a linha do título e o "termina em…" vai para o canto do pódio.

## Onde mudar

| O quê | Onde |
|---|---|
| Virada da semana, tamanhos da lista, cache, intervalo de gravação, limite de abates no mesmo alvo | `src/shared/Data/RankConfig.luau` |
| Textos | chaves `rank.*` em `src/shared/Strings/ptBR.luau` |
| Artes (ids, 9 partes, posições do pódio) | `src/shared/RankingImages.luau` (fontes em `assets/ui/ranking/`, recorte por `prepare_ranking.py`) |
| Tamanhos da tela (compacto, empilhado, alturas mínimas) | `src/shared/UIFlow/RankingLayout.luau` |
| Tela | `src/client/Menu/Ranking/` (`RankingScreen`, `RankingPodium`, `RankingList`, `RankingState`) |

**Limite de abates no mesmo jogador:** `RankConfig.SAME_VICTIM_DAILY_LIMIT` (0 = desligado, como está; decisão do Elizeu enquanto há pouca gente jogando). Com 3, por exemplo, matar o mesmo jogador conta no máximo 3 vezes por dia no ranking (o Perfil conta tudo).

**Pódio desalinhado com uma arte nova:** as posições ficam em `RankingImages.PODIUM_SPOTS`, em frações da imagem (x do degrau, topo do tampo, centro da plaquinha). O `prepare_ranking.py` imprime uma primeira medida; confira com uma régua sobre a imagem (a da plaquinha do 1º saiu errada na primeira vez).

## Comandos de teste (Studio, vista do Servidor)

```lua
-- Tirar alguém do placar desta semana (moderação); semana opcional no 2º argumento
game.ServerStorage.DevRankRemove:Invoke(USERID)
-- Esquecer o cache do top (a próxima abertura lê o placar de novo)
game.ServerStorage.DevRankRefresh:Invoke()
```

Para ver a tela cheia no Studio, dá para gravar valores de teste direto no placar de dev (`Dev_Rank_<categoria>`, escopo `W<semana>`) com ids de contas reais do Roblox e depois apagar com `RemoveAsync`.

## O que foi visto no Studio (09/11)

- Gravar e ler de verdade: 4321 pontos voltaram no top com o nome e a posição 1; `DevRankRemove` tirou.
- Tela com 14 jogadores de teste: pódio alinhado (avatares nos tampos, "1º/2º/3º" nas plaquinhas), abas trocando (Pontos → XP), linha "você" com "—" e 0, "termina em 6d 11h".
- Escala de interface 1,25 (área de ~680 px lógicos): continua lado a lado e alinhado.
- Depois da revisão final: troca rápida de aba (Pontos → XP → Dias em 0,2 s) carrega a última; janela compacta 537×379 (escala 1,6) com as abas na linha do título, pódio alinhado e a linha "você" à vista; gravação com a lógica nova (7777 no placar).
