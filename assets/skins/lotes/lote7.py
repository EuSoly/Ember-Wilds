# Lote 7 — skins de corpo (detalhadas). Montar com build_skins.py (Blender aberto) ou render_lote.py (segundo plano).
# dragão de lava, marshmallow, cthulhu, falcão, boneco de neve, pinha, urso de madeira, raposa enfaixada, robô, helicóptero.
from skin_lib import *


# ---------------------------------------------------------------- ajudantes do lote
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

def _arco(cx, cy, r0, r1, a0, a1, n=12):
    # pedaço de anel de a0 a a1 (radianos), raios r0 (dentro) e r1 (fora)
    A = [a0 + (a1 - a0)*i/(n - 1) for i in range(n)]
    return [_pol(a, r1, cx, cy) for a in A] + [_pol(a, r0, cx, cy) for a in reversed(A)]

def _crescente(a0, a1, r, w, cx=0.0, cy=0.0, n=14):
    # meia-lua colada numa borda de raio r: grossura w no meio, zero nas pontas
    A = [a0 + (a1 - a0)*i/(n - 1) for i in range(n)]
    return [_pol(a, r, cx, cy) for a in A] + [_pol(a, r - w*math.sin(math.pi*(a - a0)/(a1 - a0)), cx, cy) for a in reversed(A[1:-1])]

def _pena(x0, y0, ang, L, w, n=12):
    return ellipse(x0 + math.cos(ang) * L / 2, y0 + math.sin(ang) * L / 2, L / 2, w, n=n, rot=ang)

def _espinho(x0, y0, ang, L, w, curva=0.0):
    P = _local(x0, y0, ang)
    return [P(0, -w), P(0.45*L, -0.55*w + 0.25*curva*w), P(L, curva*w), P(0.45*L, 0.55*w + 0.25*curva*w), P(0, w)]


def _chaikin(poly, passes=2):
    for _ in range(passes):
        poly = [
            p for a, b in zip(poly, poly[1:] + poly[:1])
            for p in ((0.75*a[0] + 0.25*b[0], 0.75*a[1] + 0.25*b[1]),
                      (0.25*a[0] + 0.75*b[0], 0.25*a[1] + 0.75*b[1]))
        ]
    return poly

# ---------------------------------------------------------------- skins
def dragao_lava(s):
    # Dragão de lava — seguindo diretamente o modelo "Lava Dragon" do jogo (assets/npcs/build_catalog.py):
    # paleta oficial do mob: lava (#4E282C), borda hostile (#B63B58), lava_mid (#75403B), tan (#AD7951) e ivory (#FFF4EC).
    # Cauda bifurcada suave atrás, asas grandes curvadas para trás em lava_mid com borda hostile e membrana tan recortada,
    # faixa dorsal oval (spine_stripe) em lava_mid com 5 espinhos dorsais marfim suaves em fila,
    # chifres laterais marfim saindo das têmporas, focinho arredondado na frente com narinas lava_mid e 4 presas marfim.
    s.base()
    lava, hostile, lava_mid, tan, ivory = "#4E282C", "#B63B58", "#75403B", "#AD7951", "#FFF4EC"
    # cauda bifurcada suave atrás (mesmo desenho do Lava Dragon do jogo, adaptada para frente = +Y)
    cauda = _chaikin([(-0.55, -1.45), (-0.64, -2.45), (-0.24, -2.98), (0.0, -2.62), (0.24, -2.98), (0.64, -2.45), (0.55, -1.45)], 2)
    s.flat(cauda, 0.82, 0.92, lava, outline=hostile, ow=0.11, smooth=False)
    # asas grandes curvadas para trás nos ombros (wing + wing_membrane do Lava Dragon do jogo)
    asa = _chaikin([(1.45, 0.15), (2.52, -0.08), (3.22, -1.05), (3.05, -2.42), (2.52, -1.52), (1.62, -0.95)], 2)
    s.sym(asa, 0.88, 0.88, lava_mid, outline=hostile, ow=0.11, smooth=False)
    mem = [(1.82, -0.58), (2.88, -1.92), (2.74, -1.02), (2.25, -0.86), (2.62, -0.68), (2.18, -0.32)]
    s.sym(mem, 1.77, 0.03, tan, smooth=False)
    # chifres laterais marfim saindo das laterais da cabeça para fora/trás (horn do Lava Dragon, por cima da borda)
    chifre = _chaikin([(1.32, 0.52), (2.48, 0.12), (1.85, -0.36)], 2)
    s.sym(chifre, 1.25, 0.82, ivory, smooth=False)
    # focinho oval na frente com borda hostile, narinas lava_mid e 4 presas marfim por cima da borda do focinho
    s.flat(ellipse(0.0, 1.56, 0.94, 0.52, n=28), 0.86, 1.12, lava, outline=hostile, ow=0.11)
    s.sym(ellipse(0.42, 1.62, 0.11, 0.16, n=14), TOP + 0.01, 0.03, lava_mid)
    for x0, y0 in [(0.34, 1.88), (0.72, 1.76)]:
        dente = [(x0 - 0.12, y0), (x0 + 0.12, y0), (x0, y0 + 0.42)]
        s.sym(dente, TOP, 0.08, ivory, smooth=False)
    # faixa dorsal oval (spine_stripe) em lava_mid + fila central de 5 espinhos marfim suaves (spine do Lava Dragon)
    s.flat(ellipse(0.0, -0.78, 0.42, 1.28, n=28), TOP, 0.035, lava_mid)
    for i in range(5):
        y = 0.08 - i * 0.52
        w = 0.28 - i * 0.028
        esp = _chaikin([(-w, y + 0.12), (0.0, y - 0.36), (w, y + 0.12)], 2)
        z0 = TOP + 0.035 if y > -1.75 else 1.74
        s.flat(esp, z0, 0.10, ivory, smooth=False)
    # mão: escama dorsal lava_mid e 3 garras marfim na frente
    s.hand_flat(ellipse(0.0, 0.05, 0.34, 0.28, n=12), 1.83, 0.03, lava_mid)
    for kk in (-1, 0, 1):
        garra = [(kk*0.22 - 0.08, 0.42), (kk*0.22 + 0.08, 0.42), (kk*0.24, 0.82)]
        s.hand_flat(garra, 1.25, 0.35, ivory, smooth=False)


