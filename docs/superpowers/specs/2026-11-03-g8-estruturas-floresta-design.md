# G8 — Estruturas e modelos novos da floresta (design)

Data: 2026-11-03. Conversado com o Elizeu em chat. Ele modelou no Blender 55 modelos ("world-pack": construções dos 6 tiers, estruturas utilitárias, depósitos de minério e ícones de inventário), exportados e já importados no place em `Workspace["mundo-completo"]`.

## Intenção

Colocar no jogo os modelos novos **funcionando como no Starve.io** (regras da wiki: "as utilidades vc pode pegar da wiki"). Nesta fase entra **só o que dá para fazer com os recursos da floresta** (madeira, pedra, ouro, frutinha e o que os mobs da floresta deixam: peles de coelho, lobo e javali, pena, linha, carne). O resto fica escrito num plano para depois. As estruturas **novas** funcionam por completo, mas **só para teste** por enquanto: o Elizeu vai liberá-las aos jogadores em updates futuros. Times (totem) são a próxima etapa, não esta.

## Objetivos

1. **Trocar o visual do que já existe** (continua liberado como hoje), usando os modelos do Elizeu:
   - paredes, portas e espinhos de madeira, pedra e ouro (`<tier>_wall`, `<tier>_door`, `<tier>_spike`);
   - bancada (`workbench`), baú (`chest`), fogueira (`campfire`), fogueira grande (`big_fire`; no jogo o item é `big_campfire`);
   - depósitos de pedra e ouro no lugar das rochas e veios de ouro do mapa (modelos `stone_deposit_icon` e `gold_deposit_icon`, a versão "do inventário para o mapa").
2. **Peças que se mexem** (o export já as separa):
   - **porta**: as duas folhas (`*_panel_left`/`*_panel_right`) deslizam para os lados ao abrir (sugestão do Blender: ±2,25 em X local, antes da escala) em vez de ficarem translúcidas;
   - **baú**: a tampa (`chest_lid`, pivô na dobradiça) abre (−105° em X local do Blender) enquanto alguém olha o baú;
   - **fogueiras e fornalha**: as chamas (`*_flames`) ficam separadas para brilho/efeito e para sumir quando apagar;
   - **extratores**: o rotor (`*_rotor`) gira em torno do eixo vertical enquanto trabalha.
3. **Estruturas novas, funcionando, só para teste** (regras da wiki; números sem fonte = provisórios, escolha minha):
   - **Portas com espinhos** de madeira, pedra e ouro (`<tier>_spike_door`): porta (abre e fecha para o dono/aliados, como a porta) que fere quem não é aliado ao encostar, como o espinho do mesmo tier.
   - **Extrator de pedra e de ouro** (`stone_extractor`, `gold_extractor`): o jogador põe madeira (não dá para tirar de volta); enquanto tiver madeira, gasta **2 madeiras a cada 10 s** e produz o minério do tipo, que fica guardado até o jogador pegar (dono e aliados). Quanto produz por ciclo e o limite guardado: provisórios.
   - **Fornalha** (`furnace`): "baú de mão única" de madeira (põe, não tira); enquanto tiver ao menos 1 madeira, **queima 1 a cada 6 s** e esquenta (fonte de calor maior que a fogueira; não queima quem encosta). Sem madeira, apaga.
   - **Ponte** (`bridge`): só se coloca sobre a água; quem está em cima não perde oxigênio nem fica lento como na água (ponte = chão).
   - **Telhado** (`roof`): colocado na altura das paredes, por cima de outras peças; protege quem está embaixo de ataque de mob voador (o falcão não morde quem está sob telhado); fica translúcido para o próprio jogador quando ele está embaixo (para ver a base). Nevasca e tempestade de areia ficam para quando esses biomas existirem.
   - **Placa** (`sign`): sinaliza para outros jogadores; mostra um símbolo escolhido de uma lista fixa (sem texto livre: texto de jogador exige filtro do Roblox). Receita da wiki: 20 madeiras.
   - **Poço** (`well`) e **balde** (`bucket`, item novo): o balde enche na água do mapa; esvaziar no poço adiciona água (**1 balde = 12 garrafas** da wiki); o jogador bebe no poço (sede). Do balde não se bebe.
   - **Cama** (`bed`): deitar dá mais regeneração de vida e gasta menos fome, frio e sede enquanto deitado; andar levanta. Receita da wiki: 100 madeiras, 50 pedras, 5 peles de lobo, 5 peles de coelho e 6 linhas.
