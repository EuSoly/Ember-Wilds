# Arquitetura do código

## Onde fica cada coisa

| Pasta | Vira no Roblox | O que tem |
|---|---|---|
| `src/shared` | `ReplicatedStorage.Shared` | Código e dados usados pelos dois lados |
| `src/shared/Defs` | `Shared.Defs` | Conteúdo do jogo como **dados**: tiers, itens (depois receitas, mobs, biomas…) |
| `src/shared/Craft` | `Shared.Craft` | Regras puras de craft: materiais, estação, espaço, duração e progresso |
| `src/shared/Simulation` | `Shared.Simulation` | Lógica que roda **dentro da simulação** do Server Authority |
| `src/shared/Models` | `Shared.Models` | Modelos montados por código (ferramenta na mão, corpo do personagem) |
| `src/shared/Data` | `Shared.Data` | Regras puras dos dados salvos (moeda, estatísticas, configurações, migrações) |
| `src/shared/World` | `Shared.World` | Formas do mapa vistas de cima, espalhador de recursos (puros) e leitura das peças do mapa |
| `src/shared/UIFlow` | `Shared.UIFlow` | Regras puras das telas: estados, compra de kit, contagem pontos→moeda, formato das configurações |
| `assets/ui` | `ReplicatedStorage.UITemplates` | Moldes das telas (instâncias em arquivo, sem scripts) |
| `net/game.blink` | — | Contrato de rede; gera `src/server/Net.luau` e `src/client/Net.luau` |
| `src/server` | `ServerScriptService.Server` | Bootstrap do servidor |
| `src/server/Services` | `Server.Services` | Um módulo por sistema do servidor |
| `ServerPackages` | `ServerScriptService.ServerPackages` | Pacotes do Wally só do servidor (ProfileStore); criado pelo `wally install` |
| `src/client` | `StarterPlayerScripts.Client` | Bootstrap do cliente |
| `src/client/Controllers` | `Client.Controllers` | Um módulo por sistema do cliente |
| `src/client/Boneco` | `Client.Boneco` | Boneco visual (montagem e renderer); quem liga é o `BonecoController` |
| `src/client/Screens` | `Client.Screens` | Telas de molde (menu, morte, configurações, lista de kits); quem liga é o `ScreenController` |
| `src/client/World` | `Client.World` | Efeitos do mundo no cliente: bolha de ar, copas transparentes, aviso de borda; quem liga é o `WorldFxController` |
| `src/client/UITemplates` | `Client.UITemplates` | `Template.luau`: liga os moldes ao código pelos nomes |
| `src/character` | `StarterPlayer.StarterCharacterScripts` | `Animate` e `Health` vazios (para o Roblox não pôr os padrões) |
| `src/first` | `ReplicatedFirst.First` | Tela de carregamento (script + molde; roda antes de tudo) |
| `map.project.json` + `map/` | — | Só para o backup do mapa com `rojo syncback` (o `rojo serve` não usa) |
| `tests` | — | Testes do Lune |

## Ciclo de vida: Init e Start

Cada arquivo em `Services/` (servidor) ou `Controllers/` (cliente) é um módulo com `Init` e/ou `Start`:

```lua
local MeuService = {}

function MeuService.Init(_self)
	-- cria estado e instâncias; não use outros serviços aqui
end

function MeuService.Start(_self)
	-- liga conexões; aqui já pode usar outros serviços
end

return MeuService
```

O bootstrap (`init.server.luau` / `init.client.luau`) carrega todos em ordem alfabética, chama **todos os `Init`** e depois **todos os `Start`** (`src/shared/Lifecycle.luau`). Para criar um sistema novo, basta criar o arquivo na pasta.

Regras:
- `Start` é curto e síncrono. Quem precisa esperar algo (`WaitForChild`) ou rodar em loop usa `task.spawn`.
- Ao tratar jogadores, conecte `PlayerAdded` **e** percorra `Players:GetPlayers()`: no Play Solo o jogador pode entrar antes do `Start`.

## Dados, cores e textos

- **Defs** (`src/shared/Defs`): tabelas congeladas com ids em `snake_case`. A validação roda no boot. Veja `adicionar-item.md`.
- **Palette** (`src/shared/Palette.luau`): todas as cores do jogo em hex. É a única fonte de cor.
- **Theme** (`src/shared/Theme.luau`): a Palette em `Color3`, mais as fontes e medidas da UI. A interface usa só o Theme.
- **Strings** (`src/shared/Strings`): todo texto exibido. `Strings.get("tier.gold") → "Ouro"`.

## Server Authority: regras do projeto

O jogo roda com `Workspace.AuthorityMode = Server`. O servidor é a fonte da verdade e o cliente prevê o próprio personagem.

