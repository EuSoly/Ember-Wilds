# Animações dos três bundles

Abra `primeira-leva-animacao.blend` e pressione Espaço. A cena contém as 12 peças em três fileiras, com poses de referência, controles de brilho e amostras dos efeitos. A linha do tempo usa 24 quadros por segundo. O quadro 1 é a pose inicial. Use a vista de cima para conferir a leitura do personagem e o modo **Material Preview** para avaliar os pulsos de neon.

## Como trabalhar na cena

- No Outliner, abra a coleção do bundle e depois a do item. Selecione um objeto `CTRL_` para ajustar a junta, ou `Raiz_` para inclinar o item inteiro. O Graph Editor permite ajustar amplitude e suavização das curvas.
- Para editar brilho, selecione o controle correspondente e procure **Object Properties → Custom Properties**. Na Caixa jardim, os controles CTRL_jardim_semente_01 e CTRL_jardim_semente_02 têm o canal brilho.
- Os marcadores `ORIGEM_` indicam onde cada efeito nasce. As malhas `PREVIA_FX_` permitem avaliar posição, ritmo e tamanho na cena. Na integração no Roblox, use os marcadores para posicionar Attachments nos itens e reproduza os efeitos com sprites. Os arquivos FBX individuais da primeira leva continuam sendo os modelos para importação.
- A demonstração reúne os eventos numa única timeline para compará-los. Em jogo, cada faixa deve responder ao evento da sua peça. A troca automática de banner da loja acontece a cada seis segundos e tem seu próprio relógio.

| Quadros | Evento representado |
|---|---|
| 1–48 | Repouso. Conferir um ciclo de ondulação da Lula e os pulsos das flores da caixa. |
| 49–80 | Deslocamento. Os braços da Lula se recolhem. |
| 81–88 | Parada. Começa a recuperação dos tentáculos e a mochila do Cartógrafo libera poeira. |
| 89–104 | Revelação das caixas. Cada uma faz seu gesto uma vez. |
| 105–145 | Consulta dos livros, leitura do efeito e retorno ao repouso. |

## Maré Profunda

| Peça | Direção de animação |
|---|---|
| **Lula** | Em repouso, uma onda de aproximadamente 5° passa pelos dez controles `CTRL_lula_tentaculo_01` a `10` em dois segundos. No deslocamento, os lados se recolhem em sentidos opostos em cerca de 12°. As pontas 02 e 09 acompanham com atraso e uma dobra extra de 8°. Ao parar, os braços assentam até o quadro 94 e as pontas até o 98. Avaliar a silhueta com a mochila equipada, especialmente o vão entre braços e mãos. |
| **Caixa do kraken** | Na revelação, a raiz inclina 6° para um lado, rebate 3° para o outro e assenta em cerca de 0,6 s. A base deve parecer pesada. |
| **Mochila Caranguejo** | Equipar o item existente `bag_caranguejo`. O jogo já aplica bolhas ascendentes e respingos de água pela configuração BagFxConfig. |
| **Tomo Abissal** | Equipar o item existente `book_tentaculo`. SkinMotion anima a espiral e a ponta; preservar o comportamento atual. |

## Bosque Desperto · Lendário

| Peça | Direção de animação |
|---|---|
| Toco da Floresta | Reutilizar o movimento existente dos brotos e das raízes em SkinMotion. |
| Caixa jardim | Dois miolos de neon verde-dourado sobre as flores da tampa acendem alternadamente. A versão importada usa CrateAnimator e CrateMotion com ciclo de 2,8 segundos. As pétalas permanecem presas à caixa. |
| Sementes de Esmeralda | A mochila mantém os vaga-lumes, as faíscas, as folhas e a névoa existentes de bag_cubos_esmeralda. |
| Tomo Trepadeira | Preservar a animação de flores e folhas do livro book_trepadeira. |

## Norte Perdido

| Peça | Direção de animação |
|---|---|
| **Explorador** | Ao consultar o livro, inclinar o personagem 7° na direção da leitura em sete quadros. Sustentar enquanto a rota aparece e voltar até o quadro 141. No jogo, preservar a posição dos pés e o controle do jogador. |
| **Caixa do aventureiro** | Balanço curto na revelação: −5° no quadro 92, +3° no 97 e repouso no 103. |
| **Mochila Cartógrafo** | Uma pequena nuvem de poeira parte de `ORIGEM_cartografo_poeira` quando o personagem termina de andar. Três grãos se espalham perto da base em cerca de meio segundo. Disparar uma vez por parada. |
| **Tomo da Bússola** | Girar `CTRL_bussola_agulha` em torno do eixo Z local até −34° e acomodar em −28° no quadro 118, apontando para o norte **desenhado na página**. Acender os marcadores `rota_01`, `02` e `03` nos quadros 118, 122 e 126, na ordem do trajeto. Os três pontos ficam presos à página e somem no 134. A agulha retorna ao fechar. |

## Passagem para o Studio

As rotações acima estão nos eixos do Blender. Para as origens locais, o manifesto guarda `anchors_blender` em coordenadas do item. A conversão para o Roblox é (X, Z, −Y). Vincular cada efeito à mochila ou ao livro que o emite e interrompê-lo ao desequipar. Personagens e caixas recebem movimento ou neon. Conferir a leitura com a câmera do jogo, testar equipar e desequipar durante um efeito e abrir o livro duas vezes para verificar que a segunda consulta começa do início.
