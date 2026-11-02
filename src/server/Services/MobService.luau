--!strict
-- Os mobs de verdade (G5). Cada mob é uma raiz invisível ancorada (contrato de
-- docs/guia/mobs-modelos.md, "Raiz no servidor", mais MobFlying) que o cliente
-- desenha; a posição, a vida e o cérebro ficam aqui, num índice espacial só do
-- servidor (SpatialGrid).
-- - Passo (MobRules.TICK): para cada mob vivo, os jogadores vivos no bioma dele
--   viram `nearest`/`target` do MobBrain.think; a intenção anda com
--   MobMove.step entre os círculos de peças (porta aberta não conta), recursos,
--   outros mobs no chão e jogadores, sem entrar na água nem sair do bioma
--   (voando: só o bioma). Mordida = CharacterService.hurt de combate (causa =
--   nome do mob) e MobAttack += 1; teia = WebbedUntil no personagem (instante
--   absoluto, renova sem somar). Mob sem jogador a FAR_RADIUS pensa a cada
--   FAR_EVERY. Atributos só são escritos quando mudam.
-- - Dano (hit = golpe do jogador; damage = genérico, ex. espinho sem pontos):
--   MobHurt += 1, MobBrain.onHit se tem atacante; vida 0 = MobDead, pontos a
--   quem matou (uma vez só), ouvintes de onDeath (gancho da caixa de drop), a
--   raiz some depois de MobRules.DEATH_REMOVE e a vaga esfria por
--   MobRules.RESPAWN_DELAY.
-- - População (POPULATION_EVERY): MobSpawn.diff entre a meta do período
--   (dia/noite) e vivos + vagas esfriando, por bioma. Falta: nasce até
--   SPAWN_PER_TYPE de cada tipo por rodada, em ponto livre (fora da água, sem
--   encostar em recurso ou mob, longe de jogadores e de construções). Sobra:
--   some uma vaga esfriando, ou um mob longe de todos os jogadores (ninguém vê).
-- Só mexe nos mobs que criou: a galeria do Studio (DevMobService) também tem
-- raízes com a tag Mob.
-- Studio (barra de comandos do servidor):
-- - ServerStorage.DevSpawnMob:Invoke(player, "wolf"): cria a 12 studs à frente
--   (sem as distâncias de nascimento);
-- - ServerStorage.DevMobCount:Invoke(): contagem por tipo e a meta do período.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local BuildRules = require(ReplicatedStorage.Shared.Build.BuildRules)
local DayCycle = require(ReplicatedStorage.Shared.DayCycle)
local Defs = require(ReplicatedStorage.Shared.Defs)
local MobBrain = require(ReplicatedStorage.Shared.Mobs.MobBrain)
local MobMove = require(ReplicatedStorage.Shared.Mobs.MobMove)
local MobRules = require(ReplicatedStorage.Shared.Mobs.MobRules)
local MobSpawn = require(ReplicatedStorage.Shared.Mobs.MobSpawn)
local Rng = require(ReplicatedStorage.Shared.World.Rng)
local SpatialGrid = require(ReplicatedStorage.Shared.World.SpatialGrid)
local StatNames = require(ReplicatedStorage.Shared.StatNames)
local Types = require(ReplicatedStorage.Shared.Defs.Types)
local WaterSim = require(ReplicatedStorage.Shared.Simulation.WaterSim)
local WorldConfig = require(ReplicatedStorage.Shared.WorldConfig)
local CharacterService = require(script.Parent.CharacterService)
local ResourceService = require(script.Parent.ResourceService)
local ScoreService = require(script.Parent.ScoreService)
local StructureService = require(script.Parent.StructureService)

type MobDef = Defs.MobDef
type MobStats = Types.MobStats

