--!strict
-- Ponto único de acesso às definições de conteúdo.
-- Uso: local Defs = require(ReplicatedStorage.Shared.Defs); Defs.Items.wood_pickaxe
--
-- Ao ser carregado, valida todas as tabelas e falha com a lista de erros
-- se algo estiver inconsistente.
-- Num init.luau, "./" aponta para os irmãos da pasta Defs (ou seja, Shared/).
local Strings = require("./Strings")
local Types = require("@self/Types")
local Validate = require("@self/Validate")

export type TierDef = Types.TierDef
export type ItemDef = Types.ItemDef
export type ItemCategory = Types.ItemCategory

local Defs: Types.DefsTables = table.freeze({
	Tiers = require("@self/Tiers"),
	Items = require("@self/Items"),
})

local errors = Validate.all(Defs, Strings.has)
if #errors > 0 then
	error("[Defs] definições inválidas:\n  " .. table.concat(errors, "\n  "), 0)
end

return Defs
