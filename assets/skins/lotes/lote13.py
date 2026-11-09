# Lote 13 — skins de corpo ("simples com toque" e temáticas). Montar com build_skins.py ou render_lote.py.
# gato_rosa, pinguim, gato_lilas, coco, lama, jarra_vidro, geleia_rubi, fantasminha, anciao, sombra_carmesim.
from skin_lib import *


# ---------------------------------------------------------------- ajudantes do lote
def _pol(a, r, cx=0.0, cy=0.0):
    return (cx + math.cos(a) * r, cy + math.sin(a) * r)


def _local(x0, y0, ang):
    ca, sa = math.cos(ang), math.sin(ang)
    return lambda u, v: (x0 + ca * u - sa * v, y0 + sa * u + ca * v)


def _chaikin(poly, passes=2):
    for _ in range(passes):
        poly = [
            p for a, b in zip(poly, poly[1:] + poly[:1])
            for p in ((0.75 * a[0] + 0.25 * b[0], 0.75 * a[1] + 0.25 * b[1]),
                      (0.25 * a[0] + 0.75 * b[0], 0.25 * a[1] + 0.75 * b[1]))
        ]
    return poly


def _curva(ctrl, per=6):
    P = [ctrl[0]] + list(ctrl) + [ctrl[-1]]
    out = []
    for i in range(1, len(P) - 2):
        p0, p1, p2, p3 = P[i - 1], P[i], P[i + 1], P[i + 2]
        for k in range(per):
            t = k / per
            t2, t3 = t * t, t * t * t
            out.append(tuple(
                0.5 * (2 * p1[j] + (-p0[j] + p2[j]) * t
                       + (2 * p0[j] - 5 * p1[j] + 4 * p2[j] - p3[j]) * t2
                       + (-p0[j] + 3 * p1[j] - 3 * p2[j] + p3[j]) * t3)
                for j in (0, 1)
            ))
    out.append(tuple(ctrl[-1]))
    return out


def _tubo(c, wf, t0=0.0, t1=1.0, cap0=False, cap1=False, n=24):
    L = [0.0]
    for a, b in zip(c, c[1:]):
        L.append(L[-1] + math.dist(a, b))
    tot = L[-1]

    def pos(t):
        d = min(max(t, 0.0), 1.0) * tot
        for i in range(len(c) - 1):
            if d <= L[i + 1] or i == len(c) - 2:
                seg = (L[i + 1] - L[i]) or 1e-9
                u = min(max((d - L[i]) / seg, 0.0), 1.0)
                return (c[i][0] + (c[i + 1][0] - c[i][0]) * u,
                        c[i][1] + (c[i + 1][1] - c[i][1]) * u)

    def tang(t):
        a, b = pos(t - 0.012), pos(t + 0.012)
        dx, dy = b[0] - a[0], b[1] - a[1]
        l = math.hypot(dx, dy) or 1
        return dx / l, dy / l

    esq, dir_ = [], []
    for k in range(n + 1):
        t = t0 + (t1 - t0) * k / n
        (x, y), (dx, dy), w = pos(t), tang(t), max(wf(t), 0.01)
        esq.append((x - dy * w, y + dx * w))
        dir_.append((x + dy * w, y - dx * w))
    fim, ini = [], []
    if cap1:
        (x, y), (dx, dy), w = pos(t1), tang(t1), max(wf(t1), 0.01)
        for k in range(1, 6):
            th = math.pi * k / 6
            fim.append((x + w * (-dy * math.cos(th) + dx * math.sin(th)),
                        y + w * (dx * math.cos(th) + dy * math.sin(th))))
    if cap0:
        (x, y), (dx, dy), w = pos(t0), tang(t0), max(wf(t0), 0.01)
        for k in range(1, 6):
            th = math.pi * k / 6
            ini.append((x + w * (dy * math.cos(th) - dx * math.sin(th)),
                        y + w * (-dx * math.cos(th) - dy * math.sin(th))))
    return esq + fim + list(reversed(dir_)) + ini


def _arco(cx, cy, r0, r1, a0, a1, n=14):
    A = [a0 + (a1 - a0) * i / (n - 1) for i in range(n)]
    return [_pol(a, r1, cx, cy) for a in A] + [_pol(a, r0, cx, cy) for a in reversed(A)]


def _espinho(x0, y0, ang, L, w, curva=0.0):
    P = _local(x0, y0, ang)
    c = _curva([P(0, 0), P(L * 0.5, curva * L), P(L, curva * L * 2.2)], per=5)
    return _tubo(c, lambda t: w * (1 - t) ** 0.85, cap0=True, n=12)


def _anel_quads(s, cx, cy, r_in, r_out, z, thick, color, n=16, rot_deg=0.0, emit=0.0):
    rot = math.radians(rot_deg)
    for i in range(n):
        a0 = rot + 2 * math.pi * i / n
        a1 = rot + 2 * math.pi * (i + 1) / n
        q = [
            (cx + r_in * math.cos(a0), cy + r_in * math.sin(a0)),
            (cx + r_out * math.cos(a0), cy + r_out * math.sin(a0)),
            (cx + r_out * math.cos(a1), cy + r_out * math.sin(a1)),
            (cx + r_in * math.cos(a1), cy + r_in * math.sin(a1)),
        ]
        s.flat(q, z, thick, color, smooth=False, emit=emit)


def _extensao_sem_costura(s, pts, cor_base, cor_borda, ow=0.09, z_cap_top=2.01, z_base=0.68, z_cap=1.78):
    """Cria uma extensão de silhueta cujo contorno fica abaixo do chanfro do corpo (z_top=1.78 < 1.82)
    e cuja tampa superior sem contorno cobre o Outline do corpo (z=1.90) sem dar Z-fighting no topo (2.01 > 2.00)."""
    s.flat(pts, z_base, 1.10, cor_base, outline=cor_borda, ow=ow, smooth=False)
    s.flat(pts, z_cap, z_cap_top - z_cap, cor_base, smooth=False)


# ---------------------------------------------------------------- 1. Gato Rosa
def gato_rosa(s):
    # Gatinho/raposinha branca fofa (#FCFCFC) com contorno rosa-choque (#C4144C),
    # orelhas pontudas felpudas nos cantos traseiros com tufos internos rosa (#DC7090 / #C4144C),
    # tufinhos duplos nas bochechas e rabinho branco/rosa atrás; mãos brancas com almofadinha rosa.
    corpo, borda, rosa_med, rosa_cl, rosa_esc = (
        "#FCFCFC", "#C4144C", "#DC7090", "#F4D8E0", "#C8304C"
    )
    s.base()

    # Rabinho branco/rosa fofo atrás com ponta rosada
    cauda = _chaikin([
        (-0.58, -1.45), (-0.78, -2.35), (0.0, -3.12), (0.78, -2.35), (0.58, -1.45)
    ], 2)
    s.flat(cauda, 0.84, 1.06, corpo, outline=borda, ow=0.09, smooth=False)
    s.flat(_chaikin([(-0.48, -1.85), (-0.52, -2.42), (0.0, -2.96), (0.52, -2.42), (0.48, -1.85)], 2),
           1.91, 0.015, rosa_cl, smooth=False)
    s.flat(_chaikin([(-0.34, -2.22), (-0.36, -2.55), (0.0, -2.90), (0.36, -2.55), (0.34, -2.22)], 1),
           1.926, 0.015, rosa_med, smooth=False)

    # Orelhas pontudas felpudas nos cantos traseiros com tufos internos rosa (#DC7090 / #C4144C)
    for k in (-1, 1):
        X = lambda P: [(k * x, y) for x, y in P]
        orelha = _chaikin([
            (0.66, -0.80), (1.72, -0.58), (2.68, -1.28), (2.90, -2.52),
            (2.05, -2.58), (1.14, -1.88), (0.56, -1.40)
        ], 2)
        s.flat(X(orelha), 0.88, 1.04, corpo, outline=borda, ow=0.10, smooth=False)
        sombra_or = _chaikin([
            (0.95, -0.92), (1.78, -0.75), (2.52, -1.35), (2.62, -2.32), (1.92, -2.28), (1.05, -1.58)
        ], 1)
        s.flat(X(sombra_or), 1.93, 0.012, rosa_cl, smooth=False)
        miolo_or = _chaikin([
            (1.18, -1.08), (1.98, -1.05), (2.48, -1.98), (1.82, -1.98), (1.18, -1.52)
        ], 1)
        s.flat(X(miolo_or), 1.944, 0.015, rosa_med, smooth=False)
        tufo_int = _chaikin([
            (1.22, -1.18), (1.72, -1.18), (2.05, -1.68), (1.65, -1.58),
            (1.75, -1.82), (1.35, -1.62)
        ], 1)
        s.flat(X(tufo_int), 1.96, 0.016, rosa_esc, smooth=False)

    # Tufinhos duplos fofos nas bochechas
    tufo_lat = _chaikin([
        (1.42, -0.32), (2.35, 0.04), (1.88, 0.42),
        (2.40, 0.88), (1.88, 1.25), (2.02, 1.54), (1.40, 1.50)
    ], 1)
    s.sym(tufo_lat, 0.86, 1.04, corpo, outline=borda, ow=0.09, smooth=False)
    s.sym(_chaikin([(1.68, -0.10), (2.20, 0.04), (1.80, 0.30)], 1), 1.91, 0.014, rosa_cl, smooth=False)
    s.sym(_chaikin([(1.72, 0.56), (2.25, 0.86), (1.82, 1.05)], 1), 1.91, 0.014, rosa_cl, smooth=False)

    # Bochechinhas rosadas suaves nas laterais e sombreado macio (#F4D8E0) nas bordas laterais/traseiras
    s.sym(ellipse(1.34, 0.85, 0.28, 0.18, n=14, rot=-0.18), TOP + 0.004, 0.008, rosa_cl)
    s.sym(ellipse(1.34, 0.85, 0.16, 0.10, n=12, rot=-0.18), TOP + 0.012, 0.008, rosa_med)
    s.sym(_chaikin([(1.25, -0.15), (1.66, -0.35), (1.66, -1.18), (1.22, -1.42)], 2),
          TOP, 0.005, rosa_cl, smooth=False)

    # Narizinho triangular fofo de gatinho na borda frontal (y = 1.38..1.66)
    nar = _chaikin([(-0.22, 1.38), (0.22, 1.38), (0.24, 1.52), (0.0, 1.66), (-0.24, 1.52)], 2)
    s.flat(nar, TOP + 0.006, 0.016, rosa_esc, smooth=False)

    # Mão: patinha branca com almofadinha central rosa (#DC7090) e 3 dedinhos em arco (#C8304C)
    s.hand_flat(ellipse(0.0, -0.06, 0.26, 0.20, n=14), 1.82, 0.022, rosa_med)
    for tx, ty in [(-0.24, 0.22), (0.0, 0.28), (0.24, 0.22)]:
        s.hand_flat(ellipse(tx, ty, 0.10, 0.12, n=10), 1.82, 0.022, rosa_esc)