def marshmallow(s):
    # Marshmallow tostado no graveto (ref. 77): graveto de madeira atravessando horizontalmente (ponta fina à esquerda,
    # galho bifurcado grosso à direita), topo em degradê tostado pixelado/em degraus quadrados do creme na frente
    # até o marrom caramelizado atrás com quadradinhos mais escuros; mão com gravetinho e mini marshmallow.
    s.base()
    creme, am_cl, am, lar, caram, marrom, galho, galho_c, galho_e = (
        "#FCF8E0", "#F8D870", "#F4AC38", "#E88424", "#C4640C", "#9C4C00", "#9C5800", "#A46C24", "#7C4C0C"
    )
    # graveto atravessando: ponta esquerda (-X) saindo reta e afinando; lado direito (+X) grosso com bifurcação
    esq_g = [(-1.6, 0.12), (-2.65, 0.12), (-3.15, -0.18), (-3.45, -0.32), (-3.42, -0.45), (-1.6, -0.45)]
    s.flat(esq_g, 0.85, 0.9, galho, outline=galho_e, ow=0.09, smooth=False)
    s.flat([(-1.75, 0.02), (-2.6, 0.02), (-3.05, -0.25), (-1.75, -0.25)], 1.76, 0.02, galho_c, smooth=False)
    dir_g = [
        (1.6, 0.25), (2.25, 0.25), (1.92, 0.68), (2.12, 0.92), (2.68, 0.45),
        (3.38, 0.22), (3.45, -0.42), (2.55, -0.35), (1.6, -0.35)
    ]
    s.flat(dir_g, 0.85, 0.95, galho, outline=galho_e, ow=0.09, smooth=False)
    s.flat([(1.75, 0.08), (2.55, 0.18), (3.25, 0.05), (3.28, -0.22), (1.75, -0.18)], 1.81, 0.02, galho_c, smooth=False)
    # topo do marshmallow em faixas escalonadas (degraus pixelados como na ref. 77), do mais claro na frente ao tostado atrás
    # frente creme clara nas quinas dianteiras
    s.flat([(-1.68, 1.65), (-0.75, 1.65), (-0.75, 1.15), (0.25, 1.15), (0.25, 1.65), (1.68, 1.65),
            (1.68, 0.85), (-1.68, 0.85)], TOP, 0.015, creme, smooth=False)
    # faixa laranja-mel no meio (escalonada em blocos, desviando do centro logo atrás dos olhos)
    faixa_lar = [
        (-1.72, 0.15), (-1.15, 0.15), (-1.15, 0.42), (-0.45, 0.42), (-0.45, 0.05),
        (0.45, 0.05), (0.45, 0.38), (1.15, 0.38), (1.15, 0.08), (1.72, 0.08),
        (1.72, -1.68), (-1.72, -1.68)
    ]
    s.flat(faixa_lar, TOP + 0.015, 0.015, am, smooth=False)
    # faixa caramelo mais atrás (degraus quadrados)
    faixa_car = [
        (-1.72, -0.45), (-1.05, -0.45), (-1.05, -0.22), (-0.35, -0.22), (-0.35, -0.62),
        (0.35, -0.62), (0.35, -0.28), (1.05, -0.28), (1.05, -0.55), (1.72, -0.55),
        (1.72, -1.72), (-1.72, -1.72)
    ]
    s.flat(faixa_car, TOP + 0.03, 0.015, lar, smooth=False)
    # topo bem tostado na borda de trás + quadradinhos escuros assados (como os blocos marrons da ref. 77)
    faixa_mar = [
        (-1.68, -0.95), (-1.12, -0.95), (-1.12, -1.25), (-0.72, -1.25), (-0.72, -0.88),
        (0.18, -0.88), (0.18, -1.22), (0.75, -1.22), (0.75, -0.92), (1.68, -0.92),
        (1.58, -1.74), (-1.58, -1.74)
    ]
    s.flat(faixa_mar, TOP + 0.045, 0.015, caram, smooth=False)
    for x0, y0, w, h, cor in [
        (-1.52, -1.58, 0.42, 0.42, marrom),
        (-0.55, -1.58, 0.48, 0.42, marrom),
        (0.82, -1.48, 0.46, 0.42, marrom),
        (-0.22, -1.32, 0.36, 0.34, galho_e),
    ]:
        s.flat([(x0, y0), (x0 + w, y0), (x0 + w, y0 + h), (x0, y0 + h)], TOP + 0.06, 0.015, cor, smooth=False)
    # mão: espetinho de madeira com mini marshmallow tostado na ponta
    s.hand_flat(_tubo([(-0.15, -0.45), (0.2, 0.65)], lambda t: 0.07, cap0=True, cap1=True, n=6), 1.8, 0.08, galho, outline=galho_e, ow=0.03, smooth=False)
    s.hand_flat([(-0.1, 0.25), (0.38, 0.15), (0.48, 0.58), (0.0, 0.68)], 1.86, 0.12, am_cl, outline=caram, ow=0.04, smooth=False)


