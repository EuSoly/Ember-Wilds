# Texturas das partículas das mochilas (BagFx): brancas sobre transparente, para o
# ParticleEmitter tingir com a cor de cada mochila. Rodar na raiz do projeto:
#   python assets/skins/vfx/gerar_texturas.py
# Saída: assets/skins/vfx/<nome>.png (128 × 128). Ids enviados em src/shared/BagFxConfig.luau.
import math, os
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

S = 128
HERE = os.path.dirname(os.path.abspath(__file__))
SS = 4  # supersampling para bordas lisas


def salvar(img, nome):
    img = img.resize((S, S), Image.LANCZOS)
    img.save(os.path.join(HERE, nome + ".png"))
    print(nome)


def tela():
    return Image.new("RGBA", (S * SS, S * SS), (255, 255, 255, 0))


def bolha():
    # anel de sabão: borda forte, miolo quase transparente e um reflexo em cima à esquerda
    img = tela(); d = ImageDraw.Draw(img); c = S * SS / 2; r = c * 0.86
    d.ellipse([c - r, c - r, c + r, c + r], fill=(255, 255, 255, 40), outline=(255, 255, 255, 235), width=int(S * SS * 0.07))
    hr = r * 0.26; hx, hy = c - r * 0.42, c - r * 0.42
    d.ellipse([hx - hr, hy - hr * 0.7, hx + hr, hy + hr * 0.7], fill=(255, 255, 255, 230))
    return img


def floco():
    # floco de 6 braços com dois pares de galhinhos em cada
    img = tela(); d = ImageDraw.Draw(img); c = S * SS / 2; R = c * 0.9; w = int(S * SS * 0.05)
    for k in range(6):
        a = math.radians(90 + 60 * k); ux, uy = math.cos(a), -math.sin(a)
        d.line([c, c, c + ux * R, c + uy * R], fill=(255, 255, 255, 255), width=w)
        for f, L in ((0.45, 0.32), (0.72, 0.22)):
            bx, by = c + ux * R * f, c + uy * R * f
            for s in (-1, 1):
                b = a + s * math.radians(50)
                d.line([bx, by, bx + math.cos(b) * R * L, by - math.sin(b) * R * L], fill=(255, 255, 255, 255), width=int(w * 0.8))
    d.ellipse([c - w * 1.4, c - w * 1.4, c + w * 1.4, c + w * 1.4], fill=(255, 255, 255, 255))
    return img


def brilho():
    # ponto de luz macio (vaga-lume, névoa): queda gaussiana até a borda
    y, x = np.mgrid[0:S * SS, 0:S * SS]; c = S * SS / 2
    r = np.hypot(x - c, y - c) / c
    a = np.clip(np.exp(-(r / 0.42) ** 2) * 1.15 - 0.03, 0, 1)
    arr = np.zeros((S * SS, S * SS, 4), np.uint8); arr[..., :3] = 255; arr[..., 3] = (a * 255).astype(np.uint8)
    return Image.fromarray(arr, "RGBA")


def estrela():
    # brilho de quatro pontas (faísca mística), com um núcleo macio
    img = brilho().filter(ImageFilter.GaussianBlur(0))
    arr = np.array(img).astype(float); arr[..., 3] *= 0.55
    y, x = np.mgrid[0:S * SS, 0:S * SS]; c = S * SS / 2
    dx, dy = np.abs(x - c) / c, np.abs(y - c) / c
    raio = np.clip(1 - (dx * 7 + dy) , 0, 1) ** 1.5 + np.clip(1 - (dy * 7 + dx), 0, 1) ** 1.5
    arr[..., 3] = np.clip(arr[..., 3] + raio * 255, 0, 255)
    return Image.fromarray(arr.astype(np.uint8), "RGBA")


def folha():
    # folhinha em gota com nervura (transparente) no meio
    img = tela(); d = ImageDraw.Draw(img); c = S * SS / 2; L = c * 0.72; W = c * 0.36
    pts = []
    for i in range(41):
        t = i / 40; y = -L + 2 * L * t; w = W * math.sin(math.pi * t) ** 0.8
        pts.append((c + w, c + y))
    for i in range(40, -1, -1):
        t = i / 40; y = -L + 2 * L * t; w = W * math.sin(math.pi * t) ** 0.8
        pts.append((c - w, c + y))
    d.polygon(pts, fill=(255, 255, 255, 255))
    d.line([c, c - L * 0.75, c, c + L * 0.9], fill=(255, 255, 255, 110), width=int(S * SS * 0.03))
    return img.rotate(35, resample=Image.BICUBIC)


for nome, fn in (("bolha", bolha), ("floco", floco), ("brilho", brilho), ("estrela", estrela), ("folha", folha)):
    salvar(fn(), "vfx_" + nome)