local GRID_CELL = 16 -- studs por célula do índice espacial dos mobs
local POPULATION_EVERY = 2 -- segundos entre rodadas da população
local SPAWN_PER_TYPE = 2 -- no máximo nascem tantos de cada tipo por rodada
local SPAWN_TRIES = 20 -- tentativas de achar ponto livre por nascimento
-- Folga da busca de recursos: maior raio de colisão de um recurso (com variação).
local RESOURCE_SEARCH = 5
local FAR_RADIUS = 150 -- studs: sem jogador vivo a até isso, o mob pensa menos
local FAR_EVERY = 0.5 -- segundos entre passos do mob longe de todos
local MAX_DT = 1 -- segundos: teto do passo (servidor engasgado não teleporta o mob)
local DEV_SPAWN_DISTANCE = 12 -- studs à frente do jogador (DevSpawnMob)
local RAY_HEIGHT = 200 -- de onde desce o raio que acha o chão ao nascer
local RAY_LENGTH = 400
local FOLDER_NAME = "Mobs"

export type Mob = {
	id: string, -- tipo (chave de Defs.Mobs; também o atributo MobId)
	def: MobDef,
	stats: MobStats,
	root: Part,
	biome: string, -- chave de WorldConfig.BIOMES: o mob nunca sai dele
	rect: WorldConfig.Rect, -- o retângulo desse bioma
	x: number,
	z: number,
	y: number, -- chão (raycast ao nascer)
	radius: number, -- círculo do corpo (stats.radius)
	health: number,
	flying: boolean,
	dead: boolean, -- morto ou sumido: fora do índice, nada mais o afeta
	hostile: boolean,
	attacks: number, -- espelho de MobAttack
	hurts: number, -- espelho de MobHurt
	facing: Vector3, -- frente da raiz (unitária, no chão)
	brain: MobBrain.Brain,
	lastStep: number, -- os.clock() do último passo
	gridX: number, -- posição com que está no índice (para tirar de lá)
	gridZ: number,
}

-- Vaga de um mob morto, contando para a população até `untilAt` (os.clock()).
type Slot = { id: string, biome: string, untilAt: number }

-- Jogadores vivos de um bioma neste passo (`who` = o personagem).
type View = { list: { MobBrain.Seen }, byWho: { [any]: MobBrain.Seen } }

-- Biomas com tipo de dicionário (o frozen de WorldConfig não se deixa percorrer tipado).
local BIOMES: { [string]: WorldConfig.Rect } = WorldConfig.BIOMES :: any

local MobService = {}

local grid = SpatialGrid.new(GRID_CELL)
local alive: { [Mob]: boolean } = {}
local cooling: { Slot } = {}
local deathListeners: { (Mob, Player?) -> () } = {}
local rng = Rng.new(Random.new():NextInteger(0, 2 ^ 31 - 1))
local folder: Folder? = nil

-- Maior raio de mob nos dados: a busca no índice cresce por ele.
local maxRadius = 0
for _, def in Defs.Mobs do
	if def.stats then
		maxRadius = math.max(maxRadius, def.stats.radius)
	end
end

local function getFolder(): Folder
	local current = folder
	if current == nil or current.Parent == nil then
		local created = Instance.new("Folder")
		created.Name = FOLDER_NAME
		created.Parent = Workspace
		current = created
		folder = created
	end
	return current :: Folder
end

-- Raiz de um personagem vivo (montado, com Humanoid), ou nil.
local function rootOf(character: Model?): BasePart?
	if character == nil or character.Parent == nil or character:FindFirstChildOfClass("Humanoid") == nil then
		return nil
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end
	return nil
end

local function inRect(rect: WorldConfig.Rect, x: number, z: number): boolean
	return x >= rect.minX and x <= rect.maxX and z >= rect.minZ and z <= rect.maxZ
end

local function biomeAt(x: number, z: number): (string?, WorldConfig.Rect?)
	for biome, rect in BIOMES do
		if inRect(rect, x, z) then
			return biome, rect
		end
	end
	return nil, nil
end

local function isNight(): boolean
	local start = Workspace:GetAttribute(StatNames.CycleStart)
	if type(start) ~= "number" then
		return false
	end
	return DayCycle.at(Workspace:GetServerTimeNow() - start).isNight
