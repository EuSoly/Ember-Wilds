# Códigos de resgate — design curto

Data: 18/11/2026. Aprovado pelo Elizeu na conversa.

## Por quê
O Elizeu divulga códigos no servidor do Discord; os jogadores resgatam no jogo e ganham prêmios.

## Como o Elizeu cria um código
Pede ao Claude ("código X, dá tal e tal, vale até tal dia") e publica. Não há painel nem criação sem publicar.

## Abordagem (escolhida; a única que serve ao pedido)
Arquivo de dados `src/shared/Shop/Codes.luau` (como `Shop/Bundles.luau`): uma entrada por código, validada no boot. Descartadas: códigos num DataStore/painel (o Elizeu não quer criar sem publicar) e limite global de usos (precisaria de contador entre servidores).

## Regras
- Entrada: `{ code = "LANCAMENTO", rewards = { ... }, startsAt = "AAAA-MM-DD HH:MM"?, endsAt = "AAAA-MM-DD HH:MM"? }` (Brasília, `ShopDates.parse`). Prêmios = tipos de `Shop/Rewards` (Golden Ember, giros, skin, kit, kit de 1 vida, boost de XP, revive guardado...).
- Validação no boot (erro com a lista, como os pacotes): código só com A–Z e 0–9 (3 a 24), repetido, sem prêmio, prêmio inválido, data mal escrita, fim antes do começo.
- Cada jogador usa cada código uma vez (perfil `Shop.Codes`). Maiúsculas/minúsculas e espaços não importam.
- Recusas: não existe, ainda não começou, vencido, já usado, durante a partida (só no menu), pedido rápido demais (2 s entre tentativas).
- O servidor confere e entrega (`ShopService`), salva e responde com o texto dos prêmios.

## Tela
- Botão quadrado no menu embaixo do calendário do check-in (mesmo tamanho), só no menu "limpo" como o calendário. Ícone: arte nova do Elizeu (cupom/pergaminho com chave); até chegar, o ícone de presente.
- Janela pequena (moldura do check-in, `ScreenMetrics.modalPosition/Size`): título "Códigos", campo de texto, "Resgatar" e "Fechar"; resposta embaixo do campo ("Resgatado: 500 Golden Ember, 3 giros especiais" ou o motivo).

## Fica com quem constrói
Nomes dos módulos, tamanhos da janela, textos exatos das recusas.
