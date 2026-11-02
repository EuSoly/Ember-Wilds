-- Modelos provisórios das espadas e lanças (madeira, pedra, ouro) em
-- ReplicatedStorage.Assets.Tools, no formato que o ToolModel usa: Tool com
-- Handle (PrimaryPart) e Attachment "Grip" (Y = para a frente, X = lado).
-- Não substitui um modelo que já exista com o mesmo nome (os do Elizeu ficam).
-- Rodar no Studio (Edit, barra de comandos ou MCP) e salvar o place.
local TIER_COLOR = {
	wood = Color3.fromHex("9C6B3C"),
	stone = Color3.fromHex("8E9AA5"),
	gold = Color3.fromHex("F2C230"),
}
local HANDLE_COLOR = Color3.fromHex("5A3A22")

local function part(tool: Instance, name: string, size: Vector3, offset: CFrame, color: Color3): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = offset
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Anchored = false
	p.CanCollide, p.CanQuery, p.CanTouch = false, false, false
	p.Massless = true
	p.Parent = tool
	return p
end

local function weld(handle: BasePart, other: BasePart)
	local w = Instance.new("WeldConstraint")
	w.Part0, w.Part1 = handle, other
	w.Parent = handle
end

local function build(id: string, kind: string, tier: string): Tool
	local tool = Instance.new("Tool")
	tool.Name = id
	tool.RequiresHandle = false
	local color = TIER_COLOR[tier]
	local handle: Part
	if kind == "sword" then
		handle = part(tool, "Handle", Vector3.new(0.3, 1, 0.3), CFrame.new(), HANDLE_COLOR)
		weld(handle, part(tool, "Guard", Vector3.new(1, 0.2, 0.25), CFrame.new(0, 0.6, 0), HANDLE_COLOR))
		weld(handle, part(tool, "Blade", Vector3.new(0.4, 2.6, 0.12), CFrame.new(0, 2, 0), color))
		weld(handle, part(tool, "Tip", Vector3.new(0.25, 0.3, 0.12), CFrame.new(0, 3.45, 0), color))
	else
		handle = part(tool, "Handle", Vector3.new(0.22, 4.4, 0.22), CFrame.new(), HANDLE_COLOR)
		weld(handle, part(tool, "Head", Vector3.new(0.5, 0.9, 0.12), CFrame.new(0, 2.65, 0), color))
		weld(handle, part(tool, "Point", Vector3.new(0.25, 0.35, 0.12), CFrame.new(0, 3.25, 0), color))
	end
	local grip = Instance.new("Attachment")
	grip.Name = "Grip"
	-- Onde a mão segura: perto do fim do cabo (a lança mais para trás).
	grip.CFrame = CFrame.new(0, if kind == "sword" then -0.2 else -1, 0)
	grip.Parent = handle
	tool.PrimaryPart = handle
	return tool
end

local tools = game:GetService("ReplicatedStorage").Assets.Tools
local made = {}
for _, tier in { "wood", "stone", "gold" } do
	for _, kind in { "sword", "spear" } do
		local id = `{tier}_{kind}`
		if tools:FindFirstChild(id) == nil then
			build(id, kind, tier).Parent = tools
			table.insert(made, id)
		end
	end
end
print(`[make-weapon-placeholders] criados: {table.concat(made, ", ")}`)
return made
