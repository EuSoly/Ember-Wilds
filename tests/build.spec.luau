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

function spec.isDoor_porta_e_porta_com_espinhos()
	assert(BuildRules.isDoor("door"), "porta é porta")
	assert(BuildRules.isDoor("spike_door"), "porta com espinhos é porta")
	assert(not BuildRules.isDoor("spike"), "espinho não é porta")
	assert(not BuildRules.isDoor("wall"), "parede não é porta")
end

function spec.hurts_espinho_e_porta_com_espinhos()
	assert(BuildRules.hurts("spike"), "espinho fere")
	assert(BuildRules.hurts("spike_door"), "porta com espinhos fere")
	assert(not BuildRules.hurts("door"), "porta comum não fere")
	assert(not BuildRules.hurts("wall"), "parede não fere")
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

function spec.insideAny_dentro_fora_borda_e_vazio()
	local circles = { { x = 0, z = 0, r = 2 }, { x = 10, z = 0, r = 1 } }
	assert(BuildRules.insideAny(0.5, -0.5, circles), "dentro do primeiro")
	assert(BuildRules.insideAny(10.5, 0, circles), "dentro do segundo")
	assert(not BuildRules.insideAny(5, 0, circles), "entre os dois: fora")
	assert(not BuildRules.insideAny(0, 2.01, circles), "logo além da borda: fora")
	assert(BuildRules.insideAny(2, 0, circles), "exatamente na borda conta como dentro")
	assert(BuildRules.insideAny(10, -1, circles), "na borda do segundo")
	assert(not BuildRules.insideAny(0, 0, {}), "lista vazia: nunca dentro")
end

function spec.insideAny_com_margem()
	local circles = { { x = 0, z = 0, r = 2 } }
	assert(BuildRules.insideAny(3, 0, circles, 1), "na borda expandida conta")
	assert(not BuildRules.insideAny(3.01, 0, circles, 1), "além da margem: fora")
	assert(not BuildRules.insideAny(3, 0, circles), "sem margem: fora")
end

-- Ruling 11: uma fila de pontes postas a PLACE_DISTANCE dá caminho seco.
function spec.onBridge_emenda_entre_duas_pontes_e_seca()
	local r = 2.1 -- raio da ponte nos dados
	local d = BuildRules.PLACE_DISTANCE
	local bridges = { { x = 0, z = 0, r = r }, { x = d, z = 0, r = r } }
	assert(d == 5.5, "pontes a 5,5 uma da outra")
	assert(not BuildRules.insideAny(d / 2, 0, bridges), "sem margem o meio seria água (o bug)")
	assert(BuildRules.onBridge(d / 2, 0, bridges), "o meio entre as duas é seco")
	assert(BuildRules.onBridge(0, 0, bridges), "centro da ponte")
	assert(BuildRules.onBridge(0, r + BuildRules.PLAYER_RADIUS, bridges), "na borda do corpo ainda conta")
	assert(not BuildRules.onBridge(0, r + BuildRules.PLAYER_RADIUS + 0.01, bridges), "além do corpo: água")
	assert(not BuildRules.onBridge(0, 0, {}), "sem ponte: nunca")
end

function spec.layerOf_ponte_telhado_e_o_resto()
	assert(BuildRules.layerOf("bridge") == "bridge", "ponte")
	assert(BuildRules.layerOf("roof") == "roof", "telhado")
	for _, kind in { "wall", "door", "spike", "spike_door", "station", "fire", "chest", "well", "bed" } do
		assert(BuildRules.layerOf(kind) == "solid", `{kind} é sólida`)
		assert(BuildRules.isSolid(kind), `{kind} segura corpos`)
	end
	assert(not BuildRules.isSolid("bridge"), "ponte não segura corpos")
	assert(not BuildRules.isSolid("roof"), "telhado não segura corpos")
end

function spec.blocksPlacement_so_na_mesma_camada()
	assert(BuildRules.blocksPlacement("bridge", "bridge"), "ponte sobre ponte não")
	assert(BuildRules.blocksPlacement("roof", "roof"), "telhado sobre telhado não")
	assert(BuildRules.blocksPlacement("wall", "spike"), "parede sobre espinho não")
	assert(not BuildRules.blocksPlacement("roof", "wall"), "telhado sobre parede pode")
	assert(not BuildRules.blocksPlacement("wall", "roof"), "parede debaixo do telhado pode")
	assert(not BuildRules.blocksPlacement("bridge", "wall"), "ponte encostando na parede da margem pode")
	assert(not BuildRules.blocksPlacement("wall", "bridge"), "parede na margem encostando na ponte pode")
	assert(not BuildRules.blocksPlacement("bridge", "roof"), "ponte e telhado não se veem")
