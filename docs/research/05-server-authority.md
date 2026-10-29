# Pesquisa 5 — Server Authority (out/2026)

Fontes lidas:
- https://create.roblox.com/docs/projects/server-authority
- https://create.roblox.com/docs/projects/server-authority/techniques
- https://create.roblox.com/docs/reference/engine/classes/RunService#BindToSimulation
- https://create.roblox.com/docs/reference/engine/enums/AuthorityMode.md
- https://devforum.roblox.com/t/full-release-ship-fair-and-competitive-games-with-server-authority/4727993

## Status
- Full release para todos os jogos (anúncio no DevForum). Enum AuthorityMode: Server = 0 (server authority com predição e rollback no cliente); Automatic = 1 (modelo distribuído antigo).
- É opt-in; a própria Roblox diz que não serve para todo jogo.

## O que liga junto
Workspace.AuthorityMode = Server define automaticamente: NextGenerationReplication, PlayerScriptsUseInputActionSystem, SignalBehavior = Deferred, UseFixedSimulation, StreamingEnabled.
- Não verificado: se o Rojo (rbx-dom) consegue setar AuthorityMode via `$properties` no project.json.

## Input e movimento
- Input que afeta a simulação deve vir do Input Action System; não usar UserInputService.InputBegan na simulação.
- InputContext precisa ser descendente do Player (exemplo oficial clona uma pasta de contextos por jogador no servidor).
- Com SA, os PlayerScripts usam BindToSimulation para o movimento do avatar (comentário de staff).
- Não verificado: joystick de UI próprio chamando Humanoid:Move.
- Velocidade customizada: guardar estado em atributo escrito dentro de BindToSimulation e ler na simulação.
- Câmera: sincronização do InputAction de câmera removida; usar Player:GetCameraState().

## BindToSimulation
- RunService:BindToSimulation(fn, frequency = Hz30, priority = 2000).
- Usar time() (sincronizado, passo fixo). tick/os.time/os.clock não são sincronizados nem reexecutam no rollback.
- Pode criar instâncias (Instance.new/Clone) e parentar no mesmo frame.
- NÃO pode: Destroy() nem mudar Parent de instância já no DataModel; EquipTool/UnequipTools. Padrão: marcar intenção em atributo e destruir em RunService.PostSimulation no servidor.
- Efeitos e sons em RenderStepped lendo estado sincronizado (precisam tolerar misprediction).
- Exemplo oficial de entidade sem Humanoid (granada): estado só em atributos (State, Timer) escritos na simulação, render em RenderStepped.

## Limites
- Só replicam atributos entre os 64 primeiros da instância, nome ≤50 chars, string ≤50 chars.
- RemoteEvents não são ordenados com propriedades/atributos (~40–50 ms fora da timeline); sem rewind de hit no servidor ainda.
- Mais uso de CPU no servidor; se o heartbeat do servidor cair abaixo de 59 FPS o jogo degrada (visualizador Ctrl+Shift+F6).
- Animações: máx. 8 tracks ativas por Animator; não cachear AnimationTrack entre frames.
- Predição automática vale para assemblies físicas inteiras (soldadas), dentro do simulation radius.

## Problemas conhecidos
- Clientes mobile/console recebem updates da engine alguns dias depois do desktop e não conectam até atualizar.
- Tools: anúncio diz suportado; doc diz que ainda não totalmente (irrelevante: não usamos Tools).

## Templates oficiais
Racing, Soccer e Laser Tag (Server Authority Templates no Roblox). Laser Tag usa RemoteEvents para os tiros.

## Achados na implementação (F0/F1, 29/10/2026)

- **Rojo 7.7.1** grava `AuthorityMode` (token 0 = Server), `StreamingEnabled`, `SignalBehavior` (como `SignalBehavior2`), `StreamOutBehavior`, `StreamingIntegrityMode` e `ModelStreamingBehavior` pelo `$properties` do Workspace num `rojo build`. Ainda não confirmado se o plugin aplica essas propriedades **ao vivo** num place existente — conferir no Studio.
- **Binding scriptable**: as definições de tipo atuais (luau-lsp 1.70.1) têm `InputBinding.Type = Enum.InputBindingType.Scriptable` e `InputBinding:Fire(state)`; `InputAction:Fire` está marcado como depreciado. Usamos `AimBinding:Fire(Vector2)`.
- **RunService:BindToSimulation(func, frequency: Enum.StepFrequency?, priority: number?)** com `Enum.StepFrequency.Hz60` (há Hz1, Hz5, Hz10, Hz15, Hz30, Hz60).
- **`Humanoid:ApplyDescription` está depreciado** → `ApplyDescriptionAsync`.
- **Pendente de teste no Studio**: rotação do HumanoidRootPart via CFrame dentro da simulação (tremor/correções com latência), thumbstick nativo sob IAS, e se o botão de pulo do celular some com `JumpHeight = 0`.
