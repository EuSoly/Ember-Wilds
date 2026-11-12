# Sons (efeitos, ambiente e música)

Todo o áudio do jogo roda **só no cliente** e **sem tráfego de rede novo**: cada som reage a algo que o cliente já recebe (eventos, atributos, tags). Os sons da roleta da loja são à parte (`src/shared/SpinSoundConfig.luau`).

## Onde trocar um som

Tudo fica em **`src/shared/Audio/SoundConfig.luau`**: uma linha por som, com o id, o volume (0 a 1) e um comentário com o nome do áudio na loja, quem publicou e a duração.

1. Ache outro áudio em create.roblox.com/store/audio e copie o número do link.
2. Troque o id na linha do som. Ajuste o volume se precisar.
3. Use só áudios liberados para qualquer jogo: os da própria **Roblox**, da **APM Music** (`APMOfficial`) e da **ProSoundEffects**. Áudio de outro criador pode não tocar fora da conta dele.

Para **acrescentar uma música**, ponha mais uma linha `track(id, volume)` na lista do modo (`menu`, `day`, `night`, `death`). Para **um bicho ganhar som próprio**, crie a chave `mob_<id>_attack`, `mob_<id>_hurt` ou `mob_<id>_death` (ex.: `mob_hawk_attack`); sem ela, o bicho usa `mob_attack` e `mob_death`. Para **um material novo de recurso**, crie `hit_<material>`; sem ela, usa `hit_stone`.

O que cada número de um efeito quer dizer (`fx(id, volume, duração, { ... })`):

| Campo | O que faz | Padrão |
|---|---|---|
| `pitch` | Variação de tom a cada toque (0.1 = ±10%), para o som repetido não cansar | 0.06 |
| `cooldown` | Segundos mínimos entre dois toques do mesmo som | 0.08 |
| `max` | Quantos desse som tocam ao mesmo tempo | 3 |
| `range` | Alcance do som 3D em studs | `ROLLOFF_MAX` (70) |
| `group` | Volume das configurações que vale: `Effects` ou `Ambient` | `Effects` |

Limites gerais, no mesmo arquivo: `MAX_VOICES` (12 efeitos ao mesmo tempo; o que passar é descartado), `ROLLOFF_MIN`/`ROLLOFF_MAX` (12 e 70 studs), `MUSIC_FADE` (3 s de crossfade), `MUSIC_MAX_VOLUME` (0,4: a música fica sempre abaixo dos efeitos; o teste recusa faixa mais alta), `AMBIENT_FADE`, `WATER_RANGE`, `FIRE_RANGE` e `MAX_FIRES`.

## Como funciona

| Arquivo | O que faz |
|---|---|
| `src/shared/Audio/SoundConfig.luau` | Ids, volumes e limites de todos os sons |
| `src/shared/Audio/SoundRules.luau` | Regras puras (testadas): som por material, bicho e botão; cooldown e limite de sons; escolha da faixa e crossfade; volume da água; fogos mais perto |
| `src/client/Audio/SoundPlayer.luau` | Toca os efeitos: `SoundPlayer.play("chave")` (2D) ou `SoundPlayer.play("chave", posição)` (3D). Aplica grupo de volume, tom, cooldown e limite |
| `src/client/Audio/GameSounds.luau` | Liga os efeitos ao jogo: bichos, peças, inventário, craft, sede, fantasma, vida baixa, morte |
| `src/client/Audio/UiSounds.luau` | Clique em todo botão do PlayerGui, sem cada tela precisar lembrar |
| `src/client/Audio/Ambience.luau` | Floresta de dia e de noite, água, fogo e os chamados da noite |
| `src/client/Audio/MusicPlayer.luau` | Música por tela e hora, com crossfade |
| `src/client/Controllers/AudioController.luau` | Liga tudo |
| `src/client/AudioSettings.luau` | Cria os grupos `Music`, `Ambient` e `Effects` e aplica o volume das configurações |

- **Volume:** todo som usa um dos três `SoundGroup`. O jogador ajusta cada um nas configurações.
- **O "ouvido" fica no boneco**, não na câmera. A câmera fica 34 studs acima, e com o ouvido nela tudo soaria baixo. Uma peça invisível (`Workspace.AudioListener`) segue o foco da câmera com a orientação dela, então o que está à direita na tela soa à direita. No menu, o ouvido acompanha quem a câmera mostra.
- **3D e 2D:** o que acontece no mundo (golpes, bichos, portas, máquinas, outros jogadores) é 3D no ponto; interface, avisos e o que é do próprio jogador (dano, pegar item, craft, morte) é 2D.
- **Celular:** além do cooldown e do limite por som, o `SoundPlayer` não cria som 3D além do alcance, só as peças a até 85 studs são lidas, só os 3 fogos mais perto têm som e os loops mudos param de tocar.
- **Polling, não sinal:** com Server Authority, `AttributeChanged` não é confiável. O `GameSounds` lê os atributos a cada 0,1 s (bichos, peças perto e o jogador).

