--!strict
-- Artes da tela de Missões (arte do Elizeu gerada por IA, 12/11). Fontes em
-- assets/ui/missoes/ (prepare_missoes.py), enviadas na conta do Elizeu com a
-- confirmação dele. Id vazio ("") = sem a arte: a tela desenha a reserva por
-- código (Rustic e cores do Theme.rustic).
-- Puro (sem Rect/Vector2, para os testes no Lune): size = { largura, altura }
-- da arte em px; slice = { min.x, min.y, max.x, max.y } das 9 partes (cantos
-- com folhas, pregos e o quadrado do ícone não esticam); sem slice = proporção fixa.
local MissionImages = {}

export type Piece = { image: string, size: { number }, slice: { number }? }

local function piece(image: string, w: number, h: number, slice: { number }?): Piece
	return table.freeze({ image = image, size = table.freeze({ w, h }), slice = slice and table.freeze(slice) }) :: any
end

MissionImages.PIECES = table.freeze({
	WINDOW = piece("", 1024, 578, { 260, 130, 770, 420 }), -- window.png
	TAB = piece("", 1020, 315, { 130, 90, 890, 230 }), -- tab.png
	TAB_ON = piece("", 1024, 318, { 130, 90, 894, 230 }), -- tab_on.png
	CARD_ACTIVE = piece("", 1024, 258, { 250, 60, 860, 200 }), -- card_active.png
	CARD_DONE = piece("", 1024, 240, { 250, 60, 800, 190 }), -- card_done.png (fita verde à direita)
	CARD_FAILED = piece("", 1024, 241, { 250, 60, 800, 190 }), -- card_failed.png (fita vermelha)
	BAR_TRACK = piece("", 1024, 112, { 60, 30, 964, 82 }), -- bar_track.png
	BAR_ORANGE = piece("", 711, 76, { 38, 20, 673, 56 }), -- bar_orange.png
	BAR_GREEN = piece("", 711, 76, { 38, 20, 673, 56 }), -- bar_green.png
	CLAIM = piece("", 795, 288, { 80, 70, 715, 218 }), -- claim.png
	CLAIM_DOWN = piece("", 792, 276, { 80, 66, 712, 210 }), -- claim_down.png
	PLATE = piece("", 924, 501), -- plate.png
	DOT = piece("", 512, 512), -- dot.png
	BANNER_DONE = piece("", 1024, 352), -- banner_done.png
	BANNER_FAILED = piece("", 1024, 355), -- banner_failed.png
	MEDAL_BRONZE = piece("", 512, 512), -- medal_bronze.png
	MEDAL_SILVER = piece("", 512, 512), -- medal_silver.png
	MEDAL_GOLD = piece("", 512, 512), -- medal_gold.png
	MEDAL_LOCKED = piece("", 512, 512), -- medal_locked.png
}) :: { [string]: Piece }

-- Ícones (512x512), pelo nome da arte; Defs usam estas chaves no campo icon.
MissionImages.ICON = table.freeze({
	missao_hud = "", -- icon_missao_hud.png (botão do HUD e do menu)
	aba_partida = "",
	aba_diarias = "",
	aba_semanais = "",
	aba_conquistas = "",
	chrono_sobreviver = "",
	chrono_maos_limpas = "",
	conquista_lenhador = "",
	conquista_minerador = "",
	conquista_cacador = "",
	conquista_sobrevivente = "",
	conquista_artesao = "",
	conquista_lenda = "",
	conquista_guerreiro = "",
	conquista_fiel = "",
	conquista_cronista = "", -- variação "alternativo" (pergaminho com ampulheta)
	premio_giro_especial = "",
	premio_uso_kit = "",
}) :: { [string]: string }

-- Medalha do nível (1 bronze, 2 prata, 3 ouro; 0 = trancada).
function MissionImages.medal(tier: number): Piece
	local P = MissionImages.PIECES
	return if tier >= 3
		then P.MEDAL_GOLD
		elseif tier == 2 then P.MEDAL_SILVER
		elseif tier == 1 then P.MEDAL_BRONZE
		else P.MEDAL_LOCKED
end

return table.freeze(MissionImages)
