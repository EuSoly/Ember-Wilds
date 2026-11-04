--!strict
local ExpressionState = require("../src/shared/ExpressionState")
local Types = require("../src/shared/Defs/Types")

-- Mesmos valores das Defs reais (neutral, blink, hurt), montados aqui para o
-- teste não depender de mudanças de ajuste nas Defs.
local function fakeDefs(): { [string]: Types.ExpressionDef }
	return {
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
		hurt = {
			id = "hurt",
			priority = 100,
			eyes = "squeeze",
			trigger = "event",
			event = "hurt",
			duration = 0.5,
			flash = { color = "#E5484D", duration = 0.15 },
		},
	}
end

-- Sorteia sempre o mínimo do intervalo (3 s).
local function minRandom(): number
	return 0
end

local function never(_def: Types.ExpressionDef): boolean
	return false
end

local function currentId(state: ExpressionState.State, defs: { [string]: Types.ExpressionDef }, now: number): string
	return ExpressionState.current(state, defs, now, minRandom, never).id
end

return {
	["neutral when nothing happens"] = function()
		local id = currentId(ExpressionState.new(), fakeDefs(), 0)
		assert(id == "neutral", `esperava neutral, veio {id}`)
	end,

	["hurt shows for its duration"] = function()
		local defs = fakeDefs()
		local state = ExpressionState.new()
		ExpressionState.trigger(state, "hurt", 10)
		local during = currentId(state, defs, 10.2)
		assert(during == "hurt", `em 10,2 esperava hurt, veio {during}`)
		local after = currentId(state, defs, 10.6)
		assert(after == "neutral", `em 10,6 esperava neutral, veio {after}`)
	end,

	["blink is scheduled, shows briefly, then reschedules"] = function()
		local defs = fakeDefs()
		local state = ExpressionState.new()
		local expected = { { 0, "neutral" }, { 3.05, "blink" }, { 3.2, "neutral" }, { 6.15, "blink" } }
		for _, case in expected do
			local now, want = case[1] :: number, case[2] :: string
			local got = currentId(state, defs, now)
			assert(got == want, `em {now} esperava {want}, veio {got}`)
		end
	end,

	["long gap does not blink late and schedules after now"] = function()
		local defs = fakeDefs()
		local state = ExpressionState.new()
		currentId(state, defs, 0) -- agenda o piscar para 3
		-- Boneco sem atualizar por 100 s (ex. longe da câmera): não "paga" as
		-- piscadas perdidas nem pisca logo ao voltar.
		local id = currentId(state, defs, 100)
		assert(id == "neutral", `em 100 esperava neutral, veio {id}`)
		assert(currentId(state, defs, 100.05) == "neutral", "não deveria piscar logo depois")
		-- random = 0 → intervalo mínimo (3 s): a próxima piscada é em 103.
		local next = currentId(state, defs, 103.05)
		assert(next == "blink", `em 103,05 esperava blink, veio {next}`)
	end,

	["hurt wins over blink"] = function()
		local defs = fakeDefs()
		local state = ExpressionState.new()
		currentId(state, defs, 0) -- agenda o piscar para 3
		ExpressionState.trigger(state, "hurt", 3.0)
		local id = currentId(state, defs, 3.05)
		assert(id == "hurt", `esperava hurt, veio {id}`)
	end,

	["condition expression shows when its condition holds"] = function()
		local defs = fakeDefs()
		defs.cold = {
			id = "cold",
			priority = 50,
			eyes = "closed",
			trigger = "condition",
			condition = { attribute = "Cold", below = 35 },
		}
		local def = ExpressionState.current(ExpressionState.new(), defs, 0, minRandom, function(d)
			return d.id == "cold"
		end)
		assert(def.id == "cold", `esperava cold, veio {def.id}`)
	end,

	["conditionMet compares numbers and booleans"] = function()
		local sleeping = { attribute = "Sleeping", equals = true }
		assert(ExpressionState.conditionMet(sleeping, true) == true, "Sleeping=true deve valer")
		assert(ExpressionState.conditionMet(sleeping, false) == false, "Sleeping=false não vale")
		assert(ExpressionState.conditionMet(sleeping, nil) == false, "ausente não vale")
		assert(ExpressionState.conditionMet(sleeping, 1) == false, "número não vale para equals")
		local cold = { attribute = "Cold", below = 35 }
		assert(ExpressionState.conditionMet(cold, 10) == true, "10 < 35")
		assert(ExpressionState.conditionMet(cold, 50) == false, "50 não < 35")
		assert(ExpressionState.conditionMet(cold, true) == false, "boolean não vale para below")
	end,

	["flash only during its duration"] = function()
		local defs = fakeDefs()
		local state = ExpressionState.new()
		ExpressionState.trigger(state, "hurt", 0)
		local during = ExpressionState.flashColor(state, defs, 0.1)
		assert(during == "#E5484D", `em 0,1 esperava #E5484D, veio {during}`)
		local after = ExpressionState.flashColor(state, defs, 0.2)
		assert(after == nil, `em 0,2 esperava nil, veio {after}`)
	end,

	["isRecent ignores old and missing times"] = function()
		assert(ExpressionState.isRecent(nil, 5, 1) == false, "nil não é recente")
		assert(ExpressionState.isRecent(4.5, 5, 1) == true, "4,5 é recente em 5")
		assert(ExpressionState.isRecent(3, 5, 1) == false, "3 é antigo em 5")
		assert(ExpressionState.isRecent(6, 5, 1) == false, "relógio fora de ordem não conta")
	end,
}