# ---------------------------------------------------------------- 2. Pinguim
def pinguim(s):
    # Pinguim preto e branco (#202020, contorno #3C3C3C) com nadadeiras laterais inclinadas,
    # máscara facial branca em formato de coração/M ao redor dos olhos (#FCFCFC / #F0F0F0 sem tapar os olhos!),
    # bico triangular laranja (#E07034 / #E06038) na frente e rabinho curto atrás; mãos pretas em formato de nadadeira.
    corpo, borda, branco, branco_med, cinza_cl, bico_cl, bico_esc = (
        "#202020", "#3C3C3C", "#FCFCFC", "#F0F0F0", "#D4D4D4", "#E07034", "#E06038"
    )
    s.base()

    # Rabinho curto de pinguim atrás
    rabinho = _chaikin([
        (-0.75, -1.45), (-0.92, -2.18), (-0.42, -2.02),
        (0.0, -2.52),
        (0.42, -2.02), (0.92, -2.18), (0.75, -1.45)
    ], 1)
    s.flat(rabinho, 0.84, 1.06, corpo, outline=borda, ow=0.09, smooth=False)

    # Nadadeiras laterais inclinadas para os lados/trás
    nadadeira = _chaikin([
        (1.45, 0.82), (2.32, 0.48), (2.88, -0.35), (2.95, -1.22),
        (2.28, -1.32), (1.70, -0.70), (1.45, -0.35)
    ], 2)
    s.sym(nadadeira, 0.86, 1.06, corpo, outline=borda, ow=0.10, smooth=False)
    s.sym(_chaikin([(1.65, 0.45), (2.20, 0.22), (2.62, -0.45), (2.58, -1.02), (2.08, -0.95), (1.65, -0.32)], 2),
          1.93, 0.016, borda, smooth=False)

    # Bico triangular laranja (#E06038 base + #E07034 cume) saliente na frente
    bico = _chaikin([
        (-0.74, 1.48), (-0.54, 2.12), (0.0, 2.65), (0.54, 2.12), (0.74, 1.48), (0.0, 1.38)
    ], 2)
    _extensao_sem_costura(s, bico, bico_esc, borda, ow=0.09, z_cap=1.78, z_cap_top=2.01)
    cume_bico = _chaikin([
        (-0.46, 1.54), (-0.30, 2.08), (0.0, 2.52), (0.30, 2.08), (0.46, 1.54), (0.0, 1.44)
    ], 2)
    s.flat(cume_bico, TOP + 0.018, 0.022, bico_cl, smooth=False)

    # Máscara facial branca em formato de coração/M ao redor dos olhos (#D4D4D4 / #F0F0F0 / #FCFCFC)
    # Cobre z = 2.010..2.016 (acima da base do bico 2.010, mas abaixo do topo das esferas dos olhos 2.07!)
    mascara_ext = _chaikin([
        (0.0, 0.18),
        (0.45, -0.22), (1.08, -0.25), (1.58, 0.15), (1.62, 0.92), (1.22, 1.48),
        (0.55, 1.58), (0.0, 1.52), (-0.55, 1.58),
        (-1.22, 1.48), (-1.62, 0.92), (-1.58, 0.15), (-1.08, -0.25), (-0.45, -0.22)
    ], 2)
    s.flat(mascara_ext, TOP + 0.010, 0.002, cinza_cl, smooth=False)

    mascara_med = _chaikin([
        (0.0, 0.26),
        (0.45, -0.12), (1.02, -0.15), (1.48, 0.20), (1.50, 0.88), (1.14, 1.40),
        (0.50, 1.50), (0.0, 1.44), (-0.50, 1.50),
        (-1.14, 1.40), (-1.50, 0.88), (-1.48, 0.20), (-1.02, -0.15), (-0.45, -0.12)
    ], 2)
    s.flat(mascara_med, TOP + 0.012, 0.002, branco_med, smooth=False)

    mascara_int = _chaikin([
        (0.0, 0.34),
        (0.44, -0.04), (0.96, -0.06), (1.38, 0.25), (1.40, 0.84), (1.06, 1.32),
        (0.46, 1.42), (0.0, 1.36), (-0.46, 1.42),
        (-1.06, 1.32), (-1.40, 0.84), (-1.38, 0.25), (-0.96, -0.06), (-0.44, -0.04)
    ], 2)
    s.flat(mascara_int, TOP + 0.014, 0.002, branco, smooth=False)

    # Anéis brancos ao redor dos olhos (r_in = 0.48 > raio do olho 0.475) para nunca tapar os olhos
    for k in (-1, 1):
        _anel_quads(s, k * EYE_X, EYE_Y, 0.48, 0.68, TOP + 0.014, 0.008, branco, n=18)

    # Mão: nadadeira preta com relevo #3C3C3C
    aba_mao = _chaikin([
        (-0.35, -0.25), (-0.42, 0.22), (0.0, 0.68), (0.42, 0.22), (0.35, -0.25)
    ], 2)
    s.hand_flat(aba_mao, 1.28, 0.42, corpo, outline=borda, ow=0.05, smooth=False)
    s.hand_flat(ellipse(0.0, 0.12, 0.22, 0.30, n=12), 1.82, 0.020, borda)


# ---------------------------------------------------------------- 3. Gato Lilás
def gato_lilas(s):
    # Gatinho místico lilás-pastel (#E8A0F8, contorno #B04CD4), orelhas felinas pontudas nos cantos
    # com interior rosa-claro (#F0C8FC / #E454C0), constelação de pintinhas brancas/claras (#FCFCFC e #F0C8FC)
    # em V na testa e nas laterais, e rabinho lilás atrás; mãos lilás com garras claras.
    corpo, borda, rosa_cl, magenta, branco = (
        "#E8A0F8", "#B04CD4", "#F0C8FC", "#E454C0", "#FCFCFC"
    )
    s.base()

    # Rabinho místico lilás curvado atrás com ponta clara e pintinhas brancas
    cauda_c = _curva([(0.0, -1.45), (0.18, -2.15), (0.68, -2.68), (0.35, -3.15)], per=6)
    pol_cauda = _tubo(cauda_c, lambda t: 0.38 - 0.10 * t, cap0=True, cap1=True, n=18)
    s.flat(pol_cauda, 0.84, 1.06, corpo, outline=borda, ow=0.09, smooth=False)
    pol_ponta = _tubo(cauda_c, lambda t: 0.22 * t, t0=0.55, t1=0.96, cap0=True, cap1=True, n=10)
    s.flat(pol_ponta, 1.91, 0.018, rosa_cl, smooth=False)
    s.flat(ellipse(0.45, -2.92, 0.09, 0.09, n=10), 1.93, 0.016, branco)

    # Orelhas felinas pontudas nos cantos traseiros com interior rosa-claro (#F0C8FC / #E454C0)
    orelha = _chaikin([
        (0.65, -0.78), (1.72, -0.54), (2.68, -1.22), (2.88, -2.48),
        (1.98, -2.52), (1.10, -1.85), (0.55, -1.36)
    ], 2)
    s.sym(orelha, 0.88, 1.04, corpo, outline=borda, ow=0.10, smooth=False)
    s.sym(_chaikin([(0.95, -0.92), (1.80, -0.72), (2.52, -1.32), (2.60, -2.22), (1.85, -2.18), (1.05, -1.55)], 1),
          1.93, 0.014, rosa_cl, smooth=False)
    miolo_or = _chaikin([
        (1.20, -1.10), (1.98, -1.08), (2.42, -1.98), (1.78, -1.95), (1.20, -1.48)
    ], 1)
    s.sym(miolo_or, 1.946, 0.016, magenta, smooth=False)

    # Tufos felinos laterais nas bochechas
    tufo_lat = _chaikin([
        (1.42, -0.35), (2.32, -0.02), (1.88, 0.35),
        (2.38, 0.82), (1.85, 1.22), (1.40, 1.42)
    ], 1)
    s.sym(tufo_lat, 0.86, 1.04, corpo, outline=borda, ow=0.09, smooth=False)
    s.sym(_chaikin([(1.70, -0.12), (2.18, 0.00), (1.80, 0.24)], 1), 1.91, 0.014, rosa_cl, smooth=False)
    s.sym(_chaikin([(1.72, 0.52), (2.22, 0.80), (1.80, 1.02)], 1), 1.91, 0.014, rosa_cl, smooth=False)

    # Narizinho felino delicado na borda frontal
    nar = _chaikin([(-0.22, 1.38), (0.22, 1.38), (0.24, 1.52), (0.0, 1.66), (-0.24, 1.52)], 2)
    s.flat(nar, TOP + 0.006, 0.016, magenta, smooth=False)

    # Constelação de pintinhas brancas (#FCFCFC) e rosa-claras (#F0C8FC) em V na testa e nas laterais:
    # O vértice do V fica na estrela entre os olhos (0.0, 0.88) e os dois braços sobem pelas sobrancelhas/têmporas
    # em direção às orelhas, deixando o centro atrás dos olhos (x ≈ 0, y < 0.45) 100% livre!
    s.flat([(0.0, 1.14), (0.22, 0.88), (0.0, 0.62), (-0.22, 0.88)], TOP + 0.006, 0.010, rosa_cl, smooth=False)
    s.flat([(0.0, 1.02), (0.12, 0.88), (0.0, 0.74), (-0.12, 0.88)], TOP + 0.016, 0.010, branco, smooth=False)

    pintas_v = [
        (0.28, 0.48, 0.09, rosa_cl), (-0.28, 0.48, 0.09, rosa_cl),
        (0.45, 0.16, 0.11, branco), (-0.45, 0.16, 0.11, branco),
        (0.72, -0.10, 0.10, rosa_cl), (-0.72, -0.10, 0.10, rosa_cl),
        (1.02, -0.36, 0.12, branco), (-1.02, -0.36, 0.12, branco),
        (1.30, -0.65, 0.10, rosa_cl), (-1.30, -0.65, 0.10, rosa_cl),
        (1.18, -1.05, 0.13, branco), (-1.18, -1.05, 0.13, branco),
        (0.85, -1.32, 0.10, rosa_cl), (-0.85, -1.32, 0.10, rosa_cl),
        (1.42, 0.58, 0.11, branco), (-1.42, 0.58, 0.11, branco),
        (1.52, 0.18, 0.09, rosa_cl), (-1.52, 0.18, 0.09, rosa_cl),
        (1.48, -0.25, 0.11, branco), (-1.48, -0.25, 0.11, branco),
    ]
    for px, py, pr, pcol in pintas_v:
        s.flat(ellipse(px, py, pr, pr, n=12), TOP + 0.008, 0.012, pcol)

    # Mão: patinha lilás com almofada #E454C0 e 3 garras claras #FCFCFC
    s.hand_flat(ellipse(0.0, -0.04, 0.26, 0.20, n=12), 1.82, 0.022, magenta)
    for kk in (-1, 0, 1):
        s.hand_flat(_espinho(kk * 0.22, 0.34, math.radians(90 - 18 * kk), 0.44, 0.10),
                    1.28, 0.38, branco, outline=borda, ow=0.04, smooth=False)


