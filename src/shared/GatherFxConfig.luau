--!strict
-- Efeitos de cada material da coleta (GatherDef.material): cor das lasquinhas
-- e som do golpe. Para trocar um som: troque o soundId por outro áudio da loja
-- do Roblox (create.roblox.com/store/audio, copie o número do link) e ajuste o
-- volume (0 a 1). Os sons tocam no grupo "Effects" (volume das configurações).
-- Sons atuais: gratuitos da ProSoundEffects.
local Palette = require("./Palette")

export type MaterialFx = { color: string, soundId: string, volume: number }

return table.freeze({
	wood = table.freeze({ color = Palette.tier.wood, soundId = "rbxassetid://9120809592", volume = 0.5 }),
	stone = table.freeze({ color = Palette.tier.stone, soundId = "rbxassetid://9118622414", volume = 0.6 }),
	gold = table.freeze({ color = Palette.tier.gold, soundId = "rbxassetid://9125361455", volume = 0.35 }),
	leaves = table.freeze({ color = Palette.biome.forest[1], soundId = "rbxassetid://9114518386", volume = 0.6 }),
}) :: { [string]: MaterialFx }
