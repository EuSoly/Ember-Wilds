--!strict
-- As malhas das skins (SkinManifest, gerado por scripts/gen-skin-manifest.py)
-- e o cadastro das skins (Defs/Cosmetics) precisam andar juntos: malha sem
-- cadastro nunca aparece no jogo; skin de corpo cadastrada sem malha vira o
-- boneco liso.
local Defs = require("../src/shared/Defs")
local SkinManifest = require("../src/shared/Defs/SkinManifest")

return {
	["every skin with meshes is a cosmetic"] = function()
		local missing = {}
		for skinId in SkinManifest.PARTS_BY_SKIN do
			if Defs.Cosmetics[skinId] == nil then
				table.insert(missing, skinId)
			end
		end
		table.sort(missing)
		assert(#missing == 0, "malha sem cadastro em Defs/Cosmetics: " .. table.concat(missing, ", "))
	end,

	["every body cosmetic has meshes"] = function()
		local missing = {}
		for id, def in Defs.Cosmetics do
			if def.slot == "body" and id ~= "body_default" and SkinManifest.PARTS_BY_SKIN[id] == nil then
				table.insert(missing, id)
			end
		end
		table.sort(missing)
		assert(#missing == 0, "skin de corpo sem malha: " .. table.concat(missing, ", "))
	end,

	["every crate cosmetic has meshes"] = function()
		local missing = {}
		for id, def in Defs.Cosmetics do
			if def.slot == "crate" and SkinManifest.PARTS_BY_SKIN[id] == nil then
				table.insert(missing, id)
			end
		end
		table.sort(missing)
		assert(#missing == 0, "caixa sem malha: " .. table.concat(missing, ", "))
	end,

	["crate box sits on the ground"] = function()
		-- O pivô da caixa é o chão (CrateModel/CrateService): o corpo começa em y ≈ 0.
		local info = SkinManifest.PARTS.crate_default_caixa
		assert(info and info.center[2] > 0.5 and info.center[2] < 1.5, "centro da caixa padrão a ~1 stud do chão")
	end,

	["every listed part exists"] = function()
		for skinId, parts in SkinManifest.PARTS_BY_SKIN do
			for _, name in parts do
				assert(SkinManifest.PARTS[name] ~= nil, `{skinId}: peça {name} fora do PARTS`)
			end
		end
	end,
}
