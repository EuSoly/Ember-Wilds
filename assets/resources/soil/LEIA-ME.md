# Areia e terra — ícones em relevo

Dois modelos criados em 12/11/2026 no estilo dos demais ícones do projeto.
Areia (`sand`): monte claro arredondado. Terra (`ground`): torrões marrons e
rachadura. Ambos têm contorno `#1E2230`, largura de aproximadamente 1,08 unidade
e relevo até 0,16. No Blender, cores e detalhes são peças editáveis; no Roblox,
cada ícone é um MeshPart com um material e uma textura de paleta.

## Arquivos

- `areia-e-terra.blend`: catálogo editável dos dois modelos.
- `areia-e-terra.png`: prévia renderizada.
- `roblox/areia-e-terra.fbx`: FBX conjunto.
- `roblox/individual/sand.fbx` e `ground.fbx`: individuais, com origem no centro da base.
- `roblox/soil_palette.png`: textura, também embutida nos FBXs.
- `roblox/manifest.json` e `validation.json`: detalhes e verificação de reimportação.
- `areia-e-terra-roblox.zip`: pacote para importar com o script abaixo.

## Roblox

Importe `roblox/areia-e-terra.fbx` usando Import 3D, mantendo as duas malhas
separadas. Selecione o Model importado no Explorer e execute o conteúdo completo
de `import-soil.luau` na Command Bar em modo Edit.

O script instala `ReplicatedStorage.Assets.Icons.sand` e `.ground`, guarda
modelos anteriores em `ServerStorage.SoilIconsBackup_<id>` e mantém a importação
original no Workspace. Salve o place após conferir. Ele aplica a orientação
de ícone usada no lote anterior; atributos de visualização anteriores são
preservados quando já existe um molde.

`ground` é o ID escolhido para terra, seguindo o nome do recurso no catálogo.
Os dois ainda precisam ser cadastrados em `Defs.Items` para aparecerem como
novos itens utilizáveis. Este lote não altera gameplay nem foi instalado no
Studio automaticamente.

## Validação

O conjunto e os dois FBXs individuais foram reimportados no Blender para
conferir nomes, geometria, escala, pivôs, UV e textura. A prévia foi inspecionada
visualmente. O instalador teve a sintaxe compilada; não foi executado no Studio.

Gerar novamente no Blender em segundo plano: `build_soil.py`, depois
`export_soil.py`. Os scripts reutilizam os auxiliares de ícones existentes e
não sobrescrevem os lotes anteriores.
