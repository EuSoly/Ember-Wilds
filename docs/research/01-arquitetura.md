# Pesquisa 1 — Arquitetura e ferramentas (out/2026)

[V] verificado (GitHub API 28/10/2026, docs, devforum); [O] opinião.

## Toolchain
- Rokit para fixar ferramentas (rokit.toml). Aftman arquivado [V]. Rojo atual 7.7.1 (02/10/2026) [V].
- Wally para pacotes (padrão de fato; v0.3.2 2023 mas commits out/2026) [V/O]; pesde plano B.
- selene 0.32.0, StyLua 2.6.0, luau-lsp 1.70.1 ativos [V]. New Type Solver GA nov/2025 [V].
- --!strict desde o primeiro arquivo + rojo sourcemap --watch [O].
- Layout: ReplicatedStorage.Shared=src/shared, ReplicatedStorage.Packages=Packages, ServerScriptService.Server=src/server, ServerScriptService.ServerPackages=ServerPackages, StarterPlayerScripts.Client=src/client; Packages no .gitignore; wally-package-types após wally install [O].
- TestEZ arquivado; Jest-Lua 3.10.0 parado desde dez/2024 [V]. Testar só lógica pura com Lune/Jest-Lua mais tarde [O].

## Estrutura
- Sem framework (Knit arquivado [V]). Serviços/controladores = ModuleScripts com Init()/Start(); bootstrap único por lado.
- Defs em src/shared/Defs: Items, Recipes, Mobs, Structures, Biomes; `export type`, table.freeze, IDs string estáveis; agregador valida referências no boot; rede usa IDs compactos u16 derivados [O].

## Rede
- Blink v0.18.9 (set/2026) recomendado; Zap v0.6.29 alternativa [V]. ByteNet parado, Packet com falhas apontadas, Red arquivado [V].
- Servidor decide tudo; Unreliable descarta >~1000 bytes; nunca InvokeClient [V].
- Server Authority nativo em beta instável — não depender no MVP [V/O].
- Estado: barras via Attributes no Player; inventário via snapshot+delta Blink (ou Charm + charm-sync, ativo) [O]. Evitar ValueObjects.

## UI
- Vide 0.4.1 (jul/2026, commit 26/10/2026) recomendado [V/O]. Fusion 0.3-beta parado; react-lua parado desde mai/2025 [V].

## ECS
- Não no MVP. Matter arquivado; jecs ativo mas sem padrão de replicação [V]. Tabelas + CollectionService + grid espacial (célula 4 studs); mobs num loop Heartbeat com IA 5–10 Hz e desligada longe de jogadores [O].

## StreamingEnabled
- ModelStreamingBehavior=Improved, StreamOutBehavior=Opportunistic, StreamingIntegrityMode=PauseOutsideLoadedArea; MinRadius 64 / TargetRadius 1024 padrão [V].
- Cliente orientado a CollectionService added/removed; HUD não depende do Workspace; minimapa com imagem pré-renderizada; recursos Atomic; entidades por ID na rede (Instance ausente chega nil) [V/O].

## Stack
Rokit(rojo 7.7.1, wally, wally-package-types, selene, stylua, luau-lsp) · arquitetura própria Init/Start · Defs tipadas · Blink · Attributes + snapshot/delta · ProfileStore · Vide · sem ECS · Streaming Improved/Opportunistic · testes de lógica pura depois.
