# Lote 5 de MOCHILAS (10 temas finais). Base em mochila_lib.py (com boneco fantasma PREVIEW_*).
# cofre_metal, camuflada, bolsa_cristal, rocha_magma, malhada, chamas_fogo, melancia, noite_estrelada, cubos_esmeralda, carapaca_joias.
from mochila_lib import *

TIPO = "mochila"


# ---------------------------------------------------------------- ajudantes do lote
def _chaikin(poly, passes=2):
    for _ in range(passes):
        poly = [
            p for a, b in zip(poly, poly[1:] + poly[:1])
            for p in ((0.75*a[0] + 0.25*b[0], 0.75*a[1] + 0.25*b[1]),
                      (0.25*a[0] + 0.75*b[0], 0.25*a[1] + 0.75*b[1]))
        ]
    return poly


def _rect(cx, cy, w, h):
    hw, hh = w * 0.5, h * 0.5
    return [(cx - hw, cy - hh), (cx + hw, cy - hh), (cx + hw, cy + hh), (cx - hw, cy + hh)]


def _barra_rot(cx, cy, w, h, ang_deg):
    a = math.radians(ang_deg)
    ca, sa = math.cos(a), math.sin(a)
    hw, hh = w * 0.5, h * 0.5
    pts = [(-hw, -hh), (hw, -hh), (hw, hh), (-hw, hh)]
    return [(cx + x * ca - y * sa, cy + x * sa + y * ca) for x, y in pts]


def _estrela5(cx, cy, r_ext, r_int, rot_deg=0):
    pts = []
    a0 = math.radians(rot_deg - 90)
    for i in range(10):
        ang = a0 + i * math.pi / 5.0
        r = r_ext if i % 2 == 0 else r_int
        pts.append((cx + math.cos(ang) * r, cy + math.sin(ang) * r))
    return pts


# ---------------------------------------------------------------- 1. Cofre / Placa de Metal (ref. 12)
def cofre_metal(m):
    # Engrenagem lateral esquerda (+X) (#7C8490, contorno #445868)
    eng_pts = [
        (1.05, -0.32), (1.28, -0.32), (1.32, -0.18), (1.45, -0.22),
        (1.52, -0.05), (1.38, 0.05), (1.42, 0.22), (1.22, 0.28), (1.02, 0.08),
    ]
    m.flat(_chaikin(eng_pts, 1), Z0 + 0.15, MH - 0.16, "#7C8490", outline="#445868", ow=0.07, smooth=False)

    # Alça trapezoidal superior (-Y) (#7C8490, contorno #445868) com fresta verde neon (#38B44C)
    alca_sup = [(-0.48, -0.28), (0.68, -0.28), (0.48, -0.68), (-0.48, -0.68)]
    m.flat(alca_sup, Z0 + 0.15, MH - 0.16, "#7C8490", outline="#445868", ow=0.08, smooth=False)
    m.flat(_rect(0.05, -0.36, 0.72, 0.12), TOPO - 0.005, 0.012, "#38B44C", smooth=False, emit=0.35)
    m.flat(_rect(-0.68, -0.36, 0.26, 0.24), Z0 + 0.15, MH - 0.16, "#7C8490", outline="#445868", ow=0.06, smooth=False)

    # Corpo blindado assimétrico de aço (#7C8490, contorno #445868)
    corpo_aco = [
        (-1.35, 0.55), (-1.12, 0.65), (0.98, 0.65), (1.28, 0.48),
        (1.38, 0.22), (0.78, -0.32), (-1.35, -0.32),
    ]
    m.flat(corpo_aco, Z0, MH, "#7C8490", outline="#445868", ow=0.10, smooth=False)

    # Divisórias de placas soldadas e rebites (#445868)
    m.flat(_rect(-0.82, -0.05, 0.92, 0.36), TOPO + 0.006, 0.010, "#88909C", outline="#445868", ow=0.05, smooth=False)
    m.flat(_rect(-0.55, 0.36, 1.48, 0.42), TOPO + 0.006, 0.010, "#848C98", outline="#445868", ow=0.05, smooth=False)
    for rx, ry in [(-0.22, -0.02), (0.05, 0.24)]:
        m.flat(ellipse(rx, ry, 0.055, 0.055, 10), TOPO + 0.018, 0.010, "#445868", smooth=False)

    # Botão indicador circular verde brilhante (#38B44C, aro #445868) na esquerda (+X)
    m.flat(ellipse(0.76, 0.30, 0.18, 0.18, 16), TOPO + 0.018, 0.020, "#38B44C", outline="#445868", ow=0.06, smooth=False, emit=0.35)