# ---------------------------------------------------------------- 4. Coco
def coco(s):
    # Coco tropical aberto/rachado de verdade:
    # Casca externa marrom-escura fibrosa (#684020, contorno #3E2210, fibras #885830 e #523016) arredondada,
    # metade traseira/topo aberta em zigue-zague mostrando a borda grossa e branquinha de polpa de coco
    # (#E4D0B8 / #F8F8F8) e água de coco azul-clara cristalina (#98DCE8 / #BCECF8 / #DCF8FC) lá dentro,
    # mais folha verde de coqueiro (#28A048 / #1C7030) e canudinho tropical saindo da abertura;
    # mãos de meia-casca de coco com polpa branca e água visíveis!
    corpo, borda, fibra_cl, fibra_esc, polpa_cr, polpa_br, agua_esc, agua_cl, folha_v, folha_esc = (
        "#684020", "#3E2210", "#885830", "#523016", "#E4D0B8", "#F8F8F8",
        "#88D0E4", "#BCECF8", "#28A048", "#1C7030"
    )
    s.base()

    # Silhueta arredondada de coco com tufos de fibra marrom espetados nas laterais e atrás
    casca_redonda_esq = _chaikin([
        (-1.48, 1.22), (-2.22, 0.82), (-2.02, 0.45), (-2.42, 0.05),
        (-2.35, -0.68), (-1.95, -0.95), (-2.28, -1.38), (-1.58, -1.82), (-1.35, -1.35)
    ], 1)
    _extensao_sem_costura(s, casca_redonda_esq, corpo, borda, ow=0.10, z_cap=1.78, z_cap_top=2.01)

    casca_redonda_dir = _chaikin([
        (1.48, 1.22), (2.22, 0.82), (2.02, 0.45), (2.42, 0.05),
        (2.35, -0.68), (1.95, -0.95), (2.28, -1.38), (1.58, -1.82), (1.35, -1.35)
    ], 1)
    _extensao_sem_costura(s, casca_redonda_dir, corpo, borda, ow=0.10, z_cap=1.78, z_cap_top=2.01)

    casca_redonda_tras = _chaikin([
        (-1.55, -1.35), (-1.28, -2.28), (-0.55, -2.55),
        (0.0, -2.62), (0.55, -2.55), (1.28, -2.28), (1.55, -1.35)
    ], 2)
    _extensao_sem_costura(s, casca_redonda_tras, corpo, borda, ow=0.10, z_cap=1.78, z_cap_top=2.01)

    # Folha tropical verde de coqueiro (#28A048 / #1C7030) saindo do canto traseiro direito (+X, -Y)
    folha_p1 = _chaikin([
        (1.05, -1.55), (2.15, -2.18), (3.12, -2.75), (2.55, -1.78),
        (2.98, -1.52), (2.18, -1.25), (1.35, -1.15)
    ], 1)
    s.flat(folha_p1, 0.88, 1.06, folha_v, outline=folha_esc, ow=0.08, smooth=False)
    s.flat(_chaikin([(1.32, -1.48), (2.25, -1.98), (2.88, -2.52), (2.05, -1.62)], 1),
           1.95, 0.018, "#58C864", smooth=False)

    # Grande abertura de COCO RACHADO/SERRADO na metade superior/traseira (y ∈ [-2.28, -0.18]):
    # 1) Borda escura da casca quebrada em zigue-zague (dentes de rachadura na frente, suave atrás)
    casca_aberta = [
        (-1.68, -0.45), (-1.28, -0.18), (-0.88, -0.48), (-0.42, -0.22),
        (0.0, -0.52), (0.42, -0.22), (0.88, -0.48), (1.28, -0.18), (1.68, -0.45),
        (1.92, -1.05), (1.72, -1.78), (1.08, -2.25), (0.0, -2.42),
        (-1.08, -2.25), (-1.72, -1.78), (-1.92, -1.05)
    ]
    s.flat(casca_aberta, TOP + 0.012, 0.014, fibra_esc, outline=borda, ow=0.05, smooth=False)

    # 2) Borda grossa de POLPA DE COCO creme (#E4D0B8) e branca viva (#F8F8F8) recortada em zigue-zague
    polpa_ext = [
        (-1.52, -0.52), (-1.18, -0.28), (-0.82, -0.56), (-0.38, -0.32),
        (0.0, -0.60), (0.38, -0.32), (0.82, -0.56), (1.18, -0.28), (1.52, -0.52),
        (1.75, -1.05), (1.55, -1.68), (0.98, -2.10), (0.0, -2.26),
        (-0.98, -2.10), (-1.55, -1.68), (-1.75, -1.05)
    ]
    s.flat(polpa_ext, TOP + 0.026, 0.018, polpa_cr, smooth=False)

    polpa_int = [
        (-1.40, -0.58), (-1.10, -0.36), (-0.76, -0.62), (-0.35, -0.40),
        (0.0, -0.66), (0.35, -0.40), (0.76, -0.62), (1.10, -0.36), (1.40, -0.58),
        (1.62, -1.06), (1.42, -1.60), (0.90, -1.98), (0.0, -2.14),
        (-0.90, -1.98), (-1.42, -1.60), (-1.62, -1.06)
    ]
    s.flat(polpa_int, TOP + 0.044, 0.022, polpa_br, smooth=False)

    # 3) ÁGUA DE COCO cristalina azul-clara (#88D0E4 / #BCECF8 / #DCF8FC) dentro da polpa branca!
    agua_fundo = _chaikin([
        (-1.12, -0.82), (-0.55, -0.78), (0.0, -0.88), (0.55, -0.78), (1.12, -0.82),
        (1.25, -1.22), (1.05, -1.62), (0.55, -1.82), (0.0, -1.88),
        (-0.55, -1.82), (-1.05, -1.62), (-1.25, -1.22)
    ], 2)
    s.flat(agua_fundo, TOP + 0.066, 0.010, agua_esc, smooth=False)

    agua_meio = _chaikin([
        (-0.95, -0.95), (-0.45, -0.92), (0.0, -0.98), (0.45, -0.92), (0.95, -0.95),
        (1.05, -1.25), (0.85, -1.55), (0.0, -1.72), (-0.85, -1.55), (-1.05, -1.25)
    ], 2)
    s.flat(agua_meio, TOP + 0.076, 0.008, agua_cl, smooth=False)

    # Ondinhas e brilhos brancos na água de coco
    s.flat(ellipse(-0.42, -1.28, 0.36, 0.16, n=14, rot=math.radians(15)), TOP + 0.084, 0.008, "#DCF8FC")
    s.flat(ellipse(0.45, -1.38, 0.24, 0.11, n=12, rot=math.radians(-18)), TOP + 0.086, 0.008, "#FFFFFF")
    s.flat(ellipse(-0.52, -1.22, 0.14, 0.07, n=10, rot=math.radians(15)), TOP + 0.092, 0.008, "#FFFFFF")

    # Canudinho listrado (#F8F8F8 com listras vermelhas #D84848) saindo de dentro da água de coco para fora (-X, -Y)!
    P_can = _local(-0.78, -1.42, math.radians(-132))
    pts_canudo = [P_can(0.0, -0.20), P_can(1.95, -0.22), P_can(1.95, 0.22), P_can(0.0, 0.20)]
    s.flat(pts_canudo, 0.95, 1.13, "#F8F8F8", outline=borda, ow=0.06, smooth=False)
    for d_c in (0.35, 0.85, 1.35):
        faixa_c = [P_can(d_c, -0.21), P_can(d_c + 0.24, -0.21), P_can(d_c + 0.24, 0.21), P_can(d_c, 0.21)]
        s.flat(faixa_c, TOP + 0.086, 0.016, "#D84848", smooth=False)
    s.flat(ellipse(*P_can(1.90, 0.0), 0.10, 0.20, n=12, rot=math.radians(-132)), TOP + 0.086, 0.018, borda)

    # Texturas de fibras da casca marrom nas laterais e os 3 "furinhos" clássicos do coco na lateral esquerda
    for fx, fy, fw, fh, fang, fcol in [
        (-1.68, 0.45, 0.72, 0.16, 78, fibra_cl),
        (-1.85, -0.15, 0.68, 0.15, 85, fibra_esc),
        (1.68, 0.45, 0.72, 0.16, -78, fibra_cl),
        (1.85, -0.15, 0.68, 0.15, -85, fibra_esc),
        (-0.85, 1.42, 0.58, 0.14, -22, fibra_cl),
        (0.85, 1.42, 0.58, 0.14, 22, fibra_cl),
    ]:
        P_f = _local(fx, fy, math.radians(fang))
        veio = _chaikin([P_f(-fw * 0.5, 0.0), P_f(0.0, -fh * 0.5), P_f(fw * 0.5, 0.0), P_f(0.0, fh * 0.5)], 1)
        s.flat(veio, TOP + 0.012, 0.008, fcol, smooth=False)

    # Os 3 furinhos clássicos da casca do coco na bochecha direita (+X)
    for hx_c, hy_c in [(1.42, 0.92), (1.62, 0.72), (1.38, 0.62)]:
        s.flat(ellipse(hx_c, hy_c, 0.11, 0.09, n=10, rot=-0.3), TOP + 0.014, 0.010, borda)

    # Mão: meia-casca de coco aberta mostrando o aro de polpa branca (#F8F8F8) e água de coco (#BCECF8)!
    s.hand_flat(ellipse(0.0, 0.06, 0.42, 0.34, n=16), 1.78, 0.030, polpa_cr, outline=borda, ow=0.04)
    s.hand_flat(ellipse(0.0, 0.06, 0.35, 0.28, n=16), 1.815, 0.020, polpa_br)
    s.hand_flat(ellipse(0.0, 0.06, 0.22, 0.16, n=14), 1.836, 0.015, agua_cl)
    s.hand_flat(ellipse(-0.06, 0.10, 0.08, 0.05, n=8), 1.852, 0.012, "#FFFFFF")


