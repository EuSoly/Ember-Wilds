--!strict
-- Moldes de interface: cada tela é um molde (instâncias em
-- ReplicatedStorage.UITemplates, vindas de assets/ui) que o código clona e
-- liga por NOMES COMBINADOS. Trocar o visual = trocar o molde, sem mexer aqui.
-- Veja docs/guia/telas.md.
--
-- - clone: copia um molde (avisa se ele não existe).
-- - find: acha um elemento por nome em qualquer profundidade; se faltar (ou
--   for de outra classe) avisa UMA vez dizendo molde e nome, e quem chamou
--   segue sem aquela parte — o resto da tela continua funcionando.
-- - bind: textos por atributo TextKey, feedback de toque em todo botão e o
--   UIScale da configuração "Tamanho da interface" (ui_scale).
-- - show: abre/fecha com fade (e leve escala) pelo CanvasGroup "Root".
-- Moldes não têm scripts: toda animação e lógica ficam no código.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local StatNames = require(Shared:WaitForChild("StatNames"))
local Strings = require(Shared:WaitForChild("Strings"))

local FOLDER_NAME = "UITemplates"
local TEXT_KEY_ATTRIBUTE = "TextKey"
-- Gravado em cada cópia: o aviso de elemento faltando diz o nome do molde
-- mesmo que o código renomeie a cópia (ex. linhas de kit viram o id do kit).
local TEMPLATE_ATTRIBUTE = "TemplateName"
local UI_SCALE_SETTING = StatNames.SettingPrefix .. "ui_scale"
local ROOT_NAME = "Root"

