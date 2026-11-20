--!strict
-- Um bot vivo (BotService; spec 2026-11-20-bots-design): inventário, barras e
-- pontos próprios, com as mesmas regras do jogador (SurvivalRules, CraftRules,
-- GatherRules, MobRules, ArmorRules). O cérebro puro (BotBrain) escolhe o
-- objetivo; aqui ele vira alvo, passos e golpes no mundo de verdade:
-- - coleta tira recurso real (ResourceService.take) com o efeito de golpe;
-- - fogueira e bancada são peças reais (StructureService.placeForBot);
-- - leva golpe de jogador e mordida de mob pelo CharacterService.hurt
--   (onNonPlayerHurt → Actor.hurt); revida só quem provocou (BotRules);
-- - morte: caixa com o inventário e o bônus de kill de sempre a quem matou.
-- A sede não é simulada (fica cheia): ninguém vê, e achar água no mapa não
-- vale o custo. Nada do bot é salvo.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.Shared
local ArmorRules = require(Shared.Survival.ArmorRules)
local BotBrain = require(Shared.Bots.BotBrain)
local BotRules = require(Shared.Bots.BotRules)
local BuildRules = require(Shared.Build.BuildRules)
local CrateRules = require(Shared.Crate.CrateRules)
local Defs = require(Shared.Defs)
local GatherRules = require(Shared.Gather.GatherRules)
local HeldItem = require(Shared.HeldItem)
local Inventory = require(Shared.Inventory)
local MobMove = require(Shared.Mobs.MobMove)
local MobRules = require(Shared.Mobs.MobRules)
local StatNames = require(Shared.StatNames)
local SurvivalConfig = require(Shared.SurvivalConfig)
local SurvivalRules = require(Shared.Survival.SurvivalRules)
local WaterSim = require(Shared.Simulation.WaterSim)
local WorldConfig = require(Shared.WorldConfig)
local Services = script.Parent.Parent
local CharacterService = require(Services.CharacterService)
local CosmeticService = require(Services.CosmeticService)
local CrateService = require(Services.CrateService)
local GatherService = require(Services.GatherService)
local MapService = require(Services.MapService)
local MobService = require(Services.MobService)
local ResourceService = require(Services.ResourceService)
local ScoreService = require(Services.ScoreService)
local StructureService = require(Services.StructureService)
local SurvivalService = require(Services.SurvivalService)
local Body = require(script.Parent.Body)

local CAPACITY = 16 -- slots do inventário do bot (como um jogador com mochila pequena)
local CRAFT_RANGE = 8 -- studs até a estação (bancada/fogo) para craftar
local FIRE_SEEK = 50 -- fogueira até essa distância: vai até ela em vez de fazer outra
local FIRE_STOP = 3 -- para a essa distância do centro da fogueira (dentro do calor)
local THREAT_RADIUS = 16 -- mob perigoso até essa distância
local PROVOKE_REACH = 40 -- provocador mais longe que isso: a briga acaba
local PROVOKE_SECONDS = 10 -- quanto tempo a briga dura depois do último golpe dele
local SEARCH_RADII = { 40, 90, 160 } -- busca de recurso, do perto para o longe
local HUNT_RADIUS = 80
local WANDER_RADIUS = 25
local FLEE_DISTANCE = 30
local AVOID_SECONDS = 20 -- recurso em que travou fica de lado esse tempo
local PLACE_DISTANCE = 3.5 -- fogueira/bancada a essa distância à frente
local BODY_RADIUS = BuildRules.PLAYER_RADIUS
local LOOT_RADIUS = 5 -- caixa do mob que o bot matou: até essa distância do mob
local ARRIVE_SLACK = 0.5 -- chegou se está até isso além do ponto de parada
local PLAYER_SPACE = 6 -- não disputa recurso com jogador a menos disso dele

local HAND_DAMAGE = MobRules.damageOf(nil, nil)

export type Target = {
	kind: "point" | "resource" | "mob" | "character",
	x: number,
	z: number,
	stop: number, -- para de andar a essa distância
	resource: ResourceService.Entry?,
	mob: MobService.Mob?,
	character: Model?,
	fire: StructureService.Entry?, -- "warm": a fogueira para onde vai
}

