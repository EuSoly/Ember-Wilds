# Bandagem (Bandage) - Starve / Ember Wilds

Modelo 3D e ícone de viewport criado para o item **Bandagem**, inspirado no visual original de *Starve.io* e adaptado à identidade visual de relevo/baixo-polígono do projeto Ember Wilds.

## Visual do Ícone no Starve.io
- **Formato:** Rolo cilíndrico de gaze/tecido médico branco (`Inv_bandage.png`), levemente inclinado com uma faixa de tecido desenrolando para o lado.
- **Símbolo:** Uma cruz vermelha médica centralizada em destaque (primeiros socorros).
- **Estilo:** Traço cartoon 2D limpo com contorno escuro marcante (`#1E2230`) e sombreamento sutil em camadas.
- **Função no jogo:** Item utilitário fabricado na Workbench com 2 Fios (`Thread`). Triplica a regeneração natural (15% de vida a cada 10 s) desde que Fome, Sede, Temperatura e Oxigênio estejam acima de 35%. Acumula até 20 unidades.

## Arquivos Gerados
- `bandage.blend`: Cena editável aberta no Blender com materiais, hierarquia e root empty (`bandage_root`).
- `bandage.fbx`: Exportação 3D pronta para importação no Roblox Studio.
- `bandage-preview.png`: Renderização transparente com ângulo isométrico e iluminação de estúdio.
- `manifest.json`: Definição de atributos, cores e parâmetros de fabricação do item.

## Estrutura da Coleção (`bandage`)
- `bandage_root`: Empty para pivô e metadados (`item_id = 'bandage'`, `purpose = 'inventory_viewport_icon'`).
- `Bandage_Layer_Outer`: Rolo externo de gaze com chanfro e acabamento suave.
- `Bandage_Layer_Mid` / `Bandage_Layer_Inner`: Camadas concêntricas de enrolamento com variação tonal.
- `Bandage_Spool` / `Bandage_Hole`: Tubo central de papelão/carretel com miolo escuro.
- `Bandage_Unrolled_Strip`: Faixa solta de gaze desenrolando em curva Bezier.
- `Bandage_Badge` & `Bandage_Cross`: Selo médico branco com a cruz vermelha em alto-relevo chanfrado.
- `Bandage_Roll_Outline` & `Bandage_Strip_Outline`: Base de contorno escuro (`#1E2230`) no estilo cel-shaded do projeto.
