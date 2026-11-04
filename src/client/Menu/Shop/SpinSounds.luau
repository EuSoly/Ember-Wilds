--!strict
-- Sons da roleta (ids e volumes em SpinSoundConfig). Um giro abre uma sessão:
--   frame(progress, tile) — a cada quadro: tique quando um quadradinho passa
--     pelo marcador (mais agudo no fim, quanto mais rara) e o volume do chiado e
--     do tambor sobe conforme o fim chega, na medida da raridade que vai sair;
--   land() — o carrossel parou: corta o suspense e toca a revelação da raridade;
--   stop() — saiu no meio (fechou a tela): corta tudo, sem revelação.
-- Os Sound ficam numa pasta em SoundService, no grupo "Effects".
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local SpinSoundConfig = require(Shared:WaitForChild("SpinSoundConfig"))
local SpinRules = require(Shared:WaitForChild("UIFlow"):WaitForChild("SpinRules"))

local TICK_POOL = 6 -- tiques podem se sobrepor no começo (giro rápido)
local MIN_TICK_GAP = 0.03 -- s; no começo passam ~30 quadradinhos por segundo
local TICK_PITCH_UP = 0.35 -- quanto o tique sobe no suspense máximo
local SPIN_SECONDS = 5.2 -- mesmo tempo do Reel: o chiado termina junto
local FADE = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

export type Session = {
	frame: (progress: number, tile: number) -> (),
	land: () -> (),
	stop: () -> (),
}

type Bank = {
	ticks: { Sound },
	riser: Sound,
	drumroll: Sound,
	whoosh: Sound,
	reveal: { Sound },
}

local SpinSounds = {}

local bank: Bank? = nil
local rng = Random.new()

local function make(parent: Instance, name: string, entry: SpinSoundConfig.Sound, looped: boolean): Sound
	local s = Instance.new("Sound")
	s.Name = name
	s.SoundId = entry.soundId
	s.Volume = entry.volume
	s.Looped = looped
	s.SoundGroup = SoundService:FindFirstChild("Effects") :: SoundGroup?
	s.Parent = parent
	return s
end

-- Cria os Sound uma vez só (reaproveitados em todos os giros).
local function ensure(): Bank
	local existing = bank
	if existing then
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = "SpinSounds"
	folder.Parent = SoundService
	local ticks: { Sound } = {}
	for i = 1, TICK_POOL do
		table.insert(ticks, make(folder, `Tick{i}`, SpinSoundConfig.tick, false))
	end
	local reveal: { Sound } = {}
	for r, entry in SpinSoundConfig.reveal do
		table.insert(reveal, make(folder, `Reveal{r}`, entry, false))
	end
	local created: Bank = {
		ticks = ticks,
		riser = make(folder, "Riser", SpinSoundConfig.riser, false),
		drumroll = make(folder, "Drumroll", SpinSoundConfig.drumroll, true),
		whoosh = make(folder, "Whoosh", SpinSoundConfig.whoosh, false),
		reveal = reveal,
	}
	bank = created
	return created
end

-- Carrega os áudios antes do primeiro giro (sem travar quem chamou).
function SpinSounds.preload()
	local b = ensure()
	local list: { Instance } = { b.ticks[1], b.riser, b.drumroll, b.whoosh }
	for _, s in b.reveal do
		table.insert(list, s)
	end
	task.spawn(function()
		pcall(function()
			ContentProvider:PreloadAsync(list)
		end)
	end)
end

local fades: { [Sound]: Tween } = {}

-- Um fade que ainda está rolando não pode parar o som do giro seguinte.
local function cancelFade(s: Sound)
	local tween = fades[s]
	if tween then
		fades[s] = nil
		tween:Cancel()
	end
end

local function fadeOut(s: Sound)
	cancelFade(s)
	if not s.IsPlaying then
		return
	end
	local tween = TweenService:Create(s, FADE, { Volume = 0 })
	fades[s] = tween
	tween.Completed:Once(function(state)
		if state == Enum.PlaybackState.Completed and fades[s] == tween then
			fades[s] = nil
			s:Stop()
		end
	end)
	tween:Play()
end

-- Começa os sons de um giro que vai parar num item de `rarity`.
function SpinSounds.begin(rarity: number, paid: boolean): Session
	local b = ensure()
	local profile = SpinSoundConfig.tension[math.clamp(rarity, 1, #SpinSoundConfig.tension)]
	local lastTile: number? = nil
	local lastTickAt = 0
	local nextTick = 1
	local ended = false

	for _, s in { b.riser, b.drumroll, b.whoosh } do
		cancelFade(s)
		s:Stop()
	end
	if paid then
		b.whoosh.Volume = SpinSoundConfig.whoosh.volume
		b.whoosh:Play()
	end
	if profile.riser > 0 then
		-- Começa de um ponto que faz o pico do chiado cair no fim do giro.
		b.riser.Volume = 0
		b.riser.TimePosition = math.max(0, b.riser.TimeLength - SPIN_SECONDS)
		b.riser:Play()
	end
	if profile.drum > 0 then
		b.drumroll.Volume = 0
		b.drumroll.TimePosition = 0
		b.drumroll:Play()
	end

	local function cutSuspense()
		fadeOut(b.riser)
		fadeOut(b.drumroll)
	end

	local session = {} :: Session

	function session.frame(progress: number, tile: number)
		if ended then
			return
		end
		local tension = SpinRules.tensionRamp(progress)
		if profile.riser > 0 then
			b.riser.Volume = SpinSoundConfig.riser.volume * profile.riser * tension
		end
		if profile.drum > 0 then
			b.drumroll.Volume = SpinSoundConfig.drumroll.volume * profile.drum * tension
		end
		if lastTile == nil then
			lastTile = tile
			return
		end
		if tile == lastTile then
			return
		end
		lastTile = tile
		local now = os.clock()
		if now - lastTickAt < MIN_TICK_GAP then
			return
		end
		lastTickAt = now
		local tick = b.ticks[nextTick]
		nextTick = nextTick % #b.ticks + 1
		-- Agudo pelo tempo (não pela curva): os quadradinhos param de passar
		-- lá pelos 60% do giro, antes de a curva do suspense subir.
		tick.PlaybackSpeed = 1 + TICK_PITCH_UP * progress * profile.riser + (rng:NextNumber() - 0.5) * 0.06
		tick.TimePosition = 0
		tick:Play()
	end

	function session.land()
		if ended then
			return
		end
		ended = true
		cutSuspense()
		local reveal = b.reveal[math.clamp(rarity, 1, #b.reveal)]
		reveal.TimePosition = 0
		reveal:Play()
	end

	function session.stop()
		if ended then
			return
		end
		ended = true
		cutSuspense()
		fadeOut(b.whoosh)
	end

	return session
end

return SpinSounds