### De onde vem cada efeito

| Som | O que dispara |
|---|---|
| Golpe em recurso (`hit_<material>`) | `Net.ResourceHit` (em `World/GatherFx`) |
| Golpe no ar (`swing`) | Começo de cada golpe do boneco (`BonecoRenderer`), de qualquer jogador |
| Golpe em bicho (`hit_mob` + voz), ataque e morte do bicho | Contadores `MobHurt`/`MobAttack` e `MobDead` na raiz do bicho |
| Dano no jogador (`hurt`, 2D) e em outro jogador (`hit_player`) | Atributo `HurtAt` do personagem (`BonecoRenderer`) |
| Comer (`eat`) | Atributo `EatUntil` do personagem |
| Beber (`drink`) | Sede sobe 8 pontos ou mais de uma vez; ou os goles do poço caem (`Drinks`) |
| Golpe em construção ou caixa (`hit_structure`) | `StructureHealth` da peça cai |
| Colocar (`place`) e quebrar (`structure_break`) | Peça com a tag `Structure` aparece ou some a até 50 studs, jogando |
| Porta (`door_open`, `door_close`) | Atributo `DoorOpen` |
| Madeira na máquina (`machine_wood`) e coleta (`machine_collect`) | `Wood` sobe; `Stock` cai |
| Baú e caixa: abrir (`chest_open`) e mexer (`chest_item`) | Chegar perto (`ChestState.near`/`CrateState.near`); `ChestCount` muda |
| Pegar item (`pickup`) | Entrou item no inventário (coleta, caixa, baú, extrator) |
| Craft (`craft_start`, `craft_done`) | `CraftState.current` começa; termina no tempo (cancelar não faz som) |
| Largar item (`drop`) | Pedido de largar (`DragState`) |
| Morte (`death`), ressurreição (`resurrect`) | Tela "dead" ou virar fantasma; `GhostUntil` some |
| Subiu de nível (`level_up`) | Fim da contagem na tela de morte |
| Vida baixa (`heartbeat`, em loop) | Vida abaixo de 25% |
| Cliques (`ui_click`, `ui_tab`, `ui_slot`) | `Activated` de qualquer botão; o som sai do nome (`Slot3`, `Cell` → slot; `Tab_x`, `Nav_x`, `Chip_x` → aba) |
| Avisos (`notify_info`, `notify_alert`, `notify_success`) | `Notifications.push`, pelo tipo do aviso |
| Passo na água (`water_step`) | Cada ondinha de `World/WaterRipples` |

Um botão que não deve fazer som recebe o atributo `SemSom = true`.

A peça que aparece ou some só conta como "colocou" ou "quebrou" a até 50 studs. O streaming traz e leva peças a partir de 64 studs, sem ninguém ter construído nada. Nos 3 s depois de nascer também não há som de peça, porque a base em volta chega toda de uma vez.

### Música

O modo vem da tela e da hora (`SoundRules.musicMode`): **menu**, **dia**, **noite** e **morte**. Cada modo sorteia a próxima faixa sem repetir a última. A troca de modo e o fim de cada faixa entram por crossfade de 3 s; dois `Sound` fixos se revezam. A música de noite (e os grilos) começa junto com o aviso "a noite está chegando", 30 s antes de escurecer: o som conta a hora antes da luz. Faixa que não carrega em 10 s é pulada.

### Ambiente

- **Floresta:** pássaros de dia, grilos de noite e vento leve sempre, trocando em 4 s.
- **Água:** o volume sobe conforme o boneco chega perto da beira (a partir de 40 studs).
- **Fogo:** som 3D em loop nas peças com a tag `FireLight` (fogueira e fornalha). Fornalha apagada (`Lit == false`) fica muda.
- **Noite:** de vez em quando, um uivo ou uma coruja ao longe.

## Lista de sons (11/11/2026)

Todos conferidos no Studio (carregam, com a duração abaixo). PSE = ProSoundEffects.

### Efeitos

