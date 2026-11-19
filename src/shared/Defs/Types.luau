--!strict
-- Tipos das definições de conteúdo. Ficam num módulo separado para que
-- Tiers, Items e Validate possam usar os mesmos tipos sem depender um do outro.

export type TierDef = {
	id: string,
	-- Posição na escada de progressão (1 = madeira). Ramos laterais (esmeralda) usam 0.
	order: number,
	color: string, -- hex da Palette
	rarityKey: string, -- chave em Strings (raridade de cosmético equivalente)
	nameKey: string, -- chave em Strings
}

export type ItemCategory = "resource" | "food" | "tool" | "weapon" | "armor" | "bag" | "placeable" | "misc"

-- O que uma comida repõe ao ser comida (pontos de barra, 0 a 100).
-- crumbColor (só visual): cor "#RRGGBB" dos farelos da mordida; ausente = cor de pão.
export type FoodEffect = { hunger: number?, thirst: number?, health: number?, crumbColor: string? }

-- Quanto a peça soma na variação do frio por tick do Starve, por lugar e hora
-- (config oficial `<item>_warm_<lugar>`; positivo = esquenta). Ausente = 0.
-- A conversão para o nosso jogo fica em ArmorRules.coldMultiplier.
export type ArmorWarm = {
	day: number?,
	night: number?,
	waterDay: number?,
	waterNight: number?,
	winterDay: number?, -- inverno (bioma futuro)
	winterNight: number?,
	lavaDay: number?, -- lava (bioma futuro): subtrai do calor da lava
	lavaNight: number?,
}

-- Item de cabeça vestido (um por vez, como no Starve). Números em UNIDADES DO
-- STARVE (config oficial; veja docs/game-design/armaduras-starve.md); quem
-- converte é Survival/ArmorRules.
export type ArmorStats = {
	defense: number?, -- tirado do golpe de JOGADOR (`<item>_defense`)
	mobDefense: number?, -- tirado da mordida de MOB (`<item>_mob_defense`)
	warm: ArmorWarm?,
	fireHeatFactor: number?, -- multiplica o calor que o fogo põe na barra de calor (proteções = 0)
	oxygenLoss: number?, -- tirado da perda de fôlego na água (base 25 por tick)
	swimSpeed: number?, -- multiplica a velocidade nadando (mergulho 1,2)
	regenHeal: number?, -- cura por ciclo de regen (base 12; Coroa da Vida 40)
	hidesName: boolean?, -- capuzes: o nick some para os outros
	explorer: boolean?, -- mobs agressivos ignoram; bater em algo desliga por um tempo
	hungerFactor: number?, -- multiplica a queda da fome (nenhuma peça do Starve usa)
	thirstFactor: number?, -- multiplica a queda da sede (nenhuma peça do Starve usa)
	cropGrowth: number?, -- túnicas: a planta regada por quem veste cresce isso mais rápido (FarmService)
	-- Só dado, para sistemas futuros (nada no jogo lê ainda):
	blizzard: number?, -- tirado do dano da nevasca (base 26 a cada 4 s)
	sand: { damage: number, every: number }?, -- dano da tempestade de areia com a peça
	stealImmune: ("hood" | "all")?, -- imune ao roubo do capuz comum / de todos
	tameLuck: number?, -- multiplica a chance de domar (Coroa da Sorte)
	digLuck: number?, -- sorte da pá (Coroa da Sorte)
	resurrect: boolean?, -- vira fantasma e ressuscita na pedra (Coroa do Anjo)
	crabFriend: boolean?, -- caranguejos seguem e não atacam
	spiderImmune: boolean?, -- aranha não dá dano
	pilotAcceleration: number?, -- aceleração da decolagem do avião
	gearSet: string?, -- bônus com as armas do mesmo conjunto (dragão, lava)
}

export type StructureKind =
	"wall"
	| "door"
	| "spike"
	| "station"
	| "chest"
	| "fire"
	| "spike_door"
	| "extractor"
	| "furnace"
	| "bridge"
	| "roof"
	| "sign"
	| "well"
	| "bed"
	| "totem" -- cria e guarda o time do dono (TeamService)
	| "resurrection" -- pedra da ressurreição (GhostService)
	| "emerald_machine" -- pontos por minuto ao dono (EmeraldService)
	| "plot" -- canteiro: camada do chão, encaixa em grade, guarda a rega da planta (FarmService)
	| "plant" -- semente plantada: cresce, dá fruto e é colhida (FarmService, PlantRules)
