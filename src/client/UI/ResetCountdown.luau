--!strict
-- Contagem do reset pelo menu do Roblox (DeathService; ResetRules.SECONDS
-- parado). "started": um número grande no meio da tela, descendo de 10 a 1,
-- com "Fique parado" embaixo. "cancelled" (andou): some e avisa (Notifications).
-- Morreu ou trocou de personagem: some.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local ResetRules = require(Shared:WaitForChild("Survival"):WaitForChild("ResetRules"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local Net = require(script.Parent.Parent:WaitForChild("Net"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local Notifications = require(script.Parent:WaitForChild("Notifications"))

local create = vide.create
local R = Theme.rustic

type Source<T> = (() -> T) & ((T) -> T)

local startedAt: Source<number?> = vide.source(nil :: number?) :: any
local left: Source<number> = vide.source(ResetRules.SECONDS) :: any

Net.ResetStatus.On(function(state: string)
	if state == "started" then
		left(ResetRules.SECONDS)
		startedAt(os.clock())
	elseif state == "cancelled" then
		startedAt(nil)
		Notifications.push("reset.cancelled", nil, "alert")
	end
end)

local function ResetCountdown(): Frame
	-- O número desce a cada segundo; some ao trocar de personagem (morreu).
	RunService.Heartbeat:Connect(function()
		local at = vide.untrack(startedAt)
		if at == nil then
			return
		end
		local remaining = math.max(math.ceil(ResetRules.SECONDS - (os.clock() - at)), 0)
		if remaining ~= vide.untrack(left) then
			left(remaining)
		end
	end)
	Players.LocalPlayer.CharacterAdded:Connect(function()
		startedAt(nil)
	end)
	Players.LocalPlayer.CharacterRemoving:Connect(function()
		startedAt(nil)
	end)

	return create("Frame")({
		Name = "ResetCountdown",
		Visible = function()
			return startedAt() ~= nil and left() > 0
		end,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.3),
		Size = UDim2.fromOffset(260, 110),
		BackgroundTransparency = 1,
		ZIndex = 20,
		Kit.text({
			Name = "Number",
			Size = UDim2.fromScale(1, 0.68),
			FontFace = Theme.font.title,
			TextColor3 = R.emberLight,
			Text = function()
				return tostring(left())
			end,
			maxSize = 72,
			ZIndex = 20,
		}),
		Kit.text({
			Name = "Hint",
			Position = UDim2.fromScale(0, 0.7),
			Size = UDim2.fromScale(1, 0.3),
			FontFace = Theme.font.title,
			TextColor3 = R.cream,
			Text = Strings.get("reset.countdown"),
			maxSize = 22,
			ZIndex = 20,
		}),
	}) :: Frame
end

return ResetCountdown
