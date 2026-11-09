--!strict
-- Artes do HUD do jogo (arte do Elizeu, 09/11), num lugar só. Fontes em
-- assets/ui/hud/ (recorte por prepare_hud.py), enviadas na conta do Elizeu com
-- a confirmação dele. Id vazio ("") = sem a arte: cada peça volta ao desenho
-- por código de antes (o HUD continua funcionando).
-- Puro (sem Rect/Vector2): o cliente monta os 9 partes a partir de SLICED.
local HudImages = {}

-- Anéis de status: medalhão octogonal (furo no meio) e o ícone de cada barra.
HudImages.STATUS_FRAME = "" -- status_frame.png (251x256)
HudImages.STATUS_HOLE = 0.66 -- diâmetro do furo do medalhão, fração da largura
HudImages.STATUS_ICON = {
	health = "", -- status_health.png: coração
	hunger = "", -- status_hunger.png: coxa
	cold = "", -- status_cold.png: floco de neve
	thirst = "", -- status_thirst.png: gota
	heat = "", -- status_heat.png: sol com ondas
	oxygen = "", -- status_oxygen.png: bolha
} :: { [string]: string }

-- Slots (hotbar, mochila, receitas): couro com borda de madeira.
HudImages.SLOT = "" -- slot.png (126x128)
HudImages.SLOT_SELECTED = "" -- slot_selected.png (128x128): borda dourada e marquinha
HudImages.LOCK = "" -- lock.png (54x64)
HudImages.SLOT_INSET = 0.13 -- borda do slot, fração do lado (o item fica dentro)

-- Minimapa e botões redondos.
HudImages.MINIMAP_FRAME = "" -- minimap_frame.png (499x512)
HudImages.MINIMAP_INSET = 0.11 -- borda da moldura, fração do lado
HudImages.BUTTON_ROUND = "" -- button_round.png (181x192)
HudImages.ICON = {
	settings = "", -- icon_settings.png: engrenagem
	book = "", -- icon_book.png: livro com chama
	backpack = "", -- icon_backpack.png: mochila
	rotate = "", -- icon_rotate.png: setas de girar
} :: { [string]: string }

-- Painel de couro (baú, caixa, interação, mochila aberta), avisos e dica.
HudImages.PANEL = "" -- panel.png (512x504)
HudImages.TOAST = {
	info = "", -- toast_cream.png: aviso normal
	alert = "", -- toast_orange.png: alerta ("A noite está chegando")
	success = "", -- toast_green.png: deu certo ("Item criado")
} :: { [string]: string }
HudImages.TOOLTIP = "" -- tooltip_body.png (400x186): balão de papel
HudImages.TOOLTIP_TAIL = "" -- tooltip_tail.png (80x40): pontinha de baixo
HudImages.TOOLTIP_TAIL_SIZE = { 80, 40 }

-- Joystick do celular (andar e mirar).
HudImages.JOYSTICK_BASE = "" -- joystick_base.png (250x256)
HudImages.JOYSTICK_KNOB = "" -- joystick_knob.png (123x128)

-- Peças esticadas em 9 partes: tamanho da arte e o miolo que estica
-- ({ min.x, min.y, max.x, max.y }); os cantos (madeira, pregos, chanfros) não esticam.
HudImages.SLICED = {
	panel = { size = { 512, 504 }, slice = { 56, 56, 456, 448 } },
	toast = { size = { 756, 148 }, slice = { 72, 44, 684, 104 } },
	tooltip = { size = { 400, 186 }, slice = { 48, 40, 352, 146 } },
} :: { [string]: { size: { number }, slice: { number } } }

function HudImages.has(id: string?): boolean
	return id ~= nil and id ~= ""
end

return HudImages
