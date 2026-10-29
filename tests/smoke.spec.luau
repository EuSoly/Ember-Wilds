--!strict
-- Garante que o runner de testes encontra e executa specs.
return {
	["runner works"] = function()
		assert(1 + 1 == 2, "aritmética básica")
	end,
}
