# Lote 3 (parte E) — skins de corpo. Montar com build_skins.py (Blender aberto) ou render_lote.py (segundo plano).
from skin_lib import *


def _limb(center, widths, cap=True):
    # contorno de um membro ao longo de uma linha central (largura por ponto); ponta arredondada no fim
    left, right = [], []
    n = len(center)
    for i, ((x, y), w) in enumerate(zip(center, widths)):
        a, b = center[max(i - 1, 0)], center[min(i + 1, n - 1)]
        dx, dy = b[0] - a[0], b[1] - a[1]; L = math.hypot(dx, dy) or 1
        nx, ny = -dy / L, dx / L
        left.append((x + nx*w, y + ny*w)); right.append((x - nx*w, y - ny*w))
    tip = []
    if cap:
        (ax, ay), (bx, by) = center[-2], center[-1]
        dx, dy = bx - ax, by - ay; L = math.hypot(dx, dy) or 1
        tip = [(bx + dx/L*widths[-1]*0.9, by + dy/L*widths[-1]*0.9)]
    return left + tip + list(reversed(right))

def _blob(cx, cy, r, n=12, wob=0.08, seed=0, sx=1.0, sy=1.0):
    # elipse irregular (anéis de madeira, pintas): raio varia de leve
    return [(cx + sx*r*(1 + wob*math.sin(3*a + seed) + 0.5*wob*math.cos(5*a + 2*seed))*math.cos(a),
             cy + sy*r*(1 + wob*math.sin(3*a + seed) + 0.5*wob*math.cos(5*a + 2*seed))*math.sin(a))
            for a in [2*math.pi*i/n for i in range(n)]]

def _squircle(h, n=40, p=4.0, bump=0.0, k=11, cx=0.0, cy=0.0):
    # quadrado arredondado (formato do corpo), com ondulação opcional na borda
    out = []
    for i in range(n):
        a = 2*math.pi*i/n
        c, s_ = math.cos(a), math.sin(a)
        r = h / (abs(c)**p + abs(s_)**p) ** (1/p)
        r *= 1 + bump*math.sin(k*a)
        out.append((cx + r*c, cy + r*s_))
    return out


