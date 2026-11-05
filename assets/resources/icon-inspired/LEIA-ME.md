# Depósitos do mapa inspirados nos ícones de inventário

Seis modelos de depósito: pedra, ouro, diamante, ametista, reidite e esmeralda. A silhueta dos cinco primeiros foi extraída da projeção dos modelos da coleção `viewport` do usuário. Esses depósitos mantêm a identidade dos ícones, com altura e relevo para uso no mapa.

Não havia ícone de esmeralda nessa coleção: a esmeralda é uma proposta nova de três volumes angulares verdes, identificada como tal na comparação.

## Arquivos

- `minerios-icones-editaveis.blend`: seis novos depósitos, cópias dos ícones para comparação e apresentação.
- `minerios-icones-trabalho.blend`: cópia de trabalho com todas as cenas anteriores preservadas.
- `before-icon-deposits.blend`: cópia do estado anterior.
- `comparacao-preview.png`: ícones e depósitos lado a lado, em perspectiva ortográfica inclinada.
- `comparacao-vista-superior.png`: comparação de cima.
- `manifest.json`: fonte, IDs, triângulos, alturas e erro máximo do contorno.

## Modelos e edição

Collections em `Icon_Inspired_Deposits`:

- `stone_deposit_icon`
- `gold_deposit_icon`
- `diamond_deposit_icon`
- `amethyst_deposit_icon`
- `reidite_deposit_icon`
- `emerald_deposit_icon`

Cada modelo tem um vazio `_root` para movimentar o conjunto e uma malha `_body`, fechada e editável. Selecione a malha e use Tab para editar. O pivot fica no centro da base, em Z = 0; zerar a localização do root remove o deslocamento do catálogo. Largura máxima: 4 unidades. As alturas variam conforme a silhueta.

`Inventory_References` contém apenas cópias dos modelos de referência, bloqueadas para seleção. `Icon_Deposits_Presentation` contém câmera, luzes, textos e chão. Ambas podem ser ocultadas ao modelar e devem ser excluídas da exportação dos depósitos.

## Verificação

- Seis malhas fechadas, com faces de área positiva e volume orientado corretamente.
- 1.412 triângulos no total, considerando apenas os depósitos.
- Comparação do contorno em 360 direções: desvio radial máximo inferior a 1% da largura do ícone, nos cinco modelos baseados na coleção do usuário.
- Cada modelo usa apenas cores do próprio minério, extraídas dos materiais dos ícones quando disponíveis.
- Os ícones originais e os depósitos naturais aprovados anteriormente foram preservados.

Os modelos não incluem lógica de mineração, colisão configurada ou exportação FBX; são a versão editável para revisão visual.
