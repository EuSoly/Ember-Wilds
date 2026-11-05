# Lote 2 de skins de LIVRO (10 temas). Base em livro_lib.py; regras em docs/guia/skins-modelagem.md.
# Coordenadas relativas ao centro do livro: X = largura (lombada em -X), Y = comprimento (+Y = topo),
# Z para cima, base em z = 0 e capa de cima em z = TOPO (0,53). A lombada fica 0,012 acima da capa,
# então o desenho da capa começa em ZC = TOPO + 0,012.
# Detalhados (sem base()): envelope, pinheiro, orbe, bussola, aberto.
# Com toque (base() + enfeite passando da borda): tentaculo, engrenagem, trepadeira.
# Simples (base() + desenho plano na capa): cogumelo, ondas.
from livro_lib import *
# utilidades do lote 1 (faixas, recortes, folhas...)
from livros1 import barra, trilha, corta, corta_ret, arco, _eixo, folha, losango, _ruido, CX, CY

TIPO = "livro"
ZC = TOPO + 0.012


# ------------------------------------------------------------------ utilidades do lote

def suave(pts, per=6):
    """Curva aberta suavizada (Catmull-Rom) passando pelos pontos."""
    P = [pts[0]] + list(pts) + [pts[-1]]
    out = []
    for i in range(1, len(P) - 2):
        p0, p1, p2, p3 = P[i-1], P[i], P[i+1], P[i+2]
        for k in range(per):
            t = k / per; t2, t3 = t*t, t*t*t
            out.append(tuple(0.5 * (2*p1[j] + (-p0[j]+p2[j])*t + (2*p0[j]-5*p1[j]+4*p2[j]-p3[j])*t2
                                    + (-p0[j]+3*p1[j]-3*p2[j]+p3[j])*t3) for j in (0, 1)))
    out.append(tuple(pts[-1]))
    return out


def espiral(cx, cy, r0, r1, voltas, a0=0.0, n=40):
    return [(cx + (r0 + (r1-r0)*k/n)*math.cos(a0 + voltas*2*math.pi*k/n),
             cy + (r0 + (r1-r0)*k/n)*math.sin(a0 + voltas*2*math.pi*k/n)) for k in range(n + 1)]


def estrela(cx, cy, R, r, pontas=5, rot=90):
    P = []
    for k in range(2*pontas):
        a = math.radians(rot) + math.pi*k/pontas; rr = R if k % 2 == 0 else r
        P.append((cx + rr*math.cos(a), cy + rr*math.sin(a)))
    return P


def coracao(cx, cy, s, n=28):
    P = []
    for k in range(n):
        t = 2*math.pi*k/n
        x = math.sin(t)**3
        y = (13*math.cos(t) - 5*math.cos(2*t) - 2*math.cos(3*t) - math.cos(4*t)) / 16
        P.append((cx + s*x, cy + s*(y + 0.3)))
    return P


def engrenagem_pts(cx, cy, r, dentes, h=0.13, rot=0.0):
    P, d = [], 2*math.pi/dentes
    for k in range(dentes):
        a = rot + d*k
        for f, rr in ((-0.3, r - h), (-0.16, r), (0.16, r), (0.3, r - h)):
            P.append((cx + rr*math.cos(a + f*d), cy + rr*math.sin(a + f*d)))
    return P


def ret_arred(w, l, r, cx=0.0, cy=0.0, n=4):
    """Retângulo de cantos arredondados (contorno para flat com smooth=False)."""
    P = []
    for (sx, sy, a0) in ((1, 1, 0), (-1, 1, 90), (-1, -1, 180), (1, -1, 270)):
        ccx, ccy = cx + sx*(w/2 - r), cy + sy*(l/2 - r)
        for k in range(n + 1):
            a = math.radians(a0 + 90*k/n); P.append((ccx + r*math.cos(a), ccy + r*math.sin(a)))
    return P


# ------------------------------------------------------------------ DETALHADOS