export type Bot = {
	id: number,
	name: string,
	owner: StructureService.BotOwner,
	model: Model,
	root: BasePart,
	x: number,
	z: number,
	facing: Vector3,
	inv: Inventory.Inventory,
	bars: SurvivalRules.Bars,
	score: number,
	provoke: BotRules.Provoke,
	provoker: Player?,
	provokedUntil: number,
	goal: BotBrain.Goal,
	target: Target?,
	bestDistance: number,
	progressAt: number,
	avoid: { [any]: number }, -- recurso → os.clock() até quando evitar
	craft: { recipe: Defs.RecipeDef, endsAt: number }?,
	placeAfterCraft: string?,
	nextHit: number?,
	nextThink: number,
	dead: boolean,
	rng: Random,
}

local Actor = {}

-- ===== Inventário e equipamento =====

local function maxStackOf(id: string): number
	local def = Defs.Items[id]
	return if def then def.maxStack else 1
end

function Actor.counts(bot: Bot): { [string]: number }
	local counts: { [string]: number } = {}
	for _, slot in bot.inv.slots do
		counts[slot.id] = (counts[slot.id] or 0) + slot.count
	end
	return counts
end

-- Põe no inventário; devolve quanto coube.
local function addItem(bot: Bot, id: string, count: number): number
	local left = Inventory.add(bot.inv, id, count, maxStackOf(id))
	return count - left
end

-- O id do inventário com a maior nota (nil se nenhum tem nota).
local function best(bot: Bot, score: (Defs.ItemDef) -> number?): string?
	local bestId, bestScore = nil, -math.huge
	for id in Actor.counts(bot) do
		local def = Defs.Items[id]
		local value = if def then score(def) else nil
		if value and value > bestScore then
			bestId, bestScore = id, value
		end
	end
	return bestId
end

local function weaponOf(bot: Bot): string?
	return best(bot, function(def)
		local damage = MobRules.damageOf(def, nil)
		return if damage > HAND_DAMAGE then damage else nil
	end)
end

local function toolFor(bot: Bot, gather: Defs.GatherDef): string?
	-- Só ferramenta de verdade (picareta); sem ela, mão vazia (como o jogador).
	return best(bot, function(def)
		return if def.pickaxe then GatherRules.yield(def, gather) else nil
	end)
end

local function armorDef(bot: Bot): Defs.ItemDef?
	local id = bot.model:GetAttribute(StatNames.Armor)
	return if type(id) == "string" then Defs.Items[id] else nil
end

local function heldDef(bot: Bot): Defs.ItemDef?
	local id = bot.model:GetAttribute(StatNames.Equipped)
	return if type(id) == "string" then Defs.Items[id] else nil
end

local function equip(bot: Bot, id: string?)
	Body.set(bot.model, StatNames.Equipped, id)
end

-- Peça de cabeça: a melhor que tem (veste sozinho, como quem acabou de craftar).
local function wearBest(bot: Bot)
	local id = best(bot, function(def)
		if def.category ~= "armor" then
			return nil
		end
		local mods = ArmorRules.modifiers(def)
		return mods.defense + mods.mobDefense
	end)
	Body.set(bot.model, StatNames.Armor, id)
end

-- ===== Pontos =====

local function addScore(bot: Bot, points: number)
	bot.score = BotRules.addScore(bot.score, points)
	Body.set(bot.model, StatNames.BotScore, math.floor(bot.score))
end

-- ===== Mundo =====

local function serverNow(): number
	return Workspace:GetServerTimeNow()
end

local function blocked(x: number, z: number): boolean
	return MapService.isBlockedAt(x, z) or WaterSim.isWaterAt(x, z)
end

local function distance(ax: number, az: number, bx: number, bz: number): number
	local dx, dz = ax - bx, az - bz
	return math.sqrt(dx * dx + dz * dz)
end

local function rootOf(character: Model?): BasePart?
	if character == nil or character.Parent == nil or character:FindFirstChildOfClass("Humanoid") == nil then
		return nil
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

