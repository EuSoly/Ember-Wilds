--!strict
-- Folha da porta aberta: anda para fora do centro da porta, na direção do
-- próprio centro, a largura dela nessa direção (StructureModel.setOpen).
local DoorSlide = require("../src/shared/Build/DoorSlide")

local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-6
end

return {
	["folhas lado a lado em X saem cada uma para o seu lado, a própria largura"] = function()
		local dx, dz = DoorSlide.offset(1, 0, 2, 0.3)
		assert(near(dx, 2) and near(dz, 0), `direita: {dx}, {dz}`)
		dx, dz = DoorSlide.offset(-1, 0, 2, 0.3)
		assert(near(dx, -2) and near(dz, 0), `esquerda: {dx}, {dz}`)
	end,

	["folha mais estreita anda menos"] = function()
		local dx, dz = DoorSlide.offset(0.6, 0, 1.2, 0.3)
		assert(near(dx, 1.2) and near(dz, 0), `{dx}, {dz}`)
	end,

	["folha em Z usa a medida em Z"] = function()
		local dx, dz = DoorSlide.offset(0, -0.9, 0.3, 1.8)
		assert(near(dx, 0) and near(dz, -1.8), `{dx}, {dz}`)
	end,

	["folha fora do eixo anda na direção do centro dela"] = function()
		-- Direção (0,6; 0,8): largura da caixa 2 × 1 nessa direção = 0,6·2 + 0,8·1 = 2.
		local dx, dz = DoorSlide.offset(0.6, 0.8, 2, 1)
		assert(near(dx, 1.2) and near(dz, 1.6), `{dx}, {dz}`)
	end,

	["folha no centro da porta (ou conta inválida) não anda"] = function()
		local dx, dz = DoorSlide.offset(0, 0, 2, 0.3)
		assert(dx == 0 and dz == 0, `centro: {dx}, {dz}`)
		dx, dz = DoorSlide.offset(0 / 0, 0, 2, 0.3)
		assert(dx == 0 and dz == 0, `NaN: {dx}, {dz}`)
		dx, dz = DoorSlide.offset(1, 0, 0 / 0, 0.3)
		assert(dx == 0 and dz == 0, `largura NaN: {dx}, {dz}`)
	end,
}
