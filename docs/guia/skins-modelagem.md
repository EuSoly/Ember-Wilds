# Modelagem das skins de corpo

Regras combinadas com o Elizeu (04/11/2026) para modelar as skins do boneco no Blender.

## Princípios

1. **Versões nossas, não cópias.** As imagens em `assets/skins/reference/` (Starve.io) servem de catálogo de **temas** e de **paleta**. O formato, as proporções e os detalhes são desenhados por nós sobre o nosso boneco. Personagens conhecidos de filmes/marcas ficam fora.
2. **Cores da referência.** As cores seguem a paleta da skin de referência (extraída das imagens de dia), não a paleta rústica da UI.
3. **Só o dia importa.** A noite do Starve é pintada na arte; no Roblox quem escurece é a iluminação. Partes que brilham à noite viram material Neon.
4. **Ler de cima.** A câmera fica a 65° (`CameraController.PITCH`). Toda skin é conferida reto de cima e a 65°, de frente e de costas. O que funciona: silhueta passando da borda do corpo e desenho em camadas planas no topo. Volume em pé (cones, detalhes nas laterais) quase não aparece.
5. **Detalhe proporcional à mudança.**
   - **Detalhada** (a skin muda a silhueta: asas, orelhas grandes, chifres, fogo, tentáculos): mais camadas, recortes e detalhes de topo, e mão temática.
   - **Simples** (cor, textura ou estampa): corpo base com cores e camadas planas no topo, sem enfeite extra. Mão redonda na cor da skin.
   - **Simples com toque**: igual à simples, mais um detalhe pequeno na borda (orelhinha, tufo, laço).

## Triagem

`assets/skins/triagem/triagem.json` classifica os 281 IDs de referência, com pranchas em `assets/skins/triagem/*.png`:

| Grupo | IDs | Critério |
|---|---|---|
| Detalhada | 120 | silhueta preenche menos de 80% do retângulo ou passa da largura do corpo |
| Simples com toque | 64 | entre 80% e 88%, ou um pouco mais larga |
| Simples | 93 | 88% ou mais, dentro do quadrado |
| Fora | 4 (120–123) | personagens de filmes conhecidos |

Muitos IDs são variações do mesmo tema (tocos com folhas 253–281, raposas 162–166, conchas e estrelas 55–61, rosquinhas 221–223, bolhas de cor 33–36). Cada tema vira **uma** skin nossa (com variações de cor se fizer sentido), não uma por ID.

## Montagem no Blender

- Medidas do `BonecoConfig` (1 m = 1 stud; frente do boneco = +Y no Blender): corpo 3,6 × 2 × 3,6, cantos 0,9, contorno 0,2 (topo 0,1 abaixo), mão Ø 1,3 em x = ±1,95, 1,45 à frente, 1,2 de altura.
- Nomes: `<skin>_Body`, `<skin>_Outline`, `<skin>_Hand`, `<skin>_HandOutline`, `<skin>_Hand_*` (peças da mão), `<skin>_Extra_*` (silhueta e topo). `PREVIEW_*` é só prévia (olhos e mão esquerda) e não é exportado: os olhos vêm do código (piscar, dor).
- Peças planas: contorno 2D suavizado e extrudado (0,03–0,05 no topo; silhuetas mais grossas, abaixo do topo).
- **Nada grande e escuro logo atrás dos olhos:** de cima, uma mancha ali vira "boca". E peças compridas não podem descer dos olhos para trás (viram presas de morsa); orelhas e chifres saem das laterais de trás para fora.
- **A metade de trás também aparece "embaixo dos olhos":** quando o boneco anda para longe da câmera, as costas ficam entre os olhos e a câmera. Por isso a vista reta de cima com a frente para cima é o teste mais duro: anel, faixa escura ou mancha nas costas vira boca ali. Auréolas e enfeites soltos ficam atrás da borda de trás.
- **Nada de fileira de pontas de alto contraste no topo** (espinhos, labaredas em zigue-zague, gotas claras apontando para trás): de cima viram dentes ou presas embaixo dos olhos. No topo, usar bordas onduladas e tons próximos do corpo; as pontas fortes ficam na silhueta, fora do corpo.

## Script e lotes

| Arquivo | O que é |
|---|---|
| `assets/skins/skin_lib.py` | Biblioteca comum: classe `Skin` com `base()`, `flat()` (peça plana com contorno), `sym()` (dos dois lados), `sphere()`, `hand_flat()` e `finish()` (mão esquerda de prévia); `build(lote)` e `render_previews(prefixo)` |
| `assets/skins/lotes/<lote>.py` | Uma função por skin + lista `LOTE` com `(nome, função, corpo, contorno, mão, contorno da mão)`. Começa com `from skin_lib import *` |
| `assets/skins/build_skins.py` | Monta no Blender **aberto**: `LOTE_ESCOLHIDO = "lote2"` (ou um glob, `"lote3_*"`) e `exec(open(...).read())` |
| `assets/skins/render_lote.py` | Monta e renderiza em **segundo plano**, sem mexer no Blender aberto: `blender -b --factory-startup --python assets/skins/render_lote.py -- <lote ou glob> <pasta>` → `<lote>-cima.png`, `<lote>-65.png` e `<lote>.blend`. O Blender fica em `C:\Program Files (x86)\Steam\steamapps\common\Blender\blender.exe` |

