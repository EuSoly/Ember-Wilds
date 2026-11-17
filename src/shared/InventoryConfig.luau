--!strict
-- Números do inventário num lugar só (servidor, cliente e testes leem daqui).
--
-- Capacidade de um jogador = BASE_SLOTS + slots da mochila vestida + bônus do
-- VIP, nunca passando de MAX_SLOTS. Para mudar o limite máximo também é
-- preciso mudar as faixas u8(1..40) em net/game.blink.
return table.freeze({
	-- Slots que todo jogador tem; os primeiros HOTBAR_SLOTS são a hotbar.
	BASE_SLOTS = 10,
	HOTBAR_SLOTS = 10,
	-- Limite absoluto de slots (mochila maior + VIP).
	MAX_SLOTS = 40,

	-- Limites do contrato de rede (net/game.blink: Id string(1..32), Count u16).
	-- Validate rejeita itens que passem disso, senão o cliente não decodifica.
	MAX_ITEM_ID_LENGTH = 32,
	MAX_STACK = 65535,

	-- VIP (por tempo, Shop.VipUntil): slots extras no inventário enquanto vale
	-- na vida (PerkService). Não é mais gamepass.
	vipPass = table.freeze({
		bonusSlots = 3,
	}),
})
