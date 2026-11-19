# Arte dos três bundles

Cada bundle tem um cenário cartoon original, quatro itens recortados do modelo do jogo e um sprite de efeito. Os PNGs de vitrine têm contorno escuro para separar os itens do cenário. As mochilas usam a câmera corrigida. O enquadramento de referência é 1120 × 300 e reserva espaço para título e raridade à esquerda, e recompensas, contador e preço à direita.

| Arquivo | Função |
|---|---|
| cenario-cartoon.png | Ilustração original em resolução de geração. |
| fundo.png | Cenário enquadrado com contraste ajustado na área dos controles. |
| personagem.png, caixa.png, mochila.png, livro.png | Recortes transparentes originais dos modelos. |
| loja-personagem.png, loja-caixa.png, loja-mochila.png, loja-livro.png | Camadas transparentes com acabamento cartoon usadas pela loja. |
| ambiente.png | Sprite transparente de 256 × 256. O redemoinho gira, três folhas caem em sequência ou a rosa dos ventos oscila. |
| particula.png | Sprite de bolha, fagulha ou ponto da rota, conforme o conjunto. |
| previa.png e efeito.png | Composição de referência sem textos e camada de efeito no enquadramento de desktop. |
| moldura.png | Borda recortada do cartão da loja, disponível para uso editorial. |

O módulo `BundleBanner.luau` monta sete camadas a partir dos IDs da pasta ArteBundles. O fundo desloca levemente com margem de recorte, o personagem oscila e os efeitos acompanham a mochila ou o livro. No Norte Perdido, três pontos acendem na ordem da rota durante a consulta. A troca de slide reinicia a sequência. O movimento pausa com a loja fechada.

As instruções e o arquivo de importação ficam em [IMPORTAR.md](../../../skins/roblox/primeira_leva/IMPORTAR.md). Para reproduzir os renders dos modelos, use `renderizar_itens.py` no Blender. Para compor as prévias desktop, compacta e animada, execute `compor_vitrine.py` com Pillow e as fontes locais utilizadas no projeto.

## Direção dos cenários

As cenas nasceram de descrições de uma gruta de coral, uma clareira entre raízes antigas e um mirante de exploração. O acabamento cartoon usou o render do personagem de cada bundle como referência de formas, contornos e sombras. Os fundos foram criados com o ImageGen integrado. O Bosque usa as texturas de folhas e brilho do próprio jogo. O ambiente fica atrás dos itens e tem movimento próprio. As bolhas, vaga-lumes e marcas da rota continuam em outra camada.
