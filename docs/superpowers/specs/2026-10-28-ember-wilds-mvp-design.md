# Ember Wilds — Design do MVP (N0)

Data: 28/10/2026 · Autor do jogo: Elizeu W Ruthes · Documento escrito com Claude Code

Fontes de conteúdo (ler junto):
- `docs/game-design/catalogo-e-roadmap.md` — catálogo do Starve.io e o nível (N0–N5) de cada item. **É a fonte da verdade para receitas, números e o que entra no N0.**
- `docs/game-design/identidade-visual.md` + `docs/game-design/img/` — direção de arte, paleta, tipografia, HUD, animações, iluminação, som.
- `docs/research/01..05` — pesquisa técnica (out/2026) que embasa as escolhas abaixo.

Marcações: **[decidido]** = escolha do Elizeu; **[escolha do Claude]** = decisão técnica tomada por mim, que o Elizeu pode vetar; **[builder]** = deixado para quem implementa.

---

## 1. Intenção

Um survival multiplayer top-down para Roblox, inspirado no Starve.io (coletar, craftar, construir, sobreviver à fome/frio/sede e à noite, PvP livre), com identidade própria: low-poly "de brinquedo" visto de cima, contraste frio-azul da noite contra o laranja do fogo, mobile-first. Nome provisório: **Ember Wilds**.

O jogo vai crescer por updates que abrem biomas (N1 floresta completa → N2 inverno → N3 oceano → N4 deserto/lava → N5 extras). Por isso **a qualidade mais importante do código é facilitar updates** [decidido]: conteúdo novo deve ser dado (entradas em tabelas), não código novo.

Modo de trabalho [decidido]: o Claude escreve o código e os modelos; o Elizeu (experiência média em Studio/Luau) estuda, testa no Studio e faz ajustes nos sistemas. Logo, o código precisa ser legível para ele.

## 2. Objetivos, não-objetivos e anti-objetivos

### Objetivos do MVP (N0)
O checklist N0 do catálogo: floresta com lago, árvores, rochas, ouro e frutinhas; dia/noite de 8 min; barras vida/fome/frio/sede no servidor; inventário 10 + mochila 6; crafting com tempo; bancada e fogueiras; picaretas/espadas/lanças até ouro; capacetes madeira/pedra; protetor de orelha, garrafa d'água (receita sem areia), carne assada; paredes/portas/espinhos/portas-espinho de madeira e pedra com limite por jogador; coelho, lobo, aranha; PvP com drop, pontos, ranking, chat filtrado; moeda soft ao morrer, loja com 10–15 cosméticos e pacotes de moeda; controles de toque e câmera top-down travada; arte, nome, ícones e sons próprios.

### Ordem de construção [decidido]
Primeiro a parte gráfica e a base (câmera, HUD, inventário, telas iniciais, sistema de dados), depois a gameplay. Ver seção 10.

### Não-objetivos (agora)
- Conteúdo de N1+ (fazenda, times, baús, inverno etc.). A arquitetura deve **suportar** sem refatorar, mas nada disso é implementado.
- Modelos em Blender, rigs e animações de mobs — só quando chegar a fase de mobs.
- Tradução para outros idiomas (só a estrutura de strings fica pronta).
- Modos alternativos (zumbi, vampiro), domar/montar.

### Anti-objetivos (seria fracasso mesmo funcionando)
- **Pay-to-win**: nada vendido com Robux dá dano, defesa ou recursos. Só visual ou conveniência leve.
- **Copiar o Starve.io**: nomes de itens do catálogo são referência interna; nome, arte, ícones e sons do jogo são próprios. Os IDs internos podem ser em inglês genérico (`wood_pickaxe`), mas os textos exibidos são nossos.
- **Código que só o Claude entende**: arquivos gigantes, mágica, frameworks obscuros.
- **Sistemas que conhecem itens pelo nome** (ex.: `if itemId == "stone_sword"` dentro do combate). Tudo vem das definições.
- **Cliente confiável**: qualquer coisa que muda estado de jogo é decidida e validada no servidor.
- HUD ilegível no celular pequeno.

## 3. Restrições