- **Input que muda a simulação vem de InputAction.** O servidor cria o contexto `Gameplay` dentro de cada Player (`InputContextService`) com as ações `Aim` (mira), `Use` (bater), `Backpack` (mochila) e `Slot1`…`Slot10`; os nomes ficam em `src/shared/InputNames.luau`. O cliente só alimenta os valores (ex.: `AimController` e o joystick direito disparam a `AimBinding`).
- **Código de simulação** fica em `src/shared/Simulation` e é ligado dos dois lados: `SimulationService` (servidor, todos os jogadores) e `SimulationController` (cliente, só o próprio personagem). Mesma função nos dois lados, então o resultado bate.
- Dentro de `BindToSimulation`:
  - use `time()` para tempo (não `tick`/`os.clock`);
  - **não** use `Destroy()` nem troque `Parent` de algo que já existe — marque num atributo e remova em `RunService.PostSimulation` no servidor;
  - efeitos visuais e sons ficam fora, em `RenderStepped`.
- Atributos replicados: no máximo 64 por instância, strings de até 50 caracteres.
- **No cliente, estado do personagem vindo do servidor é lido por polling, não por sinal de atributo.** Com Server Authority o personagem do jogador local é previsto, e `GetAttributeChangedSignal` não dispara para ele quando o valor chega do servidor (verificado no Studio: o valor chega, o sinal não). Leia o atributo a cada quadro e compare com o último valor (ex.: `syncAttributes` em `BonecoRenderer`). Sinais de vida da instância (`Destroying`, `AncestryChanged`) funcionam normalmente.
- Ações discretas (mover item, selecionar slot; depois coletar, craftar, construir) vão por eventos de rede validados no servidor. Veja "Rede (Blink)" abaixo.

## Rede (Blink)

