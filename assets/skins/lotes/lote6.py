# Lote 6 — skins de corpo (detalhadas). Montar com build_skins.py (Blender aberto) ou render_lote.py (segundo plano).
# gárgula, ouriço-do-mar, carneiro, espírito de gelo, arbusto florido, wyvern de gelo, gaio-azul, zumbi, mago, pão.
from skin_lib import *


# ---------------------------------------------------------------- ajudantes do lote (cópias dos do lote 5 + novos)
def _pol(a, r, cx=0.0, cy=0.0):
    return (cx + math.cos(a) * r, cy + math.sin(a) * r)

def _raio_corpo(a, folga=0.0):
    # raio da borda do corpo (quadrado arredondado ~ superelipse) no ângulo a
    c, s_ = abs(math.cos(a)), abs(math.sin(a))
    return 1.85 / (c**4 + s_**4) ** 0.25 + folga

def _local(x0, y0, ang):
    # sistema local: u ao longo de ang, v para a esquerda
    ca, sa = math.cos(ang), math.sin(ang)
    return lambda u, v: (x0 + ca*u - sa*v, y0 + sa*u + ca*v)

def _curva(ctrl, per=6):
    # curva aberta (Catmull-Rom) passando pelos pontos de controle
    P = [ctrl[0]] + list(ctrl) + [ctrl[-1]]
    out = []
    for i in range(1, len(P) - 2):
        p0, p1, p2, p3 = P[i-1], P[i], P[i+1], P[i+2]
        for k in range(per):
            t = k / per; t2, t3 = t*t, t*t*t
            out.append(tuple(0.5 * (2*p1[j] + (-p0[j]+p2[j])*t + (2*p0[j]-5*p1[j]+4*p2[j]-p3[j])*t2
                                    + (-p0[j]+3*p1[j]-3*p2[j]+p3[j])*t3) for j in (0, 1)))
    out.append(tuple(ctrl[-1]))
    return out

def _tubo(c, wf, t0=0.0, t1=1.0, cap0=False, cap1=False, n=24):
    # faixa ao longo da linha c (meia-largura wf(t)); pedaço de t0 a t1, pontas redondas opcionais
    L = [0.0]
    for a, b in zip(c, c[1:]): L.append(L[-1] + math.dist(a, b))
    tot = L[-1]
    def pos(t):
        d = min(max(t, 0.0), 1.0) * tot
        for i in range(len(c) - 1):
            if d <= L[i+1] or i == len(c) - 2:
                seg = (L[i+1] - L[i]) or 1e-9
                u = min(max((d - L[i]) / seg, 0.0), 1.0)
                return (c[i][0] + (c[i+1][0] - c[i][0])*u, c[i][1] + (c[i+1][1] - c[i][1])*u)
    def tang(t):
        a, b = pos(t - 0.012), pos(t + 0.012)
        dx, dy = b[0] - a[0], b[1] - a[1]; l = math.hypot(dx, dy) or 1
        return dx / l, dy / l
    esq, dir_ = [], []
    for k in range(n + 1):
        t = t0 + (t1 - t0) * k / n
        (x, y), (dx, dy), w = pos(t), tang(t), max(wf(t), 0.01)
        esq.append((x - dy*w, y + dx*w)); dir_.append((x + dy*w, y - dx*w))
    fim, ini = [], []
    if cap1:
        (x, y), (dx, dy), w = pos(t1), tang(t1), max(wf(t1), 0.01)
        for k in range(1, 6):
            th = math.pi * k / 6
            fim.append((x + w*(-dy*math.cos(th) + dx*math.sin(th)), y + w*(dx*math.cos(th) + dy*math.sin(th))))
    if cap0:
        (x, y), (dx, dy), w = pos(t0), tang(t0), max(wf(t0), 0.01)
        for k in range(1, 6):
            th = math.pi * k / 6
            ini.append((x + w*(dy*math.cos(th) - dx*math.sin(th)), y + w*(-dx*math.cos(th) - dy*math.sin(th))))
    return esq + fim + list(reversed(dir_)) + ini

def _radial(rf, n=56, cx=0.0, cy=0.0, maos=0.0):
    # contorno r = rf(a) em volta de (cx, cy); com maos > 0 abre um recorte em volta de cada mão
    out = []
    for i in range(n):
        a = 2*math.pi*i/n; ux, uy = math.cos(a), math.sin(a)
        r = rf(a)
        if maos:
            for hx in (HX, -HX):
                px, py = hx - cx, HY - cy
                b = ux*px + uy*py; disc = b*b - (px*px + py*py - maos*maos)
                if disc >= 0 and b > 0:
                    r = min(r, b - math.sqrt(disc))
        out.append((cx + ux*r, cy + uy*r))
    return out

def _blob(cx, cy, r, n=12, wob=0.08, seed=0, sx=1.0, sy=1.0):
    # elipse irregular (pintas, pedras)
    return [(cx + sx*r*(1 + wob*math.sin(3*a + seed) + 0.5*wob*math.cos(5*a + 2*seed))*math.cos(a),
             cy + sy*r*(1 + wob*math.sin(3*a + seed) + 0.5*wob*math.cos(5*a + 2*seed))*math.sin(a))
            for a in [2*math.pi*i/n for i in range(n)]]

def _arco(cx, cy, r0, r1, a0, a1, n=12):
    # pedaço de anel de a0 a a1 (radianos), raios r0 (dentro) e r1 (fora)
    A = [a0 + (a1 - a0)*i/(n - 1) for i in range(n)]
    return [_pol(a, r1, cx, cy) for a in A] + [_pol(a, r0, cx, cy) for a in reversed(A)]

def _crescente(a0, a1, r, w, cx=0.0, cy=0.0, n=14):
    # meia-lua colada numa borda de raio r: grossura w no meio, zero nas pontas
    A = [a0 + (a1 - a0)*i/(n - 1) for i in range(n)]
    return [_pol(a, r, cx, cy) for a in A] + [_pol(a, r - w*math.sin(math.pi*(a - a0)/(a1 - a0)), cx, cy) for a in reversed(A[1:-1])]

def _pena(x0, y0, ang, L, w, n=12):
    # pena oval saindo de (x0, y0) na direção ang
    return ellipse(x0 + math.cos(ang) * L / 2, y0 + math.sin(ang) * L / 2, L / 2, w, n=n, rot=ang)

def _cristal(x0, y0, ang, L, w):
    # cristal de gelo: lados paralelos e ponta em bico
    P = _local(x0, y0, ang)
    return [P(0, -w), P(0.72*L, -w), P(L, 0), P(0.72*L, w), P(0, w)]

