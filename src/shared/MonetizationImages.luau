--!strict
-- Ids das artes da monetização (VIP, revive, check-in, boost, receita fixada),
-- num lugar só. Fontes em assets/ui/monetizacao/jogo/ (numeração da lista em
-- docs/game-design/assets-ui-monetizacao.md). Ainda não enviadas ao Roblox:
-- id vazio ("") = sem a arte, a tela usa o desenho feito por código. Os Rect
-- são o SliceCenter sugerido em assets/ui/monetizacao/LEIA-ME.txt (peças 9-slice).
local MonetizationImages = {}

-- 1. Ícone do VIP ao lado do nome.
MonetizationImages.VIP_NICK = ""

-- 2. Cartão do VIP (1024x512): normal / ativo, e o brilho de canto por cima.
MonetizationImages.VIP_CARD = { normal = "", active = "" } :: { [string]: string }
MonetizationImages.VIP_CARD_SLICE = Rect.new(78, 78, 946, 434)
MonetizationImages.VIP_CORNER_GLOW = ""

-- 3 e 4. Ícones das gamepasses.
MonetizationImages.EMBER_2X = ""
MonetizationImages.BOOK = ""

-- 5. Ícone do revive.
MonetizationImages.REVIVE = ""

-- 6. Painel da oferta de revive (800x500).
MonetizationImages.REVIVE_PANEL = ""
MonetizationImages.REVIVE_PANEL_SLICE = Rect.new(62, 62, 738, 438)

-- 7 e 8. Botões (512x154): reviver (normal / apertado / desligado) e "não obrigado".
MonetizationImages.REVIVE_BUTTON = { normal = "", pressed = "", disabled = "" } :: { [string]: string }
MonetizationImages.DECLINE_BUTTON = { normal = "", pressed = "" } :: { [string]: string }
MonetizationImages.BUTTON_SLICE = Rect.new(55, 49, 457, 107)

-- 9. Fita "grátis para VIP" (300x100), sem texto.
MonetizationImages.VIP_RIBBON = ""
MonetizationImages.VIP_RIBBON_SLICE = Rect.new(64, 35, 236, 65)

-- 10. Cadeado da caixa.
MonetizationImages.LOCK_BOX = ""

-- 11. Janela do check-in (1000x700).
MonetizationImages.CHECKIN_WINDOW = ""
MonetizationImages.CHECKIN_WINDOW_SLICE = Rect.new(60, 60, 940, 640)

-- 12. Dia do check-in (240x300): bloqueado / futuro / hoje / resgatado.
MonetizationImages.CHECKIN_DAY = { locked = "", future = "", today = "", claimed = "" } :: { [string]: string }
MonetizationImages.CHECKIN_DAY_SLICE = Rect.new(50, 50, 190, 250)

-- 13. Dia 7 (360x450), mesmos estados.
MonetizationImages.CHECKIN_DAY7 = { locked = "", future = "", today = "", claimed = "" } :: { [string]: string }
MonetizationImages.CHECKIN_DAY7_SLICE = Rect.new(56, 56, 304, 394)

-- 14. Carimbo "resgatado" (vai por cima do cartão resgatado).
MonetizationImages.CLAIMED_STAMP = ""

-- 15. Calendário do check-in.
MonetizationImages.CHECKIN_CALENDAR = ""

-- 16. Bolinha de aviso (128x128), opcional.
MonetizationImages.NOTICE_DOT = ""

-- 17. Ícone do boost de XP.
MonetizationImages.XP_BOOST = ""

-- 18. Cartão de benefícios do Premium (1024x400).
MonetizationImages.PREMIUM_CARD = ""
MonetizationImages.PREMIUM_CARD_SLICE = Rect.new(62, 62, 962, 338)

-- 19. Etiqueta do multiplicador (200x64).
MonetizationImages.MULTIPLIER_TAG = ""
MonetizationImages.MULTIPLIER_TAG_SLICE = Rect.new(29, 24, 171, 41)

-- 20. Bloqueio dos giros (onde não se compra item aleatório pago).
MonetizationImages.SPINS_BLOCK = ""

-- 29. Pergaminho da receita fixada (400x600): só a altura cresce.
MonetizationImages.RECIPE_SCROLL = ""
MonetizationImages.RECIPE_SCROLL_SLICE = Rect.new(48, 112, 352, 506)

function MonetizationImages.has(id: string?): boolean
	return id ~= nil and id ~= ""
end

return table.freeze(MonetizationImages)
