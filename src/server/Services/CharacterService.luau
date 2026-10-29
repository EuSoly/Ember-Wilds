--!strict
-- Configura todo personagem que nasce:
-- - sem pulo e sem rotação automática (quem gira o personagem é a simulação de mira);
-- - proporções travadas, para todo mundo ter o mesmo hitbox no PvP.
-- As Avatar Settings da experiência (no Studio) já limitam a escala; aqui é a
-- segunda camada de defesa, caso algum avatar escape delas.
local Players = game:GetService("Players")

-- Valores da HumanoidDescription que todo personagem deve ter.
local LOCKED_SCALES: { [string]: number } = {
	HeightScale = 1,
	WidthScale = 1,
	DepthScale = 1,
	HeadScale = 1,
	BodyTypeScale = 0,
	ProportionScale = 0,
}

local CharacterService = {}

local function lockProportions(humanoid: Humanoid)
	local description = humanoid:GetAppliedDescription()
	local changed = false
	for property, value in LOCKED_SCALES do
		if (description :: any)[property] ~= value then
			(description :: any)[property] = value
			changed = true
		end
	end
	-- Só reaplica quando precisa: aplicar a descrição recria partes do avatar.
	if changed then
		local ok, err = pcall(function()
			humanoid:ApplyDescriptionAsync(description)
		end)
		if not ok then
			warn(`[CharacterService] não consegui travar as proporções: {err}`)
		end
	end
end

local function setupCharacter(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid.AutoRotate = false
	humanoid.UseJumpPower = false
	humanoid.JumpHeight = 0
end

local function setupPlayer(player: Player)
	player.CharacterAdded:Connect(setupCharacter)
	player.CharacterAppearanceLoaded:Connect(function(character)
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			lockProportions(humanoid)
		end
	end)
	if player.Character then
		task.spawn(setupCharacter, player.Character)
	end
end

function CharacterService.Start(_self)
	Players.PlayerAdded:Connect(setupPlayer)
	-- Jogadores que entraram antes deste Start (ex.: no Play Solo do Studio).
	for _, player in Players:GetPlayers() do
		setupPlayer(player)
	end
end

return CharacterService
