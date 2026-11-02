--!strict
-- A função única de morte (kill). Toda morte de jogador passa por aqui: as
-- fases G chamam ao matar; o comando de dev DevEndLife também; qualquer morte
-- do Humanoid que não veio daqui é trazida para cá com a causa
-- "death.cause.unknown"; e a queda do mapa vira "death.cause.fall" (abaixo) —
-- nunca fica um corpo parado sem tela.
--
-- A morte: fim de vida da F4 (pontos → Golden Ember, estatísticas), guarda os
-- pontos para comprar kit (KitPoints), zera o inventário e tira a mochila e a
-- armadura (no Starve a morte perde tudo), some com as peças construídas por
-- ele (StructureService.removeOwned), remove o personagem e manda ao jogador o resumo
-- (Net.LifeEnded) para a tela de morte. Quem renasce é o SpawnService, a pedido.
--
-- Morte por jogador (G6): `killer` = quem deu o golpe final
-- (CharacterService.hurt com attacker). Válido (no jogo e não é o próprio
-- morto): o nome dele vai na tela (KillerName) e, se ainda está vivo, ganha
-- CrateRules.killBonus dos pontos que o morto tinha (lidos antes do fim de vida,
-- que os zera). É bônus: o morto não perde nada a mais.
-- Ouvintes de onDeath (caixa de itens) rodam antes de zerar o inventário,
-- protegidos: um erro num ouvinte não impede a morte.
--
-- Queda do mapa: ao passar de Workspace.FallenPartsDestroyHeight, o Roblox
-- apaga o HumanoidRootPart SEM matar o Humanoid e sem disparar Died (visto no
-- Studio: vida 100, estado Freefall, sem raiz). O Died sozinho deixaria o
-- jogador preso sem corpo e sem tela de morte. Por isso um laço único confere
-- os personagens a cada FALL_CHECK_INTERVAL e mata quem está sem raiz ou
-- abaixo de WorldConfig.KILL_Y (antes de o Roblox apagar a raiz).
--
-- Futuro (spec F5, não-objetivos): revive por Robux — pagar para voltar com os
-- mesmos itens. Para caber, a morte poderia guardar o inventário da morte por
-- alguns segundos antes do reset; os pontos zeram e viram moeda normalmente.
-- As peças construídas ficam se o revive não chamar StructureService.removeOwned.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CrateRules = require(ReplicatedStorage.Shared.Crate.CrateRules)
local StatNames = require(ReplicatedStorage.Shared.StatNames)
local WorldConfig = require(ReplicatedStorage.Shared.WorldConfig)
local ArmorService = require(script.Parent.ArmorService)
local InventoryService = require(script.Parent.InventoryService)
local LifeService = require(script.Parent.LifeService)
local ScoreService = require(script.Parent.ScoreService)
local StructureService = require(script.Parent.StructureService)
local Net = require(script.Parent.Parent.Net)

local UNKNOWN_CAUSE = "death.cause.unknown"
local FALL_CAUSE = "death.cause.fall"
local FALL_CHECK_INTERVAL = 0.25 -- segundos
-- Limites do contrato LifeEnded (net/game.blink): Days u16, Points u32, Currency u16.
local MAX_U16 = 65535
local MAX_U32 = 4294967295
local MAX_KILLER_NAME = 64 -- bytes (KillerName: string(1..64))

local DeathService = {}

local deathListeners: { (Player, Model, Player?) -> () } = {}
-- Mortes em andamento: um ouvinte de onDeath que pausa não abre espaço para
-- uma segunda morte do mesmo personagem (caixa duplicada).
local dying: { [Player]: boolean } = {}

-- Inteiro dentro de [0, max] (o Blink não aceita fora da faixa do tipo).
local function clampInt(value: number, max: number): number
	if value ~= value then
		return 0
	end
	return math.clamp(math.floor(value), 0, max)
end

-- Pontos da vida atual (finito e não negativo, senão 0).
local function scoreOf(player: Player): number
	local score = player:GetAttribute(StatNames.Score)
	if type(score) ~= "number" or score ~= score or score < 0 or score == math.huge then
		return 0
	end
	return score
end

-- Nome mostrado na tela de morte: o DisplayName (o mesmo da etiqueta do
-- boneco); se passar do limite do contrato, o Name (curto, só ASCII).
local function killerNameOf(killer: Player): string
	local name = killer.DisplayName
	if name == "" or #name > MAX_KILLER_NAME then
		return killer.Name
	end
	return name
end

