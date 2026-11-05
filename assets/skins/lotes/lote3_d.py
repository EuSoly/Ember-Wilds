# Lote 3 (parte D) — skins de corpo: cacto e maçã.
# Montar com build_skins.py (Blender aberto) ou render_lote.py (segundo plano).
from skin_lib import *


def _capsule(x0, y0, x1, y1, r, n=8):
    # "salsicha" de p0 a p1 com pontas redondas (braços do cacto, talinho)
    a = math.atan2(y1 - y0, x1 - x0)
    pts = []
    for i in range(n + 1):
        t = a - math.pi/2 + math.pi*i/n
        pts.append((x1 + r*math.cos(t), y1 + r*math.sin(t)))
    for i in range(n + 1):
        t = a + math.pi/2 + math.pi*i/n
        pts.append((x0 + r*math.cos(t), y0 + r*math.sin(t)))
    return pts

def _bar(x0, y0, x1, y1, w):
    dx, dy = x1 - x0, y1 - y0; L = math.hypot(dx, dy) or 1; nx, ny = -dy/L*w, dx/L*w
    return [(x0+nx, y0+ny), (x1+nx, y1+ny), (x1-nx, y1-ny), (x0-nx, y0-ny)]

def _tuft(px, py, ang, L=0.34, spread=0.42, w=0.05):
    # par de espinhos em "V" saindo do ponto (px, py) na direção ang
    d = (math.cos(ang), math.sin(ang)); n = (-d[1], d[0])
    t1 = (px + L*math.cos(ang + spread), py + L*math.sin(ang + spread))
    t2 = (px + L*math.cos(ang - spread), py + L*math.sin(ang - spread))
    return [(px - n[0]*w, py - n[1]*w), t2, (px + d[0]*0.12, py + d[1]*0.12), t1, (px + n[0]*w, py + n[1]*w)]

def _flower(s, cx, cy, z, r, petal, ink, seed, hand=False):
    put = s.hand_flat if hand else s.flat
    for i in range(5):
        a = 2*math.pi*i/5 + math.pi/2
        put(ellipse(cx + math.cos(a)*r, cy + math.sin(a)*r, r*1.05, r*0.7, n=10, rot=a), z, 0.05, petal, outline=ink, ow=0.035)
    put(ellipse(cx, cy, r*0.5, r*0.5, n=8), z + 0.06, 0.03, ink)
    put(ellipse(cx, cy, r*0.22, r*0.22, n=6), z + 0.09, 0.03, seed)


def cacto(s):
    # Cacto de deserto: dois braços em "L" saindo das laterais e virando para trás (alturas diferentes),
    # costelas claras no topo em tom próximo do corpo, espinhos só na silhueta, flor rosa no canto de trás.
    s.base()
    light, body, groove, ink, spine, petal, deep = "#95A37E", "#86976B", "#70855D", "#5D6F4C", "#BEBC9F", "#AE809A", "#593850"
    # braços (cápsulas sobrepostas: o contorno só aparece na borda de fora da união)
    arms = [((-1.4, 0.05), (-2.6, 0.05), (-2.6, -1.6), 0.4),   # esquerdo: mais comprido
            ((1.4, -0.35), (2.5, -0.35), (2.5, -2.0), 0.37)]   # direito: mais baixo e mais longo para trás
    for (a, e, t, r) in arms:
        s.flat(_capsule(*a, *e, r), 0.85, 1.0, body, outline=ink, ow=0.09, smooth=False)
        s.flat(_capsule(*e, *t, r), 0.85, 1.0, body, outline=ink, ow=0.09, smooth=False)
        k = 1 if e[0] > 0 else -1
        s.flat(_bar(a[0] + k*0.35, a[1], e[0], e[1], 0.08), 1.86, 0.03, light, smooth=False)
        s.flat(_bar(e[0], e[1], t[0], t[1] + 0.1, 0.08), 1.86, 0.03, light, smooth=False)
        s.flat(ellipse(e[0], e[1], 0.08, 0.08, n=8), 1.86, 0.03, light, smooth=False)  # junta do cotovelo
    # costelas do corpo: faixas claras e macias, longe da linha dos olhos (x = ±0,8)
    s.flat(ellipse(0, -0.1, 0.2, 1.55, n=16), TOP, 0.03, light)
    s.sym(ellipse(1.42, -0.05, 0.17, 1.3, n=16), TOP, 0.03, light)
    # espinhos em tufos, só para fora da borda
    tufts = [(-2.6 - 0.4*0.7, 0.05 + 0.4*0.7, math.radians(135)), (-3.0, -0.8, math.pi), (-3.0, -1.45, math.radians(195)),
             (2.5 + 0.37*0.7, -0.35 + 0.37*0.7, math.radians(45)), (2.87, -1.3, 0.0), (2.5, -2.37, -math.pi/2),
             (-0.55, -1.95, -math.pi/2), (0.3, -1.95, -math.pi/2)]
    for px, py, ang in tufts:
        s.flat(_tuft(px, py, ang), 1.45, 0.35, spine, smooth=False)  # sem contorno: de 65° ele vira parede escura
    # flor no canto de trás (passa da borda) e um botão na ponta do braço esquerdo
    _flower(s, 1.3, -1.35, TOP + 0.02, 0.3, petal, deep, spine)
    s.flat(ellipse(-2.6, -1.75, 0.2, 0.25, n=10), 1.86, 0.06, petal, outline=deep, ow=0.035)
    # mão: tufos de espinho para fora e uma florzinha no alto
    for a in (-25, 40, 100):
        r = math.radians(a)
        s.hand_flat(_tuft(math.cos(r)*0.6, math.sin(r)*0.6, r, L=0.3), 1.2, 0.3, spine, smooth=False)
    _flower(s, 0, 0, 1.84, 0.17, petal, deep, spine, hand=True)