-- Uma cultura (config oficial do Starve: grown_/born_/water_/time_life_<crop>, em s).
export type PlantDef = {
	crop: string, -- pasta Assets.Farming.<crop> (stage_01 a stage_04)
	fruit: string, -- item colhido
	growSeconds: number, -- de semente a madura (sem bônus)
	fruitSeconds: number, -- um fruto novo a cada tanto, depois de madura
	waterSeconds: number, -- quanto dura uma rega
	lifeSeconds: number, -- idade em que a planta morre
	maxFruit: number, -- frutos guardados no máximo (os do modelo stage_04)
	fruitPoints: number, -- pontos por fruto colhido
}
export type ExtractorDef = {
	output: string, -- id do item produzido
	woodPerCycle: number,
	cycleSeconds: number,
	yield: number,
	maxWood: number,
	maxStock: number,
}
export type FurnaceDef = { burnEvery: number, maxWood: number }
export type WellDef = { drinksPerBucket: number, maxDrinks: number, thirstPerDrink: number }
export type BedDef = { regenFactor: number, drainFactor: number }
export type StructureDef = {
	kind: StructureKind,
	health: number, -- vida máxima (> 0)
	radius: number?, -- studs: raio do círculo da peça no chão; padrão BuildRules.PIECE_RADIUS
	spikeDamage: number?, -- kind "spike" e "spike_door" (obrigatório neles) e "plant" (arbusto de espinho, madura): dano ao encostar
	spikeHitDamage: number?, -- só "spike" e "spike_door": dano em quem BATE na peça (Starve "hit")
	lifetime: number?, -- segundos até sumir; só kind "fire" (obrigatório nele)
	heatRadius: number?, -- studs; só kind "fire" e "furnace" (obrigatório neles)
	station: CraftStation?, -- estação oferecida: "workbench" (kind station) ou "fire" (kind fire/furnace)
	-- Blocos por tipo: só no seu kind e obrigatórios nele.
	extractor: ExtractorDef?,
	furnace: FurnaceDef?, -- calor por heatRadius; queima enquanto tem madeira (sem lifetime)
	well: WellDef?,
	bed: BedDef?,
	plant: PlantDef?,
	-- Encaixa em grade nas vizinhas da mesma camada com snap (chão e teto:
	-- telhado, ponte, canteiros). Veja BuildRules.snapPlacement.
	snap: boolean?,
	-- Quantas desta peça (do mesmo kind) cada jogador pode ter no mundo (nil = sem limite).
	maxPerPlayer: number?,
}

export type ItemDef = {
	id: string,
	-- Só para teste: fora do Studio o item não existe para o jogador (ItemAccess).
	testOnly: boolean?,
	nameKey: string,
	category: ItemCategory,
	-- Item que não é ferramenta nem arma mas aparece na mão com o modelo de
	-- ReplicatedStorage.Assets.Tools.<id> (livro, baldes). Ver ToolModel.
	handModel: boolean?,
	tier: string?, -- id em Tiers; nil = moldura neutra (recursos, comida)
	maxStack: number,
	-- Só para category "bag": quantos slots a mochila dá quando vestida.
	bagSlots: number?,
	-- Só (e obrigatório) para category "food": o que repõe ao comer.
	food: FoodEffect?,
	-- Só (e obrigatório) para category "armor": proteção e modificadores das barras.
	armor: ArmorStats?,
	-- Só para category "tool": picareta de nível `level` (madeira 1, pedra 2,
	-- ouro 3...). Rende `level - dureza + 1` por golpe (ver Gather/GatherRules).
	pickaxe: { level: number }?,
	-- Multiplicador de velocidade de criação (só category "misc").
	craftSpeed: number?,
	-- Só (e obrigatório) para category "placeable": como a peça age depois de colocada.
	structure: StructureDef?,
	-- Dano do golpe em peça de construção (> 0). Ausente = golpe de mão.
	structureDamage: number?,
	-- Dano do golpe em mob (> 0). Ausente = golpe de mão (MobRules.HAND_DAMAGE).
	mobDamage: number?,
	-- Fração da velocidade de andar com o item na mão (0–1; ausente = 1). No
	-- Starve, espada e lança deixam o jogador bem mais lento.
	moveSpeed: number?,
	-- Segundos que o item fica preso na mão depois de equipado (ausente = 0):
	-- não dá para trocar de slot antes (arma do Starve).
	equipLock: number?,
	-- Studs a mais de alcance do golpe (ausente = 0). A lança alcança mais longe.
	reach: number?,
	-- Studs que o golpe empurra o mob para longe de quem bateu (ausente = 0).
	-- A lança empurra: fugindo e batendo para trás, o mob da floresta não alcança.
	-- Só mob: nunca empurra jogador (no PvP seria forte demais; decisão do Elizeu).
	knockback: number?,
	-- Animação do golpe com o item na mão: "swing" (padrão, arco de lado, como a
	-- picareta e a espada), "thrust" (estocada para a frente: as lanças e os
	-- forcados) ou "bash" (escudo nas duas mãos, à frente; o golpe avança). Só visual.
	attackAnim: AttackAnim?,
	-- Escudo (Starve): na mão, a defesa soma com a da peça de cabeça (golpe de
	-- jogador e mordida de mob). arrowDefense é só dado (flechas não existem).
	shield: { defense: number, mobDefense: number, arrowDefense: number? }?,
	-- Martelo: contra construção de material acima do dele, o dano em
	-- construção cai para minDamage (Starve `building_min_damage`).
	hammer: { minDamage: number }?,
	-- Bônus de conjunto: + damage no golpe quando a peça de cabeça vestida tem
	-- armor.gearSet == set (espadas e lanças de dragão e de lava).
	gearBonus: { set: string, damage: number }?,
	-- Chave inglesa: golpe numa construção aliada danificada devolve essa vida.
	repair: number?,
	dig: number?, -- pá: quanto cava por golpe (DigRules)
	harvest: number?, -- forcado: frutos colhidos por golpe (PlantRules.harvestOf)
	waters: boolean?, -- regador cheio: o golpe rega planta e canteiro (FarmService)
	-- Só dado, para sistemas futuros (nada no jogo lê ainda):
	butcher: number?, -- facão: multiplica o que a caixa de mob dá
	crabCalm: boolean?, -- lança de caranguejo: acalma caranguejos
}