| Chave | Áudio | Id | Duração |
|---|---|---|---|
| `hit_wood` | PSE, machado na madeira | 9120809592 | 0,5 s |
| `hit_stone` | PSE "Rock Impacts" | 9118622414 | 0,4 s |
| `hit_gold` | PSE, batida em metal | 9125361455 | 0,6 s |
| `hit_diamond` | PSE "Glass Clinks 30" | 9114597147 | 0,75 s |
| `hit_leaves` | PSE, folhas | 9114518386 | 1,3 s |
| `hit_mob` | PSE "Flesh Hits 2" | 9114482141 | 0,76 s |
| `hit_player` | PSE "Boxing Hits 14" | 9113573976 | 0,58 s |
| `hit_structure` | PSE "Wood Pound Dirt Two Wood Poles 1" | 9120950231 | 0,7 s |
| `swing` | PSE "Wood Whoosh Slicing Air Quick Swings 4" | 9120972321 | 0,6 s |
| `pickup` | PSE "Suction Pop 4" | 9119669065 | 0,29 s |
| `drop` | PSE "Dog Food Bag 4" | 9114121520 | 0,38 s |
| `craft_start` | PSE "Gavel Hit Wood Mallet Hit Wood Triple Impact" | 9125574374 | 1,12 s |
| `craft_done` | PSE "Synth Sparkle Tone High Pitch Bell Tone Ding" | 9126073001 | 1,16 s |
| `eat` | PSE "Carrot Break In Half 1" | 9113723854 | 0,89 s |
| `drink` | PSE "Drinking Cu Gulping 2" | 9114171855 | 0,9 s |
| `place` | PSE "Wood Hit Giant Wood Beam Dull Thuds Knocks 1" | 9126267413 | 0,63 s |
| `structure_break` | PSE "Wood Roof Crash 1" | 9120957463 | 2,7 s |
| `door_open` | PSE "Wood Door Creak Squeak 7" | 9120839359 | 1,14 s |
| `door_close` | PSE "Cabinet Doors 6" | 9113656909 | 0,81 s |
| `machine_wood` | PSE "Wood Drop Boards Falling To Floor 46" | 9120857129 | 0,68 s |
| `machine_collect` | PSE "Pebbles Movement 4" | 9117268548 | 0,71 s |
| `chest_open` | PSE "Wood Groan Creak Opening Wood Chest Coffin 9" | 9120881979 | 0,82 s |
| `chest_item` | PSE "Leather Bible 11" | 9116251623 | 0,27 s |
| `hurt` | PSE "Body Hit 11" | 9113487745 | 0,5 s |
| `death` | PSE "Deep Impacts 7" | 9114036511 | 1,3 s |
| `resurrect` | PSE "Magic Glows Soft Clusters Of Chiming Hits 1" | 9116394545 | 1,43 s |
| `level_up` | PSE "Magic Transformation 17" | 9116422213 | 1,61 s |
| `heartbeat` | PSE "Synth Whomps 38" | 9119882039 | 0,94 s |
| `ui_click` | Roblox "Roblox_UI_Bright_Click" | 15675059323 | 0,37 s |
| `ui_tab` | Roblox "Roblox_UI_Paper_Swipe" | 15675037413 | 0,62 s |
| `ui_slot` | Roblox "Roblox_UI_Small_Click" | 15675032796 | 0,13 s |
| `notify_info` | PSE "Electronic Blips Sharp Crystalline Beeps Gat" | 9125530803 | 0,56 s |
| `notify_alert` | Roblox "Roblox GUI - Negative" | 17208353912 | 0,38 s |
| `notify_success` | PSE "Beeps Light Shimmering 5" | 9113397314 | 0,48 s |
| `water_step` | PSE "Puddle Stomps Small Water Splashes 3" | 9117946641 | 0,39 s |
| `mob_attack` (genérico) | PSE "Creature Bite Pterodactyl Crunch Flying Bug" | 9125467298 | 0,48 s |
| `mob_death` (genérico) | PSE "Body Fall Thud 1" | 9113480917 | 0,38 s |
| `mob_wolf_attack` | PSE "Wolf Snorts 6" | 9120792018 | 0,8 s |
| `mob_wolf_death` | PSE "Coyotes Gruff Barking 12" | 9113955748 | 0,42 s |
| `mob_boar_attack` | PSE "Pig Grunts 18" | 9117356889 | 0,69 s |
| `mob_boar_death` | PSE "Pig Squeals 5" | 9117370218 | 0,9 s |
| `mob_spider_attack` | PSE "Creature Vocal Spider Hiss Exhale 2" | 9113990344 | 0,56 s |
| `mob_spider_death` | PSE "Wet Newspaper Slap Hit With Shovel 3" | 9120647258 | 0,38 s |
| `mob_rabbit_hurt` | PSE "Mouse Vocal 3" | 9117006438 | 0,52 s |
| `mob_rabbit_death` | PSE "Mouse Vocal 8" | 9117011106 | 0,3 s |
| `night_howl` | PSE "Wolf Howl Two Versions 2" | 9120790553 | 5,2 s |
| `night_owl` | PSE "Owl Hooting Reverberant Several 1" | 9117181540 | 5,5 s |