# ---------------------------------------------------------------- 2. Mochila Camuflada (ref. 13)
def camuflada(m):
    # Topo arredondado (#788450, contorno #3C4C2C) e corpo camuflado
    m.flat(_chaikin(_rect(0.0, -0.45, 1.62, 0.54), 2), Z0, MH - 0.02, "#788450", outline="#3C4C2C", ow=0.10, smooth=False)
    m.flat(_chaikin(_rect(0.0, 0.16, 2.54, 1.02), 2), Z0, MH, "#788450", outline="#3C4C2C", ow=0.10, smooth=False)

    # Manchas orgânicas de camuflagem (#54643C verde-musgo e #C8C480 cáqui-claro)
    manchas_esc = [
        [(0.45, -0.22), (0.88, -0.18), (0.98, 0.25), (0.55, 0.35)],
        [(-0.05, 0.15), (-0.48, 0.08), (-0.52, 0.55), (0.12, 0.58)],
        [(-0.85, -0.15), (-1.22, -0.12), (-1.22, 0.38), (-0.88, 0.28)],
        [(0.18, -0.58), (-0.25, -0.58), (-0.15, -0.32), (0.25, -0.35)],
    ]
    for pts in manchas_esc:
        m.flat(_chaikin(pts, 2), TOPO + 0.006, 0.010, "#54643C", smooth=False)

    manchas_claras = [
        [(-0.18, -0.58), (-0.65, -0.55), (-0.52, -0.32), (-0.12, -0.35)],
        [(0.05, 0.32), (0.38, 0.28), (0.32, 0.58), (-0.08, 0.55)],
        [(-0.35, -0.18), (-0.15, -0.18), (-0.12, 0.12), (-0.32, 0.05)],
        [(-0.92, 0.35), (-1.18, 0.28), (-1.15, 0.55), (-0.82, 0.55)],
    ]
    for pts in manchas_claras:
        m.flat(_chaikin(pts, 2), TOPO + 0.017, 0.010, "#C8C480", smooth=False)

    # Friso horizontal cáqui (#C8C480) e 2 alças verticais camufladas (#848C58, contorno #3C4C2C)
    m.flat(_rect(0.0, -0.26, 1.38, 0.10), TOPO + 0.028, 0.010, "#C8C480", smooth=False)
    for sx in (-1, 1):
        m.flat(_chaikin(_rect(sx * 0.74, 0.14, 0.28, 1.14), 2),
               TOPO + 0.032, 0.022, "#848C58", outline="#3C4C2C", ow=0.08, smooth=False)


