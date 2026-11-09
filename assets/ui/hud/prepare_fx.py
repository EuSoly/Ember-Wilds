"""Prepara as bordas de sofrimento e o ícone da arma presa (arte do Elizeu,
09/11, pasta "Hud do jogo", arquivos das 14:55).

Bordas: tela inteira com o meio transparente, reduzidas para 1024x576 (o
Roblox reduz tudo para no máximo 1024 de qualquer jeito). Ícone: 256.

Uso (precisa do Pillow):
    python assets/ui/hud/prepare_fx.py "C:/Users/Elize/Downloads/UI Assets/Hud do jogo"
"""

import os
import sys

from PIL import Image

OUT = os.path.dirname(os.path.abspath(__file__))
PREFIX = "Imagem do ChatGPT 9 de nov. de 2026, "

# arquivo -> (nome, tamanho final)
PIECES = {
    "14_55_11-1.png": ("fx_damage", (1024, 576)),  # vermelho, golpe
    "14_55_11-2.png": ("fx_cold", (1024, 576)),  # gelo
    "14_55_12-3.png": ("fx_heat", (1024, 576)),  # brasas e lava
    "14_55_13-4.png": ("fx_hunger", (1024, 576)),  # terra e coxinhas
    "14_55_13-5.png": ("fx_thirst", (1024, 576)),  # gotas nos cantos
    "14_55_14-6.png": ("fx_oxygen", (1024, 576)),  # ondas e bolhas
    "14_55_14-7.png": ("icon_weapon_lock", (256, 256)),  # espada, machado e picareta
}


def main(source):
    for file, (name, size) in PIECES.items():
        image = Image.open(os.path.join(source, PREFIX + file)).convert("RGBA")
        image = image.resize(size, Image.LANCZOS)
        image.save(os.path.join(OUT, name + ".png"))
        print(f"{name}.png: {size[0]}x{size[1]}")


if __name__ == "__main__":
    main(sys.argv[1])
