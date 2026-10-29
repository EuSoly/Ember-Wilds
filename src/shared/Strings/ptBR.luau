--!strict
-- Textos exibidos em português do Brasil. Chave → texto.
-- Toda chave usada por Defs (nameKey, rarityKey) precisa existir aqui:
-- a validação das Defs falha no boot se faltar alguma.
return table.freeze({
	-- Raridades (iguais aos tiers de material)
	["rarity.common"] = "Comum",
	["rarity.uncommon"] = "Incomum",
	["rarity.rare"] = "Raro",
	["rarity.epic"] = "Épico",
	["rarity.mythic"] = "Mítico",
	["rarity.legendary"] = "Lendário",

	-- Tiers de material
	["tier.wood"] = "Madeira",
	["tier.stone"] = "Pedra",
	["tier.gold"] = "Ouro",
	["tier.diamond"] = "Diamante",
	["tier.amethyst"] = "Ametista",
	["tier.reidite"] = "Reidite",
	["tier.emerald"] = "Esmeralda",

	-- HUD
	["hud.day"] = "Dia {day}",
	["hud.points"] = "{points} pts",
	["hud.rank"] = "#{rank}",
	["hud.nightComing"] = "A noite está chegando",
	["hud.backpack"] = "Mochila",

	-- Itens
	["item.wood"] = "Madeira",
	["item.stone"] = "Pedra",
	["item.gold"] = "Ouro",
	["item.berry"] = "Frutinha",
	["item.leather_bag"] = "Mochila de Couro",
	["item.wood_pickaxe"] = "Picareta de Madeira",
	["item.stone_pickaxe"] = "Picareta de Pedra",
	["item.gold_pickaxe"] = "Picareta de Ouro",

	-- Cosméticos
	["cosmeticSlot.body"] = "Corpo",
	["cosmetic.body_default"] = "Clássico",
	["cosmetic.body_ember"] = "Brasa",

	-- Moeda
	["currency.name"] = "Golden Ember",

	-- Dados salvos (mensagens de expulsão)
	["data.loadFailed"] = "Não foi possível carregar seus dados. Tente entrar de novo.",
	["data.sessionTaken"] = "Seus dados foram abertos em outro servidor.",
	["data.newerVersion"] = "O jogo foi atualizado. Entre de novo para continuar.",
	["data.devReset"] = "Perfil de desenvolvimento apagado. Entre de novo.",
	["data.corrupt"] = "Seus dados precisam de ajuda do suporte. Fale com a equipe do jogo.",

	-- Estatísticas
	["stat.players_killed"] = "Jogadores derrotados",
	["stat.mobs_killed"] = "Criaturas derrotadas",
	["stat.resources_gathered"] = "Recursos coletados",
	["stat.items_crafted"] = "Itens criados",
	["stat.deaths"] = "Mortes",
	["stat.score_total"] = "Pontuação total",
	["stat.score_best"] = "Melhor pontuação",
	["stat.days_best"] = "Mais dias vivo",
	["stat.playtime_seconds"] = "Tempo de jogo",

	-- Configurações
	["setting.music_volume"] = "Volume da música",
	["setting.ambient_volume"] = "Volume do ambiente",
	["setting.effects_volume"] = "Volume dos efeitos",
	["setting.quality"] = "Qualidade gráfica",
	["setting.ui_scale"] = "Tamanho da interface",
	["setting.left_handed"] = "Modo canhoto",
	["setting.quality.auto"] = "Automática",
	["setting.quality.low"] = "Baixa",
	["setting.quality.medium"] = "Média",
	["setting.quality.high"] = "Alta",
	["setting.on"] = "Ligado",
	["setting.off"] = "Desligado",
	["settings.title"] = "Configurações",
	["settings.close"] = "Fechar",

	-- Carregamento
	["loading.title"] = "Ember Wilds",
	["loading.status"] = "Carregando…",

	-- Menu
	["menu.play"] = "Jogar",
	["menu.settings"] = "Configurações",
	["menu.balance"] = "{amount} Golden Ember",
	["menu.kits"] = "Kit inicial",

	-- Morte
	["death.title"] = "Você morreu",
	["death.cause"] = "Causa: {cause}",
	["death.days"] = "Dias vividos: {days}",
	["death.points"] = "{points} pts",
	["death.currency"] = "+{amount} Golden Ember",
	["death.playAgain"] = "Jogar de novo",
	["death.menu"] = "Menu",
	["death.cause.dev"] = "Teste",
	["death.cause.fall"] = "Caiu do mapa",
	["death.cause.unknown"] = "Desconhecida",

	-- Kits iniciais
	["kit.kit_starter"] = "Iniciante",
	["kit.kit_explorer"] = "Explorador",
	["kit.kit_survivor"] = "Sobrevivente",
	["kit.kit_veteran"] = "Veterano",
	["kit.price"] = "{price} pts",
	["kit.points"] = "Pontos para kit: {points}",
})
