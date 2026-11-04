--!strict
-- Ids das artes da Loja (UI 2), num lugar só. Fontes em assets/ui/shop/
-- (recortadas da pasta de artes do Elizeu; o botão verde é o laranja com a
-- cor trocada). Enviadas na conta do Elizeu. Id vazio ("") = sem a arte: a
-- loja volta ao desenho feito por código.
local ShopImages = {}

-- Roleta em 3 camadas no mesmo quadro (320x320): o disco gira, moldura e
-- ponteiro ficam parados por cima.
ShopImages.WHEEL_DISC = "rbxassetid://76372227015002"
ShopImages.WHEEL_FRAME = "rbxassetid://75556963387452"
ShopImages.WHEEL_POINTER = "rbxassetid://126933206606519"

-- Fundos dos cartões (com raios de luz), por cor.
ShopImages.CARD = {
	red = "rbxassetid://85231216406276",
	purple = "rbxassetid://99414578695936",
	green = "rbxassetid://91584277286673",
	blue = "rbxassetid://132578163648411",
	orange = "rbxassetid://137660553407622",
} :: { [string]: string }
ShopImages.CARD_SIZE = Vector2.new(256, 400)
ShopImages.CARD_SLICE = Rect.new(40, 40, 216, 360) -- cantos e borda não esticam

ShopImages.ROBUX = "rbxassetid://136687427128806" -- símbolo do Robux, branco (tinge com ImageColor3)
ShopImages.BUTTON_GREEN = "rbxassetid://92965878315450" -- mesmo formato do botão laranja (UiImages.BUTTON_EMBER)
ShopImages.RIBBON = "rbxassetid://78213738653219"
ShopImages.RIBBON_SIZE = Vector2.new(240, 94)
ShopImages.RIBBON_SLICE = Rect.new(44, 20, 196, 74)
ShopImages.COIN_STACK_2 = "rbxassetid://80796565256376"
ShopImages.COIN_STACK_3 = "rbxassetid://107961956032893"

-- Ícones das abas.
ShopImages.TAB = {
	packs = "rbxassetid://98902908545845", -- presente
	passes = "rbxassetid://113403146757257", -- coroa
	spins = "rbxassetid://119630282286077", -- roleta
} :: { [string]: string }

-- Ícones das gamepasses (por id de MockStore.PASSES).
ShopImages.PASS = {
	kit_starter = "rbxassetid://112277672433244", -- morango
	kit_explorer = "rbxassetid://115992262876096", -- picareta
	kit_survivor = "rbxassetid://89195781946000", -- mochila
	kit_veteran = "rbxassetid://90193660058023", -- medalha
	vip = "rbxassetid://109684898286867", -- estrela
} :: { [string]: string }

function ShopImages.has(id: string?): boolean
	return id ~= nil and id ~= ""
end

return table.freeze(ShopImages)
