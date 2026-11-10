--!strict
-- Brilho de "carregando" por cima de um quadradinho 3D (skins dos Cosméticos e
-- da loja) enquanto a malha ou a textura dele ainda não baixou: a tela de
-- carregamento só espera a interface, e o resto chega em segundo plano
-- (Shared/AssetPreload). Some sozinho quando tudo do modelo chegou, ou depois
-- de TIMEOUT (para nunca ficar piscando para sempre).
--
-- Mesmo com tudo baixado, na primeira vez que um item aparece num
-- ViewportFrame o quadro fica vazio por ~1 s (só os olhos do boneco, até nas
-- skins só de cor, feitas de peças simples; visto no Studio em 10/11/2026). Não
-- há sinal de quando isso termina, então na primeira vez de cada item na sessão
-- o brilho fica FIRST_VIEW.
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")

local CHECK_EVERY = 0.25 -- s entre conferências
local TIMEOUT = 20 -- s no máximo com o brilho
local FIRST_VIEW = 0.9 -- s de brilho na primeira vez de cada item (malha saindo do disco)
local SWEEP = TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1)

local LoadingShimmer = {}

local seen: { [string]: true } = {} -- itens que já apareceram nesta sessão

-- Ids de conteúdo (malha e textura) das peças do modelo.
local function contentOf(model: Instance): { string }
	local ids: { string } = {}
	local function add(id: string)
		if id ~= "" then
			table.insert(ids, id)
		end
	end
	for _, d in model:GetDescendants() do
		if d:IsA("MeshPart") then
			add(d.MeshId)
			add(d.TextureID)
		elseif d:IsA("SpecialMesh") then
			add(d.MeshId)
			add(d.TextureId)
		end
	end
	return ids
end

local function allLoaded(ids: { string }): boolean
	for _, id in ids do
		local ok, status = pcall(ContentProvider.GetAssetFetchStatus, ContentProvider, id)
		-- Falhou de vez também conta como "pronto": não há o que esperar.
		if ok and status ~= Enum.AssetFetchStatus.Success and status ~= Enum.AssetFetchStatus.Failure then
			return false
		end
	end
	return true
end

-- Põe o brilho em `container` até as artes de `model` chegarem (e, na
-- primeira vez do item `key` na sessão, pelo menos FIRST_VIEW).
function LoadingShimmer.watch(container: GuiObject, model: Instance, key: string)
	local ids = contentOf(model)
	local firstView = not seen[key]
	seen[key] = true
	if not firstView and allLoaded(ids) then
		return
	end
	local overlay = Instance.new("Frame")
	overlay.Name = "LoadingShimmer"
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.new(1, 1, 1)
	overlay.BackgroundTransparency = 0
	overlay.BorderSizePixel = 0
	overlay.ZIndex = 20
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.12, 0)
	corner.Parent = overlay
	-- Uma faixa clara atravessando o quadro, sem parar.
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 20
	-- Véu claro no quadro todo e uma faixa mais forte atravessando.
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.7),
		NumberSequenceKeypoint.new(0.4, 0.7),
		NumberSequenceKeypoint.new(0.5, 0.25),
		NumberSequenceKeypoint.new(0.6, 0.7),
		NumberSequenceKeypoint.new(1, 0.7),
	})
	gradient.Offset = Vector2.new(-1, 0)
	gradient.Parent = overlay
	overlay.Parent = container
	local sweep = TweenService:Create(gradient, SWEEP, { Offset = Vector2.new(1, 0) })
	sweep:Play()

	task.spawn(function()
		local started = os.clock()
		while overlay.Parent ~= nil and os.clock() - started < TIMEOUT do
			local minimum = if firstView then FIRST_VIEW else 0
			if os.clock() - started >= minimum and allLoaded(ids) then
				break
			end
			task.wait(CHECK_EVERY)
		end
		sweep:Cancel()
		overlay:Destroy()
	end)
end

return LoadingShimmer
