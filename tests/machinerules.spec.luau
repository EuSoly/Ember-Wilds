--!strict
local MachineRules = require("../src/shared/Build/MachineRules")

-- Os números da wiki (extrator de pedra/ouro e fornalha dos Defs).
local EXTRACTOR = { output = "stone", woodPerCycle = 2, cycleSeconds = 10, yield = 1, maxWood = 100, maxStock = 100 }
local FURNACE = { burnEvery = 6, maxWood = 200 }

local spec = {}

function spec.extrator_ciclo_2_madeiras_1_pedra_a_cada_10s()
	local s = { wood = 10, stock = 0, timer = 0 }
	s = MachineRules.extractorStep(s, EXTRACTOR, 9.5)
	assert(s.wood == 10 and s.stock == 0, "antes de 10 s nada muda")
	assert(MachineRules.isWorking(s, EXTRACTOR), "com madeira e espaço trabalha")
	s = MachineRules.extractorStep(s, EXTRACTOR, 0.5)
	assert(s.wood == 8 and s.stock == 1, `10 s: 2 madeiras → 1 pedra (wood {s.wood}, stock {s.stock})`)
	-- Passos de 0,5 s (o loop do servidor) por mais 20 s: mais 2 ciclos.
	for _ = 1, 40 do
		s = MachineRules.extractorStep(s, EXTRACTOR, 0.5)
	end
	assert(s.wood == 4 and s.stock == 3, `30 s: 3 ciclos (wood {s.wood}, stock {s.stock})`)
	-- Um passo grande conta todos os ciclos dele.
	s = MachineRules.extractorStep(s, EXTRACTOR, 20)
	assert(s.wood == 0 and s.stock == 5, `passo de 20 s = 2 ciclos (wood {s.wood}, stock {s.stock})`)
end

function spec.extrator_para_sem_madeira()
	local s = { wood = 1, stock = 0, timer = 0 }
	assert(not MachineRules.isWorking(s, EXTRACTOR), "1 madeira não basta para um ciclo")
	s = MachineRules.extractorStep(s, EXTRACTOR, 60)
	assert(s.wood == 1 and s.stock == 0, "sem madeira para o ciclo, nada muda")
	assert(s.timer == 0, "parado não acumula tempo")
	-- Gasta a madeira e para.
	s = MachineRules.extractorStep({ wood = 2, stock = 0, timer = 0 }, EXTRACTOR, 100)
	assert(s.wood == 0 and s.stock == 1 and s.timer == 0, "um ciclo só e para")
end

function spec.extrator_para_com_estoque_cheio()
	local s = { wood = 10, stock = 99, timer = 0 }
	s = MachineRules.extractorStep(s, EXTRACTOR, 10)
	assert(s.wood == 8 and s.stock == 100, "chegou ao máximo")
	assert(not MachineRules.isWorking(s, EXTRACTOR), "cheio não trabalha")
	s = MachineRules.extractorStep(s, EXTRACTOR, 100)
	assert(s.wood == 8 and s.stock == 100 and s.timer == 0, "cheio: não gasta madeira nem produz")
end

function spec.extrator_nao_muda_o_estado_recebido()
	local s = { wood = 4, stock = 0, timer = 0 }
	MachineRules.extractorStep(s, EXTRACTOR, 10)
	assert(s.wood == 4 and s.stock == 0 and s.timer == 0, "devolve um estado novo")
end

function spec.fornalha_queima_1_a_cada_6s_e_apaga_em_0()
	local s = { wood = 2, timer = 0 }
	assert(MachineRules.isLit(s), "com madeira: acesa")
	s = MachineRules.furnaceStep(s, FURNACE, 5.5)
	assert(s.wood == 2, "antes de 6 s não queima")
	s = MachineRules.furnaceStep(s, FURNACE, 0.5)
	assert(s.wood == 1 and MachineRules.isLit(s), "6 s: queimou 1, ainda acesa")
	for _ = 1, 12 do
		s = MachineRules.furnaceStep(s, FURNACE, 0.5)
	end
	assert(s.wood == 0 and not MachineRules.isLit(s), "12 s: apagou em 0")
	assert(s.timer == 0, "apagada não acumula tempo")
	s = MachineRules.furnaceStep(s, FURNACE, 60)
	assert(s.wood == 0 and s.timer == 0 and not MachineRules.isLit(s), "apagada fica apagada")
	-- Passo grande não passa de 0.
	s = MachineRules.furnaceStep({ wood = 3, timer = 0 }, FURNACE, 600)
	assert(s.wood == 0 and not MachineRules.isLit(s), "não fica negativa")
end

function spec.passo_invalido_nao_muda_nada()
	for _, dt in { 0, -1, 0 / 0 } do
		local e = MachineRules.extractorStep({ wood = 10, stock = 0, timer = 9 }, EXTRACTOR, dt)
		assert(e.wood == 10 and e.stock == 0 and e.timer == 9, `extrator com dt {dt}`)
		local f = MachineRules.furnaceStep({ wood = 10, timer = 5 }, FURNACE, dt)
		assert(f.wood == 10 and f.timer == 5, `fornalha com dt {dt}`)
	end
end

function spec.putWood_respeita_o_maximo()
	assert(MachineRules.WOOD_PER_PUT == 10, "até 10 por ação")
	assert(MachineRules.putWood(0, 50, 100) == 10, "até 10 por ação")
	assert(MachineRules.putWood(0, 3, 100) == 3, "só o que o jogador tem")
	assert(MachineRules.putWood(95, 50, 100) == 5, "só até o máximo")
	assert(MachineRules.putWood(100, 50, 100) == 0, "cheia: nada")
	assert(MachineRules.putWood(0, 0, 100) == 0, "sem madeira: nada")
	assert(MachineRules.putWood(120, 50, 100) == 0, "acima do máximo: nada (nunca negativo)")
	assert(MachineRules.putWood(0, 0 / 0, 100) == 0, "NaN: nada")
end

return spec
