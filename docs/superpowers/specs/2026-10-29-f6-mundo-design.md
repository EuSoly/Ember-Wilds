# Ember Wilds — F6 Mundo: mapa, recursos espalhados, água e dia/noite (design)

Data: 2026-10-29 · Status: revisado por um builder independente; aguardando aprovação do Elizeu
Base: spec do MVP §9 e §10 (F6), catálogo (`docs/game-design/catalogo-e-roadmap.md`, "Mapa e biomas"), identidade visual (noite, fogo, escala).

Legenda: **[Elizeu]** decidido por ele · **[spec]** já decidido · **[Claude]** decisão técnica minha · **[builder]** quem implementa decide.

## 1. Intenção

Trocar o chão de teste pelo **mapa de verdade**, no layout do Starve.io: um quadrado com quatro biomas nos cantos e o oceano em cruz no meio [Elizeu, imagem do mapa do Starve]. **No lançamento só a floresta é jogável**, indo até o ouro [Elizeu; catálogo N0]; os outros cantos já existem no desenho e são "abertos" nos updates. O Elizeu **desenha o mapa à mão no Studio** e o jogo **espalha os recursos** dentro das zonas que ele marca [Elizeu: "gostei bastante da proposta para desenhar"]. Junto, a água (córregos e lago) e a iluminação de dia e noite.

## 2. Objetivos, não-objetivos e anti-objetivos

**Objetivos**
1. Layout do mapa inteiro (≈ 2.220 × 2.220 studs) com a floresta (960 × 960, **~1 min** para atravessar a 16 studs/s [Elizeu; reduzido à metade em 29/10]) no canto inferior esquerdo.
2. Ferramentas de desenho para o Elizeu: chão, **córregos** e lago [Elizeu], caminhos/clareiras, **zonas de recurso** e recursos colocados à mão.
3. Espalhador de recursos por zona, determinístico (mesmo mapa a cada partida), sem cair em água nem em caminhos.
4. Modelos dos recursos da floresta (árvore, rocha, jazida de ouro, arbusto de frutinha), 2–3 variações cada.
5. Água: atravessável, mais lenta (~60% da velocidade), "estar na água" disponível para a sede, e **o fôlego (oxigênio) cai na água** [Elizeu].
6. Borda da floresta intransponível no lançamento, com aviso "Região ainda não descoberta".
7. Dia e noite com iluminação, aviso 30 s antes da noite, e luz de fogo pronta para a fogueira.

**Não-objetivos (agora)**
- Coletar/bater nos recursos, quantos itens dão e renascer (fase de coleta, G2).
- Sede/fome/frio de verdade (G1): aqui só fica pronto o "está na água"; o `DevStatsService` (Studio) enche a sede na água como provisório.
- Biomas além da floresta jogáveis; rio com correnteza; oceano jogável.
- Fogueira construível (fase de construção); aqui só o modelo de luz e um comando de teste.

**Anti-objetivos**
- Mapa diferente a cada partida (o espalhador tem semente fixa).
- Recurso nascendo dentro de córrego, lago, caminho ou fora da zona.
- Noite tão escura que no celular não se vê um mob chegando [identidade visual].
- Desenhar o mapa exigir mexer em código.

## 3. Restrições

- O Workspace **não** é controlado pelo Rojo: o mapa desenhado vive no place. Backup no git é feito exportando (seção 9).
- Server Authority: mudanças de movimento (lentidão na água) precisam rodar **na simulação** (`BindToSimulation`, dos dois lados), como o `FacingSim`.
- Streaming ligado: recursos e mapa só chegam ao cliente perto dele.
- Escala [spec §9]: coletáveis ≥ 1,5× o boneco vistos de cima (boneco 3,6 → ≥ 5,4 studs); chão no Y = 0; a câmera a 65° vê o topo, então o topo é o que importa.
- Desempenho: alvo de 30 jogadores; recursos com poucas peças cada (≤ 6) e `ModelStreamingMode = Atomic`.

## 4. Coordenadas do mapa [Claude]

- Centro do mapa na origem; −Z é "para cima" na tela (câmera fixa).
- Quadrado total `MAP_SIZE = 2220` (2 × 960 + cruz do oceano de 300). **Reduzido à metade em 29/10** [Elizeu, depois de ver no Studio: "está bem grande"] — a floresta leva ~1 min para atravessar (o Starve.io, 1 min 16 s).
- Floresta: X de −1110 a −150, Z de +150 a +1110 (canto inferior esquerdo da tela). Inverno em cima à esquerda, lava em cima à direita, deserto embaixo à direita, oceano na cruz do meio e em volta.
- Spawn e âncora da câmera do menu passam para o **centro da floresta** (−630, 0, 630).
- Tudo em `WorldConfig` (números), para ajustar sem caçar no código.

## 5. Como o Elizeu desenha (convenções) [Claude]

Uma pasta `Workspace.Map` feita no Studio, com subpastas de nome combinado:

