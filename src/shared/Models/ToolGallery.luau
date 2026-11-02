--!strict
-- Organização da galeria (jogo, DevWeapons) e da bancada (Edit,
-- scripts/studio/weapon-bench.luau) das ferramentas e armas: uma fileira por
-- tipo, pelo fim do id (wood_pickaxe = pickaxe), em ordem de tier; o que não
-- segue o padrão vai para a fileira "outros", em ordem alfabética. Pura.
local ToolGallery = {}

ToolGallery.KINDS = table.freeze({ "pickaxe", "hammer", "shovel", "sword", "spear", "pitchfork", "shield", "outros" })
ToolGallery.TIERS =
	table.freeze({ "wood", "stone", "gold", "diamond", "amethyst", "reidite", "dragon", "lava", "pirate", "crab" })

export type Row = { kind: string, ids: { string } }

-- Fileiras não vazias, na ordem de KINDS.
function ToolGallery.rows(ids: { string }): { Row }
	local byKind: { [string]: { string } } = {}
	for _, kind in ToolGallery.KINDS do
		byKind[kind] = {}
	end
	local tierIndex: { [string]: number } = {}
	for i, tier in ToolGallery.TIERS do
		tierIndex[tier] = i
	end
	for _, id in ids do
		local tier, kind = id:match("^(%a+)_(%a+)$")
		local row = if tier and tierIndex[tier] and kind and byKind[kind] then kind else "outros"
		table.insert(byKind[row], id)
	end

	local rows: { Row } = {}
	for _, kind in ToolGallery.KINDS do
		local list = byKind[kind]
		if #list == 0 then
			continue
		end
		table.sort(list, function(a, b)
			local ta = tierIndex[a:match("^(%a+)_") or ""] or 99
			local tb = tierIndex[b:match("^(%a+)_") or ""] or 99
			if kind ~= "outros" and ta ~= tb then
				return ta < tb
			end
			return a < b
		end)
		table.insert(rows, { kind = kind, ids = list })
	end
	return rows
end

return ToolGallery