-- Círculos que seguram o bot (como os mobs: peças sólidas, recursos, mobs no
-- chão e jogadores).
local function circlesAround(bot: Bot, reach: number): { MobMove.Circle }
	local circles: { MobMove.Circle } = {}
	for _, entry in StructureService.near(bot.x, bot.z, reach) do
		if BuildRules.blocksBodies(entry.def.kind) and entry.model:GetAttribute(StatNames.DoorOpen) ~= true then
			table.insert(circles, { x = entry.x, z = entry.z, radius = entry.radius })
		end
	end
	for _, entry in ResourceService.near(bot.x, bot.z, reach + 6) do
		table.insert(circles, { x = entry.x, z = entry.z, radius = entry.radius })
	end
	for _, mob in MobService.near(bot.x, bot.z, reach) do
		if not mob.dead and not mob.flying then
			table.insert(circles, { x = mob.x, z = mob.z, radius = mob.radius })
		end
	end
	for _, player in Players:GetPlayers() do
		local root = rootOf(player.Character)
		if root and distance(root.Position.X, root.Position.Z, bot.x, bot.z) <= reach + BODY_RADIUS then
			table.insert(circles, { x = root.Position.X, z = root.Position.Z, radius = BODY_RADIUS })
		end
	end
	return circles
end

local function pointNear(bot: Bot, radius: number): (number, number)
	for _ = 1, 8 do
		local angle = bot.rng:NextNumber() * 2 * math.pi
		local r = radius * (0.4 + 0.6 * bot.rng:NextNumber())
		local x, z = bot.x + math.cos(angle) * r, bot.z + math.sin(angle) * r
		if not blocked(x, z) then
			return x, z
		end
	end
	return bot.x, bot.z
end

-- ===== Foto para o cérebro =====

local function bestFood(counts: { [string]: number }): string?
	local found, hunger = nil, 0
	for id in counts do
		local def = Defs.Items[id]
		local food = def and def.food
		if food and (food.hunger or 0) > hunger then
			found, hunger = id, food.hunger or 0
		end
	end
	return found
end

local function nearestFire(bot: Bot, radius: number): StructureService.Entry?
	local found, bestD = nil, math.huge
	for _, entry in StructureService.near(bot.x, bot.z, radius) do
		if entry.def.kind == "fire" and (bot.avoid[entry] or 0) < os.clock() then
			local d = distance(entry.x, entry.z, bot.x, bot.z)
			if d < bestD then
				found, bestD = entry, d
			end
		end
	end
	return found
end

local function threatOf(bot: Bot): MobService.Mob?
	local found, bestD = nil, math.huge
	for _, mob in MobService.near(bot.x, bot.z, THREAT_RADIUS) do
		if not mob.dead and mob.hostile and mob.stats.bite ~= nil then
			local d = distance(mob.x, mob.z, bot.x, bot.z)
			if d < bestD then
				found, bestD = mob, d
			end
		end
	end
	return found
end

local function activeProvoker(bot: Bot, now: number): (Player?, BasePart?)
	local player = bot.provoker
	if player == nil or now > bot.provokedUntil or player.Parent ~= Players then
		return nil, nil
	end
	local root = rootOf(player.Character)
	if root == nil or distance(root.Position.X, root.Position.Z, bot.x, bot.z) > PROVOKE_REACH then
		return nil, nil
	end
	return player, root
end

-- Tempo sem chegar mais perto do alvo; parado no alvo (na fogueira, batendo
-- na árvore) não conta como travado.
local function stuckSeconds(bot: Bot): number
	local target = bot.target
	if target == nil or distance(target.x, target.z, bot.x, bot.z) <= target.stop + ARRIVE_SLACK then
		return 0
	end
	return os.clock() - bot.progressAt
end

