# Pesquisa 4 — Sistemas de gameplay (out/2026)

[V] verificado; [O] opinião. Conferido por mim: Server Authority em full release (devforum 4727993; enum AuthorityMode doc atualizada 22/10/2026). Blink ATIVO (v0.18.9, 19/09/2026 via gh api) — o pesquisador 4 errou ao dizer out/2024.

## 0. Server Authority
- Workspace.AuthorityMode = Server força NextGen Replication, IAS, SignalBehavior Deferred, StreamingEnabled, UseFixedSimulation; cliente só manda input; lógica em RunService:BindToSimulation(); Destroy/Parent erram dentro da simulação; 64 atributos replicados/instância, strings ≤50; RemoteEvents fora da timeline (~40–50 ms); mais CPU no servidor; sem rewind de hit ainda [V].
- Migrar depois custa reescrita [O]; sugerido spike de 1–2 dias.

## 1. Loop
- Um Heartbeat com acumulador: status 2 Hz, calor/espinhos 5 Hz, IA 10 Hz, plantas/respawn 1 Hz; relógio GetServerTimeNow() [O].
- Barras: atributos inteiros no Player, só quando mudam [V].
- Posições de mob: UnreliableRemoteEvent + buffer + sequência; limite documentado 900 bytes [V].
- Sem TweenService no servidor [V].

## 2. Recursos
- Instances anchored com tag "Resource", atributos Kind/Stage/Hp; servidor tem tabela id→estado; respawn reaproveita instância [O].
- CanTouch=false, colisão Box/Hull [V].
- Golpe: cliente manda id; servidor checa cooldown, distância (alcance + ~2 studs), rendimento por tier [O].

## 3. Combate
- Arco à frente; servidor itera jogadores próximos, ângulo+distância; espada: raycast com estruturas bloqueia; lança ignora estruturas [O].
- Lag compensation: histórico ~1 s a 10–20 Hz, rewind ≤200 ms [O/V].
- ShapecastHitbox/RaycastHitbox desnecessárias para top-down; Touched descartado [V/O].
- Anti-speed: distância entre amostras vs WalkSpeed·dt·1,4, puxar de volta; exceção para teleportes do servidor [V/O].

## 4. Construção
- grid[x..","..z] = pieceId no servidor; GetPartBoundsInBox (0,95 da célula) só contra recursos/jogadores; fantasma só no cliente; servidor revalida alcance/limite/recursos [O/V].
- Portas: ToggleDoor(id) checa dono/time.
- Espinhos: checagem de células vizinhas no tick de 5 Hz, cooldown por vítima — não Touched [O].
- Peças anchored, CanTouch false, models ≤64 studs, Nonatomic, nada Persistent [V].

## 5. Mobs
- Humanoid caro [V]; caso de referência 10 mil NPCs sem Humanoid, buffer 20 Hz, 500 NPCs ≈ 15 KB/s [V].
- Mob = dados no servidor (pos 2D, estado, alvo), FSM Idle/Wander/Flee/Chase/Attack/Return, steering + 2–3 raycasts; lobo LOS a 4–5 Hz; parte anchored invisível via BulkMoveTo para hits; visual no cliente via buffer 10–20 Hz [O].
- PathfindingService só para boss/preso; problemas de performance relatados; SimplePath parado [V].

## 6. Inventário/crafting
- slots fixos {id,count}; operações puras sem yield (atômicas); deltas reliable [O].
- Craft: valida estação por tag, consome ingredientes e fome no início, job {recipe, endsAt}, tick conclui; morte cancela [O].

## 7. Dia/noite e zonas
- CycleStart atributo; cliente e servidor usam mesma fórmula [O].
- biomeAt(x,z) própria; ZonePlus overkill/manutenção incerta [V].
- Fogueiras em hash espacial; calor ≤18 studs [O].

## 8. Loot
- Uma caixa por morte com cópia da tabela, TTL 90–120 s, teto por servidor; itens no chão com TTL varridos a 1 Hz [O].
- Booga Booga original uncopylocked — só referência de estrutura [V/O].
