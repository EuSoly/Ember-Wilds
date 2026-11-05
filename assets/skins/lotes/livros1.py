# Lote 1 de skins de LIVRO (10 temas). Base em livro_lib.py; regras em docs/guia/skins-modelagem.md.
# Coordenadas relativas ao centro do livro: X = largura (lombada em -X), Y = comprimento (+Y = topo),
# Z para cima, base em z = 0 e capa de cima em z = TOPO (0,53).
# Detalhados (outro objeto no lugar do livro, sem base()): pergaminho, mapa, tabua, paleta, presente.
# Com toque (base() + enfeite passando da borda): floresta, gelo, cristais.
# Simples (base() + desenho plano na capa): lava, melancia.
from livro_lib import *
from mathutils import Matrix

TIPO = "livro"

# ------------------------------------------------------------------ utilidades do lote
# área útil da capa de cima (o canto é chanfrado em 0,08)
CX, CY = LW/2 - 0.08, LL/2 - 0.08


def barra(x1, y1, x2, y2, w, w2=None):
    """Faixa reta de (x1,y1) a (x2,y2), largura w no início e w2 no fim (afunila)."""
    w2 = w if w2 is None else w2
    dx, dy = x2 - x1, y2 - y1; l = math.hypot(dx, dy) or 1
    nx, ny = -dy/l, dx/l
    return [(x1 + nx*w/2, y1 + ny*w/2), (x2 + nx*w2/2, y2 + ny*w2/2),
            (x2 - nx*w2/2, y2 - ny*w2/2), (x1 - nx*w/2, y1 - ny*w/2)]


def trilha(pts, w0, w1):
    """Faixa ao longo de uma polilinha, afinando de w0 a w1 (rachaduras, galhos, rabiscos)."""
    n = len(pts); esq, dir_ = [], []
    for i, (x, y) in enumerate(pts):
        a, b = pts[max(i-1, 0)], pts[min(i+1, n-1)]
        dx, dy = b[0]-a[0], b[1]-a[1]; l = math.hypot(dx, dy) or 1
        w = max(0.01, w0 + (w1 - w0) * i / (n-1)) / 2
        esq.append((x - dy/l*w, y + dx/l*w)); dir_.append((x + dy/l*w, y - dx/l*w))
    return esq + dir_[::-1]


def corta(P, nx, ny, c):
    """Mantém a parte do polígono com nx*x + ny*y <= c (recorte por um semiplano)."""
    out, n = [], len(P)
    for i in range(n):
        a, b = P[i], P[(i+1) % n]
        da, db = nx*a[0] + ny*a[1] - c, nx*b[0] + ny*b[1] - c
        if da <= 0: out.append(a)
        if (da <= 0) != (db <= 0):
            t = da / (da - db); out.append((a[0] + (b[0]-a[0])*t, a[1] + (b[1]-a[1])*t))
    return out


def corta_ret(P, x0=-CX, x1=CX, y0=-CY, y1=CY):
    """Recorta o polígono no retângulo (padrão: a capa de cima)."""
    for nx, ny, c in ((1, 0, x1), (-1, 0, -x0), (0, 1, y1), (0, -1, -y0)):
        P = corta(P, nx, ny, c)
        if len(P) < 3: return None
    return P


def arco(cx, cy, r, w, a0, a1, n=24):
    """Faixa em arco (veios de madeira), ângulos em graus."""
    A = [math.radians(a0 + (a1 - a0) * k / n) for k in range(n + 1)]
    return [(cx + (r + w/2)*math.cos(a), cy + (r + w/2)*math.sin(a)) for a in A] + \
           [(cx + (r - w/2)*math.cos(a), cy + (r - w/2)*math.sin(a)) for a in reversed(A)]


def _eixo(cx, cy, ang):
    a = math.radians(ang); ux, uy = math.cos(a), math.sin(a)
    return lambda t, s: (cx + ux*t - uy*s, cy + uy*t + ux*s)


def ponta(cx, cy, ang, comp, larg):
    """Lasca de cristal vista de cima, saindo de (cx,cy) na direção ang (graus).
    Devolve o corpo e a faceta (metade clara)."""
    p = _eixo(cx, cy, ang)
    corpo = [p(0, -larg/2), p(comp*0.7, -larg/2), p(comp, 0), p(comp*0.7, larg/2), p(0, larg/2)]
    faceta = [p(0, 0), p(comp, 0), p(comp*0.7, larg/2), p(0, larg/2)]
    return corpo, faceta


