--!strict
-- Ficha do item no livro de receitas (versão mínima: o nome no papel; a
-- completa vem na etapa 6 do plano).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Defs = require(Shared:WaitForChild("Defs"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local Rustic = require(script.Parent:WaitForChild("Rustic"))

export type Props = {
	item: () -> string?,
	onShow: (string) -> (),
	Position: UDim2,
	Size: UDim2,
}

local function BookSheet(props: Props): Frame
	return Rustic.paper({
		Name = "Sheet",
		Position = props.Position,
		Size = props.Size,
		Rustic.label({
			dark = true,
			Name = "ItemName",
			Position = UDim2.fromOffset(20, 16),
			Size = UDim2.new(1, -40, 0, 30),
			FontFace = Theme.font.number,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = function()
				local id = props.item()
				local def = id and Defs.Items[id]
				return if def then Strings.get(def.nameKey) else ""
			end,
			maxSize = 24,
		}),
	})
end

return BookSheet
