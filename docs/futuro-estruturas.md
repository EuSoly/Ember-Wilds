# Plano do futuro: estruturas além da floresta

A G8 colocou no jogo os modelos do Elizeu e as estruturas que dá para fazer só com os recursos da floresta (madeira, pedra, ouro, frutinha e o que os mobs da floresta deixam). Este documento diz **o que já está pronto** e **o que falta** para cada grupo que depende de coisas que ainda não existem. As regras "da wiki" vêm da wiki do Starve.io; o que não tem fonte é provisório e tem que ser conferido antes de entrar.

Veja `guia/construcao.md` para como as peças funcionam hoje e como liberar um item só para teste.

## O que já está pronto

- **Modelos:** os 55 modelos do world-pack foram importados (`scripts/studio/import-world.luau`). Os de diamante, ametista, reidite e esmeralda já estão no place com o nome original: construções em `ReplicatedStorage.Assets.Structures`, ícones em `Assets.Icons` e depósitos em `ServerStorage.Assets.Resources`. Falta só ligá-los a itens e recursos.
- **Templates por id:** o `StructureModel` pega o visual de `Assets.Structures/<itemId>` e o `ResourceModels` o de `Assets.Resources`; criar o item com o mesmo id basta para o modelo aparecer.
- **Marca `testOnly`:** `ItemDef.testOnly` + `src/shared/ItemAccess.luau`. Item novo pode nascer marcado e só ser liberado num update, tirando a marca.
- **Estruturas de máquina:** `MachineRules`/`MachineService` (extrator e fornalha), `InteractRules`/`InteractService.register`, evento `StructureAction` e o `InteractPanel`. Uma peça nova de usar de perto entra por ali.
- **Portas com espinhos:** `BuildRules.isDoor` e `BuildRules.hurts` aceitam qualquer tier.
- **Bancada de ajuste:** `scripts/studio/structure-bench.luau` (montar, captar, apagar) ajusta qualquer template novo.
- **Aliados:** `BuildRules.areAllies` é o único ponto de decisão (hoje: só o dono).
- **Efeitos de cliente:** `StructureFx` (tampa do baú, rotor, chamas), `RoofFade`.

## Diamante, ametista e reidite

**Estado:** os tiers existem em `Defs/Tiers.luau` e as picaretas dos três já são itens. Modelos prontos. **Não existem** os recursos (minério) nem os biomas onde nascem, então nada disso pode ser obtido ainda.

Regras da wiki (a confirmar na wiki na hora de implementar): cada tier novo é mais resistente que o anterior; a construção do tier só se faz com o minério dele.

O que falta, por tier (diamante, ametista, reidite):

1. **Recurso e bioma:** minério em `Defs/Resources.luau` e zona em `Defs/ResourceZones.luau`; o bioma novo no mapa (veja `guia/mapa.md`). A picareta de nível certo já existe. É o bloqueio de tudo abaixo.
2. **Item do minério** (`diamond`, `amethyst`, `reidite`) em `Defs/Items.luau`, com texto em `Strings/ptBR.luau`.
3. **Depósito:** ligar o modelo (`<tier>_deposit_icon`, já em `Assets.Resources`) ao recurso. O mapa já lê os modelos por nome.
4. **Ícone:** o template do ícone já está em `Assets.Icons`, com o id do minério ou item (`wood`, `stone`, `diamond`...); basta o item existir com o mesmo id para o slot mostrar o 3D.
5. **Construções:** parede, porta, espinho e porta com espinhos do tier (`<tier>_wall`, `_door`, `_spike`, `_spike_door`) em `Defs/Items.luau` (bloco `structure`; vida e dano do tier acima do ouro) e receitas em `Defs/Recipes.luau`. Os templates e os colisores seguem as mesmas regras do madeira/pedra/ouro: sem código novo.
6. **Extratores:** `diamond_extractor`, `amethyst_extractor` e `reidite_extractor` (kind `extractor`, bloco `extractor` com o minério do tier em `output`). O modelo e o rotor já existem; ciclo e estoque provisórios como nos de pedra e ouro.
7. **Dano em construção:** ajustar o `structureDamage` das armas se for preciso para os tiers novos (valores provisórios hoje).

Marcar tudo com `testOnly = true` até o bioma existir.

## Esmeralda

