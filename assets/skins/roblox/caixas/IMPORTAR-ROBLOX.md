# Importar as 64 skins de caixas no Roblox Studio

O arquivo `skins-caixas.fbx` leva as 64 caixas em um único arquivo. Cada caixa
continua sendo um Model separado, com suas peças MeshPart agrupadas e nomeadas
por `crate_<skin>`. O FBX leva as cores pela textura de paleta incluída.

1. Extraia o ZIP para uma pasta local.
2. No Roblox Studio, use **File > Import 3D** e escolha `skins-caixas.fbx`.
3. Na janela de importação, confira a prévia e importe os modelos.
4. Se preferir trazer uma skin por vez, use os arquivos da pasta `individual`.

`manifest.json` contém a lista das 64 skins, nomes das malhas, pivôs e grupos
de animação. `validation.json` confirma que o arquivo geral e os 64 FBX
individuais foram reabertos e conferidos no Blender. Os grupos animáveis de
vento e vórtice estão preservados nas peças e no manifesto; veja `ANIMACAO.md`.

## Conteúdo do ZIP

- `skins-caixas.fbx`: importação conjunta das 64 skins.
- `caixas_palette.png`: textura compartilhada com as cores das caixas.
- `manifest.json`: catálogo, pivôs e nomes.
- `validation.json`: relatório de validação.
- `individual/`: alternativa para importar caixas separadamente.
- `ANIMACAO.md`: grupos e pivôs do vento e do vórtice.

A validação cobre a reimportação dos FBX no Blender; confirme a orientação e
os materiais na prévia do Studio antes de usar no jogo.
