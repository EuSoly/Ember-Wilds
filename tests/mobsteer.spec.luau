--!strict
-- Desvio dos mobs (MobSteer): simula o mob andando passo a passo com o MobMove,
-- como o MobService faz, e confere que ele chega ao alvo dando a volta no
-- obstáculo em vez de ficar parado empurrando (pedido do Elizeu, 19/11/2026).
local BuildRules = require("../src/shared/Build/BuildRules")
local MobMove = require("../src/shared/Mobs/MobMove")
local MobSteer = require("../src/shared/Mobs/MobSteer")

local RADIUS = 1
local SPEED = 12
local DT = 0.1

type Circle = MobSteer.Circle

-- Anda do (x, z) até o alvo (tx, tz) por até `steps` passos. Devolve se chegou
-- (a 1,5 stud) e se algum passo sobrepôs um obstáculo.
local function chase(
	x: number,
	z: number,
	tx: number,
	tz: number,
	obstacles: { Circle },
	steps: number
): (boolean, boolean, number)
	local memory = MobSteer.new()
	local overlapped = false
	for step = 1, steps do
		local dx, dz = tx - x, tz - z
		local gap = math.sqrt(dx * dx + dz * dz)
		if gap < 1.5 then
			return true, overlapped, step
		end
		local dirX, dirZ = MobSteer.steer(memory, step * DT, x, z, RADIUS, dx, dz, gap, math.pi, obstacles, nil)
		x, z = MobMove.step(x, z, dirX, dirZ, SPEED * DT, RADIUS, obstacles, nil)
		for _, c in obstacles do
			if BuildRules.circlesOverlap(x, z, RADIUS, c.x, c.z, c.radius) then
				overlapped = true
			end
		end
	end
	return false, overlapped, steps
end

return {
	["caminho livre: direção não muda"] = function()
		local memory = MobSteer.new()
		local dx, dz =
			MobSteer.steer(memory, 0, 0, 0, RADIUS, 1, 0, 20, math.pi, { { x = 0, z = 10, radius = 2 } }, nil)
		assert(dx == 1 and dz == 0, `{dx}, {dz}`)
	end,

	["sem desvio o mob fica preso atrás da pedra (o bug)"] = function()
		local rock = { x = 10, z = 0, radius = 3 }
		local x, z = 0, 0
		for _ = 1, 100 do
			x, z = MobMove.step(x, z, 20 - x, -z, SPEED * DT, RADIUS, { rock }, nil)
		end
		assert(20 - x > 5, `sem o desvio já chegava ({x}, {z}): o teste não reproduz o bug`)
	end,

	["pedra entre o mob e o jogador: dá a volta e chega"] = function()
		local reached, overlapped, steps = chase(0, 0, 20, 0, { { x = 10, z = 0, radius = 3 } }, 100)
		assert(reached, "não chegou ao alvo")
		assert(not overlapped, "atravessou a pedra")
		assert(steps < 40, `demorou demais: {steps} passos`)
	end,

	["duas pedras coladas viram um obstáculo só"] = function()
		local rocks = { { x = 10, z = -2.5, radius = 3 }, { x = 10, z = 2.5, radius = 3 } }
		local reached, overlapped = chase(0, 0, 20, 0, rocks, 150)
		assert(reached and not overlapped, `chegou={reached} sobrepôs={overlapped}`)
	end,

	["parede reta curta de peças: contorna pela ponta"] = function()
		local wall = {}
		for i = -3, 3 do
			table.insert(wall, { x = 10, z = i * 2.4, radius = 1.3 })
		end
		local reached, overlapped = chase(0, 0, 20, 0, wall, 200)
		assert(reached and not overlapped, `chegou={reached} sobrepôs={overlapped}`)
	end,

	["histerese: bem atrás do centro, mantém o lado escolhido"] = function()
		local rock = { x = 6, z = 0, radius = 3 }
		local memory = MobSteer.new()
		local _, first = MobSteer.steer(memory, 0, 0, 0, RADIUS, 1, 0, 12, math.pi, { rock }, nil)
		for i = 1, 5 do
			-- Dentro do prazo, mesmo com o mob ligeiramente do outro lado.
			local wobble = if i % 2 == 0 then 0.01 else -0.01
			local _, dz = MobSteer.steer(memory, i * 0.05, 0, wobble, RADIUS, 1, 0, 12, math.pi, { rock }, nil)
			assert(math.sign(dz) == math.sign(first), `trocou de lado no passo {i}`)
		end
	end,

	["fugindo: desvia da pedra sem virar de volta para o jogador"] = function()
		local rock = { x = 5, z = 0, radius = 2 }
		local memory = MobSteer.new()
		local maxTurn = math.pi * 0.6
		local dx, dz = MobSteer.steer(memory, 0, 0, 0, RADIUS, 1, 0, 8, maxTurn, { rock }, nil)
		local angle = math.abs(math.atan2(dz, dx))
		assert(angle > 0.05, "não desviou")
		assert(angle <= maxTurn + 1e-6, `virou demais: {angle}`)
	end,

	["lado bloqueado (água/borda) não é escolhido"] = function()
		local rock = { x = 6, z = 0, radius = 3 }
		local memory = MobSteer.new()
		-- Água em todo z > 0: só sobra o lado de z negativo.
		local _, dz = MobSteer.steer(memory, 0, 0, 0.2, RADIUS, 1, 0, 12, math.pi, { rock }, function(_px, pz)
			return pz > 0
		end)
		assert(dz < 0, `foi para a água: dz = {dz}`)
	end,

	["alvo dentro do círculo (o próprio jogador) não conta como obstáculo"] = function()
		local memory = MobSteer.new()
		local dx, dz =
			MobSteer.steer(memory, 0, 0, 0, RADIUS, 1, 0, 5, math.pi, { { x = 5, z = 0, radius = 1.5 } }, nil)
		assert(dx == 1 and dz == 0, `{dx}, {dz}`)
	end,
}