- **Plataforma**: Roblox, Luau, projeto Rojo em `C:\Users\Elize\Desktop\Roblox\starve` (hoje só scaffold). Windows. Rokit já instalado (1.2.0) com `rokit.toml` do projeto.
- **Mobile-first**, celular em paisagem; PC e gamepad também.
- **Server Authority ligado desde o início** [decidido] (`Workspace.AuthorityMode = Server`), para não ter de refatorar quando o jogo crescer. Consequências na seção 5.
- Desenvolvedor solo + IA; prazo do N0 não fixado.
- Avatar R15 do próprio jogador com proporções travadas (hitbox justa).
- **Place de desenvolvimento** [decidido]: o Elizeu criou um place, já conectado ao Rojo (`rojo serve` sincroniza ao vivo). Para testar persistência real no Studio, ele precisa estar publicado com "Enable Studio Access to API Services" ligado; os dados de desenvolvimento usam um nome/escopo de DataStore separado do que será o jogo real (ex.: prefixo `Dev_`), trocado por configuração. Developer Products, Game Pass e Avatar Settings são configurados nesse place pelo Elizeu quando a fase pedir — o plano lista esses passos manuais.
- **Git** [decidido]: commit ao fim de cada fase (ou parte dela), mensagens em português, sem push.
- O grafo do graphify (`graphify-out/`) deve ser atualizado após mudanças de código (`python -m graphify update .`; o comando `graphify` não está no PATH desta máquina). Docs ficam em `docs/` para entrarem no grafo.

## 4. Stack e ferramentas [escolha do Claude, aprovada pelo Elizeu em conversa]

| Área | Escolha | Por quê |
|---|---|---|
| Gerenciador de ferramentas | Rokit (`rokit.toml`) | Já instalado; fixa versões |
| Sync | Rojo **7.7.1** (atualizar de 7.7.0) | Versão atual |
| Pacotes | Wally (+ `wally-package-types`) | Padrão de fato |
| Qualidade | `--!strict` em todo arquivo, luau-lsp + `rojo sourcemap`, selene, StyLua | Erros de tipo são a rede de segurança para código escrito por IA |
| Arquitetura | Própria, sem framework: módulos com `Init()`/`Start()` + bootstrap por lado | Knit arquivado; simples de estudar |
| Rede (eventos discretos) | **Blink** (IDL → Luau tipado, buffer) | Ativo (v0.18.9, set/2026); contrato legível |
| UI | **Vide** (reativo, tipado, leve) | Ativo; HUD que muda a cada tick sem re-render |
| Persistência | **ProfileStore** | Session lock, Reconcile, padrão de compras idempotente |
| Testes | Só lógica pura (inventário, crafting, fórmulas), com Lune ou Jest-Lua, quando esses sistemas existirem | Não vale montar testes no Studio agora |

Se uma dessas bibliotecas não funcionar com Server Authority (ex.: Vide/Blink e SignalBehavior Deferred), o builder troca pela alternativa da pesquisa (Zap; UI imperativa organizada; Lyra) e registra no documento de decisões.

## 5. Server Authority — como o jogo usa

Base: `docs/research/05-server-authority.md`.

- **Movimento do personagem**: fica com o sistema nativo (PlayerScripts com Input Action System e predição). A velocidade do jogador é controlada por **atributos** escritos na simulação (ex.: multiplicador por arma segurada, por bioma), aplicados ao `Humanoid.WalkSpeed` dentro de `BindToSimulation`. Pulo desligado.
- **Orientação e mira** [decidido; celular revisto em 29/10/2026]:
  - **PC**: o personagem sempre vira para o cursor do mouse, mesmo andando para outro lado (como no Starve.io). Segurar o botão esquerdo bate repetidamente na direção do cursor, no ritmo da arma/ferramenta [escolha do Claude].
  - **Celular — dois joysticks**: o **esquerdo** (thumbstick nativo) anda; o **direito** (joystick próprio) mira. **Sem usar o direito**, o personagem vira para onde anda e a câmera continua fixa. **Segurando o direito**, ele vira para a direção do joystick e **bate sozinho**, repetindo no ritmo da arma/ferramenta. Atacar e coletar são a mesma ação ("bater"), como no Starve.io. Isto substitui o botão de ação com auto-alvo em cone.
  - **Construção (PC e celular)**: com uma estrutura na mão, a peça fantasma aparece a uma **distância fixa** (uma célula da grade à frente) na direção da mira — mouse no PC, joystick direito no celular —, presa na grade, verde se pode e vermelha se não pode. No celular, **soltar o joystick direito sempre constrói** (se a posição for inválida, nada é gasto). No PC, o clique constrói [escolha do Claude]. Para parar de construir, o jogador tira a peça da mão (troca de slot na hotbar).
  - **Gamepad** segue o celular, com o analógico direito no papel do joystick direito [escolha do Claude].
  - **Implementação**: `AutoRotate` desligado e rotação escrita **dentro da simulação** a partir da InputAction `Aim` (comprovado na F1 sob Server Authority, inclusive com 150 ms de latência). O joystick direito alimenta a mesma `AimBinding` que o mouse; "segurar para bater" e "soltar para construir" vêm de uma InputAction de botão (Bool) ligada ao joystick/clique. O servidor revalida cada golpe e cada construção.