def cthulhu(s):
    # Cthulhu (ref. 106): verde-esmeralda com tentáculos curvos saindo das bochechas/frente com ventosas,
    # quatro lóbulos curtos na frente do rosto, asinhas membranosas palmadas nos ombros de trás e manchas
    # circulares em tom verde-escuro espalhadas na cabeça; mão com tentáculo curvo.
    s.base()
    v_cl, v_med, v_esc, v_borda = "#08B478", "#0CA06C", "#089464", "#056844"
    # asinhas palmadas nos cantos traseiros-laterais (3 dedos com membrana recortada)
    asa = [
        (1.55, -0.15), (2.25, -0.05), (3.05, -0.25), (3.25, -0.52),
        (2.92, -0.78), (3.05, -1.18), (2.45, -1.15), (1.65, -1.05)
    ]
    s.sym(asa, 0.9, 0.9, v_cl, outline=v_esc, ow=0.09)
    for tx, ty in [(3.05, -0.35), (2.88, -0.78), (2.85, -1.12)]:
        s.sym(_tubo([(1.72, -0.55), (tx, ty)], lambda t: 0.07 - 0.03*t, n=6), 1.81, 0.02, v_esc, smooth=False)
    # dois pares de tentáculos curvos saindo das laterais da frente (com ventosas claras)
    for pts, w0, z in [
        ([(1.55, 0.65), (2.18, 0.85), (2.42, 1.35), (2.18, 1.85)], 0.28, 0.92),
        ([(1.25, 1.25), (1.95, 1.52), (2.48, 1.92), (2.68, 2.35)], 0.26, 0.96),
    ]:
        c = _curva(pts)
        s.sym(_tubo(c, lambda t, w0=w0: w0*(1 - 0.72*t), n=20), z, 0.95, v_med, outline=v_esc, ow=0.07, smooth=False)
        for u in (0.28, 0.55, 0.78):
            idx = min(int(u * (len(c) - 1)), len(c) - 1)
            px, py = c[idx]
            s.sym(ellipse(px, py, 0.09*(1.2 - u), 0.07*(1.2 - u), n=8), z + 0.96, 0.02, v_cl, outline=v_esc, ow=0.02)
    # quatro lóbulos curtos de tentáculos na borda da frente (barba do Cthulhu)
    for x in (-0.66, -0.22, 0.22, 0.66):
        s.flat(ellipse(x, 1.88, 0.24, 0.34, n=12), 0.88, 1.0, v_cl, outline=v_esc, ow=0.07)
    # manchas circulares verde-escuras espalhadas nas laterais e costas (longe da zona logo atrás dos olhos)
    for x, y, r in [(-1.05, -1.05, 0.34), (-0.25, -1.35, 0.22), (0.95, -0.95, 0.28), (1.25, -0.35, 0.2),
                    (-1.25, 0.05, 0.26), (0.65, -1.48, 0.16), (-0.75, -0.45, 0.14), (1.35, 0.45, 0.15)]:
        s.flat(ellipse(x, y, r, r, n=12), TOP, 0.02, v_esc)
    # mão: tentáculo curvo na frente com duas ventosas
    c_m = _curva([(0.0, 0.15), (0.35, 0.55), (0.15, 0.95), (-0.2, 1.05)])
    s.hand_flat(_tubo(c_m, lambda t: 0.2*(1 - 0.7*t), n=16), 1.25, 0.5, v_med, outline=v_esc, ow=0.04, smooth=False)
    for px, py in [(0.22, 0.45), (0.22, 0.78)]:
        s.hand_flat(ellipse(px, py, 0.07, 0.07, n=8), 1.76, 0.02, v_cl)


