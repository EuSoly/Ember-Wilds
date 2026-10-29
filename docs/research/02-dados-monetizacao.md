# Pesquisa 2 — Persistência e monetização (out/2026)

[V] verificado; [O] opinião.

## Biblioteca
- ProfileStore (loleris, sucessor do ProfileService, out/2024): session lock, Reconcile, MessageAsync, autosave 300 s, BindToClose, Mock. Último commit de código 2025-03, merge 2025-07; estável [V].
- Descartados: DataStore2 (parado 2023, método Berezaa ruim com novo limite de armazenamento), Lapis (comunidade pequena), DocumentService (beta), Suphi (menor), DataStoreService puro [V/O].
- Limites 2026: escrita por experiência 300 + CCU×20/min; servidor 60 + jogadores×40; 4 MB/min escrita por chave; valor até 4.194.304 chars; armazenamento 500 MB + 1 MB × usuários vitalícios (excesso cobrado após 2 semanas). Novos erros GameServerThrottled/ExperienceThrottled → backoff com jitter [V].

## Schema
- Um perfil por jogador, chave `Player_{UserId}`; SchemaVersion + migrações sequenciais antes do Reconcile; nada efêmero no perfil; ids string; listas limitadas [O].
```lua
local PROFILE_TEMPLATE = {
	SchemaVersion = 1,
	Coins = 0,
	CoinsEarnedHour = { Window = 0, Amount = 0 },
	Cosmetics = { Owned = {}, Equipped = { Skin = "default" } },
	Stats = { BestScore = 0, Deaths = 0, MaxDaysSurvived = 0, TotalPlaytime = 0 },
	Settings = { Volume = 0.8, Quality = "auto", UIScale = 1, LeftHanded = false },
	Quests = {},
	PurchaseIdCache = {},
	LifetimeRobuxSpent = 0,
}
```

## Salvamento
- Autosave do ProfileStore + EndSession no PlayerRemoving + BindToClose [V]. profile:Save() ao morrer/converter moeda/comprar cosmético [O]. Kick se StartSessionAsync falhar. Toda mudança de moeda por uma função. Mock no Studio (mesma chave Studio+live = perda) [V/O].

## Compras
- ProcessReceipt único; NotProcessedYet se jogador ausente; padrão ProfileStore: PurchaseIdCache (100) → conceder → esperar LastSavedData conter id → PurchaseGranted [V].
- Game Pass: UserOwnsGamePassAsync em pcall + PromptGamePassPurchaseFinished; cache em atributo, não no perfil [V/O]. Venda cross-game desativada 30/05/2026 [V].
- Caixas pagas: vale também para moeda comprada com Robux; % numérica somando 100% antes de gastar; ajustar chances se item único; PolicyService ArePaidRandomItemsRestricted → bloquear/alternativa [V]. Implicação: moeda soft vendida por Robux contamina caixas → caixas só com moeda ganha, segunda moeda, ou venda direta [O].
- Premium Payouts substituído por Creator Rewards (24/07/2025), automático [V].

## Leaderboards
- OrderedDataStore para recordes permanentes (limite 30 + jogadores×5/min por servidor); gravar só ao bater recorde; ler top 10 a cada 2–5 min em cache [V/O].
- MemoryStore SortedMap para diário/semanal; um mapa por período; cota 1000 + 120×CCU [V].
- Ranking do servidor: memória/leaderstats [O].

## GDPR
- RTBF: 30 dias para remover; templates de deleção automática com `{UserId}` estático (também ordered) na aba RTBF do Data Stores Manager [V]. Não guardar nomes/chat [O].

## Partida ao sair/cair
- Sem doc de como Starve.io/Booga tratam [V]. Combat logging é problema clássico [V].
- Recomendação [O]: queda do servidor = partida perdida, mas converter pontos em moeda no BindToClose; sair voluntariamente = morte (converte pontos); opcional depois: graça de 60–120 s em reconexão ao mesmo JobId (estado em memória + marcador MemoryStore).
