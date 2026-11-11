--!strict
-- Painel do fantasma (GhostService; docs/guia/ressurreicao.md): enquanto o
-- jogador é fantasma (atributo GhostUntil do Player), mostra quanto tempo falta
-- e, perto de uma Pedra da Ressurreição (até o raio dela + GhostRules.REVIVE_RADIUS),
-- o botão Ressuscitar. Quem decide é o servidor (Net.Resurrect).
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local BuildRules = require(Shared:WaitForChild("Build"):WaitForChild("BuildRules"))
local Defs = require(Shared:WaitForChild("Defs"))
local GhostRules = require(Shared:WaitForChild("Survival"):WaitForChild("GhostRules"))
local StatNames = require(Shared:WaitForChild("StatNames"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local Rustic = require(script.Parent:WaitForChild("Rustic"))
local Net = require(script.Parent.Parent:WaitForChild("Net"))

local create = vide.create

-- Distância da raiz até a borda da pedra mais perto (math.huge sem pedra).
local function stoneDistance(position: Vector3): number
	local best = math.huge
	for _, instance in CollectionService:GetTagged(StatNames.StructureTag) do
		local itemId = instance:GetAttribute(StatNames.StructureItem)
		local item = if type(itemId) == "string" then Defs.Items[itemId] else nil
		local structure = item and item.structure
		if structure and structure.kind == "resurrection" and instance:IsA("PVInstance") then
			local pivot = instance:GetPivot().Position
			local d = math.sqrt((pivot.X - position.X) ^ 2 + (pivot.Z - position.Z) ^ 2)
				- BuildRules.radiusOf(structure)
			best = math.min(best, d)
		end
	end
	return best
end

local function GhostPanel(): Frame
	local left = vide.source(0) -- segundos de fantasma que faltam (0 = não é fantasma)
	local nearStone = vide.source(false)

	local connection = RunService.RenderStepped:Connect(function()
		local player = Players.LocalPlayer
		local untilAt = player:GetAttribute(StatNames.GhostUntil)
		local now = Workspace:GetServerTimeNow()
		local remaining = if type(untilAt) == "number" then math.max(untilAt - now, 0) else 0
		local seconds = math.ceil(remaining)
		if seconds ~= vide.untrack(left) then
			left(seconds)
		end
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local near = remaining > 0
			and root ~= nil
			and root:IsA("BasePart")
			and GhostRules.canRevive(stoneDistance(root.Position), now, untilAt :: number)
		if near ~= vide.untrack(nearStone) then
			nearStone(near)
		end
	end)
	vide.cleanup(function()
		connection:Disconnect()
	end)

	return create("Frame")({
		Name = "GhostPanel",
		Visible = function()
			return left() > 0
		end,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.16),
		Size = UDim2.fromOffset(300, 96),
		BackgroundTransparency = 1,
		Kit.text({
			Name = "Timer",
			Size = UDim2.new(1, 0, 0, 34),
			FontFace = Theme.font.number,
			TextColor3 = Color3.fromRGB(170, 215, 255),
			Text = function()
				return Strings.format("ghost.timer", { value = left() })
			end,
			maxSize = 26,
		}) :: Instance,
		Rustic.button({
			Name = "ReviveButton",
			Visible = nearStone,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 42),
			Size = UDim2.fromOffset(180, 46),
			kind = "ember",
			text = Strings.get("ghost.revive"),
			maxSize = 20,
			Activated = function()
				Net.Resurrect.Fire()
			end,
		}) :: Instance,
	})
end

return GhostPanel
