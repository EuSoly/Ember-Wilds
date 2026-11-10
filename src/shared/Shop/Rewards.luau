--!strict
-- Tipos de item que um produto da loja entrega (pacotes, giros, kits...).
-- Cada recompensa é { kind = "<tipo>", ...campos do tipo }.
--
-- TIPO NOVO (ex. um título, um item de jogo) = três lugares:
--   1. aqui, em KINDS: os campos válidos (roda no boot e nos testes);
--   2. no servidor, em ShopService (GRANTS): como entregar;
--   3. no card da loja, em Shop/RewardView (cliente): ícone e texto.
-- Compra, validação dos pacotes e telas usam este registro e não mudam.
local Types = require("../Defs/Types")
local ShopTypes = require("./Types")
local ShopConfig = require("./ShopConfig")
local ShopData = require("./ShopData")

export type Reward = ShopTypes.Reward

type Defs = Types.DefsTables
-- `owned` (opcional): o jogador já tem o que esta recompensa dá? Usado para
-- não vender de novo um kit ou passe para sempre que ele ganhou por outro
-- caminho (ex. num pacote). Sem `owned`, nunca conta como possuída.
export type KindDef = {
	validate: (reward: Reward, defs: Defs) -> string?,
	owned: ((reward: Reward, d: ShopData.ShopData) -> boolean)?,
}

local function positiveInt(value: number?): boolean
	return type(value) == "number" and value >= 1 and value % 1 == 0
end

local Rewards = {}

local KINDS: { [string]: KindDef } = {
	-- Skin do catálogo (corpo, livro, mochila, caixa...). Já possuída = ignorada.
	cosmetic = {
		validate = function(reward: Reward, defs: Defs): string?
			if type(reward.id) ~= "string" or defs.Cosmetics[reward.id] == nil then
				return `cosmetic: id "{reward.id}" não existe em Defs.Cosmetics`
			end
			return nil
		end,
	},
	-- Golden Ember (sem o teto por hora: é compra).
	ember = {
		validate = function(reward: Reward, _defs: Defs): string?
			if not positiveInt(reward.amount) then
				return `ember: amount precisa ser inteiro ≥ 1 (veio {reward.amount})`
			end
			return nil
		end,
	},
	-- Giros: "normal" ou "paid" (especial), `count` deles.
	spins = {
		validate = function(reward: Reward, _defs: Defs): string?
			if reward.spin ~= "normal" and reward.spin ~= "paid" then
				return `spins: spin precisa ser "normal" ou "paid" (veio {reward.spin})`
			end
			if not positiveInt(reward.count) then
				return `spins: count precisa ser inteiro ≥ 1 (veio {reward.count})`
			end
			return nil
		end,
	},
	-- Kit para sempre (posse; o jogador ativa com "Usar").
	kit = {
		validate = function(reward: Reward, defs: Defs): string?
			if type(reward.id) ~= "string" or defs.Kits[reward.id] == nil then
				return `kit: id "{reward.id}" não existe em Defs.Kits`
			end
			return nil
		end,
		owned = function(reward: Reward, d: ShopData.ShopData): boolean
			return reward.id ~= nil and d.KitsOwned[reward.id] == true
		end,
	},
	-- Saldo de kit de 1 vida (cada vida com ele gasta 1).
	kitOnce = {
		validate = function(reward: Reward, defs: Defs): string?
			if type(reward.id) ~= "string" or defs.Kits[reward.id] == nil then
				return `kitOnce: id "{reward.id}" não existe em Defs.Kits`
			end
			if not positiveInt(reward.count) then
				return `kitOnce: count precisa ser inteiro ≥ 1 (veio {reward.count})`
			end
			return nil
		end,
	},
	-- Passe para sempre (ShopConfig.PASSES; ex. "vip").
	pass = {
		validate = function(reward: Reward, _defs: Defs): string?
			if type(reward.id) ~= "string" or ShopConfig.PASSES[reward.id] == nil then
				return `pass: id "{reward.id}" não existe em ShopConfig.PASSES`
			end
			return nil
		end,
		owned = function(reward: Reward, d: ShopData.ShopData): boolean
			return reward.id ~= nil and d.Passes[reward.id] == true
		end,
	},
}
Rewards.KINDS = table.freeze(KINDS)

-- O jogador já tem tudo o que `rewards` dá? (lista vazia ou tipo sem `owned` = não)
function Rewards.allOwned(rewards: { Reward }, d: ShopData.ShopData): boolean
	if #rewards == 0 then
		return false
	end
	for _, reward in rewards do
		local kind = Rewards.KINDS[reward.kind]
		local owned = kind and kind.owned
		if owned == nil or not owned(reward, d) then
			return false
		end
	end
	return true
end

-- Erro da recompensa (nil = válida). Tipo desconhecido também é erro.
function Rewards.validate(reward: Reward, defs: Defs): string?
	local kind = Rewards.KINDS[reward.kind]
	if kind == nil then
		return `kind "{reward.kind}" desconhecido (veja Shop/Rewards.luau)`
	end
	return kind.validate(reward, defs)
end

return Rewards
