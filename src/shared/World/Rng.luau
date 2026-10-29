--!strict
-- Gerador de números aleatórios com semente (mulberry32), puro: dá exatamente
-- a mesma sequência no Roblox e no Lune (que não tem o Random do Roblox).
-- O espalhador do mapa usa este gerador para o mapa sair igual a cada partida.
-- As contas de 32 bits usam bit32 e uma multiplicação partida em metades de
-- 16 bits, para nenhum produto passar de 2^53 (o limite exato de um número).

local TWO_32 = 4294967296

-- Multiplicação de 32 bits sem sinal, com resultado módulo 2^32.
local function mul32(a: number, b: number): number
	local aLow, aHigh = a % 65536, a // 65536
	local bLow, bHigh = b % 65536, b // 65536
	local cross = (aHigh * bLow + aLow * bHigh) % 65536
	return (cross * 65536 + aLow * bLow) % TWO_32
end

local Rng = {}
Rng.__index = Rng

export type Rng = typeof(setmetatable({} :: { _state: number }, Rng))

-- Qualquer número inteiro serve de semente (negativos e enormes também).
function Rng.new(seed: number): Rng
	return setmetatable({ _state = math.floor(seed) % TWO_32 }, Rng)
end

-- Número em [0, 1).
function Rng.nextNumber(self: Rng): number
	self._state = (self._state + 0x6D2B79F5) % TWO_32
	local t = self._state
	t = mul32(bit32.bxor(t, bit32.rshift(t, 15)), bit32.bor(t, 1))
	t = bit32.bxor(t, (t + mul32(bit32.bxor(t, bit32.rshift(t, 7)), bit32.bor(t, 61))) % TWO_32)
	return bit32.bxor(t, bit32.rshift(t, 14)) / TWO_32
end

-- Inteiro em [min, max] (os dois inclusive).
function Rng.nextInteger(self: Rng, min: number, max: number): number
	return min + math.floor(self:nextNumber() * (max - min + 1))
end

return Rng
