# Prompts de imagem: update do inverno + fazenda com mercado (18/11)

Prompts para o ChatGPT (gerador de imagem) fazer as artes 2D do próximo update:

- **Área congelada:** o bioma de inverno, hoje fechado (`guia/mapa.md`, de X −1110 a −150 e de Z −1110 a −150).
- **Plantações liberadas:** as 8 culturas que hoje são `testOnly` (`guia/fazenda.md`).
- **Mercado:** troca colheita por recurso e por semente, como no Starve. No Starve, o mercado é só uma janela, sem NPC. Trocas do Starve: 1 frutinha → 3 madeiras, 1 abóbora → 4 pedras, 1 pão → 6 ouros, 4 cenouras → 1 diamante, 8 tomates → 1 ametista, 16 espinheiros → 1 reidite. Sementes: 10 pães → semente de abóbora, 16 abóboras → semente de cenoura, e assim por diante.

**O que NÃO é por imagem:**
- Os modelos 3D: árvores e rochas de neve, jazida de diamante e mobs do inverno.
- Os ícones dos itens: no jogo, eles são modelos 3D em `Assets.Icons`, e as 9 culturas já têm modelo e ícone.

A IA faz só a interface, os ícones de botão, os avisos e a divulgação.

## Como usar

1. Abra uma conversa nova no ChatGPT e **anexe as referências**:
   - `docs/game-design/propostas/rustica-v1/prancha.png`: a direção aprovada;
   - `docs/game-design/design-system/componentes.png`;
   - `assets/ui/missoes/window.png`, `card_active.png` e `claim.png`: o padrão de janela, cartão e botão que já está no jogo.
2. Cole o **bloco de estilo** e, em seguida, **um prompt por vez**. Gerar uma folha por vez dá resultado melhor do que pedir tudo de uma vez.
3. Se a arte vier com texto, peça de novo: "sem nenhum texto, letra ou número". O texto entra por código.
4. Salve em `Downloads/UI Assets/update-inverno`. Eu recorto e coloco em `assets/ui/mercado/` e `assets/ui/inverno/`, como foi feito nas Missões.

## 0. Bloco de estilo (cole antes de cada prompt)

```
STYLE LOCK — Ember Wilds (Roblox top-down survival game). Match the attached reference images exactly: rustic hand-crafted game UI made of carved dark walnut wood (#59402D body, #805739 lit face, #38291F thickness), warm leather (#95603D), aged cream parchment (#E8D5AE) and glowing ember orange (#E99843, highlight #FFC66B). Chunky dark charcoal outline (#211A15) on every piece, 45-degree chamfered corners, simple bevels, light from upper-left, short hard shadow down-right. Flat-shaded, 2–3 tones per surface, at most 2–3 wide wood grain lines per piece, no noise behind content areas. Low-poly "toy" friendly look, saturated but not neon, no gore, no sci-fi, no ornate medieval filigree, no blurry drop shadows.
TECH RULES: transparent PNG background. ABSOLUTELY NO TEXT, letters or numbers anywhere (text is added in code). Stretchable pieces (windows, cards, tabs, buttons, bars) must have uniform borders and corners and a flat, empty center so they can be 9-sliced. Icons are square, centered, bold silhouette readable at 48 px on a phone. When several pieces are on one sheet, lay them out in a clean grid with generous empty space between them, all at the same scale, nothing overlapping.
```

## 1. Janela do Mercado (folha de peças)

```
Using the STYLE LOCK, create ONE sprite sheet with the separate UI pieces for a crop-trading MARKET window in the same family as the attached mission window:
1) Large market window: walnut wood frame with chamfered corners and a cream parchment inner area, a small wooden header plaque at the top center (empty), and a subtle farm motif carved into the top frame only (two small wheat stalks and a carrot carved at the corners). Center completely empty.
2) Tab, two states: normal (brown leather) and selected (lighter leather with an ember-orange outer edge). Empty, no icon.
3) Trade card: horizontal parchment strip with a darker inset slot on the left (what you give), a carved wooden arrow pointing right in the middle, and a darker inset slot on the right (what you get). Three states: available (normal), not enough items (slightly desaturated, grey-brown), and just traded (thin green glow edge).
4) Big TRADE button: ember-orange face, three states: normal, pressed (face lowered, less shadow), disabled (grey-brown with a small padlock).
5) Small round quantity buttons: minus and plus (leather, carved symbol, no digits), and a small dark rounded backing for an amount number.
6) Empty item slot: square leather slot, plus a selected version with ember edge.
All pieces separated on one transparent sheet, same scale, no text.
```

## 2. Ícones do Mercado e das abas

```
Using the STYLE LOCK, create a sheet of 4 square game icons, same size and visual weight, no tile background:
1) MARKET button icon for the HUD and menu: a small rustic wooden market stall with a striped orange-and-cream awning, a crate of vegetables in front (a pumpkin, carrots, a wheat bundle) and two arrows forming a circle above it (trade symbol).
2) Tab icon "Resources": a small pile of a log, a grey stone and a gold nugget.
3) Tab icon "Seeds": a small burlap seed pouch spilling a few seeds, with a green sprout.
4) Tab icon "Crops": a woven basket with a pumpkin, a carrot, a tomato and a watermelon slice.
Thick dark outline, 2–3 flat tones, tiny highlight upper-left, readable at 48 px.
```

## 3. Aviso de "área liberada" e cadeado do mapa

