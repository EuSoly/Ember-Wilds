# Lote 14 — 20 skins de corpo básicas (10 cores/tons comuns + 10 estampas/texturas planas incomuns).
# Silhueta 100% padrão do BonecoConfig (sem apêndices saindo do corpo) + mãos redondas, para raridades iniciais.
from skin_lib import *


def _chaikin(poly, passes=2):
    for _ in range(passes):
        poly = [
            p for a, b in zip(poly, poly[1:] + poly[:1])
            for p in ((0.75 * a[0] + 0.25 * b[0], 0.75 * a[1] + 0.25 * b[1]),
                      (0.25 * a[0] + 0.75 * b[0], 0.25 * a[1] + 0.75 * b[1]))
        ]
    return poly


def _skin_cor_basica(s, sombra, brilho):
    """Acabamento limpo de skin básica de cor: sombreado suave nas bordas laterais/traseira e brilho discreto."""
    s.base()
    # Sombra suave nas laterais do topo (dentro do chanfro 1.60)
    faixa_lat = _chaikin([
        (1.22, 1.25), (1.56, 1.05), (1.58, -1.05), (1.15, -1.48),
        (1.02, -1.18), (1.30, 0.0), (1.12, 1.02)
    ], 2)
    s.sym(faixa_lat, TOP, 0.012, sombra, smooth=False)
    # Brilho oval discreto nos dois cantos frontais/superiores
    s.sym(ellipse(1.15, 1.18, 0.22, 0.12, n=12, rot=-0.45), TOP + 0.014, 0.012, brilho)
    # Brilho discreto na mão redonda
    s.hand_flat(ellipse(-0.14, 0.14, 0.18, 0.12, n=10, rot=0.4), 1.83, 0.02, brilho)


# ================================================================
# PARTE 1: 10 SKINS BÁSICAS DE COR / TOM (COMUNS)
# ================================================================
def basico_ardosia(s):
    _skin_cor_basica(s, "#607C88", "#B4C8CC")


def basico_areia(s):
    _skin_cor_basica(s, "#B09480", "#DECBB4")


def basico_bronze(s):
    _skin_cor_basica(s, "#844C2C", "#B47C4C")


def basico_laranja(s):
    _skin_cor_basica(s, "#C83C18", "#F88068")


def basico_ciano(s):
    _skin_cor_basica(s, "#0090A8", "#58E4F4")


def basico_vermelho(s):
    _skin_cor_basica(s, "#A81800", "#F05030")


def basico_roxo(s):
    _skin_cor_basica(s, "#601C8C", "#A054D4")


def basico_dourado(s):
    _skin_cor_basica(s, "#C8A000", "#F4E06C")


def basico_menta(s):
    _skin_cor_basica(s, "#18A86C", "#68E8B4")


def basico_musgo(s):
    _skin_cor_basica(s, "#446C30", "#74A854")


# ================================================================
# PARTE 2: 10 SKINS BÁSICAS DE TEXTURA / ESTAMPA PLANA (INCOMUNS)
# ================================================================
def estampa_camuflado(s):
    # Camuflado militar (ref. 24): manchas orgânicas planas no topo e na mão
    s.base()
    claro, escuro, bege = "#848C58", "#405030", "#D4CC84"
    manchas = [
        ([(-1.55, 1.35), (-0.85, 1.55), (-0.55, 1.18), (-1.15, 0.85), (-1.58, 0.92)], claro),
        ([(0.75, 1.55), (1.48, 1.38), (1.58, 0.72), (1.12, 0.55), (0.68, 1.12)], escuro),
        ([(-1.58, 0.35), (-1.12, 0.45), (-0.95, -0.35), (-1.35, -0.78), (-1.58, -0.45)], escuro),
        ([(1.12, 0.15), (1.58, 0.25), (1.55, -0.68), (0.95, -0.82), (0.85, -0.25)], claro),
        ([(-1.45, -0.95), (-0.65, -0.75), (-0.35, -1.35), (-0.98, -1.58), (-1.52, -1.38)], bege),
        ([(0.25, -0.72), (0.95, -0.95), (1.35, -1.45), (0.55, -1.58), (-0.05, -1.25)], escuro),
        ([(-0.45, 1.55), (0.35, 1.58), (0.22, 1.05), (-0.35, 1.08)], bege),
        ([(1.05, -1.05), (1.55, -0.88), (1.48, -1.42), (1.02, -1.48)], bege),
    ]
    for pts, col in manchas:
        s.flat(_chaikin(pts, 2), TOP, 0.015, col, smooth=False)
    s.hand_flat(ellipse(-0.12, 0.08, 0.26, 0.16, n=10, rot=0.4), 1.83, 0.02, claro)
    s.hand_flat(ellipse(0.15, -0.10, 0.20, 0.14, n=10, rot=-0.3), 1.84, 0.02, escuro)