- **Joysticks no celular** [escolha do Claude, ajustada à decisão acima]: o de movimento é o thumbstick nativo (funciona com IAS e predição — confirmado no emulador). O joystick direito de mira/ação é próprio (UI) e só alimenta InputActions (`AimBinding` scriptable + a ação de bater/construir), sem mexer no movimento. Construir e mochila são botões próprios. Ações que mexem na simulação usam **InputActions** (bindings separados para teclado, gamepad e toque); ações só de interface, como abrir a mochila, chamam a UI direto no toque [decidido na F2]. No PC a mochila abre com **B** — o Tab é da lista de jogadores do Roblox e nunca chega ao jogo [decidido na F2].
- **Ações discretas** (coletar/atacar, craftar, colocar construção, mover item no inventário, comprar, "Jogar" no menu) [escolha do Claude]: vão por **Blink (RemoteEvents)** e o servidor valida tudo (distância, cooldown, posse, limites). Esse é o mesmo padrão do template oficial Laser Tag. Feedback visual é imediato no cliente (juice) e o resultado real vem do servidor. A predição de combate dentro da simulação fica como evolução futura, não MVP.
- **Regras para todo código de simulação**: usar `time()`; não usar `Destroy()`/trocar `Parent` dentro de `BindToSimulation` (marcar em atributo e destruir em `PostSimulation` no servidor); efeitos e sons em `RenderStepped`, lendo estado.
- **Atributos replicados**: no máximo 64 por instância, strings ≤ 50 caracteres. Barras de status como atributos numéricos no `Player`.
- **Configuração do Workspace**: setar `AuthorityMode = Server` pelo `default.project.json` se o Rojo suportar a propriedade; se não suportar, setar no Studio e documentar no README como passo manual. Isso força StreamingEnabled, SignalBehavior Deferred, NextGen Replication, IAS e simulação fixa.
- **Risco conhecido**: clientes mobile atualizam a engine alguns dias depois do desktop. Testar sempre no emulador de celular do Studio.
- **Validação cedo**: a Fase 1 (câmera + movimento) é também o spike que confirma que Server Authority + câmera própria + thumbstick funcionam bem. Se algo bloquear, parar e trazer para o Elizeu antes de seguir.

## 6. Arquitetura do código

### 6.1 Estrutura de pastas (alvo)
```
src/
  shared/            -> ReplicatedStorage.Shared
    Defs/            definições de conteúdo (dados puros, tipados, congelados)
      Tiers.luau     madeira..reidite: cor (paleta), raridade, ordem
      Items.luau     (ou Items/ por categoria quando crescer)
      Recipes.luau
      Structures.luau
      Mobs.luau
      Biomes.luau
      Cosmetics.luau
      init.luau      agrega e VALIDA referências no boot (receita → item inexistente = erro)
    Theme.luau       cores, fontes, tamanhos (fonte única de estilo)
    Strings/         textos exibidos (pt-BR agora; estrutura para en depois)
    Net/             código gerado pelo Blink
    Util/            funções puras (inventário, fórmulas) — testáveis
  server/            -> ServerScriptService.Server
    init.server.luau bootstrap: require de todos os serviços, Init() de todos, Start() de todos
    Services/        um módulo por sistema (DataService, InventoryService, SurvivalService...)
  client/            -> StarterPlayer.StarterPlayerScripts.Client
    init.client.luau bootstrap dos controladores
    Controllers/     CameraController, InputController, UIController...
    UI/              componentes Vide (HUD, Inventory, Menus...)
    Juice.luau       feedback padronizado (tweens, partículas, sons)
  first/             -> ReplicatedFirst (tela de carregamento)
Packages/, ServerPackages/  (Wally, no .gitignore)
net/*.blink          contratos de rede
```
Os nomes exatos dos módulos são [builder], mas a divisão (Defs / Services / Controllers / UI / Util) é o contrato.

