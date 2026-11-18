# Códigos de resgate

Desde 18/11/2026. Spec: `docs/superpowers/specs/2026-11-18-codigos-design.md`.

O jogador abre o botão embaixo do calendário do Prêmio Diário, **no menu** (na partida não existe), digita o código e ganha os prêmios. Cada jogador usa cada código **uma vez**. Maiúsculas, minúsculas e espaços não importam para quem digita.

## Como criar um código

Pedir ao Claude: "código NATAL, dá 500 Golden Ember e 3 giros especiais, vale de 20/12 até 26/12". Ele escreve a entrada em `src/shared/Shop/Codes.luau`, roda `bash scripts/check.sh` e o código vale **depois de publicar o jogo**.

Cada entrada:

- `code`: MAIÚSCULAS, só letras e números, de 3 a 24.
- `rewards`: os mesmos prêmios da loja (`Shop/Rewards`): `ember` (Golden Ember), `spins` (`normal` ou `paid`), `cosmetic` (skin), `kit` (para sempre), `kitOnce` (1 vida), `xpBoost` (segundos), `reviveCredit` (revive guardado).
- `startsAt` / `endsAt` (opcionais): `"AAAA-MM-DD HH:MM"` no horário de Brasília. Sem `startsAt` já vale; sem `endsAt` não vence. Vence no minuto exato do `endsAt`.

O jogo confere o arquivo ao abrir e para com a lista de erros: código repetido ou mal escrito, prêmio que não existe, data mal escrita, fim antes do começo.

## Recusas que o jogador vê

Código não encontrado; ainda não começou; já venceu; já usou; espere um pouco (uma tentativa a cada 2 s, para ninguém testar códigos no chute); resgate pelo menu (pedido durante a partida).

## Onde fica cada coisa

- `src/shared/Shop/Codes.luau`: a lista de códigos.
- `src/shared/Shop/CodeRules.luau`: regras puras (normalizar, conferir, validar), testadas em `tests/coderules.spec.luau`.
- `src/server/Services/CodeService.luau`: confere e entrega (`ShopService.giveAll`), marca no perfil (`Shop.Codes`).
- `src/client/Menu/CodePanel.luau`: botão e janela. Ícone: `MonetizationImages.CODES_ICON` (vazio = o de presente).

## Código de teste

`TESTE` (100 Golden Ember, vence 30/11/2026): tirar antes do lançamento.