```
Using the STYLE LOCK, create a sheet with these separate pieces for unlocking a new FROZEN WINTER REGION:
1) Wide announcement banner that slides down from the top of the screen: wooden plank banner with frosted edges (snow caps on top, small icicles hanging under the bottom edge), an empty cream parchment center for a title, and a pale-blue snowflake medallion on the left end. Must be 9-slice friendly in the middle.
2) Same banner in a "locked" version: darker wood, no glow, a dark metal padlock on the left medallion instead of the snowflake.
3) Region icon "Frozen Lands": round medallion with snowy pine trees, a blue-white mountain and a small diamond crystal, cold blue (#4DA3FF / #EAF4FF) contrasting with a warm ember rim.
4) Minimap marker: small wooden sign post with snow on top and a padlock (locked), and the same sign with an open padlock (unlocked).
No text anywhere.
```

## 4. Efeito de tela da nevasca (vinheta)

```
Using the STYLE LOCK colors, create a full-screen 16:9 overlay vignette for a BLIZZARD in a top-down game: frost creeping in from all four edges and corners (white and pale-blue ice crystals, frosted glass texture, small snowflakes), getting stronger at the edges, and the whole center 60% of the image fully transparent. Soft but stylized, flat-shaded, matching a cartoon low-poly game, not photorealistic. Transparent PNG, no text.
```

Já existe a vinheta do frio, `assets/ui/hud/fx_cold.png`. Esta é mais forte e serve para a nevasca. Se a do frio já bastar, pule este prompt.

## 5. Divulgação do update: thumbnail e ícone

```
Create a 16:9 (1920x1080) Roblox game thumbnail for the update "Frozen Lands & Market" of Ember Wilds, a cute low-poly top-down survival game. Camera high and angled down (top-down 3/4 view), toy-like low-poly 3D look with chunky shapes and soft lighting.
Left half: a lush green forest farm at golden hour — wooden planter boxes in a grid with growing pumpkins, carrots, tomatoes, watermelons and wheat, a watering can, and a small rustic market stall with an orange-and-cream striped awning and crates of vegetables, a cozy campfire.
Right half: a snowy frozen region being revealed — snowy pine trees, icy blue rocks, glowing cyan diamond ore crystals, a woolly mammoth silhouette in the distance, light snowfall; a broken wooden barrier with a fallen padlock in the middle, showing the path is now open.
Strong warm vs cold contrast (ember orange on the left, icy blue on the right). Two small round cartoon characters with simple dot eyes and floating hands (no Roblox avatar, no characters from other games): one holding a pitchfork, one in a fur hat walking into the snow. Leave clear empty space in the upper third for the logo and title added later. No text, no logo, no UI.
```

Para o **ícone** (512×512), peça no mesmo chat: "Agora a mesma cena em formato quadrado 1:1, como ícone de jogo: só a fogueira no centro, com metade do chão verde de fazenda (uma abóbora) e metade com neve (um cristal de diamante). Contorno grosso, fácil de ler em tamanho pequeno, sem texto."

Para os bonecos ficarem iguais aos do jogo, anexe também um print do boneco tirado no Studio.

## 6. (Opcional) Arte conceitual do bioma de inverno

Serve só de referência para modelar no Blender. Não entra no jogo.

```
Concept art sheet, top-down orthographic view, for the WINTER biome of a cute low-poly survival game (same toy-like style as the attached forest references). Show on a white background, separated and same scale: 3 snowy pine tree variations, 2 icy rocks, a diamond ore deposit in 3 sizes (cyan crystals growing from grey rock), an ice block that can be dug with a shovel, a patch of snowy ground texture tile, and a small frozen pond. Big readable silhouettes from above, flat colors with simple shading, palette: snow #EAF4FF, shadow blue #6C85C9, diamond #3FD0E0, stone #8A8F98. No text.
```

## Lista de entrega

| # | Peça | Estados | Prioridade |
|---|---|---|---|
| 1 | Janela do mercado | 1 | essencial |
| 2 | Aba | normal, selecionada | essencial (ou reaproveitar `missoes/tab.png`) |
| 3 | Cartão de troca | disponível, sem itens, trocado | essencial |
| 4 | Botão TROCAR | normal, apertado, bloqueado | essencial (ou reaproveitar `missoes/claim.png`) |
| 5 | Botões − e + e fundo do número | 3 | bom ter |
| 6 | Ícone do Mercado (HUD e menu) | 1 | essencial |
| 7 | Ícones das abas: Recursos, Sementes, Colheita | 3 | essencial |
| 8 | Faixa de "área liberada" e versão trancada | 2 | essencial |
| 9 | Medalhão da região congelada | 1 | bom ter |
| 10 | Marcador do minimapa: trancado e aberto | 2 | bom ter |
| 11 | Vinheta da nevasca | 1 | bom ter |
| 12 | Thumbnail 1920×1080 e ícone 512×512 do update | 2 | para o lançamento |
| 13 | Conceito do bioma de inverno | 1 | opcional |

Já temos e vou reaproveitar:
- o cadeado (`hud/lock.png`);
- a moeda Golden Ember;
- os avisos `hud/toast_*`;
- as barras `missoes/bar_*`;
- a vinheta de frio;
- os ícones 3D de todos os itens.

## Perguntas abertas para o Elizeu

1. **Formato do mercado:** só uma janela, como no Starve, ou uma barraca ou NPC no mapa? Se for barraca, ela vira modelo 3D no Blender, e o prompt 5 serve de referência.
2. **Abas do mercado:** duas (Recursos e Sementes, como no Starve) ou três (com Colheita)?
3. **Liberação da área congelada:** abre para todos de uma vez no update, ou cada jogador destrava a sua (por nível, quest ou item)? Isso decide se a faixa trancada e o marcador com cadeado entram.