def estampa_madeira(s):
    # Tábua de madeira (ref. 84): veios longitudinais e nós de madeira planos no topo
    s.base()
    veio, claro = "#703C18", "#A46C44"
    # Tábuas/frisos verticais suaves nas laterais (|x|=1.34) e curtos na metade traseira (|x|=0.52, longe dos olhos)
    for x0 in (-1.34, 1.34):
        faixa = _chaikin([
            (x0 - 0.08, -1.48), (x0 + 0.06, -0.25), (x0 - 0.05, 1.18),
            (x0 - 0.15, 1.18), (x0 - 0.04, -0.25), (x0 - 0.16, -1.48)
        ], 2)
        s.flat(faixa, TOP, 0.014, veio, smooth=False)
    for x0 in (-0.52, 0.52):
        faixa_t = _chaikin([
            (x0 - 0.06, -1.52), (x0 + 0.05, -0.85), (x0 - 0.04, -0.25),
            (x0 - 0.13, -0.25), (x0 - 0.04, -0.85), (x0 - 0.14, -1.52)
        ], 2)
        s.flat(faixa_t, TOP, 0.014, veio, smooth=False)
    # Nós circulares de madeira nos cantos traseiros
    for kx, ky in [(-1.05, -1.05), (1.08, -0.85)]:
        s.flat(ellipse(kx, ky, 0.32, 0.22, n=14, rot=0.25), TOP + 0.005, 0.014, claro)
        s.flat(ellipse(kx, ky, 0.18, 0.11, n=12, rot=0.25), TOP + 0.020, 0.014, veio)
    s.hand_flat(ellipse(0.0, 0.0, 0.28, 0.14, n=10, rot=0.3), 1.83, 0.02, veio)


def estampa_zebra(s):
    # Listras de zebra (ref. 89): fundo creme com listras pretas vindo das bordas
    s.base()
    listra, sombra = "#303030", "#D4CCB8"
    s.sym(_chaikin([(1.25, 1.30), (1.58, 1.10), (1.58, -1.10), (1.25, -1.35), (1.38, 0.0)], 2),
          TOP, 0.008, sombra, smooth=False)
    listras_lat = [
        [(1.58, 1.28), (1.58, 0.95), (0.98, 1.18), (1.12, 1.42)],
        [(1.58, 0.52), (1.58, 0.18), (1.15, 0.28), (1.18, 0.55)],
        [(1.58, -0.18), (1.58, -0.55), (0.85, -0.42), (0.95, -0.12)],
        [(1.58, -0.88), (1.58, -1.25), (0.68, -1.12), (0.82, -0.78)],
        [(1.18, -1.58), (0.78, -1.58), (0.35, -1.15), (0.58, -0.98)],
    ]
    for pts in listras_lat:
        s.sym(_chaikin(pts, 1), TOP + 0.010, 0.016, listra, smooth=False)
    # Listra curta em V na testa
    s.flat(_chaikin([(0.0, 1.02), (0.20, 1.56), (-0.20, 1.56)], 1), TOP + 0.010, 0.016, listra, smooth=False)
    s.hand_flat(_chaikin([(-0.32, 0.05), (0.32, 0.15), (0.28, -0.08), (-0.28, -0.15)], 1), 1.83, 0.02, listra, smooth=False)


