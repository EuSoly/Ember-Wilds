--!strict
-- Prêmio de quem entra no grupo do jogo no Roblox (janela de Códigos, cartão
-- da direita). Uma vez por jogador; o servidor confere a entrada no grupo
-- (Player:IsInGroupAsync) e entrega pelo ShopService. Guia: docs/guia/codigos.md.
--
-- A skin do prêmio é `unreleased` (fora dos giros, só aparece na grade para
-- quem tem) e tem a etiqueta Limitada (`tags` no Defs/Cosmetics).
local CodeRules = require("./CodeRules")
local ShopTypes = require("./Types")

local GroupReward = {}

-- Grupo "Ember Wilds inc" (roblox.com/communities/557568805). 0 = sem grupo:
-- o cartão some da janela.
GroupReward.GROUP_ID = 557568805

GroupReward.rewards = table.freeze({
	{ kind = "cosmetic", id = "body_gaio_azul" },
	{ kind = "ember", amount = 200 },
} :: { ShopTypes.Reward })

-- Marca no perfil (Shop.Codes) de quem já pegou. Tem "_", que código de
-- resgate não tem (só A–Z e 0–9), então nunca bate com um código.
function GroupReward.mark(groupId: number): string
	return `GROUP_{groupId}`
end

-- Prêmio já pego? `used` = Shop.Codes do perfil.
function GroupReward.claimed(used: { [string]: boolean }, groupId: number): boolean
	return used[GroupReward.mark(groupId)] == true
end

-- A marca do grupo nunca pode ser lida como código de resgate.
assert(not CodeRules.isCodeShape(GroupReward.mark(GroupReward.GROUP_ID)), "marca do grupo parece código")

return GroupReward
