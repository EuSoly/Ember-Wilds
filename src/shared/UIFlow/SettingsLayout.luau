--!strict
-- Configurações no celular deitado (17/11/2026): duas colunas, sem rolar.
-- Os grupos (Som, Tela, Controles: SettingsFormat.grouped) se dividem entre
-- as colunas sem quebrar grupo e sem trocar a ordem, deixando a coluna mais
-- alta o mais baixa possível. Configuração nova entra sozinha na conta.
local SettingsFormat = require("./SettingsFormat")

type Group = SettingsFormat.Group

local SettingsLayout = {}

SettingsLayout.ROW_COMPACT = 40 -- altura da linha de uma opção
SettingsLayout.HEADER_COMPACT = 24 -- altura do título do grupo
SettingsLayout.GAP = 4 -- entre linhas
-- Lista única do PC. Com a linha do zoom (17/11) as medidas antigas (linha
-- 50, título 30, espaço 6) faziam a lista rolar em 1280x720 e a opção nova
-- ficava escondida.
SettingsLayout.ROW_PC = 44
SettingsLayout.HEADER_PC = 24
SettingsLayout.GAP_PC = 4

-- Altura de uma lista com estes grupos: títulos de `header`, linhas de `row`
-- e `gap` entre cada item.
function SettingsLayout.listHeight(groups: { Group }, row: number, header: number, gap: number): number
	local items, height = 0, 0
	for _, group in groups do
		height += header
		items += 1
		for _ in group.settings do
			height += row
			items += 1
		end
	end
	return height + math.max(items - 1, 0) * gap
end

-- Altura de uma coluna do celular com estes grupos.
function SettingsLayout.columnHeight(groups: { Group }): number
	return SettingsLayout.listHeight(
		groups,
		SettingsLayout.ROW_COMPACT,
		SettingsLayout.HEADER_COMPACT,
		SettingsLayout.GAP
	)
end

-- Esquerda e direita: o corte entre grupos que deixa a coluna mais alta menor.
function SettingsLayout.split(groups: { Group }): ({ Group }, { Group })
	local best, bestHeight = #groups, math.huge
	for cut = 1, #groups do
		local left = table.move(groups, 1, cut, 1, {})
		local right = table.move(groups, cut + 1, #groups, 1, {})
		local tallest = math.max(SettingsLayout.columnHeight(left), SettingsLayout.columnHeight(right))
		if tallest < bestHeight then
			best, bestHeight = cut, tallest
		end
	end
	return table.move(groups, 1, best, 1, {}), table.move(groups, best + 1, #groups, 1, {})
end

return SettingsLayout
