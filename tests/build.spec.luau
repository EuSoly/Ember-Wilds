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

function spec.targetCell_perto_da_borda_e_negativo()
	-- Na borda da própria célula (0 a 4), olhando para fora: pula a vizinha
	-- encostada e cai na seguinte.
	local cx, cz = BuildRules.targetCell(3.9, 2, 1, 0)
	eq2(cx, cz, 2, 0, "x = 3.9 para o leste")
	cx, cz = BuildRules.targetCell(0.1, 2, -1, 0)
	eq2(cx, cz, -2, 0, "x = 0.1 para o oeste")
	-- Coordenadas negativas.
	cx, cz = BuildRules.targetCell(-6, -0.1, 0, -1)
	eq2(cx, cz, -2, -2, "(-6, -0.1) para o norte")
	cx, cz = BuildRules.targetCell(-6, -3.9, 0, 1)
	eq2(cx, cz, -2, 0, "(-6, -3.9) para o sul")
end

-- Ao longo de um eixo, em qualquer posição, a célula-alvo nunca encosta no
-- corpo de quem constrói (raio 1,5: a mesma margem que o servidor usa).
function spec.targetCell_nunca_encosta_no_corpo()
	local dirs = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }
	for i = 0, 160 do
		local p = -10.13 + i * 0.13
		for _, d in dirs do
			for _, q in { -5.3, -0.7, 0.2, 3.9 } do
				local x, z = p, q
				if d[1] == 0 then
					x, z = q, p
				end
				local cx, cz = BuildRules.targetCell(x, z, d[1], d[2])
				assert(
					not BuildRules.touches(x, z, cx, cz, 1, 1.5),
					`({x}, {z}) olhando ({d[1]}, {d[2]}): célula ({cx}, {cz}) encosta no corpo`
				)
			end
		end
	end
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

local function near(a: number, b: number, msg: string)
	assert(math.abs(a - b) < 1e-6, `{msg}: esperava {b}, veio {a}`)
end

-- Diferença de ângulos em graus, módulo 360, no intervalo [-180, 180].
local function angleDiff(a: number, b: number): number
	return (a - b + 180) % 360 - 180
end

function spec.placePoint_quatro_direcoes_e_diagonal()
	local d = BuildRules.PLACE_DISTANCE
	near(d, 5.5, "PLACE_DISTANCE")
	local x, z = BuildRules.placePoint(10, 20, 1, 0)
	near(x, 10 + d, "leste x")
	near(z, 20, "leste z")
	x, z = BuildRules.placePoint(10, 20, -1, 0)
	near(x, 10 - d, "oeste x")
	near(z, 20, "oeste z")
	x, z = BuildRules.placePoint(10, 20, 0, 1)
	near(x, 10, "sul x")
	near(z, 20 + d, "sul z")
	x, z = BuildRules.placePoint(10, 20, 0, -1)
	near(x, 10, "norte x")
	near(z, 20 - d, "norte z")
	local s = math.sqrt(0.5)
	x, z = BuildRules.placePoint(10, 20, s, s)
	near(math.sqrt((x - 10) ^ 2 + (z - 20) ^ 2), d, "distância na diagonal")
end

-- Convenção: yaw em graus em torno de Y; CFrame.Angles(0, rad(yaw), 0) gira anti-horário
-- visto de cima e o LookVector em yaw 0 é -Z, então a frente no plano XZ é (-sin, -cos).
function spec.facingYaw_frente_aponta_para_quem_constroi()
	local cases = {
		{ 0, 0, 0, 5 }, -- construtor ao sul (+Z): yaw 0 olha para -Z, então a peça precisa girar 180
		{ 0, 0, 0, -5 }, -- norte
		{ 0, 0, 5, 0 }, -- leste
		{ 0, 0, -5, 0 }, -- oeste
		{ 3, -2, 7, 4 }, -- qualquer
		{ -8, 6, -9, -1 },
	}
	for _, c in cases do
		local px, pz, fx, fz = c[1], c[2], c[3], c[4]
		local yaw = BuildRules.facingYaw(px, pz, fx, fz, 0)
		local lx, lz = -math.sin(math.rad(yaw)), -math.cos(math.rad(yaw))
		local dx, dz = fx - px, fz - pz
		local len = math.sqrt(dx * dx + dz * dz)
		near(lx, dx / len, `frente x para ({fx}, {fz})`)
		near(lz, dz / len, `frente z para ({fx}, {fz})`)
	end
	-- Valores conhecidos: yaw 0 olha para -Z; yaw 90 olha para -X.
	near(angleDiff(BuildRules.facingYaw(0, 0, 0, -5, 0), 0), 0, "olhando para -Z")
	near(angleDiff(BuildRules.facingYaw(0, 0, -5, 0, 0), 90), 0, "olhando para -X")
