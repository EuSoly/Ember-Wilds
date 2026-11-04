--!strict
local BuildRules = require("../src/shared/Build/BuildRules")
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
				group = "sound",
				order = 1,
				kind = "number",
				default = 0.8,
				min = 0,
				max = 1,
			},
			quality = {
				id = "quality",
				nameKey = "setting.quality",
				group = "screen",
				order = 2,
				kind = "choice",
				default = "auto",
				options = { "auto", "low" },
			},
			left_handed = {
				id = "left_handed",
				nameKey = "setting.left_handed",
				group = "controls",
				order = 3,
				kind = "boolean",
				default = false,
			},
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

-- Defs falsas só com recursos e zonas válidos; cada teste estraga um campo.
local function validWorldDefs(): any
	return {
		Tiers = {},
		Items = { wood = validItem("wood") },
		Resources = {
			tree = {
				id = "tree",
				nameKey = "resource.tree",
				radius = 5,
				collisionRadius = 1.2,
				variants = 3,
				gather = {
					item = "wood",
					points = 1,
					material = "wood",
					hardness = 0,
					amount = { min = 20, max = 80 },
					regen = { amount = 2, every = 10 },
				},
			},
		},
		ResourceZones = {
			forest_dense = { id = "forest_dense", nameKey = "zone.forest_dense", densities = { tree = 14 } },
		},
	}
end

