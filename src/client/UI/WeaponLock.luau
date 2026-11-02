--!strict
-- Relógio da arma presa: depois de equipar espada ou lança (item com
-- equipLock), um círculo no canto inferior esquerdo da hotbar mostra quantos
-- segundos faltam para poder trocar de slot. O disco de dentro encolhe até
-- sumir. Lido por polling: atributo do personagem previsto não avisa quando muda.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Defs = require(Shared:WaitForChild("Defs"))
local StatNames = require(Shared:WaitForChild("StatNames"))
local Theme = require(Shared:WaitForChild("Theme"))
local Kit = require(script.Parent:WaitForChild("Kit"))

local create = vide.create

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
		Size = UDim2.fromScale(0.07, 0.07),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		BackgroundColor3 = Theme.ui.panel,
		BackgroundTransparency = Theme.panelTransparency,
		BorderSizePixel = 0,
		create("UISizeConstraint")({ MinSize = Vector2.new(36, 36), MaxSize = Vector2.new(64, 64) }),
		create("UICorner")({ CornerRadius = UDim.new(1, 0) }),
		create("UIStroke")({ Color = Theme.ui.border, Thickness = Theme.strokeThickness }),
		-- Disco que encolhe com o tempo.
		create("Frame")({
			Name = "Fill",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = function()
				local size = 0.85 * fraction()
				return UDim2.fromScale(size, size)
			end,
			BackgroundColor3 = Theme.ui.action,
			BackgroundTransparency = 0.35,
			BorderSizePixel = 0,
			create("UICorner")({ CornerRadius = UDim.new(1, 0) }),
		}),
		Kit.text({
			Size = UDim2.fromScale(0.7, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			ZIndex = 2,
			Text = function()
				return tostring(math.ceil(left()))
			end,
			maxSize = 20,
		}),
	}) :: Frame
end

return WeaponLock
