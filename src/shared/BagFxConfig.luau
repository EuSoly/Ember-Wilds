--!strict
-- Efeitos das mochilas dos pacotes do lançamento: partículas que saem da
-- mochila enquanto o jogador anda (a quantidade acompanha a velocidade;
-- parado, nada). Puro: o client/Boneco/BagFx monta os ParticleEmitter.
--   bag_cubo_gelo (Gelo): flocos de neve, geada no chão e faíscas frias;
--   bag_caranguejo (Abissal): bolhas subindo e respingos de água;
--   bag_cubos_esmeralda (Floresta): vaga-lumes, faíscas, folhinhas e névoa
--   verde, tudo meio místico.
-- Texturas brancas (o emitter tinge): assets/skins/vfx/gerar_texturas.py,
-- enviadas na conta do Elizeu.
local BagFxConfig = {}

BagFxConfig.TEXTURES = table.freeze({
	bolha = "rbxassetid://78981018584713",
	floco = "rbxassetid://114944944083043",
	brilho = "rbxassetid://74358121247057",
	estrela = "rbxassetid://95253426313845",
	folha = "rbxassetid://126681208517270",
})

-- Um emissor. Faixas {mín, máx}; sequências {início, fim} ou {início, meio, fim}.
-- offset: studs a partir do meio da mochila (X direita, Y cima, Z para trás);
-- o chão fica em y = GROUND_Y. flat = deitada no chão (geada, névoa).
export type Emitter = {
	texture: string,
	colors: { string },
	size: { number },
	transparency: { number },
	lifetime: { number },
	speed: { number },
	rate: number, -- partículas por segundo andando a toda
	spread: number, -- graus
	acceleration: { number },
	rotSpeed: { number }?,
	lightEmission: number?,
	drag: number?,
	offset: { number }?,
	flat: boolean?,
}

-- Chão em relação ao meio da mochila (a raiz fica 1 stud acima do chão e o
-- meio da mochila 0,3 acima da raiz).
BagFxConfig.GROUND_Y = -1.25

local GROUND = BagFxConfig.GROUND_Y

local BY_BAG: { [string]: { Emitter } } = {
	bag_cubo_gelo = {
		{ -- flocos girando e caindo devagar
			texture = BagFxConfig.TEXTURES.floco,
			colors = { "#FFFFFF", "#BFEFFF" },
			size = { 0.8, 0.5 },
			transparency = { 0.05, 0.2, 1 },
			lifetime = { 1.2, 1.8 },
			speed = { 1, 2 },
			rate = 14,
			spread = 60,
			acceleration = { 0, -2, 0 },
			rotSpeed = { -90, 90 },
			drag = 1,
			offset = { 0, 0.6, 0 },
		},
		{ -- geada no chão, ficando para trás
			texture = BagFxConfig.TEXTURES.brilho,
			colors = { "#DDF8FF", "#98D8EC" },
			size = { 2.6, 3.6 },
			transparency = { 0.45, 1 },
			lifetime = { 1.1, 1.4 },
			speed = { 0.01, 0.01 },
			rate = 9,
			spread = 0,
			acceleration = { 0, 0, 0 },
			offset = { 0, GROUND, 0 },
			flat = true,
		},
		{ -- faíscas frias
			texture = BagFxConfig.TEXTURES.estrela,
			colors = { "#FFFFFF", "#8FE3FF" },
			size = { 1, 0 },
			transparency = { 0, 1 },
			lifetime = { 0.5, 0.8 },
			speed = { 0.5, 1.5 },
			rate = 6,
			spread = 120,
			acceleration = { 0, 0.5, 0 },
			rotSpeed = { -45, 45 },
			lightEmission = 0.8,
		},
	},
	bag_caranguejo = {
		{ -- bolhas subindo
			texture = BagFxConfig.TEXTURES.bolha,
			colors = { "#D8F8FF", "#7FD8FF" },
			size = { 0.5, 0.9 },
			transparency = { 0.1, 0.2, 1 },
			lifetime = { 1.2, 2 },
			speed = { 1.5, 2.5 },
			rate = 12,
			spread = 25,
			acceleration = { 0, 1.5, 0 },
			drag = 1,
			offset = { 0, 0.8, 0 },
		},
		{ -- respingos de água caindo
			texture = BagFxConfig.TEXTURES.brilho,
			colors = { "#9FE6FF", "#3FA9D9" },
			size = { 0.4, 0.15 },
			transparency = { 0, 1 },
			lifetime = { 0.45, 0.65 },
			speed = { 3, 4 },
			rate = 10,
			spread = 50,
			acceleration = { 0, -14, 0 },
			lightEmission = 0.3,
			offset = { 0, 0.5, 0.2 },
		},
	},
	bag_cubos_esmeralda = {
		{ -- vaga-lumes verdes flutuando
			texture = BagFxConfig.TEXTURES.brilho,
			colors = { "#B9FFC9", "#2EE07A" },
			size = { 0, 0.8, 0 },
			transparency = { 0, 0.1, 1 },
			lifetime = { 1.6, 2.4 },
			speed = { 0.5, 1.2 },
			rate = 10,
			spread = 180,
			acceleration = { 0, 0.6, 0 },
			lightEmission = 1,
			drag = 0.5,
		},
		{ -- faíscas místicas
			texture = BagFxConfig.TEXTURES.estrela,
			colors = { "#E2FFE8", "#5CF29A" },
			size = { 1.1, 0 },
			transparency = { 0, 1 },
			lifetime = { 0.6, 0.9 },
			speed = { 0.3, 1 },
			rate = 6,
			spread = 180,
			acceleration = { 0, 0.4, 0 },
			rotSpeed = { -60, 60 },
			lightEmission = 1,
		},
		{ -- folhinhas caindo
			texture = BagFxConfig.TEXTURES.folha,
			colors = { "#3DBE6E", "#1C7C44" },
			size = { 0.6, 0.5 },
			transparency = { 0, 0.1, 1 },
			lifetime = { 1.5, 2 },
			speed = { 1, 2 },
			rate = 5,
			spread = 70,
			acceleration = { 0, -1.5, 0 },
			rotSpeed = { -120, 120 },
			drag = 1,
			offset = { 0, 0.6, 0 },
		},
		{ -- névoa verde no chão
			texture = BagFxConfig.TEXTURES.brilho,
			colors = { "#3DDC84", "#0C643C" },
			size = { 3, 4.5 },
			transparency = { 0.75, 1 },
			lifetime = { 1.4, 1.8 },
			speed = { 0.01, 0.01 },
			rate = 5,
			spread = 0,
			acceleration = { 0, 0, 0 },
			lightEmission = 0.6,
			offset = { 0, GROUND, 0 },
			flat = true,
		},
	},
}

-- Abaixo disso (fração de velocidade) a mochila não solta nada.
BagFxConfig.MIN_WALK = 0.15

-- Emissores da mochila `bagId`; nil = mochila sem efeito.
function BagFxConfig.of(bagId: string?): { Emitter }?
	return if bagId then BY_BAG[bagId] else nil
end

function BagFxConfig.bags(): { string }
	local list = {}
	for id in BY_BAG do
		table.insert(list, id)
	end
	table.sort(list)
	return list
end

-- Partículas por segundo do emissor com a fração de velocidade `walk` (0 a 1).
function BagFxConfig.rate(emitter: Emitter, walk: number): number
	if walk < BagFxConfig.MIN_WALK then
		return 0
	end
	return emitter.rate * math.clamp(walk, 0, 1)
end

return BagFxConfig
