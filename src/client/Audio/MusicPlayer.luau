--!strict
-- Música do jogo (grupo Music): menu, dia, noite e tela de morte. Cada modo
-- tem uma lista de faixas em Shared/Audio/SoundConfig.music; a faixa seguinte
-- é sorteada sem repetir a última (SoundRules.nextTrack) e entra por
-- crossfade (SoundConfig.MUSIC_FADE), tanto na troca de modo quanto no fim de
-- cada faixa. O modo vem da tela (ScreenState) e da hora (DayCycle +
-- atributo CycleStart): sem tráfego de rede. A música de noite começa junto
-- com o aviso "a noite está chegando" (o som conta a hora antes da luz).
-- Dois Sound fixos se revezam: nada é criado por faixa.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Audio = Shared:WaitForChild("Audio")
local SoundConfig = require(Audio:WaitForChild("SoundConfig"))
local SoundRules = require(Audio:WaitForChild("SoundRules"))
local DayCycle = require(Shared:WaitForChild("DayCycle"))
local StatNames = require(Shared:WaitForChild("StatNames"))

local Client = script.Parent.Parent
local ScreenState = require(Client:WaitForChild("ScreenState"))
local SoundPlayer = require(script.Parent:WaitForChild("SoundPlayer"))

local LOAD_TIMEOUT = 10 -- s: faixa que não carregou nesse tempo é pulada

local MusicPlayer = {}

local started = false
local sounds: { Sound } = {}
local currentSlot = 1
local mode: SoundRules.MusicMode? = nil
local lastIndex: { [string]: number } = {}
-- Volume cheio da faixa atual e o volume em que a anterior estava na troca.
local currentVolume = 0
local previousVolume = 0
local progress = 1 -- 0 a 1 do crossfade em andamento
local playing = false -- há faixa atual
local startedAt = 0

-- A noite "do som" começa no aviso da noite chegando.
local function nightNow(): boolean?
	local start = Workspace:GetAttribute(StatNames.CycleStart)
	if type(start) ~= "number" then
		return nil
	end
	local state = DayCycle.at(Workspace:GetServerTimeNow() - start)
	return state.isNight or state.nightSoon
end

MusicPlayer.nightNow = nightNow

-- Troca para uma faixa nova do modo `target` (nil = silêncio): a atual vira a
-- "anterior" e some no crossfade.
local function switch(target: SoundRules.MusicMode?)
	local previous = sounds[currentSlot]
	previousVolume = if playing then previous.Volume else 0
	currentSlot = if currentSlot == 1 then 2 else 1
	local current = sounds[currentSlot]
	current:Stop() -- era a anterior de uma troca passada
	mode = target
	progress = 0
	playing = false

	local tracks = if target then SoundConfig.music[target] else nil
	if target == nil or tracks == nil then
		return
	end
	local index = SoundRules.nextTrack(#tracks, lastIndex[target], math.random())
	if index == nil then
		return
	end
	lastIndex[target] = index
	local track = tracks[index]
	current.SoundId = track.soundId
	current.Volume = 0
	current.TimePosition = 0
	-- Uma faixa só no modo: repete sozinha; com várias, o fim emenda a próxima.
	current.Looped = #tracks == 1
	current:Play()
	currentVolume = track.volume
	playing = true
	startedAt = os.clock()
end

local function step(dt: number)
	local screen: string = vide.untrack(ScreenState.current) :: any
	local target: SoundRules.MusicMode? = SoundRules.musicMode(screen, nightNow())
	local current = sounds[currentSlot]
	if target ~= mode then
		switch(target)
	elseif playing and not current.Looped then
		local stuck = not current.IsLoaded and os.clock() - startedAt > LOAD_TIMEOUT
		local ended = current.IsLoaded and not current.IsPlaying and progress >= 1
		if
			stuck
			or ended
			or SoundRules.shouldAdvance(current.TimePosition, current.TimeLength, SoundConfig.MUSIC_FADE)
		then
			switch(mode)
		end
	end

	if progress < 1 then
		progress = math.min(progress + dt / SoundConfig.MUSIC_FADE, 1)
	end
	local out, into = SoundRules.crossfade(progress)
	current = sounds[currentSlot]
	local previous = sounds[if currentSlot == 1 then 2 else 1]
	if playing then
		current.Volume = currentVolume * into
	end
	if previous.IsPlaying then
		previous.Volume = previousVolume * out
		if progress >= 1 then
			previous:Stop()
		end
	end
end

-- Liga a música (chamado uma vez pelo AudioController).
function MusicPlayer.start()
	if started then
		return
	end
	started = true
	for i = 1, 2 do
		local sound = Instance.new("Sound")
		sound.Name = `Music{i}`
		sound.SoundGroup = SoundPlayer.group("Music")
		sound.Volume = 0
		sound.Parent = SoundService
		sounds[i] = sound
	end
	RunService.Heartbeat:Connect(step)
end

return MusicPlayer