function DeathService.kill(player: Player, causeKey: string, killer: Player?)
	if player.Parent ~= Players then
		return
	end
	-- Idempotente: sem personagem, já morreu (ou nunca nasceu). Uma segunda
	-- chamada (ex. queda + Died no mesmo instante) não pode zerar os KitPoints
	-- nem mandar outra tela de morte.
	local character = player.Character
	if character == nil or dying[player] then
		return
	end
	-- Quem matou só vale se ainda está no jogo e não é o próprio morto.
	local validKiller = if killer ~= nil and killer ~= player and killer.Parent == Players then killer else nil

	-- Ouvintes com o inventário, a mochila e a armadura ainda intactos.
	dying[player] = true
	for _, listener in deathListeners do
		local ok, err = pcall(listener :: any, player, character, validKiller)
		if not ok then
			warn(`[DeathService] onDeath: {err}`)
		end
	end
	dying[player] = nil
	-- Um ouvinte pode ter pausado: confere de novo quem continua no jogo.
	if player.Parent ~= Players or player.Character ~= character then
		return
	end
	if validKiller and validKiller.Parent ~= Players then
		validKiller = nil
	end

	-- Bônus de quem matou: sobre os pontos do morto antes do fim de vida (que
	-- os zera). Só para quem está vivo: os pontos são da vida atual, e um morto
	-- no menu os levaria para a próxima vida.
	if validKiller and validKiller.Character ~= nil then
		ScoreService.add(validKiller, CrateRules.killBonus(scoreOf(player)))
	end
	-- nil = sem vida ativa ou sem perfil: a tela de morte mostra zeros.
	local summary = LifeService.endLife(player) or { points = 0, days = 0, currency = 0 }

	-- Pontos da vida que acabou ficam para comprar um kit antes de renascer.
	player:SetAttribute(StatNames.KitPoints, summary.points)
	InventoryService.reset(player)
	ArmorService.wear(player, nil)
	StructureService.removeOwned(player)

	-- Remove o personagem antes de avisar: o Humanoid.Died de um personagem
	-- que já não é o atual é ignorado abaixo, então não conta duas vezes.
	player.Character = nil
	character:Destroy()

	Net.LifeEnded.Fire(player, {
		CauseKey = causeKey,
		Days = clampInt(summary.days, MAX_U16),
		Points = clampInt(summary.points, MAX_U32),
		Currency = clampInt(summary.currency, MAX_U16),
		KillerName = if validKiller then killerNameOf(validKiller) else nil,
	})
end

-- Chamado (sem pausa, protegido) em toda morte de jogador, antes de zerar o
-- inventário, com o personagem e quem deu o golpe final (nil se não foi outro
-- jogador ou se ele já saiu).
function DeathService.onDeath(listener: (player: Player, character: Model, killer: Player?) -> ())
	table.insert(deathListeners, listener)
end

local function setupCharacter(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
	if humanoid == nil then
		return
	end
	humanoid.Died:Connect(function()
		-- Só se ainda é o personagem atual: a morte por kill já o removeu.
		if player.Character == character then
			DeathService.kill(player, UNKNOWN_CAUSE)
		end
	end)
end

local function setupPlayer(player: Player)
	player.CharacterAdded:Connect(function(character)
		setupCharacter(player, character)
	end)
	if player.Character then
		task.spawn(setupCharacter, player, player.Character)
	end
end

-- true se o personagem atual caiu do mapa: sem raiz (o Roblox já a apagou) ou
-- com a raiz abaixo de KILL_Y.
local function hasFallen(character: Model): boolean
	local root = character:FindFirstChild("HumanoidRootPart")
	if root == nil or not root:IsA("BasePart") then
		return true
	end
	return root.Position.Y < WorldConfig.KILL_Y
end

local function checkFalls()
	for _, player in Players:GetPlayers() do
		local character = player.Character
		-- Só personagens já montados: logo depois do CharacterAdded a raiz pode
		-- ainda não estar dentro do modelo (Humanoid é o sinal de que montou).
		if character and character.Parent and character:FindFirstChildOfClass("Humanoid") then
			if hasFallen(character) then
				-- Thread própria: um erro na morte nunca derruba este laço.
				task.spawn(DeathService.kill, player, FALL_CAUSE)
			end
		end
	end
end

function DeathService.Start(_self)
	Players.PlayerAdded:Connect(setupPlayer)
	for _, player in Players:GetPlayers() do
		setupPlayer(player)
	end

	-- Uma thread só para todos os jogadores.
	task.spawn(function()
		while true do
			task.wait(FALL_CHECK_INTERVAL)
			checkFalls()
		end
	end)
end

return DeathService
