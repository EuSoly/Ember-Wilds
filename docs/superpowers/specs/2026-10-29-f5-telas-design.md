# Ember Wilds — F5 Telas: fluxo do jogo com moldes de interface (design)

Data: 2026-10-29 · Status: revisado por um builder independente; aguardando aprovação do Elizeu
Base: spec do MVP §8 "Telas" e §10 (F5), identidade visual (`docs/game-design/identidade-visual.md`, "Telas fora do HUD").

Legenda: **[Elizeu]** decidido por ele · **[spec]** já decidido · **[Claude]** decisão técnica minha · **[builder]** quem implementa decide.

## 1. Intenção

Fechar o fluxo do jogo — **carregamento → menu → jogar → morte → menu/jogar de novo**, com **configurações** — usando telas **simples, só para testes** [Elizeu]. O visual de verdade vem depois: o Elizeu (ou um amigo designer) desenha as telas no **Studio** (à mão ou importando do Figma por plugin) e eu ligo o funcionamento [Elizeu]. Por isso as telas são **moldes**: o visual é um arquivo de instâncias que pode ser trocado sem mexer no código [Elizeu: "moldes"].

## 2. Objetivos, não-objetivos e anti-objetivos

**Objetivos**
1. Sistema de moldes: telas como instâncias em arquivo, ligadas ao código por **nomes combinados**; trocar o visual = substituir o arquivo.
2. Tela de carregamento (enquanto o jogo e o perfil carregam).
3. Menu: câmera passeando sobre o mapa, logo, saldo de Golden Ember, **Jogar** e **Configurações**; o boneco só nasce ao clicar Jogar [spec].
4. Morte: "Você morreu", dias vividos, pontos, Golden Ember ganha (contando para cima), **Jogar de novo** e **Menu** [spec, Elizeu].
5. Configurações (no menu e durante o jogo), salvando no perfil (F4).
6. HUD só aparece jogando.

**Não-objetivos (agora)**
- Visual final, ícones e artes (vêm dos designs do Elizeu).
- Loja, ranking e livro de receitas (quando houver conteúdo) [Elizeu].
- Morte de verdade (combate é fase G): a morte é simulada pelo comando de dev.
- Converter a HUD atual (código Vide) para moldes — só se o Elizeu quiser redesenhá-la.

**Anti-objetivos**
- Designer renomear/apagar um elemento e o jogo quebrar sem dizer o quê (tem que avisar qual elemento falta e seguir funcionando).
- Lógica de jogo dentro dos moldes (moldes são só visual; nenhum script dentro deles).
- Cliente conseguir nascer duas vezes, nascer sem perfil carregado ou fugir da morte (ex. desconectar não evita o fim de vida — a F4 já garante; não há tempo mínimo na tela de morte).

## 3. Restrições

- Server Authority; o servidor decide quando o personagem nasce.
- Rojo sincroniza disco → Studio. O designer edita o molde no Studio e salva o arquivo por cima (botão direito → *Save to File*); o Rojo então sincroniza o mesmo conteúdo de volta.
- Textos exibidos vêm de `Strings` [spec]; o Roblox não deixa o jogo mudar a qualidade gráfica do jogador.
- O Cline (implementador) não tem o Studio: os moldes iniciais precisam ser escritos como arquivo de texto.

## 4. Sistema de moldes [Claude]

- **Onde:** `assets/ui/` no repositório, mapeado pelo Rojo para `ReplicatedStorage.UITemplates`. Exceção: o molde de carregamento fica em `src/first/` (ReplicatedFirst), porque precisa existir antes de tudo.
- **Formato:** os moldes iniciais são `*.model.json` do Rojo (texto, fácil de escrever sem o Studio). Quando o designer salvar um molde pelo Studio, ele vira `Nome.rbxmx` e o `.model.json` antigo é apagado (o guia explica).
- **Cada molde** é um `ScreenGui` (ex. `MainMenu`, `Settings`, `Death`) ou, para linhas repetidas, um `Frame` (ex. `SettingRowNumber`).
- **Contrato por nomes:** o código acha os elementos por nome (ex. `PlayButton`) em qualquer profundidade dentro do molde. A lista de nomes de cada tela fica no guia (`docs/guia/telas.md`) e no topo do código da tela. Elemento faltando → `warn` uma vez dizendo molde e nome, e aquela parte não funciona (o resto sim).
- **Textos:** qualquer `TextLabel`/`TextButton` com o atributo `TextKey` (ex. `menu.play`) recebe `Strings.get(TextKey)` automaticamente; textos com dados (saldo, pontos) são escritos pelo código.
- **Animações e feedback** ficam no código [Elizeu: "o dev faz as animações"]: abrir/fechar tela com fade e leve escala; todo botão do molde ganha feedback de toque (encolhe um pouco ao apertar).
- **Escala da interface:** o código aplica um `UIScale` em cada tela conforme a configuração `ui_scale`. Moldes devem usar Scale (não pixels) para funcionar do celular ao PC.

## 5. Fluxo e estados (cliente) [Claude]

Um único estado de tela no cliente: `loading` → `menu` → `playing` → `dead` → (`playing` ou `menu`). Configurações é uma janela por cima (abre no `menu` e no `playing`).

- **loading:** tira o carregamento padrão do Roblox, mostra o molde `Loading` (texto + barra). Termina quando o jogo carregou **e** o servidor marcou o perfil como pronto (atributo `DataReady` no Player, gravado quando o perfil da F4 carrega). Então vai para `menu`.
- **menu:** sem personagem. Câmera do menu: gira devagar em volta do centro do mapa, do alto. Mostra o saldo (`Currency`). **Jogar** → pede ao servidor para nascer.
- **playing:** HUD visível, câmera do jogo (a atual). Botão de engrenagem na HUD abre Configurações.
- **dead:** HUD escondida, o mundo perde a cor (saturação até −1 em ~1 s, como na identidade visual), molde `Death` com causa, dias, pontos e Golden Ember contando de 0 até o ganho. **Jogar de novo** → pede para nascer; **Menu** → volta ao `menu`. Ao nascer, a cor volta.