-- Feedback de toque: 1 → 0.95 → 1 em ~0.08 s.
local PRESS_SCALE = 0.95
local PRESS_INFO = TweenInfo.new(0.04, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
-- Abrir/fechar: fade de ~0.15 s com leve escala.
local SHOW_INFO = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local SHOW_START_SCALE = 0.96
-- Nomes dos UIScale que o código cria quando o molde não tem um (se tiver,
-- o do molde é reusado: veja uiScaleOf).
local SHOW_SCALE_NAME = "ShowScale"
local PRESS_SCALE_NAME = "PressScale"
local UI_SCALE_NAME = "UIScaleSetting"

local Template = {}

local warned: { [string]: boolean } = {}
-- Cada show() ganha um número: um fechamento antigo não desliga uma tela que
-- foi reaberta no meio do fade.
local showTokens: { [Instance]: number } = {}

local function warnOnce(key: string, message: string)
	if warned[key] then
		return
	end
	warned[key] = true
	warn(message)
end

local function templateName(root: Instance): string
	local name = root:GetAttribute(TEMPLATE_ATTRIBUTE)
	return if type(name) == "string" then name else root.Name
end

-- Cópia de ReplicatedStorage.UITemplates[name], ou nil (com aviso) se não existir.
-- Não espera: o ScreenController só monta as telas depois de game.Loaded.
function Template.clone(name: string): Instance?
	local folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	local source = folder and folder:FindFirstChild(name)
	if source == nil then
		warnOnce(`clone/{name}`, `[Template] o molde "{name}" não existe em ReplicatedStorage.{FOLDER_NAME}`)
		return nil
	end
	local copy = source:Clone()
	copy:SetAttribute(TEMPLATE_ATTRIBUTE, name)
	return copy
end

-- Elemento `name` (de classe `className`, aceita subclasses: "GuiButton" vale
-- para TextButton e ImageButton) em qualquer profundidade dentro de `root`.
function Template.find(root: Instance, name: string, className: string): Instance?
	local found = root:FindFirstChild(name, true)
	if found ~= nil and found:IsA(className) then
		return found
	end
	local template = templateName(root)
	if found == nil then
		warnOnce(
			`{template}/{name}`,
			`[Template] o molde "{template}" não tem o elemento "{name}" ({className}); essa parte da tela não vai funcionar`
		)
	else
		warnOnce(
			`{template}/{name}`,
			`[Template] no molde "{template}", "{name}" é {found.ClassName} mas deveria ser {className}; essa parte da tela não vai funcionar`
		)
	end
	return nil
end

-- Escreve o texto se o elemento existe e é de texto (find pode ter devolvido nil).
function Template.setText(instance: Instance?, text: string)
	if instance ~= nil and (instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox")) then
		(instance :: any).Text = text
	end
end

local function applyTextKey(instance: Instance)
	local key = instance:GetAttribute(TEXT_KEY_ATTRIBUTE)
	if type(key) == "string" then
		Template.setText(instance, Strings.get(key))
	end
end

-- UIScale direto em `parent`: reusa o que já existir (importadores do Figma
-- costumam criar um; dois UIScale no mesmo objeto brigam), senão cria um com
-- o nome dado. Devolve também a escala que o molde já tinha (a do designer),
-- para o código multiplicar em vez de apagar o ajuste dele.
local function uiScaleOf(parent: Instance, name: string): (UIScale, number)
	local existing = parent:FindFirstChildOfClass("UIScale")
	if existing ~= nil then
		local base = existing:GetAttribute("BaseScale")
		if type(base) ~= "number" then
			base = existing.Scale
			existing:SetAttribute("BaseScale", base)
		end
		return existing, base :: number
	end
	local scale = Instance.new("UIScale")
	scale.Name = name
	scale:SetAttribute("BaseScale", 1)
	scale.Parent = parent
	return scale, 1
end

local function addPressFeedback(button: GuiButton)
	if button:GetAttribute("PressFeedback") == true then
		return -- já ligado (bind chamado duas vezes)
	end
	button:SetAttribute("PressFeedback", true)
	local scale, base = uiScaleOf(button, PRESS_SCALE_NAME)
	button.Activated:Connect(function()
		local down = TweenService:Create(scale, PRESS_INFO, { Scale = base * PRESS_SCALE })
		down.Completed:Once(function()
			TweenService:Create(scale, PRESS_INFO, { Scale = base }):Play()
		end)
		down:Play()
	end)
end

-- Aplica a configuração ui_scale num UIScale (atributo do Player: o sinal de
-- mudança chega no cliente). Usado pelas telas e pela HUD.
function Template.bindUiScale(parent: Instance)
	local player = Players.LocalPlayer
	local scale, base = uiScaleOf(parent, UI_SCALE_NAME)
	local function apply()
		local value = player:GetAttribute(UI_SCALE_SETTING)
		scale.Scale = base * (if type(value) == "number" and value > 0 then value else 1)
	end
	apply()
	local connection = player:GetAttributeChangedSignal(UI_SCALE_SETTING):Connect(apply)
	parent.Destroying:Once(function()
		connection:Disconnect()
	end)
end

-- Liga uma cópia de molde: textos (TextKey), feedback de toque nos botões e,
-- se for uma tela (ScreenGui), o UIScale do tamanho da interface — direto no
-- ScreenGui, que escala todo o conteúdo (a escala de abrir fica no Root, então
-- as duas se multiplicam sem brigar).
function Template.bind(root: Instance)
	local instances = root:GetDescendants()
	table.insert(instances, 1, root)
	for _, instance in instances do
		applyTextKey(instance)
		if instance:IsA("GuiButton") then
			addPressFeedback(instance)
		end
	end
	if root:IsA("LayerCollector") then
		Template.bindUiScale(root)
	end
end

local function rootGroup(gui: ScreenGui): CanvasGroup?
	local root = gui:FindFirstChild(ROOT_NAME)
	return if root ~= nil and root:IsA("CanvasGroup") then root else nil
end

-- Mostra/esconde a tela. Com um CanvasGroup "Root", faz fade e leve escala
-- (~0.15 s); sem ele, só liga/desliga (o molde funciona, mas sem animação).
function Template.show(gui: ScreenGui, visible: boolean)
	local token = (showTokens[gui] or 0) + 1
	showTokens[gui] = token
	local group = rootGroup(gui)
	if group == nil then
		gui.Enabled = visible
		return
	end
	local scale, base = uiScaleOf(group, SHOW_SCALE_NAME)
	if visible then
		if not gui.Enabled then
			group.GroupTransparency = 1
			scale.Scale = base * SHOW_START_SCALE
		end
		gui.Enabled = true
		TweenService:Create(group, SHOW_INFO, { GroupTransparency = 0 }):Play()
		TweenService:Create(scale, SHOW_INFO, { Scale = base }):Play()
	elseif gui.Enabled then
		local fade = TweenService:Create(group, SHOW_INFO, { GroupTransparency = 1 })
		fade.Completed:Once(function()
			if showTokens[gui] == token then
				gui.Enabled = false
			end
		end)
		fade:Play()
		TweenService:Create(scale, SHOW_INFO, { Scale = base * SHOW_START_SCALE }):Play()
	end
end

return Template
