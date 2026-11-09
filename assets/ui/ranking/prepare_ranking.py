"""Recorta as artes do ranking semanal (UI 6) geradas pelo Elizeu.

Entrada: a pasta "UI dos rankings" (PNGs com transparência, algumas peças
juntas no mesmo arquivo). Saída: um PNG por peça nesta pasta, com no máximo
1024 px no maior lado (o Roblox reduz para isso de qualquer jeito), e as
medidas do pódio (frações da imagem) para o src/shared/RankingImages.luau.

Uso (precisa do Pillow e do numpy):
    python assets/ui/ranking/prepare_ranking.py "C:/Users/Elize/Downloads/UI Assets/UI dos rankings"
"""

import os
import sys

import numpy as np
from PIL import Image

OUT = os.path.dirname(os.path.abspath(__file__))
PREFIX = "Imagem do ChatGPT 9 de nov. de 2026, "


def runs(flags, gap=8):
    """Faixas [início, fim) de posições com algo opaco, juntando buracos de até `gap`."""
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


def pieces(path, threshold=60, min_size=40):
    """Peças separadas por linhas e colunas vazias, de cima para baixo e da esquerda para a direita."""
    image = Image.open(path).convert("RGBA")
    alpha = np.array(image)[:, :, 3] > threshold
    found = []
    for y0, y1 in runs(alpha.any(axis=1)):
        if y1 - y0 < min_size:
            continue
        band = alpha[y0:y1]
        for x0, x1 in runs(band.any(axis=0)):
            if x1 - x0 < min_size:
                continue
            rows = np.nonzero(band[:, x0:x1].any(axis=1))[0]
            found.append(image.crop((x0, y0 + rows.min(), x1, y0 + rows.max() + 1)))
    return found


def clean(image, threshold=200):
    """Corta a peça na caixa do que é bem opaco (tira respingos soltos em volta)."""
    alpha = np.array(image)[:, :, 3] > threshold
    ys, xs = np.nonzero(alpha)
    return image.crop((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))


def save(image, name, max_side):
    image = image.copy()
    image.thumbnail((max_side, max_side), Image.LANCZOS)
    image.save(os.path.join(OUT, name))
    print(f"{name}: {image.size[0]}x{image.size[1]}")
    return image


def podium_spots(image):
    """Por degrau: centro x, topo do tampo e centro da plaquinha, em frações da imagem."""
    pixels = np.array(image.convert("RGBA")).astype(int)
    height, width = pixels.shape[:2]
    alpha = pixels[:, :, 3] > 60
    # Plaquinha = papel claro (bem mais claro que a madeira).
    light = alpha & (pixels[:, :, 0] > 200) & (pixels[:, :, 1] > 160) & (pixels[:, :, 2] > 100)
    columns = {2: 0.22, 1: 0.5, 3: 0.78}  # 2º à esquerda, 1º no meio, 3º à direita
    spots = {}
    for place, fx in columns.items():
        x = int(fx * width)
        column = alpha[:, x]
        top = int(np.argmax(column))
        plaque_rows = np.nonzero(light[:, x - 3 : x + 4].any(axis=1))[0]
        plaque_rows = plaque_rows[plaque_rows > top + height * 0.05]
        plaque = (plaque_rows.min() + plaque_rows.max()) / 2 if len(plaque_rows) else top
        spots[place] = (round(fx, 3), round(top / height, 3), round(plaque / height, 3))
    return spots


def main(source):
    def path(suffix):
        return os.path.join(source, PREFIX + suffix)

    save(pieces(path("12_17_19-1.png"))[0], "frame.png", 1024)
    save(pieces(path("12_17_19-2.png"))[0], "trophy.png", 512)
    save(pieces(path("12_17_20-3.png"))[0], "medal_1.png", 256)
    save(pieces(path("12_17_20-4.png"))[0], "medal_2.png", 256)
    save(pieces(path("12_17_21-5.png"))[0], "medal_3.png", 256)
    light, dark = pieces(path("12_17_22-6.png"))[:2]
    save(light, "row_light.png", 1024)
    save(dark, "row_dark.png", 1024)
    save(clean(pieces(path("12_21_19-1.png"))[0]), "row_me.png", 1024)
    podium = save(pieces(path("12_21_20-2.png"))[0], "podium.png", 1024)
    # 12_22_35: a faixa antiga com "VOCÊ" (não usada), a moldura do avatar e a seta.
    _, ring, arrow = pieces(path("12_22_35.png"))
    save(ring, "avatar_ring.png", 256)
    save(arrow, "arrow.png", 256)
    names = ["tab_points", "tab_xp", "tab_days", "tab_players", "tab_creatures"]
    for piece, name in zip(pieces(path("12_17_24-9.png")), names):
        save(piece, name + ".png", 256)
    for place, (x, top, plaque) in sorted(podium_spots(podium).items()):
        print(f"podium {place}: x={x} top={top} plaqueY={plaque}")


if __name__ == "__main__":
    main(sys.argv[1])