# ---------------------------------------------------------------- 3. Bolsa com Grande Cristal / Gema (ref. 19)
def bolsa_cristal(m):
    m.base_aberta()

    # Grande cristal lapidado ciano (#34C8D0, facetas claras #74ECEC, contorno #0C949C) saindo da bolsa
    cristal_esq = _chaikin([
        (0.95, 0.02), (0.92, -0.52), (0.55, -0.82),
        (0.05, -0.62), (0.12, 0.08),
    ], 1)
    m.flat(cristal_esq, Z0 + 0.25, MH - 0.19, "#34C8D0", outline="#0C949C", ow=0.08, smooth=False)
    m.flat(_chaikin([(0.65, -0.45), (0.42, -0.58), (0.25, -0.25), (0.55, -0.15)], 1),
           TOPO + 0.066, 0.010, "#74ECEC", smooth=False)

    cristal_dir = _chaikin([
        (0.38, 0.08), (0.42, -0.45), (0.05, -0.92), (-0.52, -0.95),
        (-0.88, -0.45), (-0.98, -0.12), (-0.45, 0.15),
    ], 1)
    m.flat(cristal_dir, Z0 + 0.27, MH - 0.17, "#34C8D0", outline="#0C949C", ow=0.08, smooth=False)
    m.flat(_chaikin([(-0.05, -0.55), (-0.42, -0.58), (-0.52, -0.22), (-0.08, -0.15)], 1),
           TOPO + 0.106, 0.010, "#74ECEC", smooth=False)

    # Alça diagonal de couro (#804C28, contorno #543014) passando por cima do cristal com fivela de metal (#909490)
    alca_diag = _chaikin([
        (0.55, -0.82), (0.12, -1.08), (-0.28, -0.78),
        (-0.58, -0.25), (-0.65, 0.22), (-0.38, 0.22),
        (-0.32, -0.22), (-0.02, -0.68), (0.28, -0.88),
    ], 2)
    m.flat(alca_diag, TOPO + 0.118, 0.022, "#804C28", outline="#543014", ow=0.05, smooth=False)
    fivela = _chaikin(_barra_rot(-0.42, -0.45, 0.38, 0.42, -25), 1)
    m.flat(fivela, TOPO + 0.142, 0.018, "#909490", smooth=False)
    m.flat(_barra_rot(-0.42, -0.45, 0.20, 0.24, -25), TOPO + 0.161, 0.010, "#543014", smooth=False)

    # Re-sobrepõe a borda frontal da bolsa de couro
    bolso_frente = _chaikin([
        (-1.12, -0.22), (-0.98, 0.22), (-0.55, 0.54),
        (0.0, 0.62), (0.55, 0.54), (0.98, 0.22), (1.12, -0.22),
        (0.65, -0.02), (0.0, 0.08), (-0.65, -0.02),
    ], 2)
    m.flat(bolso_frente, TOPO + 0.145, 0.022, "#804C28", outline="#543014", ow=0.05, smooth=False)


# ---------------------------------------------------------------- 4. Rocha de Magma (ref. 48)
def rocha_magma(m):
    # Topo chanfrado de basalto escuro (-Y) (#402C1C, miolo #503824, contorno #2C1C10)
    topo_bas = [(-0.85, -0.25), (0.85, -0.25), (0.62, -0.72), (0.0, -0.82), (-0.62, -0.72)]
    m.flat(topo_bas, Z0, MH - 0.02, "#402C1C", outline="#2C1C10", ow=0.10, smooth=False)
    m.flat([(-0.55, -0.45), (0.55, -0.45), (0.45, -0.64), (0.0, -0.72), (-0.45, -0.64)],
           TOPO - 0.012, 0.010, "#503824", smooth=False)

    # Fundo incandescente de magma (#FC6800, centro amarelo #FCB800 com emit)
    corpo_magma = _chaikin(_rect(0.0, 0.18, 2.52, 0.96), 2)
    m.flat(corpo_magma, Z0, MH, "#FC6800", outline="#2C1C10", ow=0.10, smooth=False, emit=0.35)
    m.flat(_barra_rot(0.18, 0.08, 0.22, 0.95, 28), TOPO + 0.006, 0.008, "#FCB800", smooth=False, emit=0.50)

    # Placas de rocha vulcânica rachadas (#4C3420, contorno #2C1C10) deixando fendas de magma visíveis
    placa_dir = [(-0.08, 0.62), (-0.75, 0.62), (-0.75, -0.24), (0.02, -0.24), (0.22, 0.15)]
    placa_esq_c = [(0.15, -0.24), (0.72, -0.24), (0.72, 0.12), (0.35, 0.12)]
    placa_esq_b = [(0.25, 0.26), (0.72, 0.26), (0.72, 0.62), (0.12, 0.62)]
    placa_lat_e = [(0.88, -0.18), (1.24, -0.12), (1.26, 0.32), (0.88, 0.52)]
    placa_lat_d = [(-0.88, -0.18), (-1.24, -0.12), (-1.26, 0.42), (-0.88, 0.15)]
    for pl in (placa_dir, placa_esq_c, placa_esq_b, placa_lat_e, placa_lat_d):
        m.flat(_chaikin(pl, 1), TOPO + 0.016, 0.018, "#4C3420", outline="#2C1C10", ow=0.06, smooth=False)

    # 2 alças verticais de rocha (#503824, contorno #2C1C10)
    for sx in (-1, 1):
        m.flat(_chaikin(_rect(sx * 0.74, 0.18, 0.28, 1.12), 2),
               TOPO + 0.040, 0.024, "#503824", outline="#2C1C10", ow=0.08, smooth=False)


