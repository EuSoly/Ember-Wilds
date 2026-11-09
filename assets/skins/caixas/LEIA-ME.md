# Caixas temáticas

64 modelos em 7 cenas de `caixas-revisao.blend`. `catalog.json` registra a
consolidação dos 115 IDs de referência e os 23 modelos de NPC usados nos relevos.
Frente +Y no Blender; origem no chão; 1 unidade = 1 stud.

## Direção visual combinada

- O tema precisa ser reconhecível principalmente **pelo topo**, na câmera de jogo.
  Modelar formas, camadas, recortes, materiais e detalhes próprios do tema.
  Uma caixa genérica com um símbolo simples colado na tampa não basta.
- Completar também as quatro laterais, usando elementos coerentes com o topo.
- Bichos usam a biblioteca aprovada `assets/npcs/rabbit/coelho-v1.blend`.
- Preservar as edições manuais antes de reconstruir ou exportar.

## Revisões de 09/11/2026

- Lote 04: favos encaixados, lápide com arco e base, peixe com nadadeiras,
  corais ramificados e flores com ramos. Animais e presente preservados.
- As 45 edições manuais posteriores do Elize nas penas e no recife estão em
  `ajustes-elize.json`, aplicadas por `../caixa_ajustes.py` ao terminar cada caixa.
  A comparação de geometria entre script e galeria passou com tolerância 0,00005.
- Lote 05: reconstruído em `../lotes/caixas_organicas.py`. Vulcão com cratera,
  picareta e minério, bolo com recheio/chantilly/morangos, grade com cadeado,
  armadura com espinhos curvos, melancia cortada, gelo com cristais e floco,
  folhas de outono com nervuras/bolotas, capulhos de algodão e calêndula em camadas.
  Aprovado pelo usuário. Cópia salva em `build/backups/caixas-lote5-aprovado.blend`.
- Lote 06: reconstruído em `../lotes/caixas_fantasia.py`, com placas de obsidiana
  e magma, vento com nuvens e penas, robô com visor e painéis, fóssil em arenito,
  portal espiral, tigre, crocodilo, lince, papagaio e sapo entalhado em madeira.
  Relevos próprios na tampa e detalhes nas quatro laterais. Os cinco animais
  deste lote não constam na biblioteca de NPCs; são esculturas originais.
  Em revisão visual pelo usuário.

## Construção e exportação

Vento e vórtice têm controles e malhas independentes para animação futura,
com pivôs locais preservados no FBX. Consulte [ANIMACAO.md](ANIMACAO.md).

Executar no Blender em segundo plano a partir da raiz do projeto:

```text
blender -b --factory-startup --python assets/skins/build_caixas.py -- 5
blender -b --factory-startup --python assets/skins/export_roblox.py -- caixas
```

O primeiro comando reconstrói somente o lote indicado. O segundo gera FBX geral,
individuais, paleta, manifesto e validação em `../roblox/caixas/`, sem exportar
novamente corpo, livros e mochilas. Os FBX são reimportados para verificar nomes,
triângulos, UVs, texturas e dimensões. Isso não equivale à importação no Studio.

`../update_caixas_review.py -- <lote> <nomes...>` substitui apenas as coleções
indicadas e verifica que as demais não mudaram. Salvar antes as edições abertas.
Não executar `../gallery_caixas.py` sobre uma galeria com alterações manuais:
ele é apenas a montagem inicial das sete cenas.
