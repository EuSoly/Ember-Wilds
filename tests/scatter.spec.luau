--!strict
local Scatter = require("../src/shared/World/Scatter")
local Shapes = require("../src/shared/World/Shapes")

local MIN_PASSAGE = 5

-- Defs falsas: um recurso grande (árvore) e um pequeno (pedrinha).
local function fakeResources(): any
	return {
		big = { id = "big", nameKey = "resource.big", radius = 5, collisionRadius = 1.2, variants = 3 },
		small = { id = "small", nameKey = "resource.small", radius = 2, collisionRadius = 1, variants = 1 },
	}
end

local function box(cx: number, cz: number, sx: number, sz: number): Shapes.Shape
	return { kind = "box", cx = cx, cz = cz, sx = sx, sz = sz, yaw = 0 }
end

local function disc(cx: number, cz: number, r: number): Shapes.Shape
	return { kind = "disc", cx = cx, cz = cz, r = r }
end

local function baseParams(seed: number): any
	return {
		zones = {
			{ shape = box(0, 0, 200, 200), densities = { big = 10, small = 5 } },
			{ shape = disc(300, 0, 60), densities = { small = 20 } },
		},
		blockers = {},
		fixed = {},
		resources = fakeResources(),
		seed = seed,
		minPassage = MIN_PASSAGE,
	}
end

local function same(a: { Scatter.Placement }, b: { Scatter.Placement }): boolean
	if #a ~= #b then
		return false
	end
	for i, pa in a do
		local pb = b[i]
		if
			pa.resourceId ~= pb.resourceId
			or pa.x ~= pb.x
			or pa.z ~= pb.z
			or pa.variant ~= pb.variant
			or pa.yaw ~= pb.yaw
		then
			return false
		end
	end
	return true
end

local function dist(ax: number, az: number, bx: number, bz: number): number
	return math.sqrt((ax - bx) ^ 2 + (az - bz) ^ 2)
end

return {
	["same seed gives identical lists"] = function()
		local a = Scatter.generate(baseParams(20261029))
		local b = Scatter.generate(baseParams(20261029))
		assert(#a > 0, "deveria gerar algo")
		assert(same(a, b), "mesma semente deveria dar a mesma lista")
	end,

	["different seed gives a different list"] = function()
		local a = Scatter.generate(baseParams(20261029))
		local b = Scatter.generate(baseParams(12345))
		assert(not same(a, b), "semente diferente deveria dar outra lista")
	end,

	["nothing inside a blocker"] = function()
		local params = baseParams(7)
		params.blockers = { disc(0, 0, 40) }
		local resources = fakeResources()
		local placements = Scatter.generate(params)
		assert(#placements > 0, "deveria gerar algo")
		for _, p in placements do
			local radius = resources[p.resourceId].radius
			local d = dist(p.x, p.z, 0, 0)
			assert(d >= 40 + radius - 1e-6, `{p.resourceId} a {d} do centro do bloqueador (mínimo {40 + radius})`)
		end
	end,

	["nothing outside its zone"] = function()
		local params = baseParams(11)
		local placements = Scatter.generate(params)
		for _, p in placements do
			local inside = false
			for _, zone in params.zones do
				if Shapes.contains(zone.shape, p.x, p.z) then
					inside = true
				end
			end
			assert(inside, `{p.resourceId} fora das zonas em ({p.x}, {p.z})`)
		end
	end,

	["minimum passage between every pair"] = function()
		local params = baseParams(3)
		-- Zona apertada e densa para forçar recursos perto uns dos outros.
		params.zones = { { shape = box(0, 0, 120, 120), densities = { big = 200, small = 200 } } }
		local resources = fakeResources()
		local placements = Scatter.generate(params)
		assert(#placements > 10, `deveria gerar vários, gerou {#placements}`)
		for i = 1, #placements do
			for j = i + 1, #placements do
				local a, b = placements[i], placements[j]
				local ra, rb = resources[a.resourceId], resources[b.resourceId]
				local d = dist(a.x, a.z, b.x, b.z)
				local need = ra.collisionRadius + rb.collisionRadius + MIN_PASSAGE
				assert(d >= need - 1e-6, `vão pequeno entre {i} e {j}: {d} < {need}`)
				assert(d >= math.max(ra.radius, rb.radius) - 1e-6, `{i} e {j} encostados: {d}`)
			end
		end
	end,

	["fixed placements take space"] = function()
		local params = baseParams(5)
		local fixed = { resourceId = "big", x = 10, z = 10, variant = 1, yaw = 0 }
		params.fixed = { fixed }
		params.zones = { { shape = box(0, 0, 100, 100), densities = { big = 300, small = 300 } } }
		local resources = fakeResources()
		local placements = Scatter.generate(params)
		assert(#placements > 0, "deveria gerar algo")
		for _, p in placements do
			local r = resources[p.resourceId]
			local need = math.max(
				r.radius,
				resources.big.radius,
				r.collisionRadius + resources.big.collisionRadius + MIN_PASSAGE
			)
			assert(dist(p.x, p.z, fixed.x, fixed.z) >= need - 1e-6, `{p.resourceId} perto demais do fixo`)
		end
	end,

	["density gives the exact count when it fits"] = function()
		local params = baseParams(9)
		params.zones = { { shape = box(0, 0, 100, 100), densities = { small = 4 } } }
		local placements = Scatter.generate(params)
		assert(#placements == 4, `esperava 4, veio {#placements}`)
		for _, p in placements do
			assert(p.resourceId == "small", `recurso inesperado {p.resourceId}`)
			assert(p.variant == 1, `variante fora do limite: {p.variant}`)
			assert(p.yaw >= 0 and p.yaw < 2 * math.pi, `yaw fora de [0, 2π): {p.yaw}`)
		end
	end,

	["variants stay in range"] = function()
		local placements = Scatter.generate(baseParams(21))
		local resources = fakeResources()
		for _, p in placements do
			local variants = resources[p.resourceId].variants
			assert(p.variant >= 1 and p.variant <= variants and p.variant % 1 == 0, `variante {p.variant}`)
		end
	end,

	["impossible zone stops and returns fewer items"] = function()
		local params = baseParams(1)
		-- 40×40 = 1600 studs²; densidade 1.000.000 pediria 160.000 itens.
		params.zones = { { shape = box(0, 0, 40, 40), densities = { big = 1000000 } } }
		params.maxAttemptsPerItem = 30
		local start = os.clock()
		local ok, result = pcall(Scatter.generate, params)
		assert(ok, `não deveria dar erro: {result}`)
		assert(#result > 0 and #result < 160000, `deveria devolver menos itens, veio {#result}`)
		assert(os.clock() - start < 2, "demorou demais numa zona impossível")
	end,

	["unknown resource in a zone is ignored"] = function()
		local params = baseParams(2)
		params.zones = { { shape = box(0, 0, 100, 100), densities = { ghost = 10, small = 4 } } }
		local placements = Scatter.generate(params)
		assert(#placements == 4, `esperava só os 4 conhecidos, veio {#placements}`)
	end,
}
