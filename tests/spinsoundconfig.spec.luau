--!strict
local SpinSoundConfig = require("../src/shared/SpinSoundConfig")

local function isSound(entry: SpinSoundConfig.Sound): boolean
	return string.match(entry.soundId, "^rbxassetid://%d+$") ~= nil and entry.volume > 0 and entry.volume <= 1
end

return {
	["todos os sons têm id e volume válidos"] = function()
		for _, name in { "tick", "riser", "drumroll", "whoosh" } do
			local entry = (SpinSoundConfig :: any)[name] :: SpinSoundConfig.Sound
			assert(isSound(entry), name)
		end
		assert(#SpinSoundConfig.reveal == 5, "um som de revelação por raridade")
		for r, entry in SpinSoundConfig.reveal do
			assert(isSound(entry), `reveal {r}`)
		end
	end,

	["suspense cresce com a raridade e Comum não tem"] = function()
		local tension = SpinSoundConfig.tension
		assert(#tension == 5, "um perfil por raridade")
		assert(tension[1].riser == 0 and tension[1].drum == 0, "Comum sem suspense")
		for r = 2, 5 do
			assert(tension[r].riser >= tension[r - 1].riser, `riser caiu na raridade {r}`)
			assert(tension[r].drum >= tension[r - 1].drum, `tambor caiu na raridade {r}`)
		end
		assert(tension[5].riser == 1 and tension[5].drum == 1, "Mítico no máximo")
	end,
}