def cristal(lv, cx, cy, ang, comp, larg, z, cor, clara, contorno, esp=0.07):
    corpo, faceta = ponta(cx, cy, ang, comp, larg)
    lv.flat(corpo, z, esp, cor, outline=contorno, ow=0.04, smooth=False)
    lv.flat(faceta, z + esp + 0.005, 0.01, clara, smooth=False)


def folha(cx, cy, ang, comp, larg):
    """Folha (contorno suavizado) com o cabo em (cx,cy), apontando para ang (graus)."""
    p = _eixo(cx, cy, ang)
    return [p(0, 0), p(comp*0.3, -larg/2), p(comp*0.72, -larg*0.32), p(comp, 0),
            p(comp*0.72, larg*0.32), p(comp*0.3, larg/2)]


def losango(cx, cy, ang, comp, larg):
    p = _eixo(cx, cy, ang)
    return [p(-comp/2, 0), p(0, -larg/2), p(comp/2, 0), p(0, larg/2)]


def cilindro_x(lv, cx, cy, cz, r, comp, cor, seg=24):
    """Cilindro deitado ao longo de X (rolos do pergaminho)."""
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=seg, radius1=r, radius2=r, depth=comp)
    bmesh.ops.rotate(bm, verts=bm.verts, cent=(0, 0, 0), matrix=Matrix.Rotation(math.pi/2, 3, 'Y'))
    bmesh.ops.translate(bm, vec=(lv.ox + cx, lv.oy + cy, cz), verts=bm.verts)
    me = bpy.data.meshes.new("c"); bm.to_mesh(me); bm.free()
    for p in me.polygons: p.use_smooth = len(p.vertices) == 4
    o = bpy.data.objects.new(lv._name("Extra"), me); o.data.materials.append(mat(cor)); lv.coll.objects.link(o)
    return o


def caixa(lv, w, l, z0, h, r, cor):
    """Caixa de cantos arredondados centrada no item (presente)."""
    return lv._caixa(lv._name("Extra"), w, l, z0, h, r, cor)


def _ruido(x, y):
    """Ruído determinístico pela posição (bordas rasgadas iguais nas peças vizinhas)."""
    v = math.sin(x*127.1 + y*311.7) * 43758.5453
    return v - math.floor(v)


# ------------------------------------------------------------------ DETALHADOS

def pergaminho(lv):
    """Folha aberta entre dois rolos, varetas com pontas de metal, fita descendo até um lacre."""
    creme, papel, sombra, borda = "#F9F6D3", "#E1D8BD", "#CFC3AD", "#C2B3A0"
    fita, fita2, metal = "#746559", "#5F4E41", "#878685"
    yR, rR = 1.1, 0.27
    lv.flat([(-1.0, -yR), (1.0, -yR), (1.0, yR), (-1.0, yR)], 0.03, 0.04, creme, outline=borda, ow=0.05, smooth=False)
    # linhas de escrita: faixas largas, sem letras
    for y, x0, x1 in ((0.0, -0.7, 0.7), (-0.3, -0.75, 0.5), (-0.6, -0.7, 0.7)):
        lv.flat(barra(x0, y, x1, y, 0.08), 0.075, 0.01, sombra, smooth=False)
    for s in (1, -1):
        cilindro_x(lv, 0, s*yR, rR, rR, 2.2, papel)          # rolo
        cilindro_x(lv, 0, s*yR, rR, 0.09, 2.5, fita2)         # vareta
        for sx in (1, -1):
            lv.sphere((sx*1.3, s*yR, rR), (0.14, 0.14, 0.14), metal)
    # fita amarrada no rolo de cima, descendo até o lacre
    cilindro_x(lv, 0, yR, rR, rR + 0.03, 0.24, fita)
    for s in (-1, 1):   # pontas da fita abertas para os lados, com corte em V
        p = _eixo(s*0.06, 0.92, -90 + s*32)
        lv.flat([p(0, -0.07), p(0.75, -0.07), p(0.66, 0), p(0.75, 0.07), p(0, 0.07)], 0.08, 0.03, fita, outline=fita2, ow=0.03, smooth=False)
    lv.flat(ellipse(0, 0.55, 0.25, 0.25, n=12), 0.09, 0.06, fita, outline=fita2, ow=0.05)
    lv.flat(ellipse(0, 0.55, 0.12, 0.12, n=8), 0.155, 0.015, fita2)


