--!strict
-- Paleta oficial do jogo (docs/game-design/identidade-visual.md e img/paleta.png).
-- Só dados puros em hex "#RRGGBB": roda tanto no Roblox quanto nos testes do Lune.
-- Para usar como Color3 no Roblox, passe pelo módulo Theme.

local function deepFreeze<T>(value: T): T
	if type(value) == "table" then
		for _, child in value :: any do
			deepFreeze(child)
		end
		table.freeze(value :: any)
	end
	return value
end

local Palette = {
	-- Tokens da interface.
	ui = {
		panel = "#1E2230", -- fundo de painéis e do HUD (usar 85% opaco)
		panelRaised = "#2A3042", -- cartas de receita, slot selecionado
		border = "#3A4258", -- UIStroke de painéis e slots
		text = "#F4F1EA", -- texto principal (branco quente)
		textSecondary = "#A9B0C2", -- descrições e rótulos
		action = "#FF8A1F", -- botão principal, seleção, destaques
		success = "#4CC38A", -- craft possível, construção válida
		warning = "#F5C542", -- barra em 35%, noite chegando
		danger = "#E5484D", -- dano, construção inválida, barra vazia
	},

	-- Cor de cada tier de material: a mesma na jazida, ferramenta, parede,
	-- moldura do ícone e raridade de cosmético.
	tier = {
		wood = "#8B5A2B",
		stone = "#8A8F98",
		gold = "#F2B632",
		diamond = "#3FD0E0",
		amethyst = "#9B5DE5",
		reidite = "#D63384",
		emerald = "#2ECC71",
	},

	-- Barras de status (anéis do HUD).
	status = {
		health = "#E5484D",
		hunger = "#F28C28",
		cold = "#4DA3FF",
		thirst = "#2EC4B6",
		oxygen = "#E8F4FF",
		heat = "#FF6B35",
	},

	-- Quatro cores por bioma, na ordem da imagem da paleta.
	biome = {
		forest = { "#6FBF4A", "#3E8E41", "#7A4E2A", "#A77B4F" },
		winter = { "#EAF4FB", "#A8D8F0", "#2F6F62", "#5B6C8F" },
		ocean = { "#F2D79B", "#4FC3D9", "#1F6F9F", "#1F3F6F" },
		desert = { "#E8B86D", "#C9774A", "#5E9E4F", "#FFD9A0" },
		lava = { "#3A2B2E", "#FF5A1F", "#FFB84D", "#6E5A5E" },
		nightFire = { "#1B2A4A", "#7F9CD6", "#FFA43A", "#FF8A1F" },
	},

	-- Moldura de itens sem tier (comida, recursos).
	neutralFrame = "#8A8F98",

	-- Design system rústico (docs/game-design/design-system/README.md, seção 2):
	-- madeira estrutura, couro convida à interação, papel explica, brasa destaca.
	-- As telas novas (carregamento, menu) usam estas cores; o resto da UI ainda
	-- usa o grupo `ui` até ser redesenhado.
	rustic = {
		outline = "#211A15", -- contorno externo e sombra mais profunda
		charcoal = "#29241F", -- fundos escuros e tinta sobre papel
		woodShadow = "#38291F",
		walnut = "#59402D", -- corpo da madeira
		woodLight = "#805739", -- face iluminada da madeira
		woodEdge = "#AD7745",
		leatherShadow = "#68432D",
		leather = "#95603D", -- botão secundário
		leatherLight = "#B87C4B",
		paperShadow = "#B99462",
		paper = "#E8D5AE", -- área de leitura
		paperLight = "#F4E5C6",
		moss = "#78834F",
		emberShadow = "#B75A22",
		ember = "#E99843", -- ação principal e seleção
		emberLight = "#FFC66B",
		cream = "#FFF3D6", -- texto sobre fundo escuro
		textSecondaryDark = "#C9B898", -- texto secundário sobre carvão/nogueira
		textSecondaryLight = "#59402D", -- texto secundário sobre papel
		success = "#92B56A",
		disabled = "#51483D", -- fundo de botão sem ação
		disabledText = "#B9AA91",
		-- Noite da barra de carregamento (o sol vira lua na metade).
		nightShadow = "#363F84",
		night = "#5B6FC4",
		nightLight = "#9FB6FF",
	},
}

return deepFreeze(Palette)