Os eventos de rede são declarados em `net/game.blink`. O [Blink](https://github.com/1Axen/blink) gera `src/server/Net.luau` e `src/client/Net.luau` (rode `bash scripts/check.sh` ou `blink net/game`). Esses arquivos vão para o commit, mas não passam por StyLua nem selene.

- O Blink serializa em buffer e **valida tipos e faixas** do que chega do cliente. Regras de jogo (capacidade, slot vazio etc.) continuam sendo checadas no serviço.
- Uso: `Net.MoveSlot.Fire(de, para)` no cliente e `Net.MoveSlot.On(function(player, de, para) ... end)` no servidor.
- O cliente liga os ouvintes **antes** de pedir dados (ex.: `RequestInventory`), para a resposta não se perder.

O primeiro sistema que usa a rede é o inventário: veja `inventario.md`.

## Orientação do personagem

`Humanoid.AutoRotate` fica desligado (`CharacterService`). A rotação é feita em `Simulation/FacingSim.luau`:
- com mira (PC): vira para o mouse, mesmo andando para outro lado;
- sem mira (celular, gamepad): vira para onde anda;
- parado e sem mira: mantém.

A matemática está em `src/shared/Facing.luau` e é testada no Lune.

### PlayerModule próprio (`vendor/PlayerModule.rbxmx`)

Com Server Authority, o `PlayerModule` padrão do Roblox religa `Humanoid.AutoRotate` **a cada passo da simulação** (servidor e cliente). Andando, o Humanoid girava o corpo para o movimento e brigava com a mira: o boneco travava de lado e não conseguia olhar para trás. Desligar no nosso código não resolve, porque a ordem entre a nossa simulação e a do Roblox não é garantida (no servidor o Roblox escrevia por último).

Solução (a oficial, segundo a equipe do Roblox no [DevForum](https://devforum.roblox.com/t/unable-to-modify-the-playermodule-when-server-authority-is-enabled/4698731)):
- uma cópia do `PlayerModule` fica em `vendor/PlayerModule.rbxmx` e o Rojo a coloca em `StarterPlayer.PlayerModule`;
- `StarterPlayer.CreateDefaultPlayerModule = false` (está no `default.project.json`, mas o Rojo **não aplica ao vivo**: em place novo, marque à mão no Studio, como o `AuthorityMode`);
- na cópia, as 3 linhas que religavam o `AutoRotate` viraram um comentário `-- EMBER WILDS: ...` (procure por esse texto).

A cópia **não recebe atualizações do Roblox**. Para atualizar: com o jogo rodando e `CreateDefaultPlayerModule` ligado, visão **Server**, botão direito em `StarterPlayer.PlayerModule` → *Save to File* (`.rbxmx`), e refaça as 3 trocas `EMBER WILDS`. O arquivo é código do Roblox: não passa por StyLua nem selene.

## Boneco

O personagem é um corpo simulado mínimo e invisível (`Humanoid` + `HumanoidRootPart` + `Head` invisível), igual para todos e marcado com a tag `Boneco`. Cada cliente monta um boneco visual **só local** para cada personagem com essa tag e o faz seguir, animar e mudar de expressão a partir dos atributos `Using`, `Equipped`, `HurtAt` e `Cosmetic_body`. Skins e expressões são dados em `Defs`. Veja `boneco.md`.

## Dados salvos

O que sobrevive à morte (Golden Ember, estatísticas, cosméticos, configurações) fica num perfil por jogador, salvo com o ProfileStore. O `DataService` abre e fecha o perfil e avisa quando ele carregou (`onLoaded`), antes de cada save (`onBeforeSave`) e antes do último save (`onUnloading`). Serviços pequenos usam esses avisos: `CurrencyService`, `StatsService`, `LifeService`, `SettingsService` e `CosmeticService`. As regras ficam em módulos puros em `src/shared/Data`, testados no Lune. O cliente só lê atributos do Player (`Currency`, `Setting_<id>`, `DataReady`, `KitPoints`). Veja `dados.md`.

## Interface (HUD)

Feita com Vide em `src/client/UI`. Só aparece jogando. Veja `hud.md`.

## Telas e moldes

Carregamento, menu, morte e configurações são **moldes**: instâncias em arquivo (`assets/ui`, no jogo `ReplicatedStorage.UITemplates`) que o código clona e liga pelos **nomes** dos elementos (`UITemplates/Template.luau`). O visual pode ser trocado no Studio ou vindo do Figma sem mexer em código. Elemento faltando gera um `warn` com molde e nome, e o resto funciona. Textos vêm do atributo `TextKey`; animações, feedback dos botões e tamanho da interface ficam no código.

Um único estado de tela no cliente (`ScreenState`: `loading` → `menu` → `playing` → `dead`) decide o que aparece; as transições ficam em `Shared/UIFlow/ScreenFlow.luau`.

No servidor:
- o personagem só nasce a pedido (`Players.CharacterAutoLoads = false`, `SpawnService` + evento `RequestSpawn`), com kit inicial opcional pago com os pontos da última vida;
- toda morte passa pelo `DeathService.kill` (fim de vida, inventário zerado, personagem removido, evento `LifeEnded` com o resumo);
- quem está sem personagem "assiste" um jogador vivo (`SpectateService`, atributo `SpectateTarget`).

Veja `telas.md`.

## Mundo e mapa

O mapa é desenhado à mão no Studio (`Workspace.Map`, fora do Rojo) e o `MapService` espalha os recursos por zona com semente fixa (mesmas posições em toda partida). A geometria e o espalhador são puros e testados (`Shared/World`). A água deixa lento **dentro da simulação** (`Simulation/WaterSim.luau`, dos dois lados, como o `FacingSim`); o fôlego e o "na água" são atributos do Player (`WaterService`). Iluminação de dia e noite, bolha de ar, copas transparentes e aviso de borda são do cliente. Veja `mapa.md`.

**Sobrevivência (G1):** o `SurvivalService` é o dono das barras (`Health`, `Hunger`, `Cold` + `Heat` por cima, `Thirst`); as regras são puras e testadas (`Shared/Survival`), os números ficam em `SurvivalConfig`. **Todo dano** passa por `CharacterService.hurt(character, quantidade, causa, tipo)` (`"combat"` sofre a defesa da armadura; `"survival"` não), e vida zerada chama `DeathService.kill` com a causa. Veja `sobrevivencia.md`.

**Coleta (G2):** o `MapService` registra cada recurso montado no `ResourceService` (reserva nos atributos `Amount`/`AmountMax`, grade espacial, regeneração); o `GatherService` faz o golpe; o `ScoreService` é o dono de `Score` e `Rank`. O cliente só mostra: tranco, lasquinhas e som via `Net.ResourceHit`, avisos via `Net.GatherNotice`, frutinhas pelo atributo `Amount`. Veja `coleta.md`.

**Crafting (G3):** `Defs/Recipes` contém as receitas e `Shared/Craft/CraftRules` concentra as regras puras. No servidor, `CraftService` valida e cobra materiais, acompanha o tempo e entrega ou devolve o resultado; `WearService` equipa armaduras e mochilas. Estações usam a tag `CraftStation` e o atributo `Station`. O cliente só pede ações pela rede e mostra a coluna, o livro e o progresso (`CraftBubble`). Veja `crafting.md`.

**Regra:** o `WaterSim` é o dono de `Humanoid.WalkSpeed` (escreve a cada passo da simulação). Qualquer outro modificador de velocidade no futuro (armas na mão, frio, montaria) tem de entrar **na simulação**, junto dele, senão é sobrescrito.

## Câmera

`CameraController`: câmera `Scriptable` a 65°, sem girar, distância 34 (zoom entre 28 e 40), seguindo o personagem com suavização. Sem personagem (menu e morte), segue o jogador do `SpectateTarget` um pouco mais alto ou, sem ninguém vivo, gira devagar sobre o centro da floresta (`WorldConfig.SPAWN`). No Studio, **Shift + P** liga a câmera livre do Roblox e pausa esta. As contas estão em `src/shared/CameraMath.luau`.
