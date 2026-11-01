--!strict
local BuildRules = require("../src/shared/Build/BuildRules")

local spec = {}

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