def _faceta(x0, y0, ang, L, w):
    # metade clara do cristal (brilho)
    P = _local(x0, y0, ang)
    return [P(0.05*L, 0.05*w), P(0.72*L, 0.05*w), P(0.97*L, 0.02*w), P(0.72*L, 0.75*w), P(0.05*L, 0.75*w)]

def _estrela(cx, cy, r0, r1, n=5, rot=math.pi/2):
    return [_pol(rot + math.pi*i/n, r1 if i % 2 == 0 else r0, cx, cy) for i in range(2*n)]

def _espinho(x0, y0, ang, L, w, curva=0.0):
    # espinho/garra: base larga em (x0, y0), ponta fina na direção ang (curva > 0 entorta para a esquerda)
    P = _local(x0, y0, ang)
    return [P(0, -w), P(0.45*L, -0.55*w + 0.25*curva*w), P(L, curva*w), P(0.45*L, 0.55*w + 0.25*curva*w), P(0, w)]

def _membrana(raiz_f, pulso, pontas, raiz_t, recuo=0.3, n=7):
    # asa membranosa: borda da frente reta até o pulso e a ponta, depois bordas recortadas em arco
    # entre as pontas dos dedos (puxadas na direção do pulso) até a raiz de trás
    out = [raiz_f, pulso, pontas[0]]
    cadeia = list(pontas) + [raiz_t]
    for A, B in zip(cadeia, cadeia[1:]):
        L = math.dist(A, B)
        for k in range(1, n):
            t = k / n
            px, py = A[0] + (B[0] - A[0])*t, A[1] + (B[1] - A[1])*t
            dx, dy = pulso[0] - px, pulso[1] - py; l = math.hypot(dx, dy) or 1
            m = recuo * L * math.sin(math.pi * t)
            out.append((px + dx/l*m, py + dy/l*m))
        out.append(B)
    return out

def _risco(s, pts, w, z, cor):
    # linha fina no topo (rachadura, costura, veio)
    s.flat(_tubo(pts, lambda t: w, n=max(4, 3*len(pts))), z, 0.01, cor, smooth=False)


# ---------------------------------------------------------------- skins
def gargula(s):
    # Gárgula: asas de morcego de pedra abertas para os lados (recortes angulosos, ossos e rachaduras),
    # chifrinhos curvos saindo das laterais de trás, focinho de pedra com narinas, rachaduras e pedrinhas no topo;
    # mão de pedra com três garras.
    s.base()
    c1, c2, c3, c4, c5, c6, ink = "#909090", "#484848", "#544848", "#6C6C6C", "#848484", "#A8A8A8", "#304848"
    # asas: membrana de pedra (recortes retos, sem suavizar), ossos por cima
    rf, pulso, pontas, rt = (1.45, 0.05), (2.95, 0.6), [(4.15, 0.15), (3.95, -1.05), (3.15, -1.95), (2.1, -2.25)], (1.25, -1.5)
    asa = _membrana(rf, pulso, pontas, rt, recuo=0.28, n=3)
    s.sym(asa, 0.95, 0.6, c4, outline=ink, ow=0.1, smooth=False)
    # faixa mais clara perto da borda da frente (pedra gasta)
    s.sym([rf, pulso, pontas[0], (3.55, -0.2), (2.6, 0.05), (1.5, -0.4)], 1.56, 0.02, c5, smooth=False)
    for p in pontas:
        s.sym(_tubo([pulso, p], lambda t: 0.1 - 0.06*t, n=6), 1.6, 0.06, c1, outline=c2, ow=0.04, smooth=False)
    s.sym(_tubo([rf, pulso], lambda t: 0.17 - 0.04*t, n=6), 1.62, 0.08, c1, outline=c2, ow=0.05, smooth=False)
    s.sym(_espinho(*pulso, math.radians(70), 0.55, 0.13, curva=0.6), 1.62, 0.1, c6, outline=c2, ow=0.04, smooth=False)
    # rachaduras na membrana
    for pts in ([(3.35, -0.55), (3.05, -0.85), (3.2, -1.2)], [(2.25, -1.25), (2.5, -1.6), (2.3, -1.85)]):
        s.sym(_tubo(pts, lambda t: 0.035, n=8), 1.58, 0.01, c2, smooth=False)
    # chifrinhos curvos saindo das laterais de trás para fora
    c = _curva([(1.05, -1.0), (1.7, -1.3), (2.05, -1.8), (1.95, -2.3)])
    s.sym(_tubo(c, lambda t: 0.24*(1 - t) + 0.03, n=20), TOP, 0.12, c6, outline=c2, ow=0.06, smooth=False)
    s.sym(_tubo(c, lambda t: 0.035, 0.1, 0.75, n=10), TOP + 0.12, 0.01, c5, smooth=False)
    # focinho de pedra na frente com narinas
    s.flat([(-0.55, 1.22), (0.55, 1.22), (0.72, 1.68), (0.45, 2.1), (0.0, 2.22), (-0.45, 2.1), (-0.72, 1.68)], TOP, 0.1, c5, outline=c2, ow=0.07)
    s.sym(ellipse(0.22, 1.86, 0.1, 0.13, n=8, rot=0.3), TOP + 0.1, 0.02, ink)
    # rachaduras finas e pedrinhas nas laterais e costas (nada grande e escuro no meio)
    for pts in ([(-1.55, 0.35), (-1.25, 0.0), (-1.4, -0.35), (-1.1, -0.7)], [(1.6, -0.1), (1.3, -0.4), (1.45, -0.75)],
                [(-0.5, -1.55), (-0.25, -1.25), (0.05, -1.4)], [(0.85, -1.2), (1.05, -1.5)]):
        _risco(s, _curva(pts, per=3), 0.035, TOP, c4)
    for i, (x, y, r, cor) in enumerate([(-1.0, -1.25, 0.24, c3), (1.15, -0.95, 0.2, c5), (-1.45, 1.1, 0.16, c5), (1.5, 0.75, 0.13, c3), (0.35, -1.0, 0.15, c4)]):
        s.flat(_blob(x, y, r, n=8, wob=0.15, seed=i), TOP, 0.02, cor, smooth=False)
    # mão: três garras de pedra na frente e uma rachadura
    for k in (-1, 0, 1):
        a = math.radians(90 - 25*k)
        s.hand_flat(_espinho(k*0.22, 0.38, a, 0.55, 0.12, curva=-0.5*k), 1.3, 0.4, c6, outline=c2, ow=0.04, smooth=False)
    s.hand_flat(_tubo([(-0.3, 0.1), (-0.05, -0.05), (0.05, -0.3)], lambda t: 0.035, n=8), 1.86, 0.01, c4, smooth=False)


