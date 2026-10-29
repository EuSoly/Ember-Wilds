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

	StatusMax = 100,
	-- Abaixo desta fração a barra entra em alerta (e a vida para de regenerar)
	WarningFraction = 0.35,
})
