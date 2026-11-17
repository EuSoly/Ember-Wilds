--!strict
-- Raiz do HUD: o ScreenGui onde todos os componentes do jogo são montados.
-- Para adicionar um componente ao HUD, crie o arquivo em UI/ e coloque-o na
-- lista de filhos abaixo.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local ScreenFlow = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("UIFlow"):WaitForChild("ScreenFlow"))
local ScreenState = require(script.Parent.Parent:WaitForChild("ScreenState"))
local AimStick = require(script.Parent:WaitForChild("AimStick"))
local Backpack = require(script.Parent:WaitForChild("Backpack"))
local ChestPanel = require(script.Parent:WaitForChild("ChestPanel"))
local CratePanel = require(script.Parent:WaitForChild("CratePanel"))
local Clock = require(script.Parent:WaitForChild("Clock"))
local CraftColumn = require(script.Parent:WaitForChild("CraftColumn"))
local DragGhost = require(script.Parent:WaitForChild("DragGhost"))
local GhostPanel = require(script.Parent:WaitForChild("GhostPanel"))
local Hotbar = require(script.Parent:WaitForChild("Hotbar"))
local HudBottom = require(script.Parent:WaitForChild("HudBottom"))
local InteractPanel = require(script.Parent:WaitForChild("InteractPanel"))
local ItemTooltip = require(script.Parent:WaitForChild("ItemTooltip"))
local Minimap = require(script.Parent:WaitForChild("Minimap"))
local MissionsButton = require(script.Parent:WaitForChild("MissionsButton"))
local Notifications = require(script.Parent:WaitForChild("Notifications"))
local RecipeBookButton = require(script.Parent:WaitForChild("RecipeBookButton"))
local RotateButton = require(script.Parent:WaitForChild("RotateButton"))
local ScorePill = require(script.Parent:WaitForChild("ScorePill"))
local SettingsButton = require(script.Parent:WaitForChild("SettingsButton"))
local StatusRings = require(script.Parent:WaitForChild("StatusRings"))
local TeamPanel = require(script.Parent:WaitForChild("TeamPanel"))
local TutorialPanel = require(script.Parent:WaitForChild("TutorialPanel"))
local PinnedRecipe = require(script.Parent:WaitForChild("PinnedRecipe"))
local Template = require(script.Parent.Parent:WaitForChild("UITemplates"):WaitForChild("Template"))
local WeaponLock = require(script.Parent:WaitForChild("WeaponLock"))
local XpBoostBadge = require(script.Parent:WaitForChild("XpBoostBadge"))

local create = vide.create

local function App(): ScreenGui
	-- Componentes do HUD, na ordem em que são desenhados.
	local children: { Instance } = {
		ScorePill(),
		CraftColumn(),
		Clock(),
		XpBoostBadge(), -- entre o selo de pontos e o relógio
		Minimap(),
		SettingsButton(),
		RecipeBookButton(),
		MissionsButton(),
		TutorialPanel(),
		PinnedRecipe(),
		GhostPanel(),
		TeamPanel(),
		-- Presos à hotbar (posições em HudBottom): anéis logo acima dela; a
		-- trava da arma e a mochila dos lados dos anéis; baú, caixa e peça
		-- acima dos anéis.
		Hotbar({
			StatusRings() :: Instance,
			WeaponLock(),
			Backpack.Button(),
			ChestPanel(),
			CratePanel(),
			InteractPanel(),
		}),
		-- Depois da hotbar: no celular os avisos passam por cima dos painéis
		-- que sobem até o topo central.
		Notifications.Component(),
		AimStick(),
		RotateButton(),
		Backpack.Panel(),
		ItemTooltip(),
		DragGhost(), -- por último: o item arrastado fica por cima de tudo
	}

	local hud = create("ScreenGui")({
		Name = "Hud",
		ResetOnSpawn = false, -- o HUD sobrevive ao respawn
		-- Só jogando: no carregamento, menu e morte quem aparece são as telas.
		Enabled = function()
			return ScreenFlow.hudVisible(ScreenState.current())
		end,
		IgnoreGuiInset = false,
		-- Desvia da barra superior do Roblox e do notch do celular.
		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		children,
	}) :: ScreenGui
	-- Mesmo "Tamanho da interface" (ui_scale) das telas de molde.
	Template.bindUiScale(hud)
	-- Mede a área do HUD (depois do UIScale) para a faixa de baixo no toque.
	HudBottom.bind(hud)
	return hud
end

return App
