-- Bancada das ferramentas e armas, no Studio em EDIT (sem rodar o jogo).
-- Rodar na barra de comandos (ou pelo MCP) trocando MODE:
--   "montar": cria Workspace.BancadaArmas, um boneco por modelo de
--     ReplicatedStorage.Assets.Tools segurando o item como no jogo (Tamanho e
--     Pegada aplicados; lança com as mãos do lado do corpo). Os bonecos ficam
--     travados (Locked); só o item ("Item") se seleciona.
--   Ajuste: mova, gire e redimensione o Item (Move/Rotate/Scale) até a mão
--     segurar onde você quer. A mão do boneco não muda.
--   "captar": lê cada Item e grava no modelo de Assets.Tools: o Grip passa a ser
--     o ponto e o giro em que a mão segura agora (já com a Pegada embutida, que
--     volta a 0) e o Tamanho vira a escala do Item. Só mexe nos que mudaram.
--     Depois salve o place.
--   "apagar": tira a bancada.
local MODE = "montar"

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local C = require(Shared.BonecoConfig)
local Defs = require(Shared.Defs)
local BonecoModel = require(game:GetService("StarterPlayer").StarterPlayerScripts.Client.Boneco.BonecoModel)

local BENCH = "BancadaArmas"
local ORIGIN = Vector3.new(-630, 1, 590) -- perto do nascimento; y = centro do corpo
local SPACING_X, SPACING_Z = 7, 9
local KINDS = { "pickaxe", "sword", "spear" } -- uma fileira por tipo
local TIERS = { "wood", "stone", "gold", "diamond", "amethyst", "reidite", "dragon", "lava", "pirate", "crab" }
local TOLERANCE = 1e-3

local tools = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Tools")

-- Golpe do item: o da definição, ou pelo nome para armas que ainda não são itens.
local function isThrust(id: string): boolean
	local def = Defs.Items[id]
	if def then
		return def.attackAnim == "thrust"
	end
	return id:match("_spear$") ~= nil
end

-- C0 do GripWeld na mão (igual ao BonecoModel.setHeldItem).
local function gripC0(id: string): CFrame
	local angle = if isThrust(id) then C.THRUST_REST_ANGLE else C.SWING_REST_ANGLE
	local rest = CFrame.Angles(0, -math.rad(angle), 0)
	return CFrame.fromMatrix(Vector3.zero, rest.RightVector, rest.LookVector)
end

local function numberAttr(instance: Instance, name: string, default: number): number
	local value = instance:GetAttribute(name)
	return if type(value) == "number" then value else default
end

local function anchorAll(model: Instance)
	for _, d in model:GetDescendants() do
		if d:IsA("JointInstance") or d:IsA("WeldConstraint") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = true
		end
	end
end

local function montar()
	local old = workspace:FindFirstChild(BENCH)
	if old then
		old:Destroy()
	end
	local bench = Instance.new("Model")
	bench.Name = BENCH

	for row, kind in KINDS do
		local column = 0
		for _, tier in TIERS do
			local id = `{tier}_{kind}`
			local template = tools:FindFirstChild(id)
			if template == nil then
				continue
			end
			column += 1
			local station = Instance.new("Model")
			station.Name = id

			-- Boneco na origem (frente = -Z), travado.
			local boneco = BonecoModel.build(id)
			local body = boneco.model
			body.Name = "Boneco"
			anchorAll(body)
			if isThrust(id) then
				for _, part in body:GetDescendants() do
					if part:IsA("BasePart") and (part.Name:match("^RightHand") or part.Name:match("^LeftHand")) then
						part.CFrame += Vector3.new(0, 0, C.THRUST_HOLD_BACK)
					end
				end
			end
			for _, part in body:GetDescendants() do
				if part:IsA("BasePart") then
					part.Locked = true
				end
			end
			body.Parent = station

			-- Item como no jogo: Tamanho e Pegada aplicados, Grip na mão.
			local item = template:Clone()
			item.Name = "Item"
			local scale = numberAttr(template, "Tamanho", 1)
			if scale ~= 1 then
				item:ScaleTo(item:GetScale() * scale)
			end
			local handle = item.PrimaryPart :: BasePart
			local grip = handle:FindFirstChild("Grip") :: Attachment
			local pegada = numberAttr(template, "Pegada", 0)
			if pegada ~= 0 then
				grip.CFrame *= CFrame.new(0, pegada * scale, 0)
			end
			anchorAll(item)
			local hand = body:FindFirstChild("RightHand") :: BasePart
			local target = hand.CFrame * gripC0(id) * grip.CFrame:Inverse()
			item:PivotTo(target * handle.CFrame:ToObjectSpace(item:GetPivot()))
			item.Parent = station

			-- Fileira por tipo; todos olhando para +Z (para quem chega pelo nascimento).
			local position = ORIGIN + Vector3.new((column - 5) * SPACING_X, 0, (row - 2) * SPACING_Z)
			station:PivotTo(CFrame.lookAt(position, position + Vector3.zAxis))
			station.Parent = bench
		end
	end

	bench.Parent = workspace
	local visuals = workspace:FindFirstChild("BonecoVisuals")
	if visuals and #visuals:GetChildren() == 0 then
		visuals:Destroy()
	end
	local camera = workspace.CurrentCamera
	camera.CFrame = CFrame.lookAt(ORIGIN + Vector3.new(0, 45, 40), ORIGIN)
	return `bancada montada: {#bench:GetChildren()} itens`