export type AttackAnim = "swing" | "thrust" | "bash"

-- "water": perto da água do mapa (Map/Water), sem peça construída.
export type CraftStation = "workbench" | "fire" | "water"
export type RecipeIngredient = { id: string, count: number }
export type RecipeDef = {
	id: string,
	nameKey: string?,
	result: string,
	count: number,
	ingredients: { RecipeIngredient },
	time: number,
	station: CraftStation?,
	-- Estações exigidas ALÉM de `station` (Starve: bancada + fogo, ou bancada +
	-- fogo + água nas coroas e nos capacetes de dragão e lava).
	alsoNear: { CraftStation }?,
	order: number,
}

-- Estilos de olho do boneco (a lista para validar fica em Validate.EYE_STYLES).
export type EyeStyle = "open" | "closed" | "squeeze" | "happy"

-- Como uma expressão fica ativa: sempre (a base), de tempos em tempos,
-- quando um evento acontece (ex. dano) ou enquanto um atributo passa de um limiar.
export type ExpressionCondition = { attribute: string, below: number?, above: number?, equals: boolean? }
export type ExpressionTrigger = "always" | "periodic" | "event" | "condition"

export type ExpressionDef = {
	id: string,
	priority: number, -- maior ganha
	eyes: EyeStyle,
	trigger: ExpressionTrigger,
	duration: number?, -- segundos; obrigatório em "periodic" e "event"
	intervalMin: number?, -- "periodic": intervalo sorteado entre min e max
	intervalMax: number?,
	event: string?, -- "event": nome do evento (ex. "hurt")
	condition: ExpressionCondition?, -- "condition"
	flash: { color: string, duration: number }?, -- pisca o corpo nessa cor
}

-- Cores de uma skin de corpo. handColor ausente = cor do corpo; eyeColor ausente = preto.
export type BodyLook = { bodyColor: string, outlineColor: string, handColor: string?, eyeColor: string? }

export type BagLook = { color: string, strapColor: string }
export type CrateLook = { bodyColor: string, bandColor: string }

export type CosmeticSlotDef = {
	id: string,
	nameKey: string,
	default: string, -- id em Cosmetics usado por quem não equipou nada
}

export type CosmeticDef = {
	id: string,
	nameKey: string,
	slot: string, -- id em CosmeticSlots
	rarity: number, -- 1 Comum, 2 Raro, 3 Épico, 4 Lendário, 5 Mítico
	unreleased: boolean?,
	inSpins: boolean?, -- entra no giro da loja? (padrão do slot: só se true)
	-- Etiquetas marcadas à mão (UIFlow/CosmeticTags): hoje só "limited"
	-- (Limitada, faixa no canto de cima à direita). Animada e Efeitos saem sozinhas.
	tags: { string }?,
	body: BodyLook?, -- dados do slot "body"
	bag: BagLook?, -- dados do slot "bag"
	crate: CrateLook?, -- dados do slot "crate"
}