def mapa(lv):
    """Mapa de papel dobrado em 6 painéis (tons alternados), borda rasgada, trilha tracejada e X."""
    claro, medio, escuro, dobra = "#CBBDAC", "#BDAC98", "#A9937B", "#B7A794"
    tinta = "#5E4632"   # marrom-escuro derivado (trilha e X)
    XE, YE = 1.3, 1.15
    xs, ys = [-XE, -0.43, 0.43, XE], [-YE, 0.0, YE]

    def rasga(x, y):
        dx = (_ruido(x, y) - 0.5)*0.18 if abs(abs(x) - XE) < 1e-6 else 0
        dy = (_ruido(y, x) - 0.5)*0.18 if abs(abs(y) - YE) < 1e-6 else 0
        return (x + dx, y + dy)

    for i in range(3):
        for j in range(2):
            x0, x1, y0, y1 = xs[i], xs[i+1], ys[j], ys[j+1]
            cant = [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]
            P = []
            for k in range(4):
                a, b = cant[k], cant[(k+1) % 4]
                ext = (a[0] == b[0] and abs(abs(a[0]) - XE) < 1e-6) or (a[1] == b[1] and abs(abs(a[1]) - YE) < 1e-6)
                n = 6 if ext else 1
                P += [(a[0] + (b[0]-a[0])*q/n, a[1] + (b[1]-a[1])*q/n) for q in range(n)]
            P = [rasga(x, y) for x, y in P]
            if i == 2 and j == 1:   # canto de cima rasgado na diagonal
                k = math.sqrt(0.5); P = corta(P, k, k, 2.0*k)
            if i == 0 and j == 0:   # pedaço faltando embaixo, perto da lombada
                k = math.sqrt(0.5); P = corta(P, -k, -k, 2.15*k)
            P = offset_poly(P, -0.025)
            lv.flat(P, 0.03, 0.04, claro if (i + j) % 2 == 0 else medio, outline=escuro, ow=0.045, smooth=False)
    z = 0.08
    # montanhas e um lago (formas simples, tons do próprio papel)
    for cx, cy, s in ((-0.95, 0.62, 0.36), (-0.6, 0.72, 0.44)):
        lv.flat([(cx - s/2, cy - s*0.35), (cx + s/2, cy - s*0.35), (cx, cy + s*0.5)], z, 0.01, escuro, smooth=False)
    lv.flat(ellipse(0.9, -0.62, 0.26, 0.17, n=9), z, 0.01, dobra, outline=escuro, ow=0.03)
    # trilha tracejada até o X
    rota = [(-0.95, -0.8), (-0.45, -0.5), (-0.55, 0.0), (-0.1, 0.32), (0.3, -0.1), (0.62, 0.18), (0.78, 0.5)]
    seg = [(rota[k], rota[k+1]) for k in range(len(rota) - 1)]
    tot = sum(math.dist(a, b) for a, b in seg); passo, d = 0.21, 0.0
    while d < tot - 0.05:
        r = d
        for a, b in seg:
            L = math.dist(a, b)
            if r <= L:
                t = r / L; px, py = a[0] + (b[0]-a[0])*t, a[1] + (b[1]-a[1])*t
                ux, uy = (b[0]-a[0])/L, (b[1]-a[1])/L
                lv.flat(barra(px - ux*0.055, py - uy*0.055, px + ux*0.055, py + uy*0.055, 0.075), z, 0.012, tinta, smooth=False)
                break
            r -= L
        d += passo
    xc, yc = 0.86, 0.72
    lv.flat(barra(xc - 0.2, yc - 0.2, xc + 0.2, yc + 0.2, 0.11), z + 0.005, 0.015, tinta, smooth=False)
    lv.flat(barra(xc - 0.2, yc + 0.2, xc + 0.2, yc - 0.2, 0.11), z + 0.005, 0.015, tinta, smooth=False)


