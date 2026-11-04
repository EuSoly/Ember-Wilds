--!strict
-- Ids das imagens da interface, num lugar só. As fontes ficam em
-- assets/ui/brand/ (PNG transparente); foram enviadas ao Roblox na conta do
-- Elizeu (dona do jogo). Para trocar uma imagem: envie o PNG novo (Studio →
-- Asset Manager ou Creator Hub), cole o id aqui e, para o carregamento, também
-- no src/first/LoadingScreen.model.json (ele roda antes deste módulo chegar ao
-- cliente, por isso tem os ids escritos no próprio molde).
-- Id vazio ("") = imagem ainda não enviada: as telas continuam funcionando.
local UiImages = {}

UiImages.LOGO = "rbxassetid://110501947889426" -- ember-wilds-logo.png (1200x804)
UiImages.SUN = "rbxassetid://93155220034712" -- sun.png (512x512)
UiImages.MOON = "rbxassetid://133419039593412" -- moon.png (512x512)
-- Menu (imagens do Elizeu, geradas por IA e recortadas em assets/ui/brand/).
UiImages.TREE = "rbxassetid://86162431826625" -- menu-tree.png (589x916): tronco e copa atrás da coluna
UiImages.BRANCH = "rbxassetid://120915569400391" -- menu-branch.png (584x222): galho do card da Golden Ember
UiImages.COIN = "rbxassetid://117768520906030" -- golden-ember.png (256x256): ícone da moeda
UiImages.PLANK = "rbxassetid://72342906066027" -- plank-wood.png (480x178): placa de madeira com pregos
-- Placa em 9 partes: as pontas (com os pregos) não esticam; só o miolo estica.
UiImages.PLANK_SIZE = Vector2.new(480, 178)
UiImages.PLANK_SLICE = Rect.new(66, 52, 414, 126)

-- true se a imagem já tem id.
function UiImages.has(id: string): boolean
	return id ~= ""
end

return table.freeze(UiImages)