**Estado:** o tier `emerald` existe (ramo lateral, `order = 0`) e o modelo do depósito, o ícone e a máquina estão no place. Sem recurso, sem item e sem lógica.

Regras da wiki:

- A **máquina de esmeralda** dá **pontos ao longo do tempo, conforme o bioma** onde está colocada.
- **Uma por jogador.**
- Se ela for **quebrada, quem a construiu morre**.

O que falta:

1. **Depósito e ícone:** igual aos minérios acima (recurso, zona, item `emerald`, template já pronto). Precisa do bioma.
2. **Máquina** (`emerald_machine`, kind novo, por exemplo `emerald_machine`): peça com vida e bloco de dados `emeraldMachine` com pontos por intervalo, por bioma.
3. **Regras puras** `EmeraldRules` (testadas no Lune): pontos por bioma e intervalo; "uma por jogador" (conferir em `canPlace`, contando as peças do dono); o dono morre se ela for destruída.
4. **Serviço:** pontua o dono a cada intervalo (o `ScoreService` já guarda os pontos da vida atual e o ranking; basta chamar `ScoreService.add`, mas os pontos por intervalo ainda não têm fonte: ver `game-design/` antes) e ligar a destruição da peça (`StructureService.onRemoved`) à morte do dono, com causa de morte nova ("Máquina de esmeralda" em `Strings`).
5. **Visual:** o efeito de girar/brilhar no `StructureFx`.

Números (pontos por bioma e intervalo) vêm da wiki; sem fonte, provisórios.

## Pedra de ressurreição

**Estado:** nada implementado. Depende de itens e mobs que ainda não existem.

Regras da wiki:

- Cria-se com o **Coração de Dragão** ou a **Coroa do Anjo**.
- Depois de morrer, o jogador tem **60 s** para chegar até ela; se chegar, **revive** mantendo **um terço da pontuação**.

O que falta:

1. **Itens de origem:** Coração de Dragão e Coroa do Anjo (dependem do dragão e do anjo, mobs e biomas futuros).
2. **Peça** `resurrection_stone` com receita que gasta um dos dois itens (provisório até a wiki ser conferida).
3. **Revive:** hoje a morte apaga as peças do dono (`StructureService.removeOwned`, chamado pelo `DeathService`) e o jogo recomeça pelo menu. É preciso uma janela de 60 s depois da morte em que as peças do dono **não** são removidas, um estado "morto esperando" e o caminho do revive no `DeathService`/`Lifecycle`, mantendo 1/3 da pontuação. O guia de construção já prevê isso: um revive "simplesmente não chama `removeOwned`".
4. **Interação:** o jogador morto precisa alcançar a pedra: modo fantasma ou respawn até ela (decisão de design a conversar).
5. **Regras puras** testadas no Lune (janela de 60 s, pontuação mantida).

## Totem e times (próxima etapa)

**Estado:** nada implementado. `BuildRules.areAllies(userIdA, userIdB)` é o **único ponto** onde "aliado" é decidido; hoje responde "é o mesmo jogador". Porta, porta com espinhos, espinho, extrator, fornalha e placa usam esse ponto (ou usarão): quando o time existir, **muda só essa função**.

O que falta:

1. **Totem:** peça que cria e gerencia o time (convite, entrada, saída). Dados em `Defs/Items.luau` e um serviço `TeamService` com regras puras testadas.
2. **`areAllies`:** passar a olhar o time do dono. Conferir que tudo que hoje é "só o dono" passe a valer para o time: abrir portas, não levar dano de espinho, usar extrator e fornalha. Hoje qualquer um perto põe madeira, mas só o dono pega o estoque do extrator; isso deve virar "dono e aliados".
3. **Placa:** hoje só o dono troca o símbolo; decidir se aliados também podem.
4. **Interface:** lista do time no HUD (`guia/hud.md`) e texto das chaves novas em `Strings`.
5. **Dono que morre:** hoje todas as peças dele somem (`removeOwned`); com time, decidir se a base passa para o time.

## Ordem sugerida

1. Biomas e minérios (destrava diamante, ametista, reidite e esmeralda).
2. Construções, portas com espinhos e extratores dos três tiers (só dados, marcados `testOnly`).
3. Máquina de esmeralda.
4. Totem e times (muda `areAllies`).
5. Pedra de ressurreição (precisa dos mobs e itens finais).
