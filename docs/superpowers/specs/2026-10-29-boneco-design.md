# Ember Wilds — Boneco próprio, animações, expressões e skins (design)

Data: 2026-10-29 · Status: aguardando aprovação do Elizeu (revisado por um builder independente)
Relacionado: `docs/superpowers/specs/2026-10-28-ember-wilds-mvp-design.md` (spec do MVP), `docs/guia/arquitetura.md`.

Legenda: **[Elizeu]** = decidido por ele em conversa · **[Claude]** = decisão técnica minha · **[builder]** = quem implementa decide.

## 1. Intenção

O jogador deixa de ser o avatar do Roblox e passa a ser um **boneco próprio no estilo Starve.io** (referências: Starve.io e Tribe Survival/moomoo.io) [Elizeu]. Motivos:
- identidade visual do jogo, legível na câmera de cima;
- **skins** no estilo do original: muda o corpo inteiro; depois, skins de ferramenta/arma e armaduras [Elizeu];
- todo mundo com o mesmo tamanho e hitbox (justo no PvP).

O boneco precisa "ter vida": andar, bater, piscar e reagir a dano, com espaço para expressões futuras (frio, calor…) [Elizeu].

## 2. Objetivos, não-objetivos e anti-objetivos

**Objetivos**
1. Personagem do jogador = boneco próprio (sem avatar do Roblox), igual para todos.
2. Visual aprovado no spike (seção 4).
3. Animações: parado (respira), andar, golpe com ferramenta, soco de mão vazia.
4. Expressões: dano (olhos "> <") e piscar; sistema pronto para novas expressões como dados.
5. Skins de corpo como dados (cosméticos do slot `body` em `Defs/Cosmetics.luau`), aplicadas por jogador; pronto para skins de ferramenta/armadura no futuro (outros slots).
6. Todos veem as animações e expressões de todos.
7. Nome do jogador e balões de chat aparecem em cima do boneco [Elizeu].
8. Barato: 30 jogadores na tela sem pesar.

**Não-objetivos (agora)**
- Comprar/guardar skins (F4), tela de escolher skin (F5), loja.
- Skins de ferramenta/arma e armaduras (só deixar o gancho).
- Expressões de frio/calor/fome em si (só o espaço no sistema).
- Animações feitas no Animation Editor (só deixar o rig compatível).
- Lógica de combate/coleta (fases G); o golpe aqui é só visual.

**Anti-objetivos (fracasso mesmo funcionando)**
- Visual do boneco atrapalhando a simulação do Server Authority (correções, tremidas, rollback desfazendo animação).
- Precisar mexer em código para adicionar uma skin ou expressão nova.
- Boneco de um jogador aparecendo diferente para outro (skin ou animação só local).
- Animação com tranco/atraso visível ao andar ou girar para o mouse.

## 3. Restrições