# ---------------------------------------------------------------- 5. Mochila Malhada / Vaca (ref. 53)
def malhada(m):
    # Domo superior (#E8ECEC, contorno cinza #C4C4C4) e corpo branco (#F8FAFA)
    m.flat(_chaikin(_rect(0.0, -0.45, 1.62, 0.54), 2), Z0, MH - 0.02, "#E8ECEC", outline="#C4C4C4", ow=0.10, smooth=False)
    m.flat(_chaikin(_rect(0.0, 0.16, 2.54, 1.02), 2), Z0, MH, "#F8FAFA", outline="#C4C4C4", ow=0.10, smooth=False)
    m.flat(_rect(0.0, -0.14, 2.32, 0.28), TOPO + 0.006, 0.008, "#ECF0F0", smooth=False)

    # Manchas pretas orgânicas de vaca (#343434)
    manchas_vaca = [
        [(0.62, 0.62), (0.55, 0.35), (0.28, 0.22), (0.05, 0.38), (-0.18, 0.62)],
        [(-0.05, -0.02), (-0.32, -0.18), (-0.35, 0.18), (-0.15, 0.22)],
        [(-0.78, -0.22), (-1.18, -0.12), (-1.08, 0.18), (-0.78, 0.05)],
        [(1.24, -0.08), (1.05, 0.08), (1.08, 0.32), (1.24, 0.42)],
        [(0.68, -0.58), (0.32, -0.58), (0.42, -0.38), (0.68, -0.42)],
    ]
    for mv in manchas_vaca:
        m.flat(_chaikin(mv, 2), TOPO + 0.016, 0.012, "#343434", smooth=False)

    # 2 alças verticais escuras (#444444, contorno #343434)
    for sx in (-1, 1):
        m.flat(_chaikin(_rect(sx * 0.74, 0.14, 0.28, 1.14), 2),
               TOPO + 0.032, 0.024, "#444444", outline="#343434", ow=0.08, smooth=False)


# ---------------------------------------------------------------- 6. Mochila de Chamas / Fogo (ref. 55)
def chamas_fogo(m):
    # Topo marrom-escuro (#3C1408, contorno #301404)
    m.flat(_chaikin(_rect(0.0, -0.42, 1.62, 0.52), 2), Z0, MH - 0.04, "#3C1408", outline="#301404", ow=0.09, smooth=False)

    # Coroa de 3 labaredas douradas/laranjas no topo (-Y) (#FCB048, contorno #BC742C)
    coroa_fogo = _chaikin([
        (0.55, -0.25), (0.62, -0.65), (0.25, -0.52), (0.0, -0.92),
        (-0.25, -0.52), (-0.62, -0.65), (-0.55, -0.25),
    ], 1)
    m.flat(coroa_fogo, Z0 + 0.22, MH - 0.22, "#FCB048", outline="#BC742C", ow=0.09, smooth=False)

    # Corpo marrom-avermelhado (#7C3C18, faixa #581C0C, contorno #301404)
    m.flat(_chaikin(_rect(0.0, 0.14, 2.52, 0.98), 2), Z0, MH, "#7C3C18", outline="#301404", ow=0.10, smooth=False)
    m.flat(_rect(0.0, -0.14, 2.25, 0.28), TOPO + 0.006, 0.010, "#581C0C", smooth=False)

    # 2 alças verticais de fogo (#FCB048, contorno #BC742C) terminando em labaredas triplas (+Y)
    alca_fogo = _chaikin([
        (0.56, -0.35), (0.92, -0.35), (0.92, 0.18), (1.18, 0.15), (1.08, 0.55),
        (0.74, 0.82), (0.40, 0.55), (0.30, 0.15), (0.56, 0.18),
    ], 1)
    m.sym(alca_fogo, TOPO + 0.018, 0.026, "#FCB048", outline="#BC742C", ow=0.08, smooth=False)