# ---------------------------------------------------------------- 5. Lama
def lama(s):
    # Monstro de Lama / Lodo do Pântano (SEM espiral fino de madeira!):
    # 3 grandes dobras/rolos horizontais volumosos empilhados com sulcos escuros (#402008),
    # camadas de lodo (#5C3814 e #886034), grande pico curvo retorcido no topo traseiro com reflexo
    # largo (#C49C68), poças e bolhas de lama estourando nas laterais e sobrancelhas grossas franzidas
    # de monstro de lama rabugento/malvado (#402008, separadas no centro!).
    corpo, borda, lama_esc, lama_prof, lama_cl, brilho = (
        "#886034", "#402008", "#5C3814", "#48280C", "#C49C68", "#FCFCFC"
    )
    s.base()

    # Grande poça disforme de lama derretendo nas laterais e atrás com lóbulos espessos
    poca_esq = _chaikin([
        (-1.42, 1.25), (-2.48, 0.88), (-2.68, 0.08), (-2.18, -0.48),
        (-2.62, -1.22), (-1.92, -1.98), (-1.25, -1.48)
    ], 2)
    _extensao_sem_costura(s, poca_esq, corpo, borda, ow=0.10, z_cap=1.78, z_cap_top=2.01)

    poca_dir = _chaikin([
        (1.42, 1.18), (2.42, 0.78), (2.62, -0.05), (2.15, -0.58),
        (2.58, -1.32), (1.88, -2.02), (1.25, -1.48)
    ], 2)
    _extensao_sem_costura(s, poca_dir, corpo, borda, ow=0.10, z_cap=1.78, z_cap_top=2.01)

    poca_tras = _chaikin([
        (-1.55, -1.32), (-1.48, -2.42), (-0.65, -2.75),
        (0.15, -2.95), (0.85, -2.68), (1.52, -2.35), (1.55, -1.32)
    ], 2)
    _extensao_sem_costura(s, poca_tras, corpo, borda, ow=0.10, z_cap=1.78, z_cap_top=2.01)

    # Grande crista/pico curvo retorcido de monstro de lama saindo no topo traseiro (inclinado para a direita!)
    pico_lama_sil = _chaikin([
        (-0.88, -1.55), (-0.95, -2.48), (-0.28, -3.22),
        (0.75, -3.38), (1.12, -2.78), (0.72, -2.25), (0.85, -1.55)
    ], 2)
    _extensao_sem_costura(s, pico_lama_sil, corpo, borda, ow=0.10, z_cap=1.78, z_cap_top=2.01)

    # 3 GRANDES DOBRAS / ROLOS HORIZONTAIS VOLUMOSOS DE LODO (como na ref 105, sem espiral de madeira!):
    # Rolo 1 (base traseira/lateral larga em #5C3814 com sulco profundo #402008)
    rolo_1 = _chaikin([
        (-1.75, 0.55), (-2.38, 0.15), (-2.05, -0.55), (-2.32, -1.22),
        (-1.42, -2.22), (0.0, -2.62), (1.42, -2.22),
        (2.32, -1.22), (2.05, -0.55), (2.38, 0.15), (1.75, 0.55),
        (1.38, -0.05), (1.28, -0.72), (0.65, -0.88), (-0.65, -0.88), (-1.28, -0.72), (-1.38, -0.05)
    ], 2)
    s.flat(rolo_1, TOP + 0.012, 0.018, lama_esc, outline=borda, ow=0.05, smooth=False)

    # Rolo 2 (dobra intermediária gorda de lama #886034 com sulco #402008)
    rolo_2 = _chaikin([
        (-1.58, -0.68), (-1.82, -1.35), (-1.18, -2.08), (0.08, -2.45),
        (1.22, -2.05), (1.78, -1.32), (1.55, -0.68),
        (0.82, -0.85), (0.0, -0.76), (-0.82, -0.85)
    ], 2)
    s.flat(rolo_2, TOP + 0.032, 0.022, corpo, outline=borda, ow=0.05, smooth=False)
    # Reflexo largo de lama clara (#C49C68) ao longo da crista do Rolo 2
    reflexo_rolo2 = _chaikin([
        (-1.28, -0.92), (-1.38, -1.32), (-0.75, -1.72), (0.75, -1.72),
        (1.38, -1.32), (1.28, -0.92), (0.0, -1.02)
    ], 2)
    s.flat(reflexo_rolo2, TOP + 0.055, 0.010, lama_cl, smooth=False)

    # Rolo 3 (grande crista horizontal ondulada de lama no topo traseiro, #5C3814 + cobertura brilhante #C49C68)
    rolo_3 = _chaikin([
        (-1.18, -1.48), (-1.25, -2.18), (-0.42, -2.98),
        (0.68, -3.12), (1.15, -2.48), (1.05, -1.48), (0.0, -1.62)
    ], 2)
    s.flat(rolo_3, TOP + 0.058, 0.026, lama_esc, outline=borda, ow=0.05, smooth=False)

    topo_rolo_3 = _chaikin([
        (-0.92, -1.72), (-0.95, -2.18), (-0.28, -2.78),
        (0.58, -2.88), (0.88, -2.35), (0.78, -1.72), (0.0, -1.85)
    ], 2)
    s.flat(topo_rolo_3, TOP + 0.085, 0.018, lama_cl, smooth=False)
    s.flat(ellipse(0.12, -2.38, 0.42, 0.16, n=14, rot=math.radians(-12)), TOP + 0.104, 0.012, brilho)

    # Bolhas de lama estourando / crateras viscosas nas laterais e atrás (esferas 3D + anéis de lama!)
    bolhas_lama_borda = [
        (-2.45, -0.35, 0.38),
        (2.42, -0.45, 0.40),
        (-1.82, -1.68, 0.34),
        (1.78, -1.72, 0.36),
    ]
    for bx, by, br in bolhas_lama_borda:
        s.flat(ellipse(bx, by, br, br, n=16), 0.86, 1.06, lama_esc, outline=borda, ow=0.08)
        s.sphere((bx, by, 1.92), (br * 0.72, br * 0.72, 0.24), corpo)
        s.sphere((bx - br * 0.22, by + br * 0.22, 2.12), (br * 0.22, br * 0.22, 0.06), lama_cl)

    # Crateras/bolhas de pântano abertas nas bochechas/laterais do topo
    for cx_b, cy_b, r_b in [(-1.62, 0.28, 0.30), (1.62, 0.22, 0.32), (-1.42, -1.15, 0.26), (1.42, -1.18, 0.26)]:
        s.flat(ellipse(cx_b, cy_b, r_b, r_b * 0.82, n=14), TOP + 0.032, 0.016, borda)
        s.flat(ellipse(cx_b, cy_b, r_b * 0.65, r_b * 0.52, n=12), TOP + 0.048, 0.012, lama_cl)

    # SOBRANCELHAS GROSSAS FRANZIDAS DE MONSTRO DE LAMA (#402008 / #5C3814, separadas no centro!)
    sobr_lama = _chaikin([
        (0.32, 0.40), (0.62, 0.10), (1.15, -0.10), (1.58, -0.18),
        (1.62, 0.12), (1.15, 0.22), (0.68, 0.36), (0.34, 0.58)
    ], 1)
    s.sym(sobr_lama, TOP + 0.016, 0.026, borda, smooth=False)
    s.sym(_chaikin([
        (0.38, 0.42), (0.65, 0.16), (1.48, -0.08), (1.50, 0.06), (0.68, 0.30)
    ], 1), TOP + 0.042, 0.014, lama_esc, smooth=False)

    # Mão: garra disforme de monstro de lama com 3 dedos viscosos e bolha de lama
    for kk in (-1, 0, 1):
        s.hand_flat(_espinho(kk * 0.22, 0.28, math.radians(90 - 18 * kk), 0.48, 0.14),
                    1.28, 0.42, lama_esc, outline=borda, ow=0.04, smooth=False)
    s.hand_flat(ellipse(-0.34, -0.10, 0.24, 0.20, n=12), 1.30, 0.42, lama_esc, outline=borda, ow=0.04)
    s.hand_flat(ellipse(0.04, -0.02, 0.28, 0.22, n=12), 1.82, 0.020, lama_cl)
    s.hand_flat(ellipse(-0.06, 0.06, 0.10, 0.07, n=10), 1.85, 0.016, brilho)


