# Espadas e lanças para Roblox

## Importar

No Roblox Studio, use **File > Import** e selecione `espadas-e-lancas.fbx`. O arquivo contém somente as 9 espadas e 9 lanças, com os nomes usados no catálogo. Revise a prévia de escala e textura no importador antes de confirmar.

Para importar uma arma por vez, use os FBXs em `individual/`. Essas versões têm a origem na empunhadura original (ROOT), sem a rotação e o deslocamento usados para organizar a galeria. O FBX conjunto mantém a disposição da galeria.

## Conteúdo

- `espadas-e-lancas.fbx`: as 18 armas, uma malha por arma.
- `individual/*.fbx`: 18 arquivos independentes.
- `weapons_palette.png`: textura de cores 256 × 256, também embutida nos FBXs.
- `espadas-e-lancas-export.blend`: arquivo Blender limpo, com somente as 18 malhas de exportação e a textura embutida.
- `manifest.json`: IDs, contagem de triângulos, dimensões e peças de origem.
- `validation.json`: resultados da reimportação dos 19 FBXs no Blender.
- `preview.png`: conferência visual da cópia exportada.

As peças foram reunidas somente na cópia de exportação. Os modificadores foram avaliados e as faces trianguladas. As cores dos materiais sólidos foram convertidas para uma única textura compartilhada, respeitando o limite de um material por malha no Roblox.

Não há picaretas, câmeras, luzes, fundo ou controles auxiliares nos modelos entregues. A cópia editável original permanece em `../armas-colecao-recuperada.blend`.

## Configuração e validação

FBX Unit Scale, escala 1, Z Forward, Y Up, textura embutida e sem animação. Total: 4.592 triângulos, 94 cores. Todos os arquivos foram reimportados no Blender e conferidos quanto a nomes, contagens, UVs, textura, dimensões e origens. Ainda não houve validação dentro do Roblox Studio.

São modelos visuais: scripts de Tool, dano, empunhadura, colisão e animação não estão incluídos. Ajuste a escala ao personagem ao importar. Os nomes, como `wood_sword` e `gold_spear`, identificam as armas.

Referências oficiais: [Importador do Studio](https://create.roblox.com/docs/studio/importer), [configuração do Blender](https://create.roblox.com/docs/art/blender), [materiais e texturas](https://create.roblox.com/docs/art/modeling/texture-specifications).