def tabua(lv):
    """Tábua de pedra de topo em arco, bordas lascadas, campo rebaixado com 4 sinais inventados."""
    c1, c2, c3, c4, c5, c6, c7 = "#ACB2B0", "#9FA6A4", "#8F9794", "#838D8A", "#6A7774", "#62706C", "#5C6966"
    W, yb, yc = 1.08, -1.32, 0.28

    def contorno(lascas):
        P = [(-W, yb)]
        if lascas: P += [(-0.32, yb), (-0.2, yb + 0.13), (-0.08, yb)]
        P += [(W - 0.22, yb), (W, yb + 0.2)] if lascas else [(W, yb)]
        if lascas: P += [(W, -0.5), (W - 0.15, -0.37), (W, -0.24)]
        P += [(W, yc)]
        for k in range(1, 18):
            a = math.pi * k / 18
            r = W - (0.16 if (lascas and k == 5) else 0)
            P.append((r*math.cos(a), yc + r*math.sin(a)))
        P += [(-W, yc)]
        if lascas: P += [(-W, 0.05), (-W + 0.12, -0.08), (-W, -0.2)]
        return P

    lv.flat(contorno(True), 0.0, 0.3, c2, outline=c7, ow=0.07, smooth=False)
    campo = offset_poly(contorno(False), -0.18)
    lv.flat(campo, 0.305, 0.01, c4, smooth=False)
    z = 0.32
    # rachadura saindo da lasca do arco
    a = math.pi*5/18
    lv.flat(trilha([((W-0.16)*math.cos(a), yc + (W-0.16)*math.sin(a)), (0.74, 0.9), (0.8, 0.74), (0.9, 0.62)], 0.05, 0.015), z, 0.01, c6, smooth=False)
    # sinal 1: anel com ponto
    lv.flat(ellipse(-0.42, 0.55, 0.22, 0.22, n=12), z, 0.01, c7)
    lv.flat(ellipse(-0.42, 0.55, 0.12, 0.12, n=10), z + 0.01, 0.01, c4)
    lv.flat(ellipse(-0.42, 0.55, 0.05, 0.05, n=8), z + 0.02, 0.01, c7)
    # sinal 2: triângulo vazado com traço no meio
    T = [(0.42, 0.8), (0.66, 0.36), (0.18, 0.36)]
    for k in range(3):
        lv.flat(barra(*T[k], *T[(k+1) % 3], 0.08), z, 0.01, c7, smooth=False)
    lv.flat(ellipse(0.42, 0.5, 0.055, 0.055, n=8), z, 0.01, c7)
    # divisória
    lv.flat(barra(-0.68, 0.1, 0.68, 0.1, 0.06), z, 0.01, c6, smooth=False)
    # sinal 3: quadrado vazado com ponto (zigue-zague e haste com galhos pareciam letras/runas reais)
    Q = [(-0.62, -0.53), (-0.22, -0.53), (-0.22, -0.13), (-0.62, -0.13)]
    for k in range(4):
        lv.flat(barra(*Q[k], *Q[(k+1) % 4], 0.08), z, 0.01, c7, smooth=False)
    lv.flat(ellipse(-0.42, -0.33, 0.06, 0.06, n=8), z, 0.01, c7)
    # sinal 4: lua crescente com ponto
    lv.flat(ellipse(0.42, -0.33, 0.23, 0.23, n=14), z, 0.01, c7)
    lv.flat(ellipse(0.5, -0.28, 0.19, 0.19, n=14), z + 0.01, 0.01, c4)
    lv.flat(ellipse(0.53, -0.3, 0.05, 0.05, n=8), z + 0.02, 0.01, c7)
    # fileira de losangos embaixo e um no topo do arco
    for x in (-0.4, 0.0, 0.4):
        lv.flat(losango(x, -0.85, 0, 0.2, 0.16), z, 0.01, c6, smooth=False)
    lv.flat(losango(0, 1.02, 90, 0.24, 0.16), z, 0.01, c6, smooth=False)