| Pasta | O que vai dentro | Como o jogo usa |
|---|---|---|
| `Map/Ground` | o chão (Parts/WedgeParts planos, topo em Y = 0), por bioma | só visual/colisão |
| `Map/Water` | córregos e lago (Parts finas, topo **um pouco acima** de Y = 0, sempre opacas — transparentes apagavam as etiquetas; decidido na implementação) | quem está dentro conta como "na água" |
| `Map/NoSpawn` | Parts invisíveis cobrindo caminhos e clareiras | o espalhador não põe recurso ali |
| `Map/Zones` | Parts invisíveis com o atributo `ZoneType` (ex. `"forest_dense"`) | o espalhador preenche cada uma conforme `Defs/ResourceZones` |
| `Map/Resources` | modelos/marcadores colocados à mão com o atributo `ResourceId` (ex. `"gold_vein"`) | viram recurso igual aos espalhados |
| `Map/Borders` | paredes invisíveis em volta da área jogável | não deixam passar |

- **Formas aceitas** em `Water`, `NoSpawn` e `Zones` [Claude]: `Part` bloco (pode girar em volta do eixo vertical) e `Part` cilindro **deitado** (disco, para lago redondo). "Dentro" é medido **de cima** (X/Z), ignorando a altura. Outras formas (cunha, união, MeshPart, Terrain) geram aviso e são ignoradas.
- **Recurso à mão = marcador** [Claude]: em `Map/Resources` vale qualquer peça/modelo com `ResourceId`; o servidor usa só a **posição e a rotação** (e o atributo opcional `Variant`), monta no lugar o **modelo padrão** e esconde o marcador. (Recursos com modelo único, feito à mão, ficam para quando houver necessidade.)
- O jogo **avisa no Output** o que estiver estranho (zona com `ZoneType` inexistente, recurso com `ResourceId` inexistente, forma não aceita) e segue funcionando.
- Sem `Workspace.Map`, o jogo usa o chão de teste atual (fallback para places novos/testes).
- O esqueleto inicial (chão dos quatro cantos, oceano, bordas da floresta, um córrego, um lago e algumas zonas de exemplo) **o Claude monta no Studio pelo MCP**; o Elizeu edita a partir dele.

## 6. Recursos e zonas como dados [Claude]

- `Defs/Resources.luau`: `id`, `nameKey`, `radius` (espaço que ocupa, para não encostar em outro), `variants` (quantas variações de modelo). Iniciais: `tree`, `rock`, `gold_vein`, `berry_bush`. Os campos de coleta (item, quantidade, ferramenta, tempo de renascer) entram na fase de coleta.
- `Defs/ResourceZones.luau`: `id`, e por recurso a **densidade** (quantos por 10.000 studs²). Iniciais [provisórios, o Elizeu ajusta]: `forest_dense` (muitas árvores, poucas rochas, alguns arbustos), `forest_open` (equilibrada), `quarry` (muitas rochas e ouro), `berry_field` (arbustos).
- **Espalhador** (lógica pura, testável): para cada zona, sorteia posições com `Random` de semente fixa (`WorldConfig.SEED` + índice da zona), descarta as que caem fora da zona, dentro de água/NoSpawn ou perto demais de outro recurso (soma dos `radius`), até a densidade pedida ou um limite de tentativas. Recurso colocado à mão entra antes e também ocupa espaço.
- O servidor monta os modelos (código, como o `ToolModel`) numa pasta `Workspace.Resources`, cada um com o atributo `ResourceId` e a tag `Resource` (a fase de coleta usa isso).
- **Colisão** [Elizeu: "devem bloquear a passagem… nas árvores o tronco bloqueado mas as copas não"]: cada recurso tem **uma** peça de colisão simples (invisível ou a própria base) e o resto do modelo sem colisão: árvore = só o tronco; rocha, jazida de ouro e arbusto = a base. `Defs/Resources` ganha `collisionRadius` (raio dessa peça).
- **Sempre dá para passar** [Claude]: o espalhador garante entre as peças de colisão de dois recursos um vão mínimo `MIN_PASSAGE = 5` studs (o corpo do boneco tem 3 de largura), mesmo nas zonas densas.
- **Copa transparente** [Claude, já previsto no spec §8 "fade de oclusão"]: copas têm a tag `Occluder`; no cliente, a copa que está entre a câmera e o **próprio** boneco fica semitransparente (só para ele), e volta ao sair de baixo.

## 7. Água e bordas [Claude]

