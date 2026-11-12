"""Prepara as artes da tela de Missões (arte do Elizeu gerada por IA, 12/11).

Entrada: a pasta `ember_wilds_missoes_assets` do zip (PNGs já recortados, com
transparência). Saída: um PNG por peça nesta pasta, com no máximo 1024 px no
maior lado (o Roblox reduz para isso de qualquer jeito), e as medidas finais
impressas para o src/shared/MissionImages.luau.

O ícone do Cronista usa a variação `conquista_cronista_alternativo` (pergaminho
com ampulheta), para não confundir com o ícone da aba Partida.

Uso (precisa do Pillow):
    python3 -E -P assets/ui/missoes/prepare_missoes.py "<pasta>/ember_wilds_missoes_assets"
"""

import os
import sys

from PIL import Image

OUT = os.path.dirname(os.path.abspath(__file__))
MAX_SIDE = 1024

# Arquivo de saída -> arquivo de entrada (relativo à pasta do zip).
PIECES = {
    "window.png": "componentes/janela_missoes.png",
    "tab.png": "componentes/aba_normal.png",
    "tab_on.png": "componentes/aba_selecionada.png",
    "card_active.png": "componentes/cartao_andamento.png",
    "card_done.png": "componentes/cartao_completa.png",
    "card_failed.png": "componentes/cartao_falhou.png",
    "bar_track.png": "componentes/progresso_trilho.png",
    "bar_orange.png": "componentes/progresso_preenchimento_laranja.png",
    "bar_green.png": "componentes/progresso_preenchimento_verde.png",
    "claim.png": "componentes/botao_resgatar_normal.png",
    "claim_down.png": "componentes/botao_resgatar_apertado.png",
    "plate.png": "componentes/plaquinha_premio.png",
    "dot.png": "avisos/aviso_bolinha.png",
    "banner_done.png": "avisos/faixa_completou.png",
    "banner_failed.png": "avisos/faixa_falhou.png",
    "medal_bronze.png": "medalhas/medalha_bronze.png",
    "medal_silver.png": "medalhas/medalha_prata.png",
    "medal_gold.png": "medalhas/medalha_ouro.png",
    "medal_locked.png": "medalhas/medalha_bloqueada.png",
}

ICONS = [
    "missao_hud",
    "aba_partida",
    "aba_diarias",
    "aba_semanais",
    "aba_conquistas",
    "chrono_sobreviver",
    "chrono_maos_limpas",
    "conquista_lenhador",
    "conquista_minerador",
    "conquista_cacador",
    "conquista_sobrevivente",
    "conquista_artesao",
    "conquista_lenda",
    "conquista_guerreiro",
    "conquista_fiel",
    "premio_giro_especial",
    "premio_uso_kit",
]
for name in ICONS:
    PIECES[f"icon_{name}.png"] = f"icones/{name}.png"
PIECES["icon_conquista_cronista.png"] = "icones/conquista_cronista_alternativo.png"


def fit(image):
    """Reduz para caber em MAX_SIDE mantendo a proporção (nunca aumenta)."""
    w, h = image.size
    scale = min(1.0, MAX_SIDE / max(w, h))
    if scale < 1.0:
        image = image.resize((round(w * scale), round(h * scale)), Image.LANCZOS)
    return image


# Pontas dos cartões pronto/falhou (a fita com o ✓/✗), recortadas de x 800 até
# o fim: vão por cima do cartão sem 9 partes (com 9 partes o Roblox deformava a fita).
CAPS = {"card_done_cap.png": "card_done.png", "card_failed_cap.png": "card_failed.png"}
CAP_LEFT = 800


def main():
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(2)
    source = sys.argv[1]
    for out_name, in_name in PIECES.items():
        image = Image.open(os.path.join(source, in_name)).convert("RGBA")
        image = fit(image)
        image.save(os.path.join(OUT, out_name))
        print(f"{out_name}: {image.size[0]}x{image.size[1]}")
    for out_name, card in CAPS.items():
        image = Image.open(os.path.join(OUT, card)).convert("RGBA")
        cap = image.crop((CAP_LEFT, 0, image.size[0], image.size[1]))
        cap.save(os.path.join(OUT, out_name))
        print(f"{out_name}: {cap.size[0]}x{cap.size[1]}")


if __name__ == "__main__":
    main()
