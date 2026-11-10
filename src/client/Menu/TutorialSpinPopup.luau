--!strict
-- Pop-up da roleta depois do tutorial: na primeira vez no menu depois de
-- completar (quando a vida do tutorial acaba, ou numa sessão nova), "Você tem
-- 2 giros!" com Ir para a roleta (abre a loja na seção de giros) ou Depois.
-- Aparece uma vez: qualquer botão avisa o servidor (TutorialPopupSeen), que
-- apaga o pendente do perfil. Sem giros normais (já gastou), não aparece.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local Client = script.Parent.Parent
local Net = require(Client:WaitForChild("Net"))
local ShopData = require(Client:WaitForChild("ShopData"))
local TutorialState = require(Client:WaitForChild("TutorialState"))
local Rustic = require(Client:WaitForChild("UI"):WaitForChild("Rustic"))
local MenuState = require(script.Parent:WaitForChild("MenuState"))

local create = vide.create
local R = Theme.rustic

local WIDTH, HEIGHT = 420, 230 -- px lógicos da janela
local BUTTON_HEIGHT = 52

local TutorialSpinPopup = {}

function TutorialSpinPopup.build(): Frame
	-- Some na hora ao clicar (sem esperar o servidor apagar o pendente).
	local dismissed = vide.source(false)
	local visible = function()
		return TutorialState.popupPending()
			and not dismissed()
			and ShopData.spins("normal") > 0
			and MenuState.panel() ~= "shop"
	end
	local function close()
		dismissed(true)
		Net.TutorialPopupSeen.Fire()
	end

	return create("Frame")({
		Name = "TutorialSpinPopup",
		Visible = visible,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = R.outline,
		BackgroundTransparency = 0.45,
		BorderSizePixel = 0,
		ZIndex = 20,
		Active = true, -- não deixa clicar no menu por trás
		Rustic.paper({
			Name = "Window",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(WIDTH, HEIGHT),
			ZIndex = 21,
			create("UIPadding")({
				PaddingLeft = UDim.new(0, 24),
				PaddingRight = UDim.new(0, 24),
				PaddingTop = UDim.new(0, 18),
				PaddingBottom = UDim.new(0, 18),
			}),
			Rustic.label({
				Name = "Title",
				Size = UDim2.new(1, 0, 0, 44),
				FontFace = Theme.font.title,
				TextColor3 = R.emberShadow,
				ZIndex = 22,
				maxSize = 34,
				Text = function()
					return Strings.format("tutorial.popup.title", { spins = ShopData.spins("normal") })
				end,
			}),
			Rustic.label({
				Name = "Body",
				dark = true,
				Position = UDim2.fromOffset(0, 52),
				Size = UDim2.new(1, 0, 0, 52),
				TextWrapped = true,
				ZIndex = 22,
				maxSize = 22,
				Text = Strings.get("tutorial.popup.body"),
			}),
			Rustic.button({
				Name = "Later",
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.fromScale(0, 1),
				Size = UDim2.new(0.4, -6, 0, BUTTON_HEIGHT),
				ZIndex = 22,
				kind = "leather",
				text = Strings.get("tutorial.popup.later"),
				Activated = close,
			}),
			Rustic.button({
				Name = "Go",
				AnchorPoint = Vector2.new(1, 1),
				Position = UDim2.fromScale(1, 1),
				Size = UDim2.new(0.6, -6, 0, BUTTON_HEIGHT),
				ZIndex = 22,
				kind = "ember",
				text = Strings.get("tutorial.popup.go"),
				Activated = function()
					close()
					MenuState.openShop("spins")
				end,
			}),
		}),
	}) :: Frame
end

return TutorialSpinPopup
