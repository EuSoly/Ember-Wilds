# Perfil e nível do jogador — design (UI 4)

Data: 04/11. Decisões do Elizeu marcadas como **(Elizeu)**; as minhas, como **(minha decisão)**.

## Por quê

O Perfil do menu hoje é mockup (números falsos do `MockStore.PROFILE`), e o "Nível 7, 340/500 XP" no canto do menu também. O Elizeu quer um **nível de verdade** porque pretende fazer um **passe de batalha** depois, e quer que o Perfil mostre os números reais do jogador. É a próxima UI da ordem combinada (Tutorial + Configurações → **Perfil** → Cosméticos → Ranking).

## Objetivos

1. Nível e XP reais, ganhos jogando.
2. Perfil mostrando as estatísticas reais do jogador, na ordem que o Elizeu pediu.
3. A placa de nível do menu passa a ser real.
4. A tela de morte mostra o XP ganho e quando sobe de nível.
5. Deixar o XP pronto para o passe de batalha usar depois, sem refazer nada.

## Fora do escopo

- Recompensas por nível, passe de batalha, temporadas.
- Ranking (próxima etapa) e o detalhe das estatísticas por tipo (criatura, item).
- Perfil de outros jogadores (só o próprio).
- Redesenho geral da tela de morte (só entra o pedaço do XP).

## O que não pode acontecer

- Perder o XP de quem já jogou: o XP inicial vem dos pontos que a pessoa já fez.
- O cliente poder mexer no XP/nível: tudo é calculado e salvo no servidor.
- Nível ou números falsos aparecendo como reais (o selo MOCKUP sai só do que virou real).

## Nível e XP

- **XP = os pontos de cada vida (Elizeu).** No fim da vida (morrer ou sair do jogo), os pontos da vida viram XP. É o mesmo momento em que os pontos já viram Golden Ember (`LifeService.endLife`).
- **Curva (Elizeu): cada nível pede 1.000 XP a mais que o anterior.** Subir do nível *n* para o *n+1* pede `1000 × n` XP. XP total para chegar ao nível *n* = `1000 × n × (n − 1) / 2`. Ex.: nível 2 = 1.000; 3 = 3.000; 4 = 6.000; 8 = 28.000; 10 = 45.000; 20 = 190.000; 50 = 1.225.000. Sem nível máximo. Começa no nível 1 com 0 XP.
- O passo (1.000) fica numa constante fácil de ajustar.
- **XP salvo como estatística** `xp_total` (contador) no perfil. O nível não é salvo: é calculado do XP (assim mudar a curva não estraga perfis).
- **Teto de XP por hora (Elizeu): até 100.000 XP por hora.** Rede de segurança contra trapaça e bug (ex.: dois amigos se matando para passar pontos pelo bônus de abate), no mesmo espírito do teto por hora da Golden Ember (`CurrencyService`). Quem joga normal (~30 mil numa partida) nunca bate. O que passar do teto na janela da hora não vira XP. A janela fica salva no perfil (sair e voltar não zera). Regra pura e testada no Lune; o valor do teto fica numa constante. Pontos fracionados viram XP arredondado para baixo.
- **O XP que entrou de verdade** (depois do teto) é o que soma em `xp_total` e o que a tela de morte mostra.
- **Quem já jogou (Elizeu confirmou começar do total de pontos; o jeito é minha decisão):** na primeira vez que o perfil carregar nesta versão, `xp_total` recebe o valor de `score_total` (o total de pontos de todas as vidas, que já é salvo) e o perfil fica marcado como "XP inicial feito" (campo novo no perfil, padrão `false`). **Sem subir a versão do esquema** (`SCHEMA_VERSION`): subir faria servidores antigos, abertos durante a atualização, recusarem perfis já migrados. O teto por hora não vale para esse XP inicial.
- **Passe de batalha depois:** o XP de cada vida passa por um ponto só (o fim da vida soma `xp_total`). O passe vai escutar esse mesmo ganho (`StatsService.onChanged` de `xp_total`, ou um evento próprio de "XP ganho") e somar numa trilha da temporada. Nada nesta etapa precisa saber do passe.

