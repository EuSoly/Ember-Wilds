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
export type FoodEffect = { hunger: number?, thirst: number?, health: number? }

-- Armadura vestida (uma por vez, como o item de cabeça do Starve).
-- defense: fração do dano de COMBATE cortada (0 a 0,9).
-- *Factor: multiplica quanto a barra cai (0,5 = metade da velocidade; até 2).
export type ArmorStats = {
	defense: number?,
	coldFactor: number?,
	hungerFactor: number?,
	thirstFactor: number?,
	heatFactor: number?, -- multiplica quanto o calor sobe (proteções de calor, N4)
}

export type ItemDef = {
	id: string,
	nameKey: string,
	category: ItemCategory,
	tier: string?, -- id em Tiers; nil = moldura neutra (recursos, comida)
	maxStack: number,
	-- Só para category "bag": quantos slots a mochila dá quando vestida.
	bagSlots: number?,
	-- Só (e obrigatório) para category "food": o que repõe ao comer.
	food: FoodEffect?,
	-- Só (e obrigatório) para category "armor": proteção e modificadores das barras.
	armor: ArmorStats?,
}

-- Estilos de olho do boneco (a lista para validar fica em Validate.EYE_STYLES).
export type EyeStyle = "open" | "closed" | "squeeze"

-- Como uma expressão fica ativa: sempre (a base), de tempos em tempos,
-- quando um evento acontece (ex. dano) ou enquanto um atributo passa de um limiar.
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
	condition: { attribute: string, below: number?, above: number? }?, -- "condition"
	flash: { color: string, duration: number }?, -- pisca o corpo nessa cor
}

-- Cores de uma skin de corpo. handColor ausente = cor do corpo; eyeColor ausente = preto.
export type BodyLook = { bodyColor: string, outlineColor: string, handColor: string?, eyeColor: string? }

export type CosmeticSlotDef = {
	id: string,
	nameKey: string,
	default: string, -- id em Cosmetics usado por quem não equipou nada
}

export type CosmeticDef = {
	id: string,
	nameKey: string,
	slot: string, -- id em CosmeticSlots
	body: BodyLook?, -- dados do slot "body"
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
export type SettingDef = {
	id: string,
	nameKey: string,
	order: number, -- posição na tela de configurações (1 = primeira)
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
}

-- Recursos do mundo (árvore, rocha...). radius = espaço que ocupa (para o
-- espalhador não encostar outro); collisionRadius = raio da única peça que
-- bloqueia a passagem; variants = quantas variações de modelo existem.
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
}

-- Zona de recursos desenhada no mapa (Map/Zones, atributo ZoneType).
-- densities: id em Resources → quantos por 10.000 studs².
export type ResourceZoneDef = {
	id: string,
	nameKey: string,
	densities: { [string]: number },
}

-- As Defs reais trazem todas as tabelas. Validate.all aceita a falta de
-- CosmeticSlots/Cosmetics/Expressions/Stats/Settings/Kits/Resources/ResourceZones
-- para os testes poderem validar só Tiers/Items.
export type DefsTables = {
	Tiers: { [string]: TierDef },
	Items: { [string]: ItemDef },
	CosmeticSlots: { [string]: CosmeticSlotDef },
	Cosmetics: { [string]: CosmeticDef },
	Expressions: { [string]: ExpressionDef },
	Stats: { [string]: StatDef },
	Settings: { [string]: SettingDef },
	Kits: { [string]: KitDef },
	Resources: { [string]: ResourceDef },
	ResourceZones: { [string]: ResourceZoneDef },
}

return nil
