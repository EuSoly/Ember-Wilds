# Assets novos da loja (09/11): o que é cada um e onde entra

O Elizeu gerou por IA e mandou em `Downloads/UI Assets` (08–09/11). Este documento é o plano de uso. **Nada disso entra agora** (decisão do Elizeu, 09/11): o foco é a UI do Ranking; estes assets ficam guardados para depois. As fontes recortadas vão para `assets/ui/shop/` e os ids para `src/shared/ShopImages.luau` (envio na conta do Elizeu, com confirmação dele).

## 1. Borda da roleta com o ponteiro (`borda da roleta com o ponteiro.png`, 1254×1254)

Anel de madeira com gemas laranja, folhas embaixo e o ponteiro triangular já preso no topo.

- **Onde:** roleta dos cartões de giro da loja (`SpinTypes.luau`), no lugar das camadas `WHEEL_FRAME` + `WHEEL_POINTER` (vira uma camada só por cima do disco que gira).
- **Preparo:** recortar no quadrado da caixa útil (x 108–1132, y 55–1149) e reduzir para 1024. A abertura mede ~690 px de largura (x 274–964) com o centro em y ≈ 628 na imagem original; o disco (`WHEEL_DISC`) é centrado e redimensionado para essa abertura, como foi feito na roleta antiga (que era um pouco oval).
- O ponteiro avança para dentro do anel (ponta em y ≈ 348): o disco fica embaixo dele.

## 2. Fundos das raridades (`fundos das raridades.png`, 1983×793) — FEITO (09/11)

No jogo desde 09/11: `assets/ui/rarity/` (recorte por `prepare_rarity.py`), ids em `src/shared/RarityImages.luau`, montagem em `src/client/UI/RarityBackground.luau` (9 partes, cantos em 16% do lado). Usado na grade e nas amostras dos Cosméticos e nos quadradinhos da Loja (roleta, prêmio, prévia dos pacotes). A legenda das chances e o selo de raridade continuam em cor lisa.

Cinco quadrados arredondados com brilho, na ordem das raridades da tabela do Elizeu: cinza = Comum, azul = Raro, roxo = Épico, amarelo = Lendário, vermelho = Mítico.

- **Onde:** fundo de cada item com raridade: grade e carrossel dos Cosméticos (`CategoryView`, `CosmeticsScreen`), quadradinhos da roleta CS:GO e janelinha do prêmio (`SpinTile`, `SpinScreen`) e lista do pacote em destaque (`Featured`). Hoje esses fundos são pintados por código com `MockStore.RARITIES[].color`.
- **Preparo:** cortar os 5 (≈ 370×378 cada; colunas x 49–418, 430–798, 808–1175, 1187–1553, 1564–1934; y 203–581), reduzir para 256×256 e usar em 9 partes (cantos de ~48 px não esticam) para servir em qualquer tamanho.

## 3. Pacotes de moedas (`pacotes de moedas.png`, 1920×819)

Cinco ícones de Golden Ember em tamanho crescente (1 moeda, 2 moedas, montinho, pilha, saco cheio) e um cartão laranja com raios e uma barra verde embaixo.

- **Onde:** compra de Golden Ember (`EmberPacks.luau`). São exatamente 5 pacotes em `MockStore.PACKS` (300, 600, 2600, 7000, 20000): um ícone por pacote, em ordem (troca `COIN` / `COIN_STACK_2` / `COIN_STACK_3`). O cartão vira o fundo de cada pacote; a barra verde é onde vai o preço em Robux.
- **Preparo:** cortar os 5 ícones (512 máx.) e o cartão. O cartão usa proporção fixa (a barra verde faz parte do desenho), com o texto de quantidade em cima e o preço sobre a barra.

## 4. Banners dos pacotes em destaque (3 zips: Floresta, Gelo, Lula) — para o lançamento

São os **pacotes de skins do lançamento do jogo** (Elizeu, 09/11): ele adiantou a arte para já termos pacotes quando o jogo for lançado. Só mexer neles quando chegar essa hora.

Cada pacote traz um **fundo de cena vazio** (sem texto, skin nem botão) e **camadas soltas para animar** com TweenService: folhas caindo, vaga-lumes piscando, raios de luz pulsando, neblina andando, borboleta voando; neve, flocos, vento, cristais; bolhas subindo, água-viva flutuando, cardume, tentáculo. Os arquivos `02_*preview*` são só referência (o banner usa o modelo 3D da skin num ViewportFrame, não a imagem).

- **Onde:** pacotes em destaque da loja (`Featured.luau`), que hoje usam o cartão colorido provisório (`MockStore.BUNDLES`: brasa, geada, musgo). Geada ← Gelo e musgo ← Floresta; a Lula entra no lugar de um deles ou como 4º pacote (decisão do Elizeu).
- **Plano técnico:** um banner animado montado por dados: cada camada = imagem, posição/tamanho no banner, ZIndex (fundo < skin < partículas < primeiro plano) e uma animação simples da lista (cair em loop, flutuar, piscar, pulsar, deslizar, balançar, voar numa curva). Só anima com o banner visível; para o celular, poucas camadas por vez.
- **Atenção:** o Roblox reduz imagens a 1024 px no maior lado; os fundos (≈ 2170 px) ficam com 1024×~314. O fundo do **Gelo** tem outra proporção (2149×406, ~5,3:1) que os outros dois (~3,3:1): ou corta/estica, ou pedir à IA no mesmo formato dos outros.

## Perguntas abertas para o Elizeu

1. Quais skins entram em cada pacote (Floresta, Gelo, Lula) e qual pacote a Lula substitui (ou se vira o 4º).
2. Refazer o fundo do Gelo na proporção dos outros, ou cortar?
