--!strict
local Defs = require("../src/shared/Defs")
local Validate = require("../src/shared/Defs/Validate")

local function validTier(id: string, order: number): any
	return { id = id, order = order, color = "#8B5A2B", rarityKey = "rarity.common", nameKey = "tier." .. id }
end

local function validItem(id: string): any
	return { id = id, nameKey = "item." .. id, category = "resource", maxStack = 255 }
end

local function alwaysHas(_key: string): boolean
	return true
end

-- Defs falsas com cosméticos e expressões válidos; cada teste estraga um campo.
local function validLookDefs(): any
	return {
		Tiers = {},
		Items = {},
		CosmeticSlots = { body = { id = "body", nameKey = "cosmeticSlot.body", default = "body_default" } },
		Cosmetics = {
			body_default = {
				id = "body_default",
				nameKey = "cosmetic.body_default",
				slot = "body",
				body = { bodyColor = "#DDF3F8", outlineColor = "#1F6F7A" },
			},
		},
		Expressions = {
			neutral = { id = "neutral", priority = 0, eyes = "open", trigger = "always" },
			blink = {
				id = "blink",
				priority = 10,
				eyes = "closed",
				trigger = "periodic",
				duration = 0.12,
				intervalMin = 3,
				intervalMax = 6,
			},
		},
	}
end

-- Defs falsas só com estatísticas e configurações válidas; cada teste estraga um campo.
local function validDataDefs(): any
	return {
		Tiers = {},
		Items = {},
		Stats = {
			deaths = { id = "deaths", nameKey = "stat.deaths", kind = "counter" },
			mobs_killed = { id = "mobs_killed", nameKey = "stat.mobs_killed", kind = "keyed", keyKind = "mob" },
		},
		Settings = {
			music_volume = {
				id = "music_volume",
				nameKey = "setting.music_volume",
				kind = "number",
				default = 0.8,
				min = 0,
				max = 1,
			},
			quality = {
				id = "quality",
				nameKey = "setting.quality",
				kind = "choice",
				default = "auto",
				options = { "auto", "low" },
			},
			left_handed = { id = "left_handed", nameKey = "setting.left_handed", kind = "boolean", default = false },
		},
	}
end

-- Defs falsas só com itens e kits válidos; cada teste estraga um campo.
local function validKitDefs(): any
	return {
		Tiers = {},
		Items = {
			wood = validItem("wood"),
			leather_bag = {
				id = "leather_bag",
				nameKey = "item.leather_bag",
				category = "bag",
				maxStack = 1,
				bagSlots = 6,
			},
		},
		Kits = {
			kit_a = {
				id = "kit_a",
				nameKey = "kit.kit_a",
				order = 1,
				price = 1000,
				items = { { id = "wood", count = 20 }, { id = "leather_bag", count = 1 } },
			},
			kit_b = {
				id = "kit_b",
				nameKey = "kit.kit_b",
				order = 2,
				price = 0,
				items = { { id = "wood", count = 1 } },
			},
		},
	}
end

local function containsError(errors: { string }, fragment: string): boolean
	for _, message in errors do
		if string.find(message, fragment, 1, true) then
			return true
		end
	end
	return false
end

