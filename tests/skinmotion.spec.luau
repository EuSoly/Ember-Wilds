--!strict
local SkinMotion = require("../src/shared/Models/SkinMotion")
local SkinManifest = require("../src/shared/Defs/SkinManifest")

local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-6
end

local function maxAngle(motion: SkinMotion.Motion, walk: number): number
	local biggest = 0
	for i = 0, 200 do
		local t = i * 0.037
		local pose = SkinMotion.pose(motion, t, t * 9, walk)
		biggest = math.max(biggest, math.abs(pose.x), math.abs(pose.z))
	end
	return biggest
end

return {
	["every animated part in the manifest has a motion and a pivot"] = function()
		local missing = {}
		for name, info in SkinManifest.PARTS do
			if string.sub(info.papel, 1, 5) == "anim_" and string.sub(info.skinId, 1, 6) ~= "crate_" then
				if SkinMotion.of(info.skinId, info.papel) == nil or info.pivot == nil then
					table.insert(missing, name)
				end
			end
		end
		table.sort(missing)
		assert(#missing == 0, "peça animada sem movimento ou pivô: " .. table.concat(missing, ", "))
	end,

	["every skin with motion has its animated parts exported"] = function()
		for _, skinId in SkinMotion.skins() do
			local found = false
			for _, name in SkinManifest.PARTS_BY_SKIN[skinId] or {} do
				local info = SkinManifest.PARTS[name]
				if SkinMotion.of(skinId, info.papel) then
					found = true
				end
			end
			assert(found, `{skinId}: sem peça animada no SkinManifest`)
		end
	end,

	["the static body does not move"] = function()
		assert(SkinMotion.of("body_dragao", "corpo") == nil, "corpo parado")
		assert(SkinMotion.of("body_lobo", "anim_asa_dir") == nil, "skin sem animação")
	end,

	["dragon wings are mirrored"] = function()
		local right = SkinMotion.of("body_dragao", "anim_asa_dir") :: SkinMotion.Motion
		local left = SkinMotion.of("body_dragao", "anim_asa_esq") :: SkinMotion.Motion
		for _, walk in { 0, 0.5, 1 } do
			local a = SkinMotion.pose(right, 1.3, 2.1, walk)
			local b = SkinMotion.pose(left, 1.3, 2.1, walk)
			assert(near(a.z, -b.z) and near(a.y, -b.y), "asa esquerda espelhada")
		end
	end,

	["walking flaps harder than standing still"] = function()
		local wing = SkinMotion.of("body_dragao", "anim_asa_dir") :: SkinMotion.Motion
		local still, walking = maxAngle(wing, 0), maxAngle(wing, 1)
		assert(walking > 2 * still, `andando {walking} > parado {still}`)
		assert(walking < 0.8, "a asa não dá a volta")
	end,

	["walking follows the steps"] = function()
		local root = SkinMotion.of("body_toco", "anim_raiz_01") :: SkinMotion.Motion
		-- Andando a toda, só a fase dos passos conta: o tempo não muda a pose.
		local a = SkinMotion.pose(root, 0.4, 1.2, 1)
		local b = SkinMotion.pose(root, 7.9, 1.2, 1)
		assert(near(a.y, b.y) and near(a.py, b.py), "segue o passo, não o relógio")
	end,

	["roots alternate in diagonal pairs"] = function()
		local a = SkinMotion.of("body_toco", "anim_raiz_01") :: SkinMotion.Motion
		local b = SkinMotion.of("body_toco", "anim_raiz_02") :: SkinMotion.Motion
		local pa = SkinMotion.pose(a, 0, 0.7, 1)
		local pb = SkinMotion.pose(b, 0, 0.7, 1)
		assert(near(pa.y, -pb.y), "par oposto no passo")
	end,

	["octopus tentacles are out of step"] = function()
		local one = SkinMotion.of("body_polvo", "anim_tentaculo_01") :: SkinMotion.Motion
		local two = SkinMotion.of("body_polvo", "anim_tentaculo_02") :: SkinMotion.Motion
		assert(not near(SkinMotion.pose(one, 0.5, 0, 0).y, SkinMotion.pose(two, 0.5, 0, 0).y), "fora de compasso")
	end,

	["books move the same walking or not"] = function()
		local leaf = SkinMotion.of("book_trepadeira", "anim_folha_03") :: SkinMotion.Motion
		local a = SkinMotion.pose(leaf, 1.1, 0, 0)
		local b = SkinMotion.pose(leaf, 1.1, 3, 1)
		assert(near(a.y, b.y) and near(a.x, b.x), "livro ignora o andar")
	end,

	["snowflake and whirlpool spin"] = function()
		local flake = SkinMotion.of("book_gelo", "anim_floco") :: SkinMotion.Motion
		local whirl = SkinMotion.of("book_tentaculo", "anim_espiral") :: SkinMotion.Motion
		assert(near(SkinMotion.pose(flake, 1, 0, 0).y, 0.6), "floco gira 0,6 rad/s")
		assert(SkinMotion.pose(whirl, 1, 0, 0).y > 0, "ângulo sempre em [0, 2π)")
	end,

	["ice crystals pulse outwards from their corner"] = function()
		local crystal = SkinMotion.of("book_gelo", "anim_cristal_01") :: SkinMotion.Motion
		local seen = false
		for i = 0, 40 do
			local pose = SkinMotion.pose(crystal, i * 0.1, 0, 0)
			if pose.px > 0.01 then
				seen = true
				assert(pose.pz < 0, "canto (+X, -Z): sai junto em X e em -Z")
			end
		end
		assert(seen, "o cristal se afasta do livro")
	end,
}
