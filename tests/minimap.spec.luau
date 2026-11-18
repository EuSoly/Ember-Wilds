--!strict
local MinimapRules = require("../src/shared/World/MinimapRules")
local WorldConfig = require("../src/shared/WorldConfig")

local spec = {}

local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-6
end

function spec.bioma_onde_o_jogador_esta()
	assert(MinimapRules.biomeAt(-630, 630) == "forest", "centro da floresta")
	assert(MinimapRules.biomeAt(630, 630) == "desert", "deserto")
	assert(MinimapRules.biomeAt(-630, -630) == "winter", "inverno")
	assert(MinimapRules.biomeAt(630, -630) == "lava", "lava")
end

function spec.no_oceano_mostra_o_bioma_mais_perto()
	-- Na cruz do oceano, 20 studs a leste da floresta (borda X = -150).
	assert(MinimapRules.biomeAt(-130, 630) == "forest", "perto da floresta")
	assert(MinimapRules.biomeAt(130, 630) == "desert", "perto do deserto")
end

function spec.posicao_no_bioma_vai_de_0_a_1()
	local forest = WorldConfig.BIOMES.forest
	local x, y = MinimapRules.toView(-630, 630, forest)
	assert(near(x, 0.5) and near(y, 0.5), "centro")
	x, y = MinimapRules.toView(forest.minX, forest.minZ, forest)
	assert(near(x, 0) and near(y, 0), "canto de cima à esquerda = -X, -Z")
	x, y = MinimapRules.toView(5000, 5000, forest)
	assert(x == 1 and y == 1, "fora: preso na borda")
end

function spec.seta_aponta_para_onde_o_jogador_olha()
	-- Na tela: cima = -Z, direita = +X; Rotation do Roblox é horária.
	assert(near(MinimapRules.heading(0, -1), 0), "para -Z: para cima")
	assert(near(MinimapRules.heading(1, 0), 90), "para +X: direita")
	assert(near(math.abs(MinimapRules.heading(0, 1)), 180), "para +Z: para baixo")
	assert(near(MinimapRules.heading(-1, 0), -90), "para -X: esquerda")
end

function spec.no_pc_o_mapa_e_maior_e_os_botoes_alinham_nas_bordas()
	local pc = MinimapRules.layout(1280, 720, false)
	local phone = MinimapRules.layout(800, 360, true)
	assert(pc.mapSize > phone.mapSize, "maior no PC")
	-- Livro na borda esquerda do mapa e engrenagem na direita: cabem lado a lado.
	assert(pc.buttonSize * 2 <= pc.mapSize, "dois botões cabem na largura do mapa")
	assert(pc.buttonSize >= 44 and phone.buttonSize >= 44, "mínimo de toque")
	assert(pc.buttonTop == pc.top + pc.mapSize + pc.gap, "botões logo embaixo do mapa")
end

function spec.no_celular_o_mapa_da_para_ler_e_a_seta_e_pequena()
	-- Teste do Elizeu de 18/11/2026: mapa de 73 px e seta de 18 px (um quarto dele).
	for _, size in { { 749, 330 }, { 667, 375 }, { 599, 264 } } do
		local phone = MinimapRules.layout(size[1], size[2], true)
		assert(phone.mapSize >= 96, `{size[1]}x{size[2]}: mapa pequeno ({phone.mapSize})`)
		assert(phone.markerSize <= phone.mapSize * 0.14, `{size[1]}x{size[2]}: seta grande demais`)
		assert(phone.markerSize >= 10, `{size[1]}x{size[2]}: seta some`)
		-- Os botões (duas fileiras) ainda cabem acima da metade de baixo da tela.
		local secondRowBottom = phone.buttonTop + 2 * phone.buttonSize + phone.gap
		assert(secondRowBottom <= size[2] * 0.8, `{size[1]}x{size[2]}: botões descem demais ({secondRowBottom})`)
	end
	local pc = MinimapRules.layout(1280, 720, false)
	assert(pc.markerSize == 18, "PC igual")
end

return spec
