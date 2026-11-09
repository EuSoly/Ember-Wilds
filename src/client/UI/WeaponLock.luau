--!strict
-- Relógio da arma presa: depois de equipar espada ou lança (item com
-- equipLock), um medalhão (o mesmo dos anéis de status) à esquerda da hotbar
-- mostra quantos segundos faltam para poder trocar de slot, com o arco
-- esvaziando até sumir. Lido por polling: atributo do personagem previsto não avisa quando muda.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Defs = require(Shared:WaitForChild("Defs"))
local HudImages = require(Shared:WaitForChild("HudImages"))
local StatNames = require(Shared:WaitForChild("StatNames"))
local Theme = require(Shared:WaitForChild("Theme"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local StatusRing = require(script.Parent:WaitForChild("StatusRing"))

local create = vide.create

local HAS_ICON = HudImages.has(HudImages.ICON.weapon_lock)

local function never(): boolean
	return false
end

local function WeaponLock(): Frame
	local left = vide.source(0) -- segundos que faltam (0 = solta)
	local fraction = vide.source(0) -- 1 = acabou de travar, 0 = solta

	local connection = RunService.RenderStepped:Connect(function()
		local character = Players.LocalPlayer.Character
		local untilTime = character and character:GetAttribute(StatNames.EquipLockUntil)
		local equipped = character and character:GetAttribute(StatNames.Equipped)
		local item = if type(equipped) == "string" then Defs.Items[equipped] else nil
		local lock = item and item.equipLock
		local remaining = if type(untilTime) == "number" and lock
			then math.max(untilTime - Workspace:GetServerTimeNow(), 0)
			else 0
		if remaining ~= vide.untrack(left) then
			left(remaining)
			fraction(if lock then math.clamp(remaining / lock, 0, 1) else 0)
		end
	end)
	vide.cleanup(function()
		connection:Disconnect()
	end)

	return create("Frame")({
		Name = "WeaponLock",
		Visible = function()
			return left() > 0
		end,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.3, 0.86),
		Size = UDim2.fromScale(0.08, 0.08),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		BackgroundTransparency = 1,
		create("UISizeConstraint")({ MinSize = Vector2.new(40, 40), MaxSize = Vector2.new(72, 72) }),
		-- Medalhão dos anéis de status com o arco esvaziando (sem pulso: não é alerta).
		StatusRing({
			name = "Ring",
			value = function()
				return fraction() * StatNames.StatusMax
			end,
			color = Theme.ui.action,
			warning = never,
			critical = never,
			icon = HudImages.ICON.weapon_lock,
		}),
		-- Com o ícone no meio, os segundos descem para um selo embaixo.
		Kit.text({
			Name = "Seconds",
			Size = if HAS_ICON then UDim2.fromScale(0.5, 0.36) else UDim2.fromScale(0.4, 0.34),
			Position = if HAS_ICON then UDim2.fromScale(0.5, 1.02) else UDim2.fromScale(0.5, 0.5),
			AnchorPoint = if HAS_ICON then Vector2.new(0.5, 1) else Vector2.new(0.5, 0.5),
			FontFace = Theme.font.number,
			ZIndex = 7,
			Text = function()
				return tostring(math.ceil(left()))
			end,
			maxSize = 22,
		}),
	}) :: Frame
end

return WeaponLock
