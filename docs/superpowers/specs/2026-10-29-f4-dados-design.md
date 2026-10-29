# Ember Wilds — F4 Dados: perfil salvo, Golden Ember, estatísticas e configurações (design)

Data: 2026-10-29 · Status: revisado por um builder independente; aguardando aprovação final do Elizeu
Base: spec do MVP §7 (`docs/superpowers/specs/2026-10-28-ember-wilds-mvp-design.md`), pesquisa `docs/research/02-dados-monetizacao.md`.

Legenda: **[Elizeu]** decidido por ele · **[spec]** já decidido no spec do MVP · **[Claude]** decisão técnica minha · **[builder]** quem implementa decide.

## 1. Intenção

Tudo o que sobrevive à morte passa a ser salvo por jogador: a moeda, os cosméticos, as configurações e um **histórico rico de estatísticas** [Elizeu], que vai alimentar no futuro **conquistas** e um **sistema de maestria** [Elizeu]. Inventário, base e pontos da partida continuam morrendo com o jogador [spec].

## 2. Objetivos, não-objetivos e anti-objetivos

**Objetivos**
1. Perfil por jogador salvo com segurança (ProfileStore, session lock, autosave), com versão e migrações [spec].
2. Moeda **Golden Ember** [Elizeu]: ganha convertendo os pontos de cada vida, com tetos anti-farm, por uma função única do servidor [spec].
3. Estatísticas permanentes, extensíveis como dados [Elizeu]:
   - jogadores mortos;
   - mobs mortos **por tipo** (ex.: 10 vacas, 11 aranhas);
   - recursos coletados **por recurso**;
   - itens craftados **por item**;
   - pontuação total acumulada e melhor pontuação;
   - mortes, mais dias vivo numa vida, tempo de jogo [spec].
4. Cosméticos possuídos e equipados salvos; a skin do boneco vem do perfil [spec].
5. Configurações salvas (volumes, qualidade, tamanho da UI, canhoto) [spec].
6. Sair do jogo = morte (pontos viram moeda); servidor caindo também converte [spec].
7. Testável no Studio: com acesso às APIs usa um DataStore de desenvolvimento; sem acesso, perfil falso com aviso [spec].

**Não-objetivos (agora)**
- Conquistas e maestria em si (só os contadores e o aviso de mudança ficam prontos).
- Telas de configurações, loja, perfil e ranking (F5); compras com Robux (Developer Products) e caixas.
- Pontuação real, combate, coleta e crafting (fases G) — eles só **chamarão** as funções de estatística/moeda.
- Ranking global (OrderedDataStore) e reconexão com período de graça.

**Anti-objetivos**
- Perder ou duplicar moeda/cosméticos (dois servidores com o mesmo perfil, salvar no meio de uma operação).
- Cliente conseguir mexer em moeda, estatística ou cosmético (só pedir configurações, validadas).
- Precisar mudar o formato do perfil para cada estatística nova de um update.
- Testes no Studio sujando os dados do jogo real.

## 3. Restrições

- ProfileStore oficial (`lm-loleris/profilestore@1.0.3`, realm **server** → `[server-dependencies]` no Wally, pasta `ServerPackages` mapeada no Rojo para `ServerScriptService`) [Claude].
- Server Authority: o perfil só existe no servidor. O cliente recebe o que precisa por **atributos no Player** (que, ao contrário dos do personagem, disparam sinal normalmente) e pede mudanças de configuração por Blink.
- Limites do DataStore (pesquisa 02): salvar no autosave do ProfileStore, ao fim de cada vida, ao trocar cosmético e ao sair; nada de salvar a cada mudança de estatística.
- Strings de atributo ≤ 50 caracteres; IDs string estáveis (vão para o DataStore e nunca mudam de significado).
- GDPR: chave `Player_{UserId}`; nada de nomes ou chat no perfil [spec].

## 4. O perfil (schema v1) [Claude, a partir da pesquisa]

