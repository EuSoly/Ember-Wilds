--!strict
local CosmeticsLayout = require("../src/shared/UIFlow/CosmeticsLayout")

-- PC, notebook e celulares deitados (já em pixels lógicos: a escala 2 da
-- interface divide a tela por 2).
local SIZES = { { 1920, 1080 }, { 1280, 720 }, { 1130, 793 }, { 800, 400 }, { 844, 390 }, { 667, 375 }, { 640, 360 } }

local SIDES = { "left", "left", "left", "right", "right" }
local CARDS = #SIDES

local function inside(r: CosmeticsLayout.Rect, w: number, h: number): boolean
	return r.x >= 0 and r.y >= 0 and r.w > 0 and r.h > 0 and r.x + r.w <= w + 0.01 and r.y + r.h <= h + 0.01
end

local function overlaps(a: CosmeticsLayout.Rect, b: CosmeticsLayout.Rect): boolean
	return a.x < b.x + b.w and b.x < a.x + a.w and a.y < b.y + b.h and b.y < a.y + a.h
end

return {
	["window fits the screen"] = function()
		for _, size in SIZES do
			local l = CosmeticsLayout.compute(size[1], size[2], SIDES)
			assert(
				l.windowWidth <= size[1] and l.windowHeight <= size[2],
				`{size[1]}x{size[2]}: janela maior que a tela`
			)
			assert(l.bodyWidth > 0 and l.bodyHeight > 0, `{size[1]}x{size[2]}: sem corpo`)
		end
	end,

	["PC is wide and does not scroll"] = function()
		for _, size in { { 1920, 1080 }, { 1280, 720 }, { 1130, 793 } } do
			local l = CosmeticsLayout.compute(size[1], size[2], SIDES)
			assert(not l.compact, `{size[1]}x{size[2]} deveria ser largo`)
			assert(l.canvasHeight <= l.bodyHeight, `{size[1]}x{size[2]} não deveria rolar`)
		end
	end,

	["phone is compact"] = function()
		for _, size in { { 844, 390 }, { 667, 375 }, { 640, 360 } } do
			assert(CosmeticsLayout.compute(size[1], size[2], SIDES).compact, `{size[1]}x{size[2]} deveria ser compacto`)
		end
	end,

	["everything inside the canvas and nothing overlaps"] = function()
		for _, size in SIZES do
			local l = CosmeticsLayout.compute(size[1], size[2], SIDES)
			local rects = { l.boneco, l.crate }
			assert(#l.cards == CARDS, "um retângulo por cartão")
			for _, card in l.cards do
				table.insert(rects, card)
			end
			for i, r in rects do
				assert(inside(r, l.bodyWidth, l.canvasHeight), `{size[1]}x{size[2]}: peça {i} fora`)
				for j = i + 1, #rects do
					assert(not overlaps(r, rects[j]), `{size[1]}x{size[2]}: peças {i} e {j} se cobrem`)
				end
			end
		end
	end,

	["cards are tall enough for plate, tagline and samples"] = function()
		for _, size in SIZES do
			local l = CosmeticsLayout.compute(size[1], size[2], SIDES)
			for _, card in l.cards do
				assert(card.h >= CosmeticsLayout.CARD_MIN_HEIGHT, `{size[1]}x{size[2]}: cartão baixo ({card.h})`)
				assert(card.w >= CosmeticsLayout.CARD_MIN_WIDTH, `{size[1]}x{size[2]}: cartão estreito ({card.w})`)
			end
		end
	end,

	["compact shows the top of the cards below the showcase"] = function()
		for _, size in { { 844, 390 }, { 667, 375 }, { 640, 360 }, { 577, 367 } } do
			local l = CosmeticsLayout.compute(size[1], size[2], SIDES)
			assert(l.cards[1].y < l.bodyHeight, `{size[1]}x{size[2]}: nenhum cartão à vista sem rolar`)
		end
	end,

	["wide puts three cards left and two right of the showcase"] = function()
		local l = CosmeticsLayout.compute(1280, 720, SIDES)
		for i = 1, 3 do
			assert(l.cards[i].x + l.cards[i].w <= l.boneco.x, `cartão {i} deveria ficar à esquerda`)
		end
		for i = 4, 5 do
			assert(l.cards[i].x >= l.boneco.x + l.boneco.w, `cartão {i} deveria ficar à direita`)
		end
		assert(l.crate.y >= l.boneco.y + l.boneco.h, "a caixa fica embaixo do boneco")
	end,
}
