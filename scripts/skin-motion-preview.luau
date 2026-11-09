--!strict
-- Amostra o SkinMotion (o movimento das peças animadas no jogo) para a prévia
-- no Blender (assets/skins/preview_animacao.py). Rodar na raiz do projeto:
--   lune run scripts/skin-motion-preview
-- Saída: assets/skins/animadas/movimentos.json, com a pose de cada peça a cada
-- quadro: primeiro PARADO e depois ANDANDO (fase dos passos de quem anda a
-- toda, igual ao BonecoAnim), nos eixos do Roblox.
local fs = require("@lune/fs")
local serde = require("@lune/serde")

local C = require("../src/shared/BonecoConfig")
local SkinManifest = require("../src/shared/Defs/SkinManifest")
local SkinMotion = require("../src/shared/Models/SkinMotion")

local FPS = 24
local IDLE_SECONDS = 6
local WALK_SECONDS = 4
local STEP_SPEED = C.WALK_SPEED_REF * C.STEP_RATE -- rad/s da fase andando a toda

local out = { fps = FPS, quadros_parado = IDLE_SECONDS * FPS, quadros_andando = WALK_SECONDS * FPS, skins = {} }
for _, skinId in SkinMotion.skins() do
	local parts = {}
	for _, name in SkinManifest.PARTS_BY_SKIN[skinId] or {} do
		local info = SkinManifest.PARTS[name]
		local motion = SkinMotion.of(skinId, info.papel)
		if motion and parts[info.papel] == nil then
			local frames = {}
			for f = 0, (IDLE_SECONDS + WALK_SECONDS) * FPS - 1 do
				local t = f / FPS
				local walking = f >= IDLE_SECONDS * FPS
				local phase = if walking then (t - IDLE_SECONDS) * STEP_SPEED else 0
				local p = SkinMotion.pose(motion, t, phase, if walking then 1 else 0)
				table.insert(frames, { p.x, p.y, p.z, p.px, p.py, p.pz })
			end
			parts[info.papel] = frames
		end
	end
	out.skins[skinId] = parts
end

fs.writeDir("assets/skins/animadas")
fs.writeFile("assets/skins/animadas/movimentos.json", serde.encode("json", out, false))
print("ok: assets/skins/animadas/movimentos.json")
