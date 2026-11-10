--!strict
-- Template do perfil salvo (schema v1). O ProfileStore usa no Reconcile() para
-- completar campos que faltam em perfis antigos. Nada de nomes ou chat aqui (GDPR).
local DataConfig = require("./DataConfig")
local RankRules = require("./RankRules")
local SettingsRules = require("./SettingsRules")
local ShopData = require("../Shop/ShopData")
local Types = require("../Defs/Types")

local ProfileTemplate = {}

-- Tabela nova a cada chamada (nunca compartilhe subtabelas entre perfis).
function ProfileTemplate.build(defs: Types.DefsTables): { [string]: any }
	return {
		SchemaVersion = DataConfig.SCHEMA_VERSION,
		Currency = { Balance = 0, HourWindowStart = 0, HourEarned = 0 },
		Cosmetics = { Owned = {}, Equipped = {} },
		Stats = {},
		-- Nível (LevelRules): XP inicial já copiado do total de pontos? e a
		-- janela do teto de XP por hora. O XP em si é a estatística xp_total.
		Xp = { Seeded = false, HourWindowStart = 0, HourEarned = 0 },
		Settings = SettingsRules.defaults(defs.Settings),
		-- Ranking semanal: valores da semana (RankRules.WeekState). A semana 0
		-- nunca é a atual: o RankService troca por uma zerada na primeira leitura.
		Ranking = RankRules.empty(0),
		-- Loja (Shop/ShopData): saldos de giros e de kits, kits e passes, compras.
		Shop = ShopData.empty(),
		-- Reservado para as compras com Robux (F5/loja), padrão do ProfileStore.
		PurchaseIdCache = {},
	}
end

return ProfileTemplate
