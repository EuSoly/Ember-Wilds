--!strict
-- Tocador dos efeitos sonoros (o único lugar do cliente que cria Sound de
-- efeito). Quem quer um som chama SoundPlayer.play("chave") (2D, interface e o
-- próprio jogador) ou SoundPlayer.play("chave", posição) (3D no mundo). A chave
-- é uma entrada de Shared/Audio/SoundConfig (id, volume, cooldown...).
-- Cuida sozinho de: grupo de volume (Effects/Ambient das configurações),
-- variação de tom, cooldown dos repetitivos, limite de sons ao mesmo tempo
-- (celular) e de não tocar o que está longe demais para se ouvir.
-- O "ouvido" fica no boneco (foco da câmera), não na câmera: ela fica 34 studs
-- acima e deixaria tudo baixo. Veja docs/guia/sons.md.
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Audio = Shared:WaitForChild("Audio")
local SoundConfig = require(Audio:WaitForChild("SoundConfig"))
local SoundRules = require(Audio:WaitForChild("SoundRules"))

local Client = script.Parent.Parent
local AudioSettings = require(Client:WaitForChild("AudioSettings"))

local SoundPlayer = {}

local limiter = SoundRules.newLimiter()
local loops: { [string]: Sound } = {}
local listener: Part? = nil
local started = false

-- SoundGroup das configurações (Music, Ambient ou Effects).
function SoundPlayer.group(name: SoundConfig.Group): SoundGroup?
	AudioSettings.start() -- cria os grupos se ainda não existem (só na 1ª vez)
	local group = SoundService:FindFirstChild(name)
	return if group and group:IsA("SoundGroup") then group else nil
end

-- Onde está o ouvido: o ponto que a câmera segue (o boneco, ou quem o menu
-- acompanha).
function SoundPlayer.listenerPosition(): Vector3
	local camera = Workspace.CurrentCamera
	return if camera then camera.Focus.Position else Vector3.zero
end

-- Um Sound novo com a config de `def` (sem pai e sem tocar).
function SoundPlayer.create(def: SoundConfig.Sound, name: string): Sound
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = def.soundId
	sound.Volume = def.volume
	sound.SoundGroup = SoundPlayer.group(def.group)
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.RollOffMinDistance = SoundConfig.ROLLOFF_MIN
	sound.RollOffMaxDistance = def.range or SoundConfig.ROLLOFF_MAX
	return sound
end

-- Toca o som `key`. Sem `position` é 2D; com ela, 3D naquele ponto do mundo.
-- Devolve false se não tocou (chave desconhecida, cooldown, limite ou longe).
function SoundPlayer.play(key: string, position: Vector3?): boolean
	local def = SoundConfig.sounds[key]
	if def == nil then
		return false
	end
	if position then
		local range = def.range or SoundConfig.ROLLOFF_MAX
		if (position - SoundPlayer.listenerPosition()).Magnitude > range then
			return false
		end
	end
	if not SoundRules.allow(limiter, key, os.clock(), def, SoundConfig.MAX_VOICES) then
		return false
	end

	local sound = SoundPlayer.create(def, key)
	if def.pitch > 0 then
		sound.PlaybackSpeed = 1 + (math.random() * 2 - 1) * def.pitch
	end
	local holder: Instance = sound
	if position then
		local attachment = Instance.new("Attachment")
		attachment.Name = "Sound_" .. key
		attachment.WorldPosition = position
		attachment.Parent = Workspace.Terrain
		sound.Parent = attachment
		holder = attachment
	else
		sound.Parent = SoundService
	end
	sound:Play()
	sound.Ended:Once(function()
		holder:Destroy()
	end)
	-- Garantia: som que não carregou nunca dispara Ended.
	task.delay(def.length + 2, function()
		if holder.Parent then
			holder:Destroy()
		end
	end)
	return true
end

-- Liga ou desliga um som 2D em loop (ex.: batimento com a vida baixa).
function SoundPlayer.setLoop(key: string, on: boolean)
	local sound: Sound? = loops[key]
	if not on then
		if sound and sound.IsPlaying then
			sound:Stop()
		end
		return
	end
	if sound == nil then
		local def = SoundConfig.sounds[key]
		if def == nil then
			return
		end
		local created = SoundPlayer.create(def, "Loop_" .. key)
		created.Looped = true
		created.Parent = SoundService
		loops[key] = created
		sound = created
	end
	if sound and not sound.IsPlaying then
		sound:Play()
	end
end

-- Liga o ouvido no boneco e carrega os efeitos em segundo plano (o primeiro
-- golpe já sai com som). Chamado uma vez pelo AudioController.
function SoundPlayer.start()
	if started then
		return
	end
	started = true

	local part = Instance.new("Part")
	part.Name = "AudioListener"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Transparency = 1
	part.Size = Vector3.one
	part.Parent = Workspace
	listener = part
	SoundService:SetListener(Enum.ListenerType.ObjectCFrame, part)
	RunService:BindToRenderStep("AudioListener", Enum.RenderPriority.Camera.Value + 1, function()
		local camera = Workspace.CurrentCamera
		if camera and listener then
			-- Posição do boneco com a orientação da câmera: o que está à direita
			-- na tela soa à direita.
			listener.CFrame = camera.CFrame.Rotation + camera.Focus.Position
		end
	end)

	task.spawn(function()
		local list: { Instance } = {}
		for key, def in SoundConfig.sounds do
			table.insert(list, SoundPlayer.create(def, key))
		end
		pcall(function()
			ContentProvider:PreloadAsync(list)
		end)
		for _, sound in list do
			sound:Destroy()
		end
	end)
end

return SoundPlayer
