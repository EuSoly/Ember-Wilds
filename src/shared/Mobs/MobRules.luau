--!strict
-- Regras puras dos mobs (sem API do Roblox, para o Lune testar). Os números
-- são do spec da G5; a IA (servidor) só consome estas constantes.
local Types = require("../Defs/Types")

type ItemDef = Types.ItemDef

local MobRules = {
	SENSE_RADIUS = 18, -- distância em que o mob agressivo enxerga o jogador (studs)
	FLEE_RADIUS = 14, -- distância em que o passivo foge
	FLEE_AFTER_HIT = 3, -- segundos de fuga depois de apanhar
	GIVE_UP = 10, -- segundos sem o alvo bater: desiste da perseguição
	CALM_TIME = 5, -- segundos depois de desistir sem perseguir ninguém sozinho
	BITE_INTERVAL = 1.5, -- segundos entre mordidas
	BITE_REACH = 2, -- folga além dos raios para morder
	HAND_DAMAGE = 5, -- golpe sem item de dano
	WANDER_RADIUS = 20,
	WANDER_SPEED = 0.4, -- fração da velocidade ao andar à toa
	WANDER_SLACK = 3, -- segundos além do tempo de viagem até desistir de um ponto inalcançável
	FLY_TIME = { 4, 10 }, -- segundos voando (sorteio min, max)
	GROUND_TIME = { 4, 10 }, -- segundos andando
	LAND_RANGE = 8, -- raio para escolher onde pousar
	SPAWN_PLAYER_GAP = 60, -- distância mínima de jogador ao nascer
	SPAWN_STRUCTURE_GAP = 30, -- distância mínima de construção ao nascer
	RESPAWN_DELAY = 30, -- segundos para repor um mob morto
	DEATH_REMOVE = 0.6, -- segundos entre a morte e a remoção do modelo
	TICK = 0.1, -- passo da IA (s)
}

-- Dano do golpe em mob: o do item, ou o de mão.
-- Dano do golpe com `item` na mão (nil = mão). `armor` = peça de cabeça de
-- quem bate: com o mesmo conjunto da arma (gearBonus), soma o bônus.
function MobRules.damageOf(item: ItemDef?, armor: ItemDef?): number
	if item == nil or type(item.mobDamage) ~= "number" then
		return MobRules.HAND_DAMAGE
	end
	local damage = item.mobDamage
	local bonus = item.gearBonus
	local worn = armor and armor.armor
	if bonus and worn and worn.gearSet == bonus.set then
		damage += bonus.damage
	end
	return damage
end

-- Teia por instante absoluto: número e ainda no prazo. NaN, nil e texto não prendem.
function MobRules.isWebbed(untilTime: any, now: number): boolean
	return type(untilTime) == "number" and now < untilTime
end

return table.freeze(MobRules)