def paleta(lv):
    """Paleta de madeira com furo de dedão (aberto por uma fenda), 5 montinhos de tinta e um pincel."""
    madeira, m2, m3, m4, escuro, metal = "#AC805E", "#73583E", "#634433", "#754F3F", "#443123", "#5D5854"
    H, hr, ws = (-0.7, -0.22), 0.23, 0.1          # furo do dedão e meia-largura da fenda
    ts = math.radians(198)                          # direção da fenda (esquerda, um pouco para baixo)

    def borda(t):
        d = (t - ts + math.pi) % (2*math.pi) - math.pi
        f = 1.0 - 0.1*math.exp(-(d/0.45)**2)
        rx = 1.42 if math.cos(t) > 0 else 1.24
        return (rx*math.cos(t)*f, 1.12*math.sin(t)*f)

    dl = ws / 1.1; N = 48
    P = [borda(ts + dl + (2*math.pi - 2*dl)*k/N) for k in range(N + 1)]
    O = borda(ts); phi = math.atan2(O[1] - H[1], O[0] - H[0]); be = math.asin(ws/hr)
    P += [(H[0] + hr*math.cos(a), H[1] + hr*math.sin(a))
          for a in [phi - be - (2*math.pi - 2*be)*k/16 for k in range(17)]]
    lv.flat(P, 0.0, 0.1, madeira, outline=m2, ow=0.06, smooth=False)
    # veios discretos
    lv.flat(arco(0.2, -0.1, 0.62, 0.03, 20, 80), 0.105, 0.005, m4, smooth=False)
    lv.flat(arco(0.2, -0.1, 0.62, 0.03, 250, 310), 0.105, 0.005, m4, smooth=False)
    # montinhos de tinta (cores vivas derivadas)
    tintas = [("#D8402F", "#9E2A1F", (0.0, 0.68)), ("#F2C230", "#B88E1C", (0.7, 0.58)),
              ("#3F7FD6", "#2A5A9E", (1.05, -0.02)), ("#3DAA55", "#2A7A3C", (0.78, -0.6)),
              ("#F4F0E4", "#B9B2A0", (0.35, -0.82))]
    for cor, cor2, (x, y) in tintas:
        pts = [(x + 0.24*(0.85 + 0.3*_ruido(x + k, y))*math.cos(2*math.pi*k/7),
                y + 0.21*(0.85 + 0.3*_ruido(y, x + k))*math.sin(2*math.pi*k/7)) for k in range(7)]
        lv.flat(pts, 0.1, 0.05, cor, outline=cor2, ow=0.035)
        lv.sphere((x - 0.02, y + 0.02, 0.16), (0.13, 0.12, 0.07), cor)
    # pincel atravessado (sai da paleta nas duas pontas)
    A, B = (0.42, -1.48), (-1.28, 0.98)
    def q(t): return (A[0] + (B[0]-A[0])*t, A[1] + (B[1]-A[1])*t)
    z = 0.17
    lv.flat(barra(*q(0.0), *q(0.6), 0.1, 0.16), z, 0.06, m3, outline=escuro, ow=0.035, smooth=False)
    lv.flat(barra(*q(0.6), *q(0.72), 0.2, 0.2), z, 0.07, metal, outline=escuro, ow=0.035, smooth=False)
    p = _eixo(*q(0.72), math.degrees(math.atan2(B[1]-A[1], B[0]-A[0])))
    L = math.dist(q(0.72), B)
    lv.flat([p(0, -0.1), p(L*0.45, -0.12), p(L, 0), p(L*0.45, 0.12), p(0, 0.1)], z, 0.06, m2, outline=escuro, ow=0.035)
    lv.flat([p(L*0.5, -0.115), p(L, 0), p(L*0.5, 0.115), p(L*0.42, 0)], z + 0.065, 0.01, "#D8402F")


