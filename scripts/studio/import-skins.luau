-- Organiza os FBX de skins (skins-corpo, skins-mochilas, skins-livros) importados
-- no Workspace ou ReplicatedStorage para dentro de:
--   ReplicatedStorage.Assets.Skins/<skinId>/<partName>
--   ReplicatedStorage.Assets.Bags/<skinId>/<partName>
--   ReplicatedStorage.Assets.Books/<skinId>/<partName>
-- Ajusta Neon, transparência e posição em relação ao pivô a partir do SkinManifest.
-- Nota: o CosmeticService já chama isso automaticamente quando você dá Play no Studio,
-- mas você também pode rodar na Barra de Comandos no modo Edit para já salvar no place.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SkinAssets = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Models"):WaitForChild("SkinAssets"))

local count = SkinAssets.organizeStudioImports()
print(`[import-skins] {count} malhas organizadas em ReplicatedStorage.Assets.\{Skins,Bags,Books}`)
return count
