--!strict
-- Estados das telas do cliente (puro, testado no Lune). Um único estado decide
-- o que aparece: loading → menu → playing → dead → (playing ou menu).
-- Configurações não é estado: é uma janela por cima (ver canOpenSettings).

export type Screen = "loading" | "menu" | "playing" | "dead"
export type Event = "ready" | "spawned" | "died" | "toMenu"

local ScreenFlow = {}

-- Transições válidas: [estado atual][evento] = próximo estado.
local TRANSITIONS: { [Screen]: { [Event]: Screen } } = {
	loading = { ready = "menu" },
	menu = { spawned = "playing" },
	playing = { died = "dead" },
	dead = { spawned = "playing", toMenu = "menu" },
}

-- Próximo estado. Evento que não vale no estado atual (ex. "died" no menu)
-- devolve o próprio estado, para eventos atrasados não bagunçarem a tela.
function ScreenFlow.next(current: Screen, event: Event): Screen
	local fromCurrent = TRANSITIONS[current]
	return if fromCurrent then fromCurrent[event] or current else current
end

function ScreenFlow.hudVisible(screen: Screen): boolean
	return screen == "playing"
end

function ScreenFlow.canOpenSettings(screen: Screen): boolean
	return screen == "menu" or screen == "playing"
end

return ScreenFlow
