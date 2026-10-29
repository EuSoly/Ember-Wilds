--!strict
-- Nomes das instâncias do Input Action System criadas para cada jogador.
-- Servidor (que cria) e cliente/simulação (que leem) usam os mesmos nomes daqui.
--
-- Player
--   Gameplay (InputContext)
--     Aim (InputAction, Direction2D): direção da mira no plano do chão (x, z)
--       AimBinding (InputBinding, Scriptable): o cliente dispara com :Fire(Vector2)
return table.freeze({
	Context = "Gameplay",
	Aim = "Aim",
	AimBinding = "AimBinding",
})