def ourico_mar(s):
    # Ouriço-do-mar: coroa de espinhos compridos saindo em volta toda (duas camadas, pontas creme fora do corpo),
    # topo com fileiras de tubérculos em tons próximos; mão com espinhos curtos.
    s.base()
    c1, c2, c3, c4, ink, creme = "#783024", "#A82424", "#6C2424", "#54180C", "#540C0C", "#C0B490"
    def livre(a):
        # sem espinhos na direção das mãos
        g = math.degrees(a) % 360
        return not (18 < g < 58 or 122 < g < 162)
    # espinhos compridos (embaixo) e curtos (em cima, intercalados)
    N = 20
    for i in range(N):
        a = 2*math.pi*i/N + 0.08
        if not livre(a): continue
        g = math.degrees(a) % 360
        L = (0.75 if 60 < g < 120 else 1.35 + 0.3*((i*7) % 3)/2)
        r0 = _raio_corpo(a) - 0.25
        s.flat(_espinho(*_pol(a, r0), a, L + 0.25, 0.24), 0.8, 1.0, c3, outline=ink, ow=0.07, smooth=False)
        P = _local(*_pol(a, r0), a)
        s.flat(_espinho(*P(L - 0.1, 0), a, 0.35, 0.09), 1.81, 0.02, creme, smooth=False)
    for i in range(N):
        a = 2*math.pi*(i + 0.5)/N + 0.08
        if not livre(a): continue
        g = math.degrees(a) % 360
        L = 0.55 if 60 < g < 120 else 0.95
        s.flat(_espinho(*_pol(a, _raio_corpo(a) - 0.2), a, L, 0.2), 0.86, 1.0, c2, outline=ink, ow=0.06, smooth=False)
    # topo: cinco fileiras duplas de tubérculos (casca do ouriço), tons próximos do corpo (afastados dos olhos e do eixo entre eles)
    for k in range(5):
        a = math.radians(90 + 72*k)
        for j, r in enumerate((0.55, 0.95, 1.32)):
            for d in (-1, 1):
                x, y = _pol(a + d*(0.32 - 0.07*j), r)
                if math.hypot(abs(x) - EYE_X, y - EYE_Y) < 0.62: continue
                if abs(x) < 0.75 and -1.0 < y < 1.25: continue
                s.flat(ellipse(x, y, 0.12 - 0.02*j, 0.12 - 0.02*j, n=8), TOP, 0.03, c2, outline=c3, ow=0.025)
    # anel de bolinhas mais escuras perto da borda, só nas laterais (tom próximo)
    for g in (0, 15, -15, 180, 165, 195):
        x, y = _pol(math.radians(g), 1.55)
        s.flat(ellipse(x, y, 0.09, 0.09, n=8), TOP, 0.02, c4)
    # mão: espinhos curtos para fora e para a frente, pontas creme
    for g in (90, 50, 10, -30, 130):
        a = math.radians(g)
        s.hand_flat(_espinho(*_pol(a, 0.45), a, 0.6, 0.12), 1.15, 0.6, c3, outline=ink, ow=0.03, smooth=False)
        x, y = _pol(a, 0.86)
        s.hand_flat(_espinho(x, y, a, 0.2, 0.05), 1.76, 0.02, creme, smooth=False)


def carneiro(s):
    # Carneiro: chifres grandes enrolados em espiral nas laterais de trás (com anéis), lã fofa cobrindo a metade de trás
    # e passando da borda em volta, cara lisa na frente com focinho; mão de casco com punho de lã.
    s.base()
    la, pele, chif2, chif, ink = "#C0A89C", "#B49078", "#785448", "#906C60", "#543C30"
    # lã: silhueta fofa em volta toda (recortada nas mãos)
    k = 14
    s.flat(_radial(lambda a: _raio_corpo(a) + 0.1 + 0.28*abs(math.sin(k*a/2))**0.55, n=168, maos=0.74), 0.82, 1.0, la, outline=ink, ow=0.08, smooth=False)
    # lã no topo: borda da frente ondulada atrás dos olhos, segue a borda do corpo por trás
    frente = [(x, 0.0 + 0.16*abs(math.sin(math.pi*x/0.62))**0.6 - 0.12*(x/1.6)**2) for x in [1.62 - 3.24*i/30 for i in range(31)]]
    tras = [_pol(a, _raio_corpo(a) - 0.06 + 0.06*abs(math.sin(7*a))) for a in [math.radians(185 + 170*i/40) for i in range(41)]]
    s.flat(frente + tras, TOP, 0.05, la, smooth=False)
    # cachinhos da lã (arcos finos no tom da pele, longe do meio de trás)
    for i, (x, y, rot) in enumerate([(-1.2, -0.4, 0.3), (1.15, -0.55, 2.0), (-0.55, -1.15, 1.2), (0.6, -1.25, -0.4), (-1.45, -1.3, 2.6), (1.5, -1.35, 0.8), (0.0, -0.5, 1.9)]):
        s.flat(_arco(x, y, 0.13, 0.19, rot, rot + 4.2, n=10), TOP + 0.05, 0.01, pele, smooth=False)
    # focinho na frente com narinas
    s.flat([(-0.5, 1.3), (0.5, 1.3), (0.62, 1.7), (0.4, 2.05), (0.0, 2.12), (-0.4, 2.05), (-0.62, 1.7)], TOP, 0.06, chif, outline=ink, ow=0.05)
    s.sym(ellipse(0.2, 1.8, 0.08, 0.12, n=8, rot=0.4), TOP + 0.06, 0.02, ink)
    # chifres em espiral (vistos de cima): saem da lateral, vão para trás, para fora, para a frente e enrolam para dentro
    cx, cy = 2.3, -0.8
    esp = []
    for i in range(48):
        t = i / 47; th = math.radians(160 + 400*t); r = 0.98 - 0.72*t
        esp.append(_pol(th, r, cx, cy))
    wf = lambda t: 0.31 - 0.2*t
    s.sym(_tubo(esp, wf, cap1=True, n=60), TOP + 0.06, 0.14, chif, outline=ink, ow=0.07, smooth=False)
    for t in [0.08 + 0.075*j for j in range(11)]:
        s.sym(_tubo(esp, wf, t, t + 0.018, n=2), TOP + 0.2, 0.01, chif2, smooth=False)
    s.sym(_tubo(esp, lambda t: 0.05, 0.05, 0.6, n=24), TOP + 0.2, 0.01, la, smooth=False)
    # mão: casco de dois dedos na frente e punho de lã atrás
    for x in (-0.18, 0.18):
        s.hand_flat(ellipse(x, 0.4, 0.17, 0.24, n=10), 1.4, 0.45, chif2, outline=ink, ow=0.04)
    s.hand_flat([(0.6*math.cos(a)*(1 + 0.1*abs(math.sin(4*a))), -0.25 + 0.38*math.sin(a)*(1 + 0.1*abs(math.sin(4*a)))) for a in [math.pi*(0.95 + 1.1*i/16) for i in range(17)]],
                1.2, 0.7, la, outline=ink, ow=0.04)


