# Tarefa 2 - Casca do menu

Implementado: MenuState (panel source + open), MenuShell (coluna com 6 botoes, barra com nivel/XP falsos, saldo real Currency, "+" para "buy", selo MOCKUP, 6 paineis placeholder com titulo e Fechar), montagem no ScreenController (so Enabled no estado "menu"; volta a "play" ao sair do menu), MainMenu esconde Root.Visible quando panel ~= "play". Strings menu.nav.*, menu.panel.*, menu.close/level/xp/mockup.

Teste: bash scripts/check.sh verde (396 passed, 0 failed; stylua, selene, luau-lsp ok). Sem teste Lune novo (so UI Roblox).

Arquivos: src/client/Menu/MenuShell.luau, src/client/Menu/MenuState.luau, src/client/Controllers/ScreenController.luau, src/client/Screens/MainMenu.luau, src/shared/Strings/ptBR.luau.

Notas: escrita do painel via MenuState.open (escrever direto pela fonte quebrava a tipagem). Nao testado visualmente no Studio: a barra/coluna do MenuShell (DisplayOrder 1) pode sobrepor elementos do molde MainMenu (BalanceLabel, engrenagem) no painel "play".

## Fix round 1
- TopBar replaced by two corner pods (TopLeft x 0.01-0.25: Level + MockupBadge, XpBar below; TopRight x 0.75-0.99: Balance + BuyButton), center free for the template logo.
- MainMenu: template BalanceLabel set Visible=false (shell owns the balance); warn() when Root is missing.
- BuyButton and column minimums derive from Theme.touchMinSize.
- Test: bash scripts/check.sh exit 0, 396 passed, 0 failed.

## Final fix
- I1/M9: new pure module src/shared/UIFlow/MenuLayout.luau + tests/menulayout.spec.luau (800x400, 1130x793, 1920x1080, plus a 300-high case that scrolls). Shell uses pixel offsets: pods 56 px tall at the top, body starts at 72 px, column is a ScrollingFrame (buttons 44 px, 4 px gap), panels have a 52 px title row and their content frame is repositioned below it; Cosmetics tabs row fixed at touch min, preview/grid start below it.
- M1 comment fixed (template DisplayOrder is 10). M8: Enabled also requires not SettingsScreen.open(). M7: order Perfil, Jogar, Cosméticos, Loja, Tutorial, Ranking. M6: header comment updated.
- Docs: telas.md (M2, M3, M4, layout module), pendencias.md (M5 items). graphify update run.
- Test: bash scripts/check.sh exit 0, 401 passed, 0 failed. Not re-checked visually in Studio.
