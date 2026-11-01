--!strict
-- Regras puras da construção: grade, dano e alcance. Rodam no servidor, cliente e testes.
local Types = require("../Defs/Types")

type ItemDef = Types.ItemDef

-- Sem limite hoje; tipado como number? para o servidor poder ler.
local MAX_PER_PLAYER: number? = nil

local BuildRules = {}
BuildRules.CELL = 4 -- studs
BuildRules.HAND_DAMAGE = 5
BuildRules.SPIKE_INTERVAL = 1 -- s por par espinho/vítima
BuildRules.MAX_PER_PLAYER = MAX_PER_PLAYER
-- Studs da raiz até o ponto que escolhe a célula-alvo: meia célula + raio do
-- corpo (1,5) + meia célula. Olhando ao longo de um eixo, a célula-alvo nunca
-- fica encostada no corpo de quem constrói (sem isso, ~40% das posições eram
-- recusadas pelo próprio jogador).
BuildRules.REACH = BuildRules.CELL / 2 + 1.5 + BuildRules.CELL / 2

-- Célula inteira que contém o ponto (floor: funciona com coordenadas negativas).
function BuildRules.cellOf(x: number, z: number): (number, number)
	return math.floor(x / BuildRules.CELL), math.floor(z / BuildRules.CELL)
end

function BuildRules.cellCenter(cx: number, cz: number): (number, number)
	return (cx + 0.5) * BuildRules.CELL, (cz + 0.5) * BuildRules.CELL
end

-- A célula à frente: a que contém o ponto a REACH studs na direção dir (vetor
-- unitário no plano do chão).
function BuildRules.targetCell(x: number, z: number, dirX: number, dirZ: number): (number, number)
	return BuildRules.cellOf(x + dirX * BuildRules.REACH, z + dirZ * BuildRules.REACH)
end

function BuildRules.key(cx: number, cz: number): string
	return `{cx},{cz}`
end

-- Chaves ocupadas por uma peça size×size com o canto em (cx, cz).
function BuildRules.cellsOf(cx: number, cz: number, size: number): { string }
	local out = {}
	for dx = 0, size - 1 do
		for dz = 0, size - 1 do
			table.insert(out, BuildRules.key(cx + dx, cz + dz))
		end
	end
	return out
end

function BuildRules.damageOf(item: ItemDef?): number
	if item ~= nil and item.structureDamage ~= nil then
		return item.structureDamage
	end
	return BuildRules.HAND_DAMAGE
end

-- Gancho dos times: hoje só o próprio jogador é aliado (UserIds).
function BuildRules.areAllies(a: number, b: number): boolean
	return a == b
end

function BuildRules.underLimit(count: number): boolean
	local max = BuildRules.MAX_PER_PLAYER
	return max == nil or count < max
end

-- O ponto está dentro do quadrado da peça (size células a partir de cx, cz) expandido por margin.
function BuildRules.touches(px: number, pz: number, cx: number, cz: number, size: number, margin: number): boolean
	local cell = BuildRules.CELL
	local minX = cx * cell - margin
	local minZ = cz * cell - margin
	local maxX = (cx + size) * cell + margin
	local maxZ = (cz + size) * cell + margin
	return px >= minX and px <= maxX and pz >= minZ and pz <= maxZ
end

return table.freeze(BuildRules)
