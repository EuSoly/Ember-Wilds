--!strict
-- Números do inventário num lugar só (servidor, cliente e testes leem daqui).
--
-- Capacidade de um jogador = BASE_SLOTS + slots da mochila vestida + bônus do
-- gamepass, nunca passando de MAX_SLOTS. Para mudar o limite máximo também é
-- preciso mudar as faixas u8(1..40) em net/game.blink.
return table.freeze({
	-- Slots que todo jogador tem; os primeiros HOTBAR_SLOTS são a hotbar.
	BASE_SLOTS = 10,
	HOTBAR_SLOTS = 10,
	-- Limite absoluto de slots (mochila maior + gamepass).
	MAX_SLOTS = 40,

	-- Limites do contrato de rede (net/game.blink: Id string(1..32), Count u16).
	-- Validate rejeita itens que passem disso, senão o cliente não decodifica.
	MAX_ITEM_ID_LENGTH = 32,
	MAX_STACK = 65535,

	-- Gamepass "VIP": conveniência leve, slots extras na mochila (spec, seção 7).
	-- gamePassId = 0 deixa desligado. Crie o passe no Roblox e coloque o ID aqui.
	vipPass = table.freeze({
		gamePassId = 0,
		bonusSlots = 3,
	}),
})
