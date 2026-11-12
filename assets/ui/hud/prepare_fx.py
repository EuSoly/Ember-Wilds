"""Prepara as bordas de sofrimento e o ícone da arma presa (arte do Elizeu,
pasta "Hud do jogo"). Bordas na subpasta "Indicadores de dano", com os nomes
que o Elizeu deu em 11/11 (dano, frio, calor, sede, respiração); a fome usa a
mesma imagem da sede (HudImages.FX). O ícone continua o de 09/11.

Bordas: tela inteira com o meio transparente, reduzidas para 1024x576 (o
Roblox reduz tudo para no máximo 1024 de qualquer jeito). Ícone: 256.

Uso (precisa do Pillow):
    python assets/ui/hud/prepare_fx.py "C:/Users/Elize/Downloads/UI Assets/Hud do jogo"
"""

import os
import sys

from PIL import Image

OUT = os.path.dirname(os.path.abspath(__file__))
FX = "Indicadores de dano"

# arquivo (relativo à pasta "Hud do jogo") -> (nome, tamanho final)
PIECES = {
    os.path.join(FX, "dano.png"): ("fx_damage", (1024, 576)),  # bordas vermelhas
    os.path.join(FX, "frio.png"): ("fx_cold", (1024, 576)),  # neve e cristais de gelo
    os.path.join(FX, "calor.png"): ("fx_heat", (1024, 576)),  # fogo
    os.path.join(FX, "sede.png"): ("fx_thirst", (1024, 576)),  # terra rachada
    os.path.join(FX, "respiração.png"): ("fx_oxygen", (1024, 576)),  # água e bolhas
    "Imagem do ChatGPT 9 de nov. de 2026, 14_55_14-7.png": ("icon_weapon_lock", (256, 256)),
}


def main(source):
    for file, (name, size) in PIECES.items():
        image = Image.open(os.path.join(source, file)).convert("RGBA")
        image = image.resize(size, Image.LANCZOS)
        image.save(os.path.join(OUT, name + ".png"))
        print(f"{name}.png: {size[0]}x{size[1]}")


if __name__ == "__main__":
    main(sys.argv[1])
