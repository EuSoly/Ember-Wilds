--!strict
local DeathLayout = require("../src/shared/UIFlow/DeathLayout")

-- PC, notebook, celulares deitados e um celular em pé (pixels lógicos).
local SIZES = {
	{ 1920, 1080 },
	{ 1280, 720 },
	{ 1128, 793 },
	{ 844, 390 },
	{ 667, 375 },
	{ 568, 320 },
	{ 390, 844 },
}
local KITS = 4

local function inside(r: DeathLayout.Rect, w: number, h: number): boolean
	return r.x >= 0 and r.y >= 0 and r.w > 0 and r.h > 0 and r.x + r.w <= w + 0.01 and r.y + r.h <= h + 0.01
end

local function overlaps(a: DeathLayout.Rect, b: DeathLayout.Rect): boolean
	return a.x < b.x + b.w and b.x < a.x + a.w and a.y < b.y + b.h and b.y < a.y + a.h
end

return {
	["panel and its title plate fit the screen"] = function()
		for _, size in SIZES do
			local l = DeathLayout.compute(size[1], size[2], KITS)
			assert(l.panelWidth <= size[1], `{size[1]}x{size[2]}: janela mais larga que a tela`)
			assert(
				l.panelHeight + DeathLayout.TITLE_HEIGHT / 2 <= size[2],
				`{size[1]}x{size[2]}: janela + placa mais altas que a tela`
			)
			assert(l.bodyWidth > 0 and l.bodyHeight > 0, `{size[1]}x{size[2]}: sem corpo`)
		end
	end,

	["panel never grows past its maximum"] = function()
		local l = DeathLayout.compute(3840, 2160, KITS)
		assert(l.panelWidth == 760 and l.panelHeight == 460, "limite 760x460")
	end,

	["wide screens use two columns side by side"] = function()
		for _, size in { { 1920, 1080 }, { 1280, 720 }, { 844, 390 }, { 667, 375 } } do
			local l = DeathLayout.compute(size[1], size[2], KITS)
			assert(not l.stacked, `{size[1]}x{size[2]}: deveria ter duas colunas`)
			assert(l.summary.x < l.kits.x, "resumo à esquerda dos kits")
			assert(l.summary.y == l.kits.y, "colunas na mesma altura")
			assert(l.canvasHeight == l.bodyHeight, "duas colunas não rolam")
		end
	end,

	["narrow screens stack summary above kits"] = function()
		for _, size in { { 568, 320 }, { 390, 844 } } do
			local l = DeathLayout.compute(size[1], size[2], KITS)
			assert(l.stacked, `{size[1]}x{size[2]}: deveria empilhar`)
			assert(l.kits.y >= l.summary.y + l.summary.h, "kits embaixo do resumo")
			assert(l.canvasHeight == l.kits.y + l.kits.h, "a rolagem vai até o fim dos kits")
			assert(l.kits.h == DeathLayout.kitsHeight(KITS), "empilhado: todos os kits sem rolar por dentro")
		end
	end,

	["pieces stay inside the body without overlapping"] = function()
		for _, size in SIZES do
			local l = DeathLayout.compute(size[1], size[2], KITS)
			assert(inside(l.summary, l.bodyWidth, l.canvasHeight), `{size[1]}x{size[2]}: resumo fora do corpo`)
			assert(inside(l.kits, l.bodyWidth, l.canvasHeight), `{size[1]}x{size[2]}: kits fora do corpo`)
			assert(not overlaps(l.summary, l.kits), `{size[1]}x{size[2]}: resumo em cima dos kits`)
		end
	end,

	["compact follows the design system rule"] = function()
		assert(DeathLayout.compute(899, 800, KITS).compact, "largura < 900 é compacto")
		assert(DeathLayout.compute(1280, 499, KITS).compact, "altura < 500 é compacto")
		assert(not DeathLayout.compute(1280, 720, KITS).compact, "1280x720 não é compacto")
	end,

	["kits height counts header, rows and gaps"] = function()
		local h = DeathLayout.kitsHeight(3)
		local inset = DeathLayout.KIT_LIST_INSET * 2
		local expected = DeathLayout.KITS_HEADER
			+ inset
			+ 3 * DeathLayout.KIT_ROW
			+ 2 * DeathLayout.KIT_GAP
			+ DeathLayout.KITS_PADDING
		assert(h == expected, `esperado {expected}, veio {h}`)
		assert(
			DeathLayout.kitsHeight(0) == DeathLayout.KITS_HEADER + inset + DeathLayout.KITS_PADDING,
			"sem kits: só o cabeçalho"
		)
	end,
}
