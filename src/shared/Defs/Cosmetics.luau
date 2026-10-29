--!strict
-- Cosméticos (skins). Para adicionar uma skin de corpo: uma entrada aqui com
-- slot = "body" e as cores + o texto "cosmetic.<id>" em Strings/ptBR.luau.
-- Veja docs/guia/boneco.md.
local Types = require("./Types")

type CosmeticDef = Types.CosmeticDef

local Cosmetics: { [string]: CosmeticDef } = {
	-- Cores do spike aprovado: o padrão de quem não equipou nada.
	body_default = {
		id = "body_default",
		nameKey = "cosmetic.body_default",
		slot = "body",
		body = { bodyColor = "#DDF3F8", outlineColor = "#1F6F7A" },
	},
	-- Segunda skin, para testar a troca.
	body_ember = {
		id = "body_ember",
		nameKey = "cosmetic.body_ember",
		slot = "body",
		body = { bodyColor = "#D8250D", outlineColor = "#5F1802" },
	},
}

for _, cosmetic in Cosmetics do
	if cosmetic.body ~= nil then
		table.freeze(cosmetic.body)
	end
	table.freeze(cosmetic)
end

return table.freeze(Cosmetics)
