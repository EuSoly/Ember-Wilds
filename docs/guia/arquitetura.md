# Arquitetura do código

## Onde fica cada coisa

| Pasta | Vira no Roblox | O que tem |
|---|---|---|
| `src/shared` | `ReplicatedStorage.Shared` | Código e dados usados pelos dois lados |
| `src/shared/Defs` | `Shared.Defs` | Conteúdo do jogo como **dados**: tiers, itens (depois receitas, mobs, biomas…) |
| `src/shared/Simulation` | `Shared.Simulation` | Lógica que roda **dentro da simulação** do Server Authority |
| `src/server` | `ServerScriptService.Server` | Bootstrap do servidor |
| `src/server/Services` | `Server.Services` | Um módulo por sistema do servidor |
| `src/client` | `StarterPlayerScripts.Client` | Bootstrap do cliente |
| `src/client/Controllers` | `Client.Controllers` | Um módulo por sistema do cliente |
| `src/first` | `ReplicatedFirst.First` | Tela de carregamento (Fase 5) |
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
- Ações discretas (coletar, craftar, construir) vão por eventos de rede validados no servidor (Fase 3 em diante).

## Orientação do personagem

`Humanoid.AutoRotate` fica desligado (`CharacterService`). A rotação é feita em `Simulation/FacingSim.luau`:
- com mira (PC): vira para o mouse, mesmo andando para outro lado;
- sem mira (celular, gamepad): vira para onde anda;
- parado e sem mira: mantém.

A matemática está em `src/shared/Facing.luau` e é testada no Lune.

## Interface (HUD)

Feita com Vide em `src/client/UI`. Veja `hud.md`.

## Câmera

`CameraController`: câmera `Scriptable` a 65°, sem girar, distância 34 (zoom entre 28 e 40), seguindo o personagem com suavização. As contas estão em `src/shared/CameraMath.luau`.