def maca(s):
    # Maçã: silhueta redonda com "ombros" atrás e covinha do talo, talinho escuro e folha passando
    # da borda de trás, metade de trás um tom mais escura, brilho suave, bichinho saindo pela lateral.
    s.base()
    red, mid, dark, ink, leaf, leaf_d, stem = "#B7442D", "#9B3B29", "#853328", "#6D2A27", "#A4BC50", "#71823F", "#241F20"
    shine = "#CF6A50"  # brilho: um tom mais claro do vermelho do corpo
    half = [(0.0, -2.12), (0.55, -2.45), (1.2, -2.6), (1.9, -2.35), (2.35, -1.75), (2.52, -0.9), (2.42, 0.0),
            (2.1, 0.7), (1.6, 1.25), (0.8, 1.5)]
    apple = half + [(-x, y) for x, y in reversed(half[1:])]
    s.flat(apple, 0.93, 1.0, red, outline=ink, ow=0.12)   # cobre o contorno quadrado: o boneco fica redondo
    # sombra atrás: passa da borda de trás do corpo e vai até os "ombros" (esconde o canto quadrado)
    back = [(0.0, -2.08), (0.55, -2.38), (1.2, -2.52), (1.85, -2.29), (2.28, -1.72), (2.44, -0.95),
            (1.7, -0.85), (0.9, -1.12), (0.0, -1.2)]
    s.flat(back + [(-x, y) for x, y in reversed(back[1:-1])], TOP, 0.03, mid)
    s.flat(ellipse(0, -1.55, 0.45, 0.28, n=12), TOP + 0.01, 0.03, dark)
    # talinho e folha
    s.flat(_bar(0.0, -1.45, 0.12, -2.2, 0.11), TOP + 0.03, 0.12, stem, smooth=False)
    s.flat(_capsule(0.12, -2.2, 0.32, -2.8, 0.1, n=5), TOP + 0.03, 0.12, stem, smooth=False)
    lf = [(0.2, -2.35), (0.95, -2.2), (1.85, -2.85), (1.0, -3.15)]
    s.flat(lf, TOP + 0.05, 0.06, leaf, outline=leaf_d, ow=0.06)
    s.flat(_bar(0.3, -2.45, 1.6, -2.85, 0.035), TOP + 0.11, 0.02, leaf_d, smooth=False)
    # brilho suave na curva da lateral esquerda (por cima da borda: arredonda o canto)
    s.flat([(-2.27, -0.65), (-2.2, 0.15), (-1.88, 0.68), (-1.95, 0.12), (-2.07, -0.6)], TOP, 0.03, shine)
    s.flat(ellipse(-2.12, -1.05, 0.08, 0.1, n=8), TOP + 0.01, 0.03, shine)
    # bichinho saindo de um furo no ombro direito
    s.flat(ellipse(2.05, -1.3, 0.2, 0.17, n=10), TOP + 0.04, 0.02, ink)
    for (x, y, r, z) in [(2.15, -1.22, 0.15, 2.05), (2.4, -1.05, 0.16, 2.08), (2.68, -1.0, 0.2, 2.11)]:
        s.flat(ellipse(x, y, r, r, n=10), z, 0.08, leaf, outline=leaf_d, ow=0.04)
    for dy in (0.08, -0.08):
        s.flat(ellipse(2.78, -1.0 + dy, 0.045, 0.045, n=6), 2.2, 0.02, stem)
    # mão: talinho e folhinha no alto
    s.hand_flat(_bar(0.0, 0.05, -0.05, -0.3, 0.06), 1.83, 0.08, stem, smooth=False)
    s.hand_flat([(-0.02, -0.18), (0.25, -0.15), (0.55, -0.5), (0.2, -0.5)], 1.84, 0.05, leaf, outline=leaf_d, ow=0.04)


LOTE = [
    ("cacto", cacto, "#86976B", "#5D6F4C", "#86976B", "#5D6F4C"),
    ("maca", maca, "#B7442D", "#6D2A27", "#B7442D", "#6D2A27"),
]
