# Lote 1 — skins de corpo. Montar com build_skins.py (Blender aberto) ou render_lote.py (segundo plano).
from skin_lib import *


def lobo(s):
    # ref. 113: cinza azulado. Orelhas para trás nas diagonais, juba em zigue-zague nas laterais, rabo felpudo.
    s.base()
    dark, mid, light, ink = "#5E6D75", "#7F8F94", "#8E9DA4", "#324050"
    # orelhas em pé sobre o topo, atrás dos olhos (de cima: triângulos; a 65°: orelhas)
    ear = [(0.55, -0.25), (1.6, 0.0), (1.75, -1.35)]
    s.sym(ear, TOP, 0.14, mid, outline=ink, ow=0.07, smooth=False)
    s.sym([(0.85, -0.3), (1.45, -0.18), (1.55, -0.95)], TOP + 0.14, 0.02, dark, smooth=False)
    ruff = [(1.75, 1.2), (2.25, 0.9), (1.95, 0.6), (2.45, 0.25), (2.05, -0.05), (2.35, -0.45), (1.75, -0.6)]
    s.sym(ruff, 0.9, 1.0, mid, outline=ink, smooth=False)
    tail = [(-0.45, -1.6), (-0.65, -2.4), (-0.35, -3.1), (0.05, -3.45), (0.45, -3.1), (0.65, -2.4), (0.45, -1.6)]
    s.flat(tail, 0.9, 1.0, mid, outline=ink)
    s.flat([(-0.3, -2.75), (0.0, -3.3), (0.3, -2.75), (0.0, -2.55)], 1.92, 0.04, light)
    # pelo mais escuro só na borda de trás, em dentes (nada grande atrás dos olhos: vira "boca" de cima)
    fringe = [(-1.5, -1.2), (-1.1, -1.0), (-0.75, -1.25), (-0.35, -1.0), (0.0, -1.25), (0.35, -1.0), (0.75, -1.25), (1.1, -1.0), (1.5, -1.2), (1.3, -1.72), (-1.3, -1.72)]
    s.flat(fringe, TOP, T, dark, smooth=False)
    # focinho claro com nariz
    s.flat(ellipse(0, 1.35, 0.75, 0.38), TOP, T, light)
    s.flat(ellipse(0, 1.55, 0.24, 0.15), TOP + T, 0.04, ink)
    for k in (-1, 0, 1):
        s.hand_flat([(k*0.22 - 0.07, 0.5), (k*0.22 + 0.07, 0.5), (k*0.22, 0.72)], 1.2, 0.08, ink, smooth=False)

def raposa(s):
    # ref. 82: laranja, pontas escuras, peito branco. Orelhas grandes, bochechas brancas, rabo curvo de lado.
    s.base()
    org, dark, white, ink = "#D46A35", "#9D5022", "#D6D4D3", "#262121"
    # orelhas grandes em pé sobre o topo, pontas escuras
    ear = [(0.4, -0.2), (1.7, 0.15), (1.95, -1.5)]
    s.sym(ear, TOP, 0.14, org, outline=ink, ow=0.07, smooth=False)
    s.sym([(1.68, -0.85), (1.82, -0.75), (1.95, -1.5)], TOP + 0.14, 0.02, ink, smooth=False)
    s.sym([(0.75, -0.25), (1.45, -0.05), (1.6, -0.9)], TOP + 0.14, 0.02, white, smooth=False)
    cheek = [(1.4, 1.5), (2.3, 1.2), (1.95, 0.85), (2.35, 0.45), (1.6, 0.3)]
    s.sym(cheek, 0.9, 1.0, white, outline=ink, smooth=False)
    tail = [(0.3, -1.6), (1.6, -2.3), (2.6, -2.0), (3.0, -1.0), (2.75, -0.2), (2.35, -0.9), (1.9, -1.5), (0.6, -1.3)]
    s.flat(tail, 0.85, 1.0, org, outline=ink)
    s.flat([(2.55, -1.8), (2.95, -1.1), (2.78, -0.35), (2.45, -0.95)], 1.88, 0.04, white)
    s.flat([(-0.18, -0.6), (0.18, -0.6), (0.12, -1.65), (-0.12, -1.65)], TOP, T, dark, smooth=False)
    s.flat([(-0.85, 1.65), (0.85, 1.65), (0.4, 0.95), (0.0, 1.15), (-0.4, 0.95)], TOP, T, white)
    s.flat(ellipse(0, 1.62, 0.2, 0.13), TOP + T, 0.04, ink)
    s.hand_flat(ellipse(0, 0.1, 0.6, 0.45), HZ + 0.05, 0.6, ink)