end

-- Jogadores vivos agora (todos no chão: montaria ainda não existe).
local function livingBodies(): { MobBrain.Seen }
	local bodies: { MobBrain.Seen } = {}
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = rootOf(character)
		if character and root then
			table.insert(bodies, { who = character, x = root.Position.X, z = root.Position.Z })
		end
	end
	return bodies
end

local function viewOf(rect: WorldConfig.Rect, bodies: { MobBrain.Seen }): View
	local view: View = { list = {}, byWho = {} }
	for _, body in bodies do
		if inRect(rect, body.x, body.z) then
			table.insert(view.list, body)
			view.byWho[body.who] = body
		end
	end
	return view
end

local function distanceSq(ax: number, az: number, bx: number, bz: number): number
	return (ax - bx) ^ 2 + (az - bz) ^ 2
end

-- Mais perto de (x, z) na lista, e o quadrado da distância (math.huge sem ninguém).
local function closest(list: { MobBrain.Seen }, x: number, z: number): (MobBrain.Seen?, number)
	local best: MobBrain.Seen? = nil
	local bestSq = math.huge
	for _, body in list do
		local sq = distanceSq(x, z, body.x, body.z)
		if sq < bestSq then
			best, bestSq = body, sq
		end
	end
	return best, bestSq
end

-- Põe o mob no índice na posição atual (troca de célula só quando muda).
local function regrid(mob: Mob)
	local oldCellX, oldCellZ = math.floor(mob.gridX / GRID_CELL), math.floor(mob.gridZ / GRID_CELL)
	if oldCellX == math.floor(mob.x / GRID_CELL) and oldCellZ == math.floor(mob.z / GRID_CELL) then
		return
	end
	grid:remove(mob, mob.gridX, mob.gridZ)
	grid:insert(mob, mob.x, mob.z)
	mob.gridX, mob.gridZ = mob.x, mob.z
end

-- Tira o mob do mundo do servidor (morte ou sumiço): fora do índice e da lista.
local function retire(mob: Mob)
	mob.dead = true
	alive[mob] = nil
	grid:remove(mob, mob.gridX, mob.gridZ)
end

-- Círculos que seguram um corpo no chão perto de (x, z), até `reach` do centro:
-- peças (porta aberta não), recursos, outros mobs no chão e jogadores vivos.
local function circlesAround(
	mob: Mob,
	x: number,
	z: number,
	reach: number,
	bodies: { MobBrain.Seen }
): { MobMove.Circle }
	local circles: { MobMove.Circle } = {}
	for _, entry in StructureService.near(x, z, reach) do
		if entry.model:GetAttribute(StatNames.DoorOpen) ~= true then
			table.insert(circles, { x = entry.x, z = entry.z, radius = entry.radius })
		end
	end
	for _, entry in ResourceService.near(x, z, reach + RESOURCE_SEARCH) do
		table.insert(circles, { x = entry.x, z = entry.z, radius = entry.radius })
	end
	for _, item in grid:query(x, z, reach + maxRadius) do
		local other = item :: Mob
		if other ~= mob and not other.dead and not other.flying then
			table.insert(circles, { x = other.x, z = other.z, radius = other.radius })
		end
	end
	local bodyReach = reach + BuildRules.PLAYER_RADIUS
	for _, body in bodies do
		if distanceSq(x, z, body.x, body.z) <= bodyReach * bodyReach then
			table.insert(circles, { x = body.x, z = body.z, radius = BuildRules.PLAYER_RADIUS })
		end
	end
	return circles
end

-- O corpo do mob cabe no chão em (x, z): no bioma, fora da água, sem sobrepor nada.
local function groundFree(mob: Mob, x: number, z: number, bodies: { MobBrain.Seen }): boolean
	if not inRect(mob.rect, x, z) or WaterSim.isWet(x, z) then
		return false
	end
	for _, circle in circlesAround(mob, x, z, mob.radius, bodies) do
		if BuildRules.circlesOverlap(x, z, mob.radius, circle.x, circle.z, circle.radius) then
			return false
		end
	end
	return true