# ---------------------------------------------------------------- 6. Jarra de Vidro
def jarra_vidro(s):
    # Pote/frasco de vidro azul-gelo (#BCDCEC, contorno #708494), gargalo e rolha de cortiça (#B06818
    # com aro de vidro #A4B4BC) salientes na silhueta traseira, nível de água/líquido interno (#68A8BC / #84B8CC)
    # e reflexos brancos de vidro nas laterais; mãos de vidro azul-claro.
    corpo, borda, liq_esc, liq_cl, vidro_cl, vidro_aro, rolha = (
        "#BCDCEC", "#708494", "#68A8BC", "#84B8CC", "#C8E0EC", "#A4B4BC", "#B06818"
    )
    s.base()

    # Rolha de cortiça (#B06818) saliente bem no fundo da silhueta traseira
    pts_rolha = _chaikin([
        (-0.68, -1.85), (-0.84, -2.82), (0.84, -2.82), (0.68, -1.85)
    ], 2)
    s.flat(pts_rolha, 0.82, 1.10, rolha, outline=borda, ow=0.09, smooth=False)
    s.flat(_chaikin([(-0.52, -2.05), (-0.60, -2.62), (0.60, -2.62), (0.52, -2.05)], 1),
           1.93, 0.018, borda, smooth=False)
    s.flat(_chaikin([(-0.44, -2.10), (-0.50, -2.55), (0.50, -2.55), (0.44, -2.10)], 1),
           1.95, 0.018, rolha, smooth=False)

    # Gargalo e aro de vidro (#A4B4BC / #C8E0EC) abraçando a rolha na silhueta traseira
    aro_gargalo = _chaikin([
        (-1.24, -1.45), (-1.34, -2.15), (1.34, -2.15), (1.24, -1.45)
    ], 2)
    s.flat(aro_gargalo, 0.86, 1.06, vidro_aro, outline=borda, ow=0.10, smooth=False)
    s.flat(_chaikin([(-1.05, -1.62), (-1.12, -2.02), (1.12, -2.02), (1.05, -1.62)], 1),
           1.93, 0.018, vidro_cl, smooth=False)

    # Alças/bordas bojudas de vidro nas laterais da jarra
    bojo_lat = _chaikin([
        (1.45, 0.95), (2.08, 0.68), (2.15, -0.68), (1.45, -0.98)
    ], 2)
    s.sym(bojo_lat, 0.86, 1.06, vidro_cl, outline=borda, ow=0.09, smooth=False)

    # Nível de água/líquido interno (#68A8BC base + onda #84B8CC) na metade frontal e central
    liquido_base = _chaikin([
        (-1.58, -0.18), (-1.05, -0.32), (0.0, -0.15), (1.05, -0.32), (1.58, -0.18),
        (1.62, 1.15), (1.22, 1.58), (0.0, 1.64), (-1.22, 1.58), (-1.62, 1.15)
    ], 2)
    s.flat(liquido_base, TOP, 0.004, liq_esc, smooth=False)

    onda_superficie = _chaikin([
        (-1.58, -0.45), (-0.95, -0.62), (0.0, -0.42), (0.95, -0.62), (1.58, -0.45),
        (1.58, 0.05), (0.95, -0.12), (0.0, 0.05), (-0.95, -0.12), (-1.58, 0.05)
    ], 2)
    s.flat(onda_superficie, TOP + 0.004, 0.004, liq_cl, smooth=False)

    # Bolhinhas claras de água somente nas laterais
    for bx, by, br in [
        (-1.28, 0.95, 0.14), (-1.42, 0.45, 0.10),
        (1.28, 0.92, 0.15), (1.40, 0.38, 0.11),
    ]:
        s.flat(ellipse(bx, by, br, br, n=12), TOP + 0.008, 0.010, vidro_cl)

    # Reflexos de vidro verticais/curvos (#C8E0EC) nas duas laterais e nos ombros traseiros
    reflexo_lat = _chaikin([
        (1.38, 1.18), (1.68, 0.92), (1.72, -0.88), (1.38, -1.18), (1.48, 0.0)
    ], 2)
    s.sym(reflexo_lat, TOP + 0.010, 0.014, vidro_cl, smooth=False)
    s.sym(ellipse(0.85, -1.18, 0.38, 0.15, n=14, rot=math.radians(-20)), TOP + 0.010, 0.012, vidro_cl)

    # Mão: esfera de vidro azul-claro com líquido #68A8BC e brilho #C8E0EC
    s.hand_flat(ellipse(0.0, -0.02, 0.32, 0.26, n=14), 1.81, 0.020, liq_esc)
    s.hand_flat(ellipse(-0.10, 0.12, 0.14, 0.10, n=10, rot=0.3), 1.84, 0.020, vidro_cl)


# ---------------------------------------------------------------- 7. Geleia de Rubi
def geleia_rubi(s):
    # Monstro de Slime/Geleia de Rubi Carmesim (#C42C3C, contorno #701428) com cara de mal:
    # Sobrancelhas furiosas inclinadas (#480C20 / #701428), presas/espinhos cristalinos de rubi na frente,
    # tentáculos e bolhas gelatinosas ácidas nas bordas (#941C38 e #FC5858), núcleo translúcido brilhante
    # e mãos gelatinosas com garras de rubi!
    corpo, borda, rubi_prof, rubi_esc, rubi_vivo, espec_1, espec_2, branco = (
        "#C42C3C", "#701428", "#480C20", "#941C38", "#FC5858", "#D86058", "#E48078", "#FCFCFC"
    )
    s.base()

    # Lóbulos e tentáculos gelatinosos agressivos fundidos ao corpo nas laterais e atrás
    lobo_esq = _chaikin([
        (-1.55, 1.18), (-2.48, 0.85), (-2.68, 0.05), (-2.08, -0.45),
        (-2.62, -1.25), (-1.85, -1.88), (-1.45, -1.25)
    ], 2)
    _extensao_sem_costura(s, lobo_esq, corpo, borda, ow=0.10, z_cap=1.78, z_cap_top=2.01)

    lobo_dir = _chaikin([
        (1.55, 0.98), (2.45, 0.58), (2.12, -0.15),
        (2.72, -0.88), (2.35, -1.68), (1.55, -1.42)
    ], 2)
    _extensao_sem_costura(s, lobo_dir, corpo, borda, ow=0.10, z_cap=1.78, z_cap_top=2.01)

    lobo_tras = _chaikin([
        (-1.35, -1.50), (-1.22, -2.48), (-0.42, -2.18),
        (0.32, -2.85), (1.22, -2.42), (1.28, -1.50)
    ], 2)
    _extensao_sem_costura(s, lobo_tras, corpo, borda, ow=0.10, z_cap=1.78, z_cap_top=2.01)

    # Presas/espinhos cristalinos de rubi (#FC5858 / #E48078) saindo na borda frontal (100% à frente dos olhos!)
    for k in (-1, 1):
        X = lambda P: [(k * x, y) for x, y in P]
        presa_r = _chaikin([(0.48, 1.55), (0.65, 2.32), (0.98, 2.05), (1.02, 1.55)], 1)
        s.flat(X(presa_r), 0.88, 1.06, rubi_vivo, outline=borda, ow=0.08, smooth=False)
        s.flat(X([(0.58, 1.65), (0.68, 2.15), (0.86, 1.95)]), 1.95, 0.02, espec_2, smooth=False)

    # Gotas e bolhas ácidas de geleia de rubi saltando na silhueta (#941C38 e #FC5858)
    bolhas_borda = [
        (-2.45, 0.45, 0.56, 0.52, rubi_esc, rubi_vivo),
        (-2.28, -1.15, 0.50, 0.46, rubi_vivo, espec_2),
        (-0.92, -2.28, 0.54, 0.50, rubi_esc, rubi_vivo),
        (0.32, -2.62, 0.65, 0.58, rubi_vivo, espec_2),
        (1.42, -2.15, 0.48, 0.44, rubi_esc, espec_1),
        (2.48, -0.92, 0.58, 0.54, rubi_vivo, espec_2),
        (2.22, 0.62, 0.48, 0.45, rubi_esc, rubi_vivo),
    ]
    for bx, by, rx, ry, c_ext, c_int in bolhas_borda:
        s.flat(ellipse(bx, by, rx, ry, n=18), 0.84, 1.06, c_ext, outline=borda, ow=0.09)
        s.flat(ellipse(bx, by, rx * 0.66, ry * 0.66, n=14), 1.91, 0.016, c_int)
        s.flat(ellipse(bx - rx * 0.25, by + ry * 0.25, rx * 0.22, ry * 0.22, n=10), 1.928, 0.016, branco)

    # SOBRANCELHAS FURIOSAS INCLINADAS DE RUBI ESCURO (#480C20 / #701428, separadas no centro!)
    sobr_rubi = _chaikin([
        (0.32, 0.42), (0.62, 0.12), (1.15, -0.08), (1.58, -0.22),
        (1.62, 0.06), (1.12, 0.20), (0.66, 0.36), (0.34, 0.58)
    ], 1)
    s.sym(sobr_rubi, TOP + 0.018, 0.028, rubi_prof, smooth=False)
    s.sym(_chaikin([
        (0.38, 0.44), (0.66, 0.18), (1.48, -0.10), (1.50, 0.02), (0.68, 0.30)
    ], 1), TOP + 0.046, 0.014, rubi_esc, smooth=False)

    # Manchas/núcleos translúcidos assimétricos no topo
    mancha_dir_tras = _chaikin([
        (0.25, -0.92), (0.45, -1.65), (1.28, -1.68), (1.58, -1.08),
        (1.48, -0.35), (0.88, -0.45)
    ], 2)
    s.flat(mancha_dir_tras, TOP + 0.012, 0.008, rubi_esc, smooth=False)
    s.flat(_chaikin([
        (0.45, -1.02), (0.62, -1.52), (1.18, -1.52), (1.42, -1.02), (1.32, -0.52), (0.88, -0.60)
    ], 2), TOP + 0.020, 0.008, rubi_vivo, smooth=False)

    mancha_esq_lat = _chaikin([
        (-1.62, 0.55), (-1.68, -0.55), (-1.18, -1.25), (-0.68, -1.05),
        (-1.02, -0.25), (-1.28, 0.48)
    ], 2)
    s.flat(mancha_esq_lat, TOP + 0.012, 0.008, rubi_esc, smooth=False)

    # Bolhas translúcidas e reflexos especulares claros (#D86058, #E48078, #FCFCFC) assimétricos no topo
    bolhas_topo = [
        (-1.38, -0.45, 0.42, 0.34, espec_1, espec_2, True),
        (1.02, -1.08, 0.45, 0.36, espec_1, espec_2, True),
        (-0.88, -1.42, 0.34, 0.28, rubi_vivo, espec_1, False),
        (1.42, 0.35, 0.34, 0.28, rubi_vivo, espec_2, True),
        (-1.35, 1.12, 0.28, 0.22, espec_1, branco, False),
        (1.32, 1.15, 0.26, 0.20, espec_2, branco, False),
    ]
    for bx, by, rx, ry, c1, c2, tem_br in bolhas_topo:
        s.flat(ellipse(bx, by, rx, ry, n=16), TOP + 0.028, 0.010, c1)
        s.flat(ellipse(bx + 0.03, by - 0.02, rx * 0.62, ry * 0.62, n=14), TOP + 0.038, 0.010, c2)
        if tem_br:
            s.flat(ellipse(bx - rx * 0.26, by + ry * 0.26, rx * 0.24, ry * 0.20, n=10), TOP + 0.048, 0.012, branco)

    # Mão: mão gelatinosa vermelha com 3 garras cristalinas de rubi (#FC5858) e bolhas ácidas
    for kk in (-1, 0, 1):
        s.hand_flat(_espinho(kk * 0.22, 0.32, math.radians(90 - 18 * kk), 0.46, 0.11),
                    1.28, 0.40, rubi_vivo, outline=borda, ow=0.04, smooth=False)
    s.hand_flat(ellipse(-0.34, -0.05, 0.22, 0.20, n=12), 1.32, 0.42, rubi_esc, outline=borda, ow=0.04)
    s.hand_flat(ellipse(0.04, 0.02, 0.26, 0.22, n=12), 1.83, 0.020, espec_2)
    s.hand_flat(ellipse(-0.05, 0.10, 0.10, 0.09, n=8), 1.86, 0.018, branco)


