--!strict
-- Contas da barra de carregamento (puras, testadas no Lune). Fica em
-- ReplicatedFirst, junto do script do carregamento, porque ele roda antes de
-- o resto do jogo (ReplicatedStorage) chegar ao cliente.
--
-- Enquanto espera, a barra vai freando perto de 90%; com a lista de artes
-- sendo carregada (AssetPreload), o alvo acompanha quantas já chegaram
-- (assetTarget) e o texto mostra a contagem. Quando tudo fica pronto, corre
-- até o fim. Na metade o
-- sol vira lua (é dia → noite), por isso a espera chega à metade em ~2 s:
-- dá tempo de ver o sol andar.
local LoadingMath = {}

LoadingMath.WAITING_TARGET = 0.9 -- até onde a barra vai sozinha
LoadingMath.WAIT_RATE = 0.4 -- por segundo; 0,9·(1−e^(−0,4·2)) ≈ 0,5 em 2 s
LoadingMath.FINISH_RATE = 1.5 -- fração da barra por segundo depois de pronto
LoadingMath.NIGHT_AT = 0.5 -- daqui em diante é noite (lua)
-- Passo máximo por quadro: num celular lento o primeiro quadro pode levar
-- segundos, e sem limite a barra pularia direto para a noite (sem sol).
LoadingMath.MAX_STEP = 0.1

LoadingMath.ASSET_START = 0.05 -- onde a barra está quando as artes começam

-- Próximo valor da barra depois de `dt` segundos. `target` = até onde ela vai
-- enquanto espera (padrão WAITING_TARGET; com artes, assetTarget).
function LoadingMath.step(progress: number, dt: number, ready: boolean, assetTarget: number?): number
	dt = math.min(dt, LoadingMath.MAX_STEP)
	if ready then
		return math.min(progress + dt * LoadingMath.FINISH_RATE, 1)
	end
	local target = assetTarget or LoadingMath.WAITING_TARGET
	if progress >= target then
		return progress -- nunca volta nem passa do alvo enquanto espera
	end
	return progress + (target - progress) * math.min(dt * LoadingMath.WAIT_RATE, 1)
end

-- Alvo da barra com `loaded` de `total` artes carregadas (sem lista: o de sempre).
function LoadingMath.assetTarget(loaded: number, total: number): number
	if total <= 0 then
		return LoadingMath.WAITING_TARGET
	end
	local share = math.clamp(loaded / total, 0, 1)
	return LoadingMath.ASSET_START + (LoadingMath.WAITING_TARGET - LoadingMath.ASSET_START) * share
end

-- Idioma da tela de carregamento. É a mesma regra de Strings.languageOf
-- ("pt*" → português, o resto → inglês, vazio → português), repetida aqui
-- porque o Strings ainda não chegou ao cliente; o teste loadingmath.spec
-- confere que as duas dão o mesmo resultado.
function LoadingMath.isEnglish(localeId: string?): boolean
	if type(localeId) ~= "string" or localeId == "" then
		return false
	end
	return string.lower(string.sub(localeId, 1, 2)) ~= "pt"
end

-- Textos fixos da tela (o resto do jogo usa Strings/ptBR e Strings/en).
local TEXT = {
	pt = {
		assets = "Carregando artes",
		ready = "Pronto!",
		night = "Acendendo as fogueiras…",
		day = "Carregando o mundo…",
		tip = "Dica: fique perto da fogueira à noite para não congelar.",
		skip = "Pular",
	},
	en = {
		assets = "Loading art",
		ready = "Ready!",
		night = "Lighting the campfires…",
		day = "Loading the world…",
		tip = "Tip: stay close to a campfire at night so you don't freeze.",
		skip = "Skip",
	},
}

local function texts(english: boolean?)
	return if english then TEXT.en else TEXT.pt
end

-- Milhar com ponto em português (1.730) e vírgula em inglês (1,730).
local function thousands(value: number, english: boolean?): string
	local sep = if english then "," else "."
	local digits = tostring(math.floor(math.max(value, 0)))
	local out = digits:reverse():gsub("(%d%d%d)", "%1" .. sep):reverse()
	return (out:gsub("^%" .. sep, ""))
end

-- Texto da contagem das artes ("Carregando artes 312/1.730").
function LoadingMath.assetStatus(loaded: number, total: number, english: boolean?): string
	return `{texts(english).assets} {thousands(loaded, english)}/{thousands(total, english)}`
end

function LoadingMath.isNight(progress: number): boolean
	return progress >= LoadingMath.NIGHT_AT
end

-- Texto embaixo da barra. Fixo aqui (e não no Strings) porque o Strings ainda
-- não chegou ao cliente nessa hora.
function LoadingMath.status(progress: number, english: boolean?): string
	local t = texts(english)
	if progress >= 1 then
		return t.ready
	elseif LoadingMath.isNight(progress) then
		return t.night
	end
	return t.day
end

-- Dica embaixo da tela e o botão Pular.
function LoadingMath.tip(english: boolean?): string
	return texts(english).tip
end

function LoadingMath.skip(english: boolean?): string
	return texts(english).skip
end

return LoadingMath
