--!strict
-- Números dos dados salvos num lugar só, para ajustar com o jogo no ar
-- (tetos da moeda, nome do store, versão do schema).
return table.freeze({
	-- DataStore do perfil. No Studio usa DEV_STORE_PREFIX .. STORE_NAME, para
	-- testes nunca sujarem os dados do jogo real.
	STORE_NAME = "PlayerData",
	DEV_STORE_PREFIX = "Dev_",
	-- Chave = KEY_PREFIX .. UserId (padrão para o template de deleção do GDPR).
	KEY_PREFIX = "Player_",
	-- Versão atual do formato do perfil; subir junto com um passo em Migrations.STEPS.
	SCHEMA_VERSION = 1,

	-- Golden Ember: floor(pontos / POINTS_PER_CURRENCY), no máximo por vida e por hora.
	POINTS_PER_CURRENCY = 1000,
	MAX_CURRENCY_PER_LIFE = 500,
	-- Rede de segurança contra bugs/exploits; só vale para ganhos do jogo.
	MAX_CURRENCY_PER_HOUR = 300,
	HOUR_SECONDS = 3600,

	-- Um ciclo completo (dia + noite), em segundos: base de days_best.
	-- Igual a DayCycle.DAY_SECONDS + DayCycle.NIGHT_SECONDS.
	DAY_CYCLE_SECONDS = 480,

	-- Chaves de estatística keyed (ids de mob/item): mesmo limite dos ids de item.
	STAT_KEY_MAX_LENGTH = 32,
})