def espirito_gelo(s):
    # Espírito de gelo: aura ondulada em volta, dois fiapos de névoa curvando atrás, cristais grandes saindo para os lados
    # e para trás (brilho Neon leve), redemoinhos claros no topo e lascas de gelo soltas; mão com três cristais.
    s.base()
    c1, c2, c3, c4, c5, c6, esc, esc2 = "#C0F0F0", "#A8F0FC", "#84E4FC", "#90D8E4", "#48B4D8", "#6CB4CC", "#183048", "#18486C"
    # fiapos de névoa atrás (curvam para os lados, pontas finas)
    for k in (1, -1):
        c = _curva([(0.35*k, -1.3), (0.6*k, -2.4), (1.3*k, -3.15), (2.15*k, -3.2), (2.55*k, -2.7)])
        s.flat(_tubo(c, lambda t: 0.42*(1 - t)**0.8 + 0.03, n=36), 0.78, 1.0, c4, outline=c5, ow=0.07, smooth=False)
        s.flat(_tubo(c, lambda t: 0.16*(1 - t) + 0.02, 0.05, 0.9, n=24), 1.79, 0.02, c1, smooth=False)
    # aura ondulada (recortada nas mãos)
    s.flat(_radial(lambda a: _raio_corpo(a) + 0.22 + 0.1*math.sin(7*a + 0.5), n=84, maos=0.74), 0.82, 1.0, c2, outline=c5, ow=0.07)
    # cristais grandes: laterais (para os lados e para trás) e dois atrás
    for (x0, y0), ang, L, w in [((1.5, -0.2), 12, 1.65, 0.21), ((1.5, -0.45), -14, 2.35, 0.29), ((1.35, -0.85), -42, 1.85, 0.23),
                                ((0.85, -1.4), -68, 1.55, 0.2)]:
        a = math.radians(ang)
        s.sym(_cristal(x0, y0, a, L, w), 0.9 + 0.01*L, 1.0, c3, outline=esc2, ow=0.06, smooth=False)
        s.sym(_faceta(x0, y0, a, L, w), 1.92 + 0.01*L, 0.02, c1, emit=0.5, smooth=False)
    # topo: redemoinhos claros nas laterais e costas, sombra suave à direita
    s.flat(_crescente(math.radians(-80), math.radians(15), 1.75, 0.35), TOP, 0.012, c4)
    for pts, w in [([(-1.5, 0.2), (-1.3, -0.35), (-0.8, -0.5), (-0.65, -0.2), (-0.9, -0.05)], 0.07),
                   ([(1.35, -0.6), (1.0, -1.1), (0.45, -1.15), (0.35, -0.85)], 0.06),
                   ([(-0.4, -1.55), (0.1, -1.6), (0.35, -1.4)], 0.05)]:
        s.flat(_tubo(_curva(pts), lambda t, w=w: w*math.sin(math.pi*(0.1 + 0.8*t)), n=24), TOP, 0.012, c3, smooth=False)
    # lascas de gelo soltas em volta (Neon leve)
    for x, y, r in [(-2.75, 0.75, 0.13), (2.8, 0.9, 0.11), (-3.0, -1.6, 0.12), (0.05, -2.95, 0.14), (3.15, -1.95, 0.1)]:
        s.flat([(x, y + r*1.5), (x + r, y), (x, y - r*1.5), (x - r, y)], 1.6, 0.1, c1, outline=c5, ow=0.03, emit=0.4, smooth=False)
    # mão: três cristais para a frente
    for kk, L in ((-1, 0.55), (0, 0.75), (1, 0.55)):
        a = math.radians(90 - 28*kk)
        s.hand_flat(_cristal(kk*0.22, 0.3, a, L, 0.11), 1.3, 0.5, c3, outline=esc2, ow=0.04, smooth=False)
        s.hand_flat(_faceta(kk*0.22, 0.3, a, L, 0.11), 1.81, 0.02, c1, emit=0.5, smooth=False)


def _flor(s, x, y, r, z, petala, meio, centro, rot=0.0, contorno=None, maos=False):
    # flor de cinco pétalas redondas com miolo e centro
    f = s.hand_flat if maos else s.flat
    for i in range(5):
        a = rot + 2*math.pi*i/5
        f(ellipse(x + math.cos(a)*r*0.52, y + math.sin(a)*r*0.52, r*0.5, r*0.36, n=10, rot=a), z, 0.04, petala, outline=contorno, ow=0.04)
    f(_estrela(x, y, r*0.22, r*0.42, n=5, rot=rot + math.pi/5), z + 0.04, 0.01, meio, smooth=False)
    f(ellipse(x, y, r*0.17, r*0.17, n=8), z + 0.05, 0.01, centro)

def arbusto_florido(s):
    # Arbusto florido: copa de folhas em duas camadas passando da borda, flores vermelho-alaranjadas e azul-turquesa
    # saindo pela borda e botões no topo, folhas pontudas mais escuras nas laterais; mão com uma flor e folhas.
    s.base()
    v1, v2, v3 = "#006C3C", "#0C4830", "#0C3C24"
    r1, r2, r3, t1, t2, t3 = "#E45424", "#B43018", "#6C1818", "#30A89C", "#247884", "#184854"
    k = 11
    s.flat(_radial(lambda a: _raio_corpo(a) + 0.22 + 0.3*abs(math.sin(k*(a + 0.1)/2))**0.6, n=154, maos=0.74), 0.8, 1.0, v2, outline=v3, ow=0.08, smooth=False)
    s.flat(_radial(lambda a: _raio_corpo(a) + 0.1 + 0.24*abs(math.sin(k*(a + 0.1)/2 + math.pi/2))**0.6, n=154, maos=0.8), 0.85, 1.0, v1, outline=v3, ow=0.06, smooth=False)
    # folhas pontudas mais escuras no topo, só na periferia das laterais e de trás
    for x, y, a in [(-1.45, 0.15, 2.1), (1.45, 0.0, 1.0), (-1.2, -1.2, 2.5), (1.25, -1.3, 0.6), (-0.4, -1.55, 1.9), (0.5, -1.6, 1.2)]:
        P = _local(x, y, a)
        s.flat([P(-0.35, 0), P(0, 0.17), P(0.35, 0.09), P(0.5, 0), P(0.35, -0.09), P(0, -0.17)], TOP, 0.03, v2)
        _risco(s, [P(-0.3, 0), P(0.4, 0)], 0.018, TOP + 0.03, v1)
    # flores na borda (centro um pouco para fora do corpo)
    for g, tipo, r, rad in [(90, "t", 2.05, 0.5), (-8, "r", 2.3, 0.58), (188, "r", 2.3, 0.55), (-52, "t", 2.35, 0.5),
                            (-92, "r", 2.4, 0.6), (-135, "t", 2.35, 0.52), (12, "t", 2.25, 0.42), (165, "t", 2.25, 0.42)]:
        x, y = _pol(math.radians(g), r)
        cores = (r1, r2, r3) if tipo == "r" else (t1, t2, t3)
        _flor(s, x, y, rad, 1.96, *cores, rot=math.radians(g * 1.7), contorno=v3)
    # botões menores no topo (costas e laterais)
    for x, y, tipo in [(-0.85, -0.75, "r"), (0.95, -0.8, "t"), (0.05, -1.25, "t"), (-1.4, -0.45, "t"), (1.35, 0.6, "r")]:
        cores = (r1, r2, r3) if tipo == "r" else (t1, t2, t3)
        _flor(s, x, y, 0.3, TOP, *cores, rot=x + y)
    # mão: flor vermelha com duas folhas
    for a in (-0.6, 3.5):
        P = _local(0.0, 0.0, a)
        s.hand_flat([P(0.0, 0), P(0.3, 0.2), P(0.8, 0.0), P(0.3, -0.2)], 1.55, 0.3, v1, outline=v3, ow=0.04)
    _flor(s, 0.0, 0.05, 0.45, 1.85, r1, r2, r3, rot=0.3, contorno=v3, maos=True)


