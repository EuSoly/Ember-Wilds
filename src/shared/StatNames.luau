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
	-- Pasta (Folder) no Player com as estatísticas permanentes: um atributo por
	-- id ("xp_total" etc.; keyed = total somado), escritos pelo StatsService. O
	-- Perfil lê dali. Fica numa pasta, não no Player, porque o Roblox limita o
	-- total de atributos de cada instância (~1 KB): com tudo no Player, o
	-- SetAttribute de Score/Rank/barras passava a falhar.
	StatsFolder = "ProfileStats",

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
	-- Instante (GetServerTimeNow) até quando a arma recém-equipada fica presa na
	-- mão (item com equipLock); nil = solta. Escrito pelo EquipService.
	EquipLockUntil = "EquipLockUntil",
	-- Instante (GetServerTimeNow) do último dano (escrito por CharacterService.hurt).
	HurtAt = "HurtAt",
	-- Instante (GetServerTimeNow) em que a mordida atual termina e a comida faz
	-- efeito; nil = não está comendo (escrito pelo FoodService). O boneco anima a
	-- mordida e a simulação deixa o jogador mais lento enquanto vale.
	EatUntil = "EatUntil",
	-- true enquanto o personagem dorme numa cama (escrito pelo BedService; olhos fechados).
	Sleeping = "Sleeping",
	-- Prefixo do id do cosmético equipado por slot: "Cosmetic_body" = skin do corpo.
	CosmeticPrefix = "Cosmetic_",
	-- Pasta (Folder) no Player com a posse publicada: um BoolValue por skin
	-- possuída, Name = id do cosmético (CosmeticService). Objetos, não atributos:
	-- com centenas de skins, atributos passariam do limite de ~1 KB da instância.
	OwnedFolder = "OwnedCosmetics",
	-- Pasta (Folder) no Player com o estado da loja (ShopService). Atributos da
	-- pasta: saldos de giros e o kit para sempre ativo ("" = nenhum). Subpastas
	-- com um objeto por entrada (listas que crescem não viram atributo):
	-- KitsOwned (BoolValue por kit), KitBalance (IntValue por kit, saldo de 1
	-- vida), Purchased (BoolValue por produto "once" comprado), Passes (BoolValue).
	ShopFolder = "Shop",
	SpinsNormal = "SpinsNormal",
	SpinsPaid = "SpinsPaid",
	KitActive = "KitActive",
	KitsOwnedFolder = "KitsOwned",
	KitBalanceFolder = "KitBalance",
	PurchasedFolder = "Purchased",
	PassesFolder = "Passes",
	-- Vantagens (PerkService), atributos da pasta Shop acima (não do Player:
	-- limite de ~1 KB). Perk_* (bool) = o que vale nesta vida enquanto há vida
	-- ativa (foto ao nascer; ganho com a vida ativa entra na hora), e o que
	-- vale agora quando morto / no menu. VipUntil, XpBoostStart, XpBoostUntil
	-- (unix) = o perfil.
	PerkVip = "Perk_vip",
	PerkEmber2x = "Perk_ember2x",
	PerkBook = "Perk_book",
	PerkPremium = "Perk_premium",
	VipUntil = "VipUntil",
	XpBoostStart = "XpBoostStart",
	XpBoostUntil = "XpBoostUntil",
	-- Check-in de 7 dias (ShopService escreve ao montar a pasta; CheckInService
	-- republica na virada do dia), também atributos da pasta Shop:
	-- CheckInDay = próximo prêmio (1..7), CheckInReady = há prêmio para resgatar hoje.
	CheckInDay = "CheckInDay",
	CheckInReady = "CheckInReady",
	-- Janela de Códigos (ShopService escreve), atributos da pasta Shop:
	-- CodeNotice = há código em destaque (Shop/Codes, news) que o jogador ainda
	-- não usou; GroupClaimed = já pegou o prêmio do grupo (Shop/GroupReward).
	CodeNotice = "CodeNotice",
	GroupClaimed = "GroupClaimed",
	-- Item aleatório pago proibido para o jogador (PolicyService), também atributo
	-- da pasta Shop. Sem resposta ainda ou com erro = true (lado seguro).
	PaidRandomBlocked = "PaidRandomBlocked",
	-- Tutorial da primeira partida (TutorialService), atributos do Player:
	-- TutorialStep = etapa atual (0 = fora do tutorial, 1..6); TutorialProtected =
	-- protegido (nem leva nem causa dano); TutorialPending = o perfil ainda não
	-- completou; SpinPopupPending = mostrar o pop-up da roleta no menu.
	TutorialStep = "TutorialStep",
	TutorialProtected = "TutorialProtected",
	TutorialPending = "TutorialPending",
	SpinPopupPending = "SpinPopupPending",
	-- Tag (CollectionService) dos personagens que ganham um boneco visual.
	BonecoTag = "Boneco",
	-- Raízes visuais dos mobs; contadores de eventos, sem regras de combate.
	MobTag = "Mob",
	MobId = "MobId",
	MobAttack = "MobAttack",
	MobHurt = "MobHurt",
	MobDead = "MobDead",
	-- Quer atacar agora (agressivo sempre; neutro depois de apanhar): borda vermelha.
	MobHostile = "MobHostile",
	-- Voando agora (booleano), na raiz do mob (MobService): o cliente sobe o
	-- visual e deixa translúcido.
	MobFlying = "MobFlying",
	-- Instante (GetServerTimeNow) em que a teia da aranha solta, atributo no
	-- personagem (MobService). Preso enquanto MobRules.isWebbed; no personagem
	-- local previsto, ler por polling.
	WebbedUntil = "WebbedUntil",
	-- Nas MeshParts de Assets.Mobs: esta camada é a borda que muda de cor.
	MobOutline = "MobOutline",
	-- Nas MeshParts de Assets.Mobs: versão brava (cortada) de um olho.
	MobAngryEye = "MobAngryEye",
	-- Ajuste de tamanho ao vivo, só no Studio: atributos nos modelos de
	-- Assets.Mobs (Tamanho = visual, todos os mobs; RaioCorpo = corpo no jogo,
	-- só mobs com IA) e na pasta Assets.Mobs (MostrarCorpo = disco do corpo;
	-- Pacifico = mobs ignoram os jogadores). Em português para não confundir
	-- com a propriedade Scale do Model. Veja docs/guia/mobs.md.
	MobDevScale = "Tamanho",
	MobDevRadius = "RaioCorpo",
	MobDevShowBody = "MostrarCorpo",
	MobDevPeaceful = "Pacifico",
	-- Tamanho de cada ferramenta/arma: atributo nos modelos de Assets.Tools
	-- (1 = tamanho importado), salvo com o place. No Studio, mudar o valor
	-- refaz o item na mão na hora. Veja docs/guia/boneco.md.
	ToolScale = "Tamanho",
	-- Onde a mão segura: studs ao longo da arma a partir do Grip importado
	-- (positivo = mão mais perto da ponta). Mesmo esquema do Tamanho.
	ToolGrip = "Pegada",
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
	-- Modo criativo ligado (true/nil), atributo no Player escrito só pelo
	-- CreativeService a partir do perfil; o cliente lê para o livro.
	Creative = "Creative",
	-- Fantasma (GhostService): instante (relógio do servidor) em que o tempo de
	-- fantasma acaba; nil = não é fantasma. Atributo no Player.
	GhostUntil = "GhostUntil",
	-- Proteção do revive (ReviveService): instante (relógio do servidor) em que
	-- ela acaba; não leva dano e os mobs não o veem. Some antes se ele bater num
	-- jogador ou mob (GatherService). Atributo no MODELO do personagem (não no
	-- Player, que tem o limite de ~1 KB de atributos): some com o corpo.
	SpawnShieldUntil = "SpawnShieldUntil",
	-- Time (TeamService): UserId do líder do time do jogador (nil = sem time),
	-- atributo no Player. No modelo do totem: TeamLeader (UserId), TeamLocked e
	-- TeamSize, para o cliente mostrar Entrar/Trancar.
	Team = "Team",
	TeamLeader = "TeamLeader",
	TeamLocked = "TeamLocked",
	TeamSize = "TeamSize",
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
	-- Tags (CollectionService) da ponte e do telhado (StructureModel.build), com o
	-- raio do círculo da peça (studs) no atributo PieceRadius do modelo: a água
	-- (WaterSim, nos dois lados), o MobService e o cliente acham as peças por aqui
	-- sem depender do StructureService.
	BridgeTag = "Bridge",
	RoofTag = "Roof",
	PieceRadius = "PieceRadius",
	-- true com a porta aberta (as peças dela não colidem), atributo no modelo da porta.
	DoorOpen = "DoorOpen",
	-- Conteúdo do baú (3 slots, ChestRules.SLOTS), atributos no modelo do baú
	-- (ChestService; todos veem): ChestItem1..3 (nil = vazio) e ChestCount1..3.
	-- Baú que ninguém mexeu ainda não tem os atributos: sem atributo = vazio.
	chestItem = function(slot: number): string
		return `ChestItem{slot}`
	end,
	chestCount = function(slot: number): string
		return `ChestCount{slot}`
	end,
	-- Estado das estruturas de usar de perto (G8), atributos no modelo da peça
	-- (todos veem; o painel de interação mostra só os que existem): madeira
	-- dentro (extrator e fornalha), estoque pronto (extrator) e goles (poço).
	Wood = "Wood",
	Stock = "Stock",
	Drinks = "Drinks",
	-- Fazenda (FarmService), atributos no modelo: frutos prontos na planta e se a
	-- planta (ou o canteiro) está regada.
	PlantFruit = "PlantFruit",
	PlantWet = "PlantWet",
	-- Índice do símbolo da placa (SignRules.SYMBOLS), 0 = nenhum; atributo no modelo.
	Symbol = "Symbol",
	-- true enquanto o extrator trabalha (o rotor gira), atributo no modelo (MachineService).
	Working = "Working",
	-- false com a peça apagada (as chamas somem; sem atributo = acesa), atributo
	-- no modelo da fornalha (MachineService).
	Lit = "Lit",

	-- Caixas de itens (G6). Tag (CollectionService) dos modelos de caixa em
	-- Workspace.Crates (CrateService). A vida usa StructureHealth/StructureHealthMax,
	-- como as peças, para a mesma barrinha aparecer; o conteúdo vai por evento
	-- (Net.CrateContents), não por atributo.
	CrateTag = "Crate",
	-- true na caixa do morto com o revive pendente (CrateService.setLocked):
	-- ninguém abre, saqueia nem quebra; o cliente mostra o cadeado. Atributo no modelo.
	CrateLocked = "CrateLocked",

	StatusMax = 100,
	-- Teto da vida (as outras barras vão até StatusMax)
	HealthMax = 200,
	-- Abaixo desta fração a barra entra em alerta (e a vida para de regenerar)
	WarningFraction = 0.35,
})
