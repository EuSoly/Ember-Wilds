--!strict
-- Painel do time (TeamService; docs/guia/times.md). No time: nome do líder,
-- membros, Sair e, para o líder perto do próprio totem, Trancar/Destrancar e o X
-- de expulsar. Sem time, perto de um totem com vaga e destrancado: Entrar.
-- Tudo lido dos atributos (Team no Player; TeamLeader/TeamLocked/TeamSize no
-- totem). Quem decide é o servidor.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local BuildRules = require(Shared:WaitForChild("Build"):WaitForChild("BuildRules"))
local Defs = require(Shared:WaitForChild("Defs"))
local StatNames = require(Shared:WaitForChild("StatNames"))
local Strings = require(Shared:WaitForChild("Strings"))
local TeamRules = require(Shared:WaitForChild("Build"):WaitForChild("TeamRules"))
local Theme = require(Shared:WaitForChild("Theme"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local Rustic = require(script.Parent:WaitForChild("Rustic"))
local Net = require(script.Parent.Parent:WaitForChild("Net"))

local create = vide.create

type Member = { id: number, name: string }
type Totem = { leader: number, locked: boolean, size: number }

local REFRESH = 0.2
local ROW = 28

local function displayName(userId: number): string
	local player = Players:GetPlayerByUserId(userId)
	return if player then player.DisplayName else tostring(userId)
end

-- Totem com time mais perto do jogador, dentro do alcance (nil = nenhum).
local function nearestTotem(position: Vector3): Totem?
	local best: Totem? = nil
	local bestDistance = math.huge
	for _, instance in CollectionService:GetTagged(StatNames.StructureTag) do
		local leader = instance:GetAttribute(StatNames.TeamLeader)
		local itemId = instance:GetAttribute(StatNames.StructureItem)
		local item = if type(itemId) == "string" then Defs.Items[itemId] else nil
		if type(leader) == "number" and item and item.structure and instance:IsA("PVInstance") then
			local pivot = instance:GetPivot().Position
			local d = math.sqrt((pivot.X - position.X) ^ 2 + (pivot.Z - position.Z) ^ 2)
				- BuildRules.radiusOf(item.structure)
			if d <= TeamRules.TOTEM_RADIUS and d < bestDistance then
				bestDistance = d
				local size = instance:GetAttribute(StatNames.TeamSize)
				best = {
					leader = leader,
					locked = instance:GetAttribute(StatNames.TeamLocked) == true,
					size = if type(size) == "number" then size else 1,
				}
			end
		end
	end
	return best
end

local function TeamPanel(): Frame
	local myTeam = vide.source(nil :: number?)
	local members = vide.source({} :: { Member })
	local totem = vide.source(nil :: Totem?)

	local last = 0
	local connection = RunService.RenderStepped:Connect(function()
		local t = os.clock()
		if t - last < REFRESH then
			return
		end
		last = t
		local me = Players.LocalPlayer
		local team = me:GetAttribute(StatNames.Team)
		local teamId = if type(team) == "number" then team else nil
		myTeam(teamId)
		local list: { Member } = {}
		if teamId then
			for _, player in Players:GetPlayers() do
				if player:GetAttribute(StatNames.Team) == teamId then
					table.insert(list, { id = player.UserId, name = player.DisplayName })
				end
			end
			table.sort(list, function(a, b)
				return (a.id == teamId) or (b.id ~= teamId and a.name < b.name)
			end)
		end
		members(list)
		local root = me.Character and me.Character:FindFirstChild("HumanoidRootPart")
		totem(if root and root:IsA("BasePart") then nearestTotem(root.Position) else nil)
	end)
	vide.cleanup(connection)

	local function isLeaderNearOwnTotem(): boolean
		local team, near = myTeam(), totem()
		return team ~= nil and team == Players.LocalPlayer.UserId and near ~= nil and near.leader == team
	end

	local function MemberRow(member: () -> Member, index: number): Frame
		return create("Frame")({
			Name = "Member",
			LayoutOrder = index,
			Size = UDim2.new(1, 0, 0, ROW),
			BackgroundTransparency = 1,
			Kit.text({
				Size = UDim2.new(1, -ROW - 4, 1, 0),
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = function()
					local m = member()
					return if m.id == myTeam() then Strings.format("team.leader", { name = m.name }) else m.name
				end,
				maxSize = 16,
			}) :: Instance,
			Rustic.button({
				Name = "Kick",
				Visible = function()
					return isLeaderNearOwnTotem() and member().id ~= myTeam()
				end,
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.fromScale(1, 0),
				Size = UDim2.fromOffset(ROW, ROW),
				kind = "leather",
				text = "X",
				maxSize = 14,
				Activated = function()
					Net.TeamKick.Fire({ UserId = vide.untrack(member).id })
				end,
			}) :: Instance,
		})
	end

	return create("Frame")({
		Name = "TeamPanel",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0.01, 0.5),
		Size = UDim2.fromOffset(220, 330),
		BackgroundTransparency = 1,
		-- Sem time, perto de um totem destrancado e com vaga: Entrar.
		Rustic.button({
			Name = "Join",
			Visible = function()
				local near = totem()
				return myTeam() == nil and near ~= nil and not near.locked and near.size < TeamRules.MAX
			end,
			Size = UDim2.new(1, 0, 0, 40),
			kind = "ember",
			text = function()
				local near = totem()
				return Strings.format("team.join", { name = if near then displayName(near.leader) else "" })
			end,
			maxSize = 16,
			Activated = function()
				local near = vide.untrack(totem)
				if near then
					Net.TeamJoin.Fire({ Leader = near.leader })
				end
			end,
		}) :: Instance,
		create("Frame")({
			Name = "Team",
			Visible = function()
				return myTeam() ~= nil
			end,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Kit.text({
				Name = "Title",
				Size = UDim2.new(1, 0, 0, 30),
				TextXAlignment = Enum.TextXAlignment.Left,
				FontFace = Theme.font.number,
				TextColor3 = Color3.fromRGB(120, 230, 120),
				Text = function()
					local team = myTeam()
					return Strings.format("team.title", {
						name = if team then displayName(team) else "",
						size = #members(),
						max = TeamRules.MAX,
					})
				end,
				maxSize = 18,
			}) :: Instance,
			create("Frame")({
				Name = "Members",
				Position = UDim2.fromOffset(0, 34),
				Size = UDim2.new(1, 0, 0, ROW * TeamRules.MAX + 4 * TeamRules.MAX),
				BackgroundTransparency = 1,
				create("UIListLayout")({ Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
				vide.indexes(members, MemberRow),
			}),
			create("Frame")({
				Name = "Buttons",
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.fromScale(0, 1),
				Size = UDim2.new(1, 0, 0, 36),
				BackgroundTransparency = 1,
				Rustic.button({
					Name = "Leave",
					Size = UDim2.fromScale(0.48, 1),
					kind = "leather",
					text = Strings.get("team.leave"),
					maxSize = 15,
					Activated = function()
						Net.TeamLeave.Fire()
					end,
				}) :: Instance,
				Rustic.button({
					Name = "Lock",
					Visible = isLeaderNearOwnTotem,
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.fromScale(1, 0),
					Size = UDim2.fromScale(0.48, 1),
					kind = "wood",
					text = function()
						local near = totem()
						return Strings.get(if near and near.locked then "team.unlock" else "team.lock")
					end,
					maxSize = 15,
					Activated = function()
						Net.TeamLock.Fire()
					end,
				}) :: Instance,
			}),
		}),
	})
end

return TeamPanel
