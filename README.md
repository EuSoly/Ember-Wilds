# Ember Wilds (nome provisório)

Survival multiplayer top-down para Roblox, inspirado no Starve.io. Projeto Rojo em Luau (`--!strict`).

## Pré-requisitos

- [Rokit](https://github.com/rojo-rbx/rokit) instalado. Ele baixa as versões fixadas em `rokit.toml`
  (Rojo, Wally, selene, StyLua, luau-lsp, Blink, Lune).
- Roblox Studio com o plugin do Rojo.
- No Git Bash, os binários do Rokit ficam em `~/.rokit/bin`: `export PATH="$HOME/.rokit/bin:$PATH"`.

## Primeiros passos

```bash
rokit install          # instala as ferramentas do projeto
bash scripts/check.sh  # formatação, lint, build, tipos e testes
rojo serve             # depois conecte pelo plugin do Rojo no Studio
```

Para gerar um place do zero: `rojo build -o starve.rbxlx`.

## Testes

A lógica pura (definições, fórmulas, inventário) é testada fora do Studio com o Lune:

```bash
lune run tests/run
```

Cada arquivo `tests/**/*.spec.luau` devolve uma tabela `{ ["nome do teste"] = function() ... end }`.

## Documentação

- `docs/game-design/` — catálogo e roadmap (N0–N5) e identidade visual.
- `docs/superpowers/specs/` — design do MVP.
- `docs/superpowers/plans/` — planos de implementação por fase.
- `docs/research/` — pesquisas técnicas que embasam as escolhas.
