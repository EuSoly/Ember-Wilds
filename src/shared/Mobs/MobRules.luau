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
	BITE_INTERVAL = 1, -- segundos entre mordidas
	BITE_REACH = 2, -- folga além dos raios para morder
	HAND_DAMAGE = 5, -- golpe sem item de dano
	WANDER_RADIUS = 20,
	WANDER_SPEED = 0.4, -- fração da velocidade ao andar à toa
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
function MobRules.damageOf(item: ItemDef?): number
	if item ~= nil and type(item.mobDamage) == "number" then
		return item.mobDamage
	end
	return MobRules.HAND_DAMAGE
end

-- Teia por instante absoluto: número e ainda no prazo. NaN, nil e texto não prendem.
function MobRules.isWebbed(untilTime: any, now: number): boolean
	return type(untilTime) == "number" and now < untilTime
end

return table.freeze(MobRules)