end

-- Ponto para nascer: fora da água, sem encostar em recurso ou mob, longe de
-- todo jogador (SPAWN_PLAYER_GAP) e de toda construção (SPAWN_STRUCTURE_GAP).
local function spawnFree(radius: number, x: number, z: number, bodies: { MobBrain.Seen }): boolean
	if WaterSim.isWet(x, z) then
		return false
	end
	local _, nearestSq = closest(bodies, x, z)
	if nearestSq < MobRules.SPAWN_PLAYER_GAP ^ 2 then
		return false
	end
	if #StructureService.near(x, z, MobRules.SPAWN_STRUCTURE_GAP) > 0 then
		return false
	end
	for _, entry in ResourceService.near(x, z, radius + RESOURCE_SEARCH) do
		if BuildRules.circlesOverlap(x, z, radius, entry.x, entry.z, entry.radius) then
			return false
		end
	end
	for _, item in grid:query(x, z, radius + maxRadius) do
		local other = item :: Mob
		if not other.dead and BuildRules.circlesOverlap(x, z, radius, other.x, other.z, other.radius) then
			return false
		end
	end
	return true
end

-- Altura do chão em (x, z): raio para baixo ignorando personagens, mobs e peças.
local function groundY(x: number, z: number): number
	local ignore: { Instance } = { getFolder() }
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(ignore, player.Character)
		end
	end
	local structures = Workspace:FindFirstChild("Structures")
	if structures then
		table.insert(ignore, structures)
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	local hit = Workspace:Raycast(Vector3.new(x, RAY_HEIGHT, z), Vector3.new(0, -RAY_LENGTH, 0), params)
	return if hit then hit.Position.Y else 0
end

local function spawnMob(def: MobDef, biome: string, rect: WorldConfig.Rect, x: number, z: number): Mob
	local stats = def.stats :: MobStats
	local y = groundY(x, z)
	local angle = rng:nextNumber() * 2 * math.pi
	local facing = Vector3.new(math.cos(angle), 0, math.sin(angle))
	local hostile = def.behavior == "aggressive"

	local root = Instance.new("Part")
	root.Name = def.id
	root.Size = Vector3.one
	root.Anchored, root.Transparency, root.CastShadow = true, 1, false
	root.CanCollide, root.CanTouch, root.CanQuery = false, false, false
	local position = Vector3.new(x, y, z)
	root.CFrame = CFrame.lookAt(position, position + facing)
	root:SetAttribute(StatNames.MobId, def.id)
	root:SetAttribute(StatNames.MobAttack, 0)
	root:SetAttribute(StatNames.MobHurt, 0)
	root:SetAttribute(StatNames.MobDead, false)
	root:SetAttribute(StatNames.MobHostile, hostile)
	root:SetAttribute(StatNames.MobFlying, false)
	root.Parent = getFolder()
	CollectionService:AddTag(root, StatNames.MobTag)

	local now = os.clock()
	local mob: Mob = {
		id = def.id,
		def = def,
		stats = stats,
		root = root,
		biome = biome,
		rect = rect,
		x = x,
		z = z,
		y = y,
		radius = stats.radius,
		health = stats.health,
		flying = false,
		dead = false,
		hostile = hostile,
		attacks = 0,
		hurts = 0,
		facing = facing,
		brain = MobBrain.new(def, x, z, now, rng),
		lastStep = now,
		gridX = x,
		gridZ = z,
	}
	alive[mob] = true
	grid:insert(mob, x, z)
	return mob
end

local function setFlying(mob: Mob, flying: boolean)
	if mob.flying ~= flying then
		mob.flying = flying
		mob.root:SetAttribute(StatNames.MobFlying, flying)
	end
end

local function setHostile(mob: Mob, hostile: boolean)
	if mob.hostile ~= hostile then
		mob.hostile = hostile
		mob.root:SetAttribute(StatNames.MobHostile, hostile)
	end