function Actor.snapshot(bot: Bot, now: number): BotBrain.Snapshot
	local counts = Actor.counts(bot)
	local nearStation: { [string]: boolean } = {}
	for _, entry in StructureService.near(bot.x, bot.z, CRAFT_RANGE) do
		local station = entry.def.station
		if station then
			nearStation[station] = true
		end
	end
	local near = SurvivalService.fireAround(bot.root.Position)
	local provoker = activeProvoker(bot, now)
	return {
		health = bot.bars.health,
		hunger = bot.bars.hunger,
		cold = bot.bars.cold,
		isNight = SurvivalService.isNight(),
		nearFire = near,
		fireNearby = nearestFire(bot, FIRE_SEEK) ~= nil,
		counts = counts,
		nearStation = nearStation,
		provoker = provoker,
		threat = threatOf(bot) ~= nil,
		hasWeapon = weaponOf(bot) ~= nil,
		food = bestFood(counts),
		stuckSeconds = stuckSeconds(bot),
	}
end

-- ===== Objetivos → alvo =====

-- O mesmo alvo de antes (o cérebro repensa a cada meio segundo): mantém a
-- conta de progresso, senão o bot travado nunca perceberia que travou.
local function sameTarget(a: Target?, b: Target?): boolean
	if a == nil or b == nil or a.kind ~= b.kind then
		return false
	end
	if a.kind == "point" then
		return math.abs(a.x - b.x) < 1 and math.abs(a.z - b.z) < 1
	end
	return a.resource == b.resource and a.mob == b.mob and a.character == b.character and a.fire == b.fire
end

local function setTarget(bot: Bot, target: Target?)
	local keep = sameTarget(bot.target, target)
	bot.target = target
	if not keep then
		bot.bestDistance = math.huge
		bot.progressAt = os.clock()
	end
end

-- Algum jogador vivo a menos de `radius` de (x, z)?
local function playerNear(x: number, z: number, radius: number): boolean
	for _, player in Players:GetPlayers() do
		local root = rootOf(player.Character)
		if root and distance(root.Position.X, root.Position.Z, x, z) <= radius then
			return true
		end
	end
	return false
end

local function findResource(bot: Bot, item: string): (ResourceService.Entry?, string?)
	local clock = os.clock()
	for _, radius in SEARCH_RADII do
		local found, tool, bestD = nil, nil, math.huge
		for _, entry in ResourceService.near(bot.x, bot.z, radius) do
			if
				entry.gather.item == item
				and entry.amount > 0
				and (bot.avoid[entry] or 0) < clock
				and not playerNear(entry.x, entry.z, entry.radius + PLAYER_SPACE)
			then
				local toolId = toolFor(bot, entry.gather)
				local toolDef = if toolId then Defs.Items[toolId] else nil
				if GatherRules.yield(toolDef, entry.gather) ~= nil then
					local d = distance(entry.x, entry.z, bot.x, bot.z)
					if d < bestD then
						found, tool, bestD = entry, toolId, d
					end
				end
			end
		end
		if found then
			return found, tool
		end
	end
	return nil, nil
end

local function wander(bot: Bot, radius: number)
	local x, z = pointNear(bot, radius)
	setTarget(bot, { kind = "point", x = x, z = z, stop = 1 })
end

local function startCraft(bot: Bot, recipeId: string): boolean
	local recipe = Defs.Recipes[recipeId]
	if recipe == nil or bot.craft ~= nil then
		return bot.craft ~= nil
	end
	local counts = Actor.counts(bot)
	for _, ingredient in recipe.ingredients do
		if (counts[ingredient.id] or 0) < ingredient.count then
			return false
		end
	end
	for _, ingredient in recipe.ingredients do
		Inventory.remove(bot.inv, ingredient.id, ingredient.count)
	end
	bot.craft = { recipe = recipe, endsAt = os.clock() + recipe.time }
	equip(bot, nil)
	Body.set(bot.model, StatNames.Using, false)
	setTarget(bot, nil)
	return true
end

-- Coloca à frente; se não cabe (recurso, peça, água), tenta em volta (8
-- direções) e vira para onde colocou.
local function place(bot: Bot, itemId: string)
	local base = math.atan2(bot.facing.Z, bot.facing.X)
	for i = 0, 7 do
		local angle = base + i * math.pi / 4
		local dir = Vector3.new(math.cos(angle), 0, math.sin(angle))
		local x, z = bot.x + dir.X * PLACE_DISTANCE, bot.z + dir.Z * PLACE_DISTANCE
		local yaw = math.deg(math.atan2(-dir.X, -dir.Z))
		if not blocked(x, z) and StructureService.placeForBot(bot.owner, itemId, x, z, yaw) then
			Inventory.remove(bot.inv, itemId, 1)
			bot.facing = dir
			return
		end
	end
	-- Nenhum lugar livre em volta: dá uns passos e tenta de novo.
	wander(bot, 8)
