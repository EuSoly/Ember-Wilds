--!strict
-- Artes do Ranking semanal (UI 6), num lugar só. Fontes recortadas em
-- assets/ui/ranking/ por prepare_ranking.py (arte do Elizeu gerada por IA);
-- enviadas na conta do Elizeu, com a confirmação dele. Id vazio ("") = sem a
-- arte: a tela usa o desenho de reserva por código (cores do Theme.rustic).
local RankingImages = {}

RankingImages.FRAME = "rbxassetid://76981891908154" -- frame.png (1018x1024): quadro de papel com moldura
RankingImages.FRAME_SIZE = Vector2.new(1018, 1024)
RankingImages.FRAME_SLICE = Rect.new(110, 110, 908, 914) -- moldura e cantos não esticam

RankingImages.TROPHY = "rbxassetid://72111598376414" -- trophy.png (512x507)
RankingImages.MEDAL =
	{ "rbxassetid://123337874044086", "rbxassetid://133302077275892", "rbxassetid://87387653699152" } :: { string } -- medal_1..3.png (~176x256)
RankingImages.MEDAL_RATIO = 176 / 256 -- largura / altura das medalhas

RankingImages.ROW_LIGHT = "rbxassetid://75425364436396" -- row_light.png (1024x179)
RankingImages.ROW_DARK = "rbxassetid://125604613040831" -- row_dark.png (1024x179)
RankingImages.ROW_SIZE = Vector2.new(1024, 179)
RankingImages.ROW_SLICE = Rect.new(60, 40, 964, 139) -- pontas rasgadas não esticam

RankingImages.ROW_ME = "rbxassetid://118857773097089" -- row_me.png (1024x228): faixa vermelha com moldura
RankingImages.ROW_ME_SIZE = Vector2.new(1024, 228)
RankingImages.ROW_ME_SLICE = Rect.new(110, 70, 914, 158) -- tampas com corda não esticam

RankingImages.PODIUM = "rbxassetid://120116045773813" -- podium.png (1024x576)
RankingImages.PODIUM_RATIO = 1024 / 576
-- Por posição, em frações da imagem do pódio (medidas pelo prepare_ranking.py):
-- x = centro do degrau, top = topo do tampo, plaqueY = centro da plaquinha.
RankingImages.PODIUM_SPOTS = {
	{ x = 0.5, top = 0.002, plaqueY = 0.483 },
	{ x = 0.22, top = 0.274, plaqueY = 0.616 },
	{ x = 0.78, top = 0.366, plaqueY = 0.681 },
} :: { { x: number, top: number, plaqueY: number } }

RankingImages.AVATAR_RING = "rbxassetid://136474449449220" -- avatar_ring.png (246x256)
RankingImages.ARROW = "rbxassetid://95744974200043" -- arrow.png (256x83): ponta para a esquerda
RankingImages.ARROW_RATIO = 256 / 83

-- Ícones das abas, por categoria (RankConfig.CATEGORIES).
RankingImages.TAB = {
	points = "rbxassetid://72043535104815", -- tab_points.png: chama com estrela
	xp = "rbxassetid://92819120449055", -- tab_xp.png: escudo com estrela
	days = "rbxassetid://76150671701078", -- tab_days.png: sol e lua
	players = "rbxassetid://113423732914694", -- tab_players.png: espadas cruzadas
	creatures = "rbxassetid://123965945106227", -- tab_creatures.png: pata
} :: { [string]: string }

function RankingImages.has(id: string?): boolean
	return id ~= nil and id ~= ""
end

return RankingImages
