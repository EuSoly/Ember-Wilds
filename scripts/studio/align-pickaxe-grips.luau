--!strict
-- Execute na Command Bar do Studio, em Edit, depois de importar as seis
-- picaretas atuais. Idempotente: usa o pivô do modelo, não o Grip anterior.
-- O pivô dos assets importados tem Y ao longo do cabo e Z na espessura.
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ChangeHistoryService = game:GetService("ChangeHistoryService")

assert(RunService:IsStudio() and not RunService:IsRunning(), "Execute em Edit no Studio")
local tools = ReplicatedStorage:FindFirstChild("Assets")
tools = tools and tools:FindFirstChild("Tools")
assert(tools, "ReplicatedStorage.Assets.Tools não encontrado")

-- Ponto de pega aprovado: parte baixa do cabo, no plano central da malha.
local gripInModel = CFrame.new(0, -1.25, 0.02437)
local updates: { { grip: Attachment, cframe: CFrame } } = {}
for _, tier in { "wood", "stone", "gold", "diamond", "amethyst", "reidite" } do
	local id = tier .. "_pickaxe"
	local model = tools:FindFirstChild(id)
	assert(model and model:IsA("Model"), `Modelo {id} não encontrado`)
	local handle = model.PrimaryPart
	assert(handle and handle.Name == "Handle", `{id}: PrimaryPart deve ser Handle`)
	local grip = handle:FindFirstChild("Grip")
	assert(grip and grip:IsA("Attachment"), `{id}: Handle.Grip não encontrado`)
	local cframe = handle.CFrame:ToObjectSpace(model:GetPivot() * gripInModel)
	table.insert(updates, { grip = grip, cframe = cframe })
	local standardGrip = handle:FindFirstChild("RightGripAttachment")
	if standardGrip and standardGrip:IsA("Attachment") then
		table.insert(updates, { grip = standardGrip, cframe = cframe })
	end
end

-- Todas as referências são validadas antes da primeira alteração.
local recording = ChangeHistoryService:TryBeginRecording("AlignPickaxeGrips", "Alinhar encaixes das picaretas")
-- O MCP pode já ter aberto seu próprio registro de desfazer.
for _, update in updates do
	update.grip.CFrame = update.cframe
end
if recording then
	ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Commit)
end
print("[PickaxeGrip] Encaixes das seis picaretas alinhados")
