# Assets de UI dos presentes (pedido ao Elizeu, 18/11)

Presentear = comprar um item da loja para **outro jogador do mesmo servidor**. O VIP não se presenteia. As regras de sempre valem (`assets-ui-monetizacao.md`): PNG com fundo transparente, **sem texto** (nome do jogador, nome do item e preço vão por código), estilo rústico do menu e da loja, peças que esticam com borda uniforme e centro liso (9 partes), ícones quadrados de pelo menos 512 px. Pode mandar numa folha só; eu recorto.

## Como a tela funciona (para saber o que desenhar)

1. Na loja, cada item que se pode dar ganha um **botão de presente** pequeno ao lado do preço.
2. Esse botão abre a **janela "Presentear"**: o item no topo e a **lista dos jogadores do servidor** (foto do avatar do Roblox + nome). Quem já tem o item (kit para sempre, 2×, livro) aparece apagado com "Já tem".
3. Escolheu o jogador → a janela de compra do Roblox → pago.
4. Quem recebe vê um **pop-up de presente**: a caixa abre, aparece o item e "Fulano te deu de presente". Quem deu vê "Presente enviado".

```
 ┌──────────── PRESENTEAR ────────────┐
 │   [ícone do item]  Kit Veterano     │
 │   Para quem?                        │
 │  ┌──────────────────────────────┐   │
 │  │ (foto) Fulano          [ ✓ ] │   │  ← linha selecionada
 │  │ (foto) Ciclano               │   │
 │  │ (foto) Beltrano   Já tem     │   │  ← apagada
 │  └──────────────────────────────┘   │
 │        [ Cancelar ] [ 🎁 399 ]      │
 └─────────────────────────────────────┘
```

## Peças

| # | Peça | Onde aparece | Estados / variações | Tamanho sugerido | Prioridade |
|---|---|---|---|---|---|
| 45 | **Ícone de presente** (caixinha com laço) | botão de presente nos cartões da loja e no botão de pagar da janela | 1 | 512 px; precisa ler em 24 px | essencial |
| 46 | **Laço de presente** para pôr por cima de um ícone | canto dos ícones dos itens na janela "Presentear" e nas capas dos produtos de presente no Creator Hub (eu ponho por cima de cada ícone que já temos) | 1 | 512 px, laço ocupando ~40% no canto de cima à direita, resto transparente | essencial |
| 47 | **Janela "Presentear"** | centro da tela, por cima da loja | 1 (se quiser, a mesma moldura do check-in, peça 11; aí não precisa) | ~900×700, estica em 9 partes | só se não reaproveitar |
| 48 | **Linha de jogador** da lista | uma por jogador do servidor | normal, selecionada (com brilho ou borda brasa) e apagada ("já tem") | ~700×110 deitada, estica em 9 partes | essencial |
| 49 | **Moldura da foto do avatar** | à esquerda de cada linha (a foto vem do Roblox) | 1 | 256 px, redonda ou quadrada com canto, centro vazio | essencial |
| 50 | **Marca de selecionado** | à direita da linha escolhida | 1 | 128 px (o check verde das missões serve; aí não precisa) | só se não reaproveitar |
| 51 | **Caixa de presente fechada** | pop-up de quem recebe, antes de abrir | 1 | 512 px | essencial |
| 52 | **Caixa de presente aberta** | pop-up de quem recebe, depois de abrir (o item aparece saindo dela) | 1, mesmo enquadramento da 51 para eu trocar uma pela outra | 512 px | essencial |
| 53 | **Painel do presente recebido** | pop-up central de quem recebe | 1 | ~800×600, estica em 9 partes | bom ter (sem ele uso a janela 47) |
| 54 | **Raios/confete** atrás da caixa aberta | pop-up de quem recebe | 1 camada branca (eu tinjo e animo) | 512 px | bom ter |
| 55 | **Ícone "ninguém para presentear"** | lista vazia (sozinho no servidor) | 1 | 512 px (caixa de presente com ponto de interrogação ou vazia) | bom ter |

## Já temos e vou reaproveitar

Ícones dos itens (kits 30–33, 2×, livro, pacotes e roletas da Golden Ember, boost), botões verde (Robux) e madeira (Cancelar), fita das ofertas, moldura e bolinha das missões, check verde das missões, símbolo do Robux.

## Produtos de presente no Roblox (eu crio)

Cada item que se pode dar vira um **produto de presente** no Roblox ("Presente: Kit Veterano"), mesmo as gamepasses, porque gamepass sempre fica com quem pagou. A capa é o ícone do item com o **laço (46)** por cima: não precisa arte nova para cada um.