# ---------------------------------------------------------------- 7. Mochila de Melancia (ref. 57)
def melancia(m):
    # Domo superior (#348434, contorno #1C4418) e corpo verde de melancia (#348434)
    m.flat(_chaikin(_rect(0.0, -0.45, 1.62, 0.54), 2), Z0, MH - 0.02, "#348434", outline="#1C4418", ow=0.10, smooth=False)
    m.flat(_chaikin(_rect(0.0, 0.16, 2.54, 1.02), 2), Z0, MH, "#348434", outline="#1C4418", ow=0.10, smooth=False)

    # Listras zigue-zague verde-escuras (#1C4418) da casca de melancia no corpo e no topo
    for lx, lw, ang_l in [(0.42, 0.26, 6), (-0.05, 0.30, -4), (-0.48, 0.24, 5), (1.08, 0.22, -25), (-1.08, 0.22, 25)]:
        m.flat(_chaikin(_barra_rot(lx, 0.16, lw, 0.96, ang_l), 1), TOPO + 0.006, 0.012, "#1C4418", smooth=False)
    for tx in (0.48, 0.15, -0.15, -0.48):
        m.flat(_rect(tx, -0.48, 0.14, 0.36), TOPO - 0.012, 0.010, "#1C4418", smooth=False)

    # 2 alças verticais verde-escuras (#18581C, contorno #1C4418)
    for sx in (-1, 1):
        m.flat(_chaikin(_rect(sx * 0.74, 0.14, 0.28, 1.14), 2),
               TOPO + 0.022, 0.024, "#18581C", outline="#1C4418", ow=0.08, smooth=False)


# ---------------------------------------------------------------- 8. Noite Estrelada / Cosmos (ref. 61)
def noite_estrelada(m):
    # Domo superior e corpo roxo-noturno profundo (#342444, contorno #2C1404)
    m.flat(_chaikin(_rect(0.0, -0.45, 1.62, 0.54), 2), Z0, MH - 0.02, "#342444", outline="#2C1404", ow=0.10, smooth=False)
    m.flat(_chaikin(_rect(0.0, 0.16, 2.54, 1.02), 2), Z0, MH, "#342444", outline="#2C1404", ow=0.10, smooth=False)

    # Nuvens/nebulosas laranja-douradas (#FC7C00 e #E05C14) na esquerda (+X) e na base direita (-X)
    for cx, cy, rx, ry, cor_n in [
        (0.95, 0.05, 0.38, 0.32, "#FC7C00"),
        (0.75, 0.12, 0.32, 0.28, "#E05C14"),
        (-0.35, 0.45, 0.36, 0.25, "#FC7C00"),
        (-0.68, 0.38, 0.32, 0.28, "#FC7C00"),
        (-0.98, 0.48, 0.28, 0.22, "#E05C14"),
    ]:
        m.flat(ellipse(cx, cy, rx, ry, 16), TOPO + 0.006, 0.012, cor_n, smooth=False)

    # Estrelinhas laranja-douradas (#FC7C00) espalhadas pelo céu noturno
    for ex, ey, er in [(0.18, 0.12, 0.13), (-0.02, 0.22, 0.08), (-0.42, -0.15, 0.11), (-0.22, -0.18, 0.07), (0.52, -0.38, 0.08)]:
        m.flat(_estrela5(ex, ey, er, er * 0.45, 12), TOPO + 0.018, 0.012, "#FC7C00", smooth=False)

    # 2 alças verticais roxo-escuras (#342444, contorno #2C1404)
    for sx in (-1, 1):
        m.flat(_chaikin(_rect(sx * 0.74, 0.14, 0.28, 1.14), 2),
               TOPO + 0.032, 0.024, "#342444", outline="#2C1404", ow=0.08, smooth=False)