def estampa_tigre(s):
    # Listras de tigre (ref. 95): laranja vibrante com listras pretas afiadas nas bordas e bochechas claras
    s.base()
    preto, claro = "#181008", "#FCE8C8"
    s.sym(ellipse(1.22, 1.15, 0.32, 0.24, n=12, rot=-0.3), TOP, 0.010, claro)
    listras = [
        [(1.58, 0.95), (1.58, 0.65), (1.12, 0.82)],
        [(1.58, 0.25), (1.58, -0.08), (1.08, 0.12)],
        [(1.58, -0.42), (1.58, -0.78), (0.82, -0.52)],
        [(1.55, -1.08), (1.32, -1.45), (0.65, -1.05)],
        [(0.95, -1.58), (0.55, -1.58), (0.28, -1.08)],
    ]
    for pts in listras:
        s.sym(_chaikin(pts, 1), TOP + 0.012, 0.016, preto, smooth=False)
    # Marca de tigre na testa (acima/entre os olhos)
    s.flat(_chaikin([(0.0, 0.95), (0.24, 1.56), (-0.24, 1.56)], 1), TOP + 0.012, 0.016, preto, smooth=False)
    s.hand_flat(_chaikin([(-0.30, 0.08), (0.30, 0.08), (0.0, -0.18)], 1), 1.83, 0.02, preto, smooth=False)


def estampa_melancia(s):
    # Casca de melancia verde (ref. 90): faixas onduladas verde-escuras nas laterais e costas
    s.base()
    escuro, claro = "#0C2C10", "#54AC58"
    # Faixas laterais externas (|x|=1.36, fora dos olhos) e faixa central traseira
    for k in (-1, 1):
        onda_lat = _chaikin([
            (k * 1.24, -1.42), (k * 1.38, -0.45), (k * 1.24, 0.45), (k * 1.36, 1.28),
            (k * 1.54, 1.15), (k * 1.44, 0.45), (k * 1.56, -0.45), (k * 1.44, -1.32)
        ], 2)
        s.flat(onda_lat, TOP, 0.015, escuro, smooth=False)
        onda_tras = _chaikin([
            (k * 0.45, -1.55), (k * 0.58, -0.98), (k * 0.42, -0.42),
            (k * 0.68, -0.42), (k * 0.82, -0.98), (k * 0.72, -1.55)
        ], 2)
        s.flat(onda_tras, TOP, 0.015, escuro, smooth=False)
    s.sym(ellipse(1.05, 1.18, 0.22, 0.14, n=10, rot=-0.4), TOP + 0.016, 0.012, claro)
    s.hand_flat(ellipse(0.0, 0.0, 0.30, 0.14, n=10), 1.83, 0.02, escuro)


def estampa_lua(s):
    # Superfície lunar (ref. 88): cinza-claro com crateras circulares sombreadas
    s.base()
    crat_borda, crat_fundo, brilho = "#ECECEC", "#A0A0A0", "#F8F8F8"
    crateras = [
        (-1.15, -0.95, 0.38, 0.32),
        (1.08, -1.05, 0.42, 0.35),
        (-0.25, -1.22, 0.28, 0.24),
        (1.25, 0.05, 0.26, 0.24),
        (-1.28, 0.18, 0.24, 0.22),
        (0.0, 1.28, 0.25, 0.20),
        (0.55, -0.68, 0.20, 0.18),
    ]
    for cx, cy, rx, ry in crateras:
        s.flat(ellipse(cx, cy, rx, ry, n=16), TOP, 0.012, crat_borda)
        s.flat(ellipse(cx + 0.03, cy - 0.02, rx * 0.72, ry * 0.72, n=14), TOP + 0.013, 0.012, crat_fundo)
    s.sym(ellipse(1.12, 1.18, 0.20, 0.12, n=10, rot=-0.4), TOP + 0.01, 0.01, brilho)
    s.hand_flat(ellipse(0.05, 0.05, 0.22, 0.18, n=12), 1.83, 0.02, crat_fundo)


