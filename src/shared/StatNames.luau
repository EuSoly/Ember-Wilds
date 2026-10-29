--!strict
-- Nomes dos atributos que o servidor publica e a interface lê.
-- Quem escreve (SurvivalService na fase G1; DevStatsService no Studio por enquanto)
-- e quem lê (HUD) usam estes nomes, nunca strings soltas.
return table.freeze({
	-- Barras de status, 0 a StatusMax, atributos no Player
	Health = "Health",
	Hunger = "Hunger",
	Cold = "Cold",
	Thirst = "Thirst",

	-- Pontuação da vida atual e posição no ranking do servidor, atributos no Player
	Score = "Score",
	Rank = "Rank",

	-- Saldo de Golden Ember (perfil salvo), atributo no Player (escrito pelo CurrencyService).
	Currency = "Currency",
	-- Prefixo das configurações do jogador: "Setting_music_volume" etc., atributos
	-- no Player (escritos pelo SettingsService a partir do perfil).
	SettingPrefix = "Setting_",

	-- true quando o perfil salvo carregou (DataService), atributo no Player: a tela
	-- de carregamento espera por ele e o servidor só deixa nascer depois dele.
	DataReady = "DataReady",
	-- Pontos da última vida, disponíveis para comprar um kit inicial (só em
	-- memória, escrito pelo DeathService/SpawnService), atributo no Player.
	KitPoints = "KitPoints",
	-- UserId do jogador que a câmera do menu acompanha (0 = ninguém: gira sobre
	-- o centro), atributo no Player (escrito pelo SpectateService).
	SpectateTarget = "SpectateTarget",

	-- Id do item da mochila vestida (ex.: "leather_bag"), ou nil sem mochila; atributo no Player.
	-- A capacidade do inventário vem da mochila (ver InventoryService.equipBag).
	Bag = "Bag",

	-- Instante (GetServerTimeNow) em que o ciclo de dia começou, atributo no Workspace
	CycleStart = "CycleStart",

	-- Estado do boneco, atributos no personagem (o visual de cada cliente lê daqui).
	-- true enquanto o jogador segura o botão de bater (escrito pelo UseSim).
	Using = "Using",
	-- Id do item na mão (slot selecionado da hotbar), ou nil (escrito pelo EquipService).
	Equipped = "Equipped",
	-- Instante (GetServerTimeNow) do último dano (escrito por CharacterService.hurt).
	HurtAt = "HurtAt",
	-- Prefixo do id do cosmético equipado por slot: "Cosmetic_body" = skin do corpo.
	CosmeticPrefix = "Cosmetic_",
	-- Tag (CollectionService) dos personagens que ganham um boneco visual.
	BonecoTag = "Boneco",
	-- Grupo de colisão do corpo simulado: bonecos não colidem entre si
	-- (registrado no CharacterService.Init, aplicado no CharacterBody).
	BonecoCollisionGroup = "Bonecos",

	-- Mundo (F6).
	-- true enquanto a raiz do personagem está dentro de Map/Water, atributo no
	-- Player (escrito pelo WaterService; lido pela sede na G1).
	InWater = "InWater",
	-- Fôlego, 0 a StatusMax, atributo no Player (WaterService): cai na água.
	Oxygen = "Oxygen",
	-- Id em Defs.Resources: nos marcadores de Map/Resources (feitos no Studio)
	-- e nos modelos montados em Workspace.Resources.
	ResourceId = "ResourceId",
	-- Variação do modelo (1..variants), opcional nos marcadores de Map/Resources.
	Variant = "Variant",
	-- Id em Defs.ResourceZones, nas peças de Map/Zones.
	ZoneType = "ZoneType",
	-- Tag (CollectionService) dos recursos montados (a fase de coleta usa).
	ResourceTag = "Resource",
	-- Tag das peças que ficam semitransparentes entre a câmera e o boneco (copas).
	OccluderTag = "Occluder",

	StatusMax = 100,
	-- Abaixo desta fração a barra entra em alerta (e a vida para de regenerar)
	WarningFraction = 0.35,
})
