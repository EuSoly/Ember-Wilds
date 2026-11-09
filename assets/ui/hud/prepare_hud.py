"""Recorta as artes do HUD (arte do Elizeu, 09/11, pasta "Hud do jogo").

Cada arquivo traz várias peças; as caixas abaixo foram medidas por blocos
conectados da transparência (x, y, largura, altura na imagem original).
Saída: um PNG por peça nesta pasta, no máximo no tamanho indicado.

Uso (precisa do Pillow):
    python assets/ui/hud/prepare_hud.py "C:/Users/Elize/Downloads/UI Assets/Hud do jogo"
"""

import os
import sys

from PIL import Image

OUT = os.path.dirname(os.path.abspath(__file__))
PREFIX = "Imagem do ChatGPT 9 de nov. de 2026, "

# arquivo -> [(nome, (x, y, w, h), maior lado)]
PIECES = {
    "13_44_16-1.png": [  # status
        ("status_frame", (112, 104, 424, 432), 256),
        ("status_health", (600, 160, 376, 332), 128),
        ("status_hunger", (1012, 152, 352, 336), 128),
        ("status_cold", (44, 600, 340, 368), 128),
        ("status_thirst", (420, 604, 268, 368), 128),
        ("status_heat", (724, 580, 332, 400), 128),
        ("status_oxygen", (1088, 608, 316, 352), 128),
    ],
    "13_44_16-2.png": [  # slots
        ("slot", (48, 292, 464, 472), 128),
        ("slot_selected", (572, 292, 472, 472), 128),
        ("lock", (1120, 376, 272, 320), 64),
    ],
    "13_44_17-3.png": [  # botões
        ("minimap_frame", (192, 28, 632, 648), 512),
        ("icon_settings", (964, 32, 308, 308), 128),
        ("icon_book", (968, 372, 300, 308), 128),
        ("button_round", (180, 708, 332, 352), 192),
        ("icon_backpack", (948, 708, 316, 332), 128),
        ("icon_rotate", (584, 752, 268, 276), 128),
    ],
    "13_44_17-4.png": [  # painéis e avisos
        ("panel", (52, 96, 776, 764), 512),
        ("toast_cream", (868, 92, 756, 148), 800),
        ("toast_orange", (868, 272, 756, 148), 800),
        ("toast_green", (868, 448, 756, 148), 800),
        ("tooltip", (1036, 648, 404, 220), 400),
    ],
    "13_44_18-5.png": [  # joystick
        ("joystick_base", (120, 176, 712, 728), 256),
        ("joystick_knob", (960, 364, 328, 340), 128),
    ],
}


def main(source):
    for file, pieces in PIECES.items():
        image = Image.open(os.path.join(source, PREFIX + file)).convert("RGBA")
        for name, (x, y, w, h), max_side in pieces:
            piece = image.crop((x, y, x + w, y + h))
            piece.thumbnail((max_side, max_side), Image.LANCZOS)
            piece.save(os.path.join(OUT, name + ".png"))
            print(f"{name}.png: {piece.size[0]}x{piece.size[1]}")
    # Balão de dica em duas peças: o corpo (esticado em 9 partes) e a pontinha
    # de baixo (desenhada por cima, no meio), para a ponta não deformar.
    tooltip = Image.open(os.path.join(OUT, "tooltip.png"))
    tooltip.crop((0, 0, tooltip.width, 186)).save(os.path.join(OUT, "tooltip_body.png"))
    tooltip.crop((160, 178, 240, tooltip.height)).save(os.path.join(OUT, "tooltip_tail.png"))
    print("tooltip_body.png e tooltip_tail.png")


if __name__ == "__main__":
    main(sys.argv[1])
