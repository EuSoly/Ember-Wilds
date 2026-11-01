--!strict
local BuildRules = require("../src/shared/Build/BuildRules")

local function eq2(a: number, b: number, ea: number, eb: number, msg: string)
	assert(a == ea and b == eb, `{msg}: esperava ({ea}, {eb}), veio ({a}, {b})`)
end

local spec = {}

function spec.cellOf_negativos_e_borda()
	eq2(select(1, BuildRules.cellOf(-0.1, 0)), select(2, BuildRules.cellOf(-0.1, 0)), -1, 0, "cellOf(-0.1, 0)")
	eq2(select(1, BuildRules.cellOf(4, 4)), select(2, BuildRules.cellOf(4, 4)), 1, 1, "cellOf(4, 4)")
	eq2(select(1, BuildRules.cellOf(3.99, -4)), select(2, BuildRules.cellOf(3.99, -4)), 0, -1, "cellOf(3.99, -4)")
end

function spec.cellCenter_e_o_meio_da_celula()
	local x, z = BuildRules.cellCenter(0, 0)
	eq2(x, z, 2, 2, "cellCenter(0, 0)")
	x, z = BuildRules.cellCenter(-1, 2)
	eq2(x, z, -2, 10, "cellCenter(-1, 2)")
end

function spec.targetCell_quatro_direcoes()
	local cx, cz = BuildRules.targetCell(2, 2, 1, 0)
	eq2(cx, cz, 1, 0, "leste")
	cx, cz = BuildRules.targetCell(2, 2, -1, 0)
	eq2(cx, cz, -1, 0, "oeste")
	cx, cz = BuildRules.targetCell(2, 2, 0, 1)
	eq2(cx, cz, 0, 1, "sul")
	cx, cz = BuildRules.targetCell(2, 2, 0, -1)
	eq2(cx, cz, 0, -1, "norte")
end

function spec.key_formata_a_celula()
	assert(BuildRules.key(3, -2) == "3,-2", "key deveria ser 'cx,cz'")
end

function spec.cellsOf_tamanho_1_e_2()
	local one = BuildRules.cellsOf(0, 0, 1)
	assert(#one == 1 and one[1] == "0,0", "size 1 deveria ocupar só 0,0")
	local two = BuildRules.cellsOf(0, 0, 2)
	assert(#two == 4, "size 2 deveria ocupar 4 células")
	local seen: { [string]: boolean } = {}
	for _, k in two do
		seen[k] = true
	end
	assert(seen["0,0"] and seen["1,0"] and seen["0,1"] and seen["1,1"], "size 2 com chaves erradas")
end

function spec.damageOf_mao_e_item()
	assert(BuildRules.damageOf(nil) == 5, "sem item deveria ser o dano da mão")
	local withDamage: any = { structureDamage = 20 }
	assert(BuildRules.damageOf(withDamage) == 20, "item com structureDamage 20")
	local without: any = {}
	assert(BuildRules.damageOf(without) == 5, "item sem structureDamage cai na mão")
end

function spec.areAllies_hoje_so_o_mesmo_jogador()
	assert(BuildRules.areAllies(1, 1), "mesmo UserId é aliado")
	assert(not BuildRules.areAllies(1, 2), "UserIds diferentes não são aliados")
end

function spec.underLimit_sem_limite()
	assert(BuildRules.MAX_PER_PLAYER == nil, "hoje não há limite")
	assert(BuildRules.underLimit(0) and BuildRules.underLimit(100000), "nil = sempre abaixo do limite")
end

function spec.touches_dentro_e_fora_com_margem()
	-- peça 1 célula em (0,0): quadrado de 0 a 4
	assert(BuildRules.touches(2, 2, 0, 0, 1, 0), "centro encosta")
	assert(not BuildRules.touches(5, 2, 0, 0, 1, 0), "fora sem margem")
	assert(BuildRules.touches(5, 2, 0, 0, 1, 1), "dentro da margem")
	assert(not BuildRules.touches(5.5, 2, 0, 0, 1, 1), "além da margem")
	assert(BuildRules.touches(-1, -1, 0, 0, 1, 1), "canto com margem")
	-- peça 2x2: quadrado de 0 a 8
	assert(BuildRules.touches(7, 7, 0, 0, 2, 0), "size 2 cobre 8 studs")
	assert(not BuildRules.touches(9, 7, 0, 0, 2, 0), "size 2 não cobre 9")
end

return spec
