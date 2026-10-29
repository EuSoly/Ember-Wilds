--!strict
-- Medidas do mundo. O mapa de teste é um quadrado centrado na origem;
-- quando o gerador de mapa entrar (Fase 6), ele também lê daqui.
return table.freeze({
	-- Lado do mundo em studs (de -size/2 a +size/2 em X e Z).
	size = 256,
	-- Altura (Y) abaixo da qual o personagem conta como caído do mapa: o
	-- DeathService mata com a causa "death.cause.fall". O topo do chão é Y = 0.
	-- Fica bem acima do Workspace.FallenPartsDestroyHeight do Roblox, para a
	-- morte vir antes de o Roblox apagar a raiz do personagem.
	KILL_Y = -100,
})