end

-- Desde 11/11 a ponte é o "piso": vale na terra também (piso_na_terra_e_na_agua).
function spec.waterAllows_piso_em_qualquer_lugar_o_resto_so_na_terra()
	assert(BuildRules.waterAllows("bridge", true), "piso na água pode")
	assert(BuildRules.waterAllows("bridge", false), "piso em terra também")
	for _, kind in { "wall", "roof", "spike", "fire", "chest" } do
		assert(BuildRules.waterAllows(kind, false), `{kind} em terra pode`)
		assert(not BuildRules.waterAllows(kind, true), `{kind} na água não`)
	end
end

function spec.constantes_da_construcao_livre()
	assert(BuildRules.PIECE_RADIUS == 2, "PIECE_RADIUS")
	assert(BuildRules.ROTATE_STEP == 45 and BuildRules.ROTATE_STEPS == 8, "passos de giro")
end

-- Encaixe em grade (telhado, ponte): vizinha de raio 3 = casa de 6 studs.
local function close(a: number, b: number): boolean
	return math.abs(a - b) < 1e-6
end

function spec.encaixe_sem_vizinha_fica_livre()
	local x, z, yaw = BuildRules.snapPlacement(4, 5, 30, 0, -1, {})
	assert(x == 4 and z == 5 and yaw == 30, "sem vizinha não muda nada")
end

function spec.encaixe_na_casa_ao_lado()
	local x, z, yaw = BuildRules.snapPlacement(6.5, 0.4, 90, 1, 0, { { x = 0, z = 0, yaw = 0, radius = 3 } })
	assert(close(x, 6) and close(z, 0), `casa ao lado: {x}, {z}`)
	assert(yaw == 0, "copia o giro da vizinha")
end

function spec.encaixe_respeita_giro_da_vizinha()
	local c, s = math.cos(math.rad(45)), math.sin(math.rad(45))
	-- Casa +1 no eixo X local da vizinha girada 45°: (6·cos, −6·sin).
	local x, z, yaw = BuildRules.snapPlacement(6 * c + 0.5, -6 * s + 0.3, 0, 1, 0, {
		{ x = 0, z = 0, yaw = 45, radius = 3 },
	})
	assert(close(x, 6 * c) and close(z, -6 * s), `casa girada: {x}, {z}`)
	assert(yaw == 45, "giro 45")
end

function spec.encaixe_em_cima_da_vizinha_vai_para_o_lado()
	-- Ponto livre quase no centro da vizinha, olhando para −Z: casa (0, −6).
	local x, z = BuildRules.snapPlacement(0.5, 0.5, 0, 0, -1, { { x = 0, z = 0, yaw = 0, radius = 3 } })
	assert(close(x, 0) and close(z, -6), `casa da frente: {x}, {z}`)
end

function spec.encaixe_vizinha_longe_nao_puxa()
	local x, z = BuildRules.snapPlacement(20, 0, 0, 1, 0, { { x = 0, z = 0, yaw = 0, radius = 3 } })
	assert(x == 20 and z == 0, "longe demais")
end

function spec.encaixe_no_canto_tambem_gruda()
	-- Ponto na diagonal entre as casas (sem zona morta): vai para a casa (1, 1).
	local x, z = BuildRules.snapPlacement(3.3, 3.3, 0, 1, 0, { { x = 0, z = 0, yaw = 0, radius = 3 } })
	assert(close(x, 6) and close(z, 6), `canto: {x}, {z}`)
end

function spec.encaixe_escolhe_a_vizinha_mais_perto()
	-- Vizinhas em grades desalinhadas, (0, 0) e (0, 13): o ponto (6.5, 11) está
	-- mais perto da segunda, que leva a (6, 13); a primeira levaria a (6, 12).
	local x, z = BuildRules.snapPlacement(6.5, 11, 0, 1, 0, {
		{ x = 0, z = 0, yaw = 0, radius = 3 },
		{ x = 0, z = 13, yaw = 0, radius = 3 },
	})
	assert(close(x, 6) and close(z, 13), `casa da vizinha mais perto: {x}, {z}`)
end

