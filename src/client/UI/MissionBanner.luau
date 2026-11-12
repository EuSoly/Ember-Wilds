--!strict
-- Faixa de aviso das Missões: desce do topo em 0,4 s com o nome da missão que
-- completou (ou da chrono quest que falhou), fica 2,5 s e sobe. Um aviso por
-- vez, na ordem (MissionsState.takeNotice, num laço próprio: animar de dentro
-- de um vide.effect travava a fila no Studio). Aparece no menu e no jogo.
-- Arte em MissionImages (BANNER_DONE / BANNER_FAILED); sem arte, uma placa.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Defs = require(Shared:WaitForChild("Defs"))
local MissionImages = require(Shared:WaitForChild("MissionImages"))
local MissionView = require(Shared:WaitForChild("UIFlow"):WaitForChild("MissionView"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local Client = script.Parent.Parent
local MissionsState = require(Client:WaitForChild("MissionsState"))
local SoundPlayer = require(Client:WaitForChild("Audio"):WaitForChild("SoundPlayer"))
local Rustic = require(script.Parent:WaitForChild("Rustic"))

local create = vide.create
local R = Theme.rustic

local SLIDE = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local HIDE = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local STAY_SECONDS = 2.5
local SHOWN = UDim2.new(0.5, 0, 0, 132) -- abaixo do relógio do HUD
-- Bem acima: a área segura começa abaixo da barra do Roblox, e o que fica
-- acima dela ainda aparece (o pé da faixa aparecia no topo da tela).
local HIDDEN = UDim2.new(0.5, 0, 0, -320)

local MissionBanner = {}

-- Nome da missão do aviso (Kind 1 Partida, 2/3 diária/semanal, 4 conquista).
local function nameOf(notice: MissionsState.Notice): string
	if notice.Id == "inventory_full" then
		return ""
	elseif notice.Kind == 1 then
		local quest = Defs.Quests[notice.Id]
		return if quest then Strings.get(quest.nameKey) else notice.Id
	elseif notice.Id == "final" then
		return Strings.format("missions.final", { n = 3 })
	elseif notice.Kind == 4 then
		local achievement = Defs.Achievements[notice.Id]
		return if achievement then Strings.get(achievement.nameKey) else notice.Id
	end
	local mission = Defs.Missions[notice.Id]
	return if mission then MissionView.missionName(mission.id, mission.target) else notice.Id
end

function MissionBanner.mount(playerGui: Instance): ScreenGui
	local P = MissionImages.PIECES
	local title = vide.source("")
	local subtitle = vide.source("")
	local done = vide.source(true)

	local banner = create("Frame")({
		Name = "Banner",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = HIDDEN,
		Visible = false, -- só durante o aviso
		Size = UDim2.new(0.42, 0, 0, 96),
		BackgroundTransparency = 1,
		create("UISizeConstraint")({ MinSize = Vector2.new(260, 70), MaxSize = Vector2.new(520, 120) }),
		create("ImageLabel")({
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ScaleType = Enum.ScaleType.Fit,
			Image = function()
				return if done() then P.BANNER_DONE.image else P.BANNER_FAILED.image
			end,
			Visible = P.BANNER_DONE.image ~= "",
		}),
		Rustic.plate({
			Size = UDim2.fromScale(1, 0.8),
			Position = UDim2.fromScale(0, 0.1),
			Visible = P.BANNER_DONE.image == "",
		}),
		Rustic.label({
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.2),
			Size = UDim2.fromScale(0.7, 0.32),
			FontFace = Theme.font.title,
			Text = title,
			maxSize = 24,
			ZIndex = 3,
			create("UIStroke")({ Color = R.outline, Thickness = 2 }),
		}),
		Rustic.label({
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.54),
			Size = UDim2.fromScale(0.66, 0.24),
			Text = subtitle,
			maxSize = 16,
			ZIndex = 3,
			create("UIStroke")({ Color = R.outline, Thickness = 1.5 }),
		}),
	}) :: Frame

	local function show(notice: MissionsState.Notice)
		done(notice.Done)
		local key = if notice.Id == "inventory_full"
			then "missions.inventory_full"
			elseif notice.Done then "missions.banner.done"
			else "missions.banner.failed"
		title(Strings.get(key))
		subtitle(nameOf(notice))
		SoundPlayer.play(if notice.Done then "notify_success" else "notify_alert")
		banner.Position = HIDDEN
		banner.Visible = true
		TweenService:Create(banner, SLIDE, { Position = SHOWN }):Play()
		task.wait(SLIDE.Time + STAY_SECONDS)
		TweenService:Create(banner, HIDE, { Position = HIDDEN }):Play()
		task.wait(HIDE.Time)
		banner.Visible = false
	end

	task.spawn(function()
		while true do
			local notice = MissionsState.takeNotice()
			if notice then
				local ok, err = pcall(function()
					show(notice)
				end)
				if not ok then
					warn(`[MissionBanner] {err}`)
				end
			else
				task.wait(0.25)
			end
		end
	end)

	local gui = create("ScreenGui")({
		Name = "MissionBanner",
		ResetOnSpawn = false,
		DisplayOrder = 25, -- acima das janelas
		IgnoreGuiInset = false,
		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
		banner,
	}) :: ScreenGui
	gui.Parent = playerGui
	return gui
end

return MissionBanner