def presente(lv):
    """Caixa vermelha com tampa, fita verde em cruz e laço grande (as alças passam da caixa)."""
    v1, v2, v3 = "#AB222A", "#A62229", "#8E191F"
    g1, g2, g3, g4 = "#22A74F", "#20964B", "#1F8A45", "#465032"
    caixa(lv, 2.2, 2.2, 0.0, 0.44, 0.1, v3)            # contorno escuro embaixo
    caixa(lv, 2.08, 2.08, 0.0, 0.5, 0.06, v2)          # corpo
    caixa(lv, 2.26, 2.26, 0.46, 0.16, 0.06, v1)        # tampa
    for w, l in ((0.44, 2.3), (2.3, 0.44)):            # fita em cruz (borda escura + fita)
        caixa(lv, w, l, 0.0, 0.627, 0.02, g3)
    for w, l in ((0.34, 2.32), (2.32, 0.34)):
        caixa(lv, w, l, 0.0, 0.637, 0.02, g1)
    z = 0.64
    # pontas da fita caindo para a frente, com corte em V
    for sx, ang in ((-1, -112), (1, -70)):
        p = _eixo(0, -0.05, ang)
        lv.flat([p(0, -0.15), p(1.45, -0.17), p(1.32, 0), p(1.45, 0.17), p(0, 0.15)], z, 0.04, g2, outline=g3, ow=0.05, smooth=False)
    # alças do laço (passam da borda da caixa) com o miolo escuro
    for ang in (14, 166):
        lv.flat(folha(0, 0.05, ang, 1.5, 0.95), z + 0.03, 0.12, g1, outline=g3, ow=0.06)
        lv.flat(folha(*_eixo(0, 0.05, ang)(0.3, 0), ang, 0.95, 0.3), z + 0.16, 0.01, g3)   # dobra da alça
    lv.flat(ellipse(0, 0.05, 0.24, 0.22, n=10), z + 0.1, 0.1, g2, outline=g3, ow=0.05)


# ------------------------------------------------------------------ LIVROS COM TOQUE

def floresta(lv):
    """Capa de madeira com veios em arco; raminhos com folhas saindo por dois cantos."""
    lv.base()
    claro, veio, galho, galho2 = "#B17D44", "#825230", "#623D2A", "#593227"
    f1, f2 = "#608038", "#465D2E"
    # veios em arco (anéis de um tronco cortado, centro abaixo da capa)
    for r, w, cor in ((0.55, 0.08, veio), (0.95, 0.07, veio), (1.4, 0.08, veio), (1.85, 0.07, veio), (2.3, 0.08, veio)):
        P = corta_ret(arco(0.15, -1.55, r, w, 0, 180, n=40))
        if P: lv.flat(P, TOPO, 0.02, cor, smooth=False)
    lv.flat(corta_ret(arco(0.15, -1.55, 1.17, 0.05, 0, 180, n=40)), TOPO, 0.02, claro, smooth=False)
    z = 0.3
    # canto de cima, lado das páginas: raminho com 3 folhas
    lv.flat(trilha([(0.8, 1.0), (1.3, 1.45), (1.62, 1.62)], 0.13, 0.06), z, 0.06, galho, outline=galho2, ow=0.04, smooth=False)
    for cx, cy, ang, c, l, w in ((1.62, 1.62, 40, f1, 0.8, 0.48), (1.3, 1.45, 100, f2, 0.72, 0.42), (1.32, 1.42, -15, f1, 0.75, 0.44)):
        lv.flat(folha(cx, cy, ang, l, w), z + 0.02, 0.05, c, outline=f2 if c == f1 else galho2, ow=0.04)
    # canto de baixo, lado da lombada: raminho com 2 folhas
    lv.flat(trilha([(-0.8, -1.0), (-1.3, -1.48), (-1.55, -1.6)], 0.13, 0.06), z, 0.06, galho, outline=galho2, ow=0.04, smooth=False)
    for cx, cy, ang, c, l, w in ((-1.5, -1.58, 205, f1, 0.78, 0.46), (-1.3, -1.48, -90, f2, 0.7, 0.4)):
        lv.flat(folha(cx, cy, ang, l, w), z + 0.02, 0.05, c, outline=f2 if c == f1 else galho2, ow=0.04)
    # uma folhinha solta no outro canto de cima (lombada)
    lv.flat(folha(-1.05, 1.2, 135, 0.65, 0.38), z + 0.02, 0.05, f1, outline=f2, ow=0.04)