end

local function eat(bot: Bot, itemId: string)
	local def = Defs.Items[itemId]
	local food = def and def.food
	if food == nil then
		return
	end
	local after = SurvivalRules.eat(bot.bars, food)
	if after == nil or not Inventory.remove(bot.inv, itemId, 1) then
		return
	end
	bot.bars = after
	Body.set(bot.model, StatNames.EatUntil, serverNow() + SurvivalConfig.EAT_DURATION)
end

function Actor.think(bot: Bot, now: number)
	if bot.dead or bot.craft ~= nil then
		return
	end
	local decision = BotBrain.decide(Actor.snapshot(bot, now))
	-- Travado: o recurso, o bicho ou a fogueira atual fica de lado por um tempo.
	local stuckOn = bot.target and (bot.target.resource or bot.target.mob or bot.target.fire)
	if decision.goal == "wander" and stuckOn then
		bot.avoid[stuckOn] = os.clock() + AVOID_SECONDS
	end
	for key, untilAt in bot.avoid do
		if untilAt < os.clock() then
			bot.avoid[key] = nil
		end
	end
	local goal: BotBrain.Goal = decision.goal
	local item = decision.item
	bot.goal = goal
	if goal == "fight" then
		local player, root = activeProvoker(bot, now)
		local weapon = weaponOf(bot)
		equip(bot, weapon)
		if player and root then
			setTarget(bot, {
				kind = "character",
				x = root.Position.X,
				z = root.Position.Z,
				stop = GatherRules.HIT_REACH,
				character = player.Character,
			})
			return
		end
		local mob = threatOf(bot)
		if mob then
			setTarget(bot, { kind = "mob", x = mob.x, z = mob.z, stop = mob.radius + GatherRules.HIT_REACH, mob = mob })
		end
		return
	elseif goal == "flee" then
		local _, root = activeProvoker(bot, now)
		local mob = threatOf(bot)
		local fromX = if root then root.Position.X elseif mob then mob.x else bot.x
		local fromZ = if root then root.Position.Z elseif mob then mob.z else bot.z
		local away = Vector3.new(bot.x - fromX, 0, bot.z - fromZ)
		away = if away.Magnitude > 1e-3 then away.Unit else bot.facing
		setTarget(
			bot,
			{ kind = "point", x = bot.x + away.X * FLEE_DISTANCE, z = bot.z + away.Z * FLEE_DISTANCE, stop = 1 }
		)
		return
	elseif goal == "warm" then
		local fire = nearestFire(bot, FIRE_SEEK)
		equip(bot, weaponOf(bot))
		if fire then
			setTarget(bot, { kind = "point", x = fire.x, z = fire.z, stop = FIRE_STOP + fire.radius, fire = fire })
		else
			setTarget(bot, nil)
		end
		return
	elseif goal == "eat" and item then
		eat(bot, item)
		return
	elseif goal == "craft" and item then
		if not startCraft(bot, item) then
			wander(bot, WANDER_RADIUS)
		end
		return
	elseif goal == "place" and item then
		if Actor.counts(bot)[item] then
			place(bot, item)
		elseif startCraft(bot, item) then
			bot.placeAfterCraft = item
		end
		return
	elseif goal == "gather" and item then
		local entry, tool = findResource(bot, item)
		if entry then
			equip(bot, tool)
			setTarget(bot, {
				kind = "resource",
				x = entry.x,
				z = entry.z,
				stop = entry.radius + GatherRules.HIT_REACH - 0.5,
				resource = entry,
			})
		else
			wander(bot, WANDER_RADIUS * 2)
		end
		return
	elseif goal == "hunt" then
		local found, bestD = nil, math.huge
		for _, mob in MobService.near(bot.x, bot.z, HUNT_RADIUS) do
			if not mob.dead and not mob.flying and mob.stats.bite == nil and (bot.avoid[mob] or 0) < os.clock() then
				local d = distance(mob.x, mob.z, bot.x, bot.z)
				if d < bestD then
					found, bestD = mob, d
				end
			end
		end
		equip(bot, weaponOf(bot))
		if found then
			setTarget(bot, {
				kind = "mob",
				x = found.x,
				z = found.z,
				stop = found.radius + GatherRules.HIT_REACH - 0.5,
				mob = found,
			})
		else
			wander(bot, WANDER_RADIUS * 2)
		end
		return
	end
	wander(bot, WANDER_RADIUS)
