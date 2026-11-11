--!strict
local Defs = require("../src/shared/Defs")
local GhostRules = require("../src/shared/Survival/GhostRules")

local items = Defs.Items

return {
	["crown keeps the heart; heart only without crown"] = function()
		assert(GhostRules.source(true, true) == "crown", "coroa e coração: vale a coroa (não gasta o coração)")
		assert(GhostRules.source(true, false) == "heart", "só o coração")
		assert(GhostRules.source(false, true) == "crown", "só a coroa")
		assert(GhostRules.source(false, false) == nil, "nada: morre")
	end,

	["crown time drops with the strongest item held"] = function()
		assert(GhostRules.seconds("heart", { items.lava_sword }) == 60, "coração: sempre 60")
		assert(GhostRules.seconds("crown", {}) == 60, "nada na mão: 60")
		assert(GhostRules.seconds("crown", { items.gold_sword }) == 60, "até ouro: 60")
		assert(GhostRules.seconds("crown", { items.diamond_sword }) == 35, "diamante: 35")
		assert(GhostRules.seconds("crown", { items.amethyst_spear }) == 25, "ametista: 25")
		assert(GhostRules.seconds("crown", { items.reidite_sword }) == 15, "reidite: 15")
		assert(GhostRules.seconds("crown", { items.dragon_sword, items.gold_sword }) == 8, "dragão: 8")
		assert(GhostRules.seconds("crown", { items.lava_spear }) == 5, "lava: 5")
	end,

	["items lost on revive"] = function()
		assert(GhostRules.loses("heart", items.gold_sword), "coração: espada")
		assert(GhostRules.loses("heart", items.wood_shield), "coração: escudo")
		assert(GhostRules.loses("heart", items.stone_pickaxe), "coração: picareta")
		assert(GhostRules.loses("heart", items.wrench), "coração: chave inglesa")
		assert(GhostRules.loses("heart", items.reidite_hammer), "coração: martelo de reidite")
		assert(GhostRules.loses("heart", items.super_hammer), "coração: super martelo")
		assert(not GhostRules.loses("heart", items.gold_hammer), "coração: martelo de ouro fica")
		assert(not GhostRules.loses("heart", items.wood), "coração: madeira fica")
		assert(GhostRules.loses("crown", items.stone_spear), "coroa: lança")
		assert(GhostRules.loses("crown", items.gold_spike), "coroa: espinho")
		assert(GhostRules.loses("crown", items.wood_spike_door), "coroa: porta com espinho")
		assert(GhostRules.loses("crown", items.super_hammer), "coroa: super martelo")
		assert(not GhostRules.loses("crown", items.gold_pickaxe), "coroa: picareta fica")
		assert(not GhostRules.loses("crown", items.wood_wall), "coroa: parede fica")
	end,

	["score after revive and for the killer"] = function()
		assert(GhostRules.revivedScore(1000) == 333, "fica com 1/3")
		assert(GhostRules.revivedScore(2) == 0, "arredonda para baixo")
		assert(GhostRules.ghostKillBonus(1000) == 100, "quem matou: 10%")
	end,

	["no ghost from a fall or an already dead body"] = function()
		assert(GhostRules.canBecomeGhost("death.cause.wolf", true), "golpe: vira fantasma")
		assert(not GhostRules.canBecomeGhost("death.cause.fall", true), "queda do mapa: morre (não gasta o coração)")
		assert(not GhostRules.canBecomeGhost("death.cause.unknown", false), "Humanoid já morto: morre")
	end,

	["revive near a stone before the time ends"] = function()
		assert(GhostRules.canRevive(5, 10, 20), "perto e no tempo")
		assert(not GhostRules.canRevive(GhostRules.REVIVE_RADIUS + 0.1, 10, 20), "longe")
		assert(not GhostRules.canRevive(1, 20, 20), "tempo acabou")
		assert(GhostRules.isGhost(20, 10) and not GhostRules.isGhost(nil, 10), "fantasma pelo instante")
	end,
}
