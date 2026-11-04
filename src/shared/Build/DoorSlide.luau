--!strict
-- Conta pura da porta do modelo do Elizeu (G8): ao abrir, cada folha
-- (*_panel_left / *_panel_right) desliza para fora do centro da porta, na
-- direção do próprio centro, a largura dela nessa direção. Tudo no XZ local
-- da porta (o pivô da peça é o centro do chão). Quem mexe nas peças é o
-- StructureModel.setOpen.

local DoorSlide = {}

-- Folha mais perto que isto do centro não tem direção: fica parada.
local MIN_OFFSET = 1e-3

-- Deslocamento (dx, dz) da folha aberta. (px, pz): centro da folha em relação
-- ao centro da porta; (sizeX, sizeZ): medida da folha nos eixos X e Z da porta.
-- A largura na direção unitária (ux, uz) é |ux|·sizeX + |uz|·sizeZ.
function DoorSlide.offset(px: number, pz: number, sizeX: number, sizeZ: number): (number, number)
	local length = math.sqrt(px * px + pz * pz)
	if not (length > MIN_OFFSET and length < math.huge) then
		return 0, 0
	end
	local ux, uz = px / length, pz / length
	local width = math.abs(ux) * sizeX + math.abs(uz) * sizeZ
	if not (width >= 0 and width < math.huge) then
		return 0, 0
	end
	return ux * width, uz * width
end

return DoorSlide
