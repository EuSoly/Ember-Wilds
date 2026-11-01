# HUD (interface do jogo)

O HUD é feito com [Vide](https://centau.github.io/vide/), uma biblioteca reativa: um componente é uma função que monta instâncias, e as propriedades podem ser **funções**. Quando o dado que a função lê muda, o Vide atualiza só aquela propriedade.

```lua
local create = vide.create
local count = vide.source(0) -- fonte: count() lê, count(5) escreve

create("TextLabel")({
	Text = function()
		return `Itens: {count()}` -- atualiza sozinho quando count muda
	end,
})
```

## Onde fica cada coisa

| Arquivo | O que é |
|---|---|
| `src/client/Controllers/HudController.luau` | Monta o HUD no PlayerGui |
| `src/client/UI/App.luau` | O ScreenGui `Hud` e a lista de componentes |
| `src/client/UI/Kit.luau` | Peças base no estilo da identidade visual: `Kit.panel`, `Kit.text`, `Kit.pill` |
| `src/client/UI/Sources.luau` | Fontes reativas: `attribute`, `isTouch`, `preferredInput`, `cycle` |
| `src/client/UI/StatusRing(s).luau` | Anéis de vida, fome, frio e sede |
| `src/client/UI/ScorePill.luau`, `Clock.luau`, `Minimap.luau` | Topo da tela |
| `src/client/UI/Minimap.luau` | Mapa inteiro esquemático (os quatro biomas a partir do `WorldConfig`, regiões fechadas escurecidas) e o ponto do jogador |
| `src/client/World/OxygenBubble.luau` | Bolha de ar ao lado do próprio boneco (no mundo, não na HUD): aparece na água ou com o fôlego abaixo do cheio, pisca abaixo de 25% |
| `src/client/UI/Notifications.luau` | Avisos (`Notifications.push("chave.do.texto")`) |
| `src/client/UI/Hotbar.luau`, `SlotButton.luau`, `ItemIcon.luau`, `src/client/HotbarState.luau` | Hotbar (slots 1–10 do inventário) |
| `src/client/UI/AimStick.luau` | Joystick direito do celular |
| `src/client/UI/Backpack.luau`, `InventoryGrid.luau`, `src/client/BackpackState.luau` | Botão e painel da mochila (só com slots além da hotbar), com a grade que cresce com a capacidade |
| `src/client/InventoryState.luau` | Cópia do inventário vinda do servidor (veja `inventario.md`) |
| `src/client/UI/SettingsButton.luau` | Engrenagem (canto superior direito, abaixo do minimapa): abre e fecha as configurações |
| `src/client/UI/CraftColumn.luau`, `src/client/CraftState.luau` | Receitas disponíveis, tooltip e progresso; clique na receita ativa cancela |
| `src/client/UI/RecipeBookButton.luau` | Abre o livro completo de receitas |
| `src/client/UI/ChestPanel.luau`, `src/client/ChestState.luau` | Painel do baú sobre a hotbar quando há um baú perto (item guardado e quantidade; clicar tira). Veja `construcao.md` |
| `src/client/World/BuildGhost.luau` | Fantasma verde/vermelho no chão com uma peça na mão (aproximação; o servidor decide) |
| `src/client/World/StructureHealth.luau` | Barrinha de vida da peça por 3 s depois de levar dano |
| `src/client/World/CraftBubble.luau` | Engrenagem girando e anel de progresso acima do **próprio** boneco enquanto crafta (os outros jogadores não veem) |

## Quando o HUD aparece

O HUD só aparece **jogando** (estado `playing`). No carregamento, no menu e na tela de morte, quem aparece são as telas de molde (veja `telas.md`). Isso é a propriedade `Enabled` do ScreenGui `Hud`, ligada ao `ScreenState`.

A configuração **Tamanho da interface** (`ui_scale`) também vale para o HUD: um `UIScale` no ScreenGui `Hud` segue o atributo `Setting_ui_scale`.

## Como adicionar um componente

1. Crie `src/client/UI/MeuComponente.luau` com uma função que devolve a instância (use o `Kit` para painéis e textos).
2. Coloque `MeuComponente()` na lista `children` do `App.luau`.
3. Posicione e dimensione com **Scale** (`UDim2.fromScale`) e trave a proporção com `UIAspectRatioConstraint`.
4. Cores do `Theme`, textos de `Strings`. Nada de cor ou texto escrito direto.

Conexões feitas dentro de um `task.spawn` (ex.: esperar uma InputAction e ligar `Pressed`) não são limpas sozinhas pelo Vide: registre a limpeza com `vide.cleanup` antes do `task.spawn`.

Tamanhos: tudo escala com a tela, mas botões de toque e slots têm `UISizeConstraint` (mínimo 44 px, slots até 56 px — `Theme.touchMinSize`, `Theme.slotMinSize`, `Theme.slotMaxSize`). Componentes presos a outro (os anéis acima da hotbar) vão como filhos dele, para nunca se sobreporem.

Cuidado com efeitos (`vide.effect`): ler uma fonte dentro de um efeito faz o efeito depender dela. Se o efeito também **escreve** nessa fonte, ele entra em loop. Use `vide.untrack(fonte)` para ler sem depender, ou `task.defer` para escrever fora do efeito (foi o bug do aviso "A noite está chegando").

## De onde vêm os dados

O HUD **não lê o Workspace** (com streaming, partes do mapa podem nem estar carregadas). Ele lê:

- **Atributos do Player**: `Health`, `Hunger`, `Cold`, `Thirst`, `Heat` (0–100; o anel do frio mostra o calor quando ele passa de 0), `Score`, `Rank`. Nomes em `src/shared/StatNames.luau`.
- **Atributo do Workspace**: `CycleStart`, o início do ciclo de dia (`src/shared/DayCycle.luau` calcula dia, hora e aviso de noite).
- **InputActions** do contexto `Gameplay` (seleção de slot, mochila).
- **Inventário** (`InventoryState`): cópia mantida pelo servidor via rede (Blink). A hotbar e a mochila só leem daqui; para mover ou selecionar, o cliente pede ao servidor. Veja `inventario.md`.
- Exceção: o minimapa lê a posição do próprio personagem.

As barras (`Health`, `Hunger`, `Cold`, `Thirst`) são do `SurvivalService` desde a G1 (veja `sobrevivencia.md`). Pontos e ranking são de verdade desde a G2 (`ScoreService`: a coleta dá pontos; o ranking é a posição entre os jogadores vivos; veja `coleta.md`). Os itens iniciais de teste ainda vêm do `DevItemsService` (só no Studio).

A coluna de crafting lista receitas cujos ingredientes estão no inventário e cuja estação necessária está a até 10 studs. O botão de livro abre a tela completa e destaca os ingredientes faltantes. Botão direito cancela no PC; no celular, toque de novo na receita ativa. Veja `crafting.md`.

## Controles por dispositivo

| | PC | Celular |
|---|---|---|
| Andar | WASD | Joystick esquerdo (nativo) |
| Mirar | Mouse | Joystick direito |
| Bater (atacar/coletar) | Segurar botão esquerdo | Segurar o joystick direito |
| Slot da hotbar | Teclas 1 … 0 ou clique | Toque no slot |
| Mochila | Tecla B | Botão "Mochila" |
| Mover item | Arrastar com o mouse entre slots | Arrastar com o dedo entre slots |

Os controles de toque (joystick direito e botão de mochila) aparecem só quando `UserInputService.PreferredInput` é `Touch`, e trocam sozinhos se o jogador mudar de dispositivo.