```
SchemaVersion = 1
Currency   = { Balance = 0, HourWindowStart = 0, HourEarned = 0 }
Cosmetics  = { Owned = { [cosmeticId] = true }, Equipped = { [slot] = cosmeticId } }
Stats      = { [statId] = number | { [key] = number } }   -- ver 5
Settings   = { [settingId] = number | boolean | string }   -- ver 7
PurchaseIdCache = {}    -- reservado para as compras (F5/loja), padrão do ProfileStore
```
- **Migrações:** lista ordenada de funções `vN → vN+1` aplicadas antes do `Reconcile()`; a v1 não tem migração, mas o mecanismo existe e é testado.
- **Store:** nome configurável; no Studio, prefixo `Dev_` (ex.: `Dev_PlayerData`), no jogo publicado `PlayerData` [spec].
- **Sem acesso às APIs no Studio:** usa o modo Mock do ProfileStore e avisa no Output (o jogo funciona, nada é salvo).
- **Falha ao abrir o perfil** (fora do Mock): o jogador é expulso com uma mensagem de `Strings` [spec].

## 5. Estatísticas como dados [Elizeu: quais; Claude: como]

`Defs/Stats.luau`, cada estatística com `id`, `nameKey` e `kind`:
- `"counter"` — só soma (ex. `deaths`);
- `"max"` — guarda o maior valor (ex. `score_best`);
- `"keyed"` — um contador por chave (ex. `mobs_killed["cow"]`), com `keyKind` dizendo o que a chave é (`"mob"`, `"item"`) para a validação e para telas futuras.

Lista inicial:

| id | kind | o quê |
|---|---|---|
| `players_killed` | counter | jogadores que você matou |
| `mobs_killed` | keyed (`mob`) | mobs mortos por tipo |
| `resources_gathered` | keyed (`item`) | recursos coletados por item |
| `items_crafted` | keyed (`item`) | itens craftados por item |
| `deaths` | counter | vidas terminadas (inclui sair do jogo) |
| `score_total` | counter | soma da pontuação de todas as vidas |
| `score_best` | max | melhor pontuação numa vida |
| `days_best` | max | mais dias completos vivo numa vida |
| `playtime_seconds` | counter | tempo de jogo (somado ao sair e a cada autosave, pelo tempo desde a última soma) [Claude] |

- Uma função única no servidor soma/registra (`add` para counter/keyed, `record` para max) e emite um aviso `(player, statId, key?, novoValor)` — é nele que as conquistas e a maestria vão se ligar no futuro.
- Chave de keyed: id string ≤ 32 (mesmo limite de item); `mob` ainda não tem Defs (mobs são fase G), então por enquanto a chave de mob só é checada pelo formato.
- Estatística nova num update = 1 entrada em `Defs/Stats` + texto em Strings; perfis antigos ganham o campo vazio sozinhos.

## 6. Golden Ember (moeda) [Elizeu: nome; spec: regras]

- Texto em Strings (`currency.name` = "Golden Ember").
- Uma função única no servidor para **toda** mudança de saldo (ganhar, gastar), com motivo (`reason`) para log; gastar falha se não houver saldo.
- Conversão ao fim de cada vida: `floor(pontos / 1000)`, limitada a **500 por vida** [Elizeu, 29/10].
- **Teto por hora: 300** [Elizeu, 29/10] — rede de segurança contra bugs/exploits, não limite do jogo normal (pontos só nascem jogando, então morrer de propósito não gera moeda). Vale para **todo ganho vindo do jogo** (conversão de vida e futuros prêmios de gameplay); **não** vale para compras com Robux nem para comandos de dev. Janela **fixa**: começa no primeiro ganho, zera 1 h depois (`HourWindowStart`, `HourEarned` no perfil; relógio `os.time()`).
- Números (1000, 500, 300, 3600 s) num módulo de configuração, para ajuste com o jogo no ar.
- O saldo é publicado no atributo `Currency` do Player (a HUD/loja da F5 lê dali).

## 7. Configurações