# ---------------------------------------------------------------- 9. Cubos de Esmeralda (ref. 68)
def cubos_esmeralda(m):
    # Hastes de madeira escura (#442410, miolo #583014) conectando os 3 blocos de esmeralda
    m.flat(_rect(0.42, 0.15, 0.38, 0.55), Z0 + 0.15, MH - 0.20, "#583014", outline="#442410", ow=0.05, smooth=False)
    m.flat(_rect(0.05, 0.45, 0.55, 0.32), Z0 + 0.15, MH - 0.20, "#583014", outline="#442410", ow=0.05, smooth=False)

    # 1. Grande cubo de esmeralda superior esquerdo (+X, -Y) (#046840, brilho #1C7C44, contorno #1C7C44)
    m.flat(_chaikin(_rect(0.32, -0.42, 1.38, 0.98), 2), Z0 + 0.20, MH - 0.16,
           "#046840", outline="#1C7C44", ow=0.09, smooth=False)
    m.flat(_chaikin(_rect(0.40, -0.45, 0.88, 0.62), 2), TOPO + 0.046, 0.012, "#1C7C44", smooth=False)

    # 2. Cubo médio de esmeralda inferior direito (-X, +Y) (#045C38, brilho #086C3C, contorno #0C643C)
    m.flat(_chaikin(_rect(-0.72, 0.28, 1.15, 0.72), 2), Z0, MH + 0.02,
           "#045C38", outline="#0C643C", ow=0.08, smooth=False)
    m.flat(_chaikin(_rect(-0.65, 0.28, 0.62, 0.38), 2), TOPO + 0.026, 0.010, "#086C3C", smooth=False)

    # 3. Bloco achatado de esmeralda inferior esquerdo (+X, +Y) (#045434, contorno #0C643C)
    m.flat(_chaikin(_rect(0.72, 0.45, 1.18, 0.44), 2), Z0, MH + 0.04,
           "#045434", outline="#0C643C", ow=0.08, smooth=False)


# ---------------------------------------------------------------- 10. Carapaça com Joias (ref. 71)
def carapaca_joias(m):
    # Gomos superiores da carapaça verde-esmeralda (#047848, divisórias #045438)
    gomos_sup = [
        (-1.18, 0.12), (-0.92, -0.42), (-0.42, -0.62), (0.0, -0.52),
        (0.42, -0.62), (0.92, -0.42), (1.18, 0.12),
    ]
    m.flat(_chaikin(gomos_sup, 2), Z0, MH - 0.02, "#047848", outline="#045438", ow=0.10, smooth=False)
    for gx, ang_g in [(0.65, 22), (0.28, 12), (-0.28, -12), (-0.65, -22)]:
        m.flat(_barra_rot(gx, -0.28, 0.11, 0.68, ang_g), TOPO - 0.012, 0.012, "#045438", smooth=False)

    # Coroa frontal pontuda verde-esmeralda (#047848, contorno #045438)
    coroa_frente = _chaikin([
        (-1.05, 0.58), (1.05, 0.58), (1.32, 0.08),
        (0.92, 0.12), (0.72, -0.15), (0.38, 0.02),
        (0.0, -0.28), (-0.38, 0.02), (-0.72, -0.15),
        (-0.92, 0.12), (-1.32, 0.08),
    ], 1)
    m.flat(coroa_frente, Z0, MH + 0.02, "#047848", outline="#045438", ow=0.10, smooth=False)

    # 5 joias vermelhas rubi (#AC1C24 com brilho rosa-claro #DC5458) engastadas na coroa
    for jx, jy, jr in [
        (0.96,  0.30, 0.14),
        (0.52,  0.22, 0.18),
        (0.0,   0.16, 0.22),
        (-0.52, 0.22, 0.18),
        (-0.96, 0.30, 0.14),
    ]:
        m.flat(ellipse(jx, jy, jr, jr, 16), TOPO + 0.026, 0.020, "#AC1C24", smooth=False)
        m.flat(ellipse(jx, jy - jr * 0.28, jr * 0.42, jr * 0.42, 12), TOPO + 0.048, 0.010, "#DC5458", smooth=False)


LOTE = [
    ("cofre_metal", cofre_metal, "#7C8490", "#445868"),
    ("camuflada", camuflada, "#788450", "#3C4C2C"),
    ("bolsa_cristal", bolsa_cristal, "#804C28", "#543014"),
    ("rocha_magma", rocha_magma, "#4C3420", "#2C1C10"),
    ("malhada", malhada, "#F8FAFA", "#C4C4C4"),
    ("chamas_fogo", chamas_fogo, "#7C3C18", "#301404"),
    ("melancia", melancia, "#348434", "#1C4418"),
    ("noite_estrelada", noite_estrelada, "#342444", "#2C1404"),
    ("cubos_esmeralda", cubos_esmeralda, "#046840", "#1C7C44"),
    ("carapaca_joias", carapaca_joias, "#047848", "#045438"),
]