def coruja(s):
    # ref. 17: marrons e dourado. Tufos nas orelhas, asas dobradas nas laterais, penas em escama nas costas, disco no rosto.
    s.base()
    brown, dark, mid, gold, ink = "#604228", "#472F1A", "#755233", "#B28C43", "#2E1E10"
    tuft = [(1.1, 1.15), (2.3, 2.2), (1.9, 1.35), (2.45, 1.45), (1.65, 0.75)]
    s.sym(tuft, 1.0, 1.05, mid, outline=ink, smooth=False)
    wing = [(1.6, 0.6), (2.25, 0.2), (2.4, -0.7), (2.15, -1.5), (1.85, -1.25), (1.95, -1.85), (1.55, -1.6), (1.4, -2.15), (1.15, -1.7)]
    s.sym(wing, 0.9, 1.0, dark, outline=ink, smooth=False)
    s.sym([(1.85, 0.2), (2.15, -0.5), (1.95, -1.1), (1.7, -0.5)], 1.92, 0.04, mid)
    for s_ in (-1, 1):
        s.flat(ellipse(s_*EYE_X, EYE_Y, 0.72, 0.68), TOP, T, gold)
    s.flat([(-0.14, 0.95), (0.14, 0.95), (0.0, 1.45)], TOP + T, 0.05, gold, outline=ink, ow=0.05, smooth=False)
    for row, y in enumerate([-0.35, -0.8, -1.25]):
        xs = [-1.1, -0.55, 0.0, 0.55, 1.1] if row % 2 == 0 else [-0.82, -0.27, 0.27, 0.82]
        for x in xs:
            s.flat([(x - 0.24, y + 0.12), (x, y - 0.18), (x + 0.24, y + 0.12), (x, y - 0.04)], TOP, 0.03, mid, smooth=False)
    for k in (-1, 0, 1):
        s.hand_flat([(k*0.25 - 0.13, 0.35), (k*0.25 + 0.13, 0.35), (k*0.25, 0.85)], 1.1, 0.5, mid, outline=ink, ow=0.05, smooth=False)

def polvo(s):
    # ref. 21: azul-marinho, vermelho e roxo. Tentáculos espalhados saindo de trás e dos lados, com ventosas.
    s.base()
    navy, red, purple, ink = "#201552", "#B8232A", "#4B399A", "#120B33"
    def tentacle(a0, length, curl, w):
        pts_l, pts_r = [], []
        for i in range(9):
            t = i / 8; a = a0 + curl * t
            r = 1.2 + length * t
            cx, cy = math.cos(a) * r, math.sin(a) * r
            ww = w * (1 - t * 0.85)
            nx, ny = -math.sin(a), math.cos(a)
            pts_l.append((cx + nx*ww, cy + ny*ww)); pts_r.append((cx - nx*ww, cy - ny*ww))
        return pts_l + list(reversed(pts_r)), a0, length, curl
    specs = [(math.radians(-60), 2.2, 0.9), (math.radians(-90), 2.5, -0.8), (math.radians(-120), 2.2, -0.9),
             (math.radians(-20), 1.9, 1.0), (math.radians(-160), 1.9, -1.0), (math.radians(10), 1.6, 1.1), (math.radians(170), 1.6, -1.1)]
    for a0, L, curl in specs:
        P, *_ = tentacle(a0, L, curl, 0.42)
        s.flat(P, 0.85, 1.0, navy, outline=ink)
        for i in (3, 5, 7):
            t = i / 8; a = a0 + curl * t; r = 1.2 + L * t
            if r > 2.0:
                s.flat(ellipse(math.cos(a)*r, math.sin(a)*r, 0.11*(1.2 - t), 0.11*(1.2 - t), n=8), 1.88, 0.03, purple)
    for x, y, r in [(-0.9, -0.7, 0.32), (0.6, -1.1, 0.26), (0.05, -0.45, 0.2), (1.1, -0.35, 0.18), (-0.4, -1.35, 0.17)]:
        s.flat(ellipse(x, y, r, r), TOP, T, purple)
    s.flat(ellipse(0, 1.3, 0.5, 0.18), TOP, T, red)
    s.hand_flat([(0.1, 0.3), (0.7, -0.2), (0.75, -0.75), (0.45, -0.95), (0.4, -0.55), (0.35, -0.2), (-0.2, 0.2)], 1.0, 0.7, navy, outline=ink, ow=0.05)

