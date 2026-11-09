--!strict
local RankConfig = require("../src/shared/Data/RankConfig")
local RankingLayout = require("../src/shared/UIFlow/RankingLayout")
local Strings = require("../src/shared/Strings")

local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-6
end

-- Mesmas frações do RankingImages.PODIUM_SPOTS (o teste não carrega Rect/Vector2).
local SECOND = { x = 0.22, top = 0.274, plaqueY = 0.616 }

return {
	["every ranking text exists"] = function()
		local keys = {
			"rank.title",
			"rank.loading",
			"rank.error",
			"rank.empty",
			"rank.you",
			"rank.position",
			"rank.outside",
			"rank.none",
			"rank.ends.days",
			"rank.ends.hours",
			"rank.ends.minutes",
			"rank.ends.soon",
		}
		for _, category in RankConfig.CATEGORIES do
			table.insert(keys, "rank.tab." .. category)
			table.insert(keys, "rank.value." .. category)
		end
		for _, key in keys do
			assert(Strings.has(key), `falta o texto {key}`)
		end
	end,

	["wide PC screen puts podium and list side by side"] = function()
		local l = RankingLayout.compute(1500, 800, 1)
		assert(not l.compact and not l.stacked, "PC largo: lado a lado, sem compacto")
		assert(l.podiumWidth + l.listWidth + l.gap <= 1500, "cabe na largura")
	end,

	["touch targets stay at least 44 px after scale"] = function()
		for _, scale in { 0.8, 1, 1.25 } do
			local l = RankingLayout.compute(1000, 560, scale)
			assert(l.rowHeight * scale >= 44, `linha {l.rowHeight * scale} com escala {scale}`)
			assert(l.tabHeight * scale >= 44, `aba {l.tabHeight * scale} com escala {scale}`)
		end
	end,

	["phone landscape is compact"] = function()
		local l = RankingLayout.compute(844, 390, 1)
		assert(l.compact, "celular deitado é compacto")
		assert(l.podiumWidth + l.listWidth + l.gap <= 844 or l.stacked, "não passa da largura")
	end,

	["narrow window stacks the podium over the list"] = function()
		local l = RankingLayout.compute(560, 700, 1)
		assert(l.stacked, "estreita: pódio em cima")
		assert(l.listWidth == l.bodyWidth and l.podiumWidth <= l.bodyWidth, "lista na largura toda do corpo")
	end,

	["short landscape window keeps podium and list side by side"] = function()
		local l = RankingLayout.compute(678, 508, 1.25)
		assert(not l.stacked, "deitada e baixa (escala 1,25): lado a lado")
		assert(l.podiumWidth + l.listWidth + l.gap <= 678, "cabe na largura")
	end,

	["compact window keeps two rows and the 'você' row visible"] = function()
		local l = RankingLayout.compute(600, 310, 1)
		assert(l.compact and l.inlineTabs, "compacto: abas na linha do título")
		local need = 2 * l.rowHeight + RankingLayout.ME_SCALE * l.rowHeight + 16
		assert(l.bodyHeight >= need, `corpo {l.bodyHeight} < {need}`)
	end,

	["phone at scale 1.25 still shows a row and the 'você' row"] = function()
		local l = RankingLayout.compute(480, 248, 1.25)
		local need = l.rowHeight + RankingLayout.ME_SCALE * l.rowHeight + 12
		assert(l.bodyHeight >= need, `corpo {l.bodyHeight} < {need}`)
		assert(l.rowHeight * 1.25 >= 44, "toque ainda >= 44")
	end,

	["body fits inside the window"] = function()
		for _, size in { { 1500, 800 }, { 844, 390 }, { 600, 310 } } do
			local l = RankingLayout.compute(size[1], size[2], 1)
			assert(l.bodyTop + l.bodyHeight + l.inset <= size[2] + 1e-6, "altura")
			assert(l.bodyWidth + 2 * l.inset <= size[1] + 1e-6, "largura")
		end
	end,

	["spot sits the avatar on the step and the number on the plaque"] = function()
		local seatX, seatY, plaqueX, plaqueY = RankingLayout.spot(SECOND, 1024, 576)
		assert(near(seatX, 0.22 * 1024) and near(plaqueX, seatX), "mesma coluna do degrau")
		assert(near(seatY, (0.274 + RankingLayout.SEAT) * 576), `assento {seatY}`)
		assert(near(plaqueY, 0.616 * 576), `plaquinha {plaqueY}`)
	end,

	["spot scales with the podium size"] = function()
		local ax, ay = RankingLayout.spot(SECOND, 1024, 576)
		local bx, by = RankingLayout.spot(SECOND, 512, 288)
		assert(near(bx, ax / 2) and near(by, ay / 2), "metade do tamanho = metade das posições")
	end,
}