end

-- Mordida no personagem (que o cérebro escolheu no passo); teia antes do dano,
-- porque a mordida pode matar e o personagem some.
local function bite(mob: Mob, character: Model, web: boolean)
	local amount = mob.stats.bite
	if amount == nil or rootOf(character) == nil then
		return
	end
	mob.attacks += 1
	mob.root:SetAttribute(StatNames.MobAttack, mob.attacks)
	local webStats = mob.stats.web
	if web and webStats then
		character:SetAttribute(StatNames.WebbedUntil, Workspace:GetServerTimeNow() + webStats.duration)
	end
	CharacterService.hurt(character, amount, mob.def.nameKey, "combat")
end

-- Anda o que a intenção pede; devolve a nova CFrame da raiz, ou nil se nada mudou.
local function move(mob: Mob, intent: MobBrain.Intent, dt: number, bodies: { MobBrain.Seen }): CFrame?
	local hasDir = intent.dirX ~= 0 or intent.dirZ ~= 0
	local distance = intent.speed * dt
	local x, z = mob.x, mob.z
	if hasDir and distance > 0 then
		local rect = mob.rect
		local circles: { MobMove.Circle }
		local blocked: (number, number) -> boolean
		if mob.flying then
			-- Voando passa por cima de tudo; só não sai do bioma.
			circles = {}
			blocked = function(px: number, pz: number): boolean
				return not inRect(rect, px, pz)
			end
		else
			circles = circlesAround(mob, x, z, mob.radius + distance, bodies)
			blocked = function(px: number, pz: number): boolean
				return not inRect(rect, px, pz) or WaterSim.isWet(px, pz)
			end
		end
		x, z = MobMove.step(x, z, intent.dirX, intent.dirZ, distance, mob.radius, circles, blocked)
	end
	local facing = if hasDir then Vector3.new(intent.dirX, 0, intent.dirZ).Unit else mob.facing
	if x == mob.x and z == mob.z and facing == mob.facing then
		return nil
	end
	mob.x, mob.z, mob.facing = x, z, facing
	regrid(mob)
	local position = Vector3.new(x, mob.y, z)
	return CFrame.lookAt(position, position + facing)
end

local function step()
	local now = os.clock()
	local bodies = livingBodies()
	local views: { [string]: View } = {}
	local parts: { BasePart } = {}
	local frames: { CFrame } = {}
	-- Cópia da lista: se a mordida pausar (morte do jogador), quem nasce ou morre
	-- nesse meio-tempo não mexe na tabela que está sendo percorrida.
	local current: { Mob } = {}
	for mob in alive do
		table.insert(current, mob)
	end
	for _, mob in current do
		if mob.dead then
			continue
		end
		local dt = now - mob.lastStep
		local _, anySq = closest(bodies, mob.x, mob.z)
		if anySq > FAR_RADIUS * FAR_RADIUS and dt < FAR_EVERY then
			continue
		end
		mob.lastStep = now
		dt = math.min(dt, MAX_DT)

		local view = views[mob.biome]
		if view == nil then
			view = viewOf(mob.rect, bodies)
			views[mob.biome] = view
		end
		local nearest = closest(view.list, mob.x, mob.z)
		-- Alvo que morreu, renasceu (outro personagem) ou saiu do bioma = nil: o cérebro desiste.
		local brainTarget = mob.brain.target
		local target = if brainTarget ~= nil then view.byWho[brainTarget] else nil
		-- Só o voador precisa saber se pode pousar onde está.
		local canLand = mob.flying and groundFree(mob, mob.x, mob.z, bodies)

		local intent = MobBrain.think(mob.brain, mob.def, now, mob.x, mob.z, nearest, target, canLand, rng)
		setFlying(mob, intent.flying)
		setHostile(mob, intent.hostile)
		if intent.bite ~= nil then
			bite(mob, intent.bite :: Model, intent.web)
			if mob.dead then
				continue
			end
		end
		local frame = move(mob, intent, dt, bodies)
		if frame then
			table.insert(parts, mob.root)
			table.insert(frames, frame)
		end
	end
	if #parts > 0 then
		Workspace:BulkMoveTo(parts, frames, Enum.BulkMoveMode.FireCFrameChanged)
	end
