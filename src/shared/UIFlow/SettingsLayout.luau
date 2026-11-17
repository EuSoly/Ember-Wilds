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

-- Altura de uma coluna com estes grupos (títulos, linhas e espaços).
function SettingsLayout.columnHeight(groups: { Group }): number
	local items, height = 0, 0
	for _, group in groups do
		height += SettingsLayout.HEADER_COMPACT
		items += 1
		for _ in group.settings do
			height += SettingsLayout.ROW_COMPACT
			items += 1
		end
	end
	return height + math.max(items - 1, 0) * SettingsLayout.GAP
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
