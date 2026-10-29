# Como rodar o projeto

## Uma vez por máquina

1. Instale o [Rokit](https://github.com/rojo-rbx/rokit).
2. Na raiz do repo: `rokit install` (baixa Rojo 7.7.1, Wally, selene, StyLua, luau-lsp, Blink e Lune nas versões do `rokit.toml`).
3. No Git Bash, coloque as ferramentas no PATH: `export PATH="$HOME/.rokit/bin:$PATH"` (vale pôr no `~/.bashrc`).
4. Instale os pacotes Luau (Vide etc.): `wally install` (o `scripts/check.sh` faz isso sozinho se a pasta `Packages/` não existir).
5. No Studio, instale o plugin do Rojo.

## No dia a dia

```bash
bash scripts/check.sh   # formatação, lint, build, tipos e testes — rode antes de commitar
rojo serve              # sincroniza o código com o Studio
```

No Studio: abra o place de desenvolvimento → plugin Rojo → **Connect**. Cada arquivo salvo aparece no Studio na hora.

Se o StyLua reclamar de formatação, `stylua src tests` corrige sozinho.

O código de rede é gerado pelo Blink a partir de `net/game.blink`: depois de editar o `.blink`, rode `blink net/game` (o `check.sh` também roda). Os arquivos gerados `src/server/Net.luau` e `src/client/Net.luau` são commitados e não devem ser editados à mão.

> Rode os comandos no **Git Bash**. No PowerShell, `bash` abre o WSL (que não tem as ferramentas) e o check falha.

## Configurações que o Rojo não aplica ao vivo (fazer à mão no place)

O `rojo build` grava essas propriedades no arquivo, mas a sincronização ao vivo do plugin pode não aplicá-las num place que já existia. Confira uma vez:

- **Apague o `Baseplate` antigo** do Workspace, se existir. O chão agora é criado pelo `WorldService` com o topo em Y = 0, e o Baseplate antigo fica no mesmo plano: os dois piscam (z-fighting).
- **Workspace → AuthorityMode = Server.** (Obrigatório fazer à mão: o plugin do Rojo não aplica essa propriedade ao vivo — testado.) Isso também liga StreamingEnabled, SignalBehavior Deferred, NextGen Replication, Input Action System e a simulação fixa.
- **Workspace → StreamingEnabled = true**, `StreamOutBehavior = Opportunistic`, `StreamingIntegrityMode = PauseOutsideLoadedArea`, `ModelStreamingBehavior = Improved`.
- **StarterPlayer → CharacterUseJumpPower = false, CharacterJumpHeight = 0, EnableMouseLockOption = false.**
- **StarterPlayer → CreateDefaultPlayerModule = false.** (Obrigatório: sem isso o Roblox usa o PlayerModule padrão, que religa o `AutoRotate` e o boneco não consegue olhar para trás andando. Veja "PlayerModule próprio" em `arquitetura.md`.)
- **Game Settings → Security → Enable Studio Access to API Services** (necessário a partir da Fase 4, para salvar dados).

Depois de mudar, salve e publique o place.

O personagem não usa mais o avatar do Roblox (veja `boneco.md`), então as Avatar Settings da experiência não importam. O corpo do personagem é criado pelo `CharacterService` ao abrir o servidor (`StarterPlayer.StarterCharacter`), e o Rojo coloca `src/character` em `StarterPlayer.StarterCharacterScripts` (scripts `Animate` e `Health` vazios, para o Roblox não pôr os padrões). Se o place tiver um `StarterCharacter` antigo feito à mão, pode apagar: o servidor troca pelo dele.

## Testando como celular

- **Emulador:** aba Test → Device → escolha um celular e gire para paisagem.
- **Latência:** aba Test → Network Simulation (ex.: 150 ms) para ver se a predição do Server Authority continua suave.

## Testes automáticos

A lógica pura roda fora do Studio:

```bash
lune run tests/run
```

Cada `tests/*.spec.luau` devolve `{ ["nome"] = function() ... end }`. Os módulos testados (em `src/shared`) não podem usar `game`, `Instance`, `Color3` etc.: por isso as cores ficam em hex na `Palette` e viram `Color3` no `Theme`.
