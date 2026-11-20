# Códigos de resgate

Desde 18/11/2026. Spec: `docs/superpowers/specs/2026-11-18-codigos-design.md`.

O jogador abre o botão embaixo do calendário do Prêmio Diário, **no menu** (na partida não existe), digita o código e ganha os prêmios. Cada jogador usa cada código **uma vez**. Maiúsculas, minúsculas e espaços não importam para quem digita.

## Como criar um código

Pedir ao Claude: "código NATAL, dá 500 Golden Ember e 3 giros especiais, vale de 20/12 até 26/12". Ele escreve a entrada em `src/shared/Shop/Codes.luau`, roda `bash scripts/check.sh` e o código vale **depois de publicar o jogo**.

Cada entrada:

- `code`: MAIÚSCULAS, só letras e números, de 3 a 24.
- `rewards`: os mesmos prêmios da loja (`Shop/Rewards`): `ember` (Golden Ember), `spins` (`normal` ou `paid`), `cosmetic` (skin), `kit` (para sempre), `kitOnce` (1 vida), `xpBoost` (segundos), `reviveCredit` (revive guardado).
- `startsAt` / `endsAt` (opcionais): `"AAAA-MM-DD HH:MM"` no horário de Brasília. Sem `startsAt` já vale; sem `endsAt` não vence. Vence no minuto exato do `endsAt`.
- `news = true` (opcional): código em destaque. A janela mostra **NOVO CÓDIGO: X** em cima do campo, e o botão acende a bolinha vermelha para quem ainda não usou. Vale o último marcado que estiver valendo agora; código novo de divulgação = marcar o novo (pode deixar o velho marcado, o último ganha).

O jogo confere o arquivo ao abrir e para com a lista de erros: código repetido ou mal escrito, prêmio que não existe, data mal escrita, fim antes do começo.

## A janela (20/11/2026)

- Botão com o **passarinho do Twitter** (`MonetizationImages.CODES_BIRD` = `rbxassetid://1181444986`, imagem pública da Creator Store, Decal 1181444990). O desenho nosso (`assets/ui/codigos/icone_passaro.png`) ficou em branco no jogo do grupo. Vazio = o ícone do pergaminho.
- **Bolinha vermelha** no botão enquanto há algo para pegar (código em destaque não usado ou prêmio do grupo) e o jogador ainda não abriu a janela nesta sessão. Atributos `CodeNotice` e `GroupClaimed` da pasta `Player.Shop` (o `ShopService` escreve).
- Duas colunas (cabe no celular deitado): à esquerda "NOVO CÓDIGO: X", "Mais códigos em breve no Discord do jogo!", campo, Resgatar e a resposta; à direita o cartão do grupo.

## Prêmio do grupo do Roblox

Grupo **Ember Wilds inc** (`557568805`). Quem entra ganha a skin **Gaio-azul** (`body_gaio_azul`, Limitada: fora dos giros, só aparece na grade para quem tem) + **200 Golden Ember**, uma vez por jogador.

- "Entrar no grupo" abre a janela do Roblox (`GroupService:PromptJoinAsync`). Entrou (ou já era), o cliente pede; o servidor confere com `Player:IsInGroupAsync`, marca `GROUP_557568805` em `Shop.Codes` (tem `_`, nunca bate com um código) e entrega pelo `ShopService.giveAll`.
- Grupo com pedido de entrada pendente: avisa para resgatar depois de aceito.
- Trocar o prêmio ou o grupo: `src/shared/Shop/GroupReward.luau` (`GROUP_ID = 0` esconde o cartão). Trocar o grupo dá o prêmio de novo a todos (a marca leva o id).

## Recusas que o jogador vê

Código não encontrado; ainda não começou; já venceu; já usou; espere um pouco (uma tentativa a cada 2 s, para ninguém testar códigos no chute); resgate pelo menu (pedido durante a partida).

## Onde fica cada coisa

- `src/shared/Shop/Codes.luau`: a lista de códigos.
- `src/shared/Shop/CodeRules.luau`: regras puras (normalizar, conferir, validar), testadas em `tests/coderules.spec.luau`.
- `src/server/Services/CodeService.luau`: confere e entrega (`ShopService.giveAll`), marca no perfil (`Shop.Codes`).
- `src/shared/Shop/GroupReward.luau`: grupo e prêmio do grupo.
- `src/client/Menu/CodePanel.luau`: botão (passarinho + bolinha) e janela (destaque + grupo).

## Códigos ativos

| Código | Prêmio | Validade | Onde saiu |
|---|---|---|---|
| `RELEASE` (destaque) | skin Gato (`body_gato`) + 1.000 Golden Ember | sem validade | anúncio de lançamento no Discord (19/11/2026) |

O `TESTE` (18/11) saiu no lançamento.
