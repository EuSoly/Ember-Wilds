--!strict
-- Artes dos presentes (peças 45–55, docs/game-design/assets-ui-presentes.md;
-- arquivos em assets/ui/presentes, ids dos .model.json de lá). Sem texto.
-- Id vazio = a tela desenha por código.
local GiftImages = {}

GiftImages.ICON = "rbxassetid://96738139747983" -- 45: caixinha com laço (botão de presente)
GiftImages.BOW = "rbxassetid://116391810918683" -- 46: laço para pôr no canto de um ícone

-- 47: janela "Presentear" (a mesma moldura do check-in).
GiftImages.WINDOW = "rbxassetid://114195747576252"
GiftImages.WINDOW_SIZE = Vector2.new(1000, 700)
GiftImages.WINDOW_SLICE = Rect.new(60, 60, 940, 640)

-- 48: linha de jogador da lista.
GiftImages.ROW = {
	normal = "rbxassetid://103763320529638",
	selected = "rbxassetid://88490061554704",
	off = "rbxassetid://83371964058561",
}
GiftImages.ROW_SIZE = Vector2.new(700, 110)
GiftImages.ROW_SLICE = Rect.new(26, 26, 674, 84)

GiftImages.AVATAR_FRAME = "rbxassetid://116900478087271" -- 49: moldura redonda da foto
GiftImages.CHECK = "rbxassetid://120551909763558" -- 50: marca da linha escolhida
GiftImages.BOX_CLOSED = "rbxassetid://91976544732836" -- 51
GiftImages.BOX_OPEN = "rbxassetid://127942085655500" -- 52 (mesmo enquadramento da 51)

-- 53: painel do presente recebido.
GiftImages.PANEL = "rbxassetid://88798671009225"
GiftImages.PANEL_SIZE = Vector2.new(800, 600)
GiftImages.PANEL_SLICE = Rect.new(52, 52, 748, 548)

GiftImages.RAYS = "rbxassetid://123743852967589" -- 54: raios/confete brancos (tingir)
GiftImages.EMPTY = "rbxassetid://83385295410199" -- 55: ninguém para presentear

function GiftImages.has(id: string?): boolean
	return id ~= nil and id ~= ""
end

return table.freeze(GiftImages)