4. **Ícones 3D no inventário** de madeira, pedra e ouro (`wood_viewport`, `stone_viewport`, `gold_viewport`), no lugar das letras ("Ma", "Pe", "Ou") nos slots.
5. **"Só para teste"**: os itens das estruturas novas (e o balde) ficam marcados nos dados. Fora do Studio eles não aparecem no craft, nos kits nem em loja, e não podem ser obtidos. No Studio, aparecem e funcionam normalmente (craft e `DevGive`) para testar. Liberar num update = tirar a marca.
6. **Plano para depois** salvo no repositório (doc), com o que fica pronto para quando houver recursos: diamante, ametista e reidite (construções, portas com espinhos, extratores, depósitos e ícones), esmeralda (depósito, ícone, máquina de esmeralda), pedra de ressurreição, totem e times.

## Não-objetivos

- Times e totem (próxima etapa).
- Tiers diamante, ametista e reidite; esmeralda; pedra de ressurreição; máquina de esmeralda (vão para o plano).
- Biomas novos (inverno, deserto, lava), nevasca, tempestade de areia.
- Liberar as estruturas novas para os jogadores (decisão de update futuro).
- Arte nova: os modelos são os do Elizeu; efeitos (brilho, partículas) só o necessário para ler o estado (aceso/apagado, girando).

## Anti-objetivos

- Uma estrutura "só para teste" aparecer ou ser obtida num servidor de verdade.
- Quebrar o que já funciona: colocar peças (giro, colisão, regras da G4), portas abrindo para aliados, espinhos ferindo, baú, fogueiras com calor, coleta das rochas.
- Números inventados apresentados como "do Starve": o que não veio da wiki fica marcado como provisório.

## Como funciona (decisões)

- **Modelos**: os 55 ficam no place como templates (onde exatamente é do builder, seguindo o padrão das ferramentas: `ReplicatedStorage.Assets.*` ou `ServerStorage.Assets.*`), com o mesmo id do item/recurso. O visual das construções sai do `StructureModel` (o arquivo já foi feito para "trocar o visual = mexer só aqui"); o dos recursos sai do `ResourceModels` (que já lê modelos do Studio por nome). A colisão continua a das regras atuais (círculo da peça), não a malha.
- **Escala e encaixe**: os modelos vieram em studs próximos do jogo (parede ≈ 3,9 de diâmetro, círculo da peça hoje = 4). Ajuste fino de tamanho/altura com o mesmo esquema que o Elizeu aprovou nas armas: uma **bancada no Edit** onde ele mexe e eu capto (escolha minha, a combinar como tarefa de ajuste).
- **Só para teste**: uma marca nos dados do item (`Defs/Items`) lida num lugar só; craft, kits, loja e `DevGive` respeitam (fora do Studio: não existe para o jogador). Escolha minha.
- **Regras das estruturas novas**: dados em `Defs` (vida, receita, números de produção/queima/água/cama), regras puras testadas no Lune, servidor autoritativo (Server Authority), como o resto do jogo.
- **Receitas**: as da wiki quando conhecidas (cama, placa); as outras provisórias, marcadas no código e no doc.
- **"Fora do Studio"** = `RunService:IsStudio()` falso (servidor de verdade, inclusive privado). Não há dado salvo a limpar: inventário e base não persistem (sair = morte), então nenhuma peça "só para teste" sobrevive de uma sessão do Studio para um servidor de verdade.
- **Persistência**: nenhuma. Estoque do extrator, madeira da fornalha, água do poço, balde cheio, placas e camas vivem só enquanto a peça existe no servidor, como o baú hoje.
- **Aliados** = só o dono por enquanto (`BuildRules.areAllies` continua o único ponto; times entram na próxima etapa por ele).
- **Telhado e ponte** são exceções da regra de "uma peça por círculo" da G4 (escolha minha): o telhado fica numa camada de cima e pode cobrir outras peças (não colide com elas nem com o jogador); a ponte só se coloca sobre a água e não pode ficar sobre outra ponte. A proteção do telhado é conferida pelo círculo dos telhados colocados na posição do alvo (sem raycast).
- **Cama** (escolha minha): deita ao usar a cama de perto; levanta ao andar (qualquer movimento) ou ao levar dano; deitado continua podendo ser atacado; o bônus soma com o calor da fogueira.
- **Números provisórios do extrator** (escolha minha): sem deixar a mineração inútil, isto é, produzir mais devagar que bater numa rocha com picareta do mesmo nível.

## O que fica para quem implementa

Onde guardar os templates, os números provisórios (vida das peças novas, produção do extrator, calor da fornalha, bônus da cama), a lista de símbolos da placa, como o balde mostra cheio/vazio, como o jogador interage com poço/cama/extrator/fornalha (o padrão do baú: chegar perto e abrir um painel, ou golpe/uso com o item na mão), a organização dos arquivos.