### 6.2 Princípios
- **Conteúdo = dados.** Itens, receitas, estruturas, mobs, biomas e cosméticos vivem em `Defs`. Cada def tem `export type`, é congelada (`table.freeze`) e usa **ID string estável** (`"wood_pickaxe"`), nunca índice numérico — esses IDs vão para o DataStore. Sistemas só leem defs por campos (`def.harvestPower`, `def.damage`, `def.station`).
- **Servidor decide; cliente pede e desenha.** O HUD nunca depende do Workspace; dados vêm de atributos e eventos.
- **Um serviço = uma responsabilidade.** Serviços conversam por funções públicas e sinais simples, não por globais.
- **Um loop central no servidor** com frequências por sistema (status 2 Hz, calor/espinhos 5 Hz, IA 10 Hz, plantas/respawn 1 Hz), em vez de `while task.wait()` espalhados. Respeitando as regras de Server Authority da seção 5.
- **Legível**: identificadores em inglês, comentários em português explicando o *porquê*; arquivos pequenos; nada de "mágica".
- **Textos exibidos** saem de `Strings` (pt-BR), nunca hardcoded na UI [escolha do Claude].

### 6.3 Guia para o Elizeu
Criar `docs/guia/` com passo a passo de: adicionar um item, uma receita, uma estrutura, um mob, um cosmético e um bioma, e como rodar o projeto (Rokit, Wally, Blink, Rojo, Studio). Atualizado a cada fase.

## 7. Dados persistentes

Base: `docs/research/02-dados-monetizacao.md`.

- **ProfileStore**, um perfil por jogador, chave `Player_{UserId}`, sessão aberta só no `PlayerAdded`; se falhar, kick com mensagem. Mock no Studio.
- **Só persiste o que sobrevive à morte**: moeda soft, cosméticos (possuídos e equipados), estatísticas (melhor pontuação, mortes, mais dias sobrevividos, tempo de jogo), configurações (volume por grupo, qualidade, tamanho da UI, canhoto), e espaço para quests/níveis futuros. Inventário, base e pontos da partida **não** são salvos.
- **Versionamento**: campo `SchemaVersion`; migrações sequenciais rodam antes do `Reconcile()`.
- **Toda mudança de moeda** passa por uma única função do servidor, com tetos anti-farm (no original: 1 moeda por 1.000 pontos, máx. 500 por partida e 60 por hora — números ajustáveis em Defs/config).
- **Saídas** [escolha do Claude, aprovada em conversa]: sair do jogo conta como morte (pontos viram moeda, resto se perde). Queda do servidor: converter pontos em moeda no `BindToClose`. Período de graça para reconexão fica para depois.
- **Compras**: `ProcessReceipt` idempotente com `PurchaseIdCache` no perfil (padrão oficial do ProfileStore). Game Pass checado no join, cacheado em atributo.
- **Ranking**: top 10 do servidor em memória; recordes globais em OrderedDataStore (gravar só ao bater recorde); leitura em cache a cada 2–5 min.
- **GDPR**: chaves com `{UserId}` estático para os templates de deleção automática; não salvar nomes nem chat.
- **Cosméticos no schema** [escolha do Claude]: o tipo de cosmético é genérico. Cada def de `Cosmetics` declara o `slot` que ocupa, e a lista de slots também vem de Defs. O perfil guarda `Owned` (conjunto de IDs) e `Equipped` (mapa slot → ID). Quais slots existem (acessório sobre o avatar, rastro, efeito de morte, visual da fogueira…) é decidido na fase da loja, sem mudar o schema.
- **Monetização e caixas aleatórias**: se a moeda soft for vendida por Robux, caixas pagas com ela entram nas regras de itens aleatórios pagos. No N0 a loja vende cosméticos **diretamente** (sem caixas); caixas ficam para N1 e exigem nova decisão. Premium Payouts agora é Creator Rewards (automático).

## 8. Parte visual (cliente)

Base: `docs/research/03-visual-cliente.md` + identidade visual.

