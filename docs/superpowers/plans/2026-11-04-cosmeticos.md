# Cosméticos — plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Cosméticos de verdade (equipar salva e aparece no jogo), tela principal com vitrine + 5 cartões, tela da categoria com grade 3×3 da Comum à Mítica e cadeado, skins de exemplo, e a loja usando as mesmas skins — tudo alimentado por um arquivo só de dados fácil de editar.

**Architecture:** `src/shared/Defs/Cosmetics.luau` vira a fonte única (raridade, cores, imagem opcional, `inSpins`). Um módulo puro `src/shared/UIFlow/CosmeticCatalog.luau` transforma os dados em listas ordenadas por categoria (Cosméticos) e em itens de giro (loja, via `MockStore.SPIN_TYPES`). O servidor publica a posse em atributos e aceita um evento Blink para equipar. As vitrines reaproveitam o `MenuBoneco` (com mochila provisória) e o `CrateModel` (com cores da skin).

**Tech Stack:** Luau `--!strict`, Vide, Blink (`net/game.blink`), Lune (`lune run tests/run`), `bash scripts/check.sh`. PATH precisa de `$HOME/.rokit/bin`.

**Spec:** `docs/superpowers/specs/2026-11-04-cosmeticos-design.md`

## Global Constraints

- Categorias e lados (Elizeu): esquerda **Skins** (`body`), **Acessórios** (`accessory`, "Em breve", sem slot de dados ainda), **Caixa** (`crate`, uma só para saque e morte); direita **Mochila** (`bag`), **Livro** (`book`).
- **Livro: uma skin só, o modelo `Assets.Tools.book`** (`book_default`). Nada de tingir ou livro provisório.
- Raridades 1..5 = `MockStore.RARITIES` (Comum #9CA3AF, Raro #3B9DFF, Épico #A855F7, Lendário #FFBD38, Mítico #FF4545). Grade ordenada da Comum à Mítica.
- Skin bloqueada: escurecida + cadeado; clicar só mostra na vitrine. Skin possuída: clicar equipa (servidor valida posse).
- Giros da loja continuam simulados (não dão skin). Categoria sem itens de giro → "Em breve" na loja.
- Visual rústico (corpo `#2B2018`, placas `Rustic.plate`, botões `Rustic.button`), como Configurações/Perfil. Nada copiado da tela de referência nem de `assets/skins/reference/`.
- Textos pt-BR com acentos. Branch `cosmeticos`. Commits pt-BR terminando com `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Sem push. Depois de mexer em código: `& (Get-Content graphify-out\.graphify_python) -m graphify update .`.

## Review Focus

1. Pedido de equipar forjado pelo cliente (id inexistente, de outro slot, não possuído, string enorme, spam): ignorado sem warn, sem mudar o perfil.
2. Perfil com equipado salvo de um slot novo (`bag`/`book`) ausente: cai no padrão sem erro (perfis antigos não têm esses slots).
3. Categoria com uma página só, ou vazia (Acessórios): setas desativadas, nada quebra; loja não abre giro sem itens.
4. Dar posse com o comando de dev com a tela aberta: o cadeado some na hora.
5. Trocar de categoria / voltar depois de "experimentar" uma bloqueada: a vitrine volta ao que está equipado de verdade.

---

### Task 1: Dados das skins e catálogo (puro)

**Files:**
- Modify: `src/shared/Defs/Types.luau` (`CosmeticDef` + `rarity: number`, `image: string?`, `inSpins: boolean?`, `bag: BagLook?`, `crate: CrateLook?`; `BagLook = { color: string, strapColor: string }`, `CrateLook = { bodyColor: string, bandColor: string }`)
- Modify: `src/shared/Defs/CosmeticSlots.luau` (+ `bag` default `bag_default`, `book` default `book_default`)
- Modify: `src/shared/Defs/Cosmetics.luau` (todas com `rarity`; skins de exemplo; comentário-guia no topo explicando cada campo)
- Modify: `src/shared/Defs/Validate.luau` (`validateCosmetics`: rarity inteira 1..5; `bag` exige `bag`, `crate` exige `crate` com cores `#RRGGBB`; `image` se presente casa `^rbxassetid://%d+$`)
- Modify: `src/shared/Strings/ptBR.luau` (`cosmetic.<id>` de cada skin nova; `cosmeticSlot.bag` "Mochila", `cosmeticSlot.book` "Livro")
- Create: `src/shared/UIFlow/CosmeticCatalog.luau`
- Test: `tests/cosmeticcatalog.spec.luau`, `tests/defs.spec.luau`

**Skins de exemplo** (nomes nossos em pt-BR; ids `body_*`, `bag_*`, `crate_*`):
- body: `body_default` (1, existe), `body_ember` (existe; rarity 3) + 8 novas → 2 Comuns, 2 Raras, 3 Épicas (contando ember), 2 Lendárias, 1 Mítica (10 no total, 2 páginas).
- bag: `bag_default` (1, couro `#95603D`/alça `#59402D`) + 5 (uma por raridade 1..5).
- crate: `crate_default` (1; corpo madeira `#A77B4F`, faixas douradas = as cores atuais do placeholder) + 5 (uma por raridade).
- book: só `book_default` (1, `inSpins = true`).

**Interfaces:**
- Produces:
  - `CosmeticCatalog.CATEGORIES: { { id: string, side: "left"|"right", slot: string? } }` na ordem: `body`(left), `accessory`(left, slot nil), `crate`(left), `bag`(right), `book`(right).
  - `CosmeticCatalog.items(slot: string): { CosmeticDef }` — todas do slot, ordenadas por `rarity` e depois `id`.
  - `CosmeticCatalog.spinItems(slot: string): { { id, nameKey, rarity, color, image? } }` — mesmas regras de ordem; inclui as com `inSpins ~= false`, **exceto** o padrão do slot, que só entra com `inSpins == true`.
  - `CosmeticCatalog.colorOf(def): string` — body→`bodyColor`, bag→`color`, crate→`bandColor`, outros→`"#8B5A2B"`.
  - `CosmeticCatalog.pageCount(count: number, perPage: number): number` (mínimo 1) e `CosmeticCatalog.page<T>(list: {T}, page: number, perPage: number): {T}` (página fora da faixa → presa).

- [ ] **Step 1: Failing tests** (`tests/cosmeticcatalog.spec.luau`): `items("body")` começa em `body_default` e as raridades não decrescem; `spinItems("body")` não tem `body_default`; `spinItems("book")` == `{ book_default }`; `spinItems("bag")` cobre raridades 1..5; `colorOf` por slot; `pageCount(0,9)==1`, `(9,9)==1`, `(10,9)==2`; `page(list10, 2, 9)` tem 1 item; `page(list10, 5, 9)` == página 2; `CATEGORIES` na ordem/lados acima. Em `tests/defs.spec.luau`: cosmético com `rarity = 6` → erro com `rarity`; slot `bag` sem `bag` → erro.
- [ ] **Step 2: Run** `lune run tests/run` — Expected: FAIL (catálogo não existe; validação sem as regras).
- [ ] **Step 3: Implement** tipos, slots, dados, validação, strings, catálogo.
- [ ] **Step 4: Run** `bash scripts/check.sh` — Expected: exit 0.
- [ ] **Step 5: Commit** `feat: skins com raridade num arquivo só e catálogo dos cosméticos`

### Task 2: Equipar de verdade (servidor + rede)

**Files:**
- Modify: `net/game.blink` (+ `event EquipCosmetic { From: Client, Type: Reliable, Call: SingleAsync, Data: struct { Id: string(1..48) } }`)
- Modify: `src/shared/StatNames.luau` (+ `OwnedPrefix = "Owns_"`)
- Modify: `src/server/Services/CosmeticService.luau` (publica `Owns_<id> = true` no Player para cada possuído ao carregar e no `grantOwnership`; handler do `EquipCosmetic` com intervalo mínimo de 0,2 s por jogador, chamando `equip`; inválido ignorado em silêncio)
- Modify: `src/shared/Models/CrateModel.luau` (placeholder de caixa de **jogador** usa `Defs.Cosmetics[modelId].crate` para corpo/faixas quando existir)

**Interfaces:**
- Produces: atributos `Owns_<id>` no Player; `Net.EquipCosmetic.Fire({ Id })`; `Cosmetic_bag`/`Cosmetic_book` passam a existir (slots novos, já escritos pelo `loadEquipped`/`apply`).

- [ ] **Step 1:** Implementar. A skin padrão não precisa de `Owns_` (o cliente trata padrão como possuído via `CosmeticSlots`).
- [ ] **Step 2: Run** `bash scripts/check.sh` — Expected: exit 0.
- [ ] **Step 3: Verificar no Studio:** no Server, `DevGrantCosmetic(player, "body_<x>")` → `Owns_body_<x>` aparece no Client; `Net.EquipCosmetic.Fire({Id="body_<x>"})` pelo Client → `Cosmetic_body` muda; id não possuído/inexistente → nada muda; caixa da morte com skin de caixa equipada usa as cores dela.
- [ ] **Step 4: Commit** `feat: equipar cosmético pelo jogador e posse publicada`

### Task 3: Vitrines (boneco com mochila e livro, caixa)

**Files:**
- Create: `src/client/Menu/Cosmetics/BagModel.luau` (`BagModel.build(look: BagLook): Model` — mochila de peças: corpo, aba e duas alças; `BagModel.attach(model, boneco)` nas costas, em relação à raiz, a frente do boneco é −Z)
- Modify: `src/client/Menu/MenuBoneco.luau` (`MenuBoneco.build(visible, override: (() -> { body: string?, bag: string? })?)` — sem override lê `Cosmetic_body`/`Cosmetic_bag` do Player; desenha a mochila; o livro continua o modelo atual)
- Create: `src/client/Menu/Cosmetics/CratePreview.luau` (`CratePreview.build(skinId: () -> string): ViewportFrame` com `CrateModel.build`)

**Interfaces:**
- Produces: `MenuBoneco.build(visible: () -> boolean, override: (() -> { body: string?, bag: string? })?): ViewportFrame`; `CratePreview.build(skinId: () -> string): ViewportFrame`.

- [ ] **Step 1:** Implementar; o boneco do centro do menu passa a mostrar a mochila equipada.
- [ ] **Step 2: Run** `bash scripts/check.sh` — Expected: exit 0.
- [ ] **Step 3: Verificar no Studio:** menu mostra o boneco com mochila nas costas e livro; trocar `Cosmetic_bag` no Server muda a cor.
- [ ] **Step 4: Commit** `feat: vitrine do boneco com mochila e prévia da caixa`

### Task 4: Tela principal dos Cosméticos

**Files:**
- Create: `src/client/Menu/Cosmetics/CosmeticsScreen.luau` (janela rústica no centro como o Perfil, sem fundo escuro; estado local `category: string?` — nil = principal)
- Modify: `src/client/Menu/MenuShell.luau` (`cosmetics` sai de `PANELS`/`CONTENT`; a janela entra como o Perfil)
- Delete: `src/client/Menu/CosmeticsPanel.luau`; remover `MockStore.CATEGORIES` e o que só ele usava (+ testes e strings `mock.*` de cosméticos)
- Modify: `src/shared/Strings/ptBR.luau` (`cosmetics.title` "Cosméticos", `cosmetics.soon` "Em breve", `cosmetics.tagline.<categoria>` — frases curtas nossas)

**Interfaces:**
- Consumes: `CosmeticCatalog.CATEGORIES/items/colorOf`, `MenuBoneco.build`, `CratePreview.build`, atributos `Owns_<id>` e `Cosmetic_<slot>`.

- [ ] **Step 1:** Vitrine no meio (boneco equipado) com a caixa equipada embaixo; cartões à esquerda (Skins, Acessórios, Caixa) e à direita (Mochila, Livro): placa com o nome, frase, amostra (até 3 quadradinhos das skins possuídas na cor da raridade/cor da skin). Acessórios: "Em breve", não abre. Clicar num cartão abre a categoria (Task 5). No celular: cartões em duas colunas acima/abaixo da vitrine ou lista que rola — a escolha que couber sem cortar.
- [ ] **Step 2: Run** `bash scripts/check.sh` — Expected: exit 0.
- [ ] **Step 3: Verificar no Studio** PC e celular (`Setting_ui_scale` 2).
- [ ] **Step 4: Commit** `feat: tela principal dos Cosméticos com a vitrine e as categorias`

### Task 5: Tela da categoria

**Files:**
- Create: `src/client/Menu/Cosmetics/CategoryView.luau`
- Modify: `src/client/Menu/Cosmetics/CosmeticsScreen.luau`

**Interfaces:**
- Consumes: `CosmeticCatalog.items/page/pageCount/colorOf`, `MockStore.RARITIES`, `Net.EquipCosmetic`, `MenuBoneco.build` (override com a skin "experimentada"), `CratePreview.build`.

- [ ] **Step 1:** Esquerda: vitrine (corpo/mochila → boneco; caixa → prévia da caixa; livro → boneco com o livro) + nome e raridade (na cor) da selecionada. Direita: placa com a categoria; grade 3×3 (`page`), setas `<` `>` desativadas na ponta; quadradinho com fundo na cor da raridade, cor/imagem da skin, nome; possuída equipada com destaque; bloqueada escurecida com cadeado. Clique: possuída → `EquipCosmetic` (seleção = ela); bloqueada → só seleção (experimentar). Voltar: volta à principal e a vitrine ao equipado. Reabrir a categoria começa na página da equipada.
- [ ] **Step 2: Run** `bash scripts/check.sh` — Expected: exit 0.
- [ ] **Step 3: Verificar no Studio:** equipar uma possuída (persiste depois de sair e voltar ao Play), experimentar bloqueada, dar posse com o dev e ver o cadeado sumir, páginas da categoria Skins.
- [ ] **Step 4: Commit** `feat: escolher skin por categoria, com cadeado e prévia`

### Task 6: Loja com as skins reais

**Files:**
- Modify: `src/shared/UIFlow/MockStore.luau` (`SPIN_TYPES[i].items = CosmeticCatalog.spinItems(id)`; `SpinItem` ganha `image: string?`; some o gerador de itens falsos e as strings `shop.item.*`)
- Modify: `src/client/Menu/Shop/SpinTile.luau` (imagem quando houver), `SpinTypes.luau` (tipo sem itens → "Em breve", sem Escolher), `ShopState.luau` (`openSpin` recusa tipo sem itens)
- Modify: `tests/mockstore.spec.luau` (itens vêm do catálogo; só `accessory` vazio; raridades 1..5)

- [ ] **Step 1: Failing test:** `MockStore.SPIN_TYPES` de `body` tem os mesmos ids de `CosmeticCatalog.spinItems("body")`; `accessory` vazio; `book` = `{ book_default }`.
- [ ] **Step 2: Run** — Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `bash scripts/check.sh` — Expected: exit 0.
- [ ] **Step 5: Verificar no Studio:** carrossel e prêmio mostram as skins reais; Acessórios "Em breve"; giro de livro mostra o livro.
- [ ] **Step 6: Commit** `feat: loja usa as skins reais dos cosméticos`

### Task 7: Guia "como adicionar ou mudar uma skin"

**Files:**
- Modify: `docs/guia/boneco.md` ou `docs/guia/telas.md` (seção Cosméticos (UI 5) + passo a passo: campos de uma skin, raridade, imagem, `inSpins`, texto, comando de dev para testar); `docs/guia/dados.md` (posse `Owns_`, evento `EquipCosmetic`)

- [ ] **Step 1:** Escrever; `bash scripts/check.sh` (exit 0); `graphify update`.
- [ ] **Step 2: Commit** `docs: guia dos Cosméticos e de como adicionar uma skin`
