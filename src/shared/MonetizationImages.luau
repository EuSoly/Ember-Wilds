--!strict
-- Ids das artes da monetização (VIP, revive, check-in, boost, receita fixada),
-- num lugar só. Fontes em assets/ui/monetizacao/jogo/ e camadas/ (numeração da
-- lista em docs/game-design/assets-ui-monetizacao.md); a lista arquivo → id
-- está em assets/ui/monetizacao/ids-enviados.md (enviadas na conta do Elizeu,
-- 17/11/2026). Id vazio ("") = sem a arte, a tela usa o desenho feito por
-- código. Os Rect são o SliceCenter das peças 9-slice (assets/ui/monetizacao/
-- LEIA-ME.txt; as camadas, medidas nos PNGs: moldura de ~44 px com os rebites
-- nos cantos, então o miolo começa em 64).
local MonetizationImages = {}

-- 1. Ícone do VIP ao lado do nome.
MonetizationImages.VIP_NICK = "rbxassetid://81974885070066"

-- 2. Cartão do VIP (1024x512): normal / ativo, e o brilho de canto por cima.
-- Com as camadas 40 (VIP_LAYERS) enviadas, o cartão usa as camadas.
MonetizationImages.VIP_CARD = {
	normal = "rbxassetid://101676598300493",
	active = "rbxassetid://77537388165789",
} :: { [string]: string }
MonetizationImages.VIP_CARD_SLICE = Rect.new(78, 78, 946, 434)
MonetizationImages.VIP_CORNER_GLOW = "rbxassetid://97690868177280"

-- 3 e 4. Ícones das gamepasses.
MonetizationImages.EMBER_2X = "rbxassetid://126241165939190"
MonetizationImages.BOOK = "rbxassetid://122966360366049"

-- 5. Ícone do revive.
MonetizationImages.REVIVE = "rbxassetid://128005438282367"

-- 6. Painel da oferta de revive (800x500).
MonetizationImages.REVIVE_PANEL = "rbxassetid://72679453405258"
MonetizationImages.REVIVE_PANEL_SIZE = Vector2.new(800, 500)
MonetizationImages.REVIVE_PANEL_SLICE = Rect.new(62, 62, 738, 438)

-- 7 e 8. Botões (512x154): reviver (normal / apertado / desligado) e "não obrigado".
MonetizationImages.REVIVE_BUTTON = {
	normal = "rbxassetid://135655765728943",
	pressed = "rbxassetid://103108075662213",
	disabled = "rbxassetid://95434092653069",
} :: { [string]: string }
MonetizationImages.DECLINE_BUTTON = {
	normal = "rbxassetid://114768068438324",
	pressed = "rbxassetid://117675903626350",
} :: { [string]: string }
MonetizationImages.BUTTON_SIZE = Vector2.new(512, 154)
MonetizationImages.BUTTON_SLICE = Rect.new(55, 49, 457, 107)

-- 9. Fita "grátis para VIP" (300x100), sem texto.
MonetizationImages.VIP_RIBBON = "rbxassetid://94918785466325"
MonetizationImages.VIP_RIBBON_SIZE = Vector2.new(300, 100)
MonetizationImages.VIP_RIBBON_SLICE = Rect.new(64, 35, 236, 65)

-- 10. Cadeado da caixa.
MonetizationImages.LOCK_BOX = "rbxassetid://109163447795655"

-- 11. Janela do check-in (1000x700), papel creme.
MonetizationImages.CHECKIN_WINDOW = "rbxassetid://114195747576252"
MonetizationImages.CHECKIN_WINDOW_SIZE = Vector2.new(1000, 700)
MonetizationImages.CHECKIN_WINDOW_SLICE = Rect.new(60, 60, 940, 640)

