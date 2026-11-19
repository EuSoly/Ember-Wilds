--!strict
-- Regras da peça de cabeça vestida (só números: testável no Lune). A peça traz
-- os números do Starve no bloco `armor` do item (Defs/Items); aqui eles viram
-- os efeitos do nosso jogo. Campos ausentes ficam neutros.
local SurvivalConfig = require("../SurvivalConfig")
local Types = require("../Defs/Types")

export type Warm = {
	day: number,
	night: number,
	waterDay: number,
	waterNight: number,
	winterDay: number,
	winterNight: number,
	lavaDay: number,
	lavaNight: number,
}

export type Modifiers = {
	defense: number, -- tirado do golpe de jogador
	mobDefense: number, -- tirado da mordida de mob
	warm: Warm,
	fireHeatFactor: number, -- multiplica o calor que o fogo põe na barra de calor
	oxygenLoss: number, -- tirado da perda de fôlego (unidades do Starve)
	swimSpeed: number, -- multiplica a velocidade nadando
	regenHeal: number?, -- cura por ciclo de regen do Starve (nil = normal)
	hidesName: boolean,
	explorer: boolean,
	hungerFactor: number, -- multiplica a queda da fome
	thirstFactor: number, -- multiplica a queda da sede
}

-- De onde vem o golpe: cada um usa a sua defesa.
export type HitSource = "player" | "mob"
-- Lugar do frio (base do Starve em SurvivalConfig.STARVE_COLD_LOSS).
export type ColdPlace = "forest" | "water" | "winter"

local C = SurvivalConfig

local ArmorRules = {}

local NO_WARM: Warm = table.freeze({
	day = 0,
	night = 0,
	waterDay = 0,
	waterNight = 0,
	winterDay = 0,
	winterNight = 0,
	lavaDay = 0,
	lavaNight = 0,
})

-- Sem peça: não corta dano, barras no ritmo normal.
ArmorRules.NONE = table.freeze({
	defense = 0,
	mobDefense = 0,
	warm = NO_WARM,
	fireHeatFactor = 1,
	oxygenLoss = 0,
	swimSpeed = 1,
	regenHeal = nil,
	hidesName = false,
	explorer = false,
	hungerFactor = 1,
	thirstFactor = 1,
}) :: Modifiers

local function warmOf(warm: Types.ArmorWarm?): Warm
	if warm == nil then
		return NO_WARM
	end
	return {
		day = warm.day or 0,
		night = warm.night or 0,
		waterDay = warm.waterDay or 0,
		waterNight = warm.waterNight or 0,
		winterDay = warm.winterDay or 0,
		winterNight = warm.winterNight or 0,
		lavaDay = warm.lavaDay or 0,
		lavaNight = warm.lavaNight or 0,
	}
end

-- Modificadores de um item (nil ou sem bloco armor = NONE).
function ArmorRules.modifiers(def: Types.ItemDef?): Modifiers
	local armor = def and def.armor
	if armor == nil then
		return ArmorRules.NONE
	end
	return {
		defense = armor.defense or 0,
		mobDefense = armor.mobDefense or 0,
		warm = warmOf(armor.warm),
		fireHeatFactor = armor.fireHeatFactor or 1,
		oxygenLoss = armor.oxygenLoss or 0,
		swimSpeed = armor.swimSpeed or 1,
		regenHeal = armor.regenHeal,
		hidesName = armor.hidesName == true,
		explorer = armor.explorer == true,
		hungerFactor = armor.hungerFactor or 1,
		thirstFactor = armor.thirstFactor or 1,
	}
end

-- Todo golpe causa pelo menos 25% do dano original (decisão do Elizeu, 19/11).
ArmorRules.MIN_DAMAGE_SHARE = 0.25

-- Golpe depois da defesa: `math.max(amount - defense, amount * MIN_DAMAGE_SHARE)`,
-- e 0 só quando `amount <= 0`. `held` = o que o atingido tem na mão: um escudo
-- soma a defesa dele.
function ArmorRules.reduce(amount: number, mods: Modifiers, source: HitSource, held: Types.ItemDef?): number
	if not (amount > 0) then
		return 0
	end
	local defense = if source == "mob" then mods.mobDefense else mods.defense
	local shield = held and held.shield
	if shield then
		defense += if source == "mob" then shield.mobDefense else shield.defense
	end
	return math.max(amount - defense, amount * ArmorRules.MIN_DAMAGE_SHARE)
end

-- Quanto a NOSSA perda de frio é multiplicada com a peça no lugar e hora:
-- (base − warm) / base, com a base do Starve. 1 = normal, 0 = não perde,
-- negativo = esquenta nessa proporção.
function ArmorRules.coldMultiplier(mods: Modifiers, place: ColdPlace, isNight: boolean): number
	local base = C.STARVE_COLD_LOSS[place]
	local loss = if isNight then base.night else base.day
	local warm = mods.warm
	local value = if place == "water"
		then (if isNight then warm.waterNight else warm.waterDay)
		elseif place == "winter" then (if isNight then warm.winterNight else warm.winterDay)
		else (if isNight then warm.night else warm.day)
	return (loss - value) / loss
end

-- Quanto a queda do fôlego na água é multiplicada (0 a 1).
function ArmorRules.oxygenFactor(mods: Modifiers): number
	return math.max(C.STARVE_OXYGEN_LOSS - mods.oxygenLoss, 0) / C.STARVE_OXYGEN_LOSS
end

-- Quanto a regeneração da vida é multiplicada.
function ArmorRules.regenFactor(mods: Modifiers): number
	return (mods.regenHeal or C.STARVE_REGEN_HEAL) / C.STARVE_REGEN_HEAL
end

-- Pode vestir outra peça? `lockUntil` = instante gravado ao vestir a última
-- (SurvivalConfig.ARMOR_SWAP_LOCK depois); nil = sem trava.
function ArmorRules.canSwap(lockUntil: number?, now: number): boolean
	return lockUntil == nil or now >= lockUntil
end

-- Instante em que o explorador volta a esconder quem bateu em algo agora.
-- Vale com QUALQUER peça (bater sem o chapéu e vestir logo depois não esconde
-- de quem apanhou).
function ArmorRules.hitOffUntil(now: number): number
	return now + C.EXPLORER_OFF
end

-- Explorador ligado: a peça tem `explorer` e o dono não bateu em nada há
-- pouco (`offUntil` = instante em que o efeito volta; nil = nunca bateu).
function ArmorRules.isStealthy(mods: Modifiers, offUntil: number?, now: number): boolean
	return mods.explorer and (offUntil == nil or now >= offUntil)
end

return ArmorRules
