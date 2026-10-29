# Pesquisa 3 — Visual do cliente (out/2026)

[V] = verificado em fonte; [O] = opinião do pesquisador.

## Câmera
- Scriptable + BindToRenderStep(Camera.Value + 1) [V]; CFrame.lookAt com pitch ~65°, lerp exponencial, zoom 28–40 [O].
- Oclusão: raycast/GetPartsObscuringTarget + LocalTransparencyModifier ~0,6 só em tag "Occluder" [V comunidade]. Invisicam descartado (sem filtro, força 0,75) [V].
- Movimento: câmera não gira → converter joystick e Humanoid:Move(dir, false) [O].

## Input
- IAS lançado 11/06/2026; ContextActionService será descontinuado; UIS continua [V].
- Ações IAS com bindings teclado/gamepad/toque; InputBinding.UIButton para botão de toque; desde fev/2026 cada binding escuta uma única fonte [V].
- GuiService.TouchControlsEnabled = false esconde thumbstick/pulo [V]; joystick próprio + Humanoid:Move. Pulo: JumpHeight 0 no servidor [O].
- Workspace.PlayerScriptsUseInputActionSystem: deixar desligado no início [O] (muda PlayerModule, GetControls removido) [V].
- UserInputService.PreferredInput + GetPropertyChangedSignal para trocar layout [V].
- Mira: mouse no PC (raycast no plano do chão); auto-alvo em cone ~90° no celular; servidor valida [O].

## Inventário/hotbar
- SetCoreGuiEnabled Backpack e Health false, em pcall com retry [V/O].
- Sem Tools: inventário é tabela no servidor, cliente redesenha; item equipado = modelo visual soldado na mão (RigidConstraint/Motor6D) [O; comunidade V].
- Celular: toque longo 0,25 s para arrastar, ou toque-origem/toque-destino no MVP [O].
- Ícones: ImageLabel com spritesheet (ImageRectOffset/Size); ViewportFrame por slot descartado [O].

## Escala / safe area
- ScreenInsets = CoreUISafeInsets no HUD interativo; None nos fundos; SafeAreaCompatibility legado [V].
- TopBar nova ~58 px (GuiService.TopbarInset), vem zerado no 1º frame → escutar mudança [V].
- Fontes LuckiestGuy, FredokaOne, BuilderSans existem em Enum.Font; usar FontFace / Font.fromEnum [V].

## Menu e loading
- LocalScript em ReplicatedFirst, RemoveDefaultLoadingScreen, esperar game.Loaded [V].
- PreloadAsync só imagens do loading/menu [V].
- CharacterAutoLoads = false; câmera de menu; "Jogar" → RemoteEvent → servidor aplica HumanoidDescription e LoadCharacter [O].
- Com StreamingEnabled, RequestStreamAroundAsync na área de spawn [O].

## Dia/noite
- Servidor guarda instante de início em atributo; cliente calcula ClockTime via workspace:GetServerTimeNow() [V comunidade].
- ColorCorrection/Atmosphere/Ambient interpolados no cliente; biomas com Tween 2 s [O].
- Future 100% no Android, cai sozinho em aparelho fraco [V]; PointLight com sombra é cara [V]; fogueira com Shadows = false [O].

## Avatar R15 travado
- Avatar Settings (jul/2025): Custom Scale + Custom Build; Movement Single Collider; preset "Consistent Gameplay"; acessórios com Custom Limit [V].
- Defesa extra no servidor: CharacterAppearanceLoaded → reaplicar escalas [O]. Bug do GetAppliedDescription corrigido 11/08/2025 [V].
- Hitbox de combate por cálculo próprio no servidor, não pelas peças do avatar [O].

## Ordem sugerida
1. Theme, Juice, ScreenGui principal, desligar CoreGui
2. Câmera top-down
3. Input IAS + joystick próprio + PreferredInput
4. HUD estático com dados falsos
5. Inventário servidor + grade 4x4 + item na mão
6. Loading e menu, fluxo Jogar
7. Dia/noite
8. Telas secundárias + fade de oclusão

Fontes: create.roblox.com/docs (input-action-system, disable-ui, loading-screens, ScreenGui, avatar-settings), devforum (IAS release 3890979, migração PlayerModule 4681909, TopBar 3248916, Future Android 3235808, Avatar Settings 3828640).
