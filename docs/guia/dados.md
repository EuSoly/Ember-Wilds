# Dados salvos

Tudo o que sobrevive à morte fica salvo por jogador num **perfil**: a moeda Golden Ember, as estatísticas, os cosméticos e as configurações. Inventário, base e pontos da partida continuam morrendo com o jogador: **a morte perde tudo** (inventário zerado e mochila tirada, como no Starve).

O perfil usa o [ProfileStore](https://madstudioroblox.github.io/ProfileStore/) (pacote `lm-loleris/profilestore`, instalado pelo Wally em `ServerPackages/`). Ele cuida do **session lock** (dois servidores nunca mexem no mesmo perfil), do autosave e do save ao sair.

O perfil só existe no **servidor**. O cliente lê o que precisa nos atributos do Player (`Currency`, `Setting_<id>`, `Cosmetic_<slot>`) e em duas pastas dentro dele (`ProfileStats`, `OwnedCosmetics`) e só pode **pedir** mudança de configuração ou de skin equipada, que o servidor valida.

## O perfil (schema v1)

| Campo | O que é |
|---|---|
| `SchemaVersion` | Versão do formato (hoje `1`). Veja "Migrações" |
| `Currency` | `{ Balance, HourWindowStart, HourEarned }`: saldo e janela do teto por hora |
| `Cosmetics` | `{ Owned = { [id] = true }, Equipped = { [slot] = id } }` |
| `Stats` | `{ [statId] = número }` ou, nas keyed, `{ [statId] = { [chave] = número } }` |
| `Settings` | `{ [settingId] = número, booleano ou texto }` |
| `Xp` | `{ Seeded, HourWindowStart, HourEarned }`: XP inicial já copiado do total de pontos? e a janela do teto de XP por hora. O XP em si é a estatística `xp_total` |
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
| `src/server/Services/DeathService.luau` | Morte (fim de vida + perde tudo + tela de morte) |
| `src/server/Services/SpawnService.luau` | Nascer a pedido, com kit inicial |
| `src/server/Services/SettingsService.luau` | Configurações (atributos + evento `SetSetting`) |
| `src/server/Services/CosmeticService.luau` | Posse (pasta `OwnedCosmetics`), skin equipada (`Cosmetic_<slot>`) e o pedido `EquipCosmetic` |
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

`DataService.save` grava no máximo uma vez a cada `DataConfig.MIN_SAVE_INTERVAL` segundos (8) por jogador. Um pedido feito durante a espera vira um único save no fim dela, então trocar de skin várias vezes seguidas não estoura os limites.

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
camera_shake = {
	id = "camera_shake",
	nameKey = "setting.camera_shake",
	group = "controls", -- grupo na tela: "sound", "screen" ou "controls"
	order = 7, -- posição na tela de configurações (inteiro ≥ 1, sem repetir)
	kind = "boolean",
	default = true,
},
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

A linha da configuração aparece sozinha na tela de configurações, na posição do `order` (veja `telas.md`, que também diz o que cada configuração já aplica).

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

## Nível e XP

- **XP = pontos de cada vida**, arredondados para baixo, somados em `xp_total` no fim da vida. O nível não é salvo: sai do XP (`src/shared/Data/LevelRules.luau`, teste `tests/levelrules.spec.luau`).
- **Curva:** subir do nível n para n+1 pede `1000 × n` XP (nível 2 = 1.000 no total; 8 = 28.000; 10 = 45.000; 50 = 1.225.000). Sem máximo.
- **Teto: 100.000 XP por hora**, rede de segurança contra trapaça e bug (como o da Golden Ember). A janela fica em `data.Xp` (sair e voltar não zera).
- **Quem já jogou:** na primeira vez que o perfil carrega nesta versão, `xp_total` recebe `score_total` (fica com o maior) e `data.Xp.Seeded` vira `true`. Não subiu a versão do esquema, para servidores antigos abertos durante a atualização não recusarem perfis.
- Para ajustar: `DataConfig.XP_STEP` e `DataConfig.MAX_XP_PER_HOUR`.
- **Passe de batalha (futuro):** escutar `StatsService.onChanged` de `xp_total` (ou o XP do resumo da vida) e somar numa trilha da temporada.

## Cosméticos no cliente

Skins ficam no perfil (`Cosmetics.Owned` e `Cosmetics.Equipped`, veja o schema). O `CosmeticService` publica no **Player**:

- Pasta `Player.OwnedCosmetics`, atributo `<id>` = `true` para cada skin possuída, ao carregar o perfil e a cada skin dada (`grantOwnership`). A skin **padrão** de cada slot conta como possuída sem o atributo. A tela de Cosméticos lê isto para tirar o cadeado.
- `Cosmetic_<slot>` = id da skin equipada (`Cosmetic_body`, `Cosmetic_bag`, `Cosmetic_book`, `Cosmetic_crate`), também no personagem. Os slots estão em `Defs/CosmeticSlots.luau`: `body`, `crate`, `bag` (mochila) e `book` (livro, uma skin só).

O cliente **pede** para equipar pelo evento `EquipCosmetic` (`{ Id }`, em `net/game.blink`). O servidor ignora em silêncio id inexistente, skin não possuída ou pedido a menos de 0,2 s do anterior; se vale, equipa e salva. Como dar uma skin para testar: `DevGrantCosmetic` (abaixo). Como criar skins: `telas.md`, "Adicionar ou mudar uma skin".

## Estatísticas no cliente

O `StatsService` publica cada estatística de `Defs.Stats` no atributo `<id>` da pasta `Player.ProfileStats`, ao carregar o perfil e a cada mudança. Counter e max vão como estão; keyed vai o **total somado** (`StatsRules.total`); o detalhe por chave fica só no servidor.

> **Limite de atributos por instância (~1 KB no total, nomes + valores).** Quando o Player passou do limite (04/11), todo `SetAttribute` **novo** no Player falhava com `Attribute total payload exceeds 1024 bytes`: sumiram os pontos (`Score`), o `Rank`, a sede e o calor, e o mob morto não soltava caixa (o erro do `ScoreService.add` interrompia o `die` antes do aviso de morte). Por isso estatísticas e posse ficam em pastas próprias. Regra: lista que cresce com o conteúdo (uma entrada por estatística, por skin, por conquista...) vai numa pasta, nunca direto no Player.

### Vida e fim de vida

- A vida começa quando o personagem nasce (só a pedido: botão Jogar).
- `LifeService.endLife(player)` é o fim de vida: converte os pontos (`Score`) em Golden Ember e em XP, soma `score_total`, `deaths`, `days_total` e `xp_total`, registra `score_best` e `days_best` (ciclos completos de 480 s vividos), zera os pontos e salva. Devolve o resumo `{ points, days, currency, xp }` (moeda e XP = os concedidos de fato, depois dos tetos), ou `nil` se não havia vida ativa ou perfil.
- `deaths` conta **toda vida terminada** (sair do jogo também). `real_deaths` conta só morte de verdade (somado no `DeathService.kill`) e é o "Mortes" do Perfil.
- Só faz a contabilidade: não limpa o inventário nem faz renascer.

### Morte

`DeathService.kill(player, causeKey)` é a **função única de morte** (as fases G chamam ao matar). Ela:
1. faz o fim de vida (`LifeService.endLife`);
2. guarda os pontos da vida no atributo **`KitPoints`** do Player, para comprar um kit inicial antes de renascer (só em memória: ao sair do jogo, perde; na primeira entrada é 0);
3. zera o inventário e tira a mochila (`InventoryService.reset`);
4. remove o personagem;
5. manda ao jogador o resumo (`Net.LifeEnded`: causa, dias, pontos, moeda) para a tela de morte.

A causa é uma chave de `Strings` (`death.cause.dev`, `death.cause.fall`, `death.cause.unknown`; as fases G adicionam as suas). Uma morte do `Humanoid` que não passou pela função vira `death.cause.unknown`. Cair do mapa (abaixo de `WorldConfig.KILL_Y`, ou o Roblox apagar a raiz do personagem) vira `death.cause.fall`. O renascer é a pedido (`SpawnService`), com o kit escolhido, se os `KitPoints` pagarem. Veja `telas.md`.
- **Uma vez por vida:** morrer e sair, ou sair enquanto o servidor fecha, conta uma vez só. A próxima vida começa no próximo nascimento.
- **Sair do jogo e o servidor fechando contam como fim de vida.**
- `playtime_seconds` é somado a cada save (autosave incluso) e ao sair.

## Comandos de teste (Studio)

O `DevDataService` cria comandos em `ServerStorage` (só no Studio). Use na barra de comandos do **servidor**:

```lua
local SS = game:GetService("ServerStorage")
local player = game.Players:GetPlayers()[1]

SS.DevScore:Invoke(player, 12345) -- pontos da vida atual
SS.DevEndLife:Invoke(player) -- morte de teste (+12 Golden Ember, 12345 KitPoints, tela de morte)
print(SS.DevCurrency:Invoke(player, 100)) -- +100 sem tetos; devolve o saldo
print(SS.DevCurrency:Invoke(player, -30)) -- gasta 30 (não gasta se faltar saldo)
SS.DevStat:Invoke(player, "mobs_killed", 10, "cow") -- soma numa estatística
print(SS.DevGrantCosmetic:Invoke(player, "body_ember")) -- dá a posse da skin
print(SS.DevProfile:Invoke(player)) -- o perfil atual em JSON
SS.DevResetProfile:Invoke(player) -- apaga o perfil de dev e expulsa
```

Para testar os tetos: `DevScore` com 800000 e depois `DevEndLife` dá 300 (com a hora zerada). Repetir na mesma hora dá 0.

Para ver se salva de verdade: com o acesso às APIs ligado, mude moeda, estatística, configuração e skin, pare o teste e dê Play de novo. Confira com `DevProfile`.

> Desde a G2 os pontos são de verdade (coleta, `ScoreService`). Para testar a conversão sem coletar, use `DevScore`.

## GDPR (direito ao esquecimento)

Todo perfil chama `AddUserId(UserId)`, e a chave segue o padrão `Player_<UserId>`. Para a Roblox apagar os dados sozinha quando um jogador pedir:

1. Abra o **Creator Dashboard** → sua experiência → **Data Stores Manager**.
2. Na aba de **deleção (Right to Erasure / RTBF)**, configure o template `Player_{UserId}` para o store `PlayerData` **e também** para o store `Dev_PlayerData`. Os testes no Studio gravam perfis de UserIds reais (os seus e os de quem testa com você) no store de desenvolvimento.

Faça isso uma vez, depois de publicar a experiência com a F4.