# ---------------------------------------------------------------- 8. Fantasminha (Assombração Glacial)
def fantasminha(s):
    # Fantasma / Assombração Glacial (#DCF4FC, contorno #B0D0F0) com cara de mal (NADA de 3 pontas de coroa!):
    # Cauda/manto ectoplásmico longo, rasgado e ASSIMÉTRICO varrendo de forma sinuosa para trás e para os lados,
    # fogos-fátuos (wisps) flutuando soltos ao redor, cavidades oculares escuras assombradas (#1C2438)
    # e sobrancelhas fantasmagóricas furiosas inclinadas (#1C2438 / #7890C8); mãos com garras ectoplásmicas!
    corpo, borda, gelo_cl, gelo_med, lavanda, sombra_olho, sobr_az, branco = (
        "#DCF4FC", "#B0D0F0", "#ECF8FC", "#D0E8FC", "#A0ACFC", "#1C2438", "#7890C8", "#FCFCFC"
    )
    s.base()

    # Grande cauda ectoplásmica principal LONGA E ASSIMÉTRICA varrendo em curva S para trás/direita!
    cauda_principal = _chaikin([
        (-1.48, -1.25), (-1.35, -2.18), (-0.65, -2.85),
        (0.48, -3.48), (1.35, -3.55), (1.12, -2.82),
        (1.42, -2.15), (1.52, -1.25), (0.0, -1.18)
    ], 2)
    _extensao_sem_costura(s, cauda_principal, corpo, borda, ow=0.10, z_cap=1.78, z_cap_top=2.01)

    # Tiras rasgadas assimétricas de mortalha/ectoplasma varrendo nas laterais (como um lençol rasgado ao vento!)
    mortalha_esq = _chaikin([
        (-1.45, 0.95), (-2.38, 0.45), (-2.85, -0.35), (-2.15, -0.58),
        (-2.78, -1.35), (-2.95, -2.12), (-1.98, -1.85), (-1.45, -1.15)
    ], 1)
    _extensao_sem_costura(s, mortalha_esq, corpo, borda, ow=0.10, z_cap=1.78, z_cap_top=2.01)

    mortalha_dir = _chaikin([
        (1.45, 0.85), (2.42, 0.28), (2.75, -0.52), (2.05, -0.75),
        (2.65, -1.58), (1.88, -1.72), (1.45, -1.05)
    ], 1)
    _extensao_sem_costura(s, mortalha_dir, corpo, borda, ow=0.10, z_cap=1.78, z_cap_top=2.01)

    # Manto superior contínuo cobrindo o topo do corpo até z=2.01 para zero costura!
    manto_topo = _chaikin([
        (-1.62, 1.48), (0.0, 1.62), (1.62, 1.48),
        (1.75, 0.20), (1.62, -1.55), (0.0, -1.65), (-1.62, -1.55), (-1.75, 0.20)
    ], 2)
    s.flat(manto_topo, TOP, 0.010, corpo, smooth=False)

    # Dobras sombreadas longas e sinuosas de ectoplasma (#D0E8FC e #A0ACFC) acompanhando a cauda em S e as laterais
    dobra_s1 = _curva([(-0.95, -1.35), (-0.75, -2.18), (0.15, -2.85), (1.08, -3.28)], per=6)
    s.flat(_tubo(dobra_s1, lambda t: 0.28 * (1.0 - 0.55 * t), cap0=True, cap1=True, n=18),
           2.011, 0.006, gelo_med, smooth=False)
    s.flat(_tubo(dobra_s1, lambda t: 0.14 * (1.0 - 0.55 * t), cap0=True, cap1=True, n=18),
           2.017, 0.006, lavanda, smooth=False)

    dobra_s2 = _curva([(0.65, -1.25), (0.82, -1.95), (1.15, -2.55)], per=5)
    s.flat(_tubo(dobra_s2, lambda t: 0.20 * (1.0 - 0.5 * t), cap0=True, cap1=True, n=14),
           2.011, 0.006, gelo_med, smooth=False)

    dobra_lat_e = _curva([(-1.55, 0.25), (-2.15, -0.45), (-2.62, -1.68)], per=5)
    s.flat(_tubo(dobra_lat_e, lambda t: 0.22 * (1.0 - 0.5 * t), cap0=True, cap1=True, n=14),
           2.011, 0.006, gelo_med, smooth=False)
    s.flat(_tubo(dobra_lat_e, lambda t: 0.10 * (1.0 - 0.5 * t), cap0=True, cap1=True, n=14),
           2.017, 0.006, lavanda, smooth=False)

    dobra_lat_d = _curva([(1.55, 0.15), (2.15, -0.42), (2.42, -1.35)], per=5)
    s.flat(_tubo(dobra_lat_d, lambda t: 0.20 * (1.0 - 0.5 * t), cap0=True, cap1=True, n=14),
           2.011, 0.006, gelo_med, smooth=False)

    # Fogos-fátuos (wisps de ectoplasma) flutuando soltos ao redor do fantasma!
    for wx, wy, wang, wr in [
        (-2.05, -2.65, -125, 0.26),
        (2.15, -2.42, -65, 0.24),
        (-2.85, 0.35, 165, 0.22),
    ]:
        wisp = _espinho(wx, wy, math.radians(wang), wr * 2.8, wr)
        s.flat(wisp, 0.90, 1.04, lavanda, outline=borda, ow=0.06, smooth=False, emit=0.4)
        s.flat(ellipse(wx, wy, wr * 0.58, wr * 0.58, n=12), 1.95, 0.022, branco, emit=0.9)

    # OLHOS ASSOMBRADOS E SOBRANCELHAS FURIOSAS DE FANTASMA:
    # Cavidades oculares escuras (#1C2438) ao redor dos olhos + sobrancelhas furiosas inclinadas (#1C2438 / #7890C8)
    for k in (-1, 1):
        _anel_quads(s, k * EYE_X, EYE_Y, 0.47, 0.66, 2.012, 0.014, sombra_olho, n=18)

    sobr_fantasma = _chaikin([
        (0.30, 0.44), (0.60, 0.12), (1.15, -0.10), (1.62, -0.26),
        (1.68, 0.04), (1.14, 0.20), (0.66, 0.38), (0.32, 0.60)
    ], 1)
    s.sym(sobr_fantasma, 2.016, 0.026, sombra_olho, smooth=False)
    s.sym(_chaikin([
        (0.36, 0.46), (0.64, 0.18), (1.52, -0.14), (1.54, -0.02), (0.68, 0.30)
    ], 1), 2.042, 0.012, sobr_az, smooth=False)

    # Mão: mão fantasmagórica com 3 garras ectoplásmicas na frente e véu rasgado atrás
    cauda_mao = _chaikin([
        (-0.36, -0.12), (-0.42, -0.72), (-0.08, -0.55), (0.18, -0.92), (0.38, -0.12)
    ], 1)
    s.hand_flat(cauda_mao, 1.28, 0.42, corpo, outline=borda, ow=0.04, smooth=False)
    for kk in (-1, 0, 1):
        s.hand_flat(_espinho(kk * 0.22, 0.32, math.radians(90 - 18 * kk), 0.46, 0.10),
                    1.28, 0.38, branco, outline=borda, ow=0.04, smooth=False)
    s.hand_flat(ellipse(0.0, 0.04, 0.24, 0.20, n=12), 1.82, 0.018, lavanda)