def estampa_biscoito(s):
    # Cookie com gotas de chocolate (ref. 146): massa dourada com gotas marrons espalhadas
    s.base()
    massa_sombra, gota_esc, gota_med = "#C86810", "#381C08", "#643408"
    s.sym(_chaikin([(1.22, 1.25), (1.58, 1.05), (1.58, -1.05), (1.22, -1.35), (1.35, 0.0)], 2),
          TOP, 0.010, massa_sombra, smooth=False)
    gotas = [
        (-1.18, 1.15, 0.20, gota_esc),
        (1.15, 1.18, 0.18, gota_med),
        (0.0, 1.28, 0.19, gota_esc),
        (-1.28, 0.05, 0.22, gota_med),
        (1.28, -0.10, 0.21, gota_esc),
        (-1.05, -1.02, 0.24, gota_esc),
        (-0.28, -1.25, 0.19, gota_med),
        (0.45, -1.12, 0.22, gota_esc),
        (1.15, -1.08, 0.20, gota_med),
        (-0.68, -0.58, 0.17, gota_med),
        (0.75, -0.52, 0.18, gota_esc),
    ]
    for gx, gy, r, col in gotas:
        s.flat(ellipse(gx, gy, r, r * 0.88, n=12, rot=gx), TOP + 0.012, 0.018, col)
    s.hand_flat(ellipse(-0.10, 0.08, 0.16, 0.14, n=10), 1.83, 0.02, gota_esc)
    s.hand_flat(ellipse(0.14, -0.10, 0.14, 0.12, n=10), 1.83, 0.02, gota_med)


def estampa_noite(s):
    # Noite estrelada (ref. 109): azul-noturno com lua crescente no canto traseiro e estrelas brilhantes
    s.base()
    azul_esc, prata, branco = "#0C1830", "#B8C8DC", "#F0F8FC"
    s.sym(_chaikin([(1.20, 1.25), (1.58, 1.05), (1.58, -1.05), (1.20, -1.35), (1.35, 0.0)], 2),
          TOP, 0.010, azul_esc, smooth=False)
    # Lua crescente no canto traseiro direito
    lua = _chaikin([
        (0.55, -0.68), (1.12, -0.58), (1.38, -0.98), (1.22, -1.42),
        (0.68, -1.48), (0.95, -1.18), (0.98, -0.88)
    ], 2)
    s.flat(lua, TOP + 0.012, 0.018, branco, smooth=False)
    # Estrelinhas de 4 pontas e pontinhos prateados
    for sx, sy, r in [(-1.05, -1.05, 0.24), (-1.25, 0.05, 0.18), (0.0, 1.25, 0.20), (-0.35, -1.25, 0.16)]:
        est = [
            (sx, sy + r), (sx + r * 0.28, sy + r * 0.28),
            (sx + r, sy), (sx + r * 0.28, sy - r * 0.28),
            (sx, sy - r), (sx - r * 0.28, sy - r * 0.28),
            (sx - r, sy), (sx - r * 0.28, sy + r * 0.28),
        ]
        s.flat(est, TOP + 0.014, 0.016, branco, smooth=False)
    for px, py in [(-1.18, 1.18), (1.18, 1.15), (1.28, 0.12), (-0.65, -0.65)]:
        s.flat(ellipse(px, py, 0.09, 0.09, n=8), TOP + 0.012, 0.014, prata)
    s.hand_flat(ellipse(0.0, 0.0, 0.15, 0.15, n=8), 1.83, 0.02, branco)


def estampa_diamante(s):
    # Diamante facetado (ref. 144): facetas geométricas cristalinas no topo quadrado
    s.base()
    f_claro, f_medio, brilho = "#A0FCDC", "#58C8DC", "#FCFCFC"
    # Facetas laterais chanfradas e facetas diagonais de cristal nos cantos
    s.sym([
        (1.18, 1.32), (1.55, 1.02), (1.55, -1.02), (1.18, -1.32), (1.32, 0.0)
    ], TOP, 0.012, f_medio, smooth=False)
    # Losangos cristalinos na testa e nos dois cantos traseiros
    s.flat([(0.0, 1.52), (0.28, 1.12), (0.0, 0.72), (-0.28, 1.12)], TOP + 0.014, 0.015, f_claro, smooth=False)
    s.flat([(0.0, 1.40), (0.15, 1.12), (0.0, 0.84), (-0.15, 1.12)], TOP + 0.030, 0.015, brilho, smooth=False)
    s.sym([(0.55, -0.68), (1.18, -0.58), (1.28, -1.22), (0.62, -1.32)], TOP + 0.014, 0.015, f_claro, smooth=False)
    s.sym([(0.72, -0.82), (1.08, -0.75), (1.12, -1.12), (0.78, -1.18)], TOP + 0.030, 0.015, brilho, smooth=False)
    s.sym(ellipse(1.15, 1.15, 0.18, 0.10, n=8, rot=-0.45), TOP + 0.016, 0.015, brilho)
    s.hand_flat([(-0.22, 0.0), (0.0, 0.25), (0.22, 0.0), (0.0, -0.25)], 1.83, 0.02, brilho, smooth=False)


