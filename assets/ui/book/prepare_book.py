"""Recorta as artes do livro de receitas (arte do Elizeu, 09/11, pasta
"Livro de Craft").

Caixas medidas pelos blocos da transparência (x, y, largura, altura na imagem
original). Saída: um PNG por peça nesta pasta, no máximo no tamanho indicado.

Uso (precisa do Pillow):
    python assets/ui/book/prepare_book.py "C:/Users/Elize/Downloads/UI Assets/Livro de Craft"
"""

import os
import sys

from PIL import Image

OUT = os.path.dirname(os.path.abspath(__file__))
PREFIX = "Imagem do ChatGPT 9 de nov. de 2026, "

# arquivo -> [(nome, (x, y, w, h), maior lado)]
PIECES = {
    PREFIX + "15_13_14-1.png": [  # estrutura
        ("tab", (32, 148, 620, 224), 256),  # aba normal (madeira escura)
        ("tab_selected", (28, 432, 628, 212), 256),  # aba selecionada (laranja)
        ("paper", (688, 84, 728, 916), 512),  # papel da ficha
        ("icon_close", (212, 712, 260, 272), 128),  # X no octógono de madeira
    ],
    PREFIX + "15_13_15-2.png": [  # ícones das abas, soltos
        ("tab_tools", (44, 100, 440, 400), 128),
        ("tab_weapons", (520, 88, 400, 416), 128),
        ("tab_armor", (1004, 88, 388, 424), 128),
        ("tab_food", (44, 592, 424, 424), 128),
        ("tab_build", (508, 576, 404, 440), 128),
        ("tab_resources", (960, 596, 456, 424), 128),
    ],
    PREFIX + "15_13_15-3.png": [  # os mesmos, no octógono de madeira (selos)
        ("badge_tools", (68, 136, 400, 380), 128),
        ("badge_weapons", (524, 136, 400, 380), 128),
        ("badge_armor", (976, 136, 400, 380), 128),
        ("badge_food", (68, 584, 400, 384), 128),
        ("badge_fire", (524, 584, 400, 384), 128),  # fogueira: "precisa de fogo"
        ("badge_resources", (976, 584, 400, 384), 128),
    ],
    PREFIX + "15_13_16-4.png": [  # recursos do mapa
        ("res_tree", (140, 16, 504, 540), 128),
        ("res_rock", (740, 88, 548, 432), 128),
        ("res_berry_bush", (736, 588, 564, 480), 128),
        ("res_gold_vein", (152, 620, 504, 448), 128),
    ],
    "Glossy Blue Water Droplet.png": [
        ("icon_water", (536, 176, 456, 632), 128),
    ],
    "Glossy Water Droplet Badge.png": [
        ("badge_water", (744, 16, 680, 688), 128),  # "precisa de água"
    ],
    # Folha das 15:24: os quatro da direita em cima se encostam; a faixa
    # (380..1740) foi dividida em quatro e cada pedaço é aparado pela transparência.
    "Ember Wilds Crafting and Stats Icons.png": [
        ("badge_workbench", (32, 64, 344, 352), 128),
        ("badge_clock", (380, 64, 340, 352), 128),
        ("stat_damage", (720, 64, 340, 352), 128),
        ("stat_structure", (1060, 64, 340, 352), 128),
        ("stat_speed", (1400, 64, 340, 352), 128),
        ("stat_equiplock", (140, 468, 344, 352), 128),
        ("stat_defense", (520, 468, 340, 352), 128),
        ("stat_reach", (896, 468, 344, 352), 128),
        ("stat_pickaxe", (1280, 468, 344, 352), 128),
    ],
}


def main(source):
    for file, pieces in PIECES.items():
        image = Image.open(os.path.join(source, file)).convert("RGBA")
        for name, (x, y, w, h), max_side in pieces:
            piece = image.crop((x, y, x + w, y + h))
            box = piece.getchannel("A").point(lambda v: 255 if v > 20 else 0).getbbox()
            if box:
                piece = piece.crop(box)
            piece.thumbnail((max_side, max_side), Image.LANCZOS)
            piece.save(os.path.join(OUT, name + ".png"))
            print(f"{name}.png: {piece.size[0]}x{piece.size[1]}")


if __name__ == "__main__":
    main(sys.argv[1])