# ---------------------------------------------------------------- 9. Ancião
def anciao(s):
    # Ancião venerável/severo de verdade (fiel à essência da ref 174):
    # Topo da cabeça calvo rosado (#D08484) com 2 rugas longas de expressão na testa (#985C68),
    # cabelo comprido grisalho/branco (#E8ECF0 / #C8D0D8, contorno #78808C) caindo nas laterais e atrás,
    # orelhas humanas discretas, sobrancelhas brancas bem grossas e franzidas (#F0F4F8, contorno #78808C),
    # nariz largo rosado (#C07878) e grande bigode + barba longa branca/grisalha em pontas na frente!
    corpo, borda, pele_med, ruga_esc, ruga_suave, cabelo_br, cabelo_gr, borda_cab = (
        "#D08484", "#985C68", "#C07878", "#A86870", "#B06C74", "#F0F4F8", "#C8D0D8", "#78808C"
    )
    s.base()

    # Cabelo comprido grisalho/branco (#F0F4F8 / #C8D0D8, contorno #78808C) nas laterais e atrás da cabeça
    # (Deixando o topo central/testa calvo em #D08484!)
    cabelo_tras = _chaikin([
        (-1.58, -1.25), (-1.92, -2.18), (-1.18, -2.02),
        (-0.78, -2.62), (0.0, -2.75), (0.78, -2.62),
        (1.18, -2.02), (1.92, -2.18), (1.58, -1.25),
        (0.95, -1.48), (0.0, -1.55), (-0.95, -1.48)
    ], 2)
    s.flat(cabelo_tras, 0.86, 1.16, cabelo_gr, outline=borda_cab, ow=0.09, smooth=False)
    s.flat(_chaikin([
        (-1.38, -1.42), (-1.65, -2.02), (-0.68, -2.42), (0.0, -2.55),
        (0.68, -2.42), (1.65, -2.02), (1.38, -1.42), (0.0, -1.62)
    ], 2), 2.026, 0.018, cabelo_br, smooth=False)

    # Mechas laterais de cabelo branco/grisalho nas têmporas/costeletas
    cabelo_lat = _chaikin([
        (1.38, 0.25), (2.15, 0.05), (2.42, -0.68), (2.25, -1.48),
        (1.55, -1.68), (1.32, -1.05), (1.42, -0.35)
    ], 2)
    s.sym(cabelo_lat, 0.88, 1.15, cabelo_br, outline=borda_cab, ow=0.09, smooth=False)
    s.sym(_chaikin([(1.52, -0.05), (2.15, -0.58), (2.02, -1.32), (1.48, -1.15)], 2),
          2.036, 0.016, cabelo_gr, smooth=False)

    # Orelhas humanas discretas saindo na frente do cabelo lateral (y ≈ 0.45)
    s.sym(ellipse(1.88, 0.48, 0.34, 0.44, n=16), 0.84, 1.06, corpo, outline=borda, ow=0.08)
    s.sym(ellipse(1.86, 0.48, 0.18, 0.26, n=12), 1.91, 0.015, ruga_suave)

    # GRANDE BARBA LONGA BRANCA/GRISALHA EM PONTAS E BIGODE FARTO NA FRENTE (+Y):
    barba_longa = _chaikin([
        (-1.42, 1.18), (-1.68, 1.88), (-1.15, 2.52), (-0.75, 2.28),
        (-0.48, 2.95), (0.0, 3.18), (0.48, 2.95),
        (0.75, 2.28), (1.15, 2.52), (1.68, 1.88), (1.42, 1.18), (0.0, 1.12)
    ], 1)
    s.flat(barba_longa, 0.78, 1.24, cabelo_gr, outline=borda_cab, ow=0.10, smooth=False)

    barba_camada_cl = _chaikin([
        (-1.18, 1.32), (-1.38, 1.85), (-0.98, 2.32), (-0.65, 2.12),
        (-0.38, 2.72), (0.0, 2.95), (0.38, 2.72),
        (0.65, 2.12), (0.98, 2.32), (1.38, 1.85), (1.18, 1.32), (0.0, 1.25)
    ], 1)
    s.flat(barba_camada_cl, 2.026, 0.020, cabelo_br, smooth=False)

    # Bigode farto arqueado de ancião (#F0F4F8 com contorno #78808C) abrindo para os dois lados abaixo do nariz
    for k in (-1, 1):
        X = lambda P: [(k * x, y) for x, y in P]
        bigode_asa = _chaikin([
            (0.0, 1.35), (0.55, 1.28), (1.28, 1.48), (1.62, 1.92),
            (1.12, 2.05), (0.52, 1.78), (0.0, 1.72)
        ], 2)
        s.flat(X(bigode_asa), 2.046, 0.026, cabelo_br, outline=borda_cab, ow=0.05, smooth=False)

    # Nariz largo de ancião (#C07878 / #D08484) pousado acima do bigode (y = 0.85..1.62)
    nariz_anc = _chaikin([
        (-0.32, 0.88), (-0.52, 1.28), (-0.42, 1.58), (0.0, 1.66),
        (0.42, 1.58), (0.52, 1.28), (0.32, 0.88)
    ], 2)
    s.flat(nariz_anc, 2.075, 0.028, pele_med, outline=borda, ow=0.04, smooth=False)
    s.flat(ellipse(0.0, 1.38, 0.30, 0.18, n=12), 2.104, 0.012, corpo)

    # SOBRANCELHAS BRANCAS/GRISALHAS BEM GROSSAS E FRANZIDAS (#F0F4F8, contorno #78808C)
    # Inclinadas com expressão severa de ancião sábio/rabugento, separadas no centro!
    sobr_branca = _chaikin([
        (0.30, 0.42), (0.62, 0.08), (1.18, -0.12), (1.65, -0.22),
        (1.72, 0.12), (1.18, 0.25), (0.68, 0.40), (0.32, 0.60)
    ], 1)
    s.sym(sobr_branca, TOP + 0.018, 0.032, cabelo_br, outline=borda_cab, ow=0.05, smooth=False)
    s.sym(_chaikin([
        (0.38, 0.44), (0.68, 0.16), (1.52, -0.08), (1.55, 0.06), (0.70, 0.30)
    ], 1), TOP + 0.052, 0.012, cabelo_gr, smooth=False)

    # Rugas de expressão na testa calva (separadas no meio e emolduradas pelo cabelo branco atrás!)
    # e pés de galinha nas bochechas
    for y_r, x0_r, x1_r in [(-0.55, 0.45, 1.22), (-0.92, 0.38, 1.15)]:
        c_ruga = _curva([(x0_r, y_r), ((x0_r + x1_r) * 0.5, y_r - 0.12), (x1_r, y_r + 0.04)], per=5)
        s.sym(_tubo(c_ruga, lambda t: 0.065 * (1.0 - 0.3 * abs(2 * t - 1)), cap0=True, cap1=True, n=10),
              TOP + 0.008, 0.010, borda, smooth=False)

    for pts_b in [
        [(1.25, 0.48), (1.58, 0.62)],
        [(1.25, 0.28), (1.58, 0.34)],
    ]:
        c_b = _curva(pts_b, per=4)
        s.sym(_tubo(c_b, lambda t: 0.055, cap0=True, cap1=True, n=8),
              TOP + 0.008, 0.010, borda, smooth=False)

    # Mão: mão de ancião com manga/punho branco-grisalho na base e dedos esculpidos
    punho_mao = _chaikin([(-0.46, -0.42), (0.46, -0.42), (0.50, 0.02), (-0.50, 0.02)], 1)
    s.hand_flat(punho_mao, 1.32, 0.48, cabelo_gr, outline=borda_cab, ow=0.04, smooth=False)
    s.hand_flat(_chaikin([(-0.38, -0.32), (0.38, -0.32), (0.40, -0.05), (-0.40, -0.05)], 1),
                1.82, 0.020, cabelo_br, smooth=False)
    for kk in (-1, 0, 1):
        s.hand_flat(ellipse(kk * 0.20, 0.26, 0.10, 0.13, n=10), 1.81, 0.022, ruga_suave)