def envelope(lv):
    """Carta fechada: aba de cima em triângulo, aba de baixo, lacre de cera com coração."""
    papel, papel2, lilas, roxo, roxo2, roxo3 = "#F2EDEC", "#F2ECEB", "#B35EA7", "#782493", "#771D93", "#762B90"
    W, H = 1.42, 1.0
    lv.flat(ret_arred(2*W, 2*H, 0.08), 0.0, 0.1, papel, outline=lilas, ow=0.07, smooth=False)
    # abas: de baixo (triângulo baixo) e de cima (triângulo que desce até o lacre)
    lv.flat([(-W + 0.06, -H + 0.06), (W - 0.06, -H + 0.06), (0, 0.02)], 0.1, 0.02, papel2, outline=lilas, ow=0.03, smooth=False)
    lv.flat([(-W + 0.04, H - 0.04), (0, -0.22), (W - 0.04, H - 0.04)], 0.13, 0.03, papel, outline=lilas, ow=0.045, smooth=False)
    # lacre de cera com coração em relevo
    cera = [(0.4*(0.9 + 0.2*_ruido(k, 3.1))*math.cos(2*math.pi*k/9), -0.22 + 0.38*(0.9 + 0.2*_ruido(2.7, k))*math.sin(2*math.pi*k/9)) for k in range(9)]
    lv.flat(cera, 0.17, 0.06, roxo, outline=roxo3, ow=0.05)
    lv.flat(ellipse(0, -0.22, 0.31, 0.31, n=12), 0.235, 0.01, roxo2)
    lv.flat(coracao(0, -0.25, 0.25), 0.245, 0.03, lilas, smooth=False)


def pinheiro(lv):
    """Pinheirinho deitado em 3 camadas (silhueta), bolinhas vermelhas, luzinhas e estrela amarela."""
    v1, v2, cont = "#109933", "#1A802A", "#016814"
    luz1, luz2, bola = "#98CD97", "#DBEFC1", "#B13126"
    ouro, ouro2 = "#F4D35E", "#B8902A"         # estrela (amarelo derivado)
    tronco, tronco2 = "#6B4A2B", "#3E2A18"     # tronco (marrom derivado)
    lv.flat(barra(0, -1.0, 0, -1.48, 0.38), 0.0, 0.1, tronco, outline=tronco2, ow=0.05, smooth=False)

    def camada(y0, y1, w, n):
        P = [(0, y1), (w*0.5 - 0.04, (y0 + y1)/2), (w, y0)]
        for k in range(n):                          # borda de baixo em arcos
            xa, xb = w - 2*w*k/n, w - 2*w*(k+1)/n
            for q in (0.25, 0.5, 0.75):
                x = xa + (xb - xa)*q
                P.append((x, y0 - 0.13*math.sin(math.pi*q)))
            P.append((xb, y0))
        P.append((-w*0.5 + 0.04, (y0 + y1)/2))
        return P

    camadas = [(-1.0, 0.45, 1.32, 4, 0.08), (-0.38, 0.98, 1.02, 3, 0.2), (0.22, 1.42, 0.72, 2, 0.32)]
    for y0, y1, w, n, z in camadas:
        P = camada(y0, y1, w, n)
        lv.flat(P, z, 0.12, v2, outline=cont, ow=0.06, smooth=False)
        claro = corta(offset_poly(P, -0.08), -1, 0, 0.0)      # metade iluminada (direita)
        lv.flat(claro, z + 0.125, 0.01, v1, smooth=False)
    # bolinhas e luzinhas em cada camada
    for x, y, z in ((-0.85, -0.78, 0.2), (0.15, -0.88, 0.2), (0.9, -0.72, 0.2),
                    (-0.6, -0.2, 0.33), (0.5, -0.15, 0.33), (0.0, 0.42, 0.45)):
        lv.sphere((x, y, z + 0.06), (0.15, 0.15, 0.12), bola)
    for x, y, z, c in ((-0.35, -0.6, 0.2, luz2), (0.55, -0.55, 0.2, luz1), (-0.1, -0.05, 0.33, luz2),
                       (0.25, 0.55, 0.45, luz1), (-0.25, 0.7, 0.45, luz2)):
        lv.flat(ellipse(x, y, 0.07, 0.07, n=8), z + 0.135, 0.02, c)
    lv.flat(estrela(0, 1.45, 0.4, 0.17), 0.46, 0.08, ouro, outline=ouro2, ow=0.05, smooth=False)