def gelo(lv):
    """Capa azul-gelo, cantoneiras de cristal com lascas saindo pelos quatro cantos, floco no meio."""
    lv.base()
    claro, medio, contorno, contorno2 = "#A3E2F4", "#57B9DC", "#394565", "#364261"
    for sx in (1, -1):
        for sy in (1, -1):
            ang = math.degrees(math.atan2(sy*LL, sx*LW))
            vira = 1 if sx*sy > 0 else -1
            cx, cy = sx*(LW/2 - 0.12), sy*(LL/2 - 0.12)
            cristal(lv, cx, cy, ang, 0.9, 0.28, TOPO - 0.03, medio, claro, contorno)
            cristal(lv, cx - sx*0.08, cy - sy*0.08, ang + 32*vira, 0.6, 0.22, TOPO - 0.035, medio, claro, contorno)
            # cantoneira (triângulo de gelo sobre o canto da capa)
            k = (sx*LW/2, sy*LL/2)
            lv.flat([k, (k[0] - sx*0.62, k[1]), (k[0], k[1] - sy*0.62)], TOPO + 0.01, 0.04, claro, outline=contorno, ow=0.04, smooth=False)
    # floco de neve: 3 braços cruzados, losangos nas pontas e miolo hexagonal
    z = TOPO + 0.01
    for a in (90, 30, 150):
        p = _eixo(0, 0, a)
        lv.flat(barra(*p(-0.62, 0), *p(0.62, 0), 0.13), z, 0.03, claro, outline=contorno2, ow=0.045, smooth=False)
    for a in range(30, 360, 60):
        p = _eixo(0, 0, a)
        lv.flat(losango(*p(0.6, 0), a, 0.34, 0.24), z + 0.005, 0.03, claro, outline=contorno2, ow=0.045, smooth=False)
        lv.flat(barra(*p(0.36, 0), *_eixo(*p(0.36, 0), a + 50)(0.2, 0), 0.08), z, 0.03, claro, outline=contorno2, ow=0.04, smooth=False)
        lv.flat(barra(*p(0.36, 0), *_eixo(*p(0.36, 0), a - 50)(0.2, 0), 0.08), z, 0.03, claro, outline=contorno2, ow=0.04, smooth=False)
    lv.flat(ellipse(0, 0, 0.2, 0.2, n=6, rot=math.pi/6), z + 0.01, 0.03, medio, outline=contorno2, ow=0.04, smooth=False)


def cristais(lv):
    """Capa verde com gema facetada no meio; aglomerados de cristais claros brotando pela borda."""
    lv.base()
    claro, medio, verde2, contorno = "#DADEDC", "#A1B4AE", "#61A287", "#2C6B51"
    z = 0.28
    grupos = [  # (origem, [(ângulo, comprimento, largura)])
        ((1.0, 0.3), [(-28, 0.85, 0.34), (5, 1.25, 0.42), (38, 0.8, 0.32)]),
        ((-0.7, 1.15), [(95, 1.0, 0.38), (128, 0.7, 0.3), (70, 0.6, 0.26)]),
        ((0.4, -1.15), [(-68, 1.1, 0.4), (-102, 0.72, 0.3), (-38, 0.65, 0.28)]),
        ((-1.0, -0.55), [(192, 0.75, 0.3), (222, 0.55, 0.24)]),
    ]
    for (ox, oy), lista in grupos:
        for ang, c, w in sorted(lista, key=lambda t: t[1]):
            cristal(lv, ox, oy, ang, c, w, z, medio, claro, contorno, esp=0.09)
            z += 0.004
    # gema facetada no meio da capa
    g = ellipse(0, 0, 0.42, 0.5, n=6, rot=math.pi/2)
    lv.flat(g, TOPO, 0.04, verde2, outline=contorno, ow=0.05, smooth=False)
    lv.flat([(0, 0), g[0], g[1], g[2]], TOPO + 0.045, 0.01, medio, smooth=False)
    lv.flat([(0, 0), g[0], g[1]], TOPO + 0.055, 0.01, claro, smooth=False)


# ------------------------------------------------------------------ LIVROS SIMPLES

