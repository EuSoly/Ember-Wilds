--!strict
local SignRules = require("../src/shared/Build/SignRules")

local spec = {}

function spec.lista_tem_de_8_a_12_simbolos_distintos()
	local n = #SignRules.SYMBOLS
	assert(n >= 8 and n <= 12, "entre 8 e 12 símbolos")
	local seen: { [string]: boolean } = {}
	for _, symbol in SignRules.SYMBOLS do
		assert(symbol ~= "" and not seen[symbol], "símbolo vazio ou repetido")
		seen[symbol] = true
	end
end

function spec.todo_indice_da_lista_e_valido()
	for i = 1, #SignRules.SYMBOLS do
		assert(SignRules.isValid(i), "índice " .. i .. " deveria ser válido")
		assert(SignRules.symbolOf(i) == SignRules.SYMBOLS[i], "symbolOf devolve o símbolo")
	end
end

function spec.indices_invalidos()
	assert(not SignRules.isValid(0), "0 = nenhum, não é escolha")
	assert(not SignRules.isValid(#SignRules.SYMBOLS + 1), "um depois do fim")
	assert(not SignRules.isValid(255), "255")
	assert(not SignRules.isValid(-1), "negativo")
	assert(not SignRules.isValid(1.5), "fracionário")
	assert(not SignRules.isValid(0 / 0), "NaN")
	assert(not SignRules.isValid(math.huge), "infinito")
	assert(not SignRules.isValid("1"), "texto")
	assert(not SignRules.isValid(nil), "nil")
	assert(SignRules.symbolOf(0) == "", "0 sem símbolo")
end

return spec
