# Como rodar o projeto

## Uma vez por máquina

1. Instale o [Rokit](https://github.com/rojo-rbx/rokit).
2. Na raiz do repo: `rokit install` (baixa Rojo 7.7.1, Wally, selene, StyLua, luau-lsp, Blink e Lune nas versões do `rokit.toml`).
3. No Git Bash, coloque as ferramentas no PATH: `export PATH="$HOME/.rokit/bin:$PATH"` (vale pôr no `~/.bashrc`).
4. No Studio, instale o plugin do Rojo.

## No dia a dia

```bash
bash scripts/check.sh   # formatação, lint, build, tipos e testes — rode antes de commitar
rojo serve              # sincroniza o código com o Studio
```

No Studio: abra o place de desenvolvimento → plugin Rojo → **Connect**. Cada arquivo salvo aparece no Studio na hora.

Se o StyLua reclamar de formatação, `stylua src tests` corrige sozinho.

> Rode os comandos no **Git Bash**. No PowerShell, `bash` abre o WSL (que não tem as ferramentas) e o check falha.

## Configurações que o Rojo não aplica ao vivo (fazer à mão no place)

O `rojo build` grava essas propriedades no arquivo, mas a sincronização ao vivo do plugin pode não aplicá-las num place que já existia. Confira uma vez:

- **Workspace → AuthorityMode = Server.** Isso também liga StreamingEnabled, SignalBehavior Deferred, NextGen Replication, Input Action System e a simulação fixa.
- **Workspace → StreamingEnabled = true**, `StreamOutBehavior = Opportunistic`, `StreamingIntegrityMode = PauseOutsideLoadedArea`, `ModelStreamingBehavior = Improved`.
- **StarterPlayer → CharacterUseJumpPower = false, CharacterJumpHeight = 0, EnableMouseLockOption = false.**
- **Game Settings → Avatar:** preset "Consistent Gameplay" (ou Custom Scale com colisor único). Trava a proporção dos avatares.
- **Game Settings → Security → Enable Studio Access to API Services** (necessário a partir da Fase 4, para salvar dados).

Depois de mudar, salve e publique o place.

## Testando como celular

- **Emulador:** aba Test → Device → escolha um celular e gire para paisagem.
- **Latência:** aba Test → Network Simulation (ex.: 150 ms) para ver se a predição do Server Authority continua suave.

## Testes automáticos

A lógica pura roda fora do Studio:

```bash
lune run tests/run
```

Cada `tests/*.spec.luau` devolve `{ ["nome"] = function() ... end }`. Os módulos testados (em `src/shared`) não podem usar `game`, `Instance`, `Color3` etc.: por isso as cores ficam em hex na `Palette` e viram `Color3` no `Theme`.
