--!strict
-- Ajuste de prêmio antes da entrega (puro, testado no Lune): skin que o jogador
-- já tem vira Golden Ember, como a skin repetida da roleta especial
-- (ShopConfig.DUPLICATE_REFUND.paid). Spec: "Skin exclusiva que o jogador já
-- tem: recebe Golden Ember no lugar".
local ShopConfig = require("../Shop/ShopConfig")
local Types = require("../Defs/Types")

type Reward = Types.MissionReward

local MissionRewards = {}

function MissionRewards.resolve(reward: Reward, owns: (id: string) -> boolean): Reward
	if reward.kind == "cosmetic" and reward.id ~= nil and owns(reward.id) then
		return { kind = "ember", amount = ShopConfig.DUPLICATE_REFUND.paid }
	end
	return reward
end

return MissionRewards
