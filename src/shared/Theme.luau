--!strict
-- Estilo visual para o Roblox: converte a Palette em Color3 e define fontes e medidas.
-- A interface e os efeitos leem daqui, para trocar um estilo num lugar só.
-- (Só roda no Roblox: usa Color3, Font e UDim.)
local Palette = require("./Palette")

local Theme = {}

local colorCache: { [string]: Color3 } = {}

-- Converte "#RRGGBB" em Color3 (com cache, porque a UI pede a mesma cor muitas vezes).
function Theme.color(hex: string): Color3
	local cached = colorCache[hex]
	if cached then
		return cached
	end
	local color = Color3.fromHex(hex)
	colorCache[hex] = color
	return color
end

local function toColors(group: { [string]: string }): { [string]: Color3 }
	local result = {}
	for name, hex in group do
		result[name] = Theme.color(hex)
	end
	return table.freeze(result)
end

-- Mesmos nomes da Palette, já em Color3. Ex.: Theme.ui.action, Theme.tier.gold.
Theme.ui = toColors(Palette.ui)
Theme.tier = toColors(Palette.tier)
Theme.status = toColors(Palette.status)

local builderSans = Font.fromEnum(Enum.Font.BuilderSans).Family

-- Fontes da identidade visual (todas nativas do Roblox).
Theme.font = table.freeze({
	title = Font.fromEnum(Enum.Font.LuckiestGuy), -- logo, títulos, "Você morreu"
	number = Font.fromEnum(Enum.Font.FredokaOne), -- números do HUD, contadores, botões
	label = Font.new(builderSans, Enum.FontWeight.Bold), -- nomes de item e rótulos
	body = Font.new(builderSans, Enum.FontWeight.Medium), -- descrições, tooltips
})

-- Medidas dos painéis e slots.
Theme.panelTransparency = 0.15 -- painel #1E2230 a 85% opaco
Theme.corner = UDim.new(0, 12)
Theme.slotCorner = UDim.new(0, 8)
Theme.strokeThickness = 1

-- Tamanhos em pixels (referência da identidade visual): botões de toque com
-- no mínimo 44 px; slots entre 44 e 56 px.
Theme.touchMinSize = Vector2.new(44, 44)
Theme.slotMinSize = Vector2.new(44, 44)
Theme.slotMaxSize = Vector2.new(56, 56)

return table.freeze(Theme)
