## Identidade visual — survival para o Roblox

Oct 28, 2026 · @Elizeu Walczuk Ruthes

### Conceito e direção de arte

A direção é um low-poly "de brinquedo" visto de cima, com o contraste entre o frio azul da noite e o laranja do fogo como assinatura visual. Ele roda bem no celular, é rápido de modelar sozinho e fica bem diferente do visual 2D chapado do Starve.io.

#### Quatro pilares

- Legível de cima e no celular. Silhuetas grossas e formas simples: uma árvore, uma rocha ou uma jazida tem que ser reconhecida em 1 segundo numa tela de 6 polegadas.

- Quente contra frio. De noite o mundo fica azul e escuro, e o fogo vira o único ponto quente da tela. A fogueira é o símbolo do jogo: aparece no logo, no ícone e na tela de carregamento.

- Tier é cor. Madeira, pedra, ouro, diamante, ametista e reidite têm uma cor fixa, que se repete na jazida, na ferramenta, na parede, na moldura do ícone e na raridade dos cosméticos. O jogador aprende a progressão sem ler nada.

- Mundo vivo, não sombrio. Cores saturadas de dia, sem sangue nem gore. O perigo vem da noite, do frio e dos outros jogadores, não de visual pesado.

#### O que muda em relação ao Starve.io

|  | Starve.io | Nosso jogo |
|---|---|---|
| Estilo | 2D chapado, formas de círculo, quase sem animação | 3D low-poly com volume, sombra e animação em tudo que se mexe |
| Personagem | Bolinha com duas mãos | O avatar Roblox do próprio jogador, com capacete e roupa do jogo por cima |
| Interface | Barras retas embaixo da tela | Anéis de status, hotbar grande para o polegar e cartas de crafting |
| Noite | Tela escurece por igual | Escurece e fica azul, e a luz do fogo pinta o chão em volta |
| Nomes e ícones | Do jogo original | Todos próprios |

Usar o avatar do jogador é a decisão mais importante: no Roblox as pessoas gostam de ver o próprio personagem, e isso abre espaço para cosméticos que combinam com o avatar.

### Nome e logo

O nome provisório é Ember Wilds ("brasa" + "terras selvagens"): curto, em inglês para o público global do Roblox, e aponta direto para o fogo, que é o centro do jogo. Antes de fechar, buscar o nome no Roblox e no INPI para ver se já existe.

| Opção | Por que funciona | Ponto fraco |
|---|---|---|
| Ember Wilds | Fogo + natureza, fácil de lembrar | Não diz "survival" |
| Last Ember | Cria tensão: a última brasa antes da noite | Soa mais sério e sombrio |
| Frostfire Survival | Mostra o contraste frio x fogo; "Survival" ajuda na busca do Roblox | Longo e mais genérico |
| Brasa | Curto e forte em português | Fraco para o público de fora do Brasil |

esboço de logo e ícone · nome provisório Ember Wilds

O ícone repete o logo sem texto, porque na lista de jogos do Roblox ele aparece pequeno. A fonte do esboço é só ilustrativa; o logo final usa Luckiest Guy com contorno escuro, como na seção Tipografia.

### Paleta de cores

A cor de cada tier é a mesma em tudo: jazida, ferramenta, parede, moldura do ícone e raridade de cosmético (madeira = comum até reidite = lendário). As barras de status usam cores que não se confundem entre si, e a cor de ação da interface é o laranja da brasa.

paleta · tiers, barras de status e biomas

#### Cores da interface

| Token | Hex | Uso |
|---|---|---|
| fundo-painel | #1E2230 (85% opaco) | Fundo de painéis e do HUD |
| painel-elevado | #2A3042 | Cartas de receita, slot selecionado |
| borda | #3A4258 | UIStroke de painéis e slots |
| texto | #F4F1EA | Texto principal (branco quente) |
| texto-secundario | #A9B0C2 | Descrições e rótulos |
| acao | #FF8A1F | Botão principal, seleção, destaques |
| sucesso | #4CC38A | Craft possível, construção válida |
| aviso | #F5C542 | Barra em 35%, noite chegando |
| perigo | #E5484D | Dano, construção inválida, barra vazia |
| slot-vazio | #FFFFFF a 8% | Fundo de slot sem item |