### Ambiente (ProSoundEffects, em loop)

| Chave | Áudio | Id | Duração |
|---|---|---|---|
| `day` | "Morning Forest Birds 6" | 9116970949 | 75,2 s |
| `wind` | "Leaves Rustle Wind Blowing Through Trees 2" | 9116258282 | 87,4 s |
| `night` | "Crickets Night 3" | 9112764891 | 63,5 s |
| `water` | "Lake Lap Water Movement 2" | 9116203162 | 45,7 s |
| `fire` | "Fireplace Constant Burning Flame 4" | 9112780462 | 42,8 s |
| `furnace` | "Macho Destructo Fire 2" | 9112825609 | 53,2 s |

### Música (APM Music)

| Modo | Faixa | Id | Duração |
|---|---|---|---|
| Menu | "Maypole Summer (d)" | 1840007392 | 159,8 s |
| Menu | "Free Ride" | 1842361802 | 107,5 s |
| Dia | "Twilight Blue" | 1842361805 | 107,3 s |
| Dia | "Acoustic Pop Guitar" | 9039509587 | 124,7 s |
| Dia | "Ethnic Journeys #8" | 1840356918 | 85,3 s |
| Dia | "Strange Cloud" | 1844433775 | 70,7 s |
| Noite | "Mysterious Night Scene" | 1847342791 | 74,1 s |
| Noite | "Agony Of Uncertainty" | 9038849903 | 138,1 s |
| Noite | "Eerie Night a" | 1841355818 | 109,5 s |
| Morte | "Sad End (Solo Piano)" | 1838635121 | 152,5 s |

Reservas já conferidas, se alguma não agradar: menu "Folk Bonfire (a 60)" 1837999940; noite "Evil Forces A" 9038849759 (mais terror); morte "Sad Piano" 80839256328898 (36,9 s) e "Live Piano Stories 08" 130240227700174; água de riacho "Stream Flow 2" 9119646672; vento puro "Barstow Wind Light Blustery Low Howl 2" 9113286969; fornalha "Lava Fire Deep Rumbling 1" 9112822944; vários lobos "Wolf Howl Bay 1" 9120789309.

## Como testar

- **Testes:** `lune run tests/run` (`tests/soundrules.spec.luau` e `tests/soundconfig.spec.luau`). O segundo avisa se uma chave que o código toca sumir da config.
- **Um id carrega?** No Play, na barra de comandos do cliente: crie um `Sound` com o id em `SoundService` e veja `TimeLength > 0`.
- **No Studio (Play, depois de nascer),** pela barra de comandos do servidor, com `local p = game.Players:GetPlayers()[1]`:
  - `ServerStorage.DevGive:Invoke(p, { wood = 5 })` → pegar item;
  - `ServerStorage.DevHurt:Invoke(p, 10)` → dano; `ServerStorage.DevBar:Invoke(p, "Health", 30)` → batimento;
  - `ServerStorage.DevBar:Invoke(p, "Thirst", 40)` e depois `90` → beber;
  - `ServerStorage.DevPlace:Invoke(p, "campfire")` → colocar e o fogo em loop; `DevPlace` com `wood_door`, `chest`, `stone_extractor` para porta, baú e máquina;
  - `ServerStorage.DevSpawnMob:Invoke(p, "wolf")` e `ServerStorage.DevKillMob:Invoke(p)` → bicho;
  - `workspace:SetAttribute("CycleStart", workspace:GetServerTimeNow() - 250)` → noite (música, grilos, coruja);
  - `ServerStorage.DevEndLife:Invoke(p)` → morte e a música da tela de morte.
- **Ver o que tocou:** os efeitos 2D aparecem por um instante em `SoundService` e os 3D em `Workspace.Terrain` (`Sound_<chave>`). A música são `SoundService.Music1` e `Music2`; o ambiente, `Ambient_<chave>`.
