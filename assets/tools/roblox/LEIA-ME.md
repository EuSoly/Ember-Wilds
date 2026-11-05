# Picaretas e ferramentas para Roblox — 29 modelos

## Importação

No Roblox Studio, abra **File > Import** e selecione `picaretas-e-ferramentas.fbx` para importar os 29 modelos juntos, organizados em fileiras. Para importar apenas um item, use seu arquivo na pasta `individual`.

Os arquivos individuais têm origem na empunhadura/centro do modelo e não carregam as rotações usadas na apresentação. A escala de modelagem foi mantida; ajuste a escala na prévia do Studio conforme o tamanho do personagem.

## Conteúdo

- 6 picaretas.
- 6 martelos, incluindo o supermartelo.
- 4 pás.
- 6 escudos.
- 2 forcados, livro, regador, balde, chave inglesa e facão.

Cada ferramenta é um objeto de malha com um nome estável, como `diamond_pickaxe`, `stone_hammer` ou `watering_can`. O FBX contém somente os modelos, sem cenário, textos, luzes ou controles vazios.

## Cores

Os FBXs incluem a textura `tools_palette.png` incorporada. Mantenha também o PNG junto ao arquivo geral. Se a textura não carregar no Studio, importe o PNG como imagem e atribua o ID à propriedade `TextureID` dos MeshParts. Todas as ferramentas usam a mesma paleta.

## Arquivos Blender

- `picaretas-e-ferramentas-editaveis.blend`: os 29 modelos com peças, materiais e coleções separados para continuar modelando.
- `picaretas-e-ferramentas-export.blend`: versão triangulada, com uma malha por ferramenta e paleta UV, correspondente ao FBX.

As duas faces dos modelos e seus relevos foram preservados. Os arquivos individuais não são objetos Roblox `Tool` completos: configuração de `Handle`, encaixe na mão e lógica do jogo ficam para a integração no Studio.

## Verificação

`manifest.json` registra nomes, peças de origem, dimensões e triângulos. `validation.json` contém a verificação por reimportação do FBX geral e dos 29 individuais no Blender. Não foi realizado upload nem teste de importação no Roblox Studio.

Documentação oficial: https://create.roblox.com/docs/studio/importer