def toco(s):
    # Toco de árvore: topo cortado com anéis de crescimento (tons de madeira próximos), casca em placas na borda,
    # raízes saindo pela silhueta e brotos com folhas saindo de trás.
    s.base()
    wood, wood2, bark, dark, ink, leaf, leafd = "#685635", "#644928", "#543F21", "#372A17", "#25201D", "#127952", "#1E6B45"
    # casca: borda ondulada um pouco maior que o corpo (silhueta rugosa)
    s.flat(_squircle(2.08, n=48, p=3.2, bump=0.05, k=13), 0.8, 1.0, bark, outline=ink, ow=0.08)
    # raízes: grossas na base, afinando, uma com bifurcação (evitam os cantos da frente, onde ficam as mãos)
    roots = [
        ([(1.3, -0.1), (2.1, -0.15), (2.7, -0.05), (3.15, 0.15)], [0.42, 0.34, 0.22, 0.12]),
        ([(1.0, -1.0), (1.8, -1.7), (2.35, -2.3), (2.6, -2.85)], [0.45, 0.36, 0.22, 0.12]),
        ([(-1.3, -0.4), (-2.15, -0.55), (-2.65, -0.85), (-2.95, -1.3)], [0.42, 0.33, 0.2, 0.11]),
        ([(-1.1, -1.1), (-1.85, -1.75), (-2.1, -2.45), (-2.0, -3.0)], [0.44, 0.34, 0.2, 0.11]),
        ([(-0.3, 1.3), (-0.4, 2.0), (-0.75, 2.55), (-1.05, 2.8)], [0.4, 0.3, 0.18, 0.1]),
        ([(0.35, 1.3), (0.5, 2.05), (0.4, 2.45)], [0.36, 0.25, 0.14]),
    ]
    for c, w in roots:
        s.flat(_limb(c, w), 0.78, 1.0, wood2, outline=ink, ow=0.08)
        if len(c) > 3:  # veio claro em cima das raízes compridas
            s.flat(_limb(c[1:], [x*0.3 for x in w[1:]]), 1.79, 0.01, wood)
    # placas de casca na borda do topo (tom mais claro sobre a casca, com frestas)
    cuts = [0.0, 0.55, 0.95, 1.6, 2.05, 2.75, 3.1, 3.7, 4.3, 4.65, 5.35, 5.8, 2*math.pi]
    for i in range(len(cuts) - 1):
        a0 = cuts[i] + 0.25 + 0.045; a1 = cuts[i + 1] + 0.25 - 0.045
        r0 = 1.6 + 0.04*(i % 3)
        pts = []
        for a, r in ((a0, r0), ((a0 + a1)/2, r0 - 0.04), (a1, r0), (a1, 1.86), (a0, 1.86)):
            c, s_ = math.cos(a), math.sin(a)
            k = 1 / (abs(c)**3.2 + abs(s_)**3.2) ** (1/3.2)
            pts.append((r*k*c, r*k*s_))
        s.flat(pts, TOP - 0.02, 0.03, wood2, smooth=False)
    # topo cortado: superfície clara com borda escura (câmbio) e anéis de crescimento em tons próximos
    cx, cy = 0.1, -0.45
    s.flat(_squircle(1.5, n=36, p=2.6, bump=0.025, k=7), TOP, 0.03, wood, outline=dark, ow=0.09)
    for i, r in enumerate((1.12, 0.78, 0.46)):
        s.flat(_blob(cx, cy, r, n=14, wob=0.06, seed=i*1.7, sx=1.08, sy=0.95), TOP + 0.03 + 0.012*i, 0.012,
               wood if i % 2 == 0 else "#6E5A39", outline=bark, ow=0.065)
    s.flat(_blob(cx, cy, 0.17, n=10, wob=0.1, seed=4), TOP + 0.08, 0.02, bark)
    # rachadura em cunha entrando pela borda de trás à direita (longe dos olhos)
    s.flat([(1.32, -1.25), (0.95, -1.0), (0.62, -0.95), (0.9, -1.12), (1.15, -1.45)], TOP + 0.09, 0.02, dark, smooth=False)
    # brotos saindo de trás: galhinhos com folhas
    twigs = [
        ([(-0.55, -1.35), (-0.8, -2.0), (-1.2, -2.6), (-1.45, -3.1)], [0.12, 0.1, 0.08, 0.06]),
        ([(0.35, -1.4), (0.45, -2.05), (0.85, -2.55)], [0.11, 0.09, 0.06]),
    ]
    for c, w in twigs:
        s.flat(_limb(c, w), 1.75, 0.25, dark, outline=ink, ow=0.05)
    leaves = [(-1.5, -3.35, 0.42, 0.22, -1.9, leaf), (-1.75, -2.75, 0.38, 0.2, 2.6, leafd),
              (-0.65, -2.55, 0.36, 0.19, -0.6, leaf), (1.15, -2.75, 0.4, 0.21, -0.55, leaf),
              (0.7, -3.0, 0.33, 0.17, -2.0, leafd), (0.05, -2.2, 0.3, 0.16, 3.5, leaf)]
    for x, y, rx, ry, rot, col in leaves:
        s.flat(ellipse(x, y, rx, ry, n=12, rot=rot), 1.85, 0.08, col, outline=leafd if col == leaf else ink, ow=0.05)
    # mão: toquinho com anéis no topo e uma folhinha brotando
    s.hand_flat(_blob(0, 0, 0.42, n=12, wob=0.05, seed=1), 1.84, 0.02, wood, outline=bark, ow=0.05)
    s.hand_flat(_blob(0.03, -0.02, 0.2, n=10, wob=0.08, seed=2), 1.87, 0.015, wood, outline=bark, ow=0.04)
    s.hand_flat(ellipse(0.55, -0.55, 0.3, 0.15, n=12, rot=-0.8), 1.6, 0.1, leaf, outline=leafd, ow=0.04)


