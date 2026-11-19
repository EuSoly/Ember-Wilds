--!strict
-- Acesso aos textos exibidos. Nenhuma tela escreve texto direto no código:
-- tudo passa por Strings.get, que escolhe a tabela do idioma do jogador.
--
-- Idiomas: português (ptBR, a referência: toda chave nasce nele) e inglês (en).
-- O jogo decide sozinho, pelo idioma do Roblox do jogador (Player.LocaleId):
-- começa com "pt" → português; qualquer outro → inglês (é a língua que mais
-- gente entende). A tradução automática do Roblox fica desligada nas nossas
-- telas (AutoLocalize = false), para ele não traduzir de novo o que já veio
-- traduzido daqui.
--
-- - No cliente: Strings.get/format usam o idioma do LocalPlayer.
-- - No servidor não existe "o jogador": texto que o servidor monta pronto para
--   alguém (kick, aviso) usa Strings.getFor/formatFor(player, ...). Strings.get
--   no servidor (e no Lune) fica em português.
-- - Chave que faltar no en cai no ptBR (melhor português que "[chave]"), e só
--   então em "[chave]" para o erro aparecer na tela. O teste
--   tests/strings.spec.luau cobra que o en tenha toda chave do ptBR.
local en = require("@self/en")
local ptBR = require("@self/ptBR")

export type Language = "ptBR" | "en"

local TABLES: { [Language]: { [string]: string } } = { ptBR = ptBR, en = en }
local DEFAULT: Language = "ptBR"

local Strings = {}

-- Idioma escolhido para um LocaleId do Roblox ("pt-br", "en-us", "es-es"...).
-- Regra pura (testada no Lune); a mesma decide o relógio AM/PM.
function Strings.languageOf(localeId: string?): Language
	if type(localeId) == "string" and string.lower(string.sub(localeId, 1, 2)) == "pt" then
		return "ptBR"
	end
	-- Sem LocaleId (ainda não carregou) fica no português, a língua de origem.
	if localeId == nil or localeId == "" then
		return DEFAULT
	end
	return "en"
end

-- Idioma de um jogador. pcall: LocaleId pode falhar fora de um jogo de
-- verdade; aí fica no padrão.
function Strings.forPlayer(player: Player?): Language
	if player == nil then
		return DEFAULT
	end
	local ok, localeId = pcall(function(): string
		return (player :: Player).LocaleId
	end)
	return Strings.languageOf(if ok then localeId else nil)
end

-- Idioma deste lado: no cliente, o do LocalPlayer (lido uma vez, na primeira
-- vez que alguém pede texto); no servidor e no Lune, o padrão. Strings.
-- setLanguage troca à força (testes; um seletor de idioma no futuro).
local current: Language? = nil

local function detect(): Language
	-- pcall: no Lune não existe `game`. Se falhar, a 2ª volta é o erro (string).
	local ok, player = pcall(function(): Player?
		return game:GetService("Players").LocalPlayer
	end)
	return Strings.forPlayer(if ok then player else nil)
end

function Strings.language(): Language
	if current == nil then
		current = detect()
	end
	return current :: Language
end

function Strings.setLanguage(language: Language)
	current = language
end

-- Texto da chave no idioma pedido; falta no idioma → ptBR → "[chave]".
local function textIn(language: Language, key: string): string
	return TABLES[language][key] or ptBR[key] or `[{key}]`
end

local function fill(text: string, vars: { [string]: string | number }): string
	return (
		string.gsub(text, "{(%w+)}", function(name: string): string
			local value = vars[name]
			return if value ~= nil then tostring(value) else `\{{name}}`
		end)
	)
end

-- Devolve o texto da chave. Se faltar, devolve "[chave]" para o erro aparecer na tela.
function Strings.get(key: string): string
	return textIn(Strings.language(), key)
end

-- Texto com variáveis: Strings.format("hud.day", { day = 3 }) -> "Dia 3".
-- Variável que não veio fica como está ("{day}"), para o erro aparecer na tela.
function Strings.format(key: string, vars: { [string]: string | number }): string
	return fill(Strings.get(key), vars)
end

-- No servidor: o texto já no idioma de `player` (ex. a mensagem do kick).
function Strings.getFor(player: Player?, key: string): string
	return textIn(Strings.forPlayer(player), key)
end

function Strings.formatFor(player: Player?, key: string, vars: { [string]: string | number }): string
	return fill(Strings.getFor(player, key), vars)
end

-- A chave existe? O ptBR é a referência (as Defs validam contra ele).
function Strings.has(key: string): boolean
	return ptBR[key] ~= nil
end

-- As tabelas cruas, para o teste comparar os idiomas.
Strings.tables = TABLES

return Strings
