--!strict
local KitOffer = require("../src/shared/UIFlow/KitOffer")

-- Estado com tudo preenchido: Iniciante permanente e ativo, Sobrevivente
-- comprado com Robux para 1 vida.
local function full(): KitOffer.State
	local state = KitOffer.new({ "kit_starter" })
	state = KitOffer.toggleActive(state, "kit_starter")
	return KitOffer.chooseRobuxOnce(state, "kit_survivor")
end

return {
	["points choice wins over robux once and active"] = function()
		local id, source = KitOffer.current(full(), "kit_explorer")
		assert(id == "kit_explorer" and source == "points", `veio {id} {source}`)
	end,

	["robux once wins over active"] = function()
		local id, source = KitOffer.current(full(), nil)
		assert(id == "kit_survivor" and source == "robuxOnce", `veio {id} {source}`)
	end,

	["active alone and nothing at all"] = function()
		local state = KitOffer.toggleActive(KitOffer.new({ "kit_starter" }), "kit_starter")
		local id, source = KitOffer.current(state, nil)
		assert(id == "kit_starter" and source == "permanent", `veio {id} {source}`)
		local none, noSource = KitOffer.current(KitOffer.new({}), nil)
		assert(none == nil and noSource == nil, `veio {none} {noSource}`)
	end,

	["toggleActive ignores not owned"] = function()
		local state = KitOffer.toggleActive(KitOffer.new({}), "kit_veteran")
		assert(state.active == nil, `ativou sem ter: {state.active}`)
	end,

	["buyPermanent owns without activating"] = function()
		local state = KitOffer.buyPermanent(KitOffer.new({}), "kit_veteran")
		assert(state.owned.kit_veteran == true, "não ficou com a posse")
		assert(state.active == nil, "não deveria ativar sozinho")
	end,

	["toggleActive swaps and turns off"] = function()
		local state = KitOffer.new({ "kit_starter", "kit_explorer" })
		state = KitOffer.toggleActive(state, "kit_starter")
		state = KitOffer.toggleActive(state, "kit_explorer")
		assert(state.active == "kit_explorer", `trocou para {state.active}`)
		state = KitOffer.toggleActive(state, "kit_explorer")
		assert(state.active == nil, `deveria desativar, veio {state.active}`)
	end,

	["clearRobuxOnce keeps active"] = function()
		local state = KitOffer.clearRobuxOnce(full())
		assert(state.robuxOnce == nil and state.active == "kit_starter", "limpou o que não devia")
	end,

	["spend clears only robuxOnce"] = function()
		local state = KitOffer.spend(full())
		assert(state.robuxOnce == nil, "a compra de 1 vida deveria ser gasta")
		assert(state.active == "kit_starter", "o permanente ativo deveria continuar")
	end,

	["functions do not mutate the input"] = function()
		local before = KitOffer.new({ "kit_starter" })
		local _ = KitOffer.chooseRobuxOnce(before, "kit_survivor")
		local _ = KitOffer.toggleActive(before, "kit_starter")
		local _ = KitOffer.buyPermanent(before, "kit_veteran")
		assert(before.robuxOnce == nil and before.active == nil, "mudou o estado antigo")
		assert(before.owned.kit_veteran == nil, "mudou a posse do estado antigo")
	end,

	["points kit dropped falls back to active"] = function()
		-- Os pontos caíram e a escolha de pontos sumiu: volta o permanente.
		local state = KitOffer.toggleActive(KitOffer.new({ "kit_starter" }), "kit_starter")
		local id, source = KitOffer.current(state, nil)
		assert(id == "kit_starter" and source == "permanent", `veio {id} {source}`)
	end,
}