end

-- ===== Passo: craft, andar, golpear =====

local function face(bot: Bot, x: number, z: number)
	local dir = Vector3.new(x - bot.x, 0, z - bot.z)
	if dir.Magnitude > 1e-3 then
		bot.facing = dir.Unit
	end
end

local function finishCraft(bot: Bot)
	local craft = bot.craft
	if craft == nil or os.clock() < craft.endsAt then
		return
	end
	bot.craft = nil
	addItem(bot, craft.recipe.result, craft.recipe.count)
	wearBest(bot)
	local placeId = bot.placeAfterCraft
	bot.placeAfterCraft = nil
	if placeId then
		place(bot, placeId)
	end
	bot.nextThink = 0
end

-- Caixas perto do mob antes do golpe (a de morte de um jogador, um item
-- largado): o bot só pega a caixa nova, a que o mob soltou ao morrer.
local function cratesNear(x: number, z: number): { [any]: boolean }
	local set: { [any]: boolean } = {}
	for _, crate in CrateService.near(x, z, LOOT_RADIUS) do
		set[crate] = true
	end
	return set
end

-- Pega a caixa que o mob soltou, se tudo cabe (senão deixa para quem passar).
local function lootNew(bot: Bot, x: number, z: number, before: { [any]: boolean })
	for _, crate in CrateService.near(x, z, LOOT_RADIUS) do
		if before[crate] then
			continue
		end
		local fits = true
		for _, item in crate.slots do
			if Inventory.spaceFor(bot.inv, item.id, maxStackOf(item.id)) < item.count then
				fits = false
			end
		end
		if fits then
			for _, item in CrateService.takeAll(crate) do
				addItem(bot, item.id, item.count)
			end
		end
	end
end

local function hit(bot: Bot, target: Target)
	local tool = heldDef(bot)
	if target.kind == "resource" then
		local entry = target.resource :: ResourceService.Entry
		local yield = GatherRules.yield(tool, entry.gather)
		if yield == nil or entry.amount <= 0 then
			bot.nextThink = 0
			return
		end
		local given = addItem(bot, entry.gather.item, math.min(yield, entry.amount))
		GatherService.resourceFx(entry, bot.x, bot.z)
		if given <= 0 then
			bot.nextThink = 0 -- inventário cheio: o cérebro decide outra coisa
			return
		end
		ResourceService.take(entry, given)
		addScore(bot, given * entry.gather.points)
		bot.progressAt = os.clock()
	elseif target.kind == "mob" then
		local mob = target.mob :: MobService.Mob
		if mob.dead then
			bot.nextThink = 0
			return
		end
		local before = cratesNear(mob.x, mob.z)
		MobService.damage(mob, MobRules.damageOf(tool, armorDef(bot)), nil)
		bot.progressAt = os.clock()
		if mob.dead then
			addScore(bot, mob.stats.points)
			lootNew(bot, mob.x, mob.z, before)
			bot.nextThink = 0
		end
	elseif target.kind == "character" then
		local character = target.character
		if character == nil or rootOf(character) == nil then
			bot.nextThink = 0
			return
		end
		CharacterService.hurt(
			character,
			MobRules.damageOf(tool, armorDef(bot)),
			"death.cause.player",
			"player",
			nil,
			bot.name
		)
		bot.progressAt = os.clock()
	end
end

