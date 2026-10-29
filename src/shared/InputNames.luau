--!strict
-- Nomes das instâncias do Input Action System criadas para cada jogador.
-- Servidor (que cria) e cliente/simulação (que leem) usam os mesmos nomes daqui.
--
-- Player
--   Gameplay (InputContext)
--     Aim (InputAction, Direction2D): direção da mira no plano do chão (x, z)
--       AimBinding (InputBinding, Scriptable): o cliente dispara com :Fire(Vector2)
--     Slot1 … Slot10 (InputAction, Bool): selecionar slot da hotbar (teclas 1 … 0)
return table.freeze({
	Context = "Gameplay",
	Aim = "Aim",
	AimBinding = "AimBinding",
	Slot = table.freeze({ "Slot1", "Slot2", "Slot3", "Slot4", "Slot5", "Slot6", "Slot7", "Slot8", "Slot9", "Slot10" }),
})