def falcao(s):
    # Falcão/águia (ref. 108): peito branco na frente, bico curvo cinza com cera azul-acinzentada, narinas e ponta preta,
    # manchas bege-claras angulosas em volta dos olhos, plumagem marrom em camadas recortadas no topo e cauda em leque
    # de 5 penas marrom-escuras com pontas bege-acinzentadas atrás; mão com 3 garras.
    s.base()
    m_cl, m_med, m_esc, branco, bege, cinza, cera, preto = (
        "#844820", "#6C3818", "#582C14", "#FCFCFC", "#C8BCB0", "#A8B0B0", "#789898", "#201014"
    )
    # cauda em leque de 5 penas atrás (marrom-muito-escuro #30180C com pontas bege-acinzentadas #887C6C)
    for i, ang in enumerate((-116, -103, -90, -77, -64)):
        a = math.radians(ang); P = _local(0.0, -1.35, a)
        L, w = 2.05, 0.34
        pts = [P(0, -0.6*w), P(0.85*L, -w), P(L, -0.55*w), P(1.06*L, 0), P(L, 0.55*w), P(0.85*L, w), P(0, 0.6*w)]
        s.flat(pts, 0.82 + 0.015*i, 0.95, "#30180C", outline=preto, ow=0.06)
        ponta = [P(0.76*L, -0.95*w), P(0.95*L, -0.65*w), P(1.06*L, 0), P(0.95*L, 0.65*w), P(0.76*L, 0.95*w)]
        s.flat(ponta, 1.78 + 0.015*i, 0.02, "#887C6C")
    # asinhas dobradas nas laterais (marrom-claro e médio)
    s.sym([(1.55, 0.45), (2.15, 0.15), (2.25, -0.65), (1.95, -1.25), (1.55, -1.05)], 0.9, 0.95, m_cl, outline=m_esc, ow=0.07)
    # peito branco passando da borda da frente (em meia-lua larga nas quinas dianteiras)
    peito = [(-1.68, 0.95), (-1.35, 1.65), (-0.65, 2.05), (0.0, 2.12), (0.65, 2.05), (1.35, 1.65), (1.68, 0.95),
             (1.15, 1.25), (0.0, 1.45), (-1.15, 1.25)]
    s.flat(peito, 0.86, 1.0, branco, outline="#887C6C", ow=0.07)
    # manchas claras (bege) angulosas em volta dos olhos (máscara de rapina da ref. 108)
    s.sym([(0.32, 0.82), (0.85, 0.98), (1.48, 0.72), (1.35, 0.18), (0.85, 0.08), (0.38, 0.35)], TOP, 0.025, bege)
    # camadas de penas marrons em arcos recortados nas costas (tons próximos para leitura limpa de cima)
    ondas = [(-1.55, -0.45), (-1.15, -0.15), (-0.75, -0.55), (-0.38, -0.05), (0.0, -0.55),
             (0.38, -0.05), (0.75, -0.55), (1.15, -0.15), (1.55, -0.45), (1.55, -1.68), (-1.55, -1.68)]
    s.flat(ondas, TOP, 0.02, m_esc)
    ondas2 = [(-1.35, -1.05), (-0.9, -0.78), (-0.45, -1.1), (0.0, -0.75), (0.45, -1.1), (0.9, -0.78), (1.35, -1.05),
              (1.25, -1.72), (-1.25, -1.72)]
    s.flat(ondas2, TOP + 0.02, 0.02, "#30180C")
    # bico de rapina na frente: base azul-acinzentada (cera), corpo cinza com narinas e ponta preta
    s.flat([(-0.52, 1.48), (-0.22, 1.25), (0.0, 1.18), (0.22, 1.25), (0.52, 1.48), (0.35, 1.72), (-0.35, 1.72)], TOP + 0.03, 0.08, cera)
    s.flat([(-0.42, 1.62), (0.42, 1.62), (0.25, 2.15), (0.0, 2.42), (-0.25, 2.15)], TOP + 0.03, 0.12, cinza, outline=m_esc, ow=0.05, smooth=False)
    s.sym(ellipse(0.11, 1.75, 0.035, 0.07, n=6), TOP + 0.15, 0.02, preto)
    s.flat([(-0.22, 2.08), (0.22, 2.08), (0.0, 2.44)], TOP + 0.15, 0.02, preto, smooth=False)
    # mão: três garras escuras na frente
    for kk in (-1, 0, 1):
        s.hand_flat(_espinho(kk*0.22, 0.35, math.radians(90 - 20*kk), 0.52, 0.1), 1.25, 0.4, "#30180C", outline=preto, ow=0.03, smooth=False)


def boneco_neve(s):
    # Boneco de neve (ref. 124): corpo branco-neve com borda cinza-clara (#B8B4B0), nariz de cenoura laranja
    # apontando para a frente com risquinhos escuros, e dois braços de galho de madeira assimétricos saindo das laterais
    # com três dedinhos cada; mão branca com raminho de madeira.
    s.base()
    branco, cinza, sombra, galho, galho_c, galho_e, cen, cen_e = (
        "#FCFCFC", "#B8B4B0", "#201C20", "#845C28", "#9C7038", "#684418", "#FC8800", "#CC7C14"
    )
    # braço de galho esquerdo (-X) e direito (+X), levemente assimétricos como na ref. 124
    for k, rot_g in ((-1, 0.12), (1, -0.08)):
        P = _local(k * 1.45, 0.15, (0.0 if k > 0 else math.pi) + rot_g)
        ramo = [
            P(0.0, -0.22), P(0.95, -0.22), P(1.38, -0.68), P(1.58, -0.58), P(1.28, -0.18),
            P(1.95, -0.12), P(2.02, 0.08), P(1.32, 0.15), P(1.65, 0.58), P(1.42, 0.72),
            P(0.92, 0.24), P(0.0, 0.22)
        ]
        s.flat(ramo, 1.05, 0.75, galho, outline=galho_e, ow=0.08)
        miolo = [P(0.1, -0.08), P(1.05, -0.06), P(1.55, -0.02), P(1.05, 0.08), P(0.1, 0.08)]
        s.flat(miolo, 1.81, 0.02, galho_c)
    # nariz de cenoura laranja na frente (entre/à frente dos olhos, apontando para +Y) com sulcos
    nariz = [(-0.34, 1.25), (0.0, 1.12), (0.34, 1.25), (0.36, 1.65), (0.18, 2.15), (0.0, 2.38), (-0.18, 2.15), (-0.36, 1.65)]
    s.flat(nariz, TOP + 0.02, 0.16, cen, outline=cen_e, ow=0.07)
    for y0, x0, x1 in [(1.52, -0.2, 0.05), (1.78, -0.05, 0.18), (2.02, -0.14, 0.06)]:
        s.flat(_tubo([(x0, y0), (x1, y0 + 0.06)], lambda t: 0.025, n=4), TOP + 0.18, 0.015, galho_e, smooth=False)
    # mão: bola de neve com gravetinho saindo para o lado
    s.hand_flat(_tubo([(0.15, 0.1), (0.78, 0.45)], lambda t: 0.09 - 0.03*t, cap1=True, n=6), 1.35, 0.35, galho, outline=galho_e, ow=0.03, smooth=False)
    s.hand_flat(_tubo([(0.52, 0.3), (0.68, 0.62)], lambda t: 0.06, cap1=True, n=4), 1.35, 0.35, galho, outline=galho_e, ow=0.03, smooth=False)