def orbe(lv):
    """Pedra mágica lisa de contorno orgânico, em degraus de tom, com espiral lilás brilhando."""
    escuro, c1, c2, c3, lilas = "#242845", "#2B3253", "#2F365B", "#333B62", "#6961AD"
    pts = []
    for k in range(14):
        t = 2*math.pi*k/14
        r = 1.0 + 0.07*math.sin(3*t + 0.5) + 0.05*math.sin(5*t + 1.2)
        pts.append((1.1*r*math.cos(t), 1.22*r*math.sin(t)))
    lv.flat(pts, 0.0, 0.3, c1, outline=escuro, ow=0.08)
    lv.flat([(x*0.82 - 0.05, y*0.82 + 0.07) for x, y in pts], 0.3, 0.04, c2)
    lv.flat([(x*0.55 - 0.12, y*0.55 + 0.16) for x, y in pts], 0.34, 0.03, c3)
    lv.flat(trilha(espiral(0.0, 0.02, 0.05, 0.66, 1.75, a0=1.0), 0.06, 0.15), 0.375, 0.02, lilas, smooth=False, emit=1.5)
    for a in (100, 220, 340):
        x, y = 0.88*math.cos(math.radians(a)), 1.0*math.sin(math.radians(a))
        lv.flat(ellipse(x, y, 0.07, 0.07, n=8), 0.34, 0.02, lilas, emit=1.5)


def bussola(lv):
    """Bússola redonda com a tampa aberta ao lado (dobradiça), rosa dos ventos e agulha vermelha/creme."""
    c1, c2, c3, c4, c5, c6, c7 = "#6E4720", "#5E3E1A", "#583B19", "#4C3518", "#433117", "#3D2E16", "#392C16"
    verm, creme = "#C8352B", "#EFE3C2"   # agulha (derivados)
    d = (math.cos(math.radians(50)), math.sin(math.radians(50)))
    C = (-0.51, -0.62); L = (C[0] + 1.7*d[0], C[1] + 1.7*d[1])
    # dobradiça entre a caixa e a tampa
    a, b = (C[0] + 0.7*d[0], C[1] + 0.7*d[1]), (L[0] - 0.64*d[0], L[1] - 0.64*d[1])
    lv.flat(barra(*a, *b, 0.3), 0.04, 0.1, c4, outline=c7, ow=0.05, smooth=False)
    # tampa aberta (vista por dentro)
    lv.flat(ellipse(*L, 0.76, 0.76, n=16), 0.0, 0.14, c2, outline=c7, ow=0.07)
    lv.flat(ellipse(*L, 0.62, 0.62, n=16), 0.14, 0.02, c5)
    lv.flat(ellipse(*L, 0.4, 0.4, n=14), 0.16, 0.01, c3)
    lv.flat(ellipse(*L, 0.33, 0.33, n=14), 0.17, 0.01, c5)
    lv.flat(losango(*L, 50, 0.3, 0.2), 0.18, 0.01, c1, smooth=False)
    # caixa: aro, botão da coroa, mostrador, rosa dos ventos, agulha
    lv.sphere((C[0] + 0.86*d[0], C[1] + 0.86*d[1], 0.16), (0.13, 0.13, 0.11), c1)
    lv.flat(ellipse(*C, 0.82, 0.82, n=16), 0.0, 0.26, c1, outline=c7, ow=0.08)
    lv.flat(ellipse(*C, 0.7, 0.7, n=16), 0.26, 0.02, c3)
    lv.flat(ellipse(*C, 0.62, 0.62, n=16), 0.28, 0.02, c6)
    lv.flat(estrela(*C, 0.32, 0.07, pontas=4, rot=45), 0.3, 0.01, c4, smooth=False)
    lv.flat(estrela(*C, 0.55, 0.1, pontas=4, rot=90), 0.31, 0.01, c1, smooth=False)
    p = _eixo(*C, 118)
    lv.flat([p(0.55, 0), p(0, 0.1), p(0, -0.1)], 0.33, 0.03, verm, outline=c7, ow=0.03, smooth=False)
    lv.flat([p(-0.48, 0), p(0, -0.1), p(0, 0.1)], 0.33, 0.03, creme, outline=c7, ow=0.03, smooth=False)
    lv.sphere((C[0], C[1], 0.37), (0.07, 0.07, 0.05), c7)


