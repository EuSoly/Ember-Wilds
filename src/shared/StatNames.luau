--!strict
-- Nomes dos atributos que o servidor publica e a interface lê.
-- Quem escreve (SurvivalService, ScoreService, ResourceService...)
-- e quem lê (HUD) usam estes nomes, nunca strings soltas.
return table.freeze({
	-- Barras de status, 0 a StatusMax, atributos no Player
	Health = "Health",
	Hunger = "Hunger",
	Cold = "Cold",
	Thirst = "Thirst",
	-- Calor "por cima" do frio, 0 a StatusMax (0 = nenhum), atributo no Player
	-- (SurvivalService). Enquanto > 0, o anel do frio mostra o calor.
	Heat = "Heat",

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
	-- Estações de crafting: atributo Station vale workbench ou fire.
	CraftStationTag = "CraftStation",
	Station = "Station",
	-- Reserva atual e máxima de um recurso coletável, atributos no modelo em
	-- Workspace.Resources (ResourceService; o cliente mostra as frutinhas).
	Amount = "Amount",
	AmountMax = "AmountMax",
	-- Raio de colisão do recurso (studs, já com a escala), atributo no modelo
	-- (ResourceService): o fantasma da construção usa o mesmo raio do servidor.
	ResourceRadius = "ResourceRadius",
	-- Tag das peças que ficam semitransparentes entre a câmera e o boneco (copas).
	OccluderTag = "Occluder",
	-- Tag das peças com a luz de fogueira (FireLight.attach): o cliente liga a
	-- tremulação em cada uma.
	FireLightTag = "FireLight",

	-- Sobrevivência (G1).
	-- Id do item de armadura vestido (category "armor"), ou nil; atributo no
	-- Player (escrito pelo ArmorService).
	Armor = "Armor",
	-- Tag (CollectionService) dos modelos que esquentam (fogueira): perto deles
	-- o frio sobe (SurvivalService).
	HeatSourceTag = "HeatSource",
	-- Raio do calor (studs), atributo no modelo com a tag HeatSource.
	HeatRadius = "HeatRadius",
	-- Raio (studs) em que a fonte de calor queima ("em cima do fogo"): passa
	-- do frio cheio e enche o calor. Atributo no modelo com a tag HeatSource.
	BurnRadius = "BurnRadius",

	-- Construção (G4). Peças colocadas em Workspace.Structures (StructureService).
	-- Tag (CollectionService) de toda peça colocada.
	StructureTag = "Structure",
	-- Id do item que virou a peça (ex.: "wood_wall"), atributo no modelo da peça:
	-- o cliente acha o tipo da peça nos Defs (ex.: o painel do baú).
	StructureItem = "StructureItem",
	-- UserId do dono da peça, atributo no modelo.
	Owner = "Owner",
	-- Vida atual e máxima da peça, atributos no modelo (a barrinha de vida lê).
	StructureHealth = "StructureHealth",
	StructureHealthMax = "StructureHealthMax",
	-- true com a porta aberta (as peças dela não colidem), atributo no modelo da porta.
	DoorOpen = "DoorOpen",
	-- Conteúdo do baú, atributos no modelo do baú (ChestService; todos veem):
	-- id do item guardado (nil = vazio) e quantidade. Baú que ninguém mexeu
	-- ainda não tem os atributos: sem atributo = vazio.
	ChestItem = "ChestItem",
	ChestCount = "ChestCount",

	StatusMax = 100,
	-- Abaixo desta fração a barra entra em alerta (e a vida para de regenerar)
	WarningFraction = 0.35,
})
