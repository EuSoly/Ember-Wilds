# Builds baseadas nas paredes do projeto

Arquivo para revisar e editar: `builds-editaveis.blend`, cena `Builds_Catalog_24`.

São 18 modelos novos: seis espinhos, seis portas e seis portas com espinhos. O catálogo inclui também seis cópias das paredes do usuário como referência. O arquivo original `C:/Users/Elize/Desktop/Roblox/Assets/recursos.blend` não foi sobrescrito.

## Organização

- `Walls_Reference`: cópias das paredes, sem alteração de formas ou materiais.
- `Spikes`: madeira, pedra, ouro, diamante, ametista e reidite.
- `Doors`: seis portas com duas metades móveis.
- `SpikeDoors`: seis portas com espinhos acompanhando as metades móveis.
- `Builds_Presentation`: fundo, textos, luzes e câmera; bloqueados para seleção.

Os IDs seguem o padrão do projeto: `wood_wall`, `wood_spike`, `wood_door`, `wood_spike_door`, etc. Cada construção tem um `<id>_root` na base, com escala aplicada às malhas. Os espinhos, cristais, engastes, alças e reforços são peças editáveis separadas.

Os modelos foram posicionados com a base em Z = 0. A geometria e os materiais dos modelos originais foram mantidos nas cópias; somente a apresentação foi reposicionada.

## Portas

As duas folhas são `<id>_panel_left` e `<id>_panel_right`. Alças, cristais e espinhos estão parentados à folha correspondente. As propriedades personalizadas `open_translation` registram a sugestão de deslocamento em X: -2.25 para a esquerda e +2.25 para a direita. O arquivo abre com as portas fechadas.

Essa abertura em duas folhas é uma adaptação 3D. A referência da wiki fornece a base circular, os tiers e a distinção entre parede, porta e espinhos. Não há lógica de abertura, dano ou colisão implementada no Roblox nesta entrega.

## Validação

`manifest.json` lista todas as peças e os triângulos. Como as paredes originais têm superfícies separadas por material, foi feita uma soldagem apenas em memória para conferir que o conjunto é fechado. As metades novas das portas e os detalhes novos são malhas fechadas. `door-opening-validation.json` registra o teste de abertura das seis portas com espinhos.

Referência: https://starveiopro.fandom.com/wiki/Structures

`builds-trabalho.blend` preserva também a cena original de recursos. `source-snapshot.blend` é a cópia de segurança anterior à criação.
