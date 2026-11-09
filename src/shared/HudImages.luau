--!strict
-- Artes do HUD do jogo (arte do Elizeu, 09/11), num lugar só. Fontes em
-- assets/ui/hud/ (recorte por prepare_hud.py), enviadas na conta do Elizeu com
-- a confirmação dele. Id vazio ("") = sem a arte: cada peça volta ao desenho
-- por código de antes (o HUD continua funcionando).
-- Puro (sem Rect/Vector2): o cliente monta os 9 partes a partir de SLICED.
local HudImages = {}

-- Anéis de status: medalhão octogonal (furo no meio) e o ícone de cada barra.
HudImages.STATUS_FRAME = "rbxassetid://96840384898561" -- status_frame.png (251x256)
HudImages.STATUS_HOLE = 0.66 -- diâmetro do furo do medalhão, fração da largura
HudImages.STATUS_ICON = {
	health = "rbxassetid://101471319366323", -- status_health.png: coração
	hunger = "rbxassetid://101700219337160", -- status_hunger.png: coxa
	cold = "rbxassetid://101822307034280", -- status_cold.png: floco de neve
	thirst = "rbxassetid://125655482884120", -- status_thirst.png: gota
	heat = "rbxassetid://107291382617283", -- status_heat.png: sol com ondas
	oxygen = "rbxassetid://127287609063098", -- status_oxygen.png: bolha
} :: { [string]: string }

-- Slots (hotbar, mochila, receitas): couro com borda de madeira.
HudImages.SLOT = "rbxassetid://100921853880593" -- slot.png (126x128)
HudImages.SLOT_SELECTED = "rbxassetid://87113190427046" -- slot_selected.png (128x128): borda dourada e marquinha
HudImages.LOCK = "rbxassetid://88163751817232" -- lock.png (54x64)
HudImages.SLOT_INSET = 0.13 -- borda do slot, fração do lado (o item fica dentro)

-- Minimapa e botões redondos.
HudImages.MINIMAP_FRAME = "rbxassetid://88379313684631" -- minimap_frame.png (499x512)
HudImages.MINIMAP_INSET = 0.11 -- borda da moldura, fração do lado
HudImages.BUTTON_ROUND = "rbxassetid://111290622168382" -- button_round.png (181x192)
HudImages.ICON = {
	settings = "rbxassetid://122138656270963", -- icon_settings.png: engrenagem
	book = "rbxassetid://119455236689691", -- icon_book.png: livro com chama
	backpack = "rbxassetid://97302070461860", -- icon_backpack.png: mochila
	rotate = "rbxassetid://77337730452030", -- icon_rotate.png: setas de girar
	weapon_lock = "rbxassetid://129728310019742", -- icon_weapon_lock.png: espada, machado e picareta (relógio da arma presa)
} :: { [string]: string }

-- Painel de couro (baú, caixa, interação, mochila aberta), avisos e dica.
HudImages.PANEL = "rbxassetid://129459129031189" -- panel.png (512x504)
HudImages.TOAST = {
	info = "rbxassetid://76955393724766", -- toast_cream.png: aviso normal
	alert = "rbxassetid://95326375963549", -- toast_orange.png: alerta ("A noite está chegando")
	success = "rbxassetid://106336406497806", -- toast_green.png: deu certo ("Item criado")
} :: { [string]: string }
HudImages.TOOLTIP = "rbxassetid://101908708502443" -- tooltip_body.png (400x186): balão de papel
HudImages.TOOLTIP_TAIL = "rbxassetid://118047862657931" -- tooltip_tail.png (80x40): pontinha de baixo
HudImages.TOOLTIP_TAIL_SIZE = { 80, 40 }

-- Joystick do celular (andar e mirar).
HudImages.JOYSTICK_BASE = "rbxassetid://81977662615817" -- joystick_base.png (250x256)
HudImages.JOYSTICK_KNOB = "rbxassetid://109220113444721" -- joystick_knob.png (123x128)

-- Bordas da tela quando o jogador sofre (UI/StatusVignette): imagem branca
-- ou já colorida cobrindo a tela inteira, transparente no meio. Vazio = a
-- borda em degradê feita por código, na cor de cada efeito.
HudImages.FX = {
	damage = "rbxassetid://138774314848335", -- fx_damage.png: golpe, vermelho
	cold = "rbxassetid://129399250486551", -- fx_cold.png: cristais de gelo
	heat = "rbxassetid://128636899006562", -- fx_heat.png: brasas e lava
	hunger = "rbxassetid://82206372108794", -- fx_hunger.png: terra e coxinhas
	thirst = "rbxassetid://115630801477028", -- fx_thirst.png: gotas nos cantos
	oxygen = "rbxassetid://135574904661131", -- fx_oxygen.png: ondas e bolhas
} :: { [string]: string }

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