def aberto(lv):
    """Livro aberto: capa por baixo, duas páginas de borda curva, faixas de texto e fita marcadora."""
    p1, p2, p3, p4, p5, capa, capa2 = "#C09D6F", "#BC9869", "#B48E5D", "#AA824D", "#A37943", "#51391F", "#2C2112"
    lv.flat(ret_arred(3.4, 2.5, 0.1), 0.0, 0.08, capa, outline=capa2, ow=0.06, smooth=False)

    def pagina(s, enc=0.0):
        xs = [s*(0.03 + 1.57*k/12) for k in range(13)]
        top = [(x, 1.06 + 0.1*math.sin(math.pi*abs(x)/1.6) - enc) for x in xs]
        bot = [(x, -1.06 - 0.06*math.sin(math.pi*abs(x)/1.6) + enc) for x in reversed(xs)]
        P = top + bot
        return P if s > 0 else P[::-1]

    for s in (-1, 1):
        lv.flat(pagina(s), 0.08, 0.14, p3, outline=p4, ow=0.03, smooth=False)       # bloco de folhas
        lv.flat(offset_poly(pagina(s, 0.0), -0.05), 0.22, 0.03, p1, smooth=False)   # folha de cima
        # faixas de "texto"
        for k, y in enumerate((0.72, 0.45, 0.18, -0.09, -0.36, -0.63)):
            x0, x1 = 0.32, 1.35 - (0.35 if k in (2, 5) else 0.0)
            lv.flat(barra(s*x0, y, s*x1, y, 0.08), 0.255, 0.01, p5, smooth=False)
    # sombra do meio (dobra das páginas)
    lv.flat(ret_arred(0.36, 2.2, 0.05), 0.252, 0.005, p2, smooth=False)
    lv.flat(ret_arred(0.12, 2.18, 0.03), 0.257, 0.006, p4, smooth=False)
    # fita marcadora: desce do topo do miolo e sai pela borda de baixo
    lv.flat(trilha(suave([(0.08, 1.0), (0.2, 0.2), (0.3, -0.7), (0.42, -1.5)], 4), 0.16, 0.16), 0.27, 0.02, capa, outline=capa2, ow=0.03, smooth=False)
    p = _eixo(0.42, -1.5, -82)
    lv.flat([p(-0.05, -0.08), p(0.2, -0.09), p(0.13, 0), p(0.2, 0.09), p(-0.05, 0.08)], 0.27, 0.02, capa, outline=capa2, ow=0.03, smooth=False)


# ------------------------------------------------------------------ LIVROS COM TOQUE

def tentaculo(lv):
    """Livro azul-marinho: tentáculo com ventosas sai pela lombada, dá a volta e abraça a capa; redemoinho claro."""
    lv.base()
    claro, fundo2, polvo, polvo2 = "#5D9EB2", "#00395B", "#501C4A", "#081D30"
    ventosa = "#8E4F86"   # lilás claro derivado do #501C4A (ventosas)
    # redemoinho
    lv.flat(trilha(espiral(-0.35, 0.5, 0.06, 0.55, 1.6, a0=0.5), 0.06, 0.13), ZC, 0.02, claro, smooth=False)
    lv.flat(corta_ret(arco(-0.35, 0.5, 0.75, 0.05, 150, 300)), ZC, 0.02, fundo2, smooth=False)
    # tentáculo (afinando da lombada até a ponta enrolada)
    ctrl = [(-1.1, -0.05), (-1.62, -0.3), (-1.72, -0.9), (-1.2, -1.2), (-0.4, -0.92), (0.4, -0.66),
            (1.05, -0.22), (1.38, 0.4), (1.08, 0.95), (0.58, 1.0), (0.4, 0.7), (0.62, 0.52)]
    C = suave(ctrl, 6)
    w0, w1 = 0.44, 0.07
    lv.flat(trilha(C, w0, w1), ZC + 0.01, 0.06, polvo, outline=polvo2, ow=0.05, smooth=False)
    n = len(C)
    for i in range(3, n - 4, 4):
        a, b = C[i-1], C[i+1]
        dx, dy = b[0]-a[0], b[1]-a[1]; l = math.hypot(dx, dy) or 1
        w = w0 + (w1 - w0)*i/(n-1)
        # ventosas do lado de dentro da curva
        x, y = C[i][0] - dy/l*w*0.18, C[i][1] + dx/l*w*0.18
        lv.flat(ellipse(x, y, w*0.26, w*0.22, n=8, rot=math.atan2(dy, dx)), ZC + 0.075, 0.015, ventosa)