def caranguejo(s):
    # ref. 22: laranja-vermelho com branco. Pinças grandes na frente, três patas por lado, casco com pintas.
    s.base()
    org, white, ink, shade = "#EF582E", "#FAF8F6", "#3A1408", "#B84524"
    claw = [(1.4, 1.2), (2.35, 1.65), (2.75, 2.35), (2.6, 3.0), (2.25, 2.6), (2.05, 2.95), (1.7, 2.75), (1.95, 2.3), (1.55, 1.85)]
    s.sym(claw, 0.95, 1.0, org, outline=ink)
    s.sym([(2.25, 2.0), (2.5, 2.45), (2.3, 2.5)], 1.96, 0.03, white)
    for i, (y, ang) in enumerate([(0.2, 0.15), (-0.5, -0.1), (-1.2, -0.4)]):
        leg = [(1.6, y + 0.15), (2.4, y + 0.2 + ang), (2.75, y - 0.1 + ang*1.5), (2.55, y - 0.15 + ang), (2.35, y - 0.05 + ang), (1.6, y - 0.15)]
        s.sym(leg, 0.8, 1.0, org, outline=ink, smooth=False)
    s.flat([(-1.4, -0.2), (-0.7, 0.05), (0.0, -0.1), (0.7, 0.05), (1.4, -0.2), (1.2, -1.45), (-1.2, -1.45)], TOP, T, shade)
    for x, y, r in [(-0.7, -0.6, 0.18), (0.3, -0.5, 0.14), (0.8, -1.0, 0.17), (-0.2, -1.1, 0.12), (1.3, 1.0, 0.1), (-1.3, 1.0, 0.1)]:
        s.flat(ellipse(x, y, r, r, n=8), TOP + T, 0.03, white)
    s.hand_flat([(-0.55, -0.1), (-0.1, 0.9), (0.05, 0.45), (0.25, 0.95), (0.6, -0.05)], 1.05, 0.6, org, outline=ink, ow=0.05)

def abelha(s):
    # ref. 20: amarelo, faixas escuras, asas claras. Asas transparentes atrás, antenas, ferrão.
    s.base()
    yel, dark, brown, wingc, ink = "#FFDC00", "#311B16", "#663C07", "#F4FAFA", "#311B16"
    for y in (-0.15, -0.95):
        s.flat([(-1.8, y + 0.25), (1.8, y + 0.25), (1.8, y - 0.25), (-1.8, y - 0.25)], TOP, T, dark, smooth=False)
    s.flat([(-1.25, -1.55), (1.25, -1.55), (0.9, -1.8), (-0.9, -1.8)], TOP, T, dark, smooth=False)
    wing = [(0.4, -0.6), (1.6, -1.1), (2.65, -1.3), (2.9, -2.0), (2.3, -2.5), (1.2, -2.2), (0.5, -1.4)]
    s.sym(wing, 2.12, 0.03, wingc, outline="#8FA3A8", ow=0.06, alpha=0.75)
    s.sym([(0.8, -1.2), (2.3, -1.55), (1.3, -1.85)], 2.16, 0.01, "#C9DDE2", smooth=False)
    s.flat([(-0.22, -1.75), (0.22, -1.75), (0.0, -2.55)], 0.9, 0.9, dark, outline=ink, ow=0.04, smooth=False)
    for k in (-1, 1):
        ant = [(k*0.45, 1.5), (k*0.75, 2.2), (k*1.05, 2.45), (k*0.95, 2.55), (k*0.62, 2.28), (k*0.33, 1.55)]
        s.flat(ant, 1.95, 0.05, dark, smooth=False)
        s.flat(ellipse(k*1.02, 2.5, 0.18, 0.18, n=10), 2.0, 0.06, dark)
    s.hand_flat([(-0.66, 0.12), (0.66, 0.12), (0.66, -0.12), (-0.66, -0.12)], 1.86, 0.03, dark, smooth=False)

