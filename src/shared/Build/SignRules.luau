--!strict
-- Regras puras da placa (G8): a lista fixa de símbolos que o dono escolhe (sem
-- texto livre: texto de jogador exigiria filtro da Roblox). O atributo Symbol da
-- peça guarda o índice (1..#SYMBOLS); 0 = nenhum símbolo.
local SignRules = {}

-- Unicode simples, que as fontes da Roblox desenham.
SignRules.SYMBOLS = table.freeze({
	"→",
	"←",
	"↑",
	"↓",
	"⚠",
	"♥",
	"☠",
	"★",
	"⌂",
	"!",
	"?",
})

-- `index` (vem do cliente, sem validar) é um símbolo da lista? Só inteiro de 1 a #SYMBOLS.
function SignRules.isValid(index: any): boolean
	return type(index) == "number" and index == math.floor(index) and index >= 1 and index <= #SignRules.SYMBOLS
end

-- Texto do símbolo, ou "" se o índice for 0 ou inválido.
function SignRules.symbolOf(index: any): string
	if SignRules.isValid(index) then
		return SignRules.SYMBOLS[index :: number]
	end
	return ""
end

return table.freeze(SignRules)