return {
	["real defs load and validate"] = function()
		assert(Defs.Tiers.gold.order == 3, `ordem do ouro: {Defs.Tiers.gold.order}`)
		assert(Defs.Tiers.gold.color == "#F2B632", `cor do ouro: {Defs.Tiers.gold.color}`)
		assert(Defs.Tiers.reidite.rarityKey == "rarity.legendary", "reidite deveria ser lendário")
		assert(Defs.Items.gold_pickaxe.tier == "gold", "picareta de ouro sem tier gold")
		assert(Defs.Items.wood.tier == nil, "madeira (recurso) não tem tier")
	end,

	["valid fake defs give no errors"] = function()
		local errors = Validate.all({
			Tiers = { wood = validTier("wood", 1) },
			Items = { wood = validItem("wood") },
		}, alwaysHas)
		assert(#errors == 0, `erros inesperados: {table.concat(errors, "; ")}`)
	end,

	["unknown tier is an error"] = function()
		local item = validItem("cup")
		item.tier = "plastic"
		local errors = Validate.all({ Tiers = { wood = validTier("wood", 1) }, Items = { cup = item } }, alwaysHas)
		assert(containsError(errors, "plastic"), `faltou erro do tier: {table.concat(errors, "; ")}`)
	end,

	["id must equal key"] = function()
		local errors = Validate.all({ Tiers = {}, Items = { wood = validItem("Wood") } }, alwaysHas)
		assert(containsError(errors, "Wood"), `faltou erro de id: {table.concat(errors, "; ")}`)
	end,

	["id must be snake case"] = function()
		local errors = Validate.all({ Tiers = {}, Items = { ["Wood"] = validItem("Wood") } }, alwaysHas)
		assert(#errors > 0, "id com maiúscula deveria falhar")
	end,

	["maxStack must be at least 1"] = function()
		local item = validItem("wood")
		item.maxStack = 0
		local errors = Validate.all({ Tiers = {}, Items = { wood = item } }, alwaysHas)
		assert(containsError(errors, "maxStack"), `faltou erro de maxStack: {table.concat(errors, "; ")}`)
	end,

	["real bag has bag slots"] = function()
		local bag = Defs.Items.leather_bag
		assert(bag ~= nil and bag.category == "bag", "mochila de couro deveria existir")
		assert(bag.bagSlots == 6, `mochila de couro deveria dar 6 slots, deu {bag.bagSlots}`)
	end,

	["bag without bag slots is an error"] = function()
		local item = validItem("sack")
		item.category = "bag"
		item.maxStack = 1
		local errors = Validate.all({ Tiers = {}, Items = { sack = item } }, alwaysHas)
		assert(containsError(errors, "bagSlots"), `faltou erro de bagSlots: {table.concat(errors, "; ")}`)
	end,

	["bag slots only on bags"] = function()
		local item = validItem("wood")
		item.bagSlots = 4
		local errors = Validate.all({ Tiers = {}, Items = { wood = item } }, alwaysHas)
		assert(
			containsError(errors, "bagSlots"),
			`faltou erro de bagSlots fora de mochila: {table.concat(errors, "; ")}`
		)
	end,

	["bag slots cannot pass the slot limit"] = function()
		local item = validItem("huge_bag")
		item.category = "bag"
		item.maxStack = 1
		item.bagSlots = 99
		local errors = Validate.all({ Tiers = {}, Items = { huge_bag = item } }, alwaysHas)
		assert(containsError(errors, "bagSlots"), `faltou erro de limite: {table.concat(errors, "; ")}`)
	end,

	["missing string is an error"] = function()
		local errors = Validate.all({ Tiers = {}, Items = { wood = validItem("wood") } }, function(key)
			return key ~= "item.wood"
		end)
		assert(containsError(errors, "item.wood"), `faltou erro de texto: {table.concat(errors, "; ")}`)
	end,
	["item id longer than the network limit is an error"] = function()
		local id = string.rep("a", 33)
		local errors = Validate.all({ Tiers = {}, Items = { [id] = validItem(id) } }, alwaysHas)
		assert(
			containsError(errors, "mais de 32 caracteres"),
			`esperava erro de id longo: {table.concat(errors, "; ")}`
		)
	end,

	["maxStack above the network limit is an error"] = function()
		local item = validItem("wood")
		item.maxStack = 70000
		local errors = Validate.all({ Tiers = {}, Items = { wood = item } }, alwaysHas)
		assert(
			containsError(errors, "maxStack deve ser inteiro entre 1 e 65535"),
			`esperava erro de maxStack: {table.concat(errors, "; ")}`
		)
	end,

	["real cosmetics and expressions load"] = function()
		assert(Defs.CosmeticSlots.body.default == "body_default", "padrão do slot body")
		local ember = Defs.Cosmetics.body_ember.body
		assert(ember ~= nil and ember.outlineColor == "#5F1802", "contorno da skin brasa")
		assert(Defs.Expressions.hurt.priority == 100, "prioridade do dano")
		assert(Defs.Expressions.blink.intervalMax == 6, "intervalo máximo do piscar")
	end,

	["valid fake look defs give no errors"] = function()
		local errors = Validate.all(validLookDefs(), alwaysHas)
		assert(#errors == 0, `erros inesperados: {table.concat(errors, "; ")}`)
	end,

	["cosmetic with unknown slot is an error"] = function()
		local defs = validLookDefs()
		defs.Cosmetics.hat_red = { id = "hat_red", nameKey = "cosmetic.hat_red", slot = "hat" }
		local errors = Validate.all(defs, alwaysHas)
		assert(
			containsError(errors, "não existe em CosmeticSlots"),
			`faltou erro de slot: {table.concat(errors, "; ")}`
		)
	end,

	["body cosmetic with bad color is an error"] = function()
		local defs = validLookDefs()
		defs.Cosmetics.body_default.body.bodyColor = "azul"
		local errors = Validate.all(defs, alwaysHas)
		assert(containsError(errors, "bodyColor"), `faltou erro de cor: {table.concat(errors, "; ")}`)
	end,

	["slot default must exist and match the slot"] = function()
		local defs = validLookDefs()
		defs.CosmeticSlots.body.default = "body_missing"
		local errors = Validate.all(defs, alwaysHas)
		assert(containsError(errors, "default"), `faltou erro de padrão: {table.concat(errors, "; ")}`)
	end,

	["expression with unknown eye style is an error"] = function()
		local defs = validLookDefs()
		defs.Expressions.blink.eyes = "wink"
		local errors = Validate.all(defs, alwaysHas)
		assert(containsError(errors, "eyes"), `faltou erro de olho: {table.concat(errors, "; ")}`)
	end,

	["periodic expression needs a valid interval"] = function()
		local defs = validLookDefs()
		defs.Expressions.blink.intervalMin = 5
		defs.Expressions.blink.intervalMax = 2
		local errors = Validate.all(defs, alwaysHas)
		assert(containsError(errors, "intervalMax"), `faltou erro de intervalo: {table.concat(errors, "; ")}`)
	end,

	["flash only on event expressions"] = function()
		local defs = validLookDefs()
		defs.Expressions.blink.flash = { color = "#E5484D", duration = 0.1 }
		local errors = Validate.all(defs, alwaysHas)
		assert(containsError(errors, "flash só vale"), `faltou erro de flash: {table.concat(errors, "; ")}`)
	end,

	["event must be a known event"] = function()
		local defs = validLookDefs()
		defs.Expressions.sneeze = {
			id = "sneeze",
			priority = 20,
			eyes = "closed",
			trigger = "event",
			event = "sneeze",
			duration = 0.3,
		}
		local errors = Validate.all(defs, alwaysHas)
		assert(containsError(errors, `event "sneeze"`), `faltou erro de evento: {table.concat(errors, "; ")}`)
	end,

	["known event with flash gives no errors"] = function()
		local defs = validLookDefs()
		defs.Expressions.hurt = {
			id = "hurt",
			priority = 100,
			eyes = "squeeze",
			trigger = "event",
			event = "hurt",
			duration = 0.5,
			flash = { color = "#E5484D", duration = 0.15 },
		}
		local errors = Validate.all(defs, alwaysHas)
		assert(#errors == 0, `erros inesperados: {table.concat(errors, "; ")}`)
	end,

	["exactly one always expression"] = function()
		local defs = validLookDefs()
		defs.Expressions.calm = { id = "calm", priority = 1, eyes = "open", trigger = "always" }
		local errors = Validate.all(defs, alwaysHas)
		assert(containsError(errors, "always"), `faltou erro de always: {table.concat(errors, "; ")}`)
	end,

	["real stats and settings load"] = function()
		assert(Defs.Stats.mobs_killed.kind == "keyed", "mobs_killed deveria ser keyed")
		assert(Defs.Stats.mobs_killed.keyKind == "mob", "mobs_killed deveria ter chave de mob")
		assert(Defs.Stats.score_best.kind == "max", "score_best deveria ser max")
		assert(Defs.Settings.quality.default == "auto", "qualidade padrão deveria ser auto")
		assert(Defs.Settings.ui_scale.max == 1.25, "ui_scale máximo deveria ser 1.25")
	end,

	["valid fake data defs give no errors"] = function()
		local errors = Validate.all(validDataDefs(), alwaysHas)
		assert(#errors == 0, `erros inesperados: {table.concat(errors, "; ")}`)
	end,

	["keyed stat without keyKind is an error"] = function()
		local defs = validDataDefs()
		defs.Stats.mobs_killed.keyKind = nil
		local errors = Validate.all(defs, alwaysHas)
		assert(containsError(errors, "keyKind"), `faltou erro de keyKind: {table.concat(errors, "; ")}`)
	end,

	["counter stat with keyKind is an error"] = function()
		local defs = validDataDefs()
		defs.Stats.deaths.keyKind = "item"
		local errors = Validate.all(defs, alwaysHas)
		assert(containsError(errors, "keyKind"), `faltou erro de keyKind: {table.concat(errors, "; ")}`)
	end,

	["number setting default out of range is an error"] = function()
		local defs = validDataDefs()
		defs.Settings.music_volume.default = 2
		local errors = Validate.all(defs, alwaysHas)
		assert(containsError(errors, "default"), `faltou erro de default: {table.concat(errors, "; ")}`)
	end,

	["choice setting default must be an option"] = function()
		local defs = validDataDefs()
		defs.Settings.quality.default = "ultra"
		local errors = Validate.all(defs, alwaysHas)
		assert(containsError(errors, "default"), `faltou erro de default: {table.concat(errors, "; ")}`)
	end,

	["choice option longer than the network limit is an error"] = function()
		local defs = validDataDefs()
		local long = string.rep("a", 17)
		defs.Settings.quality.options = { "auto", long }
		local errors = Validate.all(defs, alwaysHas)
		assert(
			containsError(errors, "de 1 a 16 caracteres"),
			`faltou erro de opção longa: {table.concat(errors, "; ")}`
		)
	end,

	["choice option at the network limit is ok"] = function()
		local defs = validDataDefs()
		defs.Settings.quality.options = { "auto", string.rep("a", 16) }
		local errors = Validate.all(defs, alwaysHas)
		assert(#errors == 0, `erros inesperados: {table.concat(errors, "; ")}`)
	end,

	["real kits load"] = function()
		local kit = Defs.Kits.kit_survivor
		assert(kit.price == 4000, `preço do kit_survivor: {kit.price}`)
		local hasBag = false
		for _, item in kit.items do
			if item.id == "leather_bag" then
				hasBag = true
			end
		end
		assert(hasBag, "kit_survivor deveria ter leather_bag")
	end,

	["valid fake kits give no errors"] = function()
		local errors = Validate.all(validKitDefs(), alwaysHas)
		assert(#errors == 0, `erros inesperados: {table.concat(errors, "; ")}`)
	end,

	["kit with unknown item is an error"] = function()
		local defs = validKitDefs()
		defs.Kits.kit_b.items = { { id = "plastic", count = 1 } }
		local errors = Validate.all(defs, alwaysHas)
		assert(containsError(errors, "plastic"), `faltou erro do item: {table.concat(errors, "; ")}`)
	end,

	["kit with two bags is an error"] = function()
		local defs = validKitDefs()
		defs.Kits.kit_a.items = { { id = "leather_bag", count = 1 }, { id = "leather_bag", count = 1 } }
		local errors = Validate.all(defs, alwaysHas)
		assert(containsError(errors, "mochila"), `faltou erro de mochila: {table.concat(errors, "; ")}`)
	end,

	["kit with a bag count above one is an error"] = function()
		local defs = validKitDefs()
		defs.Kits.kit_a.items = { { id = "leather_bag", count = 2 } }
		local errors = Validate.all(defs, alwaysHas)
		assert(containsError(errors, "mochila"), `faltou erro de mochila: {table.concat(errors, "; ")}`)
	end,

	["kits with repeated order is an error"] = function()
		local defs = validKitDefs()
		defs.Kits.kit_b.order = 1
		local errors = Validate.all(defs, alwaysHas)
		assert(containsError(errors, "order"), `faltou erro de order: {table.concat(errors, "; ")}`)
	end,

	["kit with invalid price or count is an error"] = function()
		local defs = validKitDefs()
		defs.Kits.kit_a.price = -1
		defs.Kits.kit_b.items = { { id = "wood", count = 1.5 } }
		local errors = Validate.all(defs, alwaysHas)
		assert(containsError(errors, "price"), `faltou erro de price: {table.concat(errors, "; ")}`)
		assert(containsError(errors, "count"), `faltou erro de count: {table.concat(errors, "; ")}`)
	end,

	["kit without items is an error"] = function()
		local defs = validKitDefs()
		defs.Kits.kit_b.items = {}
		local errors = Validate.all(defs, alwaysHas)
		assert(containsError(errors, "items"), `faltou erro de items: {table.concat(errors, "; ")}`)
	end,

	["boolean setting needs a boolean default"] = function()
		local defs = validDataDefs()
		defs.Settings.left_handed.default = "sim"
		local errors = Validate.all(defs, alwaysHas)
		assert(containsError(errors, "default"), `faltou erro de default: {table.concat(errors, "; ")}`)
	end,
}