-- Posição viva do alvo (mob e jogador andam).
local function refresh(target: Target): boolean
	if target.kind == "mob" then
		local mob = target.mob :: MobService.Mob
		if mob.dead then
			return false
		end
		target.x, target.z = mob.x, mob.z
	elseif target.kind == "character" then
		local root = rootOf(target.character)
		if root == nil then
			return false
		end
		target.x, target.z = root.Position.X, root.Position.Z
	elseif target.kind == "resource" then
		local entry = target.resource :: ResourceService.Entry
		if entry.amount <= 0 or entry.model.Parent == nil then
			return false
		end
	end
	return true
end

-- Um passo do bot: craft terminando, andar até o alvo, golpear ao alcance.
-- Devolve o CFrame novo da raiz (o BotService move todos de uma vez).
function Actor.step(bot: Bot, dt: number): CFrame
	finishCraft(bot)
	local target = bot.target
	local using = false
	if target and bot.craft == nil then
		if not refresh(target) then
			setTarget(bot, nil)
			bot.nextThink = 0
		else
			local d = distance(target.x, target.z, bot.x, bot.z)
			if d < bot.bestDistance - 0.5 then
				bot.bestDistance = d
				bot.progressAt = os.clock()
			end
			if d > target.stop + ARRIVE_SLACK then
				local speed = WorldConfig.WALK_SPEED * HeldItem.speedFactor(heldDef(bot))
				local dirX, dirZ = target.x - bot.x, target.z - bot.z
				local stepLength = math.min(speed * dt, d - target.stop)
				local nx, nz = MobMove.step(
					bot.x,
					bot.z,
					dirX,
					dirZ,
					stepLength,
					BODY_RADIUS,
					circlesAround(bot, stepLength + 8),
					blocked
				)
				if nx ~= bot.x or nz ~= bot.z then
					face(bot, nx, nz)
				end
				bot.x, bot.z = nx, nz
			else
				face(bot, target.x, target.z)
				if target.kind ~= "point" then
					using = true
					local clock = os.clock()
					if bot.nextHit == nil or clock >= bot.nextHit then
						bot.nextHit = GatherRules.nextHit(bot.nextHit, clock)
						hit(bot, target)
					end
				elseif bot.goal == "wander" or bot.goal == "flee" then
					setTarget(bot, nil)
					bot.nextThink = 0
				end
			end
		end
	end
	Body.set(bot.model, StatNames.Using, using)
	local position = Vector3.new(bot.x, Body.ROOT_Y, bot.z)
	return CFrame.lookAt(position, position + bot.facing)
end

-- ===== Barras =====

function Actor.survive(bot: Bot, dt: number, night: boolean)
	if bot.dead then
		return
	end
	local near, on = SurvivalService.fireAround(bot.root.Position)
	bot.bars.thirst = StatNames.StatusMax
	local result = SurvivalRules.step(bot.bars, {
		isNight = night,
		inWater = false,
		nearFire = near,
		onFire = on,
		oxygen = StatNames.StatusMax,
		mods = ArmorRules.modifiers(armorDef(bot)),
		biomeColdFactor = SurvivalConfig.BIOME_COLD_FACTOR.forest,
		coldPlace = "forest",
		biomeHeat = SurvivalConfig.BIOME_HEAT.forest,
	}, dt)
	bot.bars = result.bars
	local cause = result.cause
	if result.damage > 0 and cause then
		CharacterService.hurt(bot.model, result.damage, SurvivalRules.CAUSE_KEYS[cause :: any], "survival")
	end
end

-- ===== Dano e morte =====

local function die(bot: Bot, killer: Player?)
	if bot.dead then
		return
	end
	bot.dead = true
	local items: { CrateService.Item } = {}
	for _, slot in bot.inv.slots do
		table.insert(items, { id = slot.id, count = slot.count })
	end
	local killerSkin = if killer and killer.Parent == Players then CosmeticService.equipped(killer, "crate") else nil
	local skin = CrateRules.skinFor(killerSkin, Defs.CosmeticSlots.crate.default)
	CrateService.spawn(bot.x, bot.z, items, skin, CrateRules.PLAYER_LIFETIME)
	-- Bônus de kill de sempre (com o teto dos pontos do bot, não vira farm).
	if killer and killer.Parent == Players and killer.Character ~= nil then
		ScoreService.add(killer, CrateRules.killBonus(bot.score))
	end
	-- A bancada some com ele; a fogueira apaga sozinha no tempo dela.
	StructureService.removeBotPieces(bot.owner, "fire")
	bot.model:Destroy()
