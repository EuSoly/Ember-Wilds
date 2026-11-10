--!strict
-- Listas de ids de arte para pré-carregar (puro, testado no Lune): junta os
-- ids das tabelas de imagens (HudImages, ShopImages...) e organiza os grupos em
-- ordem de prioridade, sem repetir um id entre grupos. Quem carrega é o
-- AssetPreloader (cliente).
local AssetIds = {}

export type Group = { name: string, ids: { string } }

-- true se `value` parece um endereço de arte do Roblox.
function AssetIds.isAsset(value: string): boolean
	return string.match(value, "^rbxassetid://%d+") ~= nil
		or string.match(value, "^rbxasset://") ~= nil
		or string.match(value, "^https?://www%.roblox%.com/asset") ~= nil
end

-- Todos os ids de arte dentro de uma tabela (e das tabelas dentro dela), uma vez cada.
function AssetIds.fromTable(tbl: { [any]: any }): { string }
	local seen: { [string]: true } = {}
	local out: { string } = {}
	local visited: { [any]: true } = {}
	local function walk(value: any)
		if type(value) == "string" then
			if AssetIds.isAsset(value) and not seen[value] then
				seen[value] = true
				table.insert(out, value)
			end
		elseif type(value) == "table" and not visited[value] then
			visited[value] = true
			for _, child in value do
				walk(child)
			end
		end
	end
	walk(tbl)
	return out
end

-- Os grupos na mesma ordem, cada id só no primeiro grupo em que aparece.
function AssetIds.merge(groups: { Group }): { Group }
	local seen: { [string]: true } = {}
	local out: { Group } = {}
	for _, group in groups do
		local ids: { string } = {}
		for _, id in group.ids do
			if not seen[id] then
				seen[id] = true
				table.insert(ids, id)
			end
		end
		table.insert(out, { name = group.name, ids = ids })
	end
	return out
end

function AssetIds.total(groups: { Group }): number
	local n = 0
	for _, group in groups do
		n += #group.ids
	end
	return n
end

return AssetIds
