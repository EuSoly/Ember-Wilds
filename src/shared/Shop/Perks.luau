--!strict
-- Vantagens do jogador (puro, testado no Lune): o que o VIP, as gamepasses e o
-- Premium do Roblox dão AGORA. O servidor lê isto ao nascer e vale até o fim
-- da vida; números em ShopConfig.PERK_BONUS.
local Types = require("../Defs/Types")
local ShopConfig = require("./ShopConfig")
local ShopData = require("./ShopData")

type KitDef = Types.KitDef

export type PerkSet = { vip: boolean, ember2x: boolean, book: boolean, premium: boolean }

local Perks = {}

-- `isPremium` vem do Roblox (MembershipType.Premium); não é gravado no perfil.
function Perks.resolve(d: ShopData.ShopData, isPremium: boolean, now: number): PerkSet
	return {
		vip = d.VipUntil > now,
		ember2x = d.Passes.ember2x == true,
		book = d.Passes.book == true,
		premium = isPremium,
	}
end

-- 1 + bônus somados (2× = +1, VIP = +0,5, Premium = +0,2; máx 2,7).
function Perks.emberMultiplier(set: PerkSet): number
	local multiplier = 1
	if set.ember2x then
		multiplier += ShopConfig.PERK_BONUS.ember2x
	end
	if set.vip then
		multiplier += ShopConfig.PERK_BONUS.vip
	end
	if set.premium then
		multiplier += ShopConfig.PERK_BONUS.premium
	end
	return multiplier
end

-- Kits liberados pelas vantagens: Premium libera o kit_starter; VIP, todo vipOnly.
function Perks.unlockedKits(set: PerkSet, kits: { [string]: KitDef }): { [string]: boolean }
	local unlocked: { [string]: boolean } = {}
	if set.premium and kits.kit_starter ~= nil then
		unlocked.kit_starter = true
	end
	if set.vip then
		for id, kit in kits do
			if kit.vipOnly == true then
				unlocked[id] = true
			end
		end
	end
	return unlocked
end

return Perks