end

function spec.facingYaw_soma_45_por_passo()
	for steps = 0, 7 do
		local base = BuildRules.facingYaw(0, 0, 3, 4, 0)
		local yaw = BuildRules.facingYaw(0, 0, 3, 4, steps)
		near(angleDiff(yaw, base + steps * 45), 0, `passo {steps}`)
	end
end

function spec.validSteps_so_inteiro_0_a_7()
	assert(BuildRules.validSteps(0) and BuildRules.validSteps(7), "0 e 7 são válidos")
	assert(BuildRules.validSteps(3), "3 é válido")
	for _, bad in { 8, -1, 1.5, 0 / 0, math.huge, "2", true } do
		assert(not BuildRules.validSteps(bad), `{tostring(bad)} não deveria ser válido`)
	end
	assert(not BuildRules.validSteps(nil), "nil não é válido")
end

function spec.radiusOf_usa_o_padrao_ou_o_da_def()
	local plain: any = { kind = "wall", health = 1 }
	assert(BuildRules.radiusOf(plain) == BuildRules.PIECE_RADIUS, "sem radius cai no padrão")
	local big: any = { kind = "wall", health = 1, radius = 3 }
	assert(BuildRules.radiusOf(big) == 3, "radius da def")
end

function spec.circlesOverlap_encostar_nao_e_sobrepor()
	assert(not BuildRules.circlesOverlap(0, 0, 2, 4, 0, 2), "encostando exatamente não sobrepõe")
	assert(BuildRules.circlesOverlap(0, 0, 2, 3.9, 0, 2), "0,1 para dentro sobrepõe")
	assert(not BuildRules.circlesOverlap(0, 0, 2, 10, 0, 2), "longe não sobrepõe")
	assert(BuildRules.circlesOverlap(0, 0, 2, 0, 0, 1), "um dentro do outro sobrepõe")
end

function spec.touchesCircle_com_margem()
	assert(BuildRules.touchesCircle(0, 0, 0, 0, 2, 0), "centro encosta")
	assert(BuildRules.touchesCircle(3.5, 0, 0, 0, 2, 1.5), "exatamente na margem encosta (<=)")
	assert(not BuildRules.touchesCircle(3.6, 0, 0, 0, 2, 1.5), "além da margem não encosta")
	assert(not BuildRules.touchesCircle(2.1, 0, 0, 0, 2, 0), "fora sem margem")
end

function spec.placePoint_nunca_encosta_no_corpo()
	for i = 0, 15 do
		local a = i * math.pi / 8
		local px, pz = 4.3, -7.1
		local x, z = BuildRules.placePoint(px, pz, math.cos(a), math.sin(a))
		assert(
			not BuildRules.touchesCircle(x, z, px, pz, BuildRules.PIECE_RADIUS, BuildRules.PLAYER_RADIUS),
			`direção {i}: a peça encosta no corpo de quem constrói`
		)
	end
end

function spec.constantes_da_construcao_livre()
	assert(BuildRules.PIECE_RADIUS == 2, "PIECE_RADIUS")
	assert(BuildRules.ROTATE_STEP == 45 and BuildRules.ROTATE_STEPS == 8, "passos de giro")
end

return spec