-- 12. Dia do check-in (240x300): bloqueado / futuro / hoje / resgatado.
MonetizationImages.CHECKIN_DAY = {
	locked = "rbxassetid://115236139357242",
	future = "rbxassetid://120493219640107",
	today = "rbxassetid://133574914397795",
	claimed = "rbxassetid://87749701991109",
} :: { [string]: string }
MonetizationImages.CHECKIN_DAY_SIZE = Vector2.new(240, 300)
MonetizationImages.CHECKIN_DAY_SLICE = Rect.new(50, 50, 190, 250)

-- 13. Dia 7 (360x450), mesmos estados.
MonetizationImages.CHECKIN_DAY7 = {
	locked = "rbxassetid://87953409454069",
	future = "rbxassetid://123817595006458",
	today = "rbxassetid://132514288081972",
	claimed = "rbxassetid://85828774994312",
} :: { [string]: string }
MonetizationImages.CHECKIN_DAY7_SIZE = Vector2.new(360, 450)
MonetizationImages.CHECKIN_DAY7_SLICE = Rect.new(56, 56, 304, 394)

-- 14. Carimbo "resgatado" (vai por cima do cartão resgatado).
MonetizationImages.CLAIMED_STAMP = "rbxassetid://113859862924434"

-- 15. Calendário do check-in.
MonetizationImages.CHECKIN_CALENDAR = "rbxassetid://116858363197191"

-- 16. Bolinha de aviso (128x128), opcional.
MonetizationImages.NOTICE_DOT = "rbxassetid://100592441558127"

-- 17. Ícone do boost de XP.
-- Ícone do botão de códigos de resgate (arte do Elizeu; vazio = o de presente).
MonetizationImages.CODES_ICON = ""
MonetizationImages.XP_BOOST = "rbxassetid://83488962407228"

-- 18. Cartão de benefícios do Premium (1024x400). Com as camadas 44
-- (PREMIUM_LAYERS) enviadas, o cartão usa as camadas.
MonetizationImages.PREMIUM_CARD = "rbxassetid://85213705547309"
MonetizationImages.PREMIUM_CARD_SLICE = Rect.new(62, 62, 962, 338)

-- 19. Etiqueta do multiplicador (200x64).
MonetizationImages.MULTIPLIER_TAG = "rbxassetid://73900236775992"
MonetizationImages.MULTIPLIER_TAG_SLICE = Rect.new(29, 24, 171, 41)

-- 20. Bloqueio dos giros (onde não se compra item aleatório pago).
MonetizationImages.SPINS_BLOCK = "rbxassetid://70593058035424"

-- 29. Pergaminho da receita fixada (400x600): só a altura cresce.
MonetizationImages.RECIPE_SCROLL = "rbxassetid://112552415684669"
MonetizationImages.RECIPE_SCROLL_SLICE = Rect.new(48, 112, 352, 506)

-- Camadas para animar (seção 5 da lista). Os efeitos vêm BRANCOS e são
-- tingidos por ImageColor3 (UI/CardFx).
-- 37. Raios de luz (1024x1024, nascem no centro; somem a partir do raio 449).
MonetizationImages.RAYS = "rbxassetid://110360145283224"
-- 38. Halo (1024x1024, círculo suave; some a partir do raio 455).
MonetizationImages.HALO = "rbxassetid://82748900538683"
-- 39. Faíscas (128x128): brasinha, cruz fina, estrela de 4 pontas e ponto.
MonetizationImages.SPARKS = {
	ember = "rbxassetid://71666151543880",
	cross = "rbxassetid://80624740246035",
	star4 = "rbxassetid://124436878902510",
	dot = "rbxassetid://93212246833211",
} :: { [string]: string }

