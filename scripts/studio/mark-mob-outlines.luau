-- Marca as bordas dos mobs (atributo MobOutline = true nas MeshParts de
-- ReplicatedStorage.Assets.Mobs). O jogo pinta essas peças de vermelho quando
-- o mob quer atacar (veja docs/guia/mobs-modelos.md).
-- Rodar no Studio (Edit, barra de comandos ou MCP) depois de importar ou
-- remodelar um mob; salvar o place em seguida.
--
-- Borda = nome com "rim", "border" ou "edge" E a cor de borda dos modelos:
-- branca (fff4ec), vermelha (b63b58) ou a borda do coelho (aa718f). A cor
-- separa as bordas de dentro (boca do kraken e do verme, focinho do urso).
local OUTLINE_COLORS = { fff4ec = true, b63b58 = true, aa718f = true }
local NAME_PATTERNS = { "rim", "border", "edge" }

local function hex(color: Color3): string
	return string.format("%02x%02x%02x", math.round(color.R * 255), math.round(color.G * 255), math.round(color.B * 255))
end

local function isOutline(part: MeshPart): boolean
	if not OUTLINE_COLORS[hex(part.Color)] then
		return false
	end
	local name = string.lower(part.Name)
	for _, pattern in NAME_PATTERNS do
		if string.find(name, pattern, 1, true) then
			return true
		end
	end
	return false
end

local marked, total = 0, 0
for _, mob in game:GetService("ReplicatedStorage").Assets.Mobs:GetChildren() do
	for _, part in mob:GetDescendants() do
		if part:IsA("MeshPart") then
			total += 1
			local outline = isOutline(part)
			part:SetAttribute("MobOutline", if outline then true else nil)
			if outline then
				marked += 1
			end
		end
	end
end
print(`[mark-mob-outlines] {marked} bordas em {total} peças`)
return marked
