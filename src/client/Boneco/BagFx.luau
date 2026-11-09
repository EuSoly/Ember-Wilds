--!strict
-- Partículas das mochilas dos pacotes do lançamento (BagFxConfig): presas no
-- meio da mochila, soltam mais quanto mais rápido o boneco anda e nada quando
-- ele para. As partículas ficam no mundo (não seguem a mochila), então viram
-- um rastro atrás do jogador. Só no cliente.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BagFxConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BagFxConfig"))

export type Fx = { emitters: { ParticleEmitter }, defs: { BagFxConfig.Emitter }, walk: number }

local BagFx = {}

-- Degrau da fração de velocidade em que o Rate é reescrito.
local RATE_STEP = 0.05

local function sequence(values: { number }): NumberSequence
	if #values == 3 then
		return NumberSequence.new({
			NumberSequenceKeypoint.new(0, values[1]),
			NumberSequenceKeypoint.new(0.5, values[2]),
			NumberSequenceKeypoint.new(1, values[3]),
		})
	end
	return NumberSequence.new(values[1], values[2])
end

local function colors(list: { string }): ColorSequence
	local first = Color3.fromHex(list[1])
	return ColorSequence.new(first, if list[2] then Color3.fromHex(list[2]) else first)
end

local function range(values: { number }): NumberRange
	return NumberRange.new(values[1], values[2])
end

-- Liga os efeitos de `bagId` na mochila `bag` (BagModel). nil = sem efeito.
function BagFx.attach(bag: Model, bagId: string?): Fx?
	local defs = BagFxConfig.of(bagId)
	local main = bag.PrimaryPart
	if defs == nil or main == nil then
		return nil
	end
	local emitters = {}
	for i, def in defs do
		local offset = def.offset or { 0, 0, 0 }
		local attachment = Instance.new("Attachment")
		attachment.Name = `BagFx{i}`
		-- Na raiz do boneco (frente -Z): o meio da mochila já está nas costas.
		attachment.Position = Vector3.new(offset[1], offset[2], offset[3])
		attachment.Parent = main

		local emitter = Instance.new("ParticleEmitter")
		emitter.Texture = def.texture
		emitter.Color = colors(def.colors)
		emitter.Size = sequence(def.size)
		emitter.Transparency = sequence(def.transparency)
		emitter.Lifetime = range(def.lifetime)
		emitter.Speed = range(def.speed)
		emitter.SpreadAngle = Vector2.new(def.spread, def.spread)
		emitter.Acceleration = Vector3.new(def.acceleration[1], def.acceleration[2], def.acceleration[3])
		emitter.LightEmission = def.lightEmission or 0
		emitter.Drag = def.drag or 0
		if def.rotSpeed then
			emitter.RotSpeed = range(def.rotSpeed)
			emitter.Rotation = NumberRange.new(0, 360)
		end
		emitter.EmissionDirection = Enum.NormalId.Top
		if def.flat then
			-- Velocidade para cima + perpendicular = a partícula deita no chão.
			emitter.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
		end
		emitter.LockedToPart = false
		emitter.Rate = 0
		emitter.Enabled = false
		emitter.Parent = attachment
		table.insert(emitters, emitter)
	end
	return { emitters = emitters, defs = defs, walk = -1 }
end

-- Acerta a quantidade de partículas pela fração de velocidade (0 a 1).
function BagFx.update(fx: Fx, walk: number)
	-- Só reescreve quando muda de degrau (a fração vem suavizada a cada quadro).
	walk = if walk < BagFxConfig.MIN_WALK then 0 else math.floor(walk / RATE_STEP + 0.5) * RATE_STEP
	if walk == fx.walk then
		return
	end
	fx.walk = walk
	for i, emitter in fx.emitters do
		local rate = BagFxConfig.rate(fx.defs[i], walk)
		emitter.Rate = rate
		emitter.Enabled = rate > 0
	end
end

return BagFx
