--!strict
-- Catálogo de tudo que se compra (servidor e cliente usam o mesmo). Monta os
-- produtos a partir dos dados (Shop/Bundles, ShopConfig, Defs.Kits) e valida
-- tudo no boot: um erro de digitação num pacote para o jogo com a lista do
-- que está errado, como o Defs faz.
--
-- Ids dos produtos:
--   bundle_<id>             pacote em destaque (uma vez por jogador)
--   pack_<quantidade>       pacote de Golden Ember
--   spins_normal_<qtd>      giros normais (Golden Ember)
--   spins_paid_<qtd>        giros especiais
--   kitonce_<kit>           +1 no saldo de 1 vida do kit
--   kit_<kit>               kit para sempre (uma vez)
--   pass_<passe>            passe para sempre (uma vez)
local Defs = require("../Defs")
local DefsTypes = require("../Defs/Types")
local Strings = require("../Strings")
local Bundles = require("./Bundles")
local Rewards = require("./Rewards")
local ShopConfig = require("./ShopConfig")
local ShopDates = require("./ShopDates")
local ShopTypes = require("./Types")

export type Product = ShopTypes.Product
export type BundleDef = ShopTypes.BundleDef
export type Price = ShopTypes.Price

type DefsTables = DefsTypes.DefsTables
type StringsApi = { has: (key: string) -> boolean }

local Products = {}

local function isPositiveInt(value: any): boolean
	return type(value) == "number" and value >= 1 and value % 1 == 0
end

-- Erros dos pacotes `list` (vazio = tudo certo). Separado para os testes
-- passarem pacotes inventados.
function Products.validateBundles(list: { BundleDef }, defs: DefsTables, strings: StringsApi): { string }
	local errors: { string } = {}
	local seen: { [string]: boolean } = {}
	for i, bundle in list do
		local label = `pacote "{bundle.id}" (#{i})`
		local function fail(message: string)
			table.insert(errors, `{label}: {message}`)
		end
		if type(bundle.id) ~= "string" or not string.match(bundle.id, "^[a-z0-9_]+$") then
			fail("id só com a-z, 0-9 e _")
		elseif seen[bundle.id] then
			fail("id repetido")
		end
		seen[bundle.id] = true
		if type(bundle.nameKey) ~= "string" or not strings.has(bundle.nameKey) then
			fail(`nameKey "{bundle.nameKey}" sem texto em Strings/ptBR.luau`)
		end
		if type(bundle.theme) ~= "string" or not string.match(bundle.theme, "^#%x%x%x%x%x%x$") then
			fail("theme precisa ser #RRGGBB")
		end
		if not isPositiveInt(bundle.rarity) or bundle.rarity > 5 then
			fail("rarity precisa ser inteiro de 1 a 5")
		end
		if not isPositiveInt(bundle.robux) then
			fail("robux precisa ser inteiro ≥ 1")
		end
		local startsAt = if bundle.startsAt ~= nil then ShopDates.parse(bundle.startsAt) else nil
		local endsAt = if bundle.endsAt ~= nil then ShopDates.parse(bundle.endsAt) else nil
		if bundle.startsAt ~= nil and startsAt == nil then
			fail(`startsAt "{bundle.startsAt}" fora do formato "AAAA-MM-DD HH:MM"`)
		end
		if bundle.endsAt ~= nil and endsAt == nil then
			fail(`endsAt "{bundle.endsAt}" fora do formato "AAAA-MM-DD HH:MM"`)
		end
		if startsAt ~= nil and endsAt ~= nil and endsAt <= startsAt then
			fail("endsAt precisa ser depois de startsAt")
		end
		if type(bundle.rewards) ~= "table" or #bundle.rewards == 0 then
			fail("rewards vazio")
		else
			for _, reward in bundle.rewards do
				local message = Rewards.validate(reward, defs)
				if message then
					fail(message)
				end
			end
		end
	end
	return errors
end

