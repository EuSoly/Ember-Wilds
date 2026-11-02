--!strict
-- Liga o boneco visual: cada personagem com a tag Boneco ganha, neste cliente,
-- um boneco que o segue e anima (veja src/client/Boneco/BonecoRenderer).
local BonecoRenderer = require(script.Parent.Parent:WaitForChild("Boneco"):WaitForChild("BonecoRenderer"))
local MobRenderer = require(script.Parent.Parent:WaitForChild("Mobs"):WaitForChild("MobRenderer"))

local BonecoController = {}

function BonecoController.Start(_self)
	BonecoRenderer.start()
	MobRenderer.start()
end

return BonecoController
