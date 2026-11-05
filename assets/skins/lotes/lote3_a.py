# Lote 3 (parte A) — skins de corpo. Montar com build_skins.py (Blender aberto) ou render_lote.py (segundo plano).
from skin_lib import *


# ---------------------------------------------------------------- ajudantes do lote
def _ribbon(c, w):
    # faixa ao longo da linha central c, com meia-largura w[i] em cada ponto (chifres, rabo)
    left, right = [], []
    n = len(c)
    for i in range(n):
        a, b = c[max(i - 1, 0)], c[min(i + 1, n - 1)]
        dx, dy = b[0] - a[0], b[1] - a[1]; L = math.hypot(dx, dy) or 1
        nx, ny = -dy/L, dx/L
        left.append((c[i][0] + nx*w[i], c[i][1] + ny*w[i]))
        right.append((c[i][0] - nx*w[i], c[i][1] - ny*w[i]))
    return left + right[::-1]

def _bez(p0, p1, p2, p3, n=12):
    # curva de Bézier cúbica amostrada em n+1 pontos
    out = []
    for i in range(n + 1):
        t = i/n; u = 1 - t
        out.append(tuple(u*u*u*p0[j] + 3*u*u*t*p1[j] + 3*u*t*t*p2[j] + t*t*t*p3[j] for j in (0, 1)))
    return out

def _band(cx, cy, rx, ry, hw, a0, a1, n=14):
    # pedaço de anel (de a0 a a1, em graus); dois pedaços fecham o anel sem furo no polígono
    A = [math.radians(a0 + (a1 - a0)*i/n) for i in range(n + 1)]
    outer = [(cx + (rx + hw)*math.cos(a), cy + (ry + hw)*math.sin(a)) for a in A]
    inner = [(cx + (rx - hw)*math.cos(a), cy + (ry - hw)*math.sin(a)) for a in reversed(A)]
    return outer + inner

def _feather(root, ang, L, w, n=12):
    # pena = elipse comprida saindo da raiz no ângulo ang (graus, a partir de +x)
    a = math.radians(ang)
    return ellipse(root[0] + math.cos(a)*L/2, root[1] + math.sin(a)*L/2, L/2, w, n=n, rot=a)


# ---------------------------------------------------------------- skins
def anjo(s):
    # Asas de penas em três camadas saindo das costas, auréola dourada flutuando atrás, mão com asinha.
    s.base()
    white, pale, blue, deep, ink = "#D5EEF1", "#C8DCE7", "#B7C9E5", "#A9BCD7", "#44577D"
    gold, gold_l = "#CAAD68", "#F1DF81"
    root = (1.15, -0.75)
    for k in (-1, 1):
        r = (k*root[0], root[1])
        def ang(a): return a if k > 0 else 180 - a
        # rêmiges (as mais compridas, embaixo), depois secundárias, depois as penas curtas do ombro
        for a, L in [(22, 2.3), (2, 2.5), (-20, 2.45), (-42, 2.25), (-64, 1.95)]:
            s.flat(_feather(r, ang(a), L, 0.32), 0.8, 1.0, deep, outline=ink, ow=0.08)
        for a, L in [(12, 1.85), (-10, 1.9), (-32, 1.8), (-54, 1.6)]:
            s.flat(_feather(r, ang(a), L, 0.36), 0.86, 1.0, blue if a % 2 else pale, outline=ink, ow=0.07)
        for a, L in [(2, 1.45), (-24, 1.45), (-48, 1.3)]:
            s.flat(_feather(r, ang(a), L, 0.4), 0.92, 1.0, white, outline=ink, ow=0.07)
    # topo: manto claro de borda ondulada nas costas (tom próximo do corpo)
    back = [(-1.65, -0.55), (-1.1, -0.8), (-0.55, -0.55), (0.0, -0.85), (0.55, -0.55), (1.1, -0.8), (1.65, -0.55), (1.55, -1.75), (-1.55, -1.75)]
    s.flat(back, TOP, 0.03, pale)
    # auréola flutuando acima da parte de trás: faixa escura dourada por baixo, dourado claro com brilho por cima
    # (atrás da borda de trás: em cima do corpo, vista de cima com o boneco de costas, virava boca em "O")
    hc, hr = (0.0, -2.15), (0.8, 0.5)
    for a0, a1 in ((0, 180), (180, 360)):
        s.flat(_band(hc[0], hc[1], hr[0], hr[1], 0.15, a0, a1), TOP + 0.35, 0.07, gold, smooth=False)
        s.flat(_band(hc[0], hc[1], hr[0], hr[1], 0.08, a0, a1), TOP + 0.41, 0.05, gold_l, smooth=False, emit=0.35)
    # mão: asinha de três penas para fora e um ponto dourado
    for a, L in [(10, 1.05), (-20, 1.1), (-50, 0.95)]:
        s.hand_flat(_feather((0.2, -0.1), a, L, 0.19, n=10), 0.95, 0.8, pale if a != -20 else white, outline=ink, ow=0.05)
    s.hand_flat(ellipse(-0.05, 0.05, 0.13, 0.13, n=10), 1.86, 0.04, gold_l, emit=0.3)


