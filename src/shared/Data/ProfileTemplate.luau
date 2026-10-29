--!strict
-- Template do perfil salvo (schema v1). O ProfileStore usa no Reconcile() para
-- completar campos que faltam em perfis antigos. Nada de nomes ou chat aqui (GDPR).
local DataConfig = require("./DataConfig")
local SettingsRules = require("./SettingsRules")
local Types = require("../Defs/Types")

local ProfileTemplate = {}

-- Tabela nova a cada chamada (nunca compartilhe subtabelas entre perfis).
function ProfileTemplate.build(defs: Types.DefsTables): { [string]: any }
	return {
		SchemaVersion = DataConfig.SCHEMA_VERSION,
		Currency = { Balance = 0, HourWindowStart = 0, HourEarned = 0 },
		Cosmetics = { Owned = {}, Equipped = {} },
		Stats = {},
		Settings = SettingsRules.defaults(defs.Settings),
		-- Reservado para as compras com Robux (F5/loja), padrão do ProfileStore.
		PurchaseIdCache = {},
	}
end

return ProfileTemplate
