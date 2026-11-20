--!strict
-- Corpo de um bot (BotService): o mesmo personagem mínimo do jogador
-- (CharacterBody) com a tag Boneco, então o cliente desenha o mesmo boneco
-- (nome em cima, skin, mochila, item na mão, golpe, careta). A raiz fica
-- ancorada e o servidor a move, como os mobs (o boneco anda pela mudança de
-- posição). Os atributos visuais ficam no próprio modelo (não há Player).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.Shared
local BonecoConfig = require(Shared.BonecoConfig)
local CharacterBody = require(Shared.Models.CharacterBody)
local Defs = require(Shared.Defs)
local StatNames = require(Shared.StatNames)
local CharacterService = require(script.Parent.Parent.CharacterService)

local FOLDER = "Bots"
local ROOT_Y = BonecoConfig.HIP_HEIGHT + BonecoConfig.ROOT_HEIGHT / 2

local Body = {}

Body.ROOT_Y = ROOT_Y

local function folder(): Folder
	local found = Workspace:FindFirstChild(FOLDER)
	if found and found:IsA("Folder") then
		return found
	end
	local created = Instance.new("Folder")
	created.Name = FOLDER
	created.Parent = Workspace
	return created
end

-- Skins que um jogador comum teria: as que saem nos giros, lançadas e sem a
-- etiqueta Limitada (não desvaloriza o que se compra ou se ganha no grupo).
local function commonSkins(slot: string): { string }
	local list: { string } = {}
	for id, def in Defs.Cosmetics do
		local tags = def.tags
		local limited = tags ~= nil and table.find(tags, "limited") ~= nil
		if def.slot == slot and def.inSpins ~= false and def.unreleased ~= true and not limited then
			table.insert(list, id)
		end
	end
	table.sort(list)
	return list
end

local bodySkins = commonSkins("body")
local bagSkins = commonSkins("bag")

local function pick(list: { string }, rng: Random): string?
	if #list == 0 then
		return nil
	end
	return list[rng:NextInteger(1, #list)]
end

-- Monta o corpo em (x, z) olhando para `facing`. O nome do modelo é o nome
-- que aparece em cima do boneco e no placar.
function Body.build(name: string, botId: number, x: number, z: number, rng: Random): (Model, BasePart)
	local model = CharacterBody.build()
	model.Name = name
	local root = model.PrimaryPart :: BasePart
	root.Anchored = true
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.AutoRotate = false
	end
	model:PivotTo(CFrame.new(x, ROOT_Y, z))
	model:SetAttribute(StatNames.BotId, botId)
	model:SetAttribute(StatNames.BotScore, 0)
	-- Metade dos jogadores de verdade fica com a skin padrão: alguns bots também.
	if rng:NextNumber() < 0.75 then
		model:SetAttribute(StatNames.CosmeticPrefix .. "body", pick(bodySkins, rng))
	end
	if rng:NextNumber() < 0.5 then
		model:SetAttribute(StatNames.CosmeticPrefix .. "bag", pick(bagSkins, rng))
	end
	CharacterService.prepare(model)
	model:AddTag(StatNames.BotTag)
	model.Parent = folder()
	return model, root
end

-- Escreve um atributo só quando muda (rede e polling do cliente).
function Body.set(model: Model, name: string, value: any)
	if model:GetAttribute(name) ~= value then
		model:SetAttribute(name, value)
	end
end

return Body