end

local function die(mob: Mob, killer: Player?)
	retire(mob)
	mob.root:SetAttribute(StatNames.MobDead, true)
	table.insert(cooling, { id = mob.id, biome = mob.biome, untilAt = os.clock() + MobRules.RESPAWN_DELAY })
	if killer then
		ScoreService.add(killer, mob.stats.points)
	end
	for _, listener in deathListeners do
		local ok, err = pcall(listener :: any, mob, killer)
		if not ok then
			warn(`[MobService] onDeath: {err}`)
		end
	end
	local root = mob.root
	task.delay(MobRules.DEATH_REMOVE, function()
		root:Destroy()
	end)
end

-- Sobra de um tipo num bioma: primeiro as vagas esfriando (ninguém vê), depois
-- um mob vivo longe de todos os jogadores por rodada (some sem morrer).
local function trim(biome: string, id: string, excess: number, bodies: { MobBrain.Seen })
	for i = #cooling, 1, -1 do
		if excess <= 0 then
			return
		end
		local slot = cooling[i]
		if slot.biome == biome and slot.id == id then
			table.remove(cooling, i)
			excess -= 1
		end
	end
	if excess <= 0 then
		return
	end
	for mob in alive do
		if mob.biome == biome and mob.id == id then
			local _, nearestSq = closest(bodies, mob.x, mob.z)
			if nearestSq >= MobRules.SPAWN_PLAYER_GAP ^ 2 then
				retire(mob)
				mob.root:Destroy()
				return
			end
		end
	end
end

local function countsIn(biome: string): ({ [string]: number }, { [string]: number }, { [string]: number })
	local living: { [string]: number } = {}
	local slots: { [string]: number } = {}
	local total: { [string]: number } = {}
	for mob in alive do
		if mob.biome == biome then
			living[mob.id] = (living[mob.id] or 0) + 1
			total[mob.id] = (total[mob.id] or 0) + 1
		end
	end
	for _, slot in cooling do
		if slot.biome == biome then
			slots[slot.id] = (slots[slot.id] or 0) + 1
			total[slot.id] = (total[slot.id] or 0) + 1
		end
	end
	return living, slots, total
end

local function population()
	local now = os.clock()
	for i = #cooling, 1, -1 do
		if cooling[i].untilAt <= now then
			table.remove(cooling, i)
		end
	end
	local bodies = livingBodies()
	local night = isNight()
	for biome, rect in BIOMES do
		local _, _, counts = countsIn(biome)
		for id, delta in MobSpawn.diff(MobSpawn.targets(Defs.Mobs, biome, night), counts) do
			if delta < 0 then
				trim(biome, id, -delta, bodies)
				continue
			end
			local def = Defs.Mobs[id]
			local stats = def and def.stats
			if def == nil or stats == nil then
				continue
			end
			local function isFree(x: number, z: number): boolean
				return spawnFree(stats.radius, x, z, bodies)
			end
			for _ = 1, math.min(delta, SPAWN_PER_TYPE) do
				local x, z = MobSpawn.pick(rng, rect, isFree, SPAWN_TRIES)
				if x == nil or z == nil then
					break -- sem lugar livre agora: tenta de novo na próxima rodada
				end
				spawnMob(def, biome, rect, x, z)
			end
		end
	end
end

local function sortedKeys(...: { [string]: any }): { string }
	local seen: { [string]: boolean } = {}
	local keys: { string } = {}
	for _, map in { ... } do
		for key in map do
			if not seen[key] then
				seen[key] = true
				table.insert(keys, key)
			end
		end
	end
	table.sort(keys)
	return keys
end

