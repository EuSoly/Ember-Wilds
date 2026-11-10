--!strict
-- Como cada tipo de recompensa (Shop/Rewards) aparece no card de um pacote:
-- o texto da lista ("500 Golden Ember", "3 giros especiais") e, para skins, a
-- peça 3D da prévia. TIPO NOVO: um caso em `text` (e, se tiver figura, em
-- `tile`); sem caso, o card mostra o id cru para o esquecimento aparecer.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Defs = require(Shared:WaitForChild("Defs"))
local ShopConfig = require(Shared:WaitForChild("Shop"):WaitForChild("ShopConfig"))
local ShopTypes = require(Shared:WaitForChild("Shop"):WaitForChild("Types"))
local Strings = require(Shared:WaitForChild("Strings"))
local SpinTile = require(script.Parent:WaitForChild("SpinTile"))

type Reward = ShopTypes.Reward

local RewardView = {}

local function kitName(id: string?): string
	local kit = if id then Defs.Kits[id] else nil
	return if kit then Strings.get(kit.nameKey) else tostring(id)
end

-- Uma linha da lista do card.
function RewardView.text(reward: Reward): string
	if reward.kind == "cosmetic" then
		local cosmetic = if reward.id then Defs.Cosmetics[reward.id] else nil
		return if cosmetic then Strings.get(cosmetic.nameKey) else tostring(reward.id)
	elseif reward.kind == "ember" then
		return Strings.format("shop.reward.ember", { amount = reward.amount or 0 })
	elseif reward.kind == "spins" then
		local key = if reward.spin == "paid" then "shop.reward.spins.paid" else "shop.reward.spins.normal"
		return Strings.format(key, { count = reward.count or 0 })
	elseif reward.kind == "kit" then
		return Strings.format("shop.reward.kit", { name = kitName(reward.id) })
	elseif reward.kind == "kitOnce" then
		return Strings.format("shop.reward.kitOnce", { count = reward.count or 0, name = kitName(reward.id) })
	elseif reward.kind == "pass" then
		local pass = if reward.id then ShopConfig.PASSES[reward.id] else nil
		return Strings.format(
			"shop.reward.pass",
			{ name = if pass then Strings.get(pass.nameKey) else tostring(reward.id) }
		)
	end
	return `{reward.kind}:{reward.id or ""}`
end

-- Peça da prévia (só skins têm figura), com `sizeScale` da altura do pai.
function RewardView.tile(reward: Reward, sizeScale: number): Frame?
	if reward.kind == "cosmetic" and reward.id ~= nil then
		return SpinTile.cosmeticPreview(reward.id, sizeScale)
	end
	return nil
end

return RewardView
