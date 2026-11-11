--!strict
-- Fantasma e pedra da ressurreição (puro, testado no Lune). Números e listas do
-- guia oficial do Starve (commands.html: ghost_delay, blue_crown_ghost_malus,
-- delete_ghost_items, delete_blue_crown_items). Veja docs/guia/ressurreicao.md.
local Types = require("../Defs/Types")

type ItemDef = Types.ItemDef
-- Como volta: "heart" (Coração de Dragão, gasto) ou "crown" (Coroa do Anjo).
export type Source = string

local GhostRules = {}

GhostRules.GHOST_SECONDS = 60 -- tempo de fantasma (coração; coroa sem item forte)
GhostRules.MEMORY = 30 -- segundos que um item segurado conta para a coroa
GhostRules.REVIVE_RADIUS = 6 -- studs além do raio da pedra para ressuscitar
GhostRules.KILL_BONUS = 0.10 -- quem matou alguém que virou fantasma (morte normal: 15%)
GhostRules.HEART = "dragon_heart"

-- Tempo de fantasma da coroa pelo item mais forte segurado (Starve): até ouro 60.
local CROWN_SECONDS: { [string]: number } = {
	diamond = 35,
	amethyst = 25,
	reidite = 15,
	dragon = 8,
	lava = 5,
}

-- Como volta: a coroa (não gasta) vale antes do coração (gasta).
function GhostRules.source(hasHeart: boolean, wearsCrown: boolean): Source?
	if wearsCrown then
		return "crown"
	elseif hasHeart then
		return "heart"
	end
	return nil
end

-- "Força" do item para a coroa: o conjunto das armas de dragão/lava, ou o tier.
local function strengthOf(def: ItemDef): string?
	if def.gearBonus then
		return def.gearBonus.set
	end
	return def.tier
end

-- Segundos de fantasma. `held` = itens segurados nos últimos MEMORY segundos.
function GhostRules.seconds(source: Source, held: { ItemDef }): number
	local seconds = GhostRules.GHOST_SECONDS
	if source ~= "crown" then
		return seconds
	end
	for _, def in held do
		local strength = strengthOf(def)
		local value = strength and CROWN_SECONDS[strength]
		if value and value < seconds then
			seconds = value
		end
	end
	return seconds
end

local HIGH_TIERS: { [string]: boolean } = { reidite = true }

-- Perde este item ao ressuscitar? Coração: armas (inclui escudos), picaretas,
-- chave inglesa, forcados, super martelo e martelos de reidite para cima.
-- Coroa: armas, espinhos e portas com espinho, super martelo.
function GhostRules.loses(source: Source, def: ItemDef): boolean
	if def.id == "super_hammer" then
		return true
	end
	if def.category == "weapon" then
		return true
	end
	if source == "heart" then
		return def.pickaxe ~= nil
			or def.repair ~= nil
			or def.harvest ~= nil
			or (def.hammer ~= nil and def.tier ~= nil and HIGH_TIERS[def.tier] == true)
	end
	local structure = def.structure
	return structure ~= nil and (structure.kind == "spike" or structure.kind == "spike_door")
end

-- Pontos que ficam ao ressuscitar (1/3, para baixo).
function GhostRules.revivedScore(score: number): number
	return math.floor(score / 3)
end

-- Bônus de quem matou alguém que virou fantasma.
function GhostRules.ghostKillBonus(score: number): number
	return math.floor(score * GhostRules.KILL_BONUS)
end

-- Pode ressuscitar a `distance` studs da borda da pedra, no instante `now`?
function GhostRules.canRevive(distance: number, now: number, ghostUntil: number): boolean
	return distance <= GhostRules.REVIVE_RADIUS and now < ghostUntil
end

-- O jogador é fantasma? `ghostUntil` = atributo GhostUntil do Player (nil = não).
function GhostRules.isGhost(ghostUntil: number?, now: number): boolean
	return ghostUntil ~= nil and now < ghostUntil
end

-- O jogador é fantasma agora? Lê o atributo GhostUntil (escrito pelo GhostService).
function GhostRules.isGhostPlayer(player: Player, now: number): boolean
	local untilAt = player:GetAttribute("GhostUntil")
	return GhostRules.isGhost(if type(untilAt) == "number" then untilAt else nil, now)
end

return GhostRules
