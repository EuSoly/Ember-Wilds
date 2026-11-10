"""Prepara as bordas de sofrimento e o ícone da arma presa (arte do Elizeu,
pasta "Hud do jogo"). Bordas novas de 10/11 na subpasta "Indicadores de dano"
(dano, gelo, fogo, terra rachada da fome, água do fôlego); a sede e o ícone
continuam os de 09/11 (arquivos das 14:55).

Bordas: tela inteira com o meio transparente, reduzidas para 1024x576 (o
Roblox reduz tudo para no máximo 1024 de qualquer jeito). Ícone: 256.

Uso (precisa do Pillow):
    python assets/ui/hud/prepare_fx.py "C:/Users/Elize/Downloads/UI Assets/Hud do jogo"
"""

import os
import sys

from PIL import Image

OUT = os.path.dirname(os.path.abspath(__file__))
OLD = "Imagem do ChatGPT 9 de nov. de 2026, "
NEW = os.path.join("Indicadores de dano", "ChatGPT Image Nov 10, 2026, ")

# arquivo (relativo à pasta "Hud do jogo") -> (nome, tamanho final)
PIECES = {
    NEW + "10_28_49 AM-5.png": ("fx_damage", (1024, 576)),  # bordas vermelhas
    NEW + "10_28_47 AM-1.png": ("fx_cold", (1024, 576)),  # neve e cristais de gelo
    NEW + "10_28_47 AM-2.png": ("fx_heat", (1024, 576)),  # fogo
    NEW + "10_28_48 AM-3.png": ("fx_hunger", (1024, 576)),  # terra rachada
    OLD + "14_55_13-5.png": ("fx_thirst", (1024, 576)),  # gotas nos cantos
    NEW + "10_28_48 AM-4.png": ("fx_oxygen", (1024, 576)),  # água e bolhas
    OLD + "14_55_14-7.png": ("icon_weapon_lock", (256, 256)),  # espada, machado e picareta
}


def main(source):
    for file, (name, size) in PIECES.items():
        image = Image.open(os.path.join(source, file)).convert("RGBA")
        image = image.resize(size, Image.LANCZOS)
        image.save(os.path.join(OUT, name + ".png"))
        print(f"{name}.png: {size[0]}x{size[1]}")


if __name__ == "__main__":
    main(sys.argv[1])