-- Estatísticas salvas no perfil. "counter" só soma, "max" guarda o maior valor,
-- "keyed" tem um contador por chave (ex. mobs_killed["cow"]); keyKind diz o que
-- a chave é, para validação e para telas futuras.
export type StatKind = "counter" | "max" | "keyed"
export type StatKeyKind = "mob" | "item"
export type StatDef = { id: string, nameKey: string, kind: StatKind, keyKind: StatKeyKind? }

-- Configurações do jogador salvas no perfil (o cliente pede, o servidor valida).
export type SettingKind = "number" | "boolean" | "choice"
export type SettingValue = number | boolean | string
-- Grupo na tela de configurações (a ordem dos grupos é SettingsFormat.GROUPS).
export type SettingGroup = "sound" | "screen" | "controls"
export type SettingDef = {
	id: string,
	nameKey: string,
	group: SettingGroup,
	order: number, -- posição dentro do grupo (inteiro ≥ 1, sem repetir no arquivo)
	kind: SettingKind,
	default: SettingValue,
	min: number?, -- "number"
	max: number?, -- "number"
	options: { string }?, -- "choice"
}

-- Kits iniciais: comprados antes de nascer com os pontos da vida que acabou.
-- Uma mochila na lista é vestida em vez de ir para um slot.
export type KitItem = { id: string, count: number }
export type KitDef = {
	id: string,
	nameKey: string,
	order: number, -- posição na lista (1 = primeiro)
	price: number, -- em pontos
	items: { KitItem },
	-- Só de conquista (Defs/Achievements): fora da loja e dos pontos; só
	-- aparece e só vem para quem tem a posse (Shop.KitsOwned).
	exclusive: boolean?,
	-- Só para quem é VIP (Shop.VipUntil > agora); ver Shop/Perks.unlockedKits.
	vipOnly: boolean?,
}

-- Recursos do mundo (árvore, rocha...). radius = espaço que ocupa (para o
-- espalhador não encostar outro); collisionRadius = raio da única peça que
-- bloqueia a passagem; variants = quantas variações de modelo existem.
-- Coleta de um recurso (G2). Material escolhe as lasquinhas (GatherFxConfig) e o som (Audio/SoundConfig).
export type GatherMaterial = "wood" | "stone" | "gold" | "leaves"
export type GatherDef = {
	item: string, -- id em Items que o golpe dá
	points: number, -- pontos por unidade coletada
	material: GatherMaterial,
	-- Exatamente um dos dois: dureza (picareta mínima; 0 = mão) ou rendimento
	-- fixo por golpe com qualquer coisa na mão (ex. frutinha).
	hardness: number?,
	fixedYield: number?,
	-- Reserva; min diferente de max = cresce com o tamanho do exemplar (o menor = min).
	amount: { min: number, max: number },
	-- Volta `amount` a cada `every` segundos, até a reserva máxima.
	regen: { amount: number, every: number },
}

export type ResourceDef = {
	id: string,
	nameKey: string,
	radius: number,
	collisionRadius: number,
	variants: number,
	-- Tamanho (studs) do modelo no jogo: o modelo do Studio é redimensionado
	-- para ele. Medido na largura (maior medida vista de cima) ou na altura,
	-- conforme sizeAxis. nil = usa o tamanho do modelo.
	size: number?,
	-- "width" (padrão) ou "height": árvores usam a altura, para copas com
	-- proporções diferentes não deixarem uma árvore minúscula.
	sizeAxis: ("width" | "height")?,
	-- Fração da altura enterrada no chão (0.5 = metade). nil = 0.
	sink: number?,
	-- Variação de tamanho de cada exemplar (0.15 = ±15%). nil = 0.
	sizeJitter: number?,
	-- true = só enfeite (pedras do chão): sem colisão e sem a tag Resource.
	decorative: boolean?,
	-- Coleta (obrigatória em todo recurso que não é enfeite; proibida nos enfeites).
	gather: GatherDef?,
}

-- Zona de recursos desenhada no mapa (Map/Zones, atributo ZoneType).
-- densities: id em Resources → quantos por 10.000 studs².
export type ResourceZoneDef = {
	id: string,
	nameKey: string,
	densities: { [string]: number },
}

-- Comportamento do mob com os jogadores (Starve.io): passive nunca ataca,
-- neutral só ataca depois de apanhar, aggressive ataca quem vê.
export type MobBehavior = "passive" | "neutral" | "aggressive"