def engrenagem(lv):
    """Livro de couro com cantoneiras em engrenagem saindo pelos cantos e engrenagem grande no meio."""
    lv.base()
    metal, couro2, cubo, escuro, escuro2 = "#B58E55", "#7E4E19", "#66481B", "#4D3818", "#402C12"
    # costura de couro (moldura)
    lv.flat(offset_poly(ret_arred(LW - 0.5, LL - 0.5, 0.1), 0.0), ZC, 0.015, couro2, smooth=False)
    lv.flat(ret_arred(LW - 0.62, LL - 0.62, 0.08), ZC + 0.005, 0.015, lv.capa, smooth=False)
    for sx in (1, -1):
        for sy in (1, -1):
            cx, cy = sx*(LW/2 - 0.08), sy*(LL/2 - 0.08)
            lv.flat(engrenagem_pts(cx, cy, 0.52, 9, h=0.14, rot=0.2*sx*sy), ZC + 0.02, 0.05, metal, outline=escuro2, ow=0.04, smooth=False)
            lv.flat(ellipse(cx, cy, 0.2, 0.2, n=10), ZC + 0.075, 0.015, cubo)
            lv.flat(ellipse(cx, cy, 0.09, 0.09, n=8), ZC + 0.09, 0.015, metal)
    # engrenagem grande no meio e uma pequena engatada
    lv.flat(engrenagem_pts(-0.08, 0.18, 0.72, 12, h=0.16), ZC + 0.02, 0.05, metal, outline=escuro2, ow=0.05, smooth=False)
    lv.flat(ellipse(-0.08, 0.18, 0.4, 0.4, n=16), ZC + 0.075, 0.015, escuro)
    lv.flat(ellipse(-0.08, 0.18, 0.17, 0.17, n=12), ZC + 0.09, 0.015, metal)
    lv.flat(engrenagem_pts(0.52, -0.72, 0.36, 8, h=0.12, rot=0.2), ZC + 0.02, 0.05, metal, outline=escuro2, ow=0.04, smooth=False)
    lv.flat(ellipse(0.52, -0.72, 0.12, 0.12, n=10), ZC + 0.075, 0.015, cubo)


def trepadeira(lv):
    """Livro verde-escuro envolvido por trepadeiras com folhas (passam da borda) e duas florzinhas."""
    lv.base()
    galho, galho2, f1, f2, contorno = "#563D26", "#402B1E", "#096D41", "#829639", "#0E3D26"
    petala = "#F1E4C4"   # creme derivado (pétalas)
    ramos = [
        [(-1.65, -1.3), (-0.95, -0.95), (-0.3, -0.35), (0.3, -0.05), (0.95, 0.15), (1.45, 0.5), (1.38, 0.95), (1.08, 0.92)],
        [(-1.55, 1.6), (-0.85, 1.08), (-0.2, 0.92), (0.4, 1.18), (0.85, 1.6)],
    ]
    folhas = []
    for r, ctrl in enumerate(ramos):
        C = suave(ctrl, 6)
        lv.flat(trilha(C, 0.12, 0.06), ZC + 0.01, 0.04, galho, outline=galho2, ow=0.035, smooth=False)
        for k, i in enumerate(range(3, len(C) - 2, 5)):
            a, b = C[i-1], C[i+1]
            ang = math.degrees(math.atan2(b[1]-a[1], b[0]-a[0])) + (65 if k % 2 else -65)
            folhas.append((C[i], ang, f1 if (k + r) % 2 else f2))
    for (x, y), ang, cor in folhas:
        lv.flat(folha(x, y, ang, 0.5, 0.32), ZC + 0.06, 0.03, cor, outline=contorno, ow=0.035)
    for x, y in ((0.3, -0.05), (-0.2, 0.92)):
        for k in range(5):
            a = 2*math.pi*k/5 + 0.3
            lv.flat(ellipse(x + 0.13*math.cos(a), y + 0.13*math.sin(a), 0.11, 0.11, n=8), ZC + 0.1, 0.02, petala, outline=galho2, ow=0.025)
        lv.flat(ellipse(x, y, 0.08, 0.08, n=8), ZC + 0.125, 0.02, f2)


