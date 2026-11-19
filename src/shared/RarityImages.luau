--!strict
-- Fundos de raridade (arte do Elizeu, 09/11): um quadrado com brilho por
-- raridade, na ordem da tabela (1 Comum cinza, 2 Incomum verde, 3 Raro azul,
-- 4 Épico roxo, 5 Lendário amarelo, 6 Mítico vermelho). Fontes em assets/ui/rarity/
-- (recorte por prepare_rarity.py), enviadas na conta do Elizeu com a
-- confirmação dele. Id vazio ("") = sem a arte: os quadradinhos voltam à cor
-- lisa da raridade (MockStore.RARITIES).
-- Puro (sem Rect/Vector2): o cliente monta o 9 partes com SLICE.
local RarityImages = {}

RarityImages.BACKGROUND = {
	"rbxassetid://94940242033685", -- rarity_1.png: Comum
	"", -- Incomum: usa a cor lisa (#2ECC71) até a arte verde entrar
	"rbxassetid://96613162113425", -- rarity_2.png: Raro
	"rbxassetid://140676752204319", -- rarity_3.png: Épico
	"rbxassetid://87614583588173", -- rarity_4.png: Lendário
	"rbxassetid://87537973912466", -- rarity_5.png: Mítico
} :: { string }
RarityImages.SIZE = 256 -- lado da arte (px)
-- 9 partes: os cantos (com o contorno e o brilho) não esticam.
RarityImages.CORNER = 48
RarityImages.SLICE = { 48, 48, 208, 208 } -- min.x, min.y, max.x, max.y
-- O canto ocupa esta fração do lado do quadradinho, em qualquer tamanho.
RarityImages.CORNER_SHARE = 0.16

-- Fundo da raridade `rarity` (fora de 1..6 vai para a ponta mais próxima).
function RarityImages.background(rarity: number): string
	local list = RarityImages.BACKGROUND
	return list[math.clamp(math.floor(rarity), 1, #list)]
end

-- SliceScale para um quadradinho de `side` px (o menor lado).
function RarityImages.sliceScale(side: number): number
	return math.max(side, 0) * RarityImages.CORNER_SHARE / RarityImages.CORNER
end

function RarityImages.has(id: string?): boolean
	return id ~= nil and id ~= ""
end

return RarityImages
