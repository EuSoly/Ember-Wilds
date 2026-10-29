--!strict
-- Acesso aos textos exibidos. Nenhuma tela escreve texto direto no código:
-- tudo passa por Strings.get, para dar para traduzir depois trocando a tabela.
local ptBR = require("@self/ptBR")

local Strings = {}

-- Devolve o texto da chave. Se faltar, devolve "[chave]" para o erro aparecer na tela.
function Strings.get(key: string): string
	return ptBR[key] or `[{key}]`
end

function Strings.has(key: string): boolean
	return ptBR[key] ~= nil
end

return Strings
