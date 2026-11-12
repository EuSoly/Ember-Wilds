# Missões (partida, diárias, semanais, conquistas)

Desde 12/11/2026. Design: `docs/superpowers/specs/2026-11-12-missoes-design.md`; plano: `docs/superpowers/plans/2026-11-12-missoes.md`; números das chrono quests do Starve: `docs/game-design/quests-starve.md`.

## O que é

Uma janela **Missões** com quatro abas, aberta pelo botão redondo do HUD (embaixo da engrenagem) e pela coluna do menu. A bolinha vermelha conta os prêmios esperando o **RESGATAR**.

| Aba | Dura | Progresso | Prêmio |
|---|---|---|---|
| Partida (chrono quests) | a vida atual, prazo em dias de jogo (8 min cada) | tempo da vida + regras | item da quest + pontos da vida |
| Diárias | até 23:59:59 de Brasília | estatísticas desde o sorteio, ou a melhor vida do dia | Golden Ember; a final dá 1 uso de kit |
| Semanais | até domingo 23:59:59 (corte do ranking) | igual às diárias | Golden Ember; a final dá 1 giro especial + 1 uso do Veterano |
| Conquistas | para sempre, 3 níveis | estatísticas do perfil (e a vida atual nas de "uma vida só") | Golden Ember, giros especiais, kits e skins exclusivos |

O Golden Ember das missões **não** passa pelo teto de 300 por hora (sai por `ShopService.give`). No modo criativo nada conta.

## Onde fica cada coisa

| O quê | Arquivo |
|---|---|
| Chrono quests (13; só `survive` e `clean_hands` ligadas) | `src/shared/Defs/Quests.luau` |
| Banco das diárias e semanais | `src/shared/Defs/Missions.luau` |
| Conquistas | `src/shared/Defs/Achievements.luau` |
| Quantas por dia, finais, intervalo do resgate | `src/shared/Missions/MissionConfig.luau` |
| Regras puras (testadas) | `src/shared/Missions/` (`PeriodRules`, `AchievementRules`, `ChronoRules`, `MissionData`) |
| Diárias, semanais, conquistas no servidor | `src/server/Services/MissionService.luau` |
| Chrono quests no servidor | `src/server/Services/QuestService.luau` |
| Tela, botão, faixa | `src/client/Screens/MissionsScreen.luau`, `src/client/UI/MissionsButton.luau`, `src/client/UI/MissionBanner.luau`, `src/client/MissionsState.luau` |
| Textos da tela (puro) | `src/shared/UIFlow/MissionView.luau` |
| Artes | `src/shared/MissionImages.luau` (fontes em `assets/ui/missoes/`, recorte por `prepare_missoes.py`) |
| Rede | `net/game.blink`: `MissionsData`, `RequestMissions`, `ClaimMission`, `MissionNotice` |

## Como adicionar

- **Diária ou semanal:** uma entrada em `Defs/Missions.luau` (`track` = estatística de `Defs/Stats`, com `key` opcional, ou `{ life = "days" | "score" }`) e o texto `mission.<id>` em `Strings/ptBR.luau` (`{n}` = alvo). Comer e construir ainda não têm estatística, por isso não estão no banco.
- **Conquista:** uma entrada em `Defs/Achievements.luau` com 3 níveis crescentes, mais `achievement.<id>` e `achievement.<id>.goal`. Nível com `rewards = {}` aparece como **Em breve** e não se resgata.
- **Skin exclusiva de conquista:** no nível III, `{ { kind = "cosmetic", id = "<id>" } }`, e a skin com `inSpins = false` em `Defs/Cosmetics.luau` (e fora dos pacotes). Quem já tem a skin recebe o Golden Ember de repetida.
- **Chrono quest nova:** ligar uma em `Defs/Quests.luau` (`enabled = true`) só funciona com `ends = "time"` e as regras `alone`, `unhurt`, `peaceful` (a validação recusa o resto até o `QuestService` ter o motor dos objetivos).

## Regras das chrono quests (QuestService)

- **sozinho (`alone`):** falha num time do totem com 2 ou mais (`TeamService.sizeOf`).
- **sem perder vida (`unhurt`):** falha quando a vida baixa, de qualquer causa (`CharacterService.onHealthLost`).
- **Mãos Limpas (`peaceful`):** falha ao acertar um jogador, ao acertar um mob manso ou neutro (até para se defender; decisão do Elizeu) ou ao pôr um espinho. Mob agressivo pode.
- Resgatar pede espaço no inventário para o item; sem espaço, a faixa avisa e a quest continua pronta. Morreu, tudo da Partida some.

## Testar no Studio (barra de comandos, lado SERVIDOR)

```lua
local p, M = game.Players:GetPlayers()[1], game.ServerStorage.DevMissions
M:Invoke(p, "complete", 2, "daily_wood")  -- 1 Partida, 2 diária, 3 semanal (id do sorteio)
M:Invoke(p, "complete", 1, "survive")     -- chrono quest pronta
M:Invoke(p, "nextDay")                    -- vira o dia deste jogador ("nextWeek" = semana)
M:Invoke(p, "reset")                      -- zera as missões do perfil
print(M:Invoke(p, "dump"))                -- missões salvas + chrono quests, em JSON
```

Conquista: some na estatística com `ServerStorage.DevStat:Invoke(p, "resources_gathered", 1000, "wood")`.
