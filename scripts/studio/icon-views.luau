-- Ajustes de vista dos ícones do inventário (atributos IconeGiro, IconeZoom,
-- IconeDesloca), copiados do place em 09/11. Os atributos vivem no place; este
-- arquivo é o backup no repositório. Rodar na barra de comando do Studio (Edit)
-- regrava todos eles nos moldes de ReplicatedStorage.Assets (depois, salve o place).
-- Chave: "<pasta>/<molde>" ou "<pasta>/<molde>/<peça>" (atributo numa peça do molde).
-- Para atualizar este arquivo com os valores atuais do place, peça ao Claude
-- (ele lê os atributos pelo MCP do Studio). Ver docs/guia/icones-itens.md.
local VIEWS = {
	["Icons/aloe_vera"] = { IconeGiro = Vector3.new(0, 0, 90) },
	["Icons/aloe_vera/aloe_vera"] = { IconeGiro = Vector3.new(0, 120, 0) },
	["Icons/berry"] = { IconeGiro = Vector3.new(0, 0, 0) },
	["Icons/boar_fur"] = { IconeGiro = Vector3.new(0, 0, 0) },
	["Icons/bread"] = { IconeGiro = Vector3.new(-60, 0, 180) },
	["Icons/cactus"] = { IconeGiro = Vector3.new(-80, 5, 160), IconeZoom = 1.2 },
	["Icons/cake"] = { IconeGiro = Vector3.new(-60, 0, 180) },
	["Icons/carrot"] = { IconeGiro = Vector3.new(-60, 0, 180) },
	["Icons/cooked_fish"] = { IconeGiro = Vector3.new(-60, 0, 180) },
	["Icons/dragon_heart"] = { IconeGiro = Vector3.new(-60, 0, 180) },
	["Icons/flour"] = { IconeGiro = Vector3.new(-60, 0, 180) },
	["Icons/hawk_feather"] = { IconeGiro = Vector3.new(-80, 0, 180) },
	["Icons/lava_heart"] = { IconeGiro = Vector3.new(-60, 0, 180) },
	["Icons/mammoth_fur"] = { IconeGiro = Vector3.new(-70, 0, 180) },
	["Icons/penguin_feather"] = { IconeGiro = Vector3.new(-60, 0, 180) },
	["Icons/sandwich"] = { IconeGiro = Vector3.new(-60, 0, 180) },
	["Icons/sandworm_juice"] = { IconeGiro = Vector3.new(-60, 0, 180) },
	["Icons/tomato"] = { IconeGiro = Vector3.new(-60, 0, 180) },
	["Icons/vulture_feather"] = { IconeGiro = Vector3.new(-60, 0, 180) },
	["Icons/wheat"] = { IconeGiro = Vector3.new(-60, 0, 180) },
	["Tools/book"] = { IconeGiro = Vector3.new(-10, -120, 0) },
	["Tools/bucket"] = { IconeGiro = Vector3.new(-20, 50, 120) },
}

local assets = game:GetService("ReplicatedStorage"):WaitForChild("Assets")
local applied, missing = 0, {}
for key, attributes in VIEWS do
	local target: Instance? = assets
	for name in string.gmatch(key, "[^/]+") do
		target = target and target:FindFirstChild(name)
	end
	if target == nil then
		table.insert(missing, key)
		continue
	end
	for name, value in attributes do
		target:SetAttribute(name, value)
	end
	applied += 1
end
local summary = `[icon-views] {applied} moldes ajustados`
if #missing > 0 then
	summary ..= `; não achados: {table.concat(missing, ", ")}`
end
print(summary)
return summary
