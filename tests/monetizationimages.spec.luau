--!strict
-- O Lune não tem Rect (o módulo não carrega aqui), então o teste lê o texto de
-- src/shared/MonetizationImages.luau: cada `nome = "id"` (inclusive os de dentro
-- das tabelas de estados) e cada `NOME_SLICE = Rect.new(a, b, c, d)`.
local fs = require("@lune/fs")

local SOURCE = fs.readFile("src/shared/MonetizationImages.luau")
local SENT = fs.readFile("assets/ui/monetizacao/ids-enviados.md")

-- Tamanho da arte de cada peça 9-slice (LEIA-ME de assets/ui/monetizacao).
local SLICE_SIZES: { [string]: { number } } = {
	VIP_CARD_SLICE = { 1024, 512 },
	REVIVE_PANEL_SLICE = { 800, 500 },
	BUTTON_SLICE = { 512, 154 },
	VIP_RIBBON_SLICE = { 300, 100 },
	CHECKIN_WINDOW_SLICE = { 1000, 700 },
	CHECKIN_DAY_SLICE = { 240, 300 },
	CHECKIN_DAY7_SLICE = { 360, 450 },
	PREMIUM_CARD_SLICE = { 1024, 400 },
	MULTIPLIER_TAG_SLICE = { 200, 64 },
	RECIPE_SCROLL_SLICE = { 400, 600 },
	-- Camadas (assets/ui/monetizacao/camadas/LEIA-ME.txt).
	VIP_LAYERS_SLICE = { 1024, 512 },
	SHOP_CARD_LAYERS_SLICE = { 1024, 512 },
	DAY7_LAYERS_SLICE = { 360, 450 },
	PREMIUM_LAYERS_SLICE = { 1024, 400 },
}

-- Linhas sem comentário, para não ler texto entre aspas dos comentários.
local function codeLines(): { string }
	local lines = {}
	for line in string.gmatch(SOURCE, "[^\r\n]+") do
		if not string.match(line, "^%s*%-%-") then
			table.insert(lines, line)
		end
	end
	return lines
end

return {
	["monetization images: every id is empty or rbxassetid://<digits>"] = function()
		local count = 0
		for _, line in codeLines() do
			for name, id in string.gmatch(line, '([%w_%.]+) = "([^"]*)"') do
				count += 1
				assert(id == "" or string.match(id, "^rbxassetid://%d+$") ~= nil, `{name}: id inválido "{id}"`)
			end
		end
		assert(count > 30, `poucos ids lidos ({count}): o módulo mudou de forma?`)
	end,

	["monetization images: slices fit inside their art"] = function()
		local seen: { [string]: boolean } = {}
		for _, line in codeLines() do
			local name, a, b, c, d = string.match(line, "%.([%w_]+_SLICE) = Rect%.new%((%d+), (%d+), (%d+), (%d+)%)")
			if name then
				seen[name] = true
				local size = SLICE_SIZES[name]
				assert(size ~= nil, `{name}: Rect sem tamanho de arte no teste`)
				local x0, y0, x1, y1 =
					tonumber(a) :: number, tonumber(b) :: number, tonumber(c) :: number, tonumber(d) :: number
				assert(x0 > 0 and y0 > 0, `{name}: slice começa dentro`)
				assert(x1 < size[1] and y1 < size[2], `{name}: slice termina dentro`)
				assert(x0 < x1 and y0 < y1, `{name}: slice com miolo`)
			end
		end
		for name in SLICE_SIZES do
			assert(seen[name], `{name}: não achei o Rect no módulo`)
		end
	end,

	["monetization images: every filled id is one of the sent arts"] = function()
		for _, line in codeLines() do
			for name, id in string.gmatch(line, '([%w_%.]+) = "(rbxassetid://%d+)"') do
				assert(string.find(SENT, id, 1, true) ~= nil, `{name}: {id} não está em ids-enviados.md`)
			end
		end
	end,

	["monetization images: art sizes match the slice table"] = function()
		local count = 0
		for _, line in codeLines() do
			local name, w, h = string.match(line, "%.([%w_]+)_SIZE = Vector2%.new%((%d+), (%d+)%)")
			local size = if name then SLICE_SIZES[name .. "_SLICE"] else nil
			if name and size then
				count += 1
				assert(tonumber(w) == size[1] and tonumber(h) == size[2], `{name}_SIZE diferente do tamanho da arte`)
			end
		end
		assert(count >= 8, `poucos tamanhos lidos ({count})`)
	end,
}