def dragao(s):
    # ref. 98: verde-água com branco. Asas abertas com membrana, chifres para trás, crista na coluna, rabo com ponta.
    s.base()
    teal, white, ink, light = "#80CCCA", "#FFFFFF", "#204040", "#BBE2E1"
    wing = [(1.5, -0.2), (2.6, 0.5), (3.6, 0.3), (3.3, -0.4), (3.55, -1.1), (2.95, -1.0), (2.85, -1.75), (2.3, -1.35), (1.6, -1.4)]
    s.sym(wing, 1.15, 0.7, light, outline=ink, smooth=False)
    for tip in [(3.6, 0.3), (3.55, -1.1), (2.85, -1.75)]:
        dx, dy = tip[0] - 1.7, tip[1] + 0.3; L = math.hypot(dx, dy); nx, ny = -dy/L*0.06, dx/L*0.06
        s.sym([(1.7 + nx, -0.3 + ny), (tip[0], tip[1]), (1.7 - nx, -0.3 - ny)], 1.86, 0.03, teal, smooth=False)
    # chifres saindo das laterais de trás para fora (não podem descer dos olhos: viram presas de cima)
    horn = [(1.0, -0.45), (1.8, -0.5), (2.5, -0.3), (2.95, 0.15), (2.55, -0.75), (1.8, -0.95), (1.0, -0.85)]
    s.sym(horn, TOP, 0.12, white, outline=ink, ow=0.06)
    for i, y in enumerate([0.1, -0.4, -0.9, -1.4]):
        w = 0.32 - i*0.03
        s.flat([(-w, y + 0.15), (w, y + 0.15), (0, y - 0.35)], TOP, 0.08, white, outline=ink, ow=0.05, smooth=False)
    tail = [(-0.35, -1.7), (-0.2, -2.6), (-0.65, -2.85), (0.0, -3.6), (0.65, -2.85), (0.2, -2.6), (0.35, -1.7)]
    s.flat(tail, 0.9, 1.0, teal, outline=ink, smooth=False)
    s.flat([(-0.35, -2.9), (0.0, -3.35), (0.35, -2.9), (0.0, -2.75)], 1.92, 0.04, white, smooth=False)
    s.flat(ellipse(0, 1.35, 0.85, 0.35), TOP, T, light)
    for k in (-1, 1):
        s.flat(ellipse(k*0.25, 1.5, 0.08, 0.06, n=8), TOP + T, 0.03, ink)
    for k in (-1, 0, 1):
        s.hand_flat([(k*0.22 - 0.07, 0.5), (k*0.22 + 0.07, 0.5), (k*0.22, 0.78)], 1.2, 0.08, white, smooth=False)

def coelho(s):
    # ref. 71: rosa, rosa-escuro e rosa-claro. Orelhas compridas deitadas para trás, rabinho de algodão, bochechas.
    s.base()
    pink, dark, light, ink = "#EF97BF", "#BD678F", "#FDEFF6", "#7A3E5A"
    # orelhas compridas deitadas em V, saindo de trás dos olhos para fora e para trás
    for k in (-1, 1):
        ear = [(k*0.45, -0.35), (k*1.05, -0.15), (k*1.75, -0.9), (k*2.45, -2.0), (k*2.55, -2.65), (k*2.15, -2.75), (k*1.45, -2.0), (k*0.7, -1.0)]
        s.flat(ear, TOP + 0.06, 0.08, pink, outline=ink, ow=0.08)
        s.flat([(k*0.75, -0.45), (k*1.1, -0.4), (k*1.7, -1.15), (k*2.25, -2.15), (k*2.15, -2.45), (k*1.5, -1.75), (k*0.85, -0.9)], TOP + 0.15, 0.02, light)
    s.flat(ellipse(0, -2.05, 0.55, 0.5), 0.9, 1.0, light, outline=ink)
    for k in (-1, 1):
        s.flat(ellipse(k*1.3, 1.05, 0.28, 0.2), TOP, T, dark)
    s.flat([(-0.16, 1.45), (0.16, 1.45), (0.0, 1.25)], TOP, 0.04, dark, smooth=False)
    for x, y, r in [(0, -0.05, 0.22), (-0.27, 0.22, 0.11), (0.0, 0.32, 0.11), (0.27, 0.22, 0.11)]:
        s.hand_flat(ellipse(x, y, r, r * 0.9, n=8), 1.85, 0.03, light)