- **Server Authority ligado** (`Workspace.AuthorityMode = Server`). Regra oficial: estado de jogo na simulação (`BindToSimulation`, atributos em instâncias previstas); **efeitos visuais renderizados só no cliente** em `RenderStepped`, lendo esse estado e sabendo desfazer previsões erradas ([docs](https://create.roblox.com/docs/projects/server-authority), [techniques](https://create.roblox.com/docs/projects/server-authority/techniques)).
- **PlayerModule próprio** em `vendor/PlayerModule.rbxmx` (não religa `AutoRotate`); `FacingSim` gira o `HumanoidRootPart`. Não mexer nisso.
- Rojo sincroniza disco → Studio; código em `src/`, `--!strict`, comentários em pt-BR, identificadores em inglês, módulos com `Init/Start` carregados pelos bootstraps.
- Conteúdo = dados em `Defs` (frozen, IDs string, validados no boot e testados no Lune).
- Câmera fixa a 65°, distância 28–40 studs.
- Testes de lógica pura rodam no Lune (`tests/*.spec.luau`); nada que crie Instances é testável no Lune.

## 4. O boneco (visual aprovado no spike) [Elizeu]

Medidas em studs (valores do spike, aprovados — ficam num arquivo de configuração para ajuste):

| Peça | Forma | Medida | Cor |
|---|---|---|---|
| Corpo | caixa de cantos arredondados (vista de cima) | 3,6 × 2 (altura) × 3,6, raio do canto 0,9 | skin: `#DDF3F8` |
| Contorno do corpo | mesma forma, 0,2 maior em X/Z, topo 0,1 mais baixo | — | skin: `#1F6F7A` |
| Olhos (2) | disco preto no topo, puxados para a frente (x = ±0,8; z = −0,55) | diâmetro 0,95 | `#111111` + brilho branco (32% do olho) |
| Mãos (2) | bola solta nos cantos da frente (x = ±(1,8 + 0,15); z = −1,45), 0,2 acima do centro do corpo | diâmetro 1,3 | cor do corpo, contorno: bola 0,2 maior e 0,4 mais baixa na cor do contorno |

- Frente do boneco = −Z do `HumanoidRootPart` (`LookVector`).
- Caixa arredondada = 2 blocos em cruz + 4 cilindros verticais nos cantos (técnica do spike, sem MeshParts).
- O spike está no place do Studio: `ServerScriptService.SpikeBoneco` (código de referência) e `Workspace.SpikeReferencia`. **Será apagado** na validação final (não é do repositório).
- Ferramenta na mão: segurada pela bolinha da mão direita; o modelo da ferramenta é redimensionado para a escala do boneco (hoje está na escala do avatar e fica minúscula).

## 5. Animações e expressões [Elizeu]

**Movimento**
- Parado: mãos "respiram" devagar (pequeno sobe/desce).
- Andar: corpo dá um leve "quique" no ritmo dos passos; mãos balançam alternadas para frente/trás.

**Golpe** (enquanto o atributo `Using` do personagem for `true`)
- Com ferramenta: a mão que segura faz um arco de ~90° para a frente (ida rápida, volta mais lenta); a outra mão recua um pouco; repete no ritmo.
- Mão vazia: soquinho reto para a frente, alternando esquerda/direita.

**Expressões**
- Dano: olhos "> <" por ~0,5 s; o corpo pisca em vermelho rapidamente [Claude, aprovado como palpite].
- Piscar: a cada 3–6 s (sorteado por boneco), olhos fechados por ~0,12 s; não pisca durante dano.
- Futuro: frio, calor, fome etc. entram como **dados** (seção 6.4).

## 6. Como funciona por dentro [Claude, com base na pesquisa aprovada pelo Elizeu]

### 6.1 Dois corpos: o simulado e o visual

- **Corpo simulado (servidor, previsto pelo Server Authority):** o personagem do Roblox passa a ser um `StarterCharacter` mínimo: `Humanoid` + `HumanoidRootPart` (invisível, é o colisor/hitbox, igual para todos) e mais nada visível. É ele que anda (PlayerModule), gira (`FacingSim`) e carrega os atributos de estado.
- **Corpo visual (cada cliente, só local):** para **cada** personagem que o cliente enxerga (o seu e os dos outros), o cliente monta um boneco visual ancorado e o faz seguir o `HumanoidRootPart` a cada quadro. Animações e expressões só existem aqui.
- Por quê: é o padrão oficial do Server Authority para visual ("objeto simulado invisível + clone visual ancorado que o segue no RenderStepped"). O visual nunca entra na simulação: não sofre rollback, não gera correção, não replica nada. Skin e animação de todos chegam a todos porque cada cliente desenha a partir do **mesmo estado replicado** (atributos).

### 6.2 Estado replicado (quem escreve → quem lê)

| Estado | Onde | Quem escreve | Já existe? |
|---|---|---|---|
| Posição/rotação | `HumanoidRootPart` | física + `FacingSim` | sim |
| Está batendo | atributo `Using` no personagem | `UseSim` (simulação) | sim |
| Item na mão | atributo `Equipped` no personagem (id do item ou nil) | `EquipService` | sim |
| Levou dano | atributo `HurtAt` no personagem (`workspace:GetServerTimeNow()` do último dano) | uma função única do servidor, ex. `CharacterService.hurt(character, amount)` — hoje chamada por um comando de dev; nas fases G, pelo combate/fome/frio | **novo** |
| Skin do corpo | atributo `Cosmetic_body` no personagem (id em `Defs.Cosmetics`) | serviço de cosméticos no servidor, ao nascer | **novo** |

- O estado visual fica **no personagem**, não no Player: assim o sistema visual trata igual o boneco de um jogador e um boneco de teste sem Player (seção 6.8). [Claude]
- Dano = o cliente vê `HurtAt` mudar → toca a expressão de dano naquele boneco (só se o valor for recente, < 1 s, para não tocar ao entrar no alcance de streaming).
- Quais personagens desenhar: o servidor marca todo personagem com a tag `Boneco` (CollectionService) — jogadores e bonecos de teste. O cliente acompanha a tag (`GetInstanceAddedSignal`/`Removed`), o que também cobre o streaming (personagem saindo e voltando do alcance). [Claude]
- Movimento = velocidade horizontal do `HumanoidRootPart` calculada no cliente pela diferença de posição entre quadros (funciona igual para o seu boneco e para os outros).
- `EquipService` deixa de montar o modelo da ferramenta no servidor: passa só a gravar `Equipped`. O cliente monta a ferramenta no boneco visual. (A regra "sem Tools do Roblox" continua.)

### 6.3 Rig visual e animação por código

- Boneco visual = `Model` com uma peça raiz **ancorada e invisível** (`Root`), movida a cada quadro com `workspace:BulkMoveTo` (uma chamada para todos os bonecos). As demais peças são **não ancoradas, sem colisão, `Massless`, `CanQuery/CanTouch = false`, sem sombra**, presas por **`Motor6D`**: `Root → Body` (e as peças do corpo/contorno soldadas no `Body`), `Root → LeftHand`, `Root → RightHand`, `Body → olhos`.
- Animação = código escreve `Motor6D.Transform` de cada articulação a cada quadro, a partir de funções matemáticas puras (testáveis no Lune). Verificado no Studio (29/10): com raiz ancorada movida por `BulkMoveTo`, a mão acompanha no mesmo quadro e o `Transform` é aplicado (1 quadro de atraso se escrito no `RenderStepped`; escrever antes do render, ex. `RunService.PreRender`/`PreAnimation`, elimina) [builder escolhe o evento, critério: sem atraso visível].
- Rig compatível com o Animator do Roblox: se um dia quisermos animações feitas no editor (emotes), basta adicionar `AnimationController` + `Animator` ao boneco visual — o Animator escreve o mesmo `Transform`.
- **Um único loop** no cliente anima todos os bonecos. Bonecos longe da câmera (> ~120 studs [builder]) só seguem a posição, sem animar.
- Os números das animações (amplitude do quique, ângulo do arco, período do golpe, intervalo do piscar…) ficam num **módulo de configuração** em `src/shared` para ajuste fácil. O período do golpe é um valor padrão agora; quando as fases G definirem a velocidade de uso por item, a animação passa a ler de `Defs`.

### 6.4 Expressões como dados

- `Defs/Expressions.luau` (ou equivalente [builder]): cada expressão tem `id`, `priority`, `eyes` (estilo de olho: `"open"`, `"closed"`, `"squeeze"` = "> <"…), `duration` (para as de evento) e um efeito opcional no corpo (ex.: `flash = "#E5484D"`). Gatilhos:
  - **evento** (`damage`): disparada pelo código ao detectar dano;
  - **periódica** (`blink`): intervalo sorteado entre min/max;
  - **condição** (futuro, ex. frio): atributo do Player abaixo/acima de um limiar — o formato do dado já existe agora, mesmo sem expressão usando.
- A expressão ativa = a de **maior prioridade** entre as ativas (dano > piscar).
- Estilos de olho são construídos **uma vez** por boneco como variações (peças) e trocados por visibilidade — sem criar/destruir peças a cada piscada, sem trocar textura (trocar decal de rosto pisca/borra; EditableImage não renderiza em peças de Humanoid).
- Validação no boot: prioridade numérica, estilo de olho existente, duração > 0 para eventos, min ≤ max no periódico.

### 6.5 Skins como dados (cosméticos por slot)

Segue o que o spec do MVP já previa (§7: cosméticos genéricos com `slot`; o perfil da F4 guarda `Owned` e `Equipped` = slot → id). [Claude]
- `Defs/CosmeticSlots` (lista de slots; agora só `"body"`; depois `"tool"`, `"armor"`…) e `Defs/Cosmetics.luau`: cada cosmético tem `id`, `nameKey` (Strings), `slot` e os dados do slot. Para `slot = "body"`: `bodyColor`, `outlineColor`, `handColor` (opcional; padrão = corpo), `eyeColor` (opcional).
- Cosmético `"body_default"` = cores do spike; é o padrão de quem não tem nenhum. Validação no boot: id = chave, `slot` existe, cores `#RRGGBB`, `nameKey` existe em Strings, existe exatamente um padrão por slot [builder decide como marcar o padrão].
- O servidor grava `Cosmetic_<slot>` no **personagem** ao nascer (por enquanto sempre o padrão; comando de dev no Studio para trocar, como o `DevGive`). Na F4 o valor virá de `Equipped` do perfil.
- O cliente aplica a skin ao montar o boneco e quando o atributo muda.
- **Peças extras modeladas** (skin com chapéu, orelhas etc. vindas de `ReplicatedStorage.Assets`): **fora desta fase**. A regra de encaixe (em qual peça, pivô, se pisca vermelho no dano) será decidida quando a primeira skin modelada existir. [Claude]
- Skins de ferramenta (futuro, slot `"tool"`): a montagem da ferramenta recebe o id do item e aceita um id de cosmético opcional — deixar a assinatura preparada [builder].

### 6.6 O que muda no código existente

- `CharacterService`: some o travamento de proporções do avatar (não há mais avatar); continua `AutoRotate = false` e sem pulo.
- `StarterCharacter`: montado pelo servidor no boot e colocado em `StarterPlayer` antes do primeiro spawn [builder: por código ou modelo; critério: o personagem nasce com `Humanoid` + `HumanoidRootPart`, encosta no chão (sem afundar/flutuar > 0,1 stud), anda e gira como hoje]. Evitar os scripts padrão de personagem (`Animate`, `Health`) que o Roblox injeta — não servem para esse rig.
- `EquipService`: só grava `Equipped`; o modelo da ferramenta sai do servidor.
- `Models/ToolModel.luau`: escala nova para a mão do boneco; continua montando por código.
- HUD, inventário, câmera, mira: sem mudanças.

### 6.7 Nome e balões de chat [Elizeu: sim; como, Claude]

- **Nome:** etiqueta própria (`BillboardGui`) no boneco visual, acima do corpo, com a fonte e as cores do `Theme` (texto claro com contorno escuro, legível no chão verde). Mostra o `DisplayName`. O nome padrão do Roblox fica desligado (`Humanoid.DisplayDistanceType = None`). Aparece em todos os bonecos, inclusive o seu (como no Starve). Bonecos de teste mostram um nome fixo.
- **Balões de chat:** o chat padrão (TextChatService) continua. O balão procura a `Head` do personagem; por isso o corpo simulado ganha uma peça `Head` **invisível, sem colisão, `Massless`, `CanQuery/CanTouch = false`**, soldada ao `HumanoidRootPart` acima do boneco. Critério: o balão aparece em cima do boneco sem cobrir o nome [builder ajusta altura/offset, ex. via `BubbleChatConfiguration`].

### 6.8 Ferramenta de teste

- Comando de dev (Studio) **no servidor** que cria N bonecos de teste (personagens com `Humanoid` + `HumanoidRootPart` + tag `Boneco`, sem Player) andando em círculo, alternando `Using`, trocando `Equipped` e chamando a função de dano de vez em quando. Por serem criados no servidor, testam o caminho real de replicação. Medido no MicroProfiler com 30 bonecos [Claude].
- Comando de dev para causar dano no próprio jogador (a função única de dano), já que hoje nada reduz a vida.

## 7. Critérios de pronto

1. Play no Studio: o jogador é o boneco (sem avatar), encosta no chão, anda e encara o mouse como hoje (inclusive andando de costas).
2. Parado respira; andando quica e balança as mãos; segurando o clique, golpe com ferramenta ou soco de mão vazia no ritmo.
3. Dano (via comando de dev) mostra "> <" + flash; pisca sozinho de tempos em tempos.
4. Com 2 jogadores (Studio: Test → 2 players), cada um vê o boneco, a skin, a ferramenta, o golpe, as expressões, o nome e os balões de chat do outro.
5. Trocar a skin pelo comando de dev muda as cores para todos.
6. Adicionar uma skin nova = 1 entrada em `Defs/Cosmetics.luau` + 1 texto em Strings; nova expressão = 1 entrada em `Defs/Expressions.luau`.
7. 30 bonecos de teste na tela sem queda perceptível de FPS (MicroProfiler).
8. `bash scripts/check.sh` limpo; testes Lune novos para as funções puras (curvas de animação, escolha de expressão, agendador do piscar, validação de Skins/Expressions).
9. Docs: `docs/guia/boneco.md` (como ajustar animações, adicionar skin e expressão) e `docs/guia/arquitetura.md` atualizado; spike apagado do place.

## 8. Deixado para o builder

- Nomes exatos de módulos/arquivos (seguindo a estrutura `Defs / Services / Controllers / UI / shared puros`).
- Evento exato do loop visual (sem atraso visível) e a distância de corte da animação.
- Curvas exatas (seno, easing) desde que respeitem a seção 5.
- Como o `StarterCharacter` é montado e qual `HipHeight`/tamanho de `HumanoidRootPart` (critério na seção 6.6).
