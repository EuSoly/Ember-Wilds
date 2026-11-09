# Vento e vórtice: peças para animação

As peças estão separadas e com pivôs definidos. A pose inicial e os detalhes
aprovados foram preservados. Não há keyframes, rig de ossos ou animação aplicada.

## No Blender

Na coleção `vento` ou `vortice`, selecione os objetos `CTRL_*` no Outliner.
Os controles movem todas as pequenas peças do respectivo detalhe juntas.

| Controle | Uso sugerido |
| --- | --- |
| `CTRL_vento_rotor` | Girar as três correntes ao redor do centro da tampa |
| `CTRL_vento_nuvem_01` / `02` | Flutuar cada nuvem |
| `CTRL_vento_pena_01` / `02` | Oscilar cada pena, incluindo suas nervuras |
| `CTRL_vortice_espiral` | Girar a espiral interna |
| `CTRL_vortice_anel` | Girar o anel de pedras e seus símbolos juntos |
| `CTRL_vortice_cristal_01` / `02` | Flutuar cada cristal |

O giro sobre a tampa é no eixo Z do Blender. Cada controle começa sem rotação,
e os pivôs das penas, nuvens e cristais ficam no centro do respectivo detalhe.
As bases e laterais permanecem fora desses controles.

## FBX para o Roblox

Os arquivos `../roblox/caixas/individual/crate_vento.fbx` e
`../roblox/caixas/individual/crate_vortice.fbx` contêm as partes independentes.
Os nomes seguem `crate_<tema>_anim_<grupo>`, junto da base `crate_<tema>_caixa`.
O anel do vórtice tem duas malhas: `anim_anel` e `anim_anel_neon`, ambas com o
mesmo pivô e `animation_group=anel`; devem receber a mesma transformação.

`manifest.json` registra o grupo e `offset_do_pivo_do_skin` de cada peça,
em coordenadas Blender. Conversão para Roblox: `(x, y, z)` → `(x, z, -y)`.
O eixo vertical de giro no Roblox é Y. Ao importar, mantenha as malhas separadas
e confira os pivôs na montagem. A exportação foi reimportada e validada no Blender;
a importação no Studio e a lógica de animação ainda serão feitas no jogo.

`caixa_animacao.py` reaplica a preparação ao reconstruir os modelos,
e `export_roblox.py` mantém os grupos separados na exportação.