- **Lentidão:** um módulo de simulação (como o `FacingSim`) vê se a raiz do personagem está dentro de alguma peça de `Map/Water` e põe a velocidade em `WATER_SPEED_FACTOR = 0.6` da normal; fora, volta ao normal. Roda nos dois lados para não ter correção.
- **"Na água":** o servidor grava o atributo `InWater` no Player (lido pela sede da G1; no Studio o `DevStatsService` enche a sede nele).
- **Oxigênio** [Elizeu: "na água também precisa tirar o fôlego"]: atributo `Oxygen` no Player (0–100, como as outras barras). Na água cai até zerar em `OXYGEN_EMPTY_SECONDS = 30`; fora, enche em `OXYGEN_REFILL_SECONDS = 5` (números em configuração). **Indicador = uma bolha de ar ao lado do próprio boneco** [Elizeu], no mundo (não na HUD): esvazia conforme o oxigênio cai, pisca perto do fim (< 25%) e **só aparece** enquanto o jogador está na água ou o oxigênio não está cheio. Só o próprio jogador vê a sua bolha. Cor `Palette.status.oxygen`. **Dano com oxigênio zerado** fica para a G1 (sobrevivência), junto com o resto das barras.
- **Bordas:** paredes invisíveis de `Map/Borders` com colisão. O cliente mostra o aviso `world.locked` = "Região ainda não descoberta" (pelo `Notifications` da HUD, no máximo uma vez a cada alguns segundos) quando o boneco chega perto da borda da área jogável (`WorldConfig.PLAYABLE` = retângulo da floresta).

## 8. Dia e noite [spec + identidade visual]

- O relógio já existe (`DayCycle`, 4 min de dia + 4 de noite). Falta a luz, **no cliente**: dois "climas" de iluminação (dia e noite) com transição suave (~10 s) no amanhecer e no anoitecer — `Lighting` (`ClockTime`, `Brightness`, `Ambient`, `OutdoorAmbient`), `ColorCorrectionEffect` (tom azul à noite) e `Atmosphere`. Valores num módulo de configuração, para ajustar olhando.
- Noite: azul e escura, mas a ponto de ainda se ver o chão e os bonecos no celular [identidade visual].
- Aviso `hud.nightComing` ("A noite está chegando") 30 s antes de anoitecer: **já existe** (relógio da HUD, F2); a F6 só faz a iluminação.
- **Luz de fogo:** um módulo que põe num modelo a luz quente da fogueira (`PointLight` `#FFA43A`, alcance 18, sem sombra [spec §8]) com leve tremulação. Comando de dev para colocar uma fogueira de teste onde o jogador está (para ver a noite com fogo).

## 8b. Minimapa [Claude]

O minimapa da HUD passa a desenhar o **mapa inteiro de forma esquemática** a partir do `WorldConfig` (os quatro cantos com as cores de cada bioma, o oceano em cruz, a área jogável destacada e as outras escurecidas), com o ponto do jogador na posição certa. Detalhes desenhados (córregos, caminhos) ficam para depois — com streaming, o cliente nem tem o mapa inteiro.

## 9. Backup do mapa no git [Claude]

O mapa vive no place. Para ter histórico: o guia explica salvar o place em arquivo (`File → Save to File`, `.rbxl`) e rodar `rojo syncback` com um **arquivo de projeto separado** (ex. `map.project.json`, só com `Workspace.Map`) para extrair o mapa para o repositório (pasta `map/`), num commit. O `default.project.json` **não** inclui o mapa, então o `rojo serve` nunca toma conta do desenho.

## 10. Critérios de pronto

1. Play: o boneco nasce no centro da floresta; o chão de teste não aparece mais quando existe `Workspace.Map`.
2. As zonas de exemplo aparecem preenchidas; duas partidas seguidas geram os recursos **nas mesmas posições**; nenhum recurso dentro de água, de `NoSpawn` ou fora da zona.
2b. O boneco esbarra no tronco das árvores e na base de rochas/ouro/arbustos, passa por baixo das copas (que ficam transparentes para ele) e sempre consegue atravessar uma zona densa.
3. Recurso colocado à mão em `Map/Resources` aparece igual aos espalhados; `ZoneType`/`ResourceId` errado → aviso no Output.
4. Entrar num córrego deixa o boneco mais lento, sem tremer (Server Authority); `InWater` liga e desliga; a bolha de ar aparece ao lado do boneco e esvazia em ~30 s, e some depois de encher fora da água.
5. Encostar na borda da floresta não deixa passar e mostra "Região ainda não descoberta".
6. Anoitecer: aviso 30 s antes, transição suave para a noite azul; a fogueira de teste ilumina em volta; amanhecer volta ao dia.
7. 30 jogadores (bonecos de teste) andando pela floresta cheia de recursos sem queda perceptível de FPS.
8. `check.sh` verde; testes Lune do espalhador (determinismo, bloqueios, espaçamento, densidade) e da validação das novas Defs.
9. Docs: `docs/guia/mapa.md` (como desenhar: pastas, zonas, água, recursos à mão, ajustar densidades, backup com syncback) e `arquitetura.md`.

## 11. Deixado para o builder

- Algoritmo exato do espalhador (amostragem aleatória com rejeição + grade espacial, ou Poisson), desde que determinístico e testado.
- Formato dos modelos de recurso dentro do estilo (peças simples, cores da `Palette`, topo legível).
- Valores exatos de iluminação (o Claude ajusta olhando no Studio na validação).
- Nomes de módulos e serviços.