- **Câmera**: `Scriptable`, `BindToRenderStep` em `Camera + 1`, pitch ~65°, yaw fixo, suavização exponencial, zoom curto limitado (valores iniciais [builder]). Fade de oclusão só em peças com tag `Occluder` (copas, telhados) — pode vir depois.
- **CoreGui**: desligar Backpack e Health; chat padrão (TextChatService) mantido.
- **Avatar**: Avatar Settings da experiência (Custom Scale/Build, colisor único, limite de acessórios) + reaplicação de escala no servidor ao carregar o personagem.
- **ScreenGuis** com `ScreenInsets = CoreUISafeInsets`; respeitar a TopBar (`GuiService.TopbarInset`, ~58 px, que chega zerado no 1º frame).
- **Layout**: o da imagem `docs/game-design/img/hud-mobile.png` — pontos/ranking (sup. esq.), relógio dia/noite (topo), minimapa (sup. dir.), receitas prontas (esq.), aviso (dir.), anéis de vida/fome/frio/sede acima da hotbar, hotbar de 10 slots, **joystick direito de mira/ação** no lugar do botão "Coletar" do mockup, e botões de construir e mochila (dir.). No PC/gamepad os botões de toque somem (`UserInputService.PreferredInput`), hotbar responde a 1–0.
- **Regras de UI** da identidade visual: tokens de cor do `Theme`, fontes `LuckiestGuy`, `FredokaOne`, `BuilderSans` via `FontFace`, `TextScaled` + `UITextSizeConstraint`, Scale + `UIAspectRatioConstraint`, botões ≥ 44 px, UICorner/UIStroke, notificações máx. 2 por 3 s.
- **Inventário**: tabela autoritativa no servidor (slots fixos `{id, count}`, operações sem yield); cliente recebe snapshot + deltas e redesenha. Sem Tools do Roblox; item equipado é um modelo visual soldado na mão. Capacidade = 10 (hotbar) + slots da mochila vestida (item `category = "bag"` com `bagSlots`; no N0 a Mochila de Couro, +6) + bônus do gamepass VIP (+3, desligado até o passe existir), até 40 [decidido em 29/10/2026, para updates com mochilas maiores]. A hotbar mostra os slots 1–10; o painel da mochila mostra os slots além dela e só existe quando eles existem. Mover itens é **arrastando** entre slots (hotbar ↔ mochila e dentro de cada uma); toque rápido num slot da hotbar seleciona [decidido em 29/10/2026, substitui o "toque na origem + toque no destino"].
- **Telas**: carregamento (ReplicatedFirst, preload mínimo), menu inicial (câmera cinematográfica sobre o mapa; Jogar, Loja, Configurações; `CharacterAutoLoads = false`, servidor spawna ao clicar Jogar), configurações (persistidas no perfil), morte (causa, dias, pontos → moeda, "Jogar de novo"), loja, ranking, livro de receitas.
- **Ícones**: no começo, desenhados com elementos de UI (forma simples + moldura e fundo na cor do tier a 15%), conforme `icones-picareta.png`. Depois, imagens renderizadas dos modelos num spritesheet (upload manual pelo Elizeu ou via Open Cloud).
- **Dia/noite**: servidor publica o início do ciclo em atributo; cliente e servidor calculam a hora pela mesma fórmula (`GetServerTimeNow`). Noite azul via ColorCorrection/Atmosphere/Ambient; aviso "A noite está chegando" 30 s antes; fogueira com PointLight `#FFA43A`, 18 studs, sem sombra.
- **Juice**: um módulo concentra os feedbacks da tabela "Animações e feedback" da identidade visual; todo item novo ganha o mesmo feedback.

## 9. Arte e mundo [decidido: o Claude modela]

- **MVP**: modelos low-poly montados com Parts/WedgeParts/cilindros **por código**, a partir de "receitas de modelo" em Luau, com cores da paleta via `Theme`/`Tiers`. Um modelo por tipo, a cor e um detalhe mudam por tier (tabela "Linguagem de forma por tier"). Sem uploads.
- **Escala**: avatar ~5 studs; grid de construção 4×4 studs; coletáveis ≥ 1,5× o avatar vistos de cima; câmera a 65° → o topo de cada modelo é o que importa.
- **Mapa da floresta (N0)** [escolha do Claude]: chão plano com Parts (sem Terrain no MVP), lago, e recursos posicionados por um gerador com semente fixa a partir de Defs (densidades por bioma). Assim o mapa é reproduzível e cada bioma novo é uma entrada em `Biomes`.
- **Layout do mundo** [escolha do Claude, seguindo o catálogo]: o mapa final é **um só**, com os biomas em coordenadas fixas do mundo, como no Starve.io (floresta na metade de baixo ao lado do oceano, inverno acima, caverna do dragão no canto sup. esq., deserto no canto sudeste, lava no canto sup. dir.). `Biomes` define cada bioma como **região em coordenadas do mundo**; o gerador trabalha por região. No N0 só a região da floresta (com o lago no lugar do rio) existe e o resto é borda intransponível; cada update "abre" uma região sem mover as existentes. Tamanho inicial do mundo, da floresta e densidades ficam em Defs e são ajustados em teste.
- **Jogadores por servidor** [escolha do Claude]: alvo inicial de **30**, configurável. Orçamentos de CPU, limite de peças por jogador e raios de streaming são calibrados para esse número e revistos com o profiler (Server Authority custa mais CPU).
- **Depois**: mobs, bosses e árvores orgânicas em Blender (via MCP oferecido pelo Elizeu), com rig e 5 animações por mob. Upload das malhas pelo Elizeu ou via chave Open Cloud — decidir na fase de mobs.
- **Som**: biblioteca licenciada do Creator Store; SoundGroups Música/Ambiente/Efeitos; variação de tom ±5–10%.

