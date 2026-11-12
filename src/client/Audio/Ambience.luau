--!strict
-- Som ambiente (grupo Ambient), só no cliente e sem tráfego de rede:
-- - floresta de dia (pássaros + vento) e de noite (grilos), trocando aos
--   poucos (SoundConfig.AMBIENT_FADE); os grilos começam junto com o aviso da
--   noite chegando;
-- - água: volume pela distância até a beira (WaterSim);
-- - fogo: som 3D em loop nas peças com a tag FireLight (fogueira e fornalha)
--   mais perto do ouvido; fornalha apagada (Lit == false) fica muda;
-- - de noite, de vez em quando, um uivo ou uma coruja ao longe.
-- Os loops 2D são criados uma vez; os de fogo nascem na peça e somem com ela.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Audio = Shared:WaitForChild("Audio")
local SoundConfig = require(Audio:WaitForChild("SoundConfig"))
local SoundRules = require(Audio:WaitForChild("SoundRules"))
local StatNames = require(Shared:WaitForChild("StatNames"))
local WaterSim = require(Shared:WaitForChild("Simulation"):WaitForChild("WaterSim"))

local Client = script.Parent.Parent
local ScreenState = require(Client:WaitForChild("ScreenState"))
local MusicPlayer = require(script.Parent:WaitForChild("MusicPlayer"))
local SoundPlayer = require(script.Parent:WaitForChild("SoundPlayer"))

local SLOW_EVERY = 0.5 -- s entre as contas mais caras (água e fogos)
local FIRE_SOUND = "FireLoop"
-- Distâncias testadas até a água (WaterSim só responde "está a até R?").
local WATER_STEPS = { 4, 8, 12, 16, 20, 24, 28, 32, 36, 40 }

local Ambience = {}

type Loop = { sound: Sound, volume: number, level: number, target: number }

local started = false
local loops: { [string]: Loop } = {}
local nextCall = 0 -- os.clock do próximo uivo/coruja

local function makeLoop(key: string)
	local def = SoundConfig.ambient[key]
	if def == nil then
		return
	end
	local sound = SoundPlayer.create(def, "Ambient_" .. key)
	sound.Looped = true
	sound.Volume = 0
	sound.Parent = SoundService
	loops[key] = { sound = sound, volume = def.volume, level = 0, target = 0 }
end

local function setTarget(key: string, target: number)
	local loop = loops[key]
	if loop then
		loop.target = target
	end
end

-- Distância (studs) até a água mais perto, em degraus; math.huge se longe.
local function waterDistance(position: Vector3): number
	if WaterSim.isWet(position.X, position.Z) then
		return 0
	end
	for _, radius in WATER_STEPS do
		if WaterSim.isNearWater(position.X, position.Z, radius) then
			return radius
		end
	end
	return math.huge
end

-- A peça de fogo está acesa? (Fornalha apagada tem Lit == false no modelo.)
local function isLit(part: Instance): (boolean, boolean)
	local model = part:FindFirstAncestorWhichIsA("Model")
	while model do
		if CollectionService:HasTag(model, StatNames.StructureTag) then
			local item = model:GetAttribute(StatNames.StructureItem)
			local furnace = type(item) == "string" and string.find(item, "furnace") ~= nil
			return model:GetAttribute(StatNames.Lit) ~= false, furnace
		end
		model = model:FindFirstAncestorWhichIsA("Model")
	end
	return true, false
end

-- Liga o loop de fogo nas peças acesas mais perto e desliga nas outras.
local function updateFires(listener: Vector3)
	local parts: { BasePart } = {}
	local distances: { number } = {}
	local furnaces: { boolean } = {}
	for _, instance in CollectionService:GetTagged(StatNames.FireLightTag) do
		if instance:IsA("BasePart") and instance:IsDescendantOf(game) then
			local lit, furnace = isLit(instance)
			if lit then
				table.insert(parts, instance)
				table.insert(distances, (instance.Position - listener).Magnitude)
				table.insert(furnaces, furnace)
			else
				local sound = instance:FindFirstChild(FIRE_SOUND)
				if sound and sound:IsA("Sound") and sound.IsPlaying then
					sound:Stop()
				end
			end
		end
	end
	local chosen: { [number]: boolean } = {}
	for _, index in SoundRules.nearest(distances, SoundConfig.MAX_FIRES, SoundConfig.FIRE_RANGE) do
		chosen[index] = true
	end
	for index, part in parts do
		local existing = part:FindFirstChild(FIRE_SOUND)
		local sound: Sound? = if existing and existing:IsA("Sound") then existing else nil
		if chosen[index] then
			if sound == nil then
				local def = SoundConfig.ambient[if furnaces[index] then "furnace" else "fire"]
				if def == nil then
					continue
				end
				local created = SoundPlayer.create(def, FIRE_SOUND)
				created.Looped = true
				created.RollOffMaxDistance = SoundConfig.FIRE_RANGE
				-- Duas fogueiras não começam no mesmo ponto do loop.
				created.TimePosition = math.random() * 10
				created.Parent = part
				sound = created
			end
			if sound and not sound.IsPlaying then
				sound:Play()
			end
		elseif sound and sound.IsPlaying then
			sound:Stop()
		end
	end
end

local function slowStep()
	local screen: string = vide.untrack(ScreenState.current) :: any
	local active = screen ~= "loading"
	local night = MusicPlayer.nightNow() == true
	local listener = SoundPlayer.listenerPosition()

	setTarget("day", if active and not night then 1 else 0)
	setTarget("wind", if active then 1 else 0)
	setTarget("night", if active and night then 1 else 0)
	setTarget("water", if active then SoundRules.waterVolume(waterDistance(listener), SoundConfig.WATER_RANGE) else 0)
	updateFires(listener)

	-- Uivo ou coruja ao longe, só jogando e de noite.
	local now = os.clock()
	if screen == "playing" and night then
		if now >= nextCall then
			if nextCall > 0 then
				SoundPlayer.play(if math.random() < 0.5 then "night_howl" else "night_owl")
			end
			nextCall = now + SoundConfig.NIGHT_CALL_MIN + math.random() * SoundConfig.NIGHT_CALL_SPREAD
		end
	else
		-- Ao anoitecer, o primeiro chamado vem logo.
		nextCall = now + 4
	end
end

local function fadeStep(dt: number)
	for _, loop in loops do
		if loop.level ~= loop.target then
			loop.level = SoundRules.approach(loop.level, loop.target, dt, SoundConfig.AMBIENT_FADE)
			loop.sound.Volume = loop.volume * loop.level
		end
		-- Loop mudo não fica tocando (economia no celular).
		if loop.level > 0 and not loop.sound.IsPlaying then
			loop.sound:Play()
		elseif loop.level <= 0 and loop.sound.IsPlaying then
			loop.sound:Stop()
		end
	end
end

-- Liga o ambiente (chamado uma vez pelo AudioController).
function Ambience.start()
	if started then
		return
	end
	started = true
	for _, key in { "day", "wind", "night", "water" } do
		makeLoop(key)
	end
	local elapsed = SLOW_EVERY
	RunService.Heartbeat:Connect(function(dt: number)
		elapsed += dt
		if elapsed >= SLOW_EVERY then
			elapsed = 0
			slowStep()
		end
		fadeStep(dt)
	end)
end

return Ambience