local function devCount(): string
	local night = isNight()
	local lines = { if night then "noite" else "dia" }
	local biomes: { string } = {}
	for biome in BIOMES do
		table.insert(biomes, biome)
	end
	table.sort(biomes)
	for _, biome in biomes do
		local targets = MobSpawn.targets(Defs.Mobs, biome, night)
		local living, slots = countsIn(biome)
		for _, id in sortedKeys(targets, living, slots) do
			table.insert(
				lines,
				`{biome}/{id}: {living[id] or 0} vivos + {slots[id] or 0} esfriando, meta {targets[id] or 0}`
			)
		end
	end
	return table.concat(lines, "\n")
end

local function devSpawn(player: Player, id: string): string
	local def = Defs.Mobs[id]
	if def == nil or def.stats == nil then
		return `mob sem IA: {id}`
	end
	local root = rootOf(player.Character)
	if root == nil then
		return "jogador sem personagem"
	end
	local look = root.CFrame.LookVector * Vector3.new(1, 0, 1)
	look = if look.Magnitude > 1e-3 then look.Unit else Vector3.new(0, 0, -1)
	local x = root.Position.X + look.X * DEV_SPAWN_DISTANCE
	local z = root.Position.Z + look.Z * DEV_SPAWN_DISTANCE
	local biome, rect = biomeAt(x, z)
	if biome == nil or rect == nil then
		return "fora de bioma"
	end
	spawnMob(def, biome, rect, x, z)
	return `{id} criado`
end

local function newCommand(name: string, onInvoke: (...any) -> ...any)
	local command = Instance.new("BindableFunction")
	command.Name = name
	command.OnInvoke = onInvoke
	command.Parent = ServerStorage
end

local function loop(every: number, fn: () -> ())
	task.spawn(function()
		while true do
			task.wait(every)
			local ok, err = pcall(fn :: any)
			if not ok then
				warn(`[MobService] {err}`)
			end
		end
	end)
end

-- Mobs vivos (voando também) cujo círculo encosta no círculo (x, z, radius).
function MobService.near(x: number, z: number, radius: number): { Mob }
	local found: { Mob } = {}
	if not (radius >= 0) then
		return found
	end
	for _, item in grid:query(x, z, radius + maxRadius) do
		local mob = item :: Mob
		if not mob.dead and BuildRules.touchesCircle(x, z, mob.x, mob.z, mob.radius, radius) then
			table.insert(found, mob)
		end
	end
	return found
end

-- Dano genérico (espinho: attacker nil, sem pontos nem reação de perseguir).
-- Morto não apanha de novo: pontos e remoção só uma vez.
function MobService.damage(mob: Mob, amount: number, attacker: Player?)
	if mob.dead or not (amount > 0) then
		return
	end
	mob.health -= amount
	mob.hurts += 1
	mob.root:SetAttribute(StatNames.MobHurt, mob.hurts)
	if attacker then
		local character = attacker.Character
		local root = rootOf(character)
		if character and root then
			MobBrain.onHit(mob.brain, mob.def, character, root.Position.X, root.Position.Z, os.clock())
		end
	end
	if mob.health <= 0 then
		die(mob, attacker)
	end
end

-- Golpe do jogador com o item na mão (MobRules.damageOf). Quem está no chão
-- não acerta mob voando.
function MobService.hit(mob: Mob, attacker: Player, item: Defs.ItemDef?)
	if mob.dead or mob.flying then
		return
	end
	MobService.damage(mob, MobRules.damageOf(item), attacker)
end

-- Chamado (sem pausa, protegido) em toda morte, com quem deu o último golpe
-- (nil = espinho e afins). Gancho da caixa de drop.
function MobService.onDeath(listener: (mob: Mob, killer: Player?) -> ())
	table.insert(deathListeners, listener)
end

function MobService.Start(_self)
	loop(MobRules.TICK, step)
	loop(POPULATION_EVERY, population)

	if RunService:IsStudio() then
		newCommand("DevSpawnMob", devSpawn)
		newCommand("DevMobCount", devCount)
	end
end

return MobService
