# Dados salvos

Tudo o que sobrevive à morte fica salvo por jogador num **perfil**: a moeda Golden Ember, as estatísticas, os cosméticos e as configurações. Inventário, base e pontos da partida continuam morrendo com o jogador.

O perfil usa o [ProfileStore](https://madstudioroblox.github.io/ProfileStore/) (pacote `lm-loleris/profilestore`, instalado pelo Wally em `ServerPackages/`). Ele cuida do **session lock** (dois servidores nunca mexem no mesmo perfil), do autosave e do save ao sair.

O perfil só existe no **servidor**. O cliente lê o que precisa nos atributos do Player (`Currency`, `Setting_<id>`) e só pode **pedir** mudança de configuração, que o servidor valida.

## O perfil (schema v1)

| Campo | O que é |
|---|---|
| `SchemaVersion` | Versão do formato (hoje `1`). Veja "Migrações" |
| `Currency` | `{ Balance, HourWindowStart, HourEarned }`: saldo e janela do teto por hora |
| `Cosmetics` | `{ Owned = { [id] = true }, Equipped = { [slot] = id } }` |
| `Stats` | `{ [statId] = número }` ou, nas keyed, `{ [statId] = { [chave] = número } }` |
| `Settings` | `{ [settingId] = número, booleano ou texto }` |
| `PurchaseIdCache` | Reservado para as compras com Robux (F5) |

O template fica em `src/shared/Data/ProfileTemplate.luau`. Nada de nomes ou chat no perfil (GDPR).

## Onde ficam os dados

- **Chave:** `Player_<UserId>` (ex. `Player_123456`).
- **Store:** `PlayerData` no jogo publicado. **No Studio** é `Dev_PlayerData`, então testes nunca sujam os dados reais. Os nomes ficam em `src/shared/Data/DataConfig.luau`.
- **Sem acesso às APIs no Studio:** o ProfileStore usa um perfil falso e aparece um aviso no Output. O jogo funciona, mas **nada é salvo**. Para salvar, ligue *Game Settings → Security → Enable Studio Access to API Services* (o place precisa estar publicado).
- **Falha ao carregar:** o jogador é expulso com uma mensagem de `Strings` (`data.loadFailed`). Se outro servidor tomar a sessão, a mensagem é `data.sessionTaken`.

## Onde fica cada coisa

| Arquivo | O que é |
|---|---|
| `src/shared/Data/DataConfig.luau` | Todos os números: store, versão, tetos da moeda |
| `src/shared/Data/CurrencyRules.luau` | Conversão de pontos e tetos (testado em `tests/currency.spec.luau`) |
| `src/shared/Data/StatsRules.luau` | Soma e registro de estatísticas (`tests/stats.spec.luau`) |
| `src/shared/Data/SettingsRules.luau` | Validação das configurações (`tests/settings.spec.luau`) |
| `src/shared/Data/LifeRules.luau` | "Uma vez por vida" e dias vividos (`tests/life.spec.luau`) |
| `src/shared/Data/Migrations.luau` | Migrações do perfil (`tests/migrations.spec.luau`) |
| `src/shared/Defs/Stats.luau`, `Settings.luau` | Estatísticas e configurações como dados |
| `src/server/Services/DataService.luau` | Abre e fecha o perfil; avisa `onLoaded`, `onBeforeSave` e `onUnloading` |
| `src/server/Services/CurrencyService.luau` | Função única para mudar o saldo |
| `src/server/Services/StatsService.luau` | Função única para estatísticas + tempo de jogo |
| `src/server/Services/LifeService.luau` | Fim de vida (pontos → moeda e estatísticas) |
| `src/server/Services/SettingsService.luau` | Configurações (atributos + evento `SetSetting`) |
| `src/server/Services/CosmeticService.luau` | Posse e skin equipada |
| `src/server/Services/DevDataService.luau` | Comandos de teste (só no Studio) |

## Adicionar uma estatística

1. Uma entrada em `src/shared/Defs/Stats.luau`. Exemplo pensando na maestria: mobs mortos **por arma**, com a chave sendo o id do item:

```lua
mobs_killed_by_weapon = {
	id = "mobs_killed_by_weapon",
	nameKey = "stat.mobs_killed_by_weapon",
	kind = "keyed",
	keyKind = "item",
},
```

2. O texto em `src/shared/Strings/ptBR.luau`: `["stat.mobs_killed_by_weapon"] = "Abates por arma",`.

3. Quem conta chama o `StatsService` (ex. o combate, na fase G):

```lua
StatsService.add(player, "mobs_killed_by_weapon", 1, "wood_sword")
```

Pronto. **Não precisa de migração:** a tabela da estatística nasce na primeira soma, e perfis antigos ganham o campo sozinhos.

| `kind` | Para quê | Função |
|---|---|---|
| `"counter"` | só soma (ex. `deaths`) | `StatsService.add(player, id, quantidade)` |
| `"max"` | guarda o maior (ex. `score_best`) | `StatsService.record(player, id, valor)` |
| `"keyed"` | um contador por chave (ex. `mobs_killed["cow"]`); precisa de `keyKind` `"mob"` ou `"item"` | `StatsService.add(player, id, quantidade, chave)` |

Regras: ids e chaves em `snake_case`, até 32 caracteres. A quantidade precisa ser finita e maior que 0 (pode ser fracionária, ex. segundos). Estatística desconhecida ou valor inválido geram um `warn` e são ignorados. Os ids vão para o DataStore: **nunca mude o significado de um id existente**.

Estatísticas não são salvas a cada mudança (limites do DataStore). Quem salva é o autosave, o fim de vida e a saída.

### Aviso de mudança (conquistas e maestria)

`StatsService.onChanged` avisa toda vez que um valor muda de fato. É aqui que as conquistas e a maestria vão se ligar:

```lua
StatsService.onChanged(function(player, statId, key, value)
	if statId == "mobs_killed" and key == "cow" and value >= 100 then
		-- liberar conquista "Fazendeiro"
	end
end)
```

## Adicionar uma configuração

1. Uma entrada em `src/shared/Defs/Settings.luau`:

```lua
camera_shake = { id = "camera_shake", nameKey = "setting.camera_shake", kind = "boolean", default = true },
```

2. O texto em `Strings/ptBR.luau`: `["setting.camera_shake"] = "Tremor da câmera",`.

| `kind` | Campos obrigatórios | Campo lido no `SetSetting` |
|---|---|---|
| `"number"` | `min`, `max`, `default` entre eles | `Number` |
| `"boolean"` | `default` booleano | `Flag` |
| `"choice"` | `options` (sem repetidos, cada uma com até 16 caracteres), `default` entre elas | `Choice` |

O servidor publica cada configuração como atributo `Setting_<id>` no Player. O cliente pede mudança com:

```lua
Net.SetSetting.Fire({ Id = "music_volume", Number = 0.5 })
```

Pedido inválido (id inexistente, fora da faixa, tipo trocado, opção inexistente) é **ignorado em silêncio**, sem `warn`, para um cliente malicioso não encher o Output. Se a faixa de uma configuração mudar num update, o valor salvo que ficou inválido volta para o padrão quando o jogador entra.

A tela de configurações e o efeito de verdade (volume, qualidade) são da F5.

## Migrações (quando o formato do perfil muda)

Estatística ou configuração nova **não** precisa de migração. Migração é para quando um campo existente muda de forma, é renomeado ou precisa ser calculado a partir de outro.

Exemplo v1 → v2 (os cosméticos possuídos passam a guardar a data da compra):

1. Em `src/shared/Data/DataConfig.luau`: `SCHEMA_VERSION = 2`.
2. Em `src/shared/Data/Migrations.luau`, adicione o passo `[1]` (leva da v1 para a v2):

```lua
Migrations.STEPS = table.freeze({
	[1] = function(data)
		local owned = {}
		for id in data.Cosmetics.Owned do
			owned[id] = { at = 0 }
		end
		data.Cosmetics.Owned = owned
	end,
}) :: { [number]: Step }
```

3. Atualize o template (`ProfileTemplate.luau`) e o código que lê o campo para o formato novo, e escreva um teste em `tests/migrations.spec.luau`.

Como funciona: ao abrir o perfil, os passos que faltam rodam em ordem **antes** do `Reconcile()`, numa cópia. Se faltar um passo, nada muda e o jogador é expulso. Um perfil salvo por uma versão **mais nova** do jogo (um servidor antigo abrindo um perfil já migrado) também não é alterado, e o jogador é expulso com `data.newerVersion` para entrar num servidor atualizado.

## Golden Ember (moeda)

- **Fim de vida:** `floor(pontos / 1000)`, no máximo **500 por vida**.
- **Teto por hora: 300.** É uma rede de segurança contra bugs e exploits, não um limite do jogo normal. A janela é fixa: começa no primeiro ganho e zera 1 h depois (`os.time()`). Vale para todo ganho vindo do jogo (`earnFromGameplay`), **não** para compras nem comandos de dev (`grant`).
- Para ajustar, mexa nos números de `DataConfig` (`POINTS_PER_CURRENCY`, `MAX_CURRENCY_PER_LIFE`, `MAX_CURRENCY_PER_HOUR`, `HOUR_SECONDS`).
- Toda mudança de saldo passa pelo `CurrencyService` (`earnFromGameplay`, `grant`, `spend`, sempre com um `reason`, que aparece no Output do Studio). O saldo vai para o atributo `Currency` do Player.

### Vida e fim de vida

- A vida começa quando o personagem nasce.
- `LifeService.endLife(player)` é o fim de vida: converte os pontos (`Score`), soma `score_total` e `deaths`, registra `score_best` e `days_best` (ciclos completos de 480 s vividos), zera os pontos e salva. As fases G chamam essa função ao morrer.
- Só faz a contabilidade: não limpa o inventário nem faz renascer.
- **Uma vez por vida:** morrer e sair, ou sair enquanto o servidor fecha, conta uma vez só. A próxima vida começa no próximo nascimento.
- **Sair do jogo e o servidor fechando contam como fim de vida.**
- `playtime_seconds` é somado a cada save (autosave incluso) e ao sair.

## Comandos de teste (Studio)

O `DevDataService` cria comandos em `ServerStorage` (só no Studio). Use na barra de comandos do **servidor**:

```lua
local SS = game:GetService("ServerStorage")
local player = game.Players:GetPlayers()[1]

SS.DevScore:Invoke(player, 12345) -- pontos da vida atual
SS.DevEndLife:Invoke(player) -- fim de vida (+12 Golden Ember) e renasce
print(SS.DevCurrency:Invoke(player, 100)) -- +100 sem tetos; devolve o saldo
print(SS.DevCurrency:Invoke(player, -30)) -- gasta 30 (não gasta se faltar saldo)
SS.DevStat:Invoke(player, "mobs_killed", 10, "cow") -- soma numa estatística
print(SS.DevGrantCosmetic:Invoke(player, "body_ember")) -- dá a posse da skin
print(SS.DevProfile:Invoke(player)) -- o perfil atual em JSON
SS.DevResetProfile:Invoke(player) -- apaga o perfil de dev e expulsa
```

Para testar os tetos: `DevScore` com 800000 e depois `DevEndLife` dá 300 (com a hora zerada). Repetir na mesma hora dá 0.

Para ver se salva de verdade: com o acesso às APIs ligado, mude moeda, estatística, configuração e skin, pare o teste e dê Play de novo. Confira com `DevProfile`.

> O `DevStatsService` (valores falsos do HUD) põe 1240 pontos em todo jogador que entra. Por isso, sair sem usar `DevScore` também converte esses pontos (1 Golden Ember).

## GDPR (direito ao esquecimento)

Todo perfil chama `AddUserId(UserId)`, e a chave segue o padrão `Player_<UserId>`. Para a Roblox apagar os dados sozinha quando um jogador pedir:

1. Abra o **Creator Dashboard** → sua experiência → **Data Stores Manager**.
2. Na aba de **deleção (Right to Erasure / RTBF)**, configure o template `Player_{UserId}` para o store `PlayerData`.

Faça isso uma vez, depois de publicar a experiência com a F4.