-- Cartões em camadas: base (fundo liso) por baixo dos efeitos e moldura (centro
-- transparente) por cima deles; o conteúdo vai por cima de tudo.
-- 40. VIP (1024x512): base dourado-brasa e moldura ouro/nogueira.
MonetizationImages.VIP_LAYERS = {
	base = "rbxassetid://120971758962226",
	frame = "rbxassetid://81970612501176",
} :: { [string]: string }
MonetizationImages.VIP_LAYERS_SIZE = Vector2.new(1024, 512)
MonetizationImages.VIP_LAYERS_SLICE = Rect.new(64, 64, 960, 448)
-- 40 (extra). Coroa do VIP, ornamento separado da moldura (320x320).
MonetizationImages.VIP_CROWN_OVERLAY = "rbxassetid://88595090142974"

-- 41. Cartão genérico da loja (1024x512): base cinza neutra (tingida com a cor
-- do cartão) e moldura nogueira. Serve aos 5 fundos de ShopImages.CARD.
MonetizationImages.SHOP_CARD_LAYERS = {
	base = "rbxassetid://135480079726252",
	frame = "rbxassetid://89208251796981",
} :: { [string]: string }
MonetizationImages.SHOP_CARD_LAYERS_SIZE = Vector2.new(1024, 512)
MonetizationImages.SHOP_CARD_LAYERS_SLICE = Rect.new(64, 64, 960, 448)

-- 43. Dia 7 do check-in (360x450): base papel dourado e moldura ouro.
MonetizationImages.DAY7_LAYERS = {
	base = "rbxassetid://80773364166601",
	frame = "rbxassetid://108147051296159",
} :: { [string]: string }
MonetizationImages.DAY7_LAYERS_SIZE = Vector2.new(360, 450)
MonetizationImages.DAY7_LAYERS_SLICE = Rect.new(64, 64, 296, 386)

-- 44. Premium (1024x400): base papel e moldura nogueira.
MonetizationImages.PREMIUM_LAYERS = {
	base = "rbxassetid://128095136977070",
	frame = "rbxassetid://132874747014694",
} :: { [string]: string }
MonetizationImages.PREMIUM_LAYERS_SIZE = Vector2.new(1024, 400)
MonetizationImages.PREMIUM_LAYERS_SLICE = Rect.new(64, 64, 960, 336)

-- 30–36. Ícones dos kits (512x512, transparentes, sem brilho), por id do kit
-- (Defs/Kits). Substituem os ícones antigos da loja (morango, picareta, mochila,
-- medalha). Usados no cartão do kit na loja e na linha do painel de kits.
MonetizationImages.KIT = {
	kit_starter = "rbxassetid://80600118054893",
	kit_explorer = "rbxassetid://102277036344773",
	kit_survivor = "rbxassetid://71963070860118",
	kit_veteran = "rbxassetid://127447740117120",
	kit_vip = "rbxassetid://88509306404011",
	kit_hunter = "rbxassetid://81698575484406",
	kit_guardian = "rbxassetid://88131510037634",
} :: { [string]: string }

-- Brilho do tier atrás do ícone do kit (raios 37 + halo 38 tingidos).
MonetizationImages.KIT_GLOW = {
	kit_starter = Color3.fromHex("#D9B27C"), -- madeira clara
	kit_explorer = Color3.fromHex("#A9B0B8"), -- cinza-pedra
	kit_survivor = Color3.fromHex("#F08A3C"), -- laranja-brasa
	kit_veteran = Color3.fromHex("#F5C542"), -- dourado
	kit_vip = Color3.fromHex("#FFC66B"), -- dourado-brasa do VIP
	kit_hunter = Color3.fromHex("#B5523B"), -- vermelho-terra
	kit_guardian = Color3.fromHex("#4C7BD9"), -- azul-real
} :: { [string]: Color3 }

function MonetizationImages.has(id: string?): boolean
	return id ~= nil and id ~= ""
end

-- Conjunto de camadas completo (base e moldura enviadas)?
function MonetizationImages.hasLayers(layers: { [string]: string }): boolean
	return MonetizationImages.has(layers.base) and MonetizationImages.has(layers.frame)
end

return table.freeze(MonetizationImages)
