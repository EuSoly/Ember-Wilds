--!strict
-- Como um prêmio aparece em selo: o ícone (uma chave; a tela troca pela
-- imagem), a quantidade curta ("100", "×5", "1 vida") e o nome do prêmio
-- embaixo ("Golden Ember", "Giros especiais", "Kit Explorador"). Usado nos
-- cartões do check-in (Menu/CheckInPanel). Sem ícone (`icon` nil), a tela
-- mostra o texto inteiro do prêmio (Shop/RewardView.text).
--   coin       → a moeda da Golden Ember (UiImages.COIN)
--   spinNormal → a roleta das abas da loja (ShopImages.TAB.spins)
--   spinPaid   → o giro especial (MissionImages.ICON.premio_giro_especial)
--   kit        → o ícone do kit `kitId` (MonetizationImages.KIT)
local Strings = require("../Strings")
local ShopTypes = require("./Types")
local Kits = require("../Defs/Kits")

type Reward = ShopTypes.Reward

export type Icon = "coin" | "spinNormal" | "spinPaid" | "kit"
export type Badge = { icon: Icon?, kitId: string?, amount: string, label: string }

local RewardBadge = {}

-- 20000 → "20.000" (separador de milhar do pt-BR).
local function thousands(value: number): string
	local digits = tostring(math.floor(math.max(value, 0)))
	local out = digits:reverse():gsub("(%d%d%d)", "%1."):reverse()
	return (out:gsub("^%.", ""))
end

function RewardBadge.of(reward: Reward): Badge
	if reward.kind == "ember" then
		return { icon = "coin", amount = thousands(reward.amount or 0), label = Strings.get("checkin.label.ember") }
	elseif reward.kind == "spins" then
		local n = reward.count or 0
		local count = Strings.format("checkin.amount.count", { count = n })
		local paid = reward.spin == "paid"
		local key = if paid
			then (if n == 1 then "checkin.label.spinPaid" else "checkin.label.spinsPaid")
			else (if n == 1 then "checkin.label.spin" else "checkin.label.spins")
		return { icon = if paid then "spinPaid" else "spinNormal", amount = count, label = Strings.get(key) }
	elseif reward.kind == "kitOnce" then
		local lives = reward.count or 1
		local amount = if lives == 1
			then Strings.get("checkin.amount.life")
			else Strings.format("checkin.amount.lives", { count = lives })
		local kit = if reward.id then Kits[reward.id] else nil
		local name = if kit then Strings.get(kit.nameKey) else tostring(reward.id)
		local label = Strings.format("checkin.label.kit", { name = name })
		return { icon = "kit", kitId = reward.id, amount = amount, label = label }
	end
	return { icon = nil, amount = "", label = "" }
end

return RewardBadge
