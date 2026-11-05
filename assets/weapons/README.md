# Espadas e lanças — coleção editável

Arquivo atual: `armas-colecao-recuperada.blend`, cena `Scene`. Contém as alterações manuais do usuário e a organização das 18 armas. Os arquivos e cenas de apresentação anteriores são versões históricas, não a fonte atual.

Hierarquia: `Weapons > Swords|Spears > item_id`. Cada arma tem uma coleção e um objeto `item_id_root`. Lâmina/ponta, cabo/haste, guarda e detalhes permanecem separados conforme a modelagem do usuário. Selecione o root para mover a arma inteira; selecione uma peça e pressione Tab para editar sua malha.

Exemplos: `wood_sword_blade`, `wood_sword_handle`, `gold_spear_tip`, `gold_spear_shaft`, `reidite_sword_handle_studs`. Os encaixes já unidos numa mesma malha receberam a função `fittings`. Não se separaram nem juntaram malhas durante a organização.

## Nomes para programação

Os IDs de madeira, pedra e ouro seguem os já existentes em `src/shared/Defs/Items.luau`: `wood_sword`, `stone_sword`, `gold_sword`, `wood_spear`, `stone_spear`, `gold_spear`. Os demais estendem a mesma convenção com `diamond`, `amethyst`, `reidite`, `dragon`, `lava`, `pirate_sword` e `crab_spear`; isso não adiciona itens ao código do jogo.

`weapon-assets.json` é o mapa atual de coleções, roots, peças e funções. Cada coleção/objeto também tem a propriedade personalizada `item_id`; cada objeto tem `part_role`. Esses metadados do Blender precisam ser transferidos explicitamente na integração, não são atributos Roblox automáticos.

Os sete controles auxiliares sem malhas foram preservados em `UnusedWeaponControls`, fora de `Weapons`, e marcados com `export=false`. Para exportar, selecionar somente a coleção da arma desejada. O exportador não interpreta essa propriedade automaticamente.

A tentativa anterior de exportação individual foi interrompida; não há um conjunto validado de arquivos individuais. Use as coleções separadas do arquivo atual.

## Conteúdo

- Espadas: Madeira, Pedra, Ouro, Diamante, Ametista, Reidite, Dragão, Lava e Pirata.
- Lanças: Madeira, Pedra, Ouro, Diamante, Ametista, Reidite, Dragão, Lava e Caranguejo.

Escopo: itens da tabela Weapons da [página Items](https://starveiopro.fandom.com/wiki/Items), consultada em 02/11/2026. A espada vermelha aprovada corresponde à Reidite. Os desenhos foram adaptados para malhas de baixo volume editáveis, conforme as referências fornecidas e as imagens da tabela.

Modelos para continuar a modelagem: sem animações, colisores ou integração no Roblox. Materiais de cores sólidas; não dependem de imagens externas. Escala proposta, a ajustar ao personagem antes da importação.

`catalogo-armas.json` registra a construção original, antes das alterações manuais. A organização atual verificou todas as 83 malhas da cena: geometria local, materiais e modificadores preservados; diferença máxima nas posições mundiais dos vértices de aproximadamente 0,00000012 unidade por arredondamento numérico. Não foi feita correção de topologia na modelagem do usuário.

`backups/` contém a cópia salva antes da organização. `organize_collections.py` documenta a migração específica da hierarquia antiga; não é um organizador genérico para reexecutar sobre nomes novos. Os scripts de construção e exportação são históricos; não execute por cima da coleção editada.
