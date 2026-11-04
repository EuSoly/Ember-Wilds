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

-- true se a imagem já tem id.
function UiImages.has(id: string): boolean
	return id ~= ""
end

return table.freeze(UiImages)