def lava(lv):
    """Capa de rocha escura com placas e rachaduras de lava (laranja brilhando)."""
    lv.base()
    placa, halo, lava_c = "#453022", "#763015", "#E88401"
    # placas de rocha um pouco mais claras
    for pts in ([(-0.85, 1.15), (-0.2, 1.18), (-0.35, 0.9), (-0.75, 0.88)],
                [(0.35, 0.95), (0.95, 0.75), (0.85, 0.5), (0.45, 0.55)],
                [(-0.7, -0.15), (-0.25, -0.2), (-0.35, -0.5), (-0.8, -0.45)],
                [(0.45, -0.25), (0.95, -0.35), (0.85, -0.75), (0.5, -0.6)]):
        lv.flat(pts, TOPO, 0.015, placa)
    rachas = [
        ([(-1.15, 1.25), (-0.55, 0.72), (-0.2, 0.78), (0.15, 0.22), (0.0, -0.4), (0.35, -0.88), (1.0, -1.28)], 0.16, 0.05),
        ([(0.15, 0.22), (0.6, 0.32), (0.82, 0.78), (1.15, 1.05)], 0.12, 0.04),
        ([(0.0, -0.4), (-0.5, -0.65), (-0.75, -1.05), (-1.15, -1.2)], 0.12, 0.04),
        ([(-0.55, 0.72), (-0.95, 0.32), (-1.15, 0.25)], 0.09, 0.03),
    ]
    for pts, w0, w1 in rachas:
        P = corta_ret(trilha(pts, w0 + 0.12, w1 + 0.08))
        if P: lv.flat(P, TOPO + 0.005, 0.015, halo, smooth=False)
    for pts, w0, w1 in rachas:
        P = corta_ret(trilha(pts, w0, w1))
        if P: lv.flat(P, TOPO + 0.01, 0.02, lava_c, smooth=False, emit=2.0)
    for x, y, r in ((0.15, 0.22, 0.13), (0.0, -0.4, 0.12)):
        lv.flat(ellipse(x, y, r, r*0.9, n=8), TOPO + 0.012, 0.02, lava_c, emit=2.0)


def melancia(lv):
    """Casca listrada de verdes na capa; páginas vermelhas de polpa com sementes nas laterais."""
    lv.base()
    listra, polpa = "#1C5C20", "#8B170B"
    semente = "#2B1A14"   # quase preto derivado (sementes)
    for k, x in enumerate((-0.82, -0.3, 0.22, 0.74)):
        esq, dir_ = [], []
        for q in range(27):
            y = -1.35 + 2.7*q/26
            c = x + 0.07*math.sin(3.2*y + k*1.7)
            w = 0.13 + 0.05*math.sin(5.0*y + k*2.3)
            esq.append((c - w, y)); dir_.append((c + w, y))
        P = corta_ret(esq + dir_[::-1])
        if P: lv.flat(P, TOPO, 0.02, listra, smooth=False)
    # sementes nas faces das páginas (frente, trás e lado +X), um tico para fora da face
    yF, xF = LL/2 - PAG_IN + 0.02, LW/2 - PAG_IN*0.5 + 0.02
    for i, x in enumerate((-0.8, -0.4, 0.0, 0.4, 0.8)):
        lv.sphere((x, yF, 0.2 if i % 2 else 0.32), (0.075, 0.03, 0.045), semente)
        lv.sphere((x, -yF, 0.2 if i % 2 else 0.32), (0.075, 0.03, 0.045), semente)
    for i, y in enumerate((-0.9, -0.45, 0.0, 0.45, 0.9)):
        lv.sphere((xF, y, 0.32 if i % 2 else 0.2), (0.03, 0.075, 0.045), semente)


LOTE = [
    ("pergaminho", pergaminho, "#F9F6D3", "#C2B3A0"),
    ("mapa", mapa, "#CBBDAC", "#A9937B"),
    ("tabua", tabua, "#9FA6A4", "#5C6966"),
    ("paleta", paleta, "#AC805E", "#73583E"),
    ("presente", presente, "#AB222A", "#22A74F"),
    ("floresta", floresta, "#9E6637", "#593227", "#F2E6C9", "#623D2A"),
    ("gelo", gelo, "#568DAB", "#232E49", "#A3E2F4", "#496482"),
    ("cristais", cristais, "#35986F", "#2C6B51", "#DADEDC", "#2C6B51"),
    ("lava", lava, "#35251A", "#2D2017", "#6C3F1E", "#2D2017"),
    ("melancia", melancia, "#378839", "#18501B", "#B8301C", "#1C5B1F"),   # páginas: polpa (#8B170B mais claro: a face fica na sombra)
]