| `assets/skins/ferramentas/` | Levar mudanças feitas à mão no Blender para o script: `resumo_cena.py` (resumo das peças da cena aberta ou de um lote montado em segundo plano), `comparar_resumos.py` (peças apagadas, novas e mudadas, casadas pela forma e não pelo nome) e `rastrear_pecas.py` (linha do lote que cria cada peça) |

## Fluxo de trabalho (combinado em 05/11/2026)

1. **Um agente por lote de 10 skins**, rodando em segundo plano. Comparação feita: 5 agentes com 2 skins cada custaram ~530 mil tokens no lote 3; 1 agente com 10 custou ~183 mil no lote 4 (com qualidade parecida), porque cada agente gasta ~40–50 mil só lendo guia, biblioteca e exemplos. Pedir mais capricho ("mais rodadas nas skins fracas") subiu o lote 5 para ~254 mil; um teto de ~3 rodadas por skin equilibra.
2. **O prompt do agente** leva: este guia, `skin_lib.py`, um ou dois lotes de exemplo, a lista das skins que já existem, os temas com a paleta (hex) de cada um, a ordem de NÃO procurar nem copiar imagens de referência e de não representar personagens conhecidos, o comando do `render_lote.py`, uma **pasta de rascunho própria** (`scratchpad\prev<N>\`; com pasta comum um agente sobrescreveu o outro) e a proibição de mexer no Blender aberto, em outros arquivos e no git.
3. **Revisão:** monto o lote no Blender aberto (`build_skins.py`), olho de cima (frente para cima) e a 65°, e **devolvo as correções ao MESMO agente** (ele ainda tem o contexto; uma rodada de correção custou ~20–40 mil tokens). Só então salvo `skins-loteN.blend` + `.png`, atualizo a tabela abaixo e mostro ao Elizeu.
4. **Mudanças do Elizeu no Blender:** a cena aberta é descartada a cada montagem, então antes de tudo salvar a cena dele no `.blend` do lote e levar as mudanças para o script: `resumo_cena.py` na cena aberta + `resumo_cena.py` do lote em segundo plano → `comparar_resumos.py` → `rastrear_pecas.py` nos nomes listados → editar o lote (comentando o que ele apagou, com data) → comparar de novo até não sobrar diferença.
5. **Cuidados que apareceram nas revisões:** padrão de um personagem famoso disfarçado de tema genérico também conta como cópia (o peixe laranja com três faixas brancas contornadas de preto foi trocado por pintas); cores fora da paleta só para contraste e sempre relatadas.

## Lotes

| Lote | Arquivo | Skins (tema, referência de paleta) |
|---|---|---|
| 1 | `assets/skins/skins-lote1.blend` + `.png` (eu, `lotes/lote1.py`) | lobo (113), raposa (82), coruja (17), polvo (21), caranguejo (22), abelha (20), dragão (98), coelho (71), arbusto de frutas (153), nuvem (86) |
| 2 | `assets/skins/skins-lote2.blend` + `.png` (eu, `lotes/lote2.py`) | abóbora (69), morcego (31), chama (66, miolo em Neon), estrela-do-mar (57), concha (60), aranha (68), cervo (129), axolote (148), ouriço (76), morango (93) |
| 3 | `assets/skins/skins-lote3.blend` + `.png` (5 agentes em paralelo, `lotes/lote3_a…e.py`) | anjo (172), diabinho (173), gato (187), coala (102), mamute (139), papagaio (224), cacto (119), maçã (201), toco (255), lula (249) |
| 4 | `assets/skins/skins-lote4.blend` + `.png` (1 agente, `lotes/lote4.py`) | tartaruga (15), pintinho (8), peixe (27), cenoura (37), tubarão (96), sapo (138), macaco (140), leão (243), bolota (246), vaca (250) |
| 5 | `assets/skins/skins-lote5.blend` + `.png` (1 agente, `lotes/lote5.py`; cogumelo, vela e slime com ajustes do Elizeu no Blender, já levados ao script) | guaxinim (43), javali (101), cogumelo (168), onça (217), vela (226), bomba (236), fênix (248), yeti (170), besouro (171), slime (195) |

## Exportação para o Roblox

`assets/skins/export_roblox.py` (rodar com `blender -b --factory-startup --python assets/skins/export_roblox.py`) gera `assets/skins/roblox/corpo/` e `assets/skins/roblox/livros/`: FBX geral + individuais, textura de paleta, `.blend` de exportação, `manifest.json`, `validation.json` e `preview.png`. Lotes incluídos na lista `LOTES` do script (acrescentar cada lote novo ali). Corpo = `body_<nome>_corpo` + `body_<nome>_mao` (mão direita, pivô no centro da mão; olhos ficam no código); livro = `book_<nome>_livro`; partes com `emit` saem em `_neon` e com `alpha` em `_translucido` (ajuste de Material/Transparency no Studio). Curvas com `RES_EXPORT = 4` e Decimate acima de 5.000 (corpo) / 1.500 (mão) / 3.000 (livro) triângulos. Detalhes no `assets/skins/roblox/LEIA-ME.md`; conferir a versão exportada com `ferramentas/previa_export.py`.

### Pendente: mão esquerda (anotado em 05/11/2026)

O export traz só a mão **direita** (`body_<nome>_mao`, pivô no centro da mão). A ideia era o código usar a mesma malha nas duas mãos, mas o Roblox não espelha MeshPart (não existe tamanho negativo): girar a mão direita não vira uma mão esquerda. Mãos simétricas (esfera lisa, garras para a frente, almofadinhas) ficam certas; enfeites que apontam para fora (asa do pintinho, penas do papagaio, barbatana do tubarão, faísca da chama…) ficariam apontando para dentro ou para trás.

**Correção combinada:** o `export_roblox.py` passa a gerar também `body_<nome>_mao_esq`, espelhada em X no Blender a partir da direita (pivô no centro da mão esquerda), e o `manifest.json` ganha a peça. Depois: reimportar o FBX de corpo (ou só as mãos esquerdas), mover para `Assets.Skins` e fazer o `BonecoModel` usar uma malha por lado.

## Livros (triagem de 05/11/2026)

O livro padrão é o modelo do Elizeu, `ReplicatedStorage.Assets.Tools.book`. As skins de livro seguem as mesmas regras das de corpo (versões nossas por tema, paleta da referência, nada de copiar texto ou arte da capa). Triagem em `assets/skins/triagem/livros/triagem.json`, com pranchas por grupo na mesma pasta:

| Grupo | IDs | Temas | Critério |
|---|---|---|---|
| Detalhada | 15 | 14 (pergaminho, mapa rasgado, tábua de pedra, paleta de pintor, cardápio, envelope, pinheiro, presente, orbe, bússola, livro aberto…) | outro objeto no lugar do livro, ou silhueta bem diferente |
| Simples com toque | 18 | 12 (livro da floresta 51–56, rebites, tentáculo, fechos, cristais, enfaixado, gelo, amarras, cantoneiras, joias, trepadeiras) | livro com enfeite saindo pela borda ou capa em relevo |
| Simples | 24 | 18 (cores lisas, ondas, cogumelo, camuflado, listrado, lava, melancia, pedra, manchas, biscoitos; os marrons 0/3/4/5/6/18 viram o padrão) | só a capa |

**Base:** `assets/skins/livro_lib.py` — classe `Livro` (mesma API da `Skin`) com `base()` = livro fechado nas medidas do `Assets.Tools.book` (2,37 × 2,68 × 0,53; lombada em -X; contorno só na base para as páginas aparecerem), `build_livros(lote)` e `padrao` (o livro do jogo, referência de escala). Lote de livro = arquivo em `lotes/` com `TIPO = "livro"` e tuplas `(nome, função, capa, borda[, páginas[, lombada]])`; `build_skins.py` e `render_lote.py` reconhecem o tipo. Objetos que não são livro (pergaminho, mapa…) não usam `base()` e ocupam mais ou menos a mesma área. O livro aparece pequeno na mão: poucos elementos grandes.

| Lote | Arquivo | Livros |
|---|---|---|
| 1 | `assets/skins/livros-lote1.blend` + `.png` (1 agente, `lotes/livros1.py`, ~148 mil tokens com a correção) | pergaminho (16), mapa (15), tábua de pedra (24), paleta de pintor (28), presente (42), floresta (53), gelo (33), cristais (27), lava (26), melancia (29) |
| 2 | `assets/skins/livros-lote2.blend` + `.png` (mesmo agente do lote 1, `lotes/livros2.py`, ~187 mil tokens) | envelope (36), pinheiro (40), orbe (44), bússola (49), livro aberto (50), tentáculo (19), engrenagens (43), trepadeira (48), cogumelo (14), ondas (13) |

`lotes/livros2.py` importa funções utilitárias de `lotes/livros1.py` (`barra`, `trilha`, `corta`, `arco`, `folha`, `losango`…); não renomear o lote 1 sem mover essas funções para a `livro_lib`. Desenho de capa em `TOPO + 0,012` (acima da lombada). Reaproveitar o mesmo agente no lote seguinte **não** saiu mais barato: o contexto acumulado dele custou mais que a leitura inicial de um agente novo.

Medida usada: sobreposição (IoU) da silhueta de cada referência com a do livro 0 (todas têm 226×226); os que têm o retângulo do livro mas são outra coisa (cardápio, envelope, folha) foram corrigidos no olho. Capas com título (19, 17, 35) ficam sem o texto.

**Falta (estimativa de 05/11):** ~24 temas detalhados (2–3 lotes de 10), ~35 temas "simples com toque" e ~30 de estampa (lotes de ~20, são mais fáceis) e ~15 só de cor (só `Defs/Cosmetics`, sem Blender). Depois do corpo: acessórios, mochilas, livros e caixas (referências em `assets/skins/reference/<categoria>/`). Ainda não feito: importar as skins no Roblox (`Assets.Skins.<id>`) e o `BonecoModel` usar o modelo.