local function validRecipeDefs(): any
	return {
		Tiers = {},
		Items = { wood = validItem("wood"), paper = validItem("paper") },
		Recipes = {
			paper = {
				id = "paper",
				result = "paper",
				count = 1,
				ingredients = { { id = "wood", count = 20 } },
				time = 5,
				station = "fire",
				order = 1,
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

	["recipes match the design"] = function()
		local stonePickaxe = Defs.Recipes.stone_pickaxe
		assert(
			stonePickaxe.result == "stone_pickaxe" and stonePickaxe.count == 1 and stonePickaxe.time == 15,
			"picareta de pedra confere"
		)
		assert(
			stonePickaxe.station == "workbench" and #stonePickaxe.ingredients == 3,
			"picareta de pedra usa bancada e três ingredientes"
		)
		local spike = Defs.Recipes.gold_spike
		assert(spike.time == 20 and spike.station == "workbench", "espinho de ouro confere")
		local paper = Defs.Recipes.paper
		assert(paper.station == "fire" and paper.time == 5, "papel exige fogo e leva cinco segundos")
		local book = Defs.Recipes.book
		assert(
			book.time == 30 and book.station == "workbench" and Defs.Items.book.craftSpeed == 3,
			"livro provisório confere"
		)
		assert(
			#book.ingredients == 2 and book.ingredients[1].id == "paper" and book.ingredients[2].id == "gold",
			"livro provisório usa papel e ouro"
		)
		local workbench = Defs.Recipes.workbench
		assert(workbench.station == nil and workbench.time == 10, "bancada é craftada sem estação em dez segundos")
		assert(
			#workbench.ingredients == 2
				and workbench.ingredients[1].id == "wood"
				and workbench.ingredients[1].count == 30
				and workbench.ingredients[2].id == "stone"
				and workbench.ingredients[2].count == 10,
			"bancada exige 30 madeiras e 10 pedras"
		)
		local stoneWall = Defs.Recipes.stone_wall
		assert(
			#stoneWall.ingredients == 1 and stoneWall.ingredients[1].id == "stone",
			"parede de pedra exige só pedra"
		)
	end,

	["every recipe result and ingredient exists"] = function()
		for id, recipe in Defs.Recipes do
			assert(Defs.Items[recipe.result] ~= nil, `{id} resultado ausente`)
			for _, part in recipe.ingredients do
				assert(Defs.Items[part.id] ~= nil, `{id} ingrediente {part.id} ausente`)
			end
		end
	end,

	["recipe with unknown item is an error"] = function()
		local defs = validRecipeDefs()
		defs.Recipes.paper.result = "unknown"
		defs.Recipes.paper.ingredients[1].id = "missing"
		local errors = Validate.all(defs, alwaysHas)
		assert(containsError(errors, "unknown"))
		assert(containsError(errors, "missing"))
	end,

	["recipe with bad numbers is an error"] = function()
		local cases = {
			function(defs)
				defs.Recipes.paper.count = 0
			end,
			function(defs)
				defs.Recipes.paper.time = 0
			end,
			function(defs)
				defs.Recipes.paper.ingredients[1].count = 1.5
			end,
			function(defs)
				defs.Recipes.paper.station = "forge"
			end,
			function(defs)
				defs.Recipes.other = table.clone(defs.Recipes.paper)
				defs.Recipes.other.id = "other"
				defs.Recipes.other.order = 1
			end,
		}
		for index, spoil in cases do
			local defs = validRecipeDefs()
			spoil(defs)
			local errors = Validate.all(defs, alwaysHas)
			assert(containsError(errors, "Recipe"), `caso {index} sem erro: {table.concat(errors, "; ")}`)
		end
	end,

	["craft speed only on misc and above 1"] = function()
		for _, setup in
			{
				function(item)
					item.craftSpeed = 1
				end,
				function(item)
					item.category = "resource"
					item.craftSpeed = 3
				end,
			}
		do
			local item = validItem("wood")
			setup(item)
			local errors = Validate.all({ Tiers = {}, Items = { wood = item } }, alwaysHas)
			assert(containsError(errors, "craftSpeed"))
		end
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

	["berry restores hunger"] = function()
		local food = Defs.Items.berry.food
		assert(food ~= nil and food.hunger == 10, "frutinha repõe 10 de fome")
	end,

	["food item without food effect is an error"] = function()
		local item = validItem("apple")
		item.category = "food"
		local errors = Validate.all({ Tiers = {}, Items = { apple = item } }, alwaysHas)
		assert(containsError(errors, "food"), `faltou erro de food: {table.concat(errors, "; ")}`)
	end,

	["food effect only on food"] = function()
		local item = validItem("wood")
		item.food = { hunger = 5 }
		local errors = Validate.all({ Tiers = {}, Items = { wood = item } }, alwaysHas)
		assert(containsError(errors, "food"), `faltou erro de food fora de comida: {table.concat(errors, "; ")}`)
	end,

	["food effect out of range is an error"] = function()
		for _, effect in { { hunger = 0 }, { hunger = 150 }, {}, { thirst = 0 / 0 } } do
			local item = validItem("apple")
			item.category = "food"
			item.food = effect
			local errors = Validate.all({ Tiers = {}, Items = { apple = item } }, alwaysHas)
			assert(containsError(errors, "food"), `faltou erro de food inválido: {table.concat(errors, "; ")}`)
		end
	end,

	["armor item without armor stats is an error"] = function()
		local item = validItem("helmet")
		item.category = "armor"
		item.maxStack = 1
		local errors = Validate.all({ Tiers = {}, Items = { helmet = item } }, alwaysHas)
		assert(containsError(errors, "armor"), `faltou erro de armor: {table.concat(errors, "; ")}`)
	end,

	["armor stats only on armor"] = function()
		local item = validItem("wood")
		item.armor = { defense = 0.2 }
		local errors = Validate.all({ Tiers = {}, Items = { wood = item } }, alwaysHas)
		assert(containsError(errors, "armor"), `faltou erro de armor fora de armadura: {table.concat(errors, "; ")}`)
	end,

	["armor stats out of range is an error"] = function()
		local cases = {
			{ stats = { defense = 0.95 }, field = "defense" },
			{ stats = { coldFactor = 3 }, field = "coldFactor" },
			{ stats = { coldFactor = -1 }, field = "coldFactor" },
			{ stats = { hungerFactor = 0 / 0 }, field = "hungerFactor" },
			{ stats = { thirstFactor = 2.5 }, field = "thirstFactor" },
			{ stats = { heatFactor = 3 }, field = "heatFactor" },
		}
		for _, case in cases do
			local item = validItem("helmet")
			item.category = "armor"
			item.maxStack = 1
			item.armor = case.stats
			local errors = Validate.all({ Tiers = {}, Items = { helmet = item } }, alwaysHas)
			assert(containsError(errors, case.field), `faltou erro de {case.field}: {table.concat(errors, "; ")}`)
		end
	end,

	["valid armor passes"] = function()
		local item = validItem("helmet")
		item.category = "armor"
		item.maxStack = 1
		item.armor = { defense = 0.25, coldFactor = 0.5 }
		local errors = Validate.all({ Tiers = {}, Items = { helmet = item } }, alwaysHas)
		assert(#errors == 0, `armadura válida deu erro: {table.concat(errors, "; ")}`)
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

	["kit with a testOnly item is an error"] = function()
		local defs = validKitDefs()
		defs.Items.secret =
			{ id = "secret", nameKey = "item.secret", category = "resource", maxStack = 255, testOnly = true }
		defs.Kits.kit_b.items = { { id = "secret", count = 1 } }
		local errors = Validate.all(defs, alwaysHas)
		assert(containsError(errors, "testOnly"), `faltou erro de testOnly: {table.concat(errors, "; ")}`)
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
		assert(containsError(errors, "count de"), `faltou erro de count: {table.concat(errors, "; ")}`)
	end,

	["kit that does not fit a new inventory is an error"] = function()
		local defs = validKitDefs()
		-- Sem mochila: 10 slots (BASE_SLOTS). 11 pilhas cheias de madeira não cabem.
		defs.Kits.kit_b.items = { { id = "wood", count = 255 * 11 } }
		local errors = Validate.all(defs, alwaysHas)
		assert(containsError(errors, "não cabe"), `faltou erro de espaço: {table.concat(errors, "; ")}`)
	end,

	["kit bag slots count for the fit"] = function()
		local defs = validKitDefs()
		-- Com a mochila do próprio kit (6 slots): 16 pilhas cabem, 17 não.
		defs.Kits.kit_a.items = { { id = "wood", count = 255 * 16 }, { id = "leather_bag", count = 1 } }
		local errors = Validate.all(defs, alwaysHas)
		assert(#errors == 0, `16 pilhas deveriam caber: {table.concat(errors, "; ")}`)
		defs.Kits.kit_a.items = { { id = "wood", count = 255 * 16 + 1 }, { id = "leather_bag", count = 1 } }
		errors = Validate.all(defs, alwaysHas)
		assert(containsError(errors, "não cabe"), `faltou erro de espaço: {table.concat(errors, "; ")}`)
	end,

	["kit with the same item twice sums the slots"] = function()
		local defs = validKitDefs()
		defs.Kits.kit_b.items = { { id = "wood", count = 255 * 6 }, { id = "wood", count = 255 * 5 } }
		local errors = Validate.all(defs, alwaysHas)
		assert(containsError(errors, "não cabe"), `faltou erro de espaço: {table.concat(errors, "; ")}`)
	end,

	["kit without items is an error"] = function()
		local defs = validKitDefs()
		defs.Kits.kit_b.items = {}
		local errors = Validate.all(defs, alwaysHas)
		assert(containsError(errors, "items"), `faltou erro de items: {table.concat(errors, "; ")}`)
	end,

	["setting with an unknown group is an error"] = function()
		local defs = validDataDefs()
		defs.Settings.quality.group = "audio"
		local errors = Validate.all(defs, alwaysHas)
		assert(containsError(errors, `Setting "quality": group`), `faltou erro de group: {table.concat(errors, "; ")}`)
	end,

	["settings with repeated order is an error"] = function()
		local defs = validDataDefs()
		defs.Settings.left_handed.order = 1
		local errors = Validate.all(defs, alwaysHas)
		assert(containsError(errors, "order"), `faltou erro de order: {table.concat(errors, "; ")}`)
	end,

	["setting without a whole order is an error"] = function()
		local defs = validDataDefs()
		defs.Settings.quality.order = nil
		defs.Settings.left_handed.order = 2.5
		local errors = Validate.all(defs, alwaysHas)
		assert(
			containsError(errors, `Setting "quality": order`),
			`faltou erro de quality: {table.concat(errors, "; ")}`
		)
		assert(
			containsError(errors, `Setting "left_handed": order`),
			`faltou erro de left_handed: {table.concat(errors, "; ")}`
		)
	end,

	["real resources and zones load"] = function()
		local tree = Defs.Resources.tree
		assert(tree ~= nil and tree.radius == 5 and tree.collisionRadius == 1.4, "árvore real")
		assert(Defs.Resources.gold_vein.variants == 1, "variações da jazida de ouro")
		assert(Defs.Resources.pebble.decorative == true, "pedra do chão é enfeite")
		assert(
			Defs.Resources.tree.size == 14 and Defs.Resources.tree.sizeAxis == "height",
			"árvore medida pela altura"
		)
		assert(Defs.Resources.pebble.sink == 0.5, "pedra do chão meio enterrada")
		assert(Defs.ResourceZones.forest_dense.densities.tree == 14, "densidade de árvores na floresta densa")
		assert(Defs.ResourceZones.forest_open.densities.gold_vein == 0.3, "ouro na floresta aberta")
	end,

	["valid fake world defs give no errors"] = function()
		local errors = Validate.all(validWorldDefs(), alwaysHas)
		assert(#errors == 0, `erros inesperados: {table.concat(errors, "; ")}`)
	end,

	["gather numbers match the design"] = function()
		local function expectGather(
			id: string,
			item: string,
			points: number,
			material: string,
			minA: number,
			maxA: number,
			regenA: number,
			every: number
		)
			local g = Defs.Resources[id].gather
			assert(g ~= nil, `{id} sem gather`)
			assert(g.item == item and g.points == points and g.material == material, `{id}: item/pontos/material`)
			assert(g.amount.min == minA and g.amount.max == maxA, `{id}: reserva {g.amount.min}-{g.amount.max}`)
			assert(g.regen.amount == regenA and g.regen.every == every, `{id}: regeneração`)
		end
		expectGather("tree", "wood", 1, "wood", 20, 80, 2, 10)
		expectGather("rock", "stone", 2, "stone", 40, 40, 2, 10)
		expectGather("gold_vein", "gold", 3, "gold", 20, 20, 1, 10)
		expectGather("berry_bush", "berry", 2, "leaves", 7, 7, 1, 10)
		assert(Defs.Resources.tree.gather.hardness == 0, "árvore dureza 0")
		assert(Defs.Resources.rock.gather.hardness == 1, "rocha dureza 1")
		assert(Defs.Resources.gold_vein.gather.hardness == 2, "ouro dureza 2")
		assert(Defs.Resources.berry_bush.gather.fixedYield == 1, "frutinha rende 1")
		assert(Defs.Resources.pebble.gather == nil, "pedra do chão não coleta")
		assert(Defs.Items.wood_pickaxe.pickaxe.level == 1, "picareta de madeira nível 1")
		assert(Defs.Items.stone_pickaxe.pickaxe.level == 2, "picareta de pedra nível 2")
		assert(Defs.Items.gold_pickaxe.pickaxe.level == 3, "picareta de ouro nível 3")
	end,

	["resource without gather is an error"] = function()
		local defs = validWorldDefs()
		defs.Resources.tree.gather = nil
		local errors = Validate.all(defs, alwaysHas)
		assert(containsError(errors, "gather"), `faltou erro de gather: {table.concat(errors, "; ")}`)
	end,

	["decorative with gather is an error"] = function()
		local defs = validWorldDefs()
		defs.Resources.tree.decorative = true
		local errors = Validate.all(defs, alwaysHas)
		assert(containsError(errors, "gather"), `faltou erro de gather em enfeite: {table.concat(errors, "; ")}`)
	end,

	["gather needs hardness or fixed yield"] = function()
		local none = validWorldDefs()
		none.Resources.tree.gather.hardness = nil
		assert(containsError(Validate.all(none, alwaysHas), "hardness"), "sem dureza nem fixo")
		local both = validWorldDefs()
		both.Resources.tree.gather.fixedYield = 1
		assert(containsError(Validate.all(both, alwaysHas), "hardness"), "dureza e fixo juntos")
	end,

	["gather item must exist"] = function()
		local defs = validWorldDefs()
		defs.Resources.tree.gather.item = "unobtainium"
		local errors = Validate.all(defs, alwaysHas)
		assert(containsError(errors, "unobtainium"), `faltou erro do item: {table.concat(errors, "; ")}`)
	end,

	["gather amounts must be valid"] = function()
		local cases: { (any) -> () } = {
			function(g)
				g.amount.min = 0
			end,
			function(g)
				g.amount.max = 10
			end,
			function(g)
				g.regen.every = 0
			end,
			function(g)
				g.regen.amount = 0
			end,
			function(g)
				g.material = "lava"
			end,
			function(g)
				g.points = -1
			end,
		}
		for i, spoil in cases do
			local defs = validWorldDefs()
			spoil(defs.Resources.tree.gather)
			local errors = Validate.all(defs, alwaysHas)
			assert(containsError(errors, "gather"), `caso {i} sem erro: {table.concat(errors, "; ")}`)
		end
	end,

	["pickaxe only on tools"] = function()
		local item = validItem("wood")
		item.pickaxe = { level = 1 }
		local errors = Validate.all({ Tiers = {}, Items = { wood = item } }, alwaysHas)
		assert(containsError(errors, "pickaxe"), `faltou erro de pickaxe: {table.concat(errors, "; ")}`)
	end,

	["pickaxe level must be a positive integer"] = function()
		for _, level in { 0, 1.5, -2 } do
			local item = validItem("pick")
			item.category = "tool"
			item.maxStack = 1
			item.pickaxe = { level = level }
			local errors = Validate.all({ Tiers = {}, Items = { pick = item } }, alwaysHas)
			assert(containsError(errors, "pickaxe"), `nível {level} sem erro: {table.concat(errors, "; ")}`)
		end
	end,

	["structures match the design"] = function()
		local I = Defs.Items
		local function s(id: string): any
			local item = I[id]
			assert(item ~= nil and item.structure ~= nil, `{id} deveria ter structure`)
			return item.structure
		end
		assert(s("stone_wall").kind == "wall" and s("stone_wall").health == 1500, "parede de pedra 1500")
		assert(s("wood_wall").health == 1000 and s("gold_wall").health == 2000, "vida das paredes")
		assert(
			s("wood_door").kind == "door" and s("stone_door").health == 1500 and s("gold_door").health == 2000,
			"portas"
		)
		assert(s("gold_spike").health == 600 and s("gold_spike").spikeDamage == 30, "espinho de ouro 600/30")
		assert(s("wood_spike").health == 150 and s("wood_spike").spikeDamage == 10, "espinho de madeira")
		assert(s("stone_spike").health == 300 and s("stone_spike").spikeDamage == 20, "espinho de pedra")
		assert(s("campfire").kind == "fire" and s("campfire").health == 150, "fogueira 150")
		assert(s("campfire").lifetime == 120 and s("campfire").heatRadius == 12, "fogueira 120 s e raio 12")
		assert(s("campfire").station == "fire", "estação da fogueira")
		assert(s("big_campfire").lifetime == 360 and s("big_campfire").health == 300, "fogueira grande 360 s")
		assert(s("big_campfire").heatRadius == 18 and s("big_campfire").station == "fire", "fogueira grande")
		assert(s("workbench").kind == "station" and s("workbench").station == "workbench", "bancada")
		assert(s("workbench").health == 300, "vida da bancada")
		assert(s("chest").kind == "chest" and s("chest").health == 500, "baú 500")
		local damages = { wood = 10, stone = 15, gold = 20, diamond = 25, amethyst = 30, reidite = 35 }
		for tier, damage in damages do
			assert(I[tier .. "_pickaxe"].structureDamage == damage, `picareta {tier}`)
		end
		assert(I.wood_sword.structureDamage == 5 and I.stone_spear.structureDamage == 7.5, "dano de madeira e pedra")
		assert(I.gold_sword.structureDamage == 10 and I.gold_spear.structureDamage == 10, "dano de ouro")
	end,

	["every placeable has a structure"] = function()
		for id, item in Defs.Items do
			assert((item.category == "placeable") == (item.structure ~= nil), `{id}: structure só em placeable`)
		end
	end,

	["structure only on placeable"] = function()
		local item = validItem("wood")
		item.structure = { kind = "wall", health = 100 }
		local errors = Validate.all({ Tiers = {}, Items = { wood = item } }, alwaysHas)
		assert(containsError(errors, "structure"), `faltou erro de structure: {table.concat(errors, "; ")}`)
		item.category = "placeable"
		item.structure = nil
		errors = Validate.all({ Tiers = {}, Items = { wood = item } }, alwaysHas)
		assert(containsError(errors, "structure"), `placeable sem structure: {table.concat(errors, "; ")}`)
	end,

	["structure with bad numbers is an error"] = function()
		for index, structure in
			{
				{ kind = "wall", health = 0 },
				{ kind = "spike", health = 100 },
				{ kind = "fire", health = 100, heatRadius = 12 },
				{ kind = "fire", health = 100, lifetime = 60 },
				{ kind = "wall", health = 100, radius = 0 },
				{ kind = "wall", health = 100, radius = -1 },
				{ kind = "wall", health = 100, radius = 0 / 0 },
				{ kind = "station", health = 100, station = "forge" },
				{ kind = "tower", health = 100 },
			}
		do
			local item = validItem("wall")
			item.category = "placeable"
			item.structure = structure
			local errors = Validate.all({ Tiers = {}, Items = { wall = item } }, alwaysHas)
			assert(containsError(errors, "structure"), `caso {index} sem erro: {table.concat(errors, "; ")}`)
		end
	end,

	["structure radius above what fits next to the builder is an error"] = function()
		local limit = BuildRules.PLACE_DISTANCE - BuildRules.PLAYER_RADIUS
		for _, case in { { limit, false }, { limit + 0.01, true } } do
			local item = validItem("wall")
			item.category = "placeable"
			item.structure = { kind = "wall", health = 100, radius = case[1] }
			local errors = Validate.all({ Tiers = {}, Items = { wall = item } }, alwaysHas)
			assert(
				containsError(errors, "structure.radius") == case[2],
				`radius {case[1]} (limite {limit}): {table.concat(errors, "; ")}`
			)
		end
	end,

	["structure damage must be positive"] = function()
		for index, damage in { 0, -5, 0 / 0 } do
			local item = validItem("pick")
			item.structureDamage = damage
			local errors = Validate.all({ Tiers = {}, Items = { pick = item } }, alwaysHas)
			assert(containsError(errors, "structureDamage"), `caso {index} sem erro: {table.concat(errors, "; ")}`)
		end
	end,

	["attack animation must be swing or thrust"] = function()
		local item: any = validItem("pick")
		item.attackAnim = "spin"
		local errors = Validate.all({ Tiers = {}, Items = { pick = item } }, alwaysHas)
		assert(containsError(errors, "attackAnim"), `sem erro: {table.concat(errors, "; ")}`)
		item.attackAnim = "thrust"
		errors = Validate.all({ Tiers = {}, Items = { pick = item } }, alwaysHas)
		assert(not containsError(errors, "attackAnim"), `thrust é válido: {table.concat(errors, "; ")}`)
	end,

	["zone with unknown resource is an error"] = function()
		local defs = validWorldDefs()
		defs.ResourceZones.forest_dense.densities.cactus = 3
		local errors = Validate.all(defs, alwaysHas)
		assert(containsError(errors, "cactus"), `faltou erro do recurso: {table.concat(errors, "; ")}`)
	end,

	["collision radius above radius is an error"] = function()
		local defs = validWorldDefs()
		defs.Resources.tree.collisionRadius = 6
		local errors = Validate.all(defs, alwaysHas)
		assert(containsError(errors, "collisionRadius"), `faltou erro de colisão: {table.concat(errors, "; ")}`)
	end,

	["resource with bad radius or variants is an error"] = function()
		local defs = validWorldDefs()
		defs.Resources.tree.radius = 0
		defs.Resources.tree.variants = 1.5
		local errors = Validate.all(defs, alwaysHas)
		assert(containsError(errors, "radius"), `faltou erro de radius: {table.concat(errors, "; ")}`)
		assert(containsError(errors, "variants"), `faltou erro de variants: {table.concat(errors, "; ")}`)
	end,

	["resource with bad size or jitter is an error"] = function()
		local defs = validWorldDefs()
		defs.Resources.tree.size = 0
		defs.Resources.tree.sizeJitter = 0.7
		local errors = Validate.all(defs, alwaysHas)
		assert(containsError(errors, "size deve"), `faltou erro de size: {table.concat(errors, "; ")}`)
		assert(containsError(errors, "sizeJitter"), `faltou erro de sizeJitter: {table.concat(errors, "; ")}`)
	end,

	["resource with bad size axis or sink is an error"] = function()
		local defs = validWorldDefs()
		defs.Resources.tree.sizeAxis = "depth"
		defs.Resources.tree.sink = 1.5
		local errors = Validate.all(defs, alwaysHas)
		assert(containsError(errors, "sizeAxis"), `faltou erro de sizeAxis: {table.concat(errors, "; ")}`)
		assert(containsError(errors, "sink"), `faltou erro de sink: {table.concat(errors, "; ")}`)
	end,

	["zone with empty or negative densities is an error"] = function()
		local defs = validWorldDefs()
		defs.ResourceZones.forest_dense.densities = {}
		local errors = Validate.all(defs, alwaysHas)
		assert(containsError(errors, "densities"), `faltou erro de vazio: {table.concat(errors, "; ")}`)
		defs.ResourceZones.forest_dense.densities = { tree = -1 }
		errors = Validate.all(defs, alwaysHas)
		assert(containsError(errors, "densidade"), `faltou erro de negativo: {table.concat(errors, "; ")}`)
	end,

	["boolean setting needs a boolean default"] = function()
		local defs = validDataDefs()
		defs.Settings.left_handed.default = "sim"
		local errors = Validate.all(defs, alwaysHas)
		assert(containsError(errors, "default"), `faltou erro de default: {table.concat(errors, "; ")}`)
	end,

	["mobs follow the wiki behaviors"] = function()
		-- Wiki de fãs do Starve.io (01/11): 2 passivos e 7 neutros; o resto ataca.
		local expected = {
			rabbit = "passive",
			penguin = "passive",
			hawk = "neutral",
			boar = "neutral",
			crab = "neutral",
			king_crab = "neutral",
			baby_mammoth = "neutral",
			baby_dragon = "neutral",
			baby_lava_dragon = "neutral",
			wolf = "aggressive",
			spider = "aggressive",
			mammoth = "aggressive",
			kraken = "aggressive",
			sandworm = "aggressive",
		}
		for id, behavior in expected do
			assert(Defs.Mobs[id].behavior == behavior, `{id} deveria ser {behavior}`)
		end
	end,

	["unknown mob behavior is an error"] = function()
		local defs: any = {
			Tiers = {},
			Items = {},
			Mobs = { wolf = { id = "wolf", nameKey = "mob.wolf", behavior = "angry" } },
		}
		local errors = Validate.all(defs, alwaysHas)
		assert(containsError(errors, "behavior"), `faltou erro de behavior: {table.concat(errors, "; ")}`)
	end,
	["forest mobs have stats and population, the others do not"] = function()
		local forest = { rabbit = true, wolf = true, spider = true, boar = true, hawk = true }
		for id, mob in Defs.Mobs do
			if forest[id] then
				assert(mob.stats ~= nil, `{id} deveria ter stats`)
				assert(mob.population ~= nil and mob.population.forest ~= nil, `{id} deveria ter população forest`)
			else
				assert(mob.stats == nil and mob.population == nil, `{id} não deveria ter stats nem população`)
			end
		end
		assert(Defs.Mobs.spider.stats.web.duration == 2, "teia da aranha")
		assert(Defs.Mobs.hawk.stats.flies == true, "falcão voa")
		for _, id in { "hawk", "boar", "baby_dragon", "baby_lava_dragon" } do
			assert(Defs.Mobs[id].mountFlies == true, `{id} deveria ter mountFlies`)
		end
	end,

	["forest mobs drop the expected loot, the others none"] = function()
		local expected = {
			rabbit = { { id = "raw_meat", count = 1 }, { id = "rabbit_fur", count = 1 } },
			wolf = { { id = "raw_meat", count = 2 }, { id = "wolf_fur", count = 1 } },
			spider = { { id = "thread", count = 2 } },
			boar = { { id = "raw_meat", count = 4 }, { id = "boar_fur", count = 1 } },
			hawk = { { id = "raw_meat", count = 2 }, { id = "hawk_feather", count = 4 } },
		}
		for id, mob in Defs.Mobs do
			local want = expected[id]
			if want == nil then
				assert(mob.loot == nil, `{id} não deveria ter loot`)
			else
				assert(mob.loot ~= nil and #mob.loot == #want, `{id} loot com tamanho errado`)
				for index, entry in want do
					assert(mob.loot[index].id == entry.id, `{id} loot[{index}] id`)
					assert(mob.loot[index].count == entry.count, `{id} loot[{index}] count`)
				end
			end
		end
	end,

	["invalid mob loot is an error"] = function()
		local function check(label: string, loot: any)
			local defs: any = {
				Tiers = {},
				Items = {
					raw_meat = { id = "raw_meat", nameKey = "item.raw_meat", category = "resource", maxStack = 255 },
				},
				Mobs = { wolf = { id = "wolf", nameKey = "mob.wolf", behavior = "aggressive", loot = loot } },
			}
			local errors = Validate.all(defs, alwaysHas)
			assert(containsError(errors, "loot"), `{label}: faltou erro de loot: {table.concat(errors, "; ")}`)
		end
		check("item inexistente", { { id = "missing", count = 1 } })
		check("contagem fracionária", { { id = "raw_meat", count = 1.5 } })
		check("contagem zero", { { id = "raw_meat", count = 0 } })
		check("contagem negativa", { { id = "raw_meat", count = -1 } })
	end,

	["mob loot with a testOnly item is an error"] = function()
		local defs: any = {
			Tiers = {},
			Items = {
				secret = {
					id = "secret",
					nameKey = "item.secret",
					category = "resource",
					maxStack = 255,
					testOnly = true,
				},
			},
			Mobs = {
				wolf = {
					id = "wolf",
					nameKey = "mob.wolf",
					behavior = "aggressive",
					loot = { { id = "secret", count = 1 } },
				},
			},
		}
		local errors = Validate.all(defs, alwaysHas)
		assert(containsError(errors, "testOnly"), `faltou erro de testOnly: {table.concat(errors, "; ")}`)
	end,

	["meat items, cooked meat recipe and crate skin exist"] = function()
		assert(Defs.Items.raw_meat.food.hunger == 15, "carne crua")
		assert(Defs.Items.cooked_meat.food.hunger == 35, "carne assada")
		for _, id in { "raw_meat", "cooked_meat", "rabbit_fur", "wolf_fur", "boar_fur", "hawk_feather", "thread" } do
			assert(Defs.Items[id].maxStack == 255, `{id} maxStack`)
		end
		local cooked = Defs.Recipes.cooked_meat
		assert(cooked.station == "fire" and cooked.time == 3 and cooked.count == 1, "receita da carne assada")
		assert(#cooked.ingredients == 1 and cooked.ingredients[1].id == "raw_meat", "ingrediente da carne assada")
		assert(cooked.ingredients[1].count == 1, "1 carne crua")
		assert(Defs.CosmeticSlots.crate.default == "crate_default", "slot da caixa")
		assert(Defs.Cosmetics.crate_default.slot == "crate", "skin padrão da caixa")
	end,

	["invalid mob stats and population are errors"] = function()
		local function stats(change: (any) -> ()): any
			local s: any =
				{ health = 10, bite = 1, speed = 1, radius = 1, points = 0, web = { duration = 1, cooldown = 1 } }
			change(s)
			return s
		end
		local function check(label: string, mob: any, needle: string)
			mob.id, mob.nameKey, mob.behavior = "wolf", "mob.wolf", "aggressive"
			local defs: any = { Tiers = {}, Items = {}, Mobs = { wolf = mob } }
			local errors = Validate.all(defs, alwaysHas)
			assert(containsError(errors, needle), `{label}: faltou erro "{needle}": {table.concat(errors, "; ")}`)
		end
		local pop = { forest = { day = 1, night = 1 } }
		check("health", { stats = stats(function(s)
			s.health = 0
		end) }, "stats")
		check("speed", { stats = stats(function(s)
			s.speed = -1
		end) }, "stats")
		check("radius", { stats = stats(function(s)
			s.radius = 0
		end) }, "stats")
		check("bite", { stats = stats(function(s)
			s.bite = -1
		end) }, "bite")
		check("points", { stats = stats(function(s)
			s.points = -1
		end) }, "points")
		check("web duration", { stats = stats(function(s)
			s.web.duration = 0
		end) }, "web")
		check("web cooldown", { stats = stats(function(s)
			s.web.cooldown = 0
		end) }, "web")
		check("population sem stats", { population = pop }, "stats")
		check("bioma", { stats = stats(function() end), population = { moon = { day = 1, night = 1 } } }, "bioma")
		check(
			"negativa",
			{ stats = stats(function() end), population = { forest = { day = -1, night = 1 } } },
			"population"
		)
		check(
			"fracionária",
			{ stats = stats(function() end), population = { forest = { day = 1, night = 1.5 } } },
			"population"
		)
	end,

	["non-positive mobDamage is an error"] = function()
		local item = validItem("stick")
		item.mobDamage = 0
		local defs: any = { Tiers = {}, Items = { stick = item } }
		local errors = Validate.all(defs, alwaysHas)
		assert(containsError(errors, "mobDamage"), `faltou erro de mobDamage: {table.concat(errors, "; ")}`)
	end,

	["G8 new items exist, are testOnly and have the table recipes"] = function()
		local ids = {
			"wood_spike_door",
			"stone_spike_door",
			"gold_spike_door",
			"stone_extractor",
			"gold_extractor",
			"furnace",
			"bridge",
			"roof",
			"sign",
			"well",
			"bed",
			"bucket",
			"water_bucket",
		}
		for _, id in ids do
			local item = (Defs.Items :: any)[id]
			assert(item ~= nil and item.testOnly == true, `{id}: falta ou não é testOnly`)
			if id == "water_bucket" then
				assert(Defs.Recipes[id] == nil, "balde cheio não tem receita")
			else
				local recipe = Defs.Recipes[id]
				assert(recipe ~= nil and recipe.station == "workbench", `{id}: receita na bancada`)
			end
		end
		local function cost(id: string): { [string]: number }
			local out = {}
			for _, ing in Defs.Recipes[id].ingredients do
				out[ing.id] = ing.count
			end
			return out
		end
		local bed = cost("bed")
		assert(
			bed.wood == 100 and bed.stone == 50 and bed.wolf_fur == 5 and bed.rabbit_fur == 5 and bed.thread == 6,
			"cama"
		)
		assert(cost("stone_extractor").wood == 200 and cost("stone_extractor").stone == 50, "extrator de pedra")
		assert(cost("gold_extractor").wood == 200 and cost("gold_extractor").gold == 30, "extrator de ouro")
		assert(cost("furnace").stone == 100 and cost("furnace").gold == 30, "fornalha")
		assert(cost("bridge").wood == 30 and cost("roof").wood == 25 and cost("sign").wood == 20, "madeira")
		assert(cost("well").stone == 60 and cost("bucket").wood == 15, "poço e balde")
		assert(cost("stone_spike_door").stone_door == 1 and cost("stone_spike_door").stone_spike == 1, "porta espinhos")
		local items: any = Defs.Items
		assert(
			items.bucket.category == "misc" and items.bucket.maxStack == 1 and items.bucket.structure == nil,
			"balde"
		)
		assert(items.water_bucket.category == "misc" and items.water_bucket.maxStack == 1, "balde cheio")
	end,

	["G8 structure data matches the table"] = function()
		local items: any = Defs.Items
		local function s(id: string): any
			return items[id].structure
		end
		assert(s("wood_spike_door").kind == "spike_door" and s("wood_spike_door").health == 1000, "porta madeira")
		assert(s("stone_spike_door").health == 1500 and s("stone_spike_door").spikeDamage == 20, "porta pedra")
		assert(s("gold_spike_door").health == 2000 and s("gold_spike_door").spikeDamage == 30, "porta ouro")
		local ext = s("gold_extractor").extractor
		assert(s("gold_extractor").health == 300 and ext.output == "gold", "extrator de ouro")
		assert(ext.woodPerCycle == 2 and ext.cycleSeconds == 10 and ext.yield == 1, "ciclo")
		assert(ext.maxWood == 100 and ext.maxStock == 100, "limites do extrator")
		assert(s("stone_extractor").extractor.output == "stone", "extrator de pedra")
		local furnace = s("furnace")
		assert(furnace.heatRadius == 24 and furnace.station == "fire" and furnace.health == 500, "fornalha")
		assert(furnace.lifetime == nil and furnace.furnace.burnEvery == 6 and furnace.furnace.maxWood == 200, "queima")
		assert(s("bridge").radius == 3.1 and s("bridge").health == 300, "ponte")
		assert(s("roof").radius == 3.2 and s("roof").health == 300, "telhado")
		assert(s("sign").health == 100, "placa")
		local well = s("well").well
		assert(s("well").health == 500 and well.drinksPerBucket == 12, "poço")
		assert(well.maxDrinks == 48 and well.thirstPerDrink == 20, "poço")
		local bed = s("bed").bed
		assert(s("bed").health == 300 and bed.regenFactor == 2 and bed.drainFactor == 0.5, "cama")
	end,

	["structure blocks are required in their kind and refused elsewhere"] = function()
		local function errorsFor(structure: any): { string }
			local item = validItem("thing")
			item.category = "placeable"
			item.structure = structure
			return Validate.all({ Tiers = {}, Items = { thing = item } }, alwaysHas)
		end
		local goodExtractor =
			{ output = "stone", woodPerCycle = 2, cycleSeconds = 10, yield = 1, maxWood = 1, maxStock = 1 }
		assert(#errorsFor({ kind = "extractor", health = 100, extractor = goodExtractor }) == 0, "extrator válido")
		assert(containsError(errorsFor({ kind = "extractor", health = 100 }), "structure.extractor"), "sem bloco")
		local bad = table.clone(goodExtractor)
		bad.yield = nil
		assert(
			containsError(errorsFor({ kind = "extractor", health = 100, extractor = bad }), "extractor.yield"),
			"sem yield"
		)
		bad = table.clone(goodExtractor)
		bad.cycleSeconds = "10"
		assert(
			containsError(errorsFor({ kind = "extractor", health = 100, extractor = bad }), "cycleSeconds"),
			"tipo errado"
		)
		bad = table.clone(goodExtractor)
		bad.output = ""
		assert(containsError(errorsFor({ kind = "extractor", health = 100, extractor = bad }), "output"), "sem output")
		assert(
			containsError(errorsFor({ kind = "wall", health = 100, extractor = goodExtractor }), "só vale"),
			"campo em tipo errado"
		)
		assert(
			containsError(errorsFor({ kind = "furnace", health = 100, heatRadius = 24 }), "structure.furnace"),
			"fornalha sem bloco"
		)
		assert(
			containsError(
				errorsFor({
					kind = "well",
					health = 100,
					well = { drinksPerBucket = 1, maxDrinks = 0, thirstPerDrink = 1 },
				}),
				"well.maxDrinks"
			),
			"poço com zero"
		)
		assert(
			containsError(errorsFor({ kind = "bed", health = 100, bed = { regenFactor = 2 } }), "bed.drainFactor"),
			"cama sem campo"
		)
		assert(
			containsError(
				errorsFor({
					kind = "bed",
					health = 100,
					well = { drinksPerBucket = 1, maxDrinks = 1, thirstPerDrink = 1 },
				}),
				"structure.well"
			),
			"poço na cama"
		)
	end,

	["spike_door needs spikeDamage and furnace needs heatRadius"] = function()
		local function errorsFor(structure: any): { string }
			local item = validItem("thing")
			item.category = "placeable"
			item.structure = structure
			return Validate.all({ Tiers = {}, Items = { thing = item } }, alwaysHas)
		end
		assert(containsError(errorsFor({ kind = "spike_door", health = 100 }), "spikeDamage"), "porta sem dano")
		assert(#errorsFor({ kind = "spike_door", health = 100, spikeDamage = 10 }) == 0, "porta válida")
		assert(
			containsError(errorsFor({ kind = "door", health = 100, spikeDamage = 10 }), "spikeDamage"),
			"dano em porta comum"
		)
		local furnace = { burnEvery = 6, maxWood = 10 }
		assert(
			containsError(errorsFor({ kind = "furnace", health = 100, furnace = furnace }), "heatRadius"),
			"sem calor"
		)
		assert(
			#errorsFor({ kind = "furnace", health = 100, heatRadius = 24, station = "fire", furnace = furnace }) == 0,
			"fornalha válida"
		)
		assert(
			containsError(
				errorsFor({ kind = "furnace", health = 100, heatRadius = 24, lifetime = 5, furnace = furnace }),
				"lifetime"
			),
			"lifetime na fornalha"
		)
		assert(
			containsError(errorsFor({ kind = "wall", health = 100, heatRadius = 5 }), "heatRadius"),
			"calor na parede"
		)
	end,
}