def wyvern_gelo(s):
    # Dragão/wyvern de gelo (ref. 182): corpo verde-escuro (#244848), focinho réptil largo na mesma cor do corpo,
    # chifres enormes de gelo curvando das costas para os lados com farpas na borda externa, presas de gelo nos cantos
    # da frente, crista de cristais na coluna e cauda com ponta de cristal.
    s.base()
    c1, c2, c3, c4, c5, ink = "#6CB4A8", "#244848", "#C0E4E4", "#A8D8D8", "#306054", "#0C3030"
    # cauda em S com ponta de cristal de gelo
    c = _curva([(0.0, -1.35), (-0.18, -2.25), (0.28, -3.05), (0.15, -3.7)])
    s.flat(_tubo(c, lambda t: 0.32 - 0.19*t, n=30), 0.8, 1.0, c2, outline=ink, ow=0.08, smooth=False)
    ponta_c = [(0.15, -3.45), (0.62, -3.88), (0.4, -4.02), (0.55, -4.35), (0.12, -4.65), (-0.28, -4.3), (-0.12, -4.0), (-0.35, -3.85)]
    s.flat(ponta_c, 0.82, 1.0, c3, outline=c1, ow=0.07, smooth=False)
    s.flat([(0.13, -3.65), (0.35, -4.0), (0.12, -4.42), (-0.08, -4.0)], 1.83, 0.02, "#E4F8F8", emit=0.35, smooth=False)
    # focinho réptil largo na frente (da cor escura do corpo, não claro, para não parecer bico de pássaro!)
    foc = [(-1.08, 1.35), (-0.85, 2.02), (-0.38, 2.34), (0.0, 2.42), (0.38, 2.34), (0.85, 2.02), (1.08, 1.35)]
    s.flat(foc, 0.85, 1.15, c2, outline=ink, ow=0.09)
    s.flat([(-0.94, 1.3), (-0.72, 1.92), (0.0, 2.26), (0.72, 1.92), (0.94, 1.3)], TOP, 0.03, c5)
    # cristal de gelo pontudo (com farpas laterais, como na ref. 182) no topo do focinho
    cr_f = [(0.0, 2.38), (0.16, 1.95), (0.38, 2.02), (0.42, 1.72), (0.2, 1.54), (0.0, 1.38),
            (-0.2, 1.54), (-0.42, 1.72), (-0.38, 2.02), (-0.16, 1.95)]
    s.flat(cr_f, TOP + 0.03, 0.07, c3, outline=c1, ow=0.06, smooth=False)
    s.flat([(0.0, 2.22), (0.16, 1.86), (0.0, 1.55), (-0.16, 1.86)], TOP + 0.1, 0.02, "#E4F8F8", emit=0.35, smooth=False)
    # presas/espinhos de gelo duplos saindo das laterais do focinho para a frente/cima
    s.sym([(0.72, 1.52), (1.15, 1.75), (1.12, 2.28), (0.86, 2.05), (0.62, 1.78)], TOP + 0.02, 0.12, c3, outline=c1, ow=0.05, smooth=False)
    s.sym([(1.02, 1.32), (1.42, 1.52), (1.36, 1.95), (1.12, 1.72)], TOP + 0.01, 0.09, c4, outline=c1, ow=0.04, smooth=False)
    # chifres grandes de gelo em arco vazado (ref. 182): nascem atrás dos olhos, arqueiam alto para trás e curvam
    # para fora e para a frente deixando um vão entre o chifre e a lateral do corpo, com farpas bem marcadas!
    chifre = [
        (0.72, -0.35), (0.92, -1.05), (1.58, -1.78), (2.25, -2.18), (2.02, -1.58),
        (2.98, -1.95), (3.55, -1.35), (3.12, -0.95), (3.92, -0.58), (3.75, 0.18),
        (3.25, 0.58), (2.52, 0.52), (2.82, 0.08), (2.28, 0.15), (1.92, -0.22),
        (2.25, -0.45), (2.68, -0.25), (2.85, -0.68), (2.42, -1.15), (1.72, -1.05), (1.28, -0.55)
    ]
    s.sym(chifre, 1.15, 0.98, c3, outline=c1, ow=0.09, smooth=False)
    chifre_in = [
        (0.95, -0.65), (1.45, -1.35), (2.35, -1.62), (3.12, -1.05),
        (3.42, -0.28), (3.15, 0.25), (2.65, 0.28), (2.98, -0.25),
        (2.85, -0.85), (2.25, -1.25), (1.55, -0.98)
    ]
    s.sym(chifre_in, 2.14, 0.02, "#E4F8F8", emit=0.35, smooth=False)
    # crista de cristais na coluna (dois cristais com farpas na metade de trás)
    for cy, sc in [(-0.85, 0.95), (-1.52, 0.8)]:
        pts = [(0.0, cy + 0.42*sc), (0.14*sc, cy + 0.08*sc), (0.34*sc, cy + 0.14*sc), (0.36*sc, cy - 0.12*sc),
               (0.16*sc, cy - 0.3*sc), (0.0, cy - 0.4*sc), (-0.16*sc, cy - 0.3*sc), (-0.36*sc, cy - 0.12*sc),
               (-0.34*sc, cy + 0.14*sc), (-0.14*sc, cy + 0.08*sc)]
        s.flat(pts, TOP + 0.03, 0.08, c3, outline=c1, ow=0.05, smooth=False)
        s.flat([(0.0, cy + 0.24*sc), (0.14*sc, cy - 0.06*sc), (0.0, cy - 0.24*sc), (-0.14*sc, cy - 0.06*sc)],
               TOP + 0.11, 0.02, "#E4F8F8", emit=0.35, smooth=False)
    # mão: três garras de gelo na frente e espinho lateral
    for kk in (-1, 0, 1):
        s.hand_flat(_cristal(kk*0.22, 0.32, math.radians(90 - 22*kk), 0.55, 0.11), 1.3, 0.42, c3, outline=c1, ow=0.04, smooth=False)
    s.hand_flat([(0.25, -0.1), (0.78, -0.35), (0.55, -0.65), (0.1, -0.45)], 1.25, 0.45, c4, outline=ink, ow=0.04, smooth=False)


