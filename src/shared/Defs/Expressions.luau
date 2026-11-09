--!strict
-- Expressões do boneco (olhos e efeito no corpo). A ativa é a de maior
-- prioridade entre as que estão valendo agora (dano > piscar > neutra).
-- Para adicionar uma (ex. frio por condição), uma entrada aqui basta.
-- Veja docs/guia/boneco.md.
local Palette = require("../Palette")
local StatNames = require("../StatNames")
local Types = require("./Types")

type ExpressionDef = Types.ExpressionDef

local Expressions: { [string]: ExpressionDef } = {
	-- Base: olhos abertos quando nada mais está ativo.
	neutral = { id = "neutral", priority = 0, eyes = "open", trigger = "always" },
	-- Pisca sozinho de tempos em tempos (intervalo sorteado por boneco).
	blink = {
		id = "blink",
		priority = 10,
		eyes = "closed",
		trigger = "periodic",
		duration = 0.12,
		intervalMin = 3,
		intervalMax = 6,
	},
	-- Dormindo na cama (atributo Sleeping do personagem): olhos fechados.
	sleeping = {
		id = "sleeping",
		priority = 50,
		eyes = "closed",
		trigger = "condition",
		condition = { attribute = StatNames.Sleeping, equals = true },
	},
	-- Comendo (atributo EatUntil): olhos "^ ^" contentes durante a mordida.
	eat = {
		id = "eat",
		priority = 60,
		eyes = "happy",
		trigger = "event",
		event = "eat",
		duration = 1.2, -- igual a SurvivalConfig.EAT_DURATION (o renderer limpa se cancelar)
	},
	-- Levou dano: olhos "> <" e o corpo pisca em vermelho.
	hurt = {
		id = "hurt",
		priority = 100,
		eyes = "squeeze",
		trigger = "event",
		event = "hurt",
		duration = 0.5,
		flash = { color = Palette.ui.danger, duration = 0.15 },
	},
}

for _, expression in Expressions do
	if expression.flash ~= nil then
		table.freeze(expression.flash)
	end
	if expression.condition ~= nil then
		table.freeze(expression.condition)
	end
	table.freeze(expression)
end

return table.freeze(Expressions)