def pinha(s):
    # Pinha / flor-estrela da floresta (ref. 151): silhueta inteira formada por 8 pétalas/escamas marrons pontudas
    # abrindo em estrela ao redor do corpo, e 2 bagas grandes roxas na metade de trás com brilho lilás
    # (em z < TOP para o topo não cobrir os olhos da prévia!); mão com escama marrom e frutinha roxa.
    s.base()
    m_cl, m_esc, m_borda, roxo, lilas = "#805008", "#7C4808", "#583004", "#3C286C", "#8054B4"
    # 8 pétalas/escamas grandes formando a silhueta em estrela (nos múltiplos de 45°, topo em z = 1.98 < TOP para liberar os olhos)
    for i in range(8):
        g = i * 45
        a = math.radians(g); P = _local(0.0, 0.0, a)
        L = 2.95 if i % 2 == 0 else 2.85
        w = 0.92 if i % 2 == 0 else 0.88
        pet = [P(0.6, -0.55*w), P(0.55*L, -w), P(0.85*L, -0.52*w), P(L, 0.0), P(0.85*L, 0.52*w), P(0.55*L, w), P(0.6, 0.55*w)]
        s.flat(pet, 0.85 + 0.015*(i % 2), 1.1, m_cl if i % 2 == 0 else m_esc, outline=m_borda, ow=0.09)
        pet_in = [P(1.15, -0.35*w), P(0.58*L, -0.68*w), P(0.88*L, 0.0), P(0.58*L, 0.68*w), P(1.15, 0.35*w)]
        s.flat(pet_in, 1.97, 0.015, m_cl)
    # duas bagas roxas arredondadas nas diagonais de trás (x = ±0.78, y = -0.78, alinhadas com os olhos na frente)
    for k in (-1, 1):
        cx, cy = k * 0.78, -0.78
        s.flat(ellipse(cx, cy, 0.46, 0.46, n=16), TOP, 0.1, roxo, outline="#241844", ow=0.05)
        s.flat(ellipse(cx - 0.14, cy + 0.14, 0.16, 0.16, n=10), TOP + 0.1, 0.02, lilas)
    # mão: escama pontuda com uma baga roxa no centro
    P = _local(0.0, 0.0, math.radians(90))
    s.hand_flat([P(-0.2, -0.38), P(0.35, -0.42), P(0.82, 0.0), P(0.35, 0.42), P(-0.2, 0.38)], 1.25, 0.5, m_cl, outline=m_borda, ow=0.04)
    s.hand_flat(ellipse(0.0, 0.05, 0.24, 0.24, n=12), 1.84, 0.06, roxo, outline="#241844", ow=0.03)
    s.hand_flat(ellipse(-0.06, 0.11, 0.08, 0.08, n=8), 1.9, 0.02, lilas)


def urso_madeira(s):
    # Totem / urso entalhado em madeira (ref. 207): marrom-madeira escuro (#4C3814) com 4 abas/orelhas semicirculares
    # (nas laterais, atrás e na frente) com anéis concêntricos entalhados, aros concêntricos em volta dos olhos
    # e entalhe geométrico nas costas (traços em tons próximos da madeira); mão de madeira com anel entalhado.
    s.base()
    m_esc, m_med, m_cl, m_borda = "#4C3814", "#544020", "#604828", "#38280C"
    # 4 abas semicirculares na silhueta (esquerda, direita, trás e frente) com anéis concêntricos
    for cx, cy, rx, ry in [(-1.82, 0.0, 0.65, 0.68), (1.82, 0.0, 0.65, 0.68), (0.0, -1.82, 0.68, 0.62), (0.0, 1.82, 0.62, 0.52)]:
        s.flat(ellipse(cx, cy, rx, ry, n=16), 0.88, 1.0, m_med, outline=m_borda, ow=0.08)
        s.flat(ellipse(cx, cy, rx*0.68, ry*0.68, n=14), 1.89, 0.02, m_esc)
        s.flat(ellipse(cx, cy, rx*0.38, ry*0.38, n=12), 1.91, 0.02, m_cl)
    # aros concêntricos entalhados ao redor de cada olho (marca registrada da ref. 207)
    for k in (-1, 1):
        s.flat(ellipse(k*EYE_X, EYE_Y, 0.72, 0.72, n=20), TOP, 0.02, m_med)
        s.flat(ellipse(k*EYE_X, EYE_Y, 0.58, 0.58, n=18), TOP + 0.02, 0.015, m_esc)
    # entalhe geométrico no topo (três traços arredondados em cruz aberta nas costas, em tom próximo m_cl)
    s.flat(_tubo([(0.0, -0.22), (0.0, -1.25)], lambda t: 0.16, cap0=True, cap1=True, n=8), TOP + 0.02, 0.03, m_cl, smooth=False)
    for k in (-1, 1):
        s.flat(_tubo([(k*0.38, -0.72), (k*0.92, -0.72)], lambda t: 0.14, cap0=True, cap1=True, n=6), TOP + 0.02, 0.03, m_cl, smooth=False)
    # mão: disco de madeira com anel concêntrico entalhado
    s.hand_flat(ellipse(0.0, 0.0, 0.42, 0.42, n=14), 1.83, 0.03, m_med)
    s.hand_flat(ellipse(0.0, 0.0, 0.24, 0.24, n=12), 1.86, 0.02, m_esc)
    s.hand_flat(ellipse(0.0, 0.0, 0.11, 0.11, n=10), 1.88, 0.02, m_cl)