export type MobStats = {
	health: number,
	bite: number?, -- dano da mordida (vida do jogador, escala 0–200, StatNames.HealthMax); nil = não morde
	speed: number, -- studs/s
	radius: number, -- círculo do corpo no chão
	points: number, -- pontos para quem mata
	flies: boolean?, -- alterna voar/andar
	web: { duration: number, cooldown: number }?, -- teia ao morder
}
-- Quantos mobs o bioma mantém vivos de dia e de noite.
export type MobPopulation = { day: number, night: number }

export type MobLoot = { id: string, count: number }

export type MobDef = {
	id: string,
	nameKey: string,
	behavior: MobBehavior,
	stats: MobStats?, -- nil = ainda sem IA/servidor (só visual)
	population: { [string]: MobPopulation }?, -- por id de bioma (WorldConfig.BIOMES)
	loot: { MobLoot }?, -- o que a caixa do mob guarda ao morrer
	mountFlies: boolean?, -- gancho: montado, voa (montaria ainda não existe)
}

-- As Defs reais trazem todas as tabelas. Validate.all aceita a falta de
-- CosmeticSlots/Cosmetics/Expressions/Stats/Settings/Kits/Resources/ResourceZones
-- para os testes poderem validar só Tiers/Items.
-- Recompensa de missão: o mesmo formato das recompensas da loja (Shop/Types),
-- entregue por ShopService.give. Repetido aqui para Defs não depender de Shop.
export type MissionReward = {
	kind: string,
	id: string?,
	amount: number?,
	count: number?,
	spin: ("normal" | "paid")?,
}

-- Chrono quests (Defs/Quests): valem só na vida atual, com prazo em dias de jogo.
-- Regras que falham a quest: alone (sem time de 2+), unhurt (não perder vida),
-- peaceful (não acertar jogador nem mob manso/neutro, não pôr espinho), mined
-- e stay (só dado, para as quests de biomas futuros).
export type QuestRuleType = "alone" | "unhurt" | "peaceful" | "mined" | "stay"
export type QuestRule = { type: QuestRuleType, items: { string }?, biomes: { string }? }
-- Objetivos só como dado nas quests desligadas (ainda não há motor de objetivos).
export type QuestGoal = { type: string, item: string?, amount: number?, biomes: { string }? }
export type QuestDef = {
	id: string,
	nameKey: string,
	descKey: string,
	icon: string, -- chave de MissionImages.ICON
	enabled: boolean,
	days: number, -- prazo em dias de jogo (DataConfig.DAY_CYCLE_SECONDS cada)
	ends: "time" | "goals", -- time = vence quem chega ao fim do prazo sem quebrar regra
	goals: { QuestGoal },
	rules: { QuestRule },
	rewardItem: string, -- "" só em quest desligada (prêmio de slot de mochila)
	rewardCount: number,
	score: number, -- pontos da vida ao resgatar
}

-- De onde sai o progresso de uma missão ou conquista: uma estatística
-- (Defs/Stats; key = chave da keyed, sem key = soma) ou o valor da vida atual.
export type MissionTrack = { stat: string?, key: string?, life: ("days" | "score")? }

-- Diárias e semanais (Defs/Missions): banco sorteado por jogador.
export type MissionDef = {
	id: string,
	period: "daily" | "weekly",
	nameKey: string, -- texto com {n} = alvo
	icon: string,
	track: MissionTrack,
	target: number,
	rewards: { MissionReward },
}

-- Conquistas (Defs/Achievements): permanentes, 3 níveis. Nível com rewards
-- vazio = "em breve" (skin exclusiva ainda não escolhida).
export type AchievementTier = { target: number, rewards: { MissionReward } }
export type AchievementDef = {
	id: string,
	order: number,
	nameKey: string,
	icon: string,
	track: MissionTrack,
	tiers: { AchievementTier },
}

export type DefsTables = {
	Tiers: { [string]: TierDef },
	Items: { [string]: ItemDef },
	Recipes: { [string]: RecipeDef },
	CosmeticSlots: { [string]: CosmeticSlotDef },
	Cosmetics: { [string]: CosmeticDef },
	Expressions: { [string]: ExpressionDef },
	Stats: { [string]: StatDef },
	Settings: { [string]: SettingDef },
	Kits: { [string]: KitDef },
	Resources: { [string]: ResourceDef },
	ResourceZones: { [string]: ResourceZoneDef },
	Mobs: { [string]: MobDef },
	Quests: { [string]: QuestDef },
	Missions: { [string]: MissionDef },
	Achievements: { [string]: AchievementDef },
}

return nil
