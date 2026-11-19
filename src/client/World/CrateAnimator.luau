--!strict
-- Anima as peças móveis das caixas 3D (ex. o rotor e as penas da Caixa do
-- vento, o anel e os cristais da Caixa vórtice). Só no cliente: as peças são
-- ancoradas e o servidor nunca as move, então mexer o CFrame aqui não
-- replica nem atrapalha o jogo. Quem diz como cada peça se mexe é o
-- Models/CrateMotion, pelo papel da peça no SkinManifest (o nome da peça é o
-- nome do manifest).
--   start(): caixas do mundo (tag CrateTag), chegando aos poucos (streaming).
--   attach(model): uma caixa avulsa (prévia do menu); devolve como parar.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CrateMotion = require(Shared:WaitForChild("Models"):WaitForChild("CrateMotion"))
local SkinManifest = require(Shared:WaitForChild("Defs"):WaitForChild("SkinManifest"))
local StatNames = require(Shared:WaitForChild("StatNames"))

type Moving = { part: BasePart, rest: CFrame, transparency: number, motion: CrateMotion.Motion }
type Entry = { model: Model, parts: { Moving } }

local CrateAnimator = {}

local entries: { [Model]: Entry } = {}
local connection: RBXScriptConnection? = nil

-- Peças móveis do modelo, com a posição de descanso relativa ao pivô dele.
local function collect(model: Model): { Moving }
	local pivot = model:GetPivot()
	local parts: { Moving } = {}
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			local info = SkinManifest.PARTS[descendant.Name]
			local motion = info and CrateMotion.of(info.papel)
			if motion then
				table.insert(parts, {
					part = descendant,
					rest = pivot:ToObjectSpace(descendant.CFrame),
					transparency = descendant.Transparency,
					motion = motion,
				})
			end
		end
	end
	return parts
end

local function step()
	local t = os.clock()
	for model, entry in entries do
		if model.Parent == nil then
			entries[model] = nil
			continue
		end
		local pivot = model:GetPivot()
		for _, moving in entry.parts do
			if moving.motion.kind == "bloom" then
				-- Duas coberturas de neon sobre os miolos das flores; a base continua visível.
				moving.part.Transparency = 0.45 + 0.4 * math.cos(2 * math.pi * t / 2.8 - moving.motion.phase)
				continue
			end
			local angle, height = CrateMotion.pose(moving.motion, t)
			-- Gira em volta do eixo vertical do pivô da caixa (o meio dela) e sobe.
			moving.part.CFrame = pivot * CFrame.Angles(0, angle, 0) * CFrame.new(0, height, 0) * moving.rest
		end
	end
	if next(entries) == nil and connection then
		connection:Disconnect()
		connection = nil
	end
end

-- Começa a animar `model` (nada acontece se ele não tem peças móveis).
-- Devolve como parar (volta as peças para o descanso).
function CrateAnimator.attach(model: Model): () -> ()
	-- As duas caixas de peça única balançam uma vez ao aparecer.
	for _, part in model:GetDescendants() do
		local info = SkinManifest.PARTS[part.Name]
		if part:IsA("BasePart") and info and (info.skinId == "crate_kraken" or info.skinId == "crate_aventureiro") then
			local rest = part.CFrame
			local pivot = model:GetPivot()
			local offset = pivot:ToObjectSpace(rest)
			local first = if info.skinId == "crate_kraken" then 6 else -5
			local running: Tween? = nil
			local thread = task.defer(function()
				for _, angle in { first, -math.sign(first) * 3, 0 } do
					local tween = TweenService:Create(
						part,
						TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
						{
							CFrame = pivot * CFrame.Angles(0, 0, math.rad(angle)) * offset,
						}
					)
					running = tween
					tween:Play()
					tween.Completed:Wait()
				end
			end)
			return function()
				if coroutine.status(thread) ~= "dead" then
					task.cancel(thread)
				end
				if running then
					running:Cancel()
				end
				if part.Parent then
					part.CFrame = rest
				end
			end
		end
	end
	local parts = collect(model)
	if #parts == 0 then
		return function() end
	end
	entries[model] = { model = model, parts = parts }
	if connection == nil then
		connection = RunService.RenderStepped:Connect(step)
	end
	return function()
		local entry = entries[model]
		if entry == nil then
			return
		end
		entries[model] = nil
		if model.Parent then
			local pivot = model:GetPivot()
			for _, moving in entry.parts do
				moving.part.CFrame = pivot * moving.rest
				if moving.motion.kind == "bloom" then
					moving.part.Transparency = moving.transparency
				end
			end
		end
	end
end

-- Caixas do mundo: anima cada uma enquanto ela existe no cliente.
function CrateAnimator.start()
	local stops: { [Instance]: () -> () } = {}
	local function added(instance: Instance)
		if instance:IsA("Model") and stops[instance] == nil then
			stops[instance] = CrateAnimator.attach(instance)
		end
	end
	local function removed(instance: Instance)
		local stop = stops[instance]
		if stop then
			stops[instance] = nil
			stop()
		end
	end
	CollectionService:GetInstanceAddedSignal(StatNames.CrateTag):Connect(added)
	CollectionService:GetInstanceRemovedSignal(StatNames.CrateTag):Connect(removed)
	for _, instance in CollectionService:GetTagged(StatNames.CrateTag) do
		added(instance)
	end
end

return CrateAnimator