def estampa_ondas(s):
    # Ondas do mar (ref. 150): faixas curvas de água azul-profunda e espuma ciano-clara
    s.base()
    azul_prof, azul_med, espuma = "#106490", "#288CCC", "#80FCFC"
    for y_base, col in [(-0.55, azul_med), (-0.98, espuma), (-1.35, azul_prof)]:
        faixa = _chaikin([
            (-1.55, y_base + 0.12), (-0.85, y_base - 0.10), (0.0, y_base + 0.14),
            (0.85, y_base - 0.10), (1.55, y_base + 0.12),
            (1.55, y_base - 0.12), (0.85, y_base - 0.32), (0.0, y_base - 0.08),
            (-0.85, y_base - 0.32), (-1.55, y_base - 0.12)
        ], 2)
        s.flat(faixa, TOP + 0.010, 0.015, col, smooth=False)
    # Espuma nas laterais superiores
    s.sym(_chaikin([(1.15, 1.32), (1.55, 1.08), (1.55, 0.15), (1.20, 0.35), (1.28, 0.95)], 2),
          TOP + 0.010, 0.015, espuma, smooth=False)
    s.hand_flat(ellipse(0.0, 0.05, 0.26, 0.14, n=12), 1.83, 0.02, espuma)


LOTE = [
    # 10 básicas de cor / tom (Comuns)
    ("basico_ardosia", basico_ardosia, "#94ACB0", "#58747C", "#94ACB0", "#58747C"),
    ("basico_areia", basico_areia, "#CCB89C", "#806054", "#CCB89C", "#806054"),
    ("basico_bronze", basico_bronze, "#9C6434", "#583024", "#9C6434", "#583024"),
    ("basico_laranja", basico_laranja, "#EC583C", "#94200C", "#EC583C", "#94200C"),
    ("basico_ciano", basico_ciano, "#00BCD0", "#007890", "#00BCD0", "#007890"),
    ("basico_vermelho", basico_vermelho, "#D42400", "#94200C", "#D42400", "#94200C"),
    ("basico_roxo", basico_roxo, "#8028B0", "#4C1478", "#8028B0", "#4C1478"),
    ("basico_dourado", basico_dourado, "#ECCC00", "#B89000", "#ECCC00", "#B89000"),
    ("basico_menta", basico_menta, "#24D490", "#148858", "#24D490", "#148858"),
    ("basico_musgo", basico_musgo, "#588C3C", "#3C4830", "#588C3C", "#3C4830"),
    # 10 básicas de textura / estampa plana (Incomuns)
    ("estampa_camuflado", estampa_camuflado, "#586840", "#405030", "#586840", "#405030"),
    ("estampa_madeira", estampa_madeira, "#8C5834", "#4C3418", "#8C5834", "#4C3418"),
    ("estampa_zebra", estampa_zebra, "#ECE4CC", "#303030", "#ECE4CC", "#303030"),
    ("estampa_tigre", estampa_tigre, "#F0901C", "#242020", "#F0901C", "#242020"),
    ("estampa_melancia", estampa_melancia, "#308434", "#144014", "#308434", "#144014"),
    ("estampa_lua", estampa_lua, "#D0D0D0", "#787878", "#D0D0D0", "#787878"),
    ("estampa_biscoito", estampa_biscoito, "#EC801C", "#643408", "#EC801C", "#643408"),
    ("estampa_noite", estampa_noite, "#182840", "#04082C", "#182840", "#04082C"),
    ("estampa_diamante", estampa_diamante, "#98E4F4", "#2480A0", "#98E4F4", "#2480A0"),
    ("estampa_ondas", estampa_ondas, "#48C0E8", "#106490", "#48C0E8", "#106490"),
]
