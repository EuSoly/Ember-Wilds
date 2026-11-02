--!strict
-- Números do boneco: tamanho das peças, corpo simulado e animações.
-- Só números (sem APIs do Roblox), para os testes do Lune lerem os mesmos
-- valores. Para ajustar o visual ou o ritmo das animações, mexa aqui.
-- Veja docs/guia/boneco.md (o que cada campo faz).
return table.freeze({
	-- Geometria do boneco visual (studs) — valores do spike aprovado.
	BODY_WIDTH = 3.6,
	BODY_HEIGHT = 2,
	BODY_DEPTH = 3.6,
	CORNER_RADIUS = 0.9, -- raio dos cantos arredondados (vista de cima)
	OUTLINE = 0.2, -- quanto o contorno passa do corpo em X/Z
	OUTLINE_DROP = 0.1, -- quanto o topo do contorno fica abaixo do topo do corpo
	EYE_DIAMETER = 0.95,
	EYE_X = 0.8, -- olhos em x = ±EYE_X
	EYE_Z = -0.55, -- negativo = puxado para a frente
	SHINE_FRACTION = 0.32, -- brilho do olho, em fração do diâmetro do olho
	HAND_DIAMETER = 1.3,
	HAND_X = 1.95, -- mãos em x = ±HAND_X
	HAND_Y = 0.2, -- acima do centro do corpo
	HAND_Z = -1.45, -- à frente do centro do corpo
	HAND_OUTLINE_DROP = 0.4, -- contorno da mão mais baixo que a mão
	NAME_HEIGHT = 3.2, -- etiqueta do nome, acima do centro do corpo

	-- Corpo simulado (servidor, studs). O centro do HumanoidRootPart fica em
	-- HIP_HEIGHT + ROOT_HEIGHT / 2 = 1 stud do chão = centro do corpo visual.
	ROOT_WIDTH = 3,
	ROOT_HEIGHT = 1.6,
	ROOT_DEPTH = 3,
	HIP_HEIGHT = 0.2,
	HEAD_HEIGHT = 3.4, -- centro da Head invisível acima do HumanoidRootPart (balão do chat)
	VISUAL_OFFSET_Y = 0, -- centro do corpo visual em relação ao HumanoidRootPart

	-- Andar e parado.
	WALK_SPEED_REF = 16, -- studs/s considerados "andando a toda"
	STEP_RATE = 0.9, -- rad por stud andado (ritmo dos passos)
	BOB_HEIGHT = 0.18, -- studs, altura do quique ao andar
	HAND_SWAY = 0.35, -- studs, balanço das mãos para frente/trás ao andar
	BREATHE_HEIGHT = 0.06, -- studs, sobe/desce das mãos parado
	BREATHE_PERIOD = 2.4, -- segundos por respiração
	SPEED_SMOOTHING = 12, -- 1/s; maior = troca parado↔andando mais rápido

	-- Golpe e soco.
	SWING_PERIOD = 0.5, -- segundos por golpe (ida + volta); igual ao GatherRules.HIT_INTERVAL
	SWING_ATTACK_FRACTION = 0.35, -- fração do golpe gasta na ida (o resto é a volta)
	SWING_REST_ANGLE = 35, -- graus; a ferramenta em repouso aponta para fora (direita)
	SWING_ARC = 90, -- graus; quanto a mão da ferramenta gira no golpe
	OTHER_HAND_RECOIL = 0.3, -- studs; a outra mão recua durante o golpe
	PUNCH_DISTANCE = 1.2, -- studs; alcance do soco de mão vazia
	-- Estocada (itens com attackAnim "thrust": as lanças). Segurando, as mãos
	-- ficam do lado do corpo (recuadas THRUST_HOLD_BACK); na estocada a mão da
	-- arma avança THRUST_DISTANCE, para a frente do corpo (como no Starve).
	THRUST_HOLD_BACK = 1.45, -- studs; mãos recuadas para o lado do corpo
	THRUST_DISTANCE = 1.9, -- studs; quanto a mão avança na estocada
	THRUST_REST_ANGLE = -8, -- graus; negativo = a ponta um pouco para dentro

	-- Desempenho e expressões.
	ANIM_RANGE = 120, -- studs da câmera; mais longe só segue a posição, sem animar
	HURT_RECENT = 1, -- segundos; HurtAt mais antigo que isso não mostra a careta
	MAX_DT = 0.1, -- segundos; limite do passo (quadro travado não faz a animação pular)
})