# ---------------------------------------------------------------- 10. Sombra Carmesim
def sombra_carmesim(s):
    # Entidade/Demônio de Sombra Vinho-Escura (#400814, contorno #280414) bem ameaçadora:
    # Grandes chifres/espinhos sombrios afiados com veios Neon (#FC0000, emit=1.5) nos cantos e laterais,
    # partículas/gotas de energia vermelha (#B40404 e #FC0000 com emit=1.5) desprendendo-se nas bordas,
    # fissuras carmesim (#640810 / #84040C), presas frontais neon e SOBRANCELHAS FURIOSAS ANGULARES
    # em Neon vermelho (#FC0000, emit=1.8) sobre os olhos; mãos escuras com garras neon longas!
    corpo, borda, sombra_med, fiss_esc, fiss_cl, neon_esc, neon_vivo = (
        "#400814", "#280414", "#500C1C", "#640810", "#84040C", "#B40404", "#FC0000"
    )
    s.base()

    # Grandes chifres/espinhos sombrios afiados nos cantos traseiros com veios de energia vermelha neon
    for k in (-1, 1):
        X = lambda P: [(k * x, y) for x, y in P]
        chifre_sombra = _chaikin([
            (0.75, -1.05), (1.82, -0.88), (2.78, -1.65), (3.18, -2.98),
            (2.15, -2.65), (1.35, -1.95), (0.65, -1.48)
        ], 1)
        s.flat(X(chifre_sombra), 0.88, 1.06, corpo, outline=borda, ow=0.10, smooth=False)
        veio_ch = _curva([(1.15, -1.25), (2.15, -1.58), (2.92, -2.68)], per=5)
        s.flat(X(_tubo(veio_ch, lambda t: 0.14 * (1.0 - 0.65 * t), cap0=True, cap1=True, n=12)),
               1.95, 0.020, neon_esc, smooth=False, emit=0.9)
        s.flat(X(_tubo(veio_ch, lambda t: 0.07 * (1.0 - 0.65 * t), cap0=True, cap1=True, n=12)),
               1.97, 0.022, neon_vivo, smooth=False, emit=1.6)

    # Placas/espinhos sombrios agressivos saindo na silhueta traseira e lateral
    chama_tras = _chaikin([
        (-1.35, -1.32), (-1.65, -2.35), (-0.92, -1.95),
        (-0.55, -2.85), (0.0, -3.22), (0.55, -2.85),
        (0.92, -1.95), (1.65, -2.35), (1.35, -1.32)
    ], 1)
    _extensao_sem_costura(s, chama_tras, corpo, borda, ow=0.10, z_cap=1.78, z_cap_top=2.01)

    chama_lat = [
        (1.45, 1.05), (2.52, 0.72), (1.92, 0.22),
        (2.72, -0.28), (1.98, -0.68), (2.55, -1.18), (1.45, -1.28)
    ]
    s.sym(chama_lat, 0.85, 1.06, corpo, outline=borda, ow=0.10, smooth=False)

    # Duas presas sombrias/neon afiadas saindo na borda frontal (100% à frente dos olhos!)
    for k in (-1, 1):
        X = lambda P: [(k * x, y) for x, y in P]
        presa_s = _chaikin([(0.45, 1.55), (0.62, 2.38), (0.95, 2.08), (0.98, 1.55)], 1)
        s.flat(X(presa_s), 0.88, 1.06, neon_esc, outline=borda, ow=0.08, smooth=False, emit=0.8)
        s.flat(X([(0.55, 1.65), (0.64, 2.18), (0.82, 1.96)]), 1.95, 0.024, neon_vivo, smooth=False, emit=1.6)

    # Partículas/gotas de energia vermelha (#B40404 e #FC0000 com emit=1.5) desprendendo-se nas bordas
    gotas_energia = [
        (0.0, -2.62, -90, 0.92, 0.28),
        (-1.18, -2.08, -115, 0.75, 0.24),
        (1.18, -2.08, -65, 0.75, 0.24),
        (-2.28, -0.28, 192, 0.72, 0.24),
        (2.28, -0.28, -12, 0.72, 0.24),
        (-2.15, 0.62, 165, 0.62, 0.20),
        (2.15, 0.62, 15, 0.62, 0.20),
    ]
    for gx, gy, gang, gL, gw in gotas_energia:
        pol_g = _espinho(gx, gy, math.radians(gang), gL, gw)
        s.flat(pol_g, 0.90, 1.04, neon_esc, outline=borda, ow=0.07, smooth=False, emit=0.8)
        pol_g_in = _espinho(gx, gy, math.radians(gang), gL * 0.75, gw * 0.58)
        s.flat(pol_g_in, 1.95, 0.025, neon_vivo, smooth=False, emit=1.5)

    # Partículas/orbes soltos de energia neon nas pontas traseiras e laterais
    for ox, oy, orad in [
        (-0.62, -3.02, 0.18), (0.62, -3.02, 0.18),
        (-2.58, -1.08, 0.16), (2.58, -1.08, 0.16),
    ]:
        s.flat(ellipse(ox, oy, orad, orad, n=12), 0.90, 1.04, neon_esc, outline=borda, ow=0.06, emit=0.8)
        s.flat(ellipse(ox, oy, orad * 0.60, orad * 0.60, n=10), 1.95, 0.025, neon_vivo, emit=1.5)

    # Camadas sombrias (#500C1C) e fissuras carmesim (#640810 / #84040C / #FC0000 emit=1.5) no topo
    s.sym(_chaikin([(1.18, 1.35), (1.68, 1.05), (1.68, -1.18), (1.15, -1.48), (1.30, 0.0)], 1),
          TOP, 0.010, sombra_med, smooth=False)

    fissuras = [
        [(0.65, -0.82), (1.08, -1.35), (1.52, -1.68)],
        [(1.08, -1.35), (1.58, -0.88)],
        [(-0.65, -0.82), (-1.08, -1.35), (-1.52, -1.68)],
        [(-1.08, -1.35), (-1.58, -0.88)],
        [(0.0, -1.18), (0.0, -2.25)],
        [(1.38, -0.05), (1.62, 0.45), (1.42, 1.18)],
        [(-1.38, -0.05), (-1.62, 0.45), (-1.42, 1.18)],
        [(0.0, 1.58), (0.0, 0.92)],
    ]
    for pts_f in fissuras:
        s.flat(_tubo(pts_f, lambda t: 0.15, cap0=True, cap1=True, n=8),
               TOP + 0.012, 0.012, fiss_esc, smooth=False)
        s.flat(_tubo(pts_f, lambda t: 0.09, cap0=True, cap1=True, n=8),
               TOP + 0.024, 0.012, fiss_cl, smooth=False)
        s.flat(_tubo(pts_f, lambda t: 0.04, cap0=True, cap1=True, n=8),
               TOP + 0.036, 0.014, neon_vivo, smooth=False, emit=1.5)

    # OLHOS AMEAÇADORES COM ARCO INFERIOR + SOBRANCELHAS FURIOSAS ANGULARES EM NEON VERMELHO (#FC0000, emit=1.8)!
    for k in (-1, 1):
        X = lambda P: [(k * x, y) for x, y in P]
        # Semicírculo inferior/lateral em brasa ao redor do olho (r_in = 0.48)
        arco_inf = _arco(EYE_X, EYE_Y, 0.48, 0.66, math.radians(-20), math.radians(190), n=12)
        s.flat(X(arco_inf), TOP + 0.014, 0.018, neon_esc, smooth=False, emit=1.0)
        arco_inf_v = _arco(EYE_X, EYE_Y, 0.50, 0.60, math.radians(-15), math.radians(185), n=12)
        s.flat(X(arco_inf_v), TOP + 0.032, 0.018, neon_vivo, smooth=False, emit=1.8)

    # Sobrancelhas furiosas angulares com chamas neon apontando para as têmporas (separadas no centro!)
    sobr_sombra_base = [
        (0.28, 0.46), (0.58, 0.10), (1.15, -0.14), (1.72, -0.35),
        (1.62, 0.08), (1.78, 0.22), (1.18, 0.24), (0.64, 0.38), (0.30, 0.62)
    ]
    s.sym(sobr_sombra_base, TOP + 0.018, 0.024, neon_esc, outline=borda, ow=0.04, smooth=False, emit=1.0)
    sobr_sombra_neon = [
        (0.32, 0.48), (0.60, 0.15), (1.15, -0.08), (1.64, -0.26),
        (1.52, 0.06), (1.14, 0.18), (0.64, 0.32), (0.34, 0.56)
    ]
    s.sym(sobr_sombra_neon, TOP + 0.044, 0.022, neon_vivo, smooth=False, emit=1.8)

    # Mão: mão escura com fissura carmesim e 3 garras longas afiadas em neon (#B40404 e #FC0000, emit=1.5)
    s.hand_flat(ellipse(0.0, -0.04, 0.28, 0.22, n=12), 1.82, 0.020, fiss_cl)
    s.hand_flat(ellipse(0.0, -0.04, 0.14, 0.11, n=10), 1.84, 0.022, neon_vivo, emit=1.5)
    for kk in (-1, 0, 1):
        s.hand_flat(_espinho(kk * 0.22, 0.30, math.radians(90 - 18 * kk), 0.54, 0.12),
                    1.28, 0.42, neon_esc, outline=borda, ow=0.04, smooth=False, emit=0.9)
        s.hand_flat(_espinho(kk * 0.22, 0.32, math.radians(90 - 18 * kk), 0.40, 0.065),
                    1.72, 0.03, neon_vivo, smooth=False, emit=1.6)


LOTE = [
    ("gato_rosa", gato_rosa, "#FCFCFC", "#C4144C", "#FCFCFC", "#C4144C"),
    ("pinguim", pinguim, "#202020", "#3C3C3C", "#202020", "#3C3C3C"),
    ("gato_lilas", gato_lilas, "#E8A0F8", "#B04CD4", "#E8A0F8", "#B04CD4"),
    ("coco", coco, "#684020", "#3E2210", "#684020", "#3E2210"),
    ("lama", lama, "#886034", "#402008", "#886034", "#402008"),
    ("jarra_vidro", jarra_vidro, "#BCDCEC", "#708494", "#BCDCEC", "#708494"),
    ("geleia_rubi", geleia_rubi, "#C42C3C", "#701428", "#C42C3C", "#701428"),
    ("fantasminha", fantasminha, "#DCF4FC", "#B0D0F0", "#DCF4FC", "#B0D0F0"),
    ("anciao", anciao, "#D08484", "#985C68", "#D08484", "#985C68"),
    ("sombra_carmesim", sombra_carmesim, "#400814", "#280414", "#400814", "#280414"),
]