def gaio_azul(s):
    # Gaio-azul: topete de penas para a frente, cara e peito claros com bico escuro, asinhas laterais com barras
    # escuras e pontas claras, cauda em leque atrás; mão de ponta de asa.
    s.base()
    a1, a2, a3, a4, peito, esc = "#6090E4", "#3C6CC0", "#5484D8", "#789CCC", "#D8F0F0", "#484878"
    def penas(x0, y0, lista, z, mao=False):
        f = s.hand_flat if mao else s.flat
        for i, (ang, L, w) in enumerate(lista):
            a = math.radians(ang); P = _local(x0, y0, a)
            f(_pena(x0, y0, a, L, w), z + 0.02*i, 1.0 if not mao else 0.4, a2 if i % 2 else a3, outline=esc, ow=0.06 if not mao else 0.03)
            top = z + 0.02*i + (1.0 if not mao else 0.4)
            for u in (0.55, 0.75):
                f([P(u*L, -0.8*w), P(u*L + 0.07, -0.8*w), P(u*L + 0.07, 0.8*w), P(u*L, 0.8*w)], top, 0.01, esc, smooth=False)
            f(ellipse(*P(0.9*L, 0), 0.1*L, 0.55*w, n=8, rot=a), top, 0.01, peito)
    # cauda em leque atrás
    penas(0.0, -1.2, [(-122, 2.0, 0.3), (-58, 2.0, 0.3), (-106, 2.3, 0.32), (-74, 2.3, 0.32), (-90, 2.5, 0.34)], 0.8)
    # asinhas nas laterais (três penas para fora e para trás) com cobertura na raiz
    for k in (1, -1):
        lista = [(k*0 + (-62 if k > 0 else -118), 1.4, 0.3), ((-38 if k > 0 else -142), 1.65, 0.32), ((-14 if k > 0 else -166), 1.5, 0.3)]
        penas(1.45*k, -0.15, lista, 0.82)
    s.sym([(1.55, 0.35), (2.2, 0.15), (2.45, -0.35), (2.2, -0.8), (1.6, -0.75)], 1.0, 0.9, a1, outline=esc, ow=0.06)
    # peito claro passando da borda da frente e cara clara no topo (na frente dos olhos)
    s.flat(ellipse(0.0, 1.55, 1.0, 0.62, n=14), 0.85, 1.0, peito, outline=esc, ow=0.06)
    s.flat([(-1.2, 1.1), (-0.5, 1.05), (0.0, 1.2), (0.5, 1.05), (1.2, 1.1), (1.0, 1.6), (0.5, 1.82), (0.0, 1.85), (-0.5, 1.82), (-1.0, 1.6)], TOP, 0.03, peito)
    # bico escuro na frente (no topo, visível de cima e a 65°)
    s.flat([(-0.32, 1.55), (0.32, 1.55), (0.0, 2.38)], TOP + 0.03, 0.14, esc, outline="#2A2A48", ow=0.05, smooth=False)
    # topete: dois tufos de penas abrindo na diagonal da coroa (sem pena central atrás dos olhos, que pareceria boca de cima)
    for k in (-1, 1):
        s.flat(_pena(k*0.65, -0.7, math.radians(-90 + k*42), 1.05, 0.22), TOP + 0.03, 0.04, a3, outline=esc, ow=0.05)
        s.flat(_pena(k*0.42, -0.82, math.radians(-90 + k*24), 1.2, 0.23), TOP + 0.06, 0.04, a2, outline=esc, ow=0.05)
    # costas: brilho cinza-azulado à esquerda e escamas de pena em tom próximo nas laterais
    s.flat(_crescente(math.radians(160), math.radians(235), 1.75, 0.3), TOP, 0.012, a4)
    for x, y in [(1.25, -0.6), (1.0, -1.1), (-1.15, -0.95), (0.55, -1.45), (-0.6, -1.45)]:
        s.flat(_arco(x, y, 0.2, 0.26, math.radians(200), math.radians(340), n=8), TOP, 0.01, a3, smooth=False)
    # mão: ponta de asa (três peninhas para a frente)
    penas(0.0, -0.1, [(115, 0.8, 0.17), (65, 0.8, 0.17), (90, 0.95, 0.19)], 1.3, mao=True)


