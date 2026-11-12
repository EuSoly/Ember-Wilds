--!strict
-- Artes da tela de Missões (arte do Elizeu gerada por IA, 12/11). Fontes em
-- assets/ui/missoes/ (prepare_missoes.py), enviadas na conta do Elizeu com a
-- confirmação dele (12/11). Id vazio ("") = sem a arte: a tela desenha a reserva por
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
	WINDOW = piece("rbxassetid://105491924715193", 1024, 578, { 260, 130, 770, 420 }), -- window.png
	TAB = piece("rbxassetid://137294507455034", 1020, 315, { 130, 90, 890, 230 }), -- tab.png
	TAB_ON = piece("rbxassetid://104245417563824", 1024, 318, { 130, 90, 894, 230 }), -- tab_on.png
	CARD_ACTIVE = piece("rbxassetid://74145940195431", 1024, 258, { 250, 60, 860, 200 }), -- card_active.png
	CARD_DONE = piece("rbxassetid://117736607067914", 1024, 240, { 250, 60, 800, 190 }), -- card_done.png (fita verde à direita)
	CARD_FAILED = piece("rbxassetid://70734483213092", 1024, 241, { 250, 60, 800, 190 }), -- card_failed.png (fita vermelha)
	-- Ponta direita (a fita com ✓/✗) dos cartões pronto/falhou, por cima e sem
	-- 9 partes: com 9 partes e escala fracionária o Roblox deformava a fita.
	CARD_DONE_CAP = piece("rbxassetid://132335963743431", 224, 240), -- card_done_cap.png
	CARD_FAILED_CAP = piece("rbxassetid://84260764682963", 224, 241), -- card_failed_cap.png
	BAR_TRACK = piece("rbxassetid://75502677632651", 1024, 112, { 60, 30, 964, 82 }), -- bar_track.png
	BAR_ORANGE = piece("rbxassetid://75774099068661", 711, 76, { 38, 20, 673, 56 }), -- bar_orange.png
	BAR_GREEN = piece("rbxassetid://135891204951719", 711, 76, { 38, 20, 673, 56 }), -- bar_green.png
	CLAIM = piece("rbxassetid://101343422582036", 795, 288, { 80, 70, 715, 218 }), -- claim.png
	CLAIM_DOWN = piece("rbxassetid://117476395885328", 792, 276, { 80, 66, 712, 210 }), -- claim_down.png
	PLATE = piece("rbxassetid://110460251956580", 924, 501), -- plate.png
	DOT = piece("rbxassetid://119531423000805", 512, 512), -- dot.png
	BANNER_DONE = piece("rbxassetid://113315698378731", 1024, 352), -- banner_done.png
	BANNER_FAILED = piece("rbxassetid://94658205808518", 1024, 355), -- banner_failed.png
	MEDAL_BRONZE = piece("rbxassetid://135369668363482", 512, 512), -- medal_bronze.png
	MEDAL_SILVER = piece("rbxassetid://99344151649823", 512, 512), -- medal_silver.png
	MEDAL_GOLD = piece("rbxassetid://78515835280687", 512, 512), -- medal_gold.png
	MEDAL_LOCKED = piece("rbxassetid://97088904383413", 512, 512), -- medal_locked.png
}) :: { [string]: Piece }

-- Ícones (512x512), pelo nome da arte; Defs usam estas chaves no campo icon.
MissionImages.ICON = table.freeze({
	missao_hud = "rbxassetid://124347086794522", -- icon_missao_hud.png (botão do HUD e do menu)
	aba_partida = "rbxassetid://87156077042827",
	aba_diarias = "rbxassetid://88900360833399",
	aba_semanais = "rbxassetid://83750644421751",
	aba_conquistas = "rbxassetid://137777725141459",
	chrono_sobreviver = "rbxassetid://117161109909548",
	chrono_maos_limpas = "rbxassetid://122099489915163",
	conquista_lenhador = "rbxassetid://85809160100349",
	conquista_minerador = "rbxassetid://90356577337928",
	conquista_cacador = "rbxassetid://121818679204588",
	conquista_sobrevivente = "rbxassetid://94168221452068",
	conquista_artesao = "rbxassetid://138373061426788",
	conquista_lenda = "rbxassetid://89411426203644",
	conquista_guerreiro = "rbxassetid://111654193262459",
	conquista_fiel = "rbxassetid://136454025766510",
	conquista_cronista = "rbxassetid://139272656021913", -- variação "alternativo" (pergaminho com ampulheta)
	premio_giro_especial = "rbxassetid://75639968279046",
	premio_uso_kit = "rbxassetid://140655264274133",
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
