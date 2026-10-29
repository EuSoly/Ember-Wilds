--!strict
-- Ciclo de vida dos sistemas (serviços do servidor e controladores do cliente).
--
-- Fase 1: Init() de todos, na ordem dada. Use para criar estado e instâncias,
--         sem depender de outros sistemas estarem prontos.
-- Fase 2: Start() de todos. Aqui um sistema já pode usar os outros.
--
-- Start() deve ser curto e síncrono: quem precisa de loop cria a própria
-- thread (task.spawn) ou conexão. Assim um sistema lento não trava os outros.

export type System = {
	Name: string?,
	Init: ((any) -> ())?,
	Start: ((any) -> ())?,
}

local Lifecycle = {}

local function callPhase(system: System, phase: "Init" | "Start")
	local fn = system[phase]
	if fn == nil then
		return
	end
	local ok, err = pcall(fn, system)
	if not ok then
		error(`[Lifecycle] {phase} falhou em {system.Name or "?"}: {err}`, 0)
	end
end

function Lifecycle.run(systems: { System })
	for _, system in systems do
		callPhase(system, "Init")
	end
	for _, system in systems do
		callPhase(system, "Start")
	end
end

return Lifecycle