def zumbi(s):
    # Zumbi: borda rasgada nas laterais, orelha mordida, cicatriz costurada no topo (fora do meio) e arranhões,
    # mão de dedos compridos com manga rasgada e costura.
    s.base()
    v1, v2, r1, r2 = "#78906C", "#546048", "#B41824", "#9C1824"
    # pele rasgada passando da borda nas laterais (pontas irregulares)
    s.sym([(1.7, 0.45), (2.25, 0.35), (2.05, 0.12), (2.45, -0.15), (2.1, -0.32), (2.3, -0.7), (1.95, -0.75), (2.05, -1.1), (1.6, -1.05)],
          0.85, 1.0, v1, outline=v2, ow=0.08, smooth=False)
    # orelhas nas laterais de trás: uma inteira, outra mordida (com recorte)
    s.flat(ellipse(-1.55, -1.25, 0.42, 0.36, n=12, rot=0.7), 0.9, 1.0, v1, outline=v2, ow=0.07)
    s.flat(ellipse(-1.62, -1.32, 0.22, 0.17, n=10, rot=0.7), 1.91, 0.02, v2)
    s.flat([(1.2, -1.05), (1.75, -1.0), (1.95, -1.25), (1.72, -1.38), (1.9, -1.55), (1.6, -1.7), (1.35, -1.5)], 0.9, 1.0, v1, outline=v2, ow=0.07, smooth=False)
    # cicatriz costurada na lateral esquerda (diagonal, longe do meio de trás) com pontos vermelhos
    c = _curva([(-1.55, 0.15), (-1.25, -0.25), (-1.2, -0.7), (-0.85, -1.15)])
    _risco(s, c, 0.045, TOP, v2)
    for t in (0.12, 0.32, 0.52, 0.72, 0.9):
        i = int(t*(len(c) - 1)); (x0, y0), (x1, y1) = c[i], c[min(i + 1, len(c) - 1)]
        dx, dy = x1 - x0, y1 - y0; l = math.hypot(dx, dy) or 1; nx, ny = -dy/l*0.17, dx/l*0.17
        _risco(s, [(x0 - nx, y0 - ny), (x0 + nx, y0 + ny)], 0.025, TOP + 0.01, r1)
    # cicatriz curta na lateral direita
    c = [(1.45, 0.15), (1.3, -0.35), (1.4, -0.75)]
    _risco(s, c, 0.04, TOP, v2)
    for x, y in [(1.4, 0.0), (1.33, -0.3), (1.37, -0.6)]:
        _risco(s, [(x - 0.15, y + 0.03), (x + 0.15, y - 0.03)], 0.022, TOP + 0.01, r1)
    # arranhões finos no canto de trás à direita
    for d in (0.0, 0.17, 0.34):
        _risco(s, [(0.55 + d, -1.2 - 0.05*d), (0.85 + d, -1.6 - 0.05*d)], 0.022, TOP, r2)
    # manchas de pele mais escura (pequenas, nas laterais da frente)
    s.flat(_blob(1.4, 1.15, 0.2, n=10, wob=0.15, seed=1), TOP, 0.02, v2)
    s.flat(_blob(-0.35, -0.8, 0.12, n=8, wob=0.15, seed=3), TOP, 0.02, v2)
    # mão: manga rasgada atrás, quatro dedos compridos na frente, costura no dorso
    s.hand_flat([(-0.68, -0.05), (0.68, -0.05), (0.75, -0.45), (0.5, -0.38), (0.4, -0.75), (0.15, -0.5), (-0.1, -0.82), (-0.3, -0.45), (-0.55, -0.7), (-0.75, -0.4)],
                1.15, 0.8, v2, outline=v2, ow=0.03, smooth=False)
    for kk, L in ((-1.5, 0.3), (-0.5, 0.42), (0.5, 0.42), (1.5, 0.3)):
        s.hand_flat(_tubo([(kk*0.2, 0.3), (kk*0.22, 0.42 + L)], lambda t: 0.09, cap1=True, n=6), 1.3, 0.35, v1, outline=v2, ow=0.03, smooth=False)
    _risco(s, [(-0.35, 0.05), (0.35, 0.05)], 0.025, 1.86, v2)
    for x in (-0.22, 0.0, 0.22):
        s.hand_flat(_tubo([(x, -0.07), (x, 0.17)], lambda t: 0.02, n=2), 1.865, 0.01, r1, smooth=False)


def mago(s):
    # Mago / Elfo da floresta (ref. 238): corpo na cor de pele (#B49C78) deixando a testa e os olhos livres na frente!
    # Chapéu verde grande inclinado de lado cobrindo a parte de trás e passando nas laterais, forro listrado bege
    # bem visível no arco levantado à esquerda (-X, que fica à direita da tela a 65°), faixas claras curvas no chapéu
    # e ponta enrolada em espiral caída para o lado.
    s.base()
    v1, v2, ink = "#30906C", "#54B484", "#244848"
    pele, pele2, marrom, forro1, forro2 = "#B49C78", "#A8846C", "#784848", "#CCC0A8", "#B4A890"
    # sombra suave na testa logo à frente da aba do chapéu
    s.flat([(-1.72, 0.35), (-0.55, 0.12), (0.55, -0.02), (1.72, 0.08), (1.72, -0.25), (-1.72, -0.25)], TOP, 0.015, pele2)
    # forro interno listrado bege aparecendo debaixo da aba levantada no lado esquerdo (-X = direita na câmera a 65°)
    forro = [
        (-0.25, 0.05), (-0.95, 0.42), (-1.75, 0.52), (-2.38, 0.25),
        (-2.62, -0.28), (-2.25, -0.82), (-1.35, -0.65), (-0.35, -0.35)
    ]
    s.flat(forro, 1.05, 0.99, forro1, outline=ink, ow=0.08)
    for x0, y0, x1, y1 in [(-0.88, 0.35, -1.18, -0.35), (-1.48, 0.45, -1.78, -0.35), (-2.05, 0.35, -2.35, -0.45)]:
        s.flat(_tubo([(x0, y0), (x1, y1)], lambda t: 0.12, n=6), 2.05, 0.02, forro2, smooth=False)
    # aba do chapéu: no lado esquerdo (-X) é mais recuada em y ~ -0.15 para deixar o forro listrado aparecer na frente;
    # no lado direito (+X) avança mais para a frente (y ~ 0.12) e abre largo para o lado
    aba = [
        (-2.55, -0.28), (-1.85, -0.02), (-1.05, -0.12), (-0.25, -0.08), (0.55, 0.02), (1.45, 0.12),
        (2.45, 0.15), (2.92, -0.25), (2.68, -1.05), (2.05, -1.85), (1.15, -2.42), (0.0, -2.62),
        (-1.15, -2.48), (-2.05, -1.95), (-2.58, -1.15)
    ]
    s.flat(aba, 1.12, 0.96, v1, outline=ink, ow=0.1)
    # corpo do chapéu em 3 camadas largas e macias (sem anéis de cebola!) subindo e inclinando para -X
    copa1 = [
        (-1.95, -0.25), (-1.05, -0.15), (0.05, -0.12), (1.15, -0.15), (1.85, -0.45),
        (1.65, -1.35), (0.95, -2.05), (-0.15, -2.25), (-1.25, -1.95), (-1.95, -1.15)
    ]
    s.flat(copa1, 2.09, 0.32, v1, outline=ink, ow=0.08)
    copa2 = [
        (-1.55, -0.55), (-0.75, -0.42), (0.25, -0.45), (0.95, -0.82),
        (0.75, -1.62), (-0.15, -1.95), (-1.05, -1.72), (-1.55, -1.12)
    ]
    s.flat(copa2, 2.42, 0.32, v1)
    copa3 = [
        (-1.18, -0.82), (-0.45, -0.68), (0.28, -0.78), (0.52, -1.32),
        (-0.08, -1.68), (-0.82, -1.52), (-1.18, -1.12)
    ]
    s.flat(copa3, 2.75, 0.28, v1, outline=ink, ow=0.06)
    # faixas claras curvas (dobras do tecido verde-claro v2, como na ref. 238)
    for pts, w, z in [
        ([(2.35, -0.25), (1.25, -0.52), (0.05, -0.48), (-0.95, -0.25)], 0.16, 2.09),
        ([(1.65, -0.75), (0.65, -0.95), (-0.35, -0.85), (-1.15, -0.55)], 0.15, 2.42),
        ([(0.85, -1.15), (0.05, -1.28), (-0.68, -1.12)], 0.15, 2.75),
        ([(-0.95, -1.05), (-0.35, -0.92), (0.18, -1.05)], 0.22, 3.04),
    ]:
        s.flat(_tubo(_curva(pts), lambda t, w=w: w * math.sin(math.pi * (0.08 + 0.84*t)), n=20), z, 0.025, v2, smooth=False)
    # ponta enrolada em caracol (gancho característico da ref. 238) saindo do topo para o lado esquerdo (-X)
    gancho = _curva([(-0.35, -1.25), (-1.05, -1.18), (-1.52, -0.82), (-1.55, -0.38), (-1.18, -0.22), (-0.88, -0.48)])
    s.flat(_tubo(gancho, lambda t: 0.42*(1 - 0.7*t), cap0=True, cap1=True, n=28), 2.78, 0.28, v1, outline=ink, ow=0.07, smooth=False)
    s.flat(_tubo(gancho, lambda t: 0.16*(1 - 0.72*t), 0.06, 0.72, n=18), 3.07, 0.02, v2, smooth=False)
    # mão (cor de pele): segura cajado/varinha de madeira com folhinha mágica verde-clara
    s.hand_flat(_tubo([(-0.2, -0.45), (0.25, 0.75)], lambda t: 0.09, cap0=True, cap1=True, n=8), 1.82, 0.1, marrom, outline=ink, ow=0.03, smooth=False)
    P = _local(0.25, 0.75, math.radians(65))
    s.hand_flat([P(0, 0), P(0.22, 0.16), P(0.48, 0), P(0.22, -0.16)], 1.88, 0.06, v2, outline=ink, ow=0.03)