-- Monta todos os produtos (na ordem: pacotes, moeda, giros, kits, passes).
local function build(): { Product }
	local list: { Product } = {}
	local function add(product: Product)
		product.order = #list + 1
		table.insert(list, product)
	end
	for _, bundle in Bundles do
		add({
			id = `bundle_{bundle.id}`,
			kind = "bundle",
			price = { currency = "robux", amount = bundle.robux },
			once = true,
			startsAt = if bundle.startsAt then ShopDates.parse(bundle.startsAt) else nil,
			endsAt = if bundle.endsAt then ShopDates.parse(bundle.endsAt) else nil,
			rewards = bundle.rewards,
			nameKey = bundle.nameKey,
			order = 0,
		})
	end
	for _, pack in ShopConfig.EMBER_PACKS do
		add({
			id = `pack_{pack.amount}`,
			kind = "pack",
			price = { currency = "robux", amount = pack.robux },
			once = false,
			rewards = { { kind = "ember", amount = pack.amount } },
			order = 0,
		})
	end
	local spinKinds: { ShopTypes.SpinKind } = { "normal", "paid" }
	for _, spin in spinKinds do
		for _, offer in ShopConfig.SPIN_PACKS[spin] do
			-- O verificador alarga "normal"/"paid" para string dentro da tabela.
			local reward: ShopTypes.Reward = { kind = "spins", spin = spin, count = offer.qty } :: any
			add({
				id = `spins_{spin}_{offer.qty}`,
				kind = "spins",
				price = { currency = if spin == "normal" then "ember" else "robux", amount = offer.price },
				once = false,
				rewards = { reward },
				order = 0,
			})
		end
	end
	local kitIds: { string } = {}
	for id in Defs.Kits do
		table.insert(kitIds, id)
	end
	table.sort(kitIds, function(a, b)
		return Defs.Kits[a].order < Defs.Kits[b].order
	end)
	for _, kitId in kitIds do
		local prices = ShopConfig.KIT_ROBUX[kitId]
		if prices then
			add({
				id = `kitonce_{kitId}`,
				kind = "kitOnce",
				price = { currency = "robux", amount = prices.once },
				once = false,
				rewards = { { kind = "kitOnce", id = kitId, count = 1 } },
				nameKey = Defs.Kits[kitId].nameKey,
				order = 0,
			})
			add({
				id = `kit_{kitId}`,
				kind = "kit",
				price = { currency = "robux", amount = prices.forever },
				once = true,
				rewards = { { kind = "kit", id = kitId } },
				nameKey = `shop.pass.{kitId}`,
				order = 0,
			})
		end
	end
	for passId, pass in ShopConfig.PASSES do
		add({
			id = `pass_{passId}`,
			kind = "pass",
			price = { currency = "robux", amount = pass.robux },
			once = true,
			rewards = { { kind = "pass", id = passId } },
			nameKey = pass.nameKey,
			order = 0,
		})
	end
	return list
end

local ALL = build()
local BY_ID: { [string]: Product } = {}
for _, product in ALL do
	BY_ID[product.id] = product
end

function Products.all(): { Product }
	return ALL
end

function Products.get(id: string): Product?
	return BY_ID[id]
end

-- O pacote como escrito em Shop/Bundles (para a tela: tema, raridade...).
function Products.bundleDef(bundleId: string): BundleDef?
	for _, bundle in Bundles do
		if bundle.id == bundleId then
			return bundle
		end
	end
	return nil
end

-- Pacotes em destaque abertos em `now` (unix), na ordem de Shop/Bundles.
function Products.bundles(now: number): { Product }
	local open: { Product } = {}
	for _, product in ALL do
		if product.kind == "bundle" and ShopDates.isOpen(product.startsAt, product.endsAt, now) then
			table.insert(open, product)
		end
	end
	return open
end

-- Todos os erros do catálogo real (vazio = tudo certo).
function Products.validate(defs: DefsTables, strings: StringsApi): { string }
	local errors = Products.validateBundles(Bundles, defs, strings)
	for kitId in defs.Kits do
		if ShopConfig.KIT_ROBUX[kitId] == nil then
			table.insert(errors, `kit "{kitId}" sem preço em ShopConfig.KIT_ROBUX`)
		end
	end
	local seen: { [string]: boolean } = {}
	for _, product in ALL do
		if seen[product.id] then
			table.insert(errors, `produto "{product.id}" repetido`)
		end
		seen[product.id] = true
		if product.nameKey ~= nil and not strings.has(product.nameKey) then
			table.insert(errors, `produto "{product.id}": nameKey "{product.nameKey}" sem texto`)
		end
	end
	return errors
end

local errors = Products.validate(Defs, Strings)
if #errors > 0 then
	error("[Shop/Products] catálogo da loja com erros:\n" .. table.concat(errors, "\n"))
end

return Products