def raposa_enfaixada(s):
    # Raposa/lobo azul enfaixado com cerejas (ref. 213): pelo azul-claro (#749CE0) com bochechas felpudas creme (#F0E4D0),
    # orelhas grandes pontudas atrás/laterais (base creme, interior pêssego #ECC4AC, pontas azuis #5078C0 com bolinhas),
    # focinho creme na frente com nariz azul-escuro (#2C3860), faixa de bandagem bege-dourada (#D8B07C / #C8906C)
    # atravessando o lado esquerdo da cabeça com laço lateral, e par de cerejas (#942058) com folhinhas verdes (#306028).
    s.base()
    azul, azul_e, ink, creme, pess, faix1, faix2, cer, cer_c, folha = (
        "#749CE0", "#5078C0", "#2C3860", "#F0E4D0", "#ECC4AC", "#D8B07C", "#C8906C", "#942058", "#B8344C", "#306028"
    )
    # tufos de pelo creme e azul nas bochechas/laterais (silhueta felpuda)
    tufo_lat = [(1.55, 1.35), (2.25, 1.15), (1.92, 0.78), (2.42, 0.35), (1.98, 0.05), (2.28, -0.42), (1.55, -0.45)]
    s.sym(tufo_lat, 0.88, 0.98, creme, outline=ink, ow=0.09, smooth=False)
    s.sym([(1.5, 0.85), (2.05, 0.55), (1.75, 0.25), (2.08, -0.05), (1.5, -0.2)], 1.87, 0.02, azul, smooth=False)
    # orelhas enormes pontudas nas laterais de trás: base creme, miolo pêssego recortado e ponta azul com bolinha no topo
    for k in (-1, 1):
        X = lambda P: [(k*x, y) for x, y in P]
        orelha = [(0.45, -0.85), (1.65, -0.65), (2.35, -1.65), (2.15, -3.05), (1.25, -2.55), (0.55, -1.65)]
        s.flat(X(orelha), 0.92, 1.0, creme, outline=ink, ow=0.09)
        ponta_az = [(1.62, -1.85), (2.28, -1.72), (2.15, -3.05), (1.28, -2.55)]
        s.flat(X(ponta_az), 1.93, 0.025, azul, smooth=False)
        s.flat(X([(1.78, -2.1), (2.12, -2.05), (2.05, -2.85), (1.55, -2.55)]), 1.955, 0.02, azul_e, smooth=False)
        miolo = [(0.88, -1.05), (1.65, -1.02), (1.88, -1.95), (1.42, -1.72), (1.28, -2.05), (0.88, -1.55)]
        s.flat(X(miolo), 1.93, 0.02, pess, smooth=False)
        # bolinha azul na ponta da orelha (charme da ref. 213)
        s.flat(ellipse(k*1.95, -3.22, 0.24, 0.24, n=12), 0.95, 0.98, azul, outline=ink, ow=0.07)
    # focinho creme na frente com nariz triangular azul-escuro e mancha azul-escura entre os olhos
    s.flat(ellipse(0.0, 0.62, 0.65, 0.35, n=14), TOP, 0.015, azul_e)
    s.flat([(-0.62, 1.35), (0.62, 1.35), (0.72, 1.82), (0.35, 2.15), (0.0, 2.22), (-0.35, 2.15), (-0.72, 1.82)],
           TOP + 0.015, 0.06, creme, outline=ink, ow=0.07)
    s.flat([(-0.22, 1.65), (0.22, 1.65), (0.0, 1.92)], TOP + 0.08, 0.03, ink)
    # sobrancelha creme atrás/acima do olho direito (+X) e duas gotinhas azul-claras na bochecha direita
    s.flat(ellipse(0.85, 0.08, 0.45, 0.16, n=12, rot=0.18), TOP + 0.02, 0.025, creme)
    s.flat(ellipse(1.18, 1.35, 0.18, 0.11, n=10), TOP + 0.02, 0.02, "#98B8E0")
    s.flat(ellipse(1.42, 1.58, 0.11, 0.07, n=8), TOP + 0.02, 0.02, "#98B8E0")
    # faixa de bandagem bege cobrindo o lado esquerdo (-X) por cima do olho esquerdo, igual à ref. 213!
    band = [(-0.24, 1.92), (-1.18, 1.85), (-1.28, -1.68), (-0.34, -1.75)]
    s.flat(band, TOP + 0.03, 0.09, faix1, outline=faix2, ow=0.05)
    s.flat([(-0.88, 1.88), (-1.15, 1.85), (-1.25, -1.66), (-0.98, -1.7)], TOP + 0.12, 0.015, faix2, smooth=False)
    # pontas do nó da bandagem saindo na lateral esquerda (-X)
    for ang, L in [(155, 0.65), (195, 0.62)]:
        P = _local(-1.18, 0.35, math.radians(ang))
        s.flat([P(0, -0.14), P(L, -0.18), P(L + 0.1, 0), P(L, 0.18), P(0, 0.14)], TOP + 0.02, 0.05, faix2)
    # par de cerejas com cabinho e duas folhinhas verdes sobre a borda da faixa no lado esquerdo (-X)
    s.flat(_tubo([(-1.05, -0.22), (-1.28, -0.68), (-1.52, -0.32)], lambda t: 0.035, n=8), TOP + 0.125, 0.02, folha, smooth=False)
    for ang in (135, 45):
        P = _local(-1.28, -0.68, math.radians(ang))
        s.flat([P(0, 0), P(0.22, 0.14), P(0.48, 0), P(0.22, -0.14)], TOP + 0.13, 0.025, folha)
    s.flat(ellipse(-1.05, -0.2, 0.26, 0.26, n=12), TOP + 0.125, 0.06, cer, outline="#681438", ow=0.03)
    s.flat(ellipse(-0.98, -0.28, 0.09, 0.06, n=8), TOP + 0.185, 0.015, cer_c)
    s.flat(ellipse(-1.52, -0.3, 0.18, 0.18, n=10), TOP + 0.125, 0.05, cer, outline="#681438", ow=0.03)
    # mão: patinha azul com faixa de bandagem bege e almofadinha creme
    s.hand_flat([(-0.55, -0.15), (0.55, -0.15), (0.55, 0.18), (-0.55, 0.18)], 1.82, 0.05, faix1, outline=faix2, ow=0.03, smooth=False)
    for k in (-1, 0, 1):
        s.hand_flat(ellipse(k*0.22, 0.42, 0.11, 0.14, n=8), 1.4, 0.35, creme, outline=ink, ow=0.03)