end

-- O golpe do jogador era no bot ou no recurso do lado? (Golpe em área: quem
-- coleta na mesma árvore acerta o bot sem querer.) Refaz o centro do golpe
-- como o GatherService: da raiz, na direção em que olha, HIT_REACH + alcance.
local function aimedAt(bot: Bot, attacker: Player): boolean
	local character = attacker.Character
	local root = rootOf(character)
	if character == nil or root == nil then
		return true
	end
	local look = root.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	if flat.Magnitude < 1e-3 then
		return true
	end
	local equipped = character:GetAttribute(StatNames.Equipped)
	local held = if type(equipped) == "string" then Defs.Items[equipped] else nil
	local reach = GatherRules.HIT_REACH + HeldItem.reach(held)
	local dir = flat.Unit
	local px, pz = root.Position.X + dir.X * reach, root.Position.Z + dir.Z * reach
	local botDistance = math.max(distance(bot.x, bot.z, px, pz) - BODY_RADIUS, 0)
	local resourceDistance: number? = nil
	for _, entry in ResourceService.near(px, pz, GatherRules.HIT_RADIUS) do
		local d = math.max(distance(entry.x, entry.z, px, pz) - entry.radius, 0)
		if resourceDistance == nil or d < resourceDistance then
			resourceDistance = d
		end
	end
	return BotRules.aimedAtBot(botDistance, resourceDistance)
end

-- Dano vindo do CharacterService.hurt (golpe de jogador, mordida, barras).
function Actor.hurt(bot: Bot, amount: number, kind: string, attacker: Player?)
	if bot.dead then
		return
	end
	if kind ~= "survival" then
		amount = ArmorRules.reduce(amount, ArmorRules.modifiers(armorDef(bot)), kind :: any, heldDef(bot))
		if amount <= 0 then
			return
		end
	end
	local now = serverNow()
	if attacker and kind == "player" and aimedAt(bot, attacker) then
		BotRules.recordHit(bot.provoke, attacker, now)
		if BotRules.provoked(bot.provoke, attacker, now) then
			bot.provoker = attacker
			bot.provokedUntil = now + PROVOKE_SECONDS
			bot.nextThink = 0
		elseif bot.provoker == attacker then
			bot.provokedUntil = now + PROVOKE_SECONDS
		end
	elseif kind == "mob" then
		bot.nextThink = 0
	end
	bot.bars.health = math.max(bot.bars.health - amount, 0)
	if bot.bars.health <= 0 then
		die(bot, if kind == "player" then attacker else nil)
	end
end

-- ===== Nascer e sair =====

function Actor.new(id: number, name: string, x: number, z: number, rng: Random): Bot
	local model, root = Body.build(name, id, x, z, rng)
	local angle = rng:NextNumber() * 2 * math.pi
	return {
		id = id,
		name = name,
		owner = { UserId = id, Name = name },
		model = model,
		root = root,
		x = x,
		z = z,
		facing = Vector3.new(math.cos(angle), 0, math.sin(angle)),
		inv = Inventory.new(CAPACITY),
		bars = SurvivalRules.full(),
		score = 0,
		provoke = {},
		provoker = nil,
		provokedUntil = 0,
		goal = "wander",
		target = nil,
		bestDistance = math.huge,
		progressAt = os.clock(),
		avoid = {},
		craft = nil,
		placeAfterCraft = nil,
		nextHit = nil,
		-- Cada um começa a pensar num instante diferente (não andam em sincronia).
		nextThink = os.clock() + rng:NextNumber(),
		dead = false,
		rng = rng,
	}
end

-- Sai do jogo (sobrou bot): some com o corpo e as peças dele.
function Actor.remove(bot: Bot)
	bot.dead = true
	StructureService.removeBotPieces(bot.owner, nil)
	if bot.model.Parent then
		bot.model:Destroy()
	end
end

return Actor
