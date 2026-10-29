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
export type FoodEffect = Types.FoodEffect
export type ArmorStats = Types.ArmorStats
export type EyeStyle = Types.EyeStyle
export type ExpressionTrigger = Types.ExpressionTrigger
export type ExpressionDef = Types.ExpressionDef
export type BodyLook = Types.BodyLook
export type CosmeticSlotDef = Types.CosmeticSlotDef
export type CosmeticDef = Types.CosmeticDef
export type StatKind = Types.StatKind
export type StatKeyKind = Types.StatKeyKind
export type StatDef = Types.StatDef
export type SettingKind = Types.SettingKind
export type SettingValue = Types.SettingValue
export type SettingDef = Types.SettingDef
export type KitItem = Types.KitItem
export type KitDef = Types.KitDef
export type ResourceDef = Types.ResourceDef
export type ResourceZoneDef = Types.ResourceZoneDef

local Defs: Types.DefsTables = table.freeze({
	Tiers = require("@self/Tiers"),
	Items = require("@self/Items"),
	CosmeticSlots = require("@self/CosmeticSlots"),
	Cosmetics = require("@self/Cosmetics"),
	Expressions = require("@self/Expressions"),
	Stats = require("@self/Stats"),
	Settings = require("@self/Settings"),
	Kits = require("@self/Kits"),
	Resources = require("@self/Resources"),
	ResourceZones = require("@self/ResourceZones"),
})

local errors = Validate.all(Defs, Strings.has)
if #errors > 0 then
	error("[Defs] definições inválidas:\n  " .. table.concat(errors, "\n  "), 0)
end

return Defs