def robo(s):
    # Robô / autômato de bronze (ref. 215): moldura metálica acobreada (#A86448) em volta da tela marrom-escura (#342020)
    # com faixas horizontais de grade (#442828), visores laranja-dourados (#E49824, Neon leve) em volta dos olhos,
    # e duas grandes antenas/orelhas mecânicas nas laterais com fones circulares e 3 luzes laranjas cada; mão de garra mecânica.
    s.base()
    tela, grade, marrom, cobre, cobre_e, visor, ink = (
        "#342020", "#442828", "#502C2C", "#A86448", "#7C483C", "#E49824", "#281616"
    )
    # moldura acobreada externa em volta do corpo + painel escuro interno com 3 frisos horizontais
    s.flat(_radial(lambda a: _raio_corpo(a) + 0.04, n=72, maos=0.72), TOP, 0.025, cobre, outline=ink, ow=0.06)
    s.flat(_radial(lambda a: _raio_corpo(a) - 0.22, n=72, maos=0.82), TOP + 0.025, 0.02, tela, outline=marrom, ow=0.05)
    for y in (-1.05, -0.45, 0.15):
        s.flat([(-1.45, y - 0.08), (1.45, y - 0.08), (1.45, y + 0.08), (-1.45, y + 0.08)], TOP + 0.045, 0.015, grade, smooth=False)
    # aros laranja-dourados vazados ao redor dos olhos na frente (deixam os olhos pretos e brilhos 100% visíveis no centro!)
    for k in (-1, 1):
        for a0, a1 in ((-0.08, math.pi + 0.08), (math.pi - 0.08, 2 * math.pi + 0.08)):
            s.flat(_arco(k*EYE_X, EYE_Y, 0.45, 0.70, a0, a1, n=14), TOP + 0.04, 0.02, ink, smooth=False)
            s.flat(_arco(k*EYE_X, EYE_Y, 0.48, 0.65, a0, a1, n=14), TOP + 0.06, 0.025, visor, emit=0.8, smooth=False)
    # antenas/orelhas mecânicas grandes nas laterais: disco de fone na frente + haste comprida para trás com 3 luzes laranjas
    ant = [(1.68, 0.85), (2.25, 0.75), (2.58, -0.55), (2.35, -1.95), (1.95, -2.15), (1.72, -1.85), (1.68, -0.45)]
    s.sym(ant, 0.88, 1.15, cobre, outline=ink, ow=0.09, smooth=False)
    s.sym([(1.85, 0.65), (2.05, 0.6), (2.15, -1.85), (1.88, -1.85)], 2.04, 0.02, cobre_e, smooth=False)
    # 3 luzinhas laranjas em diagonal na aleta de cada antena
    for dy, w in [(-0.35, 0.22), (-0.82, 0.26), (-1.32, 0.3)]:
        s.sym([(2.08, dy), (2.36, dy - 0.18), (2.34, dy - 0.36), (2.06, dy - 0.18)],
              2.05, 0.02, visor, emit=0.8, smooth=False)
    # fone circular na base dianteira de cada antena
    s.sym(ellipse(1.98, 0.55, 0.38, 0.48, n=14), 0.92, 1.18, cobre, outline=ink, ow=0.07)
    s.sym(ellipse(2.02, 0.55, 0.22, 0.3, n=12), 2.11, 0.02, cobre_e)
    # mão: pinça mecânica de cobre em U na frente com luz laranja no dorso
    for k in (-1, 1):
        s.hand_flat([(k*0.18, 0.25), (k*0.45, 0.35), (k*0.42, 0.78), (k*0.15, 0.88), (k*0.12, 0.62), (k*0.24, 0.55)],
                    1.3, 0.45, cobre, outline=ink, ow=0.04, smooth=False)
    s.hand_flat(ellipse(0.0, 0.0, 0.2, 0.14, n=10), 1.86, 0.02, visor, emit=0.8)