As cores ficam num ModuleScript único (Theme) que a interface e os efeitos leem, para trocar uma cor em um só lugar.

### Tipografia

São três fontes, todas da biblioteca nativa do Roblox, então não há upload nem licença: uma pesada e divertida para títulos, uma arredondada para números e botões, e a fonte padrão do Roblox para textos longos.

| Uso | Fonte | Peso | Tamanho (referência 1920×1080) |
|---|---|---|---|
| Logo, títulos de tela, "Você morreu" | Luckiest Guy | Único | 48–72 |
| Números do HUD, contadores, botões | Fredoka One | Único | 20–28 |
| Nomes de item e rótulos | Builder Sans | Bold | 16–18 |
| Descrições, chat, tooltips | Builder Sans | Medium | 14–16 |

#### Regras

- Todo texto branco quente (#F4F1EA) leva UIStroke de 1,5–2 px em #1E2230 para continuar legível sobre neve, areia ou lava.

- Usar TextScaled com UITextSizeConstraint (mínimo 12, máximo do tamanho da tabela) para não ficar ilegível em celular pequeno.

- Números que mudam rápido (recursos, dano) sempre em Fredoka One: ela tem algarismos largos e fáceis de ler em movimento.

- Antes de fechar, conferir no seletor de fontes do Studio se as três aparecem com esses nomes.

### Interface (HUD)

A tela foi pensada primeiro para o celular na horizontal: tudo que o polegar toca fica nos cantos de baixo, as informações ficam nos cantos de cima, e o centro fica livre para ver o mundo. No PC, joystick e botões somem e a hotbar responde às teclas 1–0.

HUD no celular (paisagem) · 9 elementos

#### Regras dos componentes

| Componente | Regra |
|---|---|
| Botões de toque | No mínimo 44×44 px; o de ação tem 72 px. Nada tocável a menos de 12 px da borda da tela |
| Painéis | Fundo #1E2230 a 85%, UICorner de 12 px, UIStroke de 1 px #3A4258 |
| Slots | 40–56 px, UICorner 8 px; o selecionado ganha borda laranja (#FF8A1F) de 2 px |
| Anéis de status | 4 anéis fixos acima da hotbar; oxigênio e calor só aparecem no bioma que usa cada um |
| Receitas | Mostrar só o que dá para craftar agora, com borda verde; tocar crafta. O catálogo completo fica no livro de receitas |
| Moldura de item | Cor do tier na borda e no fundo a 15% (ver Ícones) |
| Escala | Tudo em Scale com UIAspectRatioConstraint; testar no emulador do Studio em celular pequeno, tablet e 1080p |
| Notificações | No máximo 2 na tela; somem em 3 s |

#### Telas fora do HUD

| Tela | O que tem | Nível |
|---|---|---|
| Inventário | Grade 4×4, arrastar para a hotbar, segurar para descartar | N0 |
| Livro de receitas | Abas por estação (mão, bancada, fogo); receitas bloqueadas aparecem em cinza | N0 |
| Morte | Causa da morte, dias sobrevividos, pontos e moeda ganha, botão "Jogar de novo" grande | N0 |
| Loja | Abas Cosméticos, Moeda e Passes; preço sempre visível; chances das caixas em destaque | N0 |
| Ranking | Top 10 do servidor, com você fixado embaixo | N0 |
| Configurações | Volume por grupo, qualidade gráfica, tamanho da interface, inverter botões para canhotos | N0 |
| Time (totem) | Membros, expulsar, trancar | N1 |
| Quests | Lista das chrono quests com prazo correndo | N2 |

### Ícones de itens

Cada ícone é uma silhueta grossa com contorno escuro, vista em 3/4 de cima, dentro de uma moldura com a cor do tier. Uma ferramenta tem o mesmo desenho em todos os tiers e só troca a cor da cabeça, igual aos modelos 3D.

ícone de picareta nos 6 tiers

#### Regras de produção

- Arte-fonte em 512×512, exibida entre 40 e 96 px. Testar sempre no tamanho de 40 px: se não dá para reconhecer, simplificar.

- Contorno #1E2230 de cerca de 16 px na arte de 512 (vira 1–3 px na tela). Luz vindo de cima à esquerda.

- Cada cor usa 3 tons (base, sombra e brilho), sem degradê. O item ocupa 80% da moldura e nunca tem texto.

- Moldura: borda de 3 px na cor do tier e fundo na mesma cor a 15%. Itens sem tier (comida, recursos) usam moldura cinza neutra.

- O jeito mais rápido de manter tudo igual é renderizar o próprio modelo 3D no Studio com fundo transparente e só retocar o contorno. Evitar ViewportFrame ao vivo na hotbar: pesa no celular.

- PNG com fundo transparente, nome icon_<categoria>_<item>_<tier> (ex.: icon_ferramenta_picareta_ouro), upload em lote pelo Asset Manager.

### Assets 3D

Todo o cenário é low-poly com sombreamento chapado e usa uma única textura de paleta (256×256, um quadrado por cor). Cada modelo só aponta o UV para os quadrados da paleta, o que deixa as cores sempre iguais às da seção Paleta e gasta pouca memória no celular.

#### Câmera e escala

- Câmera fixa de cima, inclinada cerca de 65° (não 90°), para os objetos mostrarem volume. Então o que mais importa em cada modelo é a parte de cima: copa da árvore, topo da rocha, cristal da jazida.

- Avatar com cerca de 5 studs de altura. Grid de construção de 4×4 studs: uma parede ocupa um quadrado.

- Tudo que o jogador coleta precisa ser pelo menos 1,5x maior que o avatar visto de cima.

#### Orçamento por asset

| Asset | Triângulos | Textura | Observação |
|---|---|---|---|
| Árvore | 200–600 | Paleta | 3 variações por bioma, girar e escalar para variar |
| Rocha e jazida | 80–300 | Paleta | 3 estágios: cheia, pela metade, quase vazia |
| Arbusto e plantação | 100–250 | Paleta | Um modelo por estágio de crescimento |
| Parede, porta, espinho | 50–300 | Paleta | Mesmo modelo para todos os tiers (ver abaixo) |
| Fogueira, fornalha | 200–400 | Paleta | Fogo é partícula + PointLight, não malha |
| Ferramenta e arma | 100–400 | Paleta | Tool com Handle; mesmo modelo por tier |
| Capacete e roupa | 200–800 | Paleta | Accessory preso ao avatar |
| Mob pequeno (coelho, aranha) | 300–1.000 | Própria 256 px | Rig simples com 4–8 ossos |
| Mob médio (lobo, urso) | 800–2.000 | Própria 256 px | Rig de quadrúpede |
| Boss (dragão, kraken) | 3.000–8.000 | Própria 512 px | Pode ter brilho (Neon) em partes |

#### Linguagem de forma por tier

Um só modelo serve para todos os tiers: muda a cor da paleta e ganha um detalhe que cresce a cada tier. Isso corta o trabalho de arte em cerca de 6 vezes.

| Tier | Jazida | Detalhe na ferramenta e na parede |
|---|---|---|
| Madeira | Árvore | Veios e nós de madeira |
| Pedra | Rocha arredondada cinza | Pedra amarrada com corda |
| Ouro | Rocha com veios amarelos | Faixas e rebites de ouro |
| Diamante | Cristais ciano saindo da rocha | Cristal na ponta ou no centro |
| Ametista | Cristais roxos pontudos e mais altos | Cristais pontudos e leve brilho |
| Reidite | Rocha escura com rachaduras magenta brilhantes | Rachaduras com Neon e partícula de faísca |
| Esmeralda | Cristais verdes hexagonais | Só em itens de dragão e na máquina |

#### Personagem e mobs

- O jogador usa o próprio avatar R15, mas com proporções travadas pelo servidor (HumanoidDescription com altura e largura fixas). Sem isso, avatares gigantes ou minúsculos teriam hitbox diferente no PvP.

- Mobs são designs próprios: formas exageradas, cabeça grande, cor de corpo + uma cor de destaque. Hostis têm olhos com brilho de noite; passivos, não.

- Cada mob precisa de 5 animações: parado, andando, atacando, tomando dano e morrendo.

### Animações e feedback

Toda ação do jogador responde em menos de 100 ms com movimento, partícula e som, porque é isso que faz bater em árvore ser gostoso por horas. Animação de interface nunca passa de 300 ms. Curvas padrão: Quad Out para entrar, Quad In para sair e Back Out para "pulos".

#### Gameplay

| Evento | O que acontece na tela | Duração | Como fazer no Roblox |
|---|---|---|---|
| Golpe em árvore ou rocha | A jazida encolhe e volta (100% → 92% → 100%), solta lascas na cor do tier, e um "+3" sobe e some | 150 ms + 600 ms do número | TweenService, ParticleEmitter:Emit(8), BillboardGui |
| Ataque com arma | Golpe do avatar com rastro na cor do tier | 250–350 ms | Animation no Animator + Trail na arma |
| Tomar dano | Borda da tela pisca vermelho, personagem brilha vermelho e recua um pouco, número de dano | 120–200 ms | Highlight, ImageLabel de vinheta, BillboardGui |
| Barra abaixo de 35% | O anel pulsa e o ícone treme; com vida abaixo de 25%, batimento cardíaco | Pulso a cada 0,8 s | Tween em loop + Sound |
| Barra vazia | Anel cinza piscando e vinheta na cor da barra (azul no frio, laranja na fome) | Contínuo | ImageLabel com transparência animada |
| Craftar | Anel de progresso sobre o ícone durante o tempo da receita; no fim o item "pula" para o slot (0 → 115% → 100%) | Tempo da receita + 250 ms | UIGradient girando ou anel em 8 partes |
| Colocar construção | Peça fantasma verde (pode) ou vermelha (não pode) presa ao grid; ao confirmar, sobe do chão com poeira | 200 ms | Modelo translúcido + Tween + ParticleEmitter |
| Construção tomando dano | Treme e mostra rachaduras em 2 estágios (66% e 33% de vida) | 100 ms | Decal de rachadura trocado por vida |
| Fogueira | Chama e faíscas, luz piscando ±15%; nos últimos 20% do tempo a chama diminui | Contínuo | 2 ParticleEmitters + PointLight com brilho variando a cada 0,1–0,2 s |
| Pegar item do chão | Item voa até o jogador e some com "pop" | 300 ms | Tween de posição + Sound |
| Mob hostil vê você | "!" sobre a cabeça | 600 ms | BillboardGui |
| Anoitecer | Aviso "A noite está chegando" 30 s antes; a luz muda aos poucos | 20 s de transição | Tween em Lighting.ClockTime e ColorCorrection |
| Morte | Câmera se afasta, mundo perde a cor, tela "Você morreu" contando pontos virando moeda | 1 s + contagem | ColorCorrection.Saturation para -1 |
| Quest ou nível completo | Faixa desce do topo e solta confete na cor do tier | 400 ms | Tween de UI + ParticleEmitter na tela |

#### Interface

| Elemento | Animação | Duração |
|---|---|---|
| Botão apertado | Encolhe para 95% e volta | 80 ms |
| Painel abrindo | Desliza 24 px e aparece | 200 ms |
| Slot recebendo item | Pula para 110% e volta, contador sobe | 150 ms |
| Item raro obtido | Moldura do tier brilha e gira um raio de luz atrás | 600 ms |
| Notificação | Entra pela direita e sai sozinha em 3 s | 200 ms entrada |

Um só módulo de "juice" (ModuleScript no cliente) deve concentrar essas funções, para que todo item novo ganhe o mesmo feedback de graça.

### Iluminação e clima por bioma

A noite é o momento mais importante do visual: o mundo fica azul e escuro o bastante para o fogo dominar a tela, mas nunca tão escuro que o jogador no celular deixe de ver o lobo chegando. Cada bioma muda a iluminação quando o jogador entra nele (detecção de zona no cliente + Tween de 2 s).

#### Configuração base

- Lighting.Technology em ShadowMap; o Roblox reduz sozinho a qualidade no celular.

- Um ColorCorrectionEffect e um Atmosphere fixos em Lighting, só com os valores mudando por bioma e horário.

- Fogueira: PointLight cor #FFA43A, alcance de 18 studs (igual ao raio de calor, para o jogador ver até onde esquenta), brilho 2 de noite e 0,5 de dia.

#### Por bioma

| Bioma | Dia | Noite | Clima e efeitos | Nível |
|---|---|---|---|---|
| Floresta | Tom levemente quente (#FFF6E8), névoa leve | Tom azul (#7F9CD6), ambiente #1B2A4A, brilho -0,1 | Vaga-lumes e folhas caindo (partículas leves) | N0 |
| Inverno | Tom frio (#EAF4FF), saturação -10%, neve leve | Azul mais escuro (#6C85C9) | Nevasca: partículas densas, névoa branca e vento; enxerga-se metade da distância | N2 |
| Praia e oceano | Tom claro (#F0FBFF), água #4FC3D9 | Água escurece para #1F3F6F, reflexo da lua | Espuma na beira e bolhas quando o oxigênio cai | N3 |
| Deserto | Tom quente (#FFE2B0), saturação +10% | Tom frio (#8A8FC7): o deserto esfria de noite | Tempestade de areia: névoa cor de areia (#E8B86D) densa e partículas laranja | N4 |
| Lava | Céu de fumaça, tom avermelhado (#FFB09A), névoa #3A2B2E | Quase igual ao dia: a luz vem da lava, de baixo | Brasas subindo, lava em Neon #FF5A1F com luzes espalhadas | N4 |

Dentro de casa (embaixo de telhado), a tela escurece 10% e o som abafa, para o jogador sentir que está protegido.

### Som

O som conta a hora do dia antes da luz: os grilos começam e a música fica tensa quando a noite se aproxima. Para começar, dá para usar a biblioteca de áudio licenciada do Creator Store do Roblox, sem custo.

| Momento | Ambiente e música | Nível |
|---|---|---|
| Floresta de dia | Pássaros e vento leve; música acústica calma | N0 |
| Floresta de noite | Grilos e uivo distante; música grave e lenta | N0 |
| Inverno | Vento constante; nevasca mais alta e abafada | N2 |
| Oceano e praia | Ondas, gaivotas; debaixo d'água, som abafado | N3 |
| Deserto | Vento seco; tempestade com chiado de areia | N4 |
| Lava | Borbulhar e ronco grave | N4 |
| Boss | Percussão forte enquanto a luta durar | N2 |

| Efeito | Som | Regra |
|---|---|---|
| Golpe em madeira / pedra / minério | Toc / clink / clink brilhante | O tom sobe a cada tier: o jogador ouve que está minerando algo melhor |
| Craft concluído | "Ding" curto | Mais longo para item raro |
| Construção colocada | Batida seca | — |
| Fogueira | Crepitar | Som 3D, some a 30 studs |
| Dano e vida baixa | Impacto e batimento cardíaco | Batimento só com vida abaixo de 25% |

Todo efeito repetido varia o tom em ±5–10% a cada vez, para não cansar. Música, ambiente e efeitos ficam em SoundGroups separados, com volume ajustável nas configurações.

### Lista de produção do MVP

Para o lançamento (N0) são cerca de 25 modelos, 35 ícones, 8 telas de interface e 15 sons. A ordem abaixo é a que destrava o jogo mais cedo: paleta e cenário primeiro, marca por último.

#### Modelos 3D

- ☐ Textura de paleta 256×256 com todas as cores da seção Paleta

- ☐ 3 árvores, 2 rochas e 1 jazida de ouro, cada uma em 3 estágios

- ☐ Arbusto de frutinha (com e sem fruto) e lago

- ☐ Bancada, fogueira e fogueira grande

- ☐ Parede, porta, espinho e porta-espinho (cores de madeira e pedra)

- ☐ Picareta, espada e lança (1 modelo cada, cores de madeira, pedra e ouro)

- ☐ Capacete (madeira e pedra), protetor de orelha, mochila, garrafa

- ☐ Coelho, lobo e aranha, com 5 animações cada

- ☐ Animações do avatar: golpe de ferramenta, golpe de espada, estocada de lança, comer, beber

#### Ícones e interface

- ☐ Cerca de 35 ícones de item e 4 de status (vida, fome, frio, sede)

- ☐ HUD: anéis de status, hotbar, minimapa e relógio de dia/noite

- ☐ Telas: crafting, inventário, morte, loja, configurações, ranking

- ☐ Controles de toque: joystick, botão de ação, botão de construir

#### Efeitos e som

- ☐ Partículas: lascas por tier, fogo, faíscas, poeira, folhas, vaga-lumes

- ☐ Vinhetas de tela: dano, frio, fome

- ☐ Cerca de 15 efeitos sonoros e 2 músicas (dia e noite)

#### Marca

- ☐ Logo final

- ☐ Ícone da experiência (512×512) e 3 thumbnails (1920×1080)