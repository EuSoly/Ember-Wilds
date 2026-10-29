--!strict
-- Acesso aos textos exibidos. Nenhuma tela escreve texto direto no código:
-- tudo passa por Strings.get, para dar para traduzir depois trocando a tabela.
local ptBR = require("@self/ptBR")

local Strings = {}

-- Devolve o texto da chave. Se faltar, devolve "[chave]" para o erro aparecer na tela.
function Strings.get(key: string): string
	return ptBR[key] or `[{key}]`
end

-- Texto com variáveis: Strings.format("hud.day", { day = 3 }) -> "Dia 3".
-- Variável que não veio fica como está ("{day}"), para o erro aparecer na tela.
function Strings.format(key: string, vars: { [string]: string | number }): string
	return (
		string.gsub(Strings.get(key), "{(%w+)}", function(name: string): string
			local value = vars[name]
			return if value ~= nil then tostring(value) else `\{{name}}`
		end)
	)
end

function Strings.has(key: string): boolean
	return ptBR[key] ~= nil
end

return Strings
