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
	["hud.rotate"] = "Girar",

	-- Itens
	["item.wood"] = "Madeira",
	["item.stone"] = "Pedra",
	["item.gold"] = "Ouro",
	["item.berry"] = "Frutinha",
	["item.leather_bag"] = "Mochila de Couro",
	["item.wood_pickaxe"] = "Picareta de Madeira",
	["item.stone_pickaxe"] = "Picareta de Pedra",
	["item.gold_pickaxe"] = "Picareta de Ouro",
	["item.diamond_pickaxe"] = "Picareta de Diamante",
	["item.amethyst_pickaxe"] = "Picareta de Ametista",
	["item.reidite_pickaxe"] = "Picareta de Reidite",
	["item.wood_sword"] = "Espada de Madeira",
	["item.stone_sword"] = "Espada de Pedra",
	["item.gold_sword"] = "Espada de Ouro",
	["item.wood_spear"] = "Lança de Madeira",
	["item.stone_spear"] = "Lança de Pedra",
	["item.gold_spear"] = "Lança de Ouro",
	["item.wood_helmet"] = "Capacete de Madeira",
	["item.stone_helmet"] = "Capacete de Pedra",
	["item.gold_helmet"] = "Capacete de Ouro",
	["item.earmuffs"] = "Protetor de Orelha",
	["item.workbench"] = "Bancada",
	["item.campfire"] = "Fogueira",
	["item.big_campfire"] = "Fogueira Grande",
	["item.wood_wall"] = "Parede de Madeira",
	["item.stone_wall"] = "Parede de Pedra",
	["item.gold_wall"] = "Parede de Ouro",
	["item.wood_door"] = "Porta de Madeira",
	["item.stone_door"] = "Porta de Pedra",
	["item.gold_door"] = "Porta de Ouro",
	["item.wood_spike"] = "Espinho de Madeira",
	["item.stone_spike"] = "Espinho de Pedra",
	["item.gold_spike"] = "Espinho de Ouro",
	["item.chest"] = "Baú",
	["item.paper"] = "Papel",
	["item.book"] = "Livro",

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
	["death.cause.hunger"] = "Fome",
	["death.cause.cold"] = "Frio",
	["death.cause.thirst"] = "Sede",
	["death.cause.drown"] = "Afogado",
	["death.cause.heat"] = "Calor",
	["death.cause.spike"] = "Espinho",

	-- Coleta
	["gather.empty"] = "Este recurso acabou",
	["gather.needTool"] = "Precisa de {item}",
	["gather.full"] = "Inventário cheio",
	["craft.needWorkbench"] = "Precisa estar perto de uma bancada",
	["craft.needFire"] = "Precisa estar perto do fogo",
	["craft.full"] = "Inventário cheio",
	["craft.station.workbench"] = "Bancada",
	["craft.station.fire"] = "Fogo",
	["craft.station.none"] = "Sem estação",
	["craft.book.title"] = "Livro de Receitas",
	["craft.book.close"] = "Fechar",

	-- Kits iniciais
	["kit.kit_starter"] = "Iniciante",
	["kit.kit_explorer"] = "Explorador",
	["kit.kit_survivor"] = "Sobrevivente",
	["kit.kit_veteran"] = "Veterano",
	["kit.price"] = "{price} pts",
	["kit.points"] = "Pontos para kit: {points}",

	-- Mundo
	["world.locked"] = "Região ainda não descoberta",

	-- Recursos do mundo
	["resource.tree"] = "Árvore",
	["resource.rock"] = "Rocha",
	["resource.gold_vein"] = "Jazida de ouro",
	["resource.berry_bush"] = "Arbusto de frutinha",
	["resource.pebble"] = "Pedra do chão",

	-- Zonas de recurso (Map/Zones, atributo ZoneType)
	["zone.forest_dense"] = "Floresta densa",
	["zone.forest_open"] = "Floresta aberta",
	["zone.quarry"] = "Pedreira",
	["zone.berry_field"] = "Campo de frutinhas",
})