## Estatísticas que chegam ao cliente

Hoje as estatísticas ficam só no servidor. Passam a ser publicadas como atributos no Player, como já é feito com as configurações:

- Atributo `Stat_<id>` para cada estatística de `Defs.Stats` (prefixo novo em `StatNames`).
- Contador e recorde: o próprio valor. Por tipo (criaturas, recursos, itens): **o total somado** (o detalhe por tipo não vai para o cliente nesta etapa).
- Publicado ao carregar o perfil e a cada mudança (`StatsService.onChanged`).

**Estatísticas novas:**

- `days_total` (minha decisão, necessária para o pedido do Elizeu): contador que soma os dias sobrevividos de cada vida, no fim da vida.
- `real_deaths` (**Elizeu: o cartão "Mortes" conta só mortes de verdade**): contador somado quando o jogador morre de fato (`DeathService`), não quando sai do jogo. O `deaths` atual (toda vida terminada, inclusive saindo) continua existindo e salvo, mas não aparece no Perfil.

As duas começam do zero a partir desta atualização: não há como recuperar o passado (hoje só existe o recorde de dias, `days_best`, e as mortes antigas não separam morte de saída).

## O Perfil (tela)

**Visual (Elizeu):** janela no centro, no estilo rústico das Configurações (corpo escuro, placa de madeira "PERFIL" no alto, botão Fechar), **sem escurecer o menu atrás**. Continua sendo o painel "profile" do menu (abre pelo botão Perfil da coluna; abrir outro painel troca; Fechar volta ao "play").

**Ordem (Elizeu):**

1. Topo: nome do jogador, **NÍVEL N**, barra de XP do nível atual com "XP no nível / XP para o próximo" e o **XP total**.
2. Três cartões grandes: **Mortes** (`real_deaths`), **Dias sobrevividos** (`days_total`), **Recorde de dias** (`days_best`).
3. Lista **Outros**: Jogadores mortos, Criaturas mortas (total), Recursos coletados (total), Itens criados (total), Recorde de pontos numa vida (`score_best`), Tempo de jogo (`playtime_seconds`, formato "12h 30min"; menos de 1 h: "45min").

Números com separador de milhar ("18.300"). Tudo ao vivo (atributos): se mudar com o perfil aberto, a tela acompanha.

Esboço aprovado:

```
╔══════════════════ PERFIL ══════════════════╗
║  Elizeu                         NÍVEL 8    ║
║  ▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░  2.000 / 8.000 XP     ║
║  XP total: 30.000                          ║
║  ┌──────────┐ ┌──────────┐ ┌──────────┐    ║
║  │  Mortes  │ │   Dias   │ │ Recorde  │    ║
║  │    41    │ │ sobrev.  │ │ de dias  │    ║
║  └──────────┘ └──────────┘ └──────────┘    ║
║  OUTROS                                    ║
║  Jogadores mortos ............... 23       ║
║  ...                                       ║
║               [  Fechar  ]                 ║
╚════════════════════════════════════════════╝
```

No celular a janela ocupa quase a tela e a parte de baixo rola (como as Configurações), com o Fechar sempre à vista.

## Placa de nível do menu

A placa do canto (nível + barra de XP) passa a usar o nível e o XP reais; sai o selo MOCKUP dela.

## Tela de morte

**(Sugestão minha, aceita pelo Elizeu)** Além do que já mostra (pontos → Golden Ember), mostra **"+N XP"** (o XP que entrou de verdade, depois do teto) e a barra de XP enchendo do valor de antes até o de agora. Se passar de nível, a barra enche, volta do zero e aparece **"Subiu para o nível N!"**. O XP ganho vem no resumo da vida que o servidor já manda (`Net.LifeEnded`), que passa a levar também o XP ganho.

## Partes deixadas para quem implementar

- Como a barra da tela de morte entra no molde `Death` (elementos novos no molde com nomes combinados, ou feita em código dentro dele).
- Nomes de arquivos/módulos, desde que a regra do nível seja pura e testada no Lune (curva, nível a partir do XP, XP dentro do nível) e a formatação do tempo de jogo também.
- Medidas exatas da janela (seguir as Configurações).
