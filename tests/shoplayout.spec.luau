--!strict
local ShopLayout = require("../src/shared/UIFlow/ShopLayout")

local SIZES = { { 1920, 1080 }, { 1280, 720 }, { 844, 390 }, { 667, 375 }, { 568, 320 } }
local GAP = ShopLayout.GAP

local function cardWidth(l: ShopLayout.Layout, columns: number): number
	return (l.contentWidth - (columns - 1) * GAP) / columns
end

return {
	["content fits the screen"] = function()
		for _, size in SIZES do
			local w, h = size[1], size[2]
			local l = ShopLayout.compute(w, h)
			assert(l.contentX >= 8 and l.contentX + l.contentWidth <= w - 8, `{w}x{h}: conteúdo fora da largura`)
			assert(l.contentTop >= l.top + l.topHeight, `{w}x{h}: conteúdo por cima do topo`)
			assert(l.contentTop < h - 8, `{w}x{h}: sem lugar para o conteúdo`)
		end
	end,

	["top bar has touch-size controls and room for the tabs"] = function()
		for _, size in SIZES do
			local w, h = size[1], size[2]
			local l = ShopLayout.compute(w, h)
			assert(l.topHeight >= 44 and l.backWidth >= 44, `{w}x{h}: topo menor que o toque`)
			assert(l.tabsWidth >= 4 * 44, `{w}x{h}: abas sem lugar ({l.tabsWidth})`)
			assert(l.tabsX + l.tabsWidth <= l.balanceLeft - 8, `{w}x{h}: abas por cima do saldo`)
			assert(l.tabsX >= l.contentX + l.backWidth + l.titleWidth, `{w}x{h}: abas por cima do voltar/título`)
		end
	end,

	["cards stay readable"] = function()
		for _, size in SIZES do
			local w, h = size[1], size[2]
			local l = ShopLayout.compute(w, h)
			assert(cardWidth(l, l.passColumns) >= 120, `{w}x{h}: gamepass estreito`)
			assert(cardWidth(l, l.spinColumns) >= 120, `{w}x{h}: giro estreito`)
			assert(
				cardWidth(l, l.emberTop) >= 120 and cardWidth(l, l.emberBottom) >= 120,
				`{w}x{h}: Golden Ember estreito`
			)
			assert(l.bannerHeight >= 120, `{w}x{h}: banner baixo`)
		end
	end,

	["compact uses fewer columns"] = function()
		local pc, phone = ShopLayout.compute(1280, 720), ShopLayout.compute(667, 375)
		assert(not pc.compact and phone.compact, "compacto errado")
		assert(
			pc.passColumns == 5 and pc.spinColumns == 5 and pc.emberTop == 3 and pc.emberBottom == 2,
			"colunas do PC"
		)
		assert(
			phone.passColumns < pc.passColumns and phone.spinColumns < pc.spinColumns,
			"celular devia ter menos colunas"
		)
		assert(phone.titleWidth == 0, "celular sem a placa LOJA")
	end,

	["spin screen stacks when narrow"] = function()
		assert(ShopLayout.compute(1280, 720).spinSideBySide, "PC lado a lado")
		assert(ShopLayout.compute(844, 390).spinSideBySide, "844 ainda cabe lado a lado")
		assert(not ShopLayout.compute(667, 375).spinSideBySide, "667 empilha")
	end,
}
