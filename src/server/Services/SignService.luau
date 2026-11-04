--!strict
-- Placa (G8): o dono escolhe um símbolo de uma lista fixa (SignRules.SYMBOLS;
-- sem texto livre, que precisaria de filtro) e todos o veem na placa.
--
-- O símbolo vive no atributo Symbol (índice, 0 = nenhum) do modelo da peça: some
-- com ela. O visual é montado AQUI, no servidor, porque o servidor é dono do
-- modelo: um SurfaceGui no `sign_body` replica para todos sem código no cliente.
-- Há um SurfaceGui na frente (-Z local) e outro atrás, porque a conversão do FBX
-- pode ter virado o modelo; assim o símbolo aparece certo dos dois lados.
-- O pedido já chega conferido pelo InteractService (alcance, dono); o `arg` não.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InteractRules = require(ReplicatedStorage.Shared.Build.InteractRules)
local SignRules = require(ReplicatedStorage.Shared.Build.SignRules)
local StatNames = require(ReplicatedStorage.Shared.StatNames)
local InteractService = require(script.Parent.InteractService)
local StructureService = require(script.Parent.StructureService)

local BODY = "sign_body"
local FACES = { Enum.NormalId.Front, Enum.NormalId.Back }

type Entry = StructureService.Entry

local SignService = {}

-- Cria os dois SurfaceGui com um TextLabel grande cada; devolve os rótulos.
local function buildLabels(model: Model): { TextLabel }
	local body = model:FindFirstChild(BODY, true)
	local labels: { TextLabel } = {}
	if body == nil or not body:IsA("BasePart") then
		return labels
	end
	for _, face in FACES do
		local gui = Instance.new("SurfaceGui")
		gui.Name = "SymbolGui" .. face.Name
		gui.Face = face
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 50
		gui.LightInfluence = 0
		gui.Parent = body

		local label = Instance.new("TextLabel")
		label.Name = "Symbol"
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.Font = Enum.Font.GothamBold
		label.TextScaled = true
		label.TextColor3 = Color3.fromRGB(40, 28, 16)
		label.Text = ""
		label.Parent = gui
		table.insert(labels, label)
	end
	return labels
end

local function setup(entry: Entry)
	if entry.def.kind ~= "sign" then
		return
	end
	local model = entry.model
	local labels = buildLabels(model)
	local function render()
		local text = SignRules.symbolOf(model:GetAttribute(StatNames.Symbol))
		for _, label in labels do
			label.Text = text
		end
	end
	model:SetAttribute(StatNames.Symbol, 0)
	model:GetAttributeChangedSignal(StatNames.Symbol):Connect(render)
	render()
end

local function onSign(_player: Player, entry: Entry, action: number, arg: number)
	if action ~= InteractRules.ACTIONS.symbol or not SignRules.isValid(arg) then
		return
	end
	entry.model:SetAttribute(StatNames.Symbol, arg)
end

function SignService.Start(_self)
	StructureService.onCreated(setup)
	InteractService.register("sign", onSign)
end

return SignService