def pao(s):
    # Pão (ref. 234): mantém o formato quadrado-arredondado do corpo com a casca marrom-escura em volta,
    # mancha assada mais escura entre os olhos e dois ramos de trigo dourado (3 pares de grãos cada)
    # arqueando nos cantos de trás/laterais (deixando o centro livre!) e passando da silhueta; mão com trigo.
    s.base()
    p1, p2, p3, p4, p5, esc, esc2 = "#D89048", "#B46C30", "#FCA848", "#C0783C", "#A85430", "#481818", "#603018"
    # casca tostada mais grossa emoldurando a borda do corpo quadrado-arredondado
    s.flat(_radial(lambda a: _raio_corpo(a) + 0.08, n=72, maos=0.72), 0.85, 1.12, p5, outline=esc2, ow=0.09)
    s.flat(_radial(lambda a: _raio_corpo(a) - 0.12, n=72, maos=0.82), TOP, 0.03, p1)
    # mancha tostada suave entre os olhos (como na ref. 234, na frente/meio, sem descer para trás dos olhos)
    s.flat(ellipse(0.0, 0.52, 0.62, 0.36, n=16), TOP + 0.03, 0.015, p4)
    # sombra tostada fina na borda de trás
    s.flat(_crescente(math.radians(-145), math.radians(-35), 1.72, 0.18), TOP + 0.03, 0.01, p4)
    # dois ramos de trigo nos cantos de trás/laterais (afastados do centro x=0 para deixar o meio aberto como na ref. 234!)
    def grao(x0, y0, ang, L, w, z_off=0.0):
        P = _local(x0, y0, ang)
        pts = [P(0.0, 0.0), P(0.32*L, 0.85*w), P(0.72*L, 0.72*w), P(L, 0.0), P(0.72*L, -0.72*w), P(0.32*L, -0.85*w)]
        s.sym(pts, TOP + 0.04 + z_off, 0.12, p3, outline=p5, ow=0.08)
        s.sym([P(0.18*L, 0.0), P(0.45*L, 0.38*w), P(0.78*L, 0.0), P(0.45*L, -0.38*w)], TOP + 0.16 + z_off, 0.015, "#FFE088")
    # 6 grãos por ramo nos cantos traseiros/laterais, bem abertos nas pontas e com folga no meio
    for (x0, y0), ang, L, w, dz in [
        ((1.15, -1.02), 168, 0.88, 0.29, 0.00),  # grão interno apontando para o meio-trás (ponta chega em x ~ 0.3)
        ((0.88, -1.25), 112, 0.96, 0.32, 0.02),  # grão superior-interno saindo da borda de trás
        ((1.42, -0.72), 138, 0.90, 0.30, 0.01),  # grão médio apontando para dentro/trás
        ((1.42, -1.22), 78,  1.05, 0.34, 0.03),  # grão do canto saindo bem para trás/fora
        ((1.72, -0.88), 38,  1.05, 0.34, 0.02),  # grão lateral-alto saindo bem para fora (+X)
        ((1.68, -0.32), 8,   0.98, 0.32, 0.04),  # grão lateral-baixo saindo para fora (+X)
    ]:
        grao(x0, y0, math.radians(ang), L, w, dz)
    # mão: dois grãos de trigo cruzados em V
    for ang in (65, 115):
        P = _local(0.0, -0.05, math.radians(ang))
        pts = [P(0, 0), P(0.22, 0.16), P(0.5, 0.12), P(0.68, 0), P(0.5, -0.12), P(0.22, -0.16)]
        s.hand_flat(pts, 1.8, 0.1, p3, outline=p5, ow=0.04)


LOTE = [
    ("gargula", gargula, "#909090", "#304848", "#909090", "#304848"),
    ("ourico_mar", ourico_mar, "#783024", "#540C0C", "#783024", "#540C0C"),
    ("carneiro", carneiro, "#B49078", "#543C30", "#C0A89C", "#543C30"),
    ("espirito_gelo", espirito_gelo, "#C0F0F0", "#18486C", "#A8F0FC", "#18486C"),
    ("arbusto_florido", arbusto_florido, "#006C3C", "#0C3C24", "#006C3C", "#0C3C24"),
    ("wyvern_gelo", wyvern_gelo, "#244848", "#0C3030", "#244848", "#0C3030"),
    ("gaio_azul", gaio_azul, "#6090E4", "#484878", "#6090E4", "#484878"),
    ("zumbi", zumbi, "#78906C", "#546048", "#78906C", "#546048"),
    ("mago", mago, "#B49C78", "#784848", "#B49C78", "#784848"),
    ("pao", pao, "#D89048", "#603018", "#D89048", "#603018"),
]
