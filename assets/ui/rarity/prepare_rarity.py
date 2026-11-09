"""Recorta os 5 fundos de raridade (arte do Elizeu, 09/11).

Entrada: "fundos das raridades.png" (cinza, azul, roxo, amarelo, vermelho,
lado a lado, fundo transparente). Saída: rarity_1.png .. rarity_5.png nesta
pasta (Comum, Raro, Épico, Lendário, Mítico), quadrados de 256 px, com uma
folga transparente igual em volta (o contorno escuro fica inteiro).

Uso (precisa do Pillow e do numpy):
    python assets/ui/rarity/prepare_rarity.py "C:/Users/Elize/Downloads/UI Assets/fundos das raridades.png"
"""

import os
import sys

import numpy as np
from PIL import Image

OUT = os.path.dirname(os.path.abspath(__file__))
SIZE = 256


def runs(flags, gap=6):
    out, start, empty = [], None, 0
    for i, value in enumerate(flags):
        if value:
            if start is None:
                start = i
            empty = 0
        elif start is not None:
            empty += 1
            if empty > gap:
                out.append((start, i - empty + 1))
                start, empty = None, 0
    if start is not None:
        out.append((start, len(flags)))
    return out


def main(source):
    image = Image.open(source).convert("RGBA")
    alpha = np.array(image)[:, :, 3] > 40
    columns = [r for r in runs(alpha.any(axis=0)) if r[1] - r[0] > 100]
    assert len(columns) == 5, f"esperava 5 quadrados, achei {len(columns)}"
    for index, (x0, x1) in enumerate(columns, start=1):
        rows = np.nonzero(alpha[:, x0:x1].any(axis=1))[0]
        piece = image.crop((x0, rows.min(), x1, rows.max() + 1))
        side = max(piece.size)
        square = Image.new("RGBA", (side, side), (0, 0, 0, 0))
        square.paste(piece, ((side - piece.size[0]) // 2, (side - piece.size[1]) // 2))
        square = square.resize((SIZE, SIZE), Image.LANCZOS)
        square.save(os.path.join(OUT, f"rarity_{index}.png"))
        print(f"rarity_{index}.png: {piece.size[0]}x{piece.size[1]} -> {SIZE}x{SIZE}")


if __name__ == "__main__":
    main(sys.argv[1])