def lula(s):
    # Lula: manto pontudo atrás com duas barbatanas em losango (silhueta principal), oito bracinhos curtos
    # e retos na frente-lateral, dois tentáculos longos com clava, cromatóforos no topo.
    s.base()
    body, deep, ink, dark, lilac, light = "#44309C", "#201552", "#130A3A", "#211554", "#B7A4EC", "#5642B2"
    # barbatanas (embaixo do manto)
    fin = [(0.35, -2.1), (1.55, -2.45), (2.85, -3.35), (1.6, -3.85), (0.3, -4.0)]
    s.sym(fin, 0.75, 1.0, body, outline=ink, ow=0.09, smooth=False)
    s.sym([(0.9, -2.6), (2.35, -3.32), (0.85, -3.55)], 1.76, 0.02, dark, smooth=False)
    # manto pontudo
    mantle = [(-1.55, -0.6), (1.55, -0.6), (1.45, -1.9), (1.05, -3.0), (0.45, -4.1), (0.0, -4.55), (-0.45, -4.1), (-1.05, -3.0), (-1.45, -1.9)]
    s.flat(mantle, 0.8, 1.0, body, outline=ink, ow=0.09)
    # oito bracinhos curtos e retos: 2 na frente e 2 na lateral de cada lado
    for k in (-1, 1):
        for (x0, y0, ang, L, w) in [(0.32, 1.4, 86, 1.05, 0.19), (1.0, 1.35, 68, 1.0, 0.19),
                                    (1.4, 0.35, 14, 1.55, 0.2), (1.4, -0.25, -4, 1.35, 0.19)]:
            a = math.radians(ang)
            c = [(x0 + math.cos(a)*L*t, y0 + math.sin(a)*L*t) for t in (0.0, 0.5, 1.0)]
            c = [(k*x, y) for x, y in c]
            s.flat(_limb(c, [w, w*0.8, w*0.5]), 0.82, 1.0, body, outline=ink, ow=0.08)
            if ang < 45:  # ventosa só nos bracinhos da frente
                continue
            ex, ey = c[-1]; mx, my = c[1]
            s.flat(ellipse((ex*0.7 + mx*0.3), (ey*0.7 + my*0.3), 0.07, 0.07, n=8), 1.83, 0.02, lilac)
    # dois tentáculos longos que saem do meio da frente, passam por cima dos bracinhos e abrem em clava
    for k in (-1, 1):
        c = [(0.62, 1.45), (0.78, 2.35), (1.2, 3.1), (1.8, 3.55), (2.35, 3.7), (2.8, 3.65), (3.2, 3.45)]
        w = [0.14, 0.12, 0.11, 0.12, 0.24, 0.26, 0.15]
        c = [(k*x, y) for x, y in c]
        s.flat(_limb(c, w), 0.9, 1.0, body, outline=ink, ow=0.08)
        for x, y, r in [(2.3, 3.7, 0.09), (2.65, 3.68, 0.1), (2.98, 3.57, 0.08)]:
            s.flat(ellipse(k*x, y, r, r, n=8), 1.91, 0.02, lilac)
    # topo: manto mais claro com borda ondulada na frente (onde o manto encontra a cabeça)
    collar = [(-1.6, -0.05), (-1.0, 0.05), (-0.5, -0.12), (0.0, -0.02), (0.5, -0.12), (1.0, 0.05), (1.6, -0.05), (1.6, -1.6), (-1.6, -1.6)]
    s.flat(collar, TOP, 0.03, light)
    s.flat([(0.0, -1.2), (0.12, -2.0), (0.0, -3.9), (-0.12, -2.0)], 1.81, 0.02, light)
    # cromatóforos: pintas de tamanhos variados (só da linha dos olhos para trás e no manto)
    for x, y, r, col in [(-0.95, -0.55, 0.2, dark), (0.55, -0.45, 0.15, dark), (-0.1, -0.95, 0.24, dark),
                         (1.1, -1.1, 0.19, dark), (0.45, -1.4, 0.11, lilac), (0.55, -2.55, 0.17, dark), (-0.6, -2.3, 0.2, dark),
                         (0.0, -3.2, 0.13, dark), (0.75, -1.95, 0.09, lilac)]:
        z = TOP + 0.03 if y > -1.6 else 1.81
        s.flat(_blob(x, y, r, n=10, wob=0.12, seed=x*3 + y), z, 0.02, col)
    # mão: ventosas
    for x, y, r in [(-0.12, 0.1, 0.22), (0.22, -0.22, 0.16)]:
        s.hand_flat(ellipse(x, y, r, r, n=12), 1.84, 0.02, lilac, outline=dark, ow=0.04)
        s.hand_flat(ellipse(x, y, r*0.45, r*0.45, n=8), 1.865, 0.01, body)


LOTE = [
    ("toco", toco, "#543F21", "#25201D", "#644928", "#25201D"),
    ("lula", lula, "#44309C", "#130A3A", "#44309C", "#130A3A"),
]
