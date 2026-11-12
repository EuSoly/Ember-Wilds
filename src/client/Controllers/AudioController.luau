--!strict
-- Liga o áudio do jogo: efeitos (SoundPlayer + GameSounds + UiSounds),
-- ambiente (Ambience) e música (MusicPlayer). Os ids e volumes ficam em
-- Shared/Audio/SoundConfig. Veja docs/guia/sons.md.
local Client = script.Parent.Parent
local Audio = Client:WaitForChild("Audio")
local Ambience = require(Audio:WaitForChild("Ambience"))
local GameSounds = require(Audio:WaitForChild("GameSounds"))
local MusicPlayer = require(Audio:WaitForChild("MusicPlayer"))
local SoundPlayer = require(Audio:WaitForChild("SoundPlayer"))
local UiSounds = require(Audio:WaitForChild("UiSounds"))

local AudioController = {}

function AudioController.Start(_self)
	SoundPlayer.start()
	GameSounds.start()
	UiSounds.start()
	Ambience.start()
	MusicPlayer.start()
end

return AudioController
