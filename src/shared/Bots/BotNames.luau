--!strict
-- Nomes dos bots no estilo dos nomes do Roblox (puro). Combinações de pedaços
-- comuns; nunca o nome de uma conta famosa. Não repete no mesmo servidor.
-- `rng` devolve [0, 1) (Random:NextNumber no servidor, World/Rng nos testes).

local FIRST = {
	"Lucas",
	"Pedro",
	"Gabriel",
	"Davi",
	"Arthur",
	"Miguel",
	"Enzo",
	"Theo",
	"Bia",
	"Duda",
	"Lara",
	"Julia",
	"Sofia",
	"Malu",
	"Nina",
	"Leo",
	"Caio",
	"Rafa",
	"Gui",
	"Vini",
	"Dark",
	"Shadow",
	"Wolf",
	"Fox",
	"Ninja",
	"Gamer",
	"Pro",
	"Noob",
	"Epic",
	"Super",
	"Ice",
	"Fire",
	"Storm",
	"Blaze",
	"Pixel",
	"Turbo",
	"Lucky",
	"Mega",
	"Craft",
	"Hunter",
}
local SECOND = {
	"",
	"",
	"",
	"Gamer",
	"Player",
	"Wolf",
	"King",
	"Master",
	"Craft",
	"Kid",
	"Boy",
	"Girl",
	"BR",
	"Pro",
	"Zin",
	"Plays",
	"Hunter",
	"Star",
	"Ninja",
	"Cat",
}
local SUFFIX = { "", "_", "123", "_BR", "XD", "007", "_YT", "2011", "2012", "2013", "_2014", "99", "77" }

local MAX_TRIES = 20
local MAX_LENGTH = 20

local BotNames = {}

local function choose<T>(rng: () -> number, list: { T }): T
	return list[math.floor(rng() * #list) + 1]
end

local function build(rng: () -> number): string
	local name = choose(rng, FIRST) .. choose(rng, SECOND)
	local suffix = choose(rng, SUFFIX)
	-- Metade das vezes um número no fim, como muita conta de verdade.
	if suffix == "" and rng() < 0.5 then
		suffix = tostring(math.floor(rng() * 9000) + 10)
	end
	return string.sub(name .. suffix, 1, MAX_LENGTH)
end

-- Um nome que não está em `taken` (quem chama marca o nome como usado).
function BotNames.pick(rng: () -> number, taken: { [string]: boolean }): string
	local name = build(rng)
	for _ = 1, MAX_TRIES do
		if not taken[name] then
			return name
		end
		name = build(rng)
	end
	-- Muitas colisões: acrescenta dígitos até ficar único.
	local base = string.sub(name, 1, MAX_LENGTH - 4)
	local n = math.floor(rng() * 9000) + 1000
	while taken[base .. n] do
		n += 1
	end
	return base .. n
end

return BotNames