function spec.espinho_machuca_quem_bate()
	local spike: any = { kind = "spike", health = 150, spikeDamage = 10, spikeHitDamage = 2 }
	assert(BuildRules.spikeHitDamage(spike, false) == 2, "estranho que bate leva o dano de bater")
	assert(BuildRules.spikeHitDamage(spike, true) == 0, "dono e aliado não levam")
	local wall: any = { kind = "wall", health = 1000 }
	assert(BuildRules.spikeHitDamage(wall, false) == 0, "parede não machuca")
end

function spec.telhados_translucidos_na_tela()
	local circles = {
		{ x = 0, z = 0, r = 3 }, -- em cima do jogador
		{ x = 30, z = 0, r = 3 }, -- longe, mas na tela
		{ x = 500, z = 0, r = 3 }, -- fora da tela
	}
	local under = BuildRules.roofsToFade(1, 1, circles, 80)
	assert(under[1] and under[2] and not under[3], "debaixo de um: todos da tela")
	local outside = BuildRules.roofsToFade(15, 0, circles, 80)
	assert(next(outside) == nil, "fora de qualquer telhado: nenhum")
end

function spec.telhado_sem_buraco_entre_os_quadrados()
	-- Quatro telhados encaixados (lado 6): o canto comum fica a 4,24 dos centros,
	-- fora do círculo de raio 3, mas debaixo do telhado quadrado.
	local circles = {
		{ x = 0, z = 0, r = 3 },
		{ x = 6, z = 0, r = 3 },
		{ x = 0, z = 6, r = 3 },
		{ x = 6, z = 6, r = 3 },
	}
	assert(next(BuildRules.roofsToFade(3, 3, circles, 80)) ~= nil, "no canto entre quatro telhados ainda está debaixo")
	assert(next(BuildRules.roofsToFade(3, 0, circles, 80)) ~= nil, "na emenda entre dois também")
end

function spec.telhado_nao_pisca_na_borda()
	local circles = { { x = 0, z = 0, r = 3 } }
	-- Pouco fora do telhado: quem não estava debaixo não apaga...
	assert(next(BuildRules.roofsToFade(5, 0, circles, 80, false)) == nil, "entrando: ainda não")
	-- ...mas quem já estava continua apagado (folga para sair).
	assert(next(BuildRules.roofsToFade(5, 0, circles, 80, true)) ~= nil, "saindo: continua apagado")
	assert(next(BuildRules.roofsToFade(12, 0, circles, 80, true)) == nil, "longe: volta ao normal")
end

function spec.limite_por_jogador()
	assert(BuildRules.underKindLimit(0, 1), "a primeira pode")
	assert(not BuildRules.underKindLimit(1, 1), "a segunda não")
	assert(BuildRules.underKindLimit(50, nil), "sem limite")
end

function spec.piso_na_terra_e_na_agua()
	assert(BuildRules.waterAllows("bridge", false), "piso na terra")
	assert(BuildRules.waterAllows("bridge", true), "piso na água")
	assert(not BuildRules.waterAllows("wall", true), "parede na água não")
	assert(BuildRules.waterAllows("wall", false), "parede na terra")
end

function spec.jogador_nao_bloqueia_piso_nem_telhado()
	assert(not BuildRules.blockedByPlayers("bridge"), "piso: dá para estar em cima")
	assert(not BuildRules.blockedByPlayers("roof"), "telhado: por cima de quem está embaixo")
	assert(BuildRules.blockedByPlayers("wall"), "parede: não em cima de jogador")
end

function spec.piso_encaixado_nao_conta_como_sobreposto()
	-- Casa vizinha calculada com seno/cosseno: a distância sai um fio menor que
	-- 2 × raio por arredondamento. Encostar continua valendo.
	local neighbor = { x = -634.34, z = 626.63, yaw = -127.8, radius = 3.1 }
	local look = math.rad(-127.8)
	local x, z =
		BuildRules.snapPlacement(neighbor.x + 1, neighbor.z + 1, 0, -math.sin(look), -math.cos(look), { neighbor })
	assert(
		not BuildRules.circlesOverlap(x, z, 3.1, neighbor.x, neighbor.z, 3.1),
		"casa vizinha encosta, não sobrepõe"
	)
	assert(not BuildRules.circlesOverlap(0, 0, 3, 6 - 1e-9, 0, 3), "encostar com arredondamento")
	assert(BuildRules.circlesOverlap(0, 0, 3, 5.9, 0, 3), "sobrepor de verdade continua barrado")
end

return spec
