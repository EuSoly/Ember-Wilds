--!strict
-- Crescimento das plantas (puro, testado no Lune em tests/plant.spec.luau).
-- Os números de cada cultura ficam no bloco `structure.plant` da semente
-- (Defs/Items, config oficial do Starve); quem guarda o estado e chama o passo
-- é o FarmService.
--
-- A planta nasce seca e só cresce molhada. A rega (Water) vive no canteiro
-- quando a planta está num, ou na própria planta no chão: dura
-- `waterSeconds` e guarda o bônus de quem regou (cropGrowth da túnica). No
-- canteiro tudo anda PLOT_SPEED vezes mais rápido. Madura, conta para o
-- próximo fruto até `maxFruit`. Morre aos `lifeSeconds` de idade.
local Types = require("../Defs/Types")

export type State = {
	grown: number, -- 0 a 1 (1 = madura)
	fruit: number, -- frutos prontos para colher
	fruitProgress: number, -- 0 a 1 até o próximo fruto
	bornAt: number, -- tempo do servidor em que foi plantada
}
export type Water = {
	wetUntil: number, -- tempo do servidor em que a rega acaba
	speed: number, -- bônus de quem regou (cropGrowth da túnica; 1 = nenhum)
}
export type Circle = { x: number, z: number, radius: number }

local PlantRules = {}

-- Canteiro: crescimento e frutos 2x mais rápidos (wiki: trigo 16 s → 8 s).
PlantRules.PLOT_SPEED = 2
-- Fração de crescimento em que cada estágio começa (stage_02 e stage_03); madura = stage_04.
PlantRules.STAGES = 4

function PlantRules.new(now: number): State
	return { grown = 0, fruit = 0, fruitProgress = 0, bornAt = now }
end

function PlantRules.newWater(): Water
	return { wetUntil = -math.huge, speed = 1 }
end

function PlantRules.isWet(water: Water, now: number): boolean
	return now < water.wetUntil
end

-- Rega agora: dura `waterSeconds` a partir de `now` e passa a usar o bônus de
-- quem regou (nil = sem túnica).
function PlantRules.water(water: Water, def: Types.PlantDef, now: number, cropGrowth: number?)
	water.wetUntil = now + def.waterSeconds
	water.speed = if type(cropGrowth) == "number" and cropGrowth > 0 then cropGrowth else 1
end

-- Avança a planta do instante `now - dt` até `now`. Só conta a parte do passo
-- em que estava molhada.
function PlantRules.step(state: State, def: Types.PlantDef, now: number, dt: number, water: Water, onPlot: boolean)
	if not (dt > 0) then
		return
	end
	local wetSeconds = math.clamp(water.wetUntil - (now - dt), 0, dt)
	if wetSeconds <= 0 then
		return
	end
	local rate = water.speed * (if onPlot then PlantRules.PLOT_SPEED else 1)
	-- Tempo efetivo (já com o bônus) que sobra para crescer e dar fruto.
	local budget = wetSeconds * rate
	if state.grown < 1 then
		local need = (1 - state.grown) * def.growSeconds
		if budget < need then
			state.grown += budget / def.growSeconds
			return
		end
		state.grown = 1
		budget -= need
	end
	if state.fruit >= def.maxFruit then
		state.fruitProgress = 0
		return
	end
	state.fruitProgress += budget / def.fruitSeconds
	while state.fruitProgress >= 1 and state.fruit < def.maxFruit do
		state.fruit += 1
		state.fruitProgress -= 1
	end
	if state.fruit >= def.maxFruit then
		state.fruitProgress = 0
	end
end

-- Estágio do modelo (1 a 4): três partes iguais do crescimento e a madura.
function PlantRules.stage(state: State): number
	if state.grown >= 1 then
		return PlantRules.STAGES
	end
	return math.clamp(math.floor(state.grown * (PlantRules.STAGES - 1)) + 1, 1, PlantRules.STAGES - 1)
end

function PlantRules.isMature(state: State): boolean
	return state.grown >= 1
end

-- Planta com espinho (arbusto) só machuca madura.
function PlantRules.hurts(state: State): boolean
	return PlantRules.isMature(state)
end

function PlantRules.isDead(state: State, def: Types.PlantDef, now: number): boolean
	return now - state.bornAt >= def.lifeSeconds
end

-- Frutos colhidos por golpe com `tool` na mão: o `harvest` do item (forcados)
-- ou 1.
function PlantRules.harvestOf(tool: Types.ItemDef?): number
	local harvest = tool and tool.harvest
	if type(harvest) == "number" and harvest >= 1 then
		return math.floor(harvest)
	end
	return 1
end

-- Tira até `amount` frutos da planta; devolve quantos saíram.
function PlantRules.harvest(state: State, amount: number): number
	local taken = math.clamp(math.floor(amount), 0, state.fruit)
	state.fruit -= taken
	return taken
end

-- Índice do canteiro cujo círculo contém (x, z), o de centro mais perto; nil = nenhum.
function PlantRules.plotAt(x: number, z: number, plots: { Circle }): number?
	local best: number? = nil
	local bestDistance = math.huge
	for index, plot in plots do
		local dx, dz = x - plot.x, z - plot.z
		local distance = dx * dx + dz * dz
		if distance <= plot.radius * plot.radius and distance < bestDistance then
			best, bestDistance = index, distance
		end
	end
	return best
end

-- Semente fora de canteiro: só no chão da floresta (nem água, nem areia, nem
-- fora do mapa jogável).
function PlantRules.groundAllows(isWater: boolean, isSand: boolean, inPlayable: boolean): boolean
	return inPlayable and not isWater and not isSand
end

return PlantRules