## 10. Fases e critérios de pronto

Cada fase termina testável no Studio (incluindo emulador de celular em paisagem) e com o grafo do graphify atualizado e o guia em `docs/guia/` atualizado.

| Fase | Entrega | Pronto quando |
|---|---|---|
| F0 Fundação | Rokit com rojo 7.7.1, wally, selene, stylua, luau-lsp, blink; estrutura de pastas; bootstraps Init/Start; `Theme`, `Tiers`, Defs iniciais com validação; Workspace com Server Authority; README de como rodar | `rojo build` gera o place, Play roda sem erros, lint e type-check limpos |
| F1 Câmera e movimento | Câmera top-down 65°, movimento nativo com predição, pulo desligado, avatar com proporção travada, personagem virando para o mouse no PC (na simulação) e para o movimento no celular, chão de teste | Andar no PC e no emulador de celular, câmera suave, rotação para o mouse sem tremer; **confirma o spike de Server Authority** |
| F2 HUD | Componentes Vide do HUD do layout, com dados falsos vindos de atributos; troca PC/celular; joystick direito de mira/ação no celular (mira + segurar para bater) e botões ligados a InputActions | HUD legível no celular pequeno, tablet e 1080p; joystick direito gira o personagem e dispara a ação de bater (verificado no servidor) |
| F3 Inventário | Inventário autoritativo + snapshot/delta via Blink; grade 4×4, hotbar, selecionar slot, item visual na mão; itens de teste por comando de debug | Mover, empilhar, selecionar e equipar funcionam e o servidor rejeita operações inválidas |
| F4 Dados | ProfileStore, schema v1, migrações, configurações e moeda persistidas, escopo de DataStore de desenvolvimento | No place publicado com API Services: sair e voltar mantém configurações e moeda; sem API Services, cai para mock com aviso no Output |
| F5 Telas | Carregamento, menu inicial com Jogar, configurações, morte (stub), loja (stub), ranking (stub) | Fluxo completo carregamento → menu → jogar → (morte simulada) → menu |
| F6 Mundo e dia/noite | Modelos de peças da floresta, gerador do mapa, lago, ciclo dia/noite com iluminação | Floresta navegável com ciclo de 8 min e noite azul |
| G1+ Gameplay | Sobrevivência → coleta → crafting → construção → mobs → combate/PvP/morte/loot → pontos/ranking → loja/monetização | Checklist N0 do catálogo |

As fases G serão detalhadas em um design/plano próprio quando F0–F6 estiverem prontas.

## 11. Deixado para o builder
- Nomes exatos de módulos e funções; valores iniciais de câmera, zoom e suavização; tamanhos finos de UI dentro das regras.
- Formato interno dos pacotes Blink.
- Como gerar a "receita de modelo" de cada peça.
- Comandos de debug (dar item, mudar hora) — desde que só funcionem no Studio.
- Ordem interna das tarefas dentro de cada fase.

## 12. Riscos e perguntas em aberto
- Rojo conseguir setar `AuthorityMode` (senão, passo manual documentado).
- Compatibilidade de Vide/Blink/ProfileStore com SignalBehavior Deferred e Server Authority (verificar na F0/F1).
- Joystick visual próprio sob Server Authority (adiado; nativo no MVP).
- Nome final do jogo (Ember Wilds é provisório; checar no Roblox e INPI antes de lançar).
- Upload de assets (malhas/ícones) — decidir na fase de mobs.