def helicoptero(s):
    # Helicóptero / girocóptero (ref. 228): corpo octogonal de metal cinza-esverdeado (#586460 / #64746C) com degrau
    # superior chanfrado, domo de bronze escuro (#342814) no centro-trás e hélice grande de 4 pás de madeira (#644C28 / #7C5828)
    # em X com cubo metálico central no topo; mão com mini hélice.
    s.base()
    metal, metal_cl, metal_esc, domo, domo_b, pa1, pa2, ink = (
        "#586460", "#64746C", "#384840", "#342814", "#241C0C", "#644C28", "#7C5828", "#201C20"
    )
    # base octogonal chanfrada passando um pouco da borda para dar o aspecto de fuselagem facetada
    octo = [(-1.25, 1.92), (1.25, 1.92), (2.02, 1.15), (2.02, -1.15), (1.25, -1.92), (-1.25, -1.92), (-2.02, -1.15), (-2.02, 1.15)]
    s.flat(octo, 0.85, 1.12, metal, outline=metal_esc, ow=0.09, smooth=False)
    # degrau metálico octogonal menor no topo (atrás da linha dos olhos)
    degrau = [(-1.05, 0.18), (1.05, 0.18), (1.58, -0.25), (1.58, -1.28), (1.05, -1.68), (-1.05, -1.68), (-1.58, -1.28), (-1.58, -0.25)]
    s.flat(degrau, TOP, 0.18, metal_cl, outline=metal_esc, ow=0.07, smooth=False)
    s.flat([(-0.95, 0.05), (0.95, 0.05), (1.38, -0.32), (1.38, -1.18), (0.95, -1.52), (-0.95, -1.52), (-1.38, -1.18), (-1.38, -0.32)],
           TOP + 0.18, 0.02, metal, smooth=False)
    # domo redondo marrom-bronze do motor (centrado em y = -0.95, atrás dos olhos)
    cx, cy = 0.0, -0.95
    s.flat(ellipse(cx, cy, 1.05, 0.85, n=24), TOP + 0.2, 0.24, domo, outline=domo_b, ow=0.07)
    s.flat(_crescente(math.radians(120), math.radians(210), 0.92, 0.28, cx=cx, cy=cy), TOP + 0.44, 0.015, "#4C3818")
    # 4 pás grandes da hélice em X (ângulos 18°, 162°, 198°, 342° bem abertos para os lados, sem passar sobre os olhos!)
    for g in (18, 162, 198, 342):
        a = math.radians(g); P = _local(cx, cy, a)
        L = 2.65
        pa = [P(0.25, -0.16), P(0.95, -0.18), P(1.05, -0.32), P(L - 0.15, -0.34), P(L, -0.18),
              P(L, 0.18), P(L - 0.15, 0.28), P(0.25, 0.22)]
        s.flat(pa, TOP + 0.46, 0.12, pa1, outline=domo_b, ow=0.07, smooth=False)
        s.flat([P(0.35, -0.02), P(L - 0.18, -0.02), P(L - 0.18, 0.16), P(0.35, 0.12)], TOP + 0.58, 0.015, pa2, smooth=False)
    # cubo metálico central da hélice por cima do cruzamento das pás
    s.flat(ellipse(cx, cy, 0.44, 0.4, n=16), TOP + 0.58, 0.16, metal_esc, outline=ink, ow=0.05)
    s.flat(ellipse(cx, cy, 0.28, 0.25, n=14), TOP + 0.74, 0.02, metal_cl)
    # mão: mini hélice de duas pás com pino metálico central
    for g in (35, 215):
        P = _local(0.0, 0.0, math.radians(g))
        s.hand_flat([P(0.1, -0.12), P(0.75, -0.16), P(0.75, 0.16), P(0.1, 0.12)], 1.82, 0.08, pa2, outline=domo_b, ow=0.03, smooth=False)
    s.hand_flat(ellipse(0.0, 0.0, 0.18, 0.18, n=10), 1.9, 0.05, metal_cl, outline=metal_esc, ow=0.03)


LOTE = [
    ("dragao_lava", dragao_lava, "#4E282C", "#B63B58", "#4E282C", "#B63B58"),
    ("marshmallow", marshmallow, "#F8D870", "#9C5800", "#F8D870", "#9C5800"),
    ("cthulhu", cthulhu, "#08B478", "#089464", "#08B478", "#089464"),
    ("falcao", falcao, "#6C3818", "#30180C", "#6C3818", "#30180C"),
    ("boneco_neve", boneco_neve, "#FCFCFC", "#B8B4B0", "#FCFCFC", "#B8B4B0"),
    ("pinha", pinha, "#805008", "#583004", "#805008", "#583004"),
    ("urso_madeira", urso_madeira, "#4C3814", "#38280C", "#4C3814", "#38280C"),
    ("raposa_enfaixada", raposa_enfaixada, "#749CE0", "#2C3860", "#749CE0", "#2C3860"),
    ("robo", robo, "#502C2C", "#281616", "#A86448", "#281616"),
    ("helicoptero", helicoptero, "#586460", "#384840", "#586460", "#384840"),
]
