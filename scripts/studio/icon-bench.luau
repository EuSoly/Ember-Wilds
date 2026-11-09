-- Bancada dos ícones do inventário (Studio, em Edit).
--
-- Fica no place como ModuleScript ServerStorage.BancadaIcones (o ServerStorage
-- não é do Rojo). Na barra de comando:
--   require(game.ServerStorage.BancadaIcones)()      monta (ou remonta) a bancada
--   require(game.ServerStorage.BancadaIcones)(true)  apaga a bancada
-- Para instalar/atualizar o ModuleScript, copie este arquivo para o Source dele.
--
-- Monta StarterGui.BancadaIcones: uma grade com o ícone de TODOS os itens
-- (Defs.Items) e de todo modelo em Assets.Icons, Tools e Structures que ainda
-- não é item (outros tiers), com o id embaixo. Para ajustar a vista de um item, selecione o molde dele
-- (ReplicatedStorage.Assets.Icons/<id>, Tools/<id> ou Structures/<id>) e crie
-- ou edite no Properties os atributos (o ícone da grade muda ao vivo):
--   IconeGiro    Vector3 em graus (X inclina, Y gira em volta da vertical, Z gira na tela)
--   IconeZoom    número (1 = enche o quadro; maior = mais perto)
--   IconeDesloca Vector2 em frações do quadro (X direita, Y cima)
-- Os atributos vivem no place: salve o place depois de ajustar.
--
-- Apague a bancada antes de publicar (ela não deve ir para o jogo).
return function(apagar: boolean?): string
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local StarterGui = game:GetService("StarterGui")
	local StarterPlayer = game:GetService("StarterPlayer")

	local NAME = "BancadaIcones"
	local old = StarterGui:FindFirstChild(NAME)
	if old then
		old:Destroy()
	end
	if apagar then
		return "bancada apagada"
	end

	local Defs = require(ReplicatedStorage.Shared.Defs)
	local vide = require(ReplicatedStorage.Packages.Vide)
	-- O Studio guarda o require em cache na barra de comando: uma cópia ao lado do
	-- original (mesmo pai, para os requires relativos) carrega sempre o código atual.
	local original = StarterPlayer.StarterPlayerScripts.Client.UI.ItemIcon
	local fresh = original:Clone()
	fresh.Name = "ItemIconBancada"
	fresh.Parent = original.Parent
	local ok, loaded = pcall(require, fresh)
	fresh:Destroy()
	assert(ok, loaded)
	local ItemIcon = loaded

	-- Ids: itens do jogo (por categoria) e depois os ícones que ainda não são item.
	local ids, seen = {}, {}
	local items = {}
	for id, def in Defs.Items do
		table.insert(items, { id = id, category = def.category })
	end
	table.sort(items, function(a, b)
		if a.category ~= b.category then
			return a.category < b.category
		end
		return a.id < b.id
	end)
	for _, item in items do
		table.insert(ids, item.id)
		seen[item.id] = true
	end
	-- Modelos que ainda não são item (outros tiers, ícones novos), por pasta.
	for _, folderName in { "Icons", "Tools", "Structures" } do
		local extra = {}
		for _, model in ReplicatedStorage.Assets[folderName]:GetChildren() do
			if not seen[model.Name] then
				table.insert(extra, model.Name)
				seen[model.Name] = true
			end
		end
		table.sort(extra)
		for _, id in extra do
			table.insert(ids, id)
		end
	end

	local CELL = 84
	local gui = Instance.new("ScreenGui")
	gui.Name = NAME
	gui.ResetOnSpawn = false
	gui.Archivable = false -- não salva com o place nem vai para o Play
	local frame = Instance.new("ScrollingFrame")
	frame.Size = UDim2.new(1, -40, 1, -40)
	frame.Position = UDim2.fromOffset(20, 20)
	frame.BackgroundColor3 = Color3.fromRGB(60, 45, 35)
	frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	frame.CanvasSize = UDim2.new()
	frame.ScrollBarThickness = 10
	frame.Parent = gui
	local padding = Instance.new("UIPadding")
	padding.PaddingTop, padding.PaddingLeft = UDim.new(0, 8), UDim.new(0, 8)
	padding.Parent = frame
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(CELL, CELL + 16)
	grid.CellPadding = UDim2.fromOffset(6, 6)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = frame

	vide.root(function()
		for index, id in ids do
			local cell = Instance.new("Frame")
			cell.Name = id
			cell.LayoutOrder = index
			cell.BackgroundTransparency = 1
			cell.Parent = frame
			local holder = Instance.new("Frame")
			holder.Size = UDim2.fromOffset(CELL, CELL)
			holder.BackgroundTransparency = 1
			holder.Parent = cell
			ItemIcon({
				item = function()
					return { id = id, count = 1 }
				end,
			}).Parent = holder
			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(1, 0, 0, 16)
			label.Position = UDim2.fromOffset(0, CELL)
			label.BackgroundTransparency = 1
			label.TextColor3 = Color3.new(1, 1, 1)
			label.TextScaled = true
			label.Font = Enum.Font.GothamMedium
			label.Text = id
			label.Parent = cell
		end
	end)

	gui.Parent = StarterGui
	return `bancada com {#ids} ícones em StarterGui.{NAME}`
end