def arbusto(s):
    # ref. 153: verdes com frutinhas vermelhas. Borda de folhas em volta toda, cachos de frutas no topo.
    s.base()
    green, dark, red, hi, ink = "#0B8052", "#056648", "#AC222A", "#E05C63", "#033D2A"
    for i in range(14):
        a = 2*math.pi*i/14 + 0.1
        r = 2.05 + 0.12*(i % 2)
        leaf = ellipse(math.cos(a)*r, math.sin(a)*r, 0.62, 0.32, n=12, rot=a)
        s.flat(leaf, 0.9 + 0.02*(i % 2), 1.0, green if i % 2 else dark, outline=ink, ow=0.06)
    for x, y, a in [(-1.0, -0.6, 0.7), (0.9, -0.9, -0.5), (0.0, -1.3, 1.6), (-1.3, 0.6, 2.4), (1.25, 0.4, -2.2)]:
        s.flat(ellipse(x, y, 0.5, 0.22, n=12, rot=a), TOP, 0.04, dark)
    for cx, cy in [(-0.55, -0.35), (0.6, -0.25), (0.0, -0.95), (-1.2, -1.15), (1.2, -1.2)]:
        for dx, dy in [(-0.17, 0.0), (0.17, 0.05), (0.0, -0.2)]:
            s.flat(ellipse(cx + dx, cy + dy, 0.17, 0.17, n=10), TOP + 0.04, 0.06, red, outline=ink, ow=0.04)
            s.flat(ellipse(cx + dx + 0.05, cy + dy + 0.05, 0.05, 0.05, n=6), TOP + 0.1, 0.02, hi)
    s.hand_flat(ellipse(0.1, -0.6, 0.38, 0.2, n=10, rot=0.6), 1.25, 0.06, green, outline=ink, ow=0.04)
    s.hand_flat(ellipse(0.15, 0.15, 0.1, 0.1, n=8), 1.86, 0.02, hi)

def nuvem(s):
    # ref. 86: branco-azulado com sombra cinza-azul. Borda fofa de bolhas, sombras macias atrás.
    s.base()
    white, edge, shade, light = "#E4F4FA", "#699498", "#B8D1CF", "#F7FEFF"
    puffs = [(0, 2.05, 0.7), (1.35, 1.75, 0.65), (2.1, 0.75, 0.62), (2.15, -0.45, 0.66), (1.6, -1.6, 0.7), (0.5, -2.15, 0.72),
             (-0.65, -2.1, 0.7), (-1.65, -1.55, 0.68), (-2.15, -0.4, 0.66), (-2.1, 0.8, 0.62), (-1.35, 1.75, 0.65)]
    for x, y, r in puffs:
        s.flat(ellipse(x, y, r, r, n=14), 0.9, 1.0, white, outline=edge, ow=0.09)
    for x, y, r in [(-0.75, -0.9, 0.55), (0.45, -1.25, 0.6), (1.1, -0.45, 0.42), (-1.25, -0.1, 0.38)]:
        s.flat(ellipse(x, y, r, r*0.8, n=14), TOP, 0.03, shade)
    for x, y, r in [(-0.9, 1.25, 0.32), (1.0, 1.2, 0.26)]:
        s.flat(ellipse(x, y, r, r*0.8, n=12), TOP, 0.03, light)
    for x, y, r in [(-0.38, -0.25, 0.32), (0.38, -0.25, 0.32), (0.0, 0.3, 0.36)]:
        s.hand_flat(ellipse(x, y, r, r, n=12), 0.95, 0.85, white, outline=edge, ow=0.06)


LOTE = [
    ("lobo", lobo, "#7F8F94", "#324050", "#5D6C74", "#324050"),
    ("raposa", raposa, "#D46A35", "#262121", "#D46A35", "#262121"),
    ("coruja", coruja, "#604228", "#2E1E10", "#5F4228", "#2E1E10"),
    ("polvo", polvo, "#2C206A", "#120B33", "#2C206A", "#120B33"),
    ("caranguejo", caranguejo, "#EF582E", "#3A1408", "#EF6A45", "#3A1408"),
    ("abelha", abelha, "#FFDC00", "#311B16", "#FFDC00", "#311B16"),
    ("dragao", dragao, "#80CCCA", "#204040", "#80CCCA", "#204040"),
    ("coelho", coelho, "#EF97BF", "#7A3E5A", "#EF97BF", "#7A3E5A"),
    ("arbusto", arbusto, "#0B8052", "#033D2A", "#AC222A", "#5E1015"),
    ("nuvem", nuvem, "#E4F4FA", "#699498", "#E4F4FA", "#699498"),
]