end

local function captar()
	local bench = workspace:FindFirstChild(BENCH)
	assert(bench, "monte a bancada antes (MODE = montar)")
	local changed = {}
	for _, station in bench:GetChildren() do
		local id = station.Name
		local template = tools:FindFirstChild(id)
		local item = station:FindFirstChild("Item")
		local body = station:FindFirstChild("Boneco")
		if template == nil or item == nil or body == nil then
			continue
		end
		local handle = item.PrimaryPart or item:FindFirstChild("Handle")
		local base = template.PrimaryPart
		local hand = body:FindFirstChild("RightHand")
		if handle == nil or base == nil or hand == nil then
			continue
		end
		local grip = base:FindFirstChild("Grip") :: Attachment

		-- Escala = tamanho do Handle agora / do modelo importado (Scale no
		-- Model ou no próprio MeshPart dão no mesmo).
		local ratio = handle.Size / base.Size
		local scale = (ratio.X + ratio.Y + ratio.Z) / 3
		if math.abs(ratio.X - ratio.Y) > 0.01 or math.abs(ratio.Y - ratio.Z) > 0.01 then
			warn(`[bancada] {id}: redimensionado sem manter a proporção; usando a média {scale}`)
		end
		-- Onde a mão está, no espaço do Handle de agora, de volta à escala 1.
		local local_ = handle.CFrame:ToObjectSpace(hand.CFrame * gripC0(id))
		local newGrip = CFrame.new(local_.Position / scale) * local_.Rotation

		local oldScale = numberAttr(template, "Tamanho", 1)
		local oldPegada = numberAttr(template, "Pegada", 0)
		local oldGrip = grip.CFrame * CFrame.new(0, oldPegada, 0)
		local _, turned = oldGrip.Rotation:ToObjectSpace(newGrip.Rotation):ToAxisAngle()
		local moved = (oldGrip.Position - newGrip.Position).Magnitude > TOLERANCE or math.abs(turned) > TOLERANCE
		local resized = math.abs(scale - oldScale) > TOLERANCE
		if moved or resized or oldPegada ~= 0 then
			grip.CFrame = newGrip
			template:SetAttribute("Pegada", 0)
			template:SetAttribute("Tamanho", math.round(scale * 1000) / 1000)
			table.insert(changed, `{id} (Tamanho {template:GetAttribute("Tamanho")})`)
		end
	end
	table.sort(changed)
	if #changed == 0 then
		return "nada mudou"
	end
	return `gravados {#changed}: {table.concat(changed, ", ")}. Salve o place.`
end

if MODE == "montar" then
	return montar()
elseif MODE == "captar" then
	return captar()
elseif MODE == "apagar" then
	local bench = workspace:FindFirstChild(BENCH)
	if bench then
		bench:Destroy()
	end
	return "bancada apagada"
end
error(`MODE desconhecido: {MODE}`)