## 6. Servidor [Claude]

- `Players.CharacterAutoLoads = false` (no `default.project.json`; em place existente, marcar à mão como o `AuthorityMode`).
- **Pedido para nascer** (evento Blink do cliente): só atende se o perfil está pronto e o jogador **não** tem personagem vivo; senão ignora. Nasce com `LoadCharacter()`.
- **Morte:** uma função única de morte (as fases G chamam ao matar o jogador): faz o fim de vida da F4 (moeda, estatísticas), **zera o inventário e tira a mochila** (no Starve a morte perde tudo — catálogo, "Morte"), remove o personagem e manda ao jogador um evento Blink com o resumo `{ causa, dias, pontos, moedaGanha }` (dias = os da vida, `LifeRules.daysSurvived`; moeda = a concedida de fato, depois do teto). O comando de dev `DevEndLife` passa a usar essa morte. Sair do jogo continua sendo só fim de vida (sem tela).
- **Mortes "do Roblox"** [Claude]: o botão "Reset Character" do menu do Roblox fica **desligado** (não é um jogo de se matar); e qualquer morte do `Humanoid` que não passou pela função (ex. cair fora do mapa) é levada para ela com a causa `death.cause.unknown` — nunca fica um corpo parado sem tela de morte.
- **"Vivo"** para o pedido de nascer = tem personagem com `Humanoid` de vida > 0. Uma marca "nascendo" no servidor impede dois pedidos rápidos de passarem juntos.
- **Status ao nascer:** quem dá os valores iniciais de vida/fome/frio/sede ao nascer é o `DevStatsService` (Studio) até o sistema de sobrevivência das fases G existir. No Studio, o `DevItemsService` dá o kit de teste **a cada nascimento** (senão o inventário fica vazio depois da primeira morte).
- **Mapa no menu:** sem personagem, o servidor aponta o foco de streaming (`ReplicationFocus`) do jogador para o centro do mapa, para a câmera do menu ter o que mostrar.
- `DataReady` no Player quando o perfil carrega (F4 `DataService.onLoaded`).
- Causa da morte = chave de `Strings` (ex. `death.cause.dev` = "Teste"); as fases G adicionam as suas.

## 7. Configurações [Claude]

- Molde `Settings` com uma lista; o código cria **uma linha por configuração de `Defs.Settings`** clonando o molde de linha do tipo certo (`SettingRowNumber`, `SettingRowBoolean`, `SettingRowChoice`). Configuração nova num update aparece sozinha.
- Número: botões − e + (passo 0,1) e o valor em %; booleano: botão liga/desliga; escolha: setas ‹ › entre as opções (texto da opção vem de `Strings`, chave `setting.<id>.<opção>`).
- Cada mudança chama o evento `SetSetting` da F4 (o servidor valida); a tela mostra o valor dos atributos `Setting_<id>` (fonte da verdade).
- **O que já é aplicado:** `ui_scale` (UIScale em todas as telas e na HUD); volumes nos três `SoundGroup` do jogo (Música, Ambiente, Efeitos), criados agora para os sons futuros. **Só salvos por enquanto:** `quality` (vai controlar os nossos efeitos quando existirem) e `left_handed` (trocar os controles de toque de lado exige mexer no joystick do PlayerModule; fica para quando testarmos o celular a fundo).

## 8. Moldes iniciais (provisórios) [Claude]

Visual mínimo com as cores do `Theme`/`Palette` (painel `#1E2230` a 85%, borda `#3A4258`, botão principal `#FF8A1F`, texto `#F4F1EA`; fontes Luckiest Guy no título, Fredoka One nos números/botões, Builder Sans no resto), tudo em Scale, centralizado:
- `Loading` (ReplicatedFirst): fundo escuro, "Ember Wilds", texto de status e barra.
- `MainMenu`: logo em texto, saldo, botões Jogar e Configurações.
- `Death`: título, linhas de causa/dias/pontos/moeda, dois botões.
- `Settings` + 3 moldes de linha + botão Fechar.

## 9. Critérios de pronto

1. Play no Studio: aparece o carregamento, depois o menu com o saldo correto; sem personagem no mapa até clicar Jogar.
2. Jogar → nasce e a HUD aparece; engrenagem abre Configurações; mudar o tamanho da interface muda na hora e continua depois de sair e voltar.
3. `DevEndLife` → personagem some, mundo cinza, tela de morte com os números certos (moeda contando); Jogar de novo → nasce de novo; Menu → volta ao menu.
4. Cliente pedindo para nascer duas vezes, ou já vivo → servidor ignora.
5. Apagar/renomear um elemento num molde → `warn` claro no Output e o resto funciona.
6. `check.sh` verde; testes Lune para a lógica pura (estados e transições de tela, passo/formatação das configurações, contagem da moeda).
7. Docs: `docs/guia/telas.md` (como trocar um molde pelo Studio ou Figma→plugin, lista de nomes de cada tela, `TextKey`, o que o código anima) e `arquitetura.md`.

## 10. Deixado para o builder

- Nomes dos módulos/controladores e como os estados são guardados (seguindo o padrão Vide/`Sources`).
- Detalhes de animação (durações, curvas) dentro do espírito da identidade visual.
- Altura/velocidade da câmera do menu.
- Formato exato dos eventos Blink novos (validação no servidor obrigatória).