# ------------------------------------------------------------------ LIVROS SIMPLES

def cogumelo(lv):
    """Capa marrom-escura com um cogumelo laranja grande pintado (chapéu com pintas, pé claro)."""
    lv.base()
    lar1, lar2, lar3, escuro = "#CA780E", "#FB9A03", "#FFAF35", "#310E00"
    # pé
    pe = [(-0.26, 0.0), (0.26, 0.0), (0.3, -0.7), (0.42, -0.98), (-0.42, -0.98), (-0.3, -0.7)]
    lv.flat(pe, ZC, 0.02, lar2, outline=lar1, ow=0.04)
    # chapéu em cúpula
    cap = [(math.cos(math.pi*k/16)*0.95, 0.05 + math.sin(math.pi*k/16)*0.98) for k in range(17)]
    cap += [(-0.6, -0.12), (0.0, -0.08), (0.6, -0.12)]
    lv.flat(cap, ZC + 0.02, 0.025, lar1, outline=escuro, ow=0.04, smooth=False)
    lv.flat(barra(-0.8, 0.0, 0.8, 0.0, 0.07), ZC + 0.047, 0.01, lar2, smooth=False)
    for x, y, r in ((-0.45, 0.45, 0.17), (0.12, 0.72, 0.15), (0.55, 0.32, 0.13), (-0.08, 0.3, 0.09), (-0.68, 0.18, 0.08)):
        lv.flat(ellipse(x, y, r, r*0.9, n=10), ZC + 0.047, 0.015, lar3)
    # pintinhas na capa ao redor
    for x, y in ((0.75, 0.95), (-0.7, -0.8), (0.75, -0.6), (-0.8, 0.95)):
        lv.flat(ellipse(x, y, 0.06, 0.06, n=8), ZC, 0.015, lar1)


def ondas(lv):
    """Capa azul com céu claro, sol amarelo pequeno e três faixas de ondas com crista branca."""
    lv.base()
    claro, ceu, medio, fundo, branco, sol = "#6DE0F4", "#BBE6DC", "#4488A1", "#094367", "#FFFFFF", "#F8E671"
    lv.flat([(-CX, -CY), (CX, -CY), (CX, CY), (-CX, CY)], ZC, 0.012, ceu, smooth=False)
    lv.flat(ellipse(0.55, 0.85, 0.24, 0.24, n=14), ZC + 0.012, 0.012, sol)
    z = ZC + 0.012
    for yb, amp, fase, cor in ((0.45, 0.09, 0.0, claro), (-0.15, 0.1, 1.6, medio), (-0.72, 0.1, 3.1, fundo)):
        topo = [(-CX + 2*CX*k/24, yb + amp*math.sin(4.2*(-CX + 2*CX*k/24) + fase)) for k in range(25)]
        lv.flat(topo + [(CX, -CY), (-CX, -CY)], z, 0.012, cor, smooth=False)
        lv.flat(trilha(topo, 0.07, 0.07), z + 0.012, 0.006, branco, smooth=False)
        z += 0.012


LOTE = [
    ("envelope", envelope, "#F2EDEC", "#B35EA7"),
    ("pinheiro", pinheiro, "#109933", "#016814"),
    ("orbe", orbe, "#2F365B", "#242845"),
    ("bussola", bussola, "#6E4720", "#392C16"),
    ("aberto", aberto, "#C09D6F", "#51391F"),
    ("tentaculo", tentaculo, "#003754", "#051E31", "#5D9EB2", "#002336"),
    ("engrenagem", engrenagem, "#A06620", "#402C12", "#B58E55", "#7E4E19"),
    ("trepadeira", trepadeira, "#1C4027", "#0E3D26", "#829639", "#0E3D26"),
    ("cogumelo", cogumelo, "#461300", "#310E00", "#5B1800", "#310E00"),
    ("ondas", ondas, "#4488A1", "#094367", "#BBE6DC", "#094367"),
]