def diabinho(s):
    # Chifrinhos curvos saindo das laterais de trás, asinhas de morcego, rabo fino com ponta de seta, mão com garras.
    s.base()
    red, wine, dark, ink, coal, coal2, bone = "#B6222A", "#92242A", "#6E1F24", "#231F20", "#393234", "#2F292A", "#D2C1C2"
    for k in (-1, 1):
        # asinha de morcego (embaixo, atrás dos chifres) com borda em arcos e varetas
        wing = [(1.3, -0.9), (2.1, -0.8), (3.0, -1.3), (2.95, -2.05), (2.6, -1.8), (2.35, -2.4), (2.0, -2.05), (1.6, -2.5), (1.3, -2.0)]
        s.flat([(k*x, y) for x, y in wing], 0.82, 1.0, dark, outline=ink, ow=0.08, smooth=False)
        for tx, ty in [(2.95, -2.05), (2.35, -2.4)]:
            s.flat(_ribbon([(k*1.9, -1.0), (k*tx*0.97, ty*0.97)], [0.06, 0.03]), 1.83, 0.03, coal2, smooth=False)
        # chifre: começa na borda de trás do corpo, abre para fora e curva para a frente na ponta
        c = _bez((1.35, -0.55), (2.1, -1.05), (2.75, -0.75), (2.75, 0.05), n=14)
        c = [(k*x, y) for x, y in c]
        w = [0.33*(1 - i/14) + 0.03 for i in range(15)]
        s.flat(_ribbon(c, w), TOP + 0.02, 0.14, coal, outline=ink, ow=0.06, smooth=False)
        # brilho claro ao longo do chifre (lado de fora)
        hl = [(x, y) for x, y in c[3:13]]
        s.flat(_ribbon(hl, [0.07*(1 - i/10) + 0.02 for i in range(10)]), TOP + 0.17, 0.02, bone, smooth=False)
    # rabo fino em S saindo das costas, com ponta de seta
    tail = _bez((0.0, -1.5), (0.9, -2.6), (-0.7, -2.9), (0.35, -3.6), n=16)
    s.flat(_ribbon(tail, [0.12]*len(tail)), 0.85, 1.0, coal, outline=ink, ow=0.07, smooth=False)
    (x0, y0), (x1, y1) = tail[-2], tail[-1]
    dx, dy = x1 - x0, y1 - y0; L = math.hypot(dx, dy); ux, uy = dx/L, dy/L; vx, vy = -uy, ux
    def P(u, v): return (x1 + ux*u + vx*v, y1 + uy*u + vy*v)
    s.flat([P(0.65, 0), P(0.0, 0.4), P(0.1, 0.12), P(-0.05, 0), P(0.1, -0.12), P(0.0, -0.4)], 0.87, 1.0, coal, outline=ink, ow=0.07, smooth=False)
    # topo: costas vinho com borda ondulada; sobrancelhas finas e bravas (de cima ficam atrás dos olhos)
    back = [(-1.65, -0.6), (-1.1, -0.85), (-0.55, -0.6), (0.0, -0.9), (0.55, -0.6), (1.1, -0.85), (1.65, -0.6), (1.55, -1.75), (-1.55, -1.75)]
    s.flat(back, TOP, 0.03, wine)
    for k in (-1, 1):
        s.flat(_ribbon([(k*0.35, 0.12), (k*1.2, -0.12)], [0.06, 0.04]), TOP, 0.04, dark, smooth=False)
    # mão: três garrinhas claras para a frente e uma ponta de seta escura no dorso
    for a in (65, 90, 115):
        r = math.radians(a)
        cx, cy = math.cos(r), math.sin(r); px, py = -cy, cx
        s.hand_flat([(cx*0.45 + px*0.12, cy*0.45 + py*0.12), (cx*0.88, cy*0.88), (cx*0.45 - px*0.12, cy*0.45 - py*0.12)], 1.0, 0.6, bone, outline=ink, ow=0.04, smooth=False)
    s.hand_flat([(0.0, 0.32), (-0.2, -0.02), (-0.06, 0.02), (-0.05, -0.25), (0.05, -0.25), (0.06, 0.02), (0.2, -0.02)], 1.85, 0.04, ink, smooth=False)


LOTE = [
    ("anjo", anjo, "#D5EEF1", "#44577D", "#D5EEF1", "#44577D"),
    ("diabinho", diabinho, "#B6222A", "#231F20", "#B6222A", "#231F20"),
]
