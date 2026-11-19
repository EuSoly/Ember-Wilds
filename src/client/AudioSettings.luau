--!strict
-- Volume por grupo de som. Cria (no cliente) os SoundGroup Music, Ambient e
-- Effects em SoundService e aplica neles os volumes das configurações
-- (atributos Setting_music_volume / Setting_ambient_volume /
-- Setting_effects_volume do Player), reagindo às mudanças.
-- Todo Sound do jogo usa SoundGroup = um destes (client/Audio; docs/guia/sons.md).
--
-- 0% tem de ser mudo para sempre (bug de 19/11/2026: a barra em 0% e o som
-- voltando). Por isso o volume não depende só do sinal de mudança:
-- - a cada CHECK_EVERY o valor do atributo é relido e reaplicado se o grupo
--   estiver diferente (sinal perdido, algo que sobrescreveu o Volume);
-- - grupo que sumiu (destruído, trocado por outro do place) é recriado e os
--   sons que apontavam para o antigo passam para o novo;
-- - quem cria Sound pega o grupo por AudioSettings.group (nunca nil);
-- - sons sem grupo nos personagens (passos e pulo do script padrão do Roblox,
--   RbxCharacterSounds) entram em Effects: não escapam da barra.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Defs = require(Shared:WaitForChild("Defs"))
local SoundRules = require(Shared:WaitForChild("Audio"):WaitForChild("SoundRules"))
local StatNames = require(Shared:WaitForChild("StatNames"))

-- Nome do SoundGroup → id da configuração de volume.
local GROUPS: { [string]: string } = {
	Music = "music_volume",
	Ambient = "ambient_volume",
	Effects = "effects_volume",
}
local CHECK_EVERY = 0.25 -- s entre as conferências do volume

export type GroupName = "Music" | "Ambient" | "Effects"

local AudioSettings = {}

local started = false
local groups: { [string]: SoundGroup } = {}

-- Passa para `group` os sons que ainda apontam para `old` (grupo recriado).
local function rebind(old: SoundGroup, group: SoundGroup)
	for _, root in { SoundService :: Instance, Workspace } do
		for _, instance in root:GetDescendants() do
			if instance:IsA("Sound") and instance.SoundGroup == old then
				instance.SoundGroup = group
			end
		end
	end
end

-- O grupo `name` em SoundService, criado (ou recriado) se faltar.
local function ensureGroup(name: string): SoundGroup
	local known = groups[name]
	if known and known.Parent == SoundService then
		return known
	end
	local existing = SoundService:FindFirstChild(name)
	local group: SoundGroup
	if existing and existing:IsA("SoundGroup") then
		group = existing
	else
		group = Instance.new("SoundGroup")
		group.Name = name
		group.Parent = SoundService
	end
	groups[name] = group
	if known and known ~= group then
		rebind(known, group)
	end
	return group
end

-- Volume salvo do grupo `name` (0 a 1). Antes do perfil carregar vale o
-- padrão da configuração (Defs.Settings), não 100%.
local function savedVolume(name: string): number
	local settingId = GROUPS[name]
	local def = Defs.Settings[settingId]
	local fallback = if def and type(def.default) == "number" then def.default else 1
	local value = Players.LocalPlayer:GetAttribute(StatNames.SettingPrefix .. settingId)
	return SoundRules.groupVolume(value, fallback)
end

local function apply(name: string)
	local group = ensureGroup(name)
	local volume = savedVolume(name)
	if group.Volume ~= volume then
		group.Volume = volume
	end
end

local function applyAll()
	for name in GROUPS do
		apply(name)
	end
end

-- Som sem grupo dentro de um personagem vai para Effects.
local function adoptSound(instance: Instance)
	if instance:IsA("Sound") and instance.SoundGroup == nil then
		instance.SoundGroup = ensureGroup("Effects")
	end
end

local function watchCharacter(character: Model)
	character.DescendantAdded:Connect(adoptSound)
	for _, descendant in character:GetDescendants() do
		adoptSound(descendant)
	end
end

local function watchPlayer(player: Player)
	player.CharacterAdded:Connect(watchCharacter)
	if player.Character then
		watchCharacter(player.Character)
	end
end

-- SoundGroup das configurações (sempre existe: cria se faltar). Todo Sound do
-- jogo deve pegar o grupo por aqui.
function AudioSettings.group(name: GroupName): SoundGroup
	AudioSettings.start()
	local group = ensureGroup(name)
	-- Grupo novo já nasce no volume salvo (sem um instante a 100%).
	apply(name)
	return group
end

function AudioSettings.start()
	if started then
		return
	end
	started = true
	local player = Players.LocalPlayer
	for name, settingId in GROUPS do
		apply(name)
		player:GetAttributeChangedSignal(StatNames.SettingPrefix .. settingId):Connect(function()
			apply(name)
		end)
	end

	-- Conferência periódica: barata (3 GetAttribute) e garante o volume salvo
	-- mesmo se o sinal falhar ou algo mexer no grupo.
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt: number)
		elapsed += dt
		if elapsed >= CHECK_EVERY then
			elapsed = 0
			applyAll()
		end
	end)

	Players.PlayerAdded:Connect(watchPlayer)
	for _, other in Players:GetPlayers() do
		watchPlayer(other)
	end
end

return AudioSettings
