--!strict
local InteractRules = require("../src/shared/Build/InteractRules")

local A = InteractRules.ACTIONS

local spec = {}

local function same(list: { number }, expected: { number }): boolean
	if #list ~= #expected then
		return false
	end
	for i, value in expected do
		if list[i] ~= value then
			return false
		end
	end
	return true
end

function spec.constantes()
	assert(InteractRules.RANGE == 8, "alcance 8")
	assert(
		A.put_wood == 1 and A.take == 2 and A.drink == 3 and A.sleep == 4 and A.symbol == 5 and A.fill == 6,
		"números das ações"
	)
end

function spec.acoes_por_tipo()
	assert(same(InteractRules.actionsFor("extractor"), { A.put_wood, A.take }), "extrator: pôr madeira, pegar")
	assert(same(InteractRules.actionsFor("furnace"), { A.put_wood }), "fornalha: pôr madeira")
	assert(same(InteractRules.actionsFor("well"), { A.drink, A.fill }), "poço: beber, encher")
	assert(same(InteractRules.actionsFor("bed"), { A.sleep }), "cama: deitar")
	assert(same(InteractRules.actionsFor("sign"), { A.symbol }), "placa: símbolo")
end

function spec.tipo_sem_acoes()
	assert(#InteractRules.actionsFor("chest") == 0, "baú não usa este painel")
	assert(#InteractRules.actionsFor("wall") == 0, "parede sem ações")
	assert(#InteractRules.actionsFor("nada") == 0, "tipo desconhecido sem ações")
end

function spec.placa_so_o_dono()
	assert(InteractRules.allowed("sign", A.symbol, true), "dono muda o símbolo")
	assert(not InteractRules.allowed("sign", A.symbol, false), "outro jogador não muda o símbolo")
end

function spec.extrator_pegar_so_o_dono()
	assert(InteractRules.allowed("extractor", A.take, true), "dono pega o estoque")
	assert(not InteractRules.allowed("extractor", A.take, false), "outro jogador não pega")
	assert(InteractRules.allowed("extractor", A.put_wood, false), "pôr lenha é de qualquer jogador")
end

function spec.resto_qualquer_jogador()
	for _, case in
		{
			{ "extractor", A.put_wood },
			{ "furnace", A.put_wood },
			{ "well", A.drink },
			{ "well", A.fill },
			{ "bed", A.sleep },
		}
	do
		local kind, action = case[1] :: string, case[2] :: number
		assert(InteractRules.allowed(kind, action, true), `{kind}/{action}: dono pode`)
		assert(InteractRules.allowed(kind, action, false), `{kind}/{action}: qualquer jogador pode`)
	end
end

function spec.acao_fora_da_lista()
	assert(not InteractRules.allowed("furnace", A.take, true), "fornalha não tem pegar")
	assert(not InteractRules.allowed("bed", A.drink, true), "cama não tem beber")
	assert(not InteractRules.allowed("well", A.symbol, true), "poço não tem símbolo")
	assert(not InteractRules.allowed("nada", A.take, true), "tipo desconhecido não deixa nada")
	assert(not InteractRules.allowed("extractor", 0, true), "ação 0 não existe")
	assert(not InteractRules.allowed("extractor", 99, true), "ação 99 não existe")
end

return spec
