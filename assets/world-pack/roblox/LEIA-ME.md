# Pacote de mundo — 55 modelos

Conteúdo: 6 depósitos novos inspirados nos ícones, 7 modelos para inventário/ViewportFrame (incluindo madeira e esmeralda), 18 estruturas utilitárias e 24 construções (paredes, espinhos, portas e portas com espinhos dos seis tiers).

## Arquivos

- `individual/`: um FBX por modelo, com origem normalizada. É a opção recomendada para importar e programar cada asset.
- `categorias/`: quatro FBXs, separados em depósitos, viewports, estruturas e construções.
- `mundo-completo.fbx`: todos os modelos organizados em uma grade para comparação.
- `mundo-editavel.blend`: peças originais separadas e editáveis, organizadas por modelo e categoria.
- `mundo-export.blend`: versão com UV, textura compartilhada e malhas trianguladas; partes estáticas agrupadas e peças móveis separadas.
- `world_palette.png`: textura compartilhada com as cores dos modelos, também incorporada aos FBXs.
- `manifest.json`: nomes, partes, contagem de triângulos, pivôs e propriedades de movimento.
- `validation.json`: resultado da reimportação dos 60 FBXs no Blender.

## Importação no Roblox Studio

1. Extraia o ZIP mantendo as pastas.
2. Abra o Importador 3D e escolha um FBX da pasta `individual`.
3. Para manter a origem preparada, use `Set Pivot to Scene Origin` e `Use Imported Pivot`. Confira a escala na prévia antes de importar.
4. Nas construções estáticas, habilite `Anchored`. Para peças animadas, configure o comportamento conforme seus scripts.
5. Se a textura não carregar automaticamente, importe `world_palette.png` e aplique o mesmo ID em `TextureID` das malhas. Deixe a cor da MeshPart branca para não tingir a textura.

Os viewports são modelos 3D para colocar dentro de um ViewportFrame; a interface e a câmera do inventário não estão incluídas. Nos itens originais com faces planas, habilite `Make Double Sided` se quiser mostrar também o verso.

Documentação oficial: https://create.roblox.com/docs/studio/importer
Texturas: https://create.roblox.com/docs/art/accessories/creating-rigid/importing

## Nomes e movimento

Os nomes usam inglês, letras minúsculas e underscore. Exemplos: `gold_deposit_icon`, `gold_viewport`, `gold_extractor`, `gold_wall`, `gold_spike`, `gold_door` e `gold_spike_door`.

- Portas: `*_panel_left` e `*_panel_right`, incluindo os detalhes de cada folha. Deslocamento previsto: -2.25/+2.25 no X local do Blender, antes de qualquer ajuste de escala.
- Baú: `chest_body` e `chest_lid`; o pivô da tampa fica na dobradiça. Abertura prevista: -105 graus no X local do Blender.
- Extratores: `*_body` e `*_rotor`; rotação em torno do eixo vertical.
- Fogueiras e forno: corpo e `*_flames` separados.
- Pedra de ressurreição e máquina de esmeralda: corpo e `*_core` separados.

Os dados de pivô no manifest usam coordenadas do Blender (Z vertical); o FBX faz a conversão para Y vertical. Os FBXs preservam a hierarquia e os pivôs, mas scripts, animações, luzes, partículas, colisões e lógica de jogo precisam ser configurados no Studio. O brilho das chamas/cristais não é levado pela textura de cores.

## Verificação

55 assets, 78 malhas e 35.232 triângulos no conjunto. Uma textura de 256×256, com 96 cores, e um material por malha. Verificados por reimportação no Blender: nomes, hierarquia, triângulos, geometria, pivôs, UVs e textura incorporada. Não foi feito upload para o Roblox.

O arquivo de trabalho aberto no Blender foi preservado. Este pacote usa uma cópia isolada dos modelos aprovados.
