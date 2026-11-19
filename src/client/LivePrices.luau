--!strict
-- Preço em Robux que o Roblox cobra deste jogador, buscado NO CLIENTE. A
-- assinatura VIP tem preço por região (Regional Pricing, que não desliga) e o
-- Creator Hub só a aprova se a tela mostrar o preço devolvido pelo Roblox na
-- hora ("Requires dynamic prices"): a chamada do cliente leva os dados do
-- jogador; a do servidor devolve o preço base. Por isso toda tela que mostra
-- preço em Robux lê daqui, e não das tabelas do código.
--
-- - gamepass:   GetProductInfoAsync(id, InfoType.GamePass).PriceInRobux
-- - produto:    GetProductInfoAsync(id, InfoType.Product).PriceInRobux
-- - assinatura: GetSubscriptionProductInfoAsync(id): DisplayPrice (texto
--   pronto, com a moeda) e PriceInRobux (0 = não se compra com Robux)
-- Cada preço é uma fonte Vide: a tela abre com o preço do código (reserva) e
-- troca sozinha quando o do Roblox chega. Busca uma vez por item (cache),
-- fora da tela (task.spawn) e em pcall; falhou, tenta de novo mais tarde e,
-- até lá, fica o do código. Regras puras em Shop/PriceRules.
-- Só o número MOSTRADO muda: quem cobra continua o RobuxService.
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local PriceRules = require(Shared:WaitForChild("Shop"):WaitForChild("PriceRules"))
local Products = require(Shared:WaitForChild("Shop"):WaitForChild("Products"))

type Source<T> = (() -> T) & ((T) -> T)
type Live = PriceRules.Live

-- Esperas entre as tentativas que falharam (segundos); depois da última,
-- desiste e fica o preço do código até o jogador voltar ao jogo.
local RETRY_SECONDS = { 5, 20, 60 }

local LivePrices = {}

local cache: { [string]: Source<Live?> } = {}

-- Pergunta ao Roblox (pode demorar: só dentro de task.spawn).
local function ask(home: string, id: number | string): any
	if home == "subscription" then
		return MarketplaceService:GetSubscriptionProductInfoAsync(id :: string)
	end
	local infoType = if home == "pass" then Enum.InfoType.GamePass else Enum.InfoType.Product
	return MarketplaceService:GetProductInfoAsync(id :: number, infoType)
end

local function fetch(key: string, home: string, id: number | string, value: Source<Live?>)
	task.spawn(function()
		-- 1ª tentativa na hora; as outras depois das esperas de RETRY_SECONDS.
		for attempt = 1, #RETRY_SECONDS + 1 do
			if attempt > 1 then
				task.wait(RETRY_SECONDS[attempt - 1])
			end
			local ok, info = pcall(ask, home, id)
			if ok then
				local live = PriceRules.read(home :: PriceRules.Home, info)
				if live ~= nil then
					value(live)
				end
				-- Respondeu sem preço (ex. fora de venda): não adianta insistir.
				return
			end
			warn(`[LivePrices] preço de {key} não veio ({info}); mostrando o do código`)
		end
	end)
end

-- Fonte do preço vivo de `productId` (`gift` = o "Presente: X" dele). nil
-- enquanto não chegou, se falhou ou se o item não tem id no Roblox.
local function source(productId: string, gift: boolean?): () -> Live?
	local key = if gift then `gift:{productId}` else productId
	local value = cache[key]
	if value == nil then
		local created: Source<Live?> = vide.source(nil :: Live?) :: any
		value = created
		cache[key] = created
		local home, id = PriceRules.target(productId, gift)
		if home ~= nil and id ~= nil then
			fetch(key, home, id, created)
		end
	end
	return value :: any
end

-- Preço do código de `productId` (a reserva).
local function codePrice(productId: string): number
	local product = Products.get(productId)
	return if product and product.price.currency == "robux" then product.price.amount else 0
end

-- Número em Robux a mostrar (reativo). `fallback` = preço do código (sem ele,
-- o de Shop/Products). `gift` = preço do produto de presente.
function LivePrices.robux(productId: string, fallback: number?, gift: boolean?): number
	return PriceRules.robux(source(productId, gift)(), fallback or codePrice(productId))
end

-- Preço com a moeda (reativo): o texto do Roblox na assinatura; nos outros,
-- o símbolo do Robux e o número.
function LivePrices.label(productId: string, fallback: number?): string
	return PriceRules.label(source(productId)(), fallback or codePrice(productId))
end

-- Fonte pronta para ShopParts.priceButton (robux = função).
function LivePrices.of(productId: string, fallback: number?, gift: boolean?): () -> number
	return function()
		return LivePrices.robux(productId, fallback, gift)
	end
end

-- Revive pago: o servidor manda só o preço do degrau (LifeEnded.Revive.Robux);
-- cada degrau é um produto (revive_1..revive_4), então busca o do degrau certo.
-- Preço que não bate com nenhum degrau: mostra o que o servidor mandou.
function LivePrices.revive(robux: number): number
	local step = PriceRules.reviveStep(robux)
	if step == nil then
		return robux
	end
	return LivePrices.robux(`revive_{step}`, robux)
end

-- Começa a buscar os preços de toda a loja (sem esperar), para a loja já
-- abrir com eles. Os ocultos (revive) também: a oferta aparece na morte, sem
-- tempo de buscar.
function LivePrices.prefetch()
	for _, product in Products.all() do
		if product.price.currency == "robux" then
			source(product.id)
		end
	end
end

-- Como o ShopData: começa ao carregar (a primeira tela que pede um preço).
LivePrices.prefetch()

return LivePrices
