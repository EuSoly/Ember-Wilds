--!strict
-- Volume por grupo de som. Cria (no cliente) os SoundGroup Music, Ambient e
-- Effects em SoundService e aplica neles os volumes das configurações
-- (atributos Setting_music_volume / Setting_ambient_volume /
-- Setting_effects_volume do Player), reagindo às mudanças.
-- Ainda não há sons no jogo: quando houver, cada Sound usa SoundGroup = um destes.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local StatNames = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("StatNames"))

-- Nome do SoundGroup → id da configuração de volume.
local GROUPS: { [string]: string } = {
	Music = "music_volume",
	Ambient = "ambient_volume",
	Effects = "effects_volume",
}

local AudioSettings = {}

local started = false

local function groupNamed(name: string): SoundGroup
	local existing = SoundService:FindFirstChild(name)
	if existing and existing:IsA("SoundGroup") then
		return existing
	end
	local group = Instance.new("SoundGroup")
	group.Name = name
	group.Parent = SoundService
	return group
end

function AudioSettings.start()
	if started then
		return
	end
	started = true
	local player = Players.LocalPlayer
	for name, settingId in GROUPS do
		local group = groupNamed(name)
		local attribute = StatNames.SettingPrefix .. settingId
		local function apply()
			local value = player:GetAttribute(attribute)
			-- Antes do perfil carregar o atributo não existe: volume cheio.
			group.Volume = if type(value) == "number" then math.clamp(value, 0, 1) else 1
		end
		apply()
		player:GetAttributeChangedSignal(attribute):Connect(apply)
	end
end

return AudioSettings