`Defs/Settings.luau` (cada uma com `id`, `kind`, faixa/opções e padrão) [Claude]:
`music_volume`, `ambient_volume`, `effects_volume` (número 0–1, padrão 0,8); `quality` (`"auto"`, `"low"`, `"medium"`, `"high"`, padrão `"auto"`); `ui_scale` (0,8–1,25, padrão 1); `left_handed` (bool, padrão false).
- O servidor publica cada uma como atributo do Player (`Setting_<id>`); o cliente pede mudança por um evento Blink, o servidor **valida** (id existe, tipo e faixa certos) e grava. A tela que usa isso é da F5; aplicar volume/qualidade de verdade também é F5.

## 8. Vida, morte e saída

- **Vida começa** quando o personagem nasce (guarda o instante).
- **Fim de vida** = uma função única do servidor (as fases G chamam ao morrer; hoje, um comando de dev): lê os pontos (`Score` do Player), converte em Golden Ember, soma `score_total`, registra `score_best` e `days_best`, soma `deaths`, zera os pontos e salva o perfil.
- **Só contabilidade** [Claude]: o fim de vida não limpa inventário/mochila/status nem faz renascer — isso é da morte de verdade (fases G). O comando de dev "terminar vida" chama o fim de vida **e** faz o personagem renascer (`LoadCharacter`), para a próxima vida começar.
- **Uma vez por vida** [Claude]: cada vida tem um estado "ativa/terminada"; terminar uma vida já terminada não faz nada. Ex.: morreu (G chama) e saiu antes de renascer → só conta uma vez; `BindToClose` e `PlayerRemoving` juntos → só uma vez. A próxima vida começa no próximo `CharacterAdded`.
- **Dias vivo** [Claude]: `days_best` = ciclos completos (dia + noite, `DayCycle.DAY_SECONDS + NIGHT_SECONDS` = 480 s) vividos desde o nascimento: `floor(tempoVivo / 480)`. É pessoal, não o "Dia N" do mundo que a HUD mostra.
- **Sair do jogo** = fim de vida antes de fechar o perfil. **Servidor fechando** (`BindToClose`) = fim de vida de todos.
- `playtime_seconds` soma o tempo da sessão ao sair (e no autosave, para não perder em queda).

## 9. Cosméticos salvos

- Os padrões de cada slot contam como possuídos sempre.
- `CosmeticService` passa a ler `Equipped` do perfil quando ele carrega (aplicando no personagem atual) e a gravar ao equipar. Equipar um cosmético não possuído falha.
- Comando de dev para dar um cosmético (posse), para testar antes da loja.

## 10. Ferramentas de teste (Studio)

Comandos de dev no servidor: dar pontos, terminar a vida, dar/tirar Golden Ember, somar estatística, dar cosmético e **apagar o próprio perfil de dev** (só no store `Dev_`). Um jeito de ler o perfil atual no Output.

## 11. Critérios de pronto

1. No place publicado com acesso às APIs: sair e voltar mantém Golden Ember, estatísticas, configurações e skin equipada [spec].
2. Sem acesso às APIs: entra com perfil falso e aviso no Output, sem erro [spec].
3. Terminar a vida com 12.345 pontos dá 12 Golden Ember, `score_total` += 12.345, `deaths` += 1, `score_best` atualizado; os tetos funcionam (vida com 800.000 pontos dá 300 se a hora estava zerada; uma segunda vida igual na mesma hora dá 0; depois de 1 h volta a ganhar).
4. Sair do jogo conta como fim de vida (moeda e estatísticas atualizadas).
5. Pedido de configuração inválido (id inexistente, fora da faixa, tipo errado) é ignorado pelo servidor.
6. Estatística nova = 1 entrada em `Defs/Stats` + texto; o perfil antigo ganha o campo sem migração.
7. `check.sh` verde; testes Lune para conversão de moeda (tetos e janela), aplicação de estatísticas, validação de configurações, migrações e validação das novas Defs.
8. Docs: `docs/guia/dados.md` (perfil, como adicionar estatística/configuração, comandos de dev, GDPR/template de deleção) e `arquitetura.md`.

## 12. Deixado para o builder

- Nomes de módulos/serviços e a divisão entre eles (seguindo `Services/` + módulos puros em `shared`).
- Formato exato do evento Blink de configuração (desde que validado no servidor).
- Onde guardar o instante de início da vida e como medir o tempo de sessão.
