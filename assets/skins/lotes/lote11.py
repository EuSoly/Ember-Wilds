# Lote 11 — skins de corpo (detalhadas). Montar com build_skins.py (Blender aberto) ou render_lote.py (segundo plano).
# kitsune, ostra, lince_roxo, urso_polar, espectro, monstro_cristal, goblin, caracal, ciborgue_sombrio, rocha_magma.
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


def _extensao_sem_costura(s, pts, cor_base, cor_borda, ow=0.09, z_cap_top=2.00, z_base=0.68, z_cap=1.77):
    """Cria uma extensão de silhueta cujo contorno fica abaixo do chanfro do corpo (z_top=1.78 < 1.82)
    e cuja tampa superior sem contorno cobre o Outline do corpo (z=1.90) sem riscar o topo."""
    s.flat(pts, z_base, 1.10, cor_base, outline=cor_borda, ow=ow, smooth=False)
    s.flat(pts, z_cap, z_cap_top - z_cap, cor_base, smooth=False)


# ---------------------------------------------------------------- 1. Kitsune
def kitsune(s):
    # Raposa mística branca com marcações e contorno vermelho-vivo, orelhas grandes pontudas brancas
    # com interior vermelho, tufos laterais nas bochechas e caudas/pontas brancas com ponta vermelha
    # saindo na silhueta traseira; mãos brancas com garras vermelhas.
    corpo, borda, verm, rosado, preto = "#f8f8f8", "#c00000", "#b80000", "#f0e0e8", "#181818"
    s.base()

    # Caudas/pontas místicas saindo na silhueta traseira (central + par lateral em leque) com ponta vermelha
    cauda_c = _chaikin([
        (-0.55, -1.45), (-0.68, -2.35), (0.0, -3.22), (0.68, -2.35), (0.55, -1.45)
    ], 2)
    s.flat(cauda_c, 0.86, 1.06, corpo, outline=borda, ow=0.09, smooth=False)
    ponta_c = _chaikin([
        (-0.45, -2.22), (-0.48, -2.52), (0.0, -3.12), (0.48, -2.52), (0.45, -2.22), (0.0, -2.42)
    ], 1)
    s.flat(ponta_c, 1.93, 0.025, verm, smooth=False)

    cauda_lat = _chaikin([
        (0.42, -1.48), (1.08, -1.68), (1.58, -2.42), (1.42, -3.05), (0.72, -2.58), (0.35, -1.82)
    ], 2)
    s.sym(cauda_lat, 0.84, 1.06, corpo, outline=borda, ow=0.09, smooth=False)
    ponta_lat = _chaikin([
        (0.95, -2.15), (1.45, -2.38), (1.36, -2.96), (0.80, -2.52)
    ], 1)
    s.sym(ponta_lat, 1.91, 0.025, verm, smooth=False)

    # Orelhas grandes pontudas brancas abrindo para trás/lados com interior vermelho e sombreado rosado
    orelha = _chaikin([
        (0.65, -0.82), (1.72, -0.58), (2.72, -1.25), (3.02, -2.58),
        (2.18, -2.65), (1.18, -1.95), (0.55, -1.45)
    ], 2)
    s.sym(orelha, 0.88, 1.04, corpo, outline=borda, ow=0.10, smooth=False)
    miolo_rosa = _chaikin([
        (1.05, -0.98), (1.82, -0.88), (2.55, -1.48), (2.68, -2.35), (1.85, -2.22), (1.08, -1.55)
    ], 2)
    s.sym(miolo_rosa, 1.93, 0.015, rosado, smooth=False)
    miolo_verm = _chaikin([
        (1.32, -1.15), (2.18, -1.22), (2.62, -2.25), (1.92, -2.08), (1.35, -1.55)
    ], 2)
    s.sym(miolo_verm, 1.95, 0.02, verm, smooth=False)

    # Tufos laterais duplos afiados nas bochechas com detalhe vermelho nas pontas
    tufo = [
        (1.48, -0.32), (2.38, 0.05), (1.92, 0.42),
        (2.45, 0.88), (1.88, 1.18), (2.05, 1.52), (1.42, 1.48)
    ]
    s.sym(tufo, 0.86, 1.06, corpo, outline=borda, ow=0.09, smooth=False)
    s.sym([(1.85, -0.05), (2.32, 0.06), (1.92, 0.28)], 1.93, 0.02, verm, smooth=False)
    s.sym([(1.88, 0.62), (2.38, 0.86), (1.92, 0.98)], 1.93, 0.02, verm, smooth=False)

    # Focinho pontudo contínuo com o rosto + narizinho escuro na ponta (ajuste Elizeu 09/11/2026: z_cap=1.777..2.007)
    foc = _chaikin([
        (-0.82, 1.25), (-0.68, 1.95), (0.0, 2.38), (0.68, 1.95), (0.82, 1.25), (0.0, 1.05)
    ], 2)
    _extensao_sem_costura(s, foc, corpo, borda, ow=0.09, z_cap=1.777, z_cap_top=2.007)
    s.flat(ellipse(0.0, 1.55, 0.48, 0.36, n=14), TOP + 0.005, 0.012, rosado)
    nar = _chaikin([(-0.26, 1.68), (0.26, 1.68), (0.30, 1.90), (0.0, 2.12), (-0.30, 1.90)], 2)
    s.flat(nar, TOP + 0.02, 0.035, preto, smooth=False)

    # Sombreado suave rosado nas laterais do dorso
    s.sym(_chaikin([(1.18, 0.95), (1.62, 0.75), (1.65, -0.85), (1.22, -1.25), (1.28, -0.05)], 2),
          TOP, 0.01, rosado, smooth=False)

    # Marcações místicas vermelho-vivo no topo (centro atrás dos olhos 100% limpo!):
    # 1) Chama/losango na ponte do nariz/testa (entre os olhos)
    chama_testa = _chaikin([
        (0.0, 1.32), (0.22, 0.80), (0.0, 0.28), (-0.22, 0.80)
    ], 1)
    s.flat(chama_testa, TOP + 0.015, 0.02, verm, smooth=False)

    # 2) Anel místico vermelho de kitsune ao redor de cada olho + ponta externa de delineado para a têmpora
    for k in (-1, 1):
        _anel_quads(s, k * EYE_X, EYE_Y, 0.48, 0.61, TOP + 0.015, 0.02, verm, n=16)
    s.sym(_chaikin([(1.20, 0.62), (1.58, 0.82), (1.42, 0.46)], 1), TOP + 0.015, 0.02, verm, smooth=False)

    # 3) Pinturas curvas vermelhas nas laterais/flancos (|x| > 1.18)
    for y0, y1 in [(0.12, 0.35), (-0.42, -0.15), (-0.95, -0.65)]:
        marca_lat = _chaikin([(1.18, y0), (1.62, y0 - 0.12), (1.62, y1 - 0.10), (1.20, y1)], 1)
        s.sym(marca_lat, TOP + 0.015, 0.02, verm, smooth=False)

    # Mão: patinha branca com marca vermelha no dorso e 3 garras vermelhas afiadas
    s.hand_flat(ellipse(0.0, -0.05, 0.26, 0.18, n=12), 1.83, 0.025, verm)
    for kk in (-1, 0, 1):
        s.hand_flat(_espinho(kk * 0.22, 0.34, math.radians(90 - 18 * kk), 0.46, 0.11),
                    1.28, 0.38, verm, outline=borda, ow=0.04, smooth=False)


# ---------------------------------------------------------------- 2. Ostra
def ostra(s):
    # Ostra marinha aberta com pérola (madrepérola de recife, bem distinta da concha lilás do lote 2):
    # Corpo base nacarado claro (#F6EFEA, contorno #B89888) onde ficam os olhos,
    # valva inferior em leque de 5 gomos na frente/laterais (#D88880, contorno #683838, interior #ECA8A0),
    # valva superior em grande leque de 5 gomos radiais atrás (#D88880, relevos #ECA8A0, costelas #A85858)
    # e pérola esférica 3D brilhante (#FFFFFF) no leito da concha; mãos com mini-valvas e pérola.
    nacre, nacre_b, casca, casca_b, rosa_cl, costela, perola = (
        "#F6EFEA", "#B89888", "#D88880", "#683838", "#ECA8A0", "#A85858", "#FFFFFF"
    )
    s.base()

    # Valva inferior (base da concha aberta): saindo por baixo/frente e pelas laterais
    # formando uma borda ondulada de 5 gomos largos em leque na frente e abas laterais
    valva_inf_frente = _chaikin([
        (-1.75, 0.85), (-2.38, 0.48), (-2.45, -0.15), (-1.92, -0.58),
        (-1.78, 1.35), (-1.68, 2.12), (-1.08, 1.92),
        (-0.82, 2.32), (-0.35, 2.02),
        (0.0, 2.42),
        (0.35, 2.02), (0.82, 2.32),
        (1.08, 1.92), (1.68, 2.12), (1.78, 1.35),
        (1.92, -0.58), (2.45, -0.15), (2.38, 0.48), (1.75, 0.85),
        (1.15, 1.15), (0.0, 1.18), (-1.15, 1.15)
    ], 2)
    s.flat(valva_inf_frente, 0.72, 1.05, casca, outline=casca_b, ow=0.10, smooth=False)
    s.flat(valva_inf_frente, 1.77, 0.14, casca, smooth=False)

    # Interior nacarado rosado (#ECA8A0) nos 5 gomos frontais e nas abas laterais da valva inferior
    for gx, gy, rx, ry, rot in [
        (0.0, 2.05, 0.28, 0.26, 0.0),
        (-0.68, 1.98, 0.25, 0.22, 0.25),
        (0.68, 1.98, 0.25, 0.22, -0.25),
        (-1.38, 1.82, 0.24, 0.20, 0.5),
        (1.38, 1.82, 0.24, 0.20, -0.5),
        (-2.05, 0.15, 0.28, 0.40, 0.15),
        (2.05, 0.15, 0.28, 0.40, -0.15),
    ]:
        s.flat(ellipse(gx, gy, rx, ry, n=12, rot=rot), 1.915, 0.02, rosa_cl)

    # Valva superior (tampa da ostra entreaberta): cobrindo a metade traseira (y < -0.05)
    # e abrindo em um grande leque de 5 gomos radiais bem marcados para trás (y até -2.78) e lados (x até ±2.42)
    valva_sup = _chaikin([
        (-1.72, -0.05),
        (-2.38, -0.48), (-2.42, -1.05), (-1.92, -1.28),
        (-2.12, -1.78), (-1.58, -2.25), (-1.08, -2.02),
        (-0.72, -2.62), (0.0, -2.78), (0.72, -2.62),
        (1.08, -2.02), (1.58, -2.25), (2.12, -1.78),
        (1.92, -1.28), (2.42, -1.05), (2.38, -0.48),
        (1.72, -0.05),
        (1.15, -0.22), (0.0, -0.32), (-1.15, -0.22)
    ], 2)
    _extensao_sem_costura(s, valva_sup, casca, casca_b, ow=0.10, z_cap_top=2.01)

    # 5 gomos radiais em relevo (#ECA8A0) abrindo em leque na valva superior
    gomos_sup = [
        # Gomo central
        [(-0.22, -0.58), (-0.48, -2.42), (0.0, -2.58), (0.48, -2.42), (0.22, -0.58)],
        # Gomos intermediários (±X)
        [(0.28, -0.55), (0.78, -1.92), (1.42, -2.05), (1.82, -1.68), (0.68, -0.48)],
        [(-0.28, -0.55), (-0.78, -1.92), (-1.42, -2.05), (-1.82, -1.68), (-0.68, -0.48)],
        # Gomos laterais externos (±X)
        [(0.72, -0.42), (1.72, -1.18), (2.18, -0.95), (2.15, -0.52), (1.25, -0.22)],
        [(-0.72, -0.42), (-1.72, -1.18), (-2.18, -0.95), (-2.15, -0.52), (-1.25, -0.22)],
    ]
    for g_pts in gomos_sup:
        s.flat(_chaikin(g_pts, 2), TOP + 0.012, 0.018, rosa_cl, smooth=False)

    # Estrias/costelas radiais (#A85858) nos sulcos entre os gomos partindo da região da pérola/charneira
    for ang_deg, comp in [(-58, 1.50), (-28, 1.65), (0, 1.38), (28, 1.65), (58, 1.50)]:
        a = math.radians(-90 + ang_deg)
        x0, y0 = 0.0, -0.88
        x1, y1 = x0 + math.cos(a) * comp, y0 + math.sin(a) * comp
        c = _curva([(x0, y0), ((x0 + x1) * 0.5, (y0 + y1) * 0.5), (x1, y1)], per=5)
        s.flat(_tubo(c, lambda t: 0.06 + 0.05 * t, cap0=True, cap1=True, n=10),
               TOP + 0.030, 0.014, costela, smooth=False)

    # Anel/leito nacarado suave (#F6EFEA e #ECA8A0) + Pérola esférica 3D brilhante (#FFFFFF) de destaque
    py_p = -1.28
    s.flat(ellipse(0.0, py_p, 0.60, 0.52, n=20), TOP + 0.038, 0.018, costela)
    s.flat(ellipse(0.0, py_p, 0.52, 0.45, n=20), TOP + 0.056, 0.018, nacre)
    s.sphere((0.0, py_p, TOP + 0.12), (0.40, 0.40, 0.26), perola)
    s.flat(ellipse(-0.08, py_p + 0.08, 0.18, 0.15, n=12, rot=0.3), TOP + 0.36, 0.02, perola)

    # Mão: mini-valva ondulada de ostra (#D88880 com contorno #683838) segurando mini-pérola branca (#FFFFFF)
    concha_mao = _chaikin([
        (-0.45, -0.15), (-0.52, 0.25), (-0.25, 0.48), (0.0, 0.58),
        (0.25, 0.48), (0.52, 0.25), (0.45, -0.15), (0.0, -0.32)
    ], 2)
    s.hand_flat(concha_mao, 1.32, 0.48, casca, outline=casca_b, ow=0.05, smooth=False)
    s.hand_flat(ellipse(0.0, 0.08, 0.30, 0.24, n=12), 1.81, 0.02, rosa_cl)
    s.hand_flat(ellipse(0.0, 0.05, 0.22, 0.22, n=14), 1.83, 0.05, perola)


# ---------------------------------------------------------------- 3. Lince Roxo
def lince_roxo(s):
    # Felino místico roxo com orelhas compridas pontudas e tufos creme nas pontas,
    # pelagem lateral espessa nas bochechas e manchas suaves no topo; mãos roxas com garras creme.
    corpo, borda, roxo_esc, creme, pardo, branco = (
        "#b068d8", "#201820", "#784890", "#e8d8b8", "#706858", "#f8f8f8"
    )
    s.base()

    # Orelhas compridas pontudas saindo das laterais traseiras com longos tufos creme nas pontas
    orelha = _chaikin([
        (0.68, -0.78), (1.68, -0.55), (2.55, -1.22), (2.72, -2.38),
        (1.92, -2.45), (1.12, -1.82), (0.58, -1.38)
    ], 2)
    s.sym(orelha, 0.88, 1.04, corpo, outline=borda, ow=0.10, smooth=False)
    sombra_or = _chaikin([
        (0.95, -0.92), (1.78, -0.75), (2.48, -1.35), (2.55, -2.22), (1.82, -2.18), (1.05, -1.55)
    ], 2)
    s.sym(sombra_or, 1.93, 0.015, roxo_esc, smooth=False)
    miolo_or = _chaikin([
        (1.25, -1.12), (1.98, -1.15), (2.35, -1.98), (1.75, -1.95), (1.25, -1.48)
    ], 2)
    s.sym(miolo_or, 1.95, 0.02, creme, smooth=False)

    # Tufos compridos creme nas pontas das orelhas (assinatura do lince!)
    tufo_ponta = _chaikin([
        (2.15, -2.05), (2.62, -1.98), (3.15, -2.78), (3.02, -3.22), (2.38, -2.70), (2.02, -2.28)
    ], 1)
    s.sym(tufo_ponta, 0.90, 1.06, creme, outline=borda, ow=0.08, smooth=False)
    s.sym([(2.32, -2.18), (2.92, -2.88), (2.52, -2.58)], 1.97, 0.02, pardo, smooth=False)

    # Pelagem lateral espessa nas bochechas (três pontas felpudas de lince com pontas creme)
    pelagem_lat = [
        (1.42, -0.42), (2.52, -0.12), (2.02, 0.25), (2.68, 0.68),
        (2.08, 1.02), (2.38, 1.48), (1.42, 1.58)
    ]
    s.sym(pelagem_lat, 0.86, 1.06, corpo, outline=borda, ow=0.10, smooth=False)
    s.sym(_chaikin([(1.55, -0.25), (2.25, -0.05), (1.88, 0.28), (1.55, 0.15)], 1),
          1.93, 0.018, roxo_esc, smooth=False)
    s.sym([(1.85, 0.45), (2.55, 0.68), (1.98, 0.92)], 1.93, 0.02, creme, smooth=False)
    s.sym([(1.78, 1.08), (2.30, 1.44), (1.68, 1.42)], 1.93, 0.02, creme, smooth=False)

    # Focinho felino contínuo com o rosto + almofadas creme e nariz escuro na ponta
    foc = _chaikin([
        (-0.85, 1.25), (-0.72, 1.95), (0.0, 2.30), (0.72, 1.95), (0.85, 1.25), (0.0, 1.08)
    ], 2)
    _extensao_sem_costura(s, foc, corpo, borda, ow=0.09)
    s.flat(ellipse(0.0, 1.65, 0.65, 0.42, n=16), TOP + 0.005, 0.015, creme)
    s.sym(ellipse(0.30, 1.72, 0.24, 0.18, n=12), TOP + 0.02, 0.015, branco)
    nar = _chaikin([(-0.30, 1.55), (0.30, 1.55), (0.34, 1.78), (0.0, 2.02), (-0.34, 1.78)], 2)
    s.flat(nar, TOP + 0.035, 0.035, pardo, smooth=False)

    # Manchinhas creme acima/frente dos olhos + manchas suaves roxo-escuras nas laterais/costas
    s.sym(ellipse(0.75, 1.12, 0.24, 0.13, n=12, rot=-0.25), TOP + 0.015, 0.02, creme)
    for mx, my, rx, ry, rot in [
        (1.28, -0.35, 0.34, 0.22, 0.35),
        (1.08, -1.18, 0.42, 0.26, -0.25),
        (0.45, -1.52, 0.28, 0.18, 0.15),
    ]:
        s.sym(ellipse(mx, my, rx, ry, n=14, rot=rot), TOP + 0.01, 0.015, roxo_esc)

    # Mão: patinha roxa com mancha escura e 3 garras creme afiadas
    s.hand_flat(ellipse(0.0, -0.05, 0.30, 0.22, n=12), 1.83, 0.025, roxo_esc)
    for kk in (-1, 0, 1):
        s.hand_flat(_espinho(kk * 0.22, 0.34, math.radians(90 - 18 * kk), 0.45, 0.11),
                    1.28, 0.38, creme, outline=borda, ow=0.04, smooth=False)


# ---------------------------------------------------------------- 4. Urso Polar
def urso_polar(s):
    # Urso polar do ártico (ref. 166): mesma estrutura limpa do urso_pardo (lote 8) com as cores exatas da ref 166:
    # corpo e mão #F0EDE0, contorno bege-areia suave #D8B49D, interior da orelha #E0AA99,
    # focinho creme-pêssego #F2D3B3 e nariz/garras #382624.
    pelo, borda, miolo_or_c, foc_c, nariz = "#F0EDE0", "#D8B49D", "#E0AA99", "#F2D3B3", "#382624"
    s.base()

    # Grandes orelhas ovais nos cantos traseiros-laterais com miolo recortado em zigue-zague (#E0AA99)
    for k in (-1, 1):
        X = lambda P: [(k * x, y) for x, y in P]
        s.flat(ellipse(k * 1.75, -1.55, 0.98, 0.92, n=24, rot=-k * 0.35),
               0.88, 1.02, pelo, outline=borda, ow=0.10)
        miolo_or = _chaikin([
            (1.38, -1.25), (1.95, -1.15), (2.28, -1.65), (2.05, -2.08),
            (1.85, -1.78), (1.68, -1.95), (1.58, -1.65), (1.35, -1.72)
        ], 1)
        s.flat(X(miolo_or), 1.91, 0.025, miolo_or_c, smooth=False)

    # Tufos felpudos nas bochechas/laterais da frente com dois dentinhos de pelo
    tufo = _chaikin([
        (1.48, -0.35), (2.12, -0.15), (2.18, 0.45), (1.92, 0.55),
        (2.15, 0.95), (1.95, 1.55), (1.42, 1.65)
    ], 1)
    s.sym(tufo, 0.88, 1.02, pelo, outline=borda, ow=0.09, smooth=False)

    # Focinho oval saliente na frente (#F2D3B3 com contorno #D8B49D abaixo do chanfro + tampa sem costura)
    # e nariz triangular arredondado escuro (#382624) na ponta da frente
    foc = _chaikin([
        (-0.62, 0.35), (-0.42, 0.05), (0.0, -0.05), (0.42, 0.05), (0.62, 0.35),
        (0.75, 1.55), (0.48, 2.15), (0.0, 2.28), (-0.48, 2.15), (-0.75, 1.55)
    ], 2)
    _extensao_sem_costura(s, foc, foc_c, borda, ow=0.08, z_cap_top=2.01)
    nar = _chaikin([(-0.32, 1.38), (0.32, 1.38), (0.36, 1.62), (0.0, 1.88), (-0.36, 1.62)], 2)
    s.flat(nar, TOP + 0.02, 0.04, nariz, smooth=False)

    # Mão: apenas as 3 garras escuras (#382624) na frente
    for kk in (-1, 0, 1):
        s.hand_flat(ellipse(kk * 0.22, 0.36, 0.10, 0.13, n=8), 1.4, 0.35, nariz)


# ---------------------------------------------------------------- 5. Espectro
def espectro(s):
    # Espectro sombrio (ref. 180): SEM orelhas e SEM anéis redondos nos olhos!
    # Proa/bico frontal pontudo em V (#201820 com contorno rubi #B6222A),
    # sobrancelhas furiosas inclinadas em V sobre os olhos (#B6222A com friso #622024),
    # silhueta de lâminas/chamas de sombra pontiagudas varrendo para trás nas laterais e traseira,
    # e mãos angulares/afiadas com carapaça pontuda e 3 garras longas vermelhas.
    corpo, borda, cam1, cam2, cam3 = (
        "#201820", "#B6222A", "#341F21", "#622024", "#902020"
    )
    s.base()

    # Silhueta traseira e lateral de lâminas/chamas de sombra varrendo para trás (5 pontas rasgadas atrás + ombros, SEM orelhas!)
    manto_tras = [
        (-1.45, -1.15), (-2.38, -2.35), (-1.42, -1.92),
        (-1.18, -2.82), (-0.52, -2.08),
        (0.0, -3.02),
        (0.52, -2.08), (1.18, -2.82),
        (1.42, -1.92), (2.38, -2.35), (1.45, -1.15)
    ]
    s.flat(manto_tras, 0.85, 1.06, corpo, outline=borda, ow=0.10, smooth=False)
    # Camadas internas carmesim-escuras nas pontas traseiras
    s.flat([
        (-1.18, -1.35), (-1.98, -2.12), (-1.28, -1.75),
        (-1.02, -2.52), (-0.42, -1.92), (0.0, -2.68),
        (0.42, -1.92), (1.02, -2.52),
        (1.28, -1.75), (1.98, -2.12), (1.18, -1.35)
    ], 1.92, 0.02, cam1, smooth=False)
    s.flat([
        (-0.82, -1.55), (-0.92, -2.28), (-0.35, -1.85), (0.0, -2.42),
        (0.35, -1.85), (0.92, -2.28), (0.82, -1.55)
    ], 1.94, 0.02, cam2, smooth=False)

    # Lâminas de sombra afiadas nos ombros/laterais varrendo para trás (quebrando a lateral quadrada)
    lamina_lat = [
        (1.42, 1.38), (2.32, 0.88), (1.88, 0.52),
        (2.55, -0.15), (1.92, -0.45),
        (2.62, -1.25), (1.45, -1.25)
    ]
    s.sym(lamina_lat, 0.86, 1.06, corpo, outline=borda, ow=0.10, smooth=False)
    s.sym([(1.62, 1.05), (2.15, 0.82), (1.75, 0.48)], 1.93, 0.02, cam2, smooth=False)
    s.sym([(1.65, 0.25), (2.35, -0.12), (1.78, -0.38)], 1.93, 0.02, cam1, smooth=False)
    s.sym([(1.68, -0.58), (2.38, -1.12), (1.62, -1.05)], 1.93, 0.02, cam2, smooth=False)

    # Bico/proa frontal pontuda em V (terminando em (0.0, 2.55)) dando formato de diamante angular à cabeça! (ajuste Elizeu 09/11/2026: z_cap=1.785..2.015)
    proa_v = [
        (-1.35, 1.35), (-0.88, 1.98), (0.0, 2.58), (0.88, 1.98), (1.35, 1.35), (0.0, 1.15)
    ]
    _extensao_sem_costura(s, proa_v, corpo, borda, ow=0.10, z_cap=1.785, z_cap_top=2.015)
    # Chanfro angular sombrio na ponta do bico frontal
    s.flat([(-0.62, 1.65), (0.0, 2.38), (0.62, 1.65), (0.0, 1.92)], TOP + 0.008, 0.015, cam1, smooth=False)
    s.flat([(-0.38, 1.82), (0.0, 2.32), (0.38, 1.82), (0.0, 2.02)], TOP + 0.024, 0.015, cam2, smooth=False)

    # Armadura/placas laterais escuras no topo emoldurando a face
    s.sym([(1.18, 1.35), (1.68, 1.05), (1.72, -1.15), (1.12, -1.45), (1.35, -0.15)],
          TOP + 0.005, 0.015, cam1, smooth=False)

    # Sobrancelhas furiosas separadas sobre os olhos (sem juntar no centro para não formar linha embaixo dos olhos de cima):
    sobr_raiva_base = [
        (0.36, 0.32), (0.62, 0.08), (1.02, -0.05), (1.50, -0.22),
        (1.56, -0.02), (1.02, 0.14), (0.64, 0.25), (0.34, 0.50)
    ]
    s.sym(sobr_raiva_base, TOP + 0.015, 0.025, borda, smooth=False)
    sobr_raiva_friso = [
        (0.38, 0.36), (0.62, 0.13), (1.02, 0.00), (1.46, -0.15),
        (1.50, -0.06), (1.00, 0.09), (0.62, 0.20), (0.36, 0.45)
    ]
    s.sym(sobr_raiva_friso, TOP + 0.042, 0.015, cam2, smooth=False)
    # Crista/chama rubi central na proa frontal reforçando a expressão ameaçadora
    s.flat([(0.0, 2.05), (0.20, 1.48), (0.0, 1.02), (-0.20, 1.48)], TOP + 0.02, 0.025, borda, smooth=False)

    # Mãos angulares/afiadas: carapaça angular pontuda (#201820 com contorno #B6222A)
    # + 3 garras longas vermelhas (#B6222A) quebrando o formato redondo da mão
    carapaca_mao = [
        (-0.58, -0.25), (0.0, -0.55), (0.58, -0.25),
        (0.65, 0.32), (0.0, 0.68), (-0.65, 0.32)
    ]
    s.hand_flat(carapaca_mao, 1.25, 0.58, corpo, outline=borda, ow=0.06, smooth=False)
    s.hand_flat([(-0.38, -0.15), (0.0, -0.35), (0.38, -0.15), (0.0, 0.38)], 1.84, 0.025, cam2, smooth=False)
    for kk in (-1, 0, 1):
        P = _local(kk * 0.26, 0.36, math.radians(90 - 20 * kk))
        garra_m = [P(0.0, -0.13), P(0.62, 0.0), P(0.0, 0.13)]
        s.hand_flat(garra_m, 1.22, 0.48, borda, outline=cam2, ow=0.03, smooth=False)


# ---------------------------------------------------------------- 6. Monstro de Cristal
def monstro_cristal(s):
    # Criatura roxa de cristal/ametista com chifres curvos nas laterais, cristas facetadas de cristal
    # saindo nas bordas e dois olhinhos extras pequenos no topo; mãos com pontas de cristal.
    corpo, borda, crist_cl, crist_esc, crist_med, branco = (
        "#8838c8", "#302068", "#b058d8", "#6038a0", "#7838b0", "#f8f8f8"
    )
    s.base()

    # Chifres curvos de cristal/ametista saindo das laterais para trás com facetas claras
    for k in (-1, 1):
        X = lambda P: [(k * x, y) for x, y in P]
        chifre = (
            _curva([(0.95, -0.85), (2.12, -0.70), (2.88, -1.45), (2.62, -2.58), (1.80, -3.12)], per=5)
            + _curva([(1.80, -3.12), (1.88, -2.15), (1.35, -1.48), (0.78, -1.35)], per=5)[1:]
        )
        s.flat(X(chifre), 0.90, 1.08, crist_esc, outline=borda, ow=0.10, smooth=False)
        faceta_ch = _chaikin([
            (1.25, -0.95), (2.08, -0.90), (2.62, -1.52), (2.38, -2.45), (1.88, -2.02), (1.32, -1.32)
        ], 1)
        s.flat(X(faceta_ch), 1.99, 0.02, crist_cl, smooth=False)
        s.flat(X([(1.98, -1.12), (2.45, -1.55), (2.20, -1.88), (1.82, -1.38)]),
               2.01, 0.02, branco, smooth=False)

    # Cristas facetadas de cristal saindo nas bordas laterais dianteiras e na borda traseira
    cristal_lat1 = [(1.48, 0.12), (2.52, 0.02), (2.78, 0.58), (2.22, 1.02), (1.48, 0.85)]
    s.sym(cristal_lat1, 0.86, 1.06, crist_cl, outline=borda, ow=0.09, smooth=False)
    s.sym([(1.75, 0.25), (2.40, 0.18), (2.56, 0.55), (1.85, 0.65)], 1.93, 0.02, branco, smooth=False)

    cristal_lat2 = [(1.38, 0.88), (2.25, 1.12), (2.32, 1.62), (1.72, 1.78), (1.32, 1.38)]
    s.sym(cristal_lat2, 0.84, 1.06, crist_med, outline=borda, ow=0.08, smooth=False)
    s.sym([(1.58, 1.08), (2.10, 1.22), (2.14, 1.54), (1.68, 1.55)], 1.91, 0.02, crist_cl, smooth=False)

    # Aglomerado de 3 prismas de cristal saindo na borda traseira
    for cx, cy, w_c, h_c, ang_c, col_c in [
        (0.0, -2.08, 0.78, 1.25, 0, crist_cl),
        (-0.72, -1.92, 0.62, 1.05, 24, crist_med),
        (0.72, -1.92, 0.62, 1.05, -24, crist_med),
    ]:
        P = _local(cx, cy, math.radians(ang_c))
        prisma = [P(-w_c * 0.5, 0.45), P(-w_c * 0.38, -h_c * 0.5), P(0.0, -h_c * 0.75),
                  P(w_c * 0.38, -h_c * 0.5), P(w_c * 0.5, 0.45)]
        s.flat(prisma, 0.86, 1.06, col_c, outline=borda, ow=0.09, smooth=False)
        s.flat([P(-w_c * 0.25, 0.25), P(-w_c * 0.20, -h_c * 0.42), P(0.0, -h_c * 0.60),
                P(w_c * 0.12, -h_c * 0.35), P(w_c * 0.15, 0.25)],
               1.93, 0.02, branco if col_c == crist_cl else crist_cl, smooth=False)

    # Facetas geométricas de ametista no topo + aros cristalinos ao redor dos olhos principais
    s.sym([(1.12, 1.38), (1.65, 1.12), (1.72, -0.58), (1.18, -1.15), (0.95, -0.25)],
          TOP, 0.015, crist_med, smooth=False)
    for k in (-1, 1):
        _anel_quads(s, k * EYE_X, EYE_Y, 0.48, 0.65, TOP + 0.015, 0.02, crist_esc, n=12)

    # Dois olhinhos extras pequenos no topo (nas laterais superiores da testa, longe do eixo central!)
    for k in (-1, 1):
        ex, ey, r_e = k * 1.12, -0.36, 0.32
        s.flat(ellipse(ex, ey, r_e * 1.22, r_e * 1.22, n=14), TOP + 0.02, 0.02, crist_cl)
        s.flat(ellipse(ex, ey, r_e, r_e, n=14), TOP + 0.04, 0.03, borda)
        s.flat(ellipse(ex + 0.10, ey + 0.10, r_e * 0.38, r_e * 0.38, n=10), TOP + 0.072, 0.02, branco)

    # Losango facetado de cristal claro na frente entre os olhos (deixando o centro atrás dos olhos limpo!)
    s.flat([(0.0, 1.62), (0.26, 1.18), (0.0, 0.75), (-0.26, 1.18)], TOP + 0.02, 0.025, crist_cl, smooth=False)
    s.flat([(0.0, 1.46), (0.13, 1.18), (0.0, 0.92), (-0.13, 1.18)], TOP + 0.045, 0.015, branco, smooth=False)

    # Mão: pontas facetadas de cristal saindo da mão
    s.hand_flat([(0.0, 0.25), (0.28, -0.02), (0.0, -0.28), (-0.28, -0.02)], 1.83, 0.03, crist_cl, smooth=False)
    for kk in (-1, 0, 1):
        P = _local(kk * 0.22, 0.32, math.radians(90 - 20 * kk))
        ponta_m = [P(0.0, -0.13), P(0.32, -0.10), P(0.52, 0.0), P(0.32, 0.10), P(0.0, 0.13)]
        s.hand_flat(ponta_m, 1.28, 0.38, crist_cl, outline=borda, ow=0.04, smooth=False)


# ---------------------------------------------------------------- 7. Goblin
def goblin(s):
    # Criatura verde de orelhas compridas pontudas saindo bem para as laterais,
    # pequena crista/topete verde-escuro no topo, duas presinhas brancas curtas na borda da frente
    # (cuidado para não descerem dos olhos!) e mãos verdes com unhas escuras.
    corpo, borda, verde_esc, verde_med, verde_cl, presa = (
        "#18b070", "#201820", "#006838", "#008848", "#089850", "#f8f8f8"
    )
    s.base()

    # Orelhas compridas pontudas de goblin saindo bem para as laterais (com entalhe na borda inferior)
    orelha = _chaikin([
        (1.45, 0.38), (2.45, 0.22), (3.55, -0.28), (3.18, -0.80),
        (2.62, -0.68), (2.38, -1.00), (1.88, -0.78), (1.45, -0.58)
    ], 1)
    s.sym(orelha, 0.88, 1.04, corpo, outline=borda, ow=0.10, smooth=False)
    sulco_or1 = _chaikin([
        (1.68, 0.12), (2.48, 0.02), (3.28, -0.32), (2.55, -0.52), (1.68, -0.32)
    ], 1)
    s.sym(sulco_or1, 1.93, 0.018, verde_cl, smooth=False)
    sulco_or2 = _chaikin([
        (1.78, -0.05), (2.45, -0.12), (3.02, -0.35), (2.40, -0.45), (1.78, -0.28)
    ], 1)
    s.sym(sulco_or2, 1.95, 0.02, verde_esc, smooth=False)

    # Duas presinhas brancas curtas na borda da frente (em y = 1.62..2.26, 100% à frente dos olhos!)
    for k in (-1, 1):
        X = lambda P: [(k * x, y) for x, y in P]
        presa_pts = _chaikin([
            (0.45, 1.62), (0.58, 2.26), (0.84, 2.12), (0.90, 1.62)
        ], 1)
        s.flat(X(presa_pts), 0.88, 1.06, presa, outline=borda, ow=0.08, smooth=False)

    # Narizinho verde achatado na borda frontal (ajuste Elizeu 09/11/2026: z_cap=1.777..2.007)
    nariz_gob = _chaikin([
        (-0.35, 1.38), (-0.42, 1.88), (0.0, 2.08), (0.42, 1.88), (0.35, 1.38)
    ], 2)
    _extensao_sem_costura(s, nariz_gob, corpo, borda, ow=0.07, z_cap=1.777, z_cap_top=2.007)
    s.flat(ellipse(0.0, 1.75, 0.32, 0.22, n=12), TOP + 0.005, 0.015, verde_cl)
    s.sym(ellipse(0.15, 1.78, 0.07, 0.05, n=8, rot=-0.3), TOP + 0.022, 0.02, verde_esc)

    # Sombreado lateral verde-médio no topo + aros de goblin ao redor dos olhos com ponta externa para as orelhas
    s.sym(_chaikin([(1.18, 1.32), (1.65, 1.12), (1.68, -1.15), (1.15, -1.45), (1.32, 0.0)], 2),
          TOP, 0.012, verde_cl, smooth=False)
    for k in (-1, 1):
        _anel_quads(s, k * EYE_X, EYE_Y, 0.48, 0.62, TOP + 0.015, 0.02, verde_esc, n=14)
    s.sym(_chaikin([(1.18, 0.65), (1.58, 0.82), (1.42, 0.42)], 1),
          TOP + 0.015, 0.02, verde_esc, smooth=False)

    # Pequena crista/topete verde-escuro no topo/trás: silhueta traseira abaixo do chanfro (z_top=1.78)
    # + crista superior sem contorno preto sobre o couro cabeludo!
    topete_sil = _chaikin([
        (-0.78, -1.45), (-0.88, -2.02), (-0.38, -1.85), (0.0, -2.48),
        (0.38, -1.85), (0.88, -2.02), (0.78, -1.45)
    ], 1)
    _extensao_sem_costura(s, topete_sil, verde_med, borda, ow=0.09)

    topete_topo = _chaikin([
        (-0.72, -1.05), (-0.85, -1.95), (-0.36, -1.78), (0.0, -2.40),
        (0.36, -1.78), (0.85, -1.95), (0.72, -1.05), (0.0, -0.82)
    ], 1)
    s.flat(topete_topo, TOP + 0.01, 0.025, verde_med, smooth=False)
    topete_miolo = _chaikin([
        (-0.50, -1.15), (-0.60, -1.78), (-0.22, -1.65), (0.0, -2.20),
        (0.22, -1.65), (0.60, -1.78), (0.50, -1.15), (0.0, -0.95)
    ], 1)
    s.flat(topete_miolo, TOP + 0.035, 0.025, verde_esc, smooth=False)

    # Mão: mão verde com detalhe sombreado e 3 unhas escuras pontudas
    s.hand_flat(ellipse(0.0, -0.05, 0.30, 0.20, n=12), 1.83, 0.025, verde_med)
    for kk in (-1, 0, 1):
        s.hand_flat(_espinho(kk * 0.22, 0.34, math.radians(90 - 18 * kk), 0.42, 0.10),
                    1.30, 0.36, verde_esc, outline=borda, ow=0.04, smooth=False)


# ---------------------------------------------------------------- 8. Caracal
def caracal(s):
    # Felino dourado/caramelo com orelhas compridas e tufos pretos longos nas pontas,
    # bochechas creme e pinturas/listras vermelhas e brancas nas laterais e topo;
    # mãos caramelo com garras escuras.
    corpo, borda, verm, creme, terracota, caramelo_s, branco = (
        "#c89860", "#282828", "#b02028", "#f8e0b8", "#b05040", "#b89060", "#f8f8f8"
    )
    s.base()

    # Orelhas compridas de caracal apontando para trás/lados com longos tufos pretos nas pontas
    orelha = _chaikin([
        (0.65, -0.78), (1.65, -0.58), (2.48, -1.28), (2.58, -2.35),
        (1.85, -2.42), (1.08, -1.82), (0.55, -1.38)
    ], 2)
    s.sym(orelha, 0.88, 1.04, corpo, outline=borda, ow=0.10, smooth=False)
    s.sym(_chaikin([(0.95, -0.95), (1.75, -0.82), (2.38, -1.42), (2.42, -2.22), (1.72, -2.15), (1.02, -1.55)], 2),
          1.93, 0.015, caramelo_s, smooth=False)
    s.sym(_chaikin([(1.25, -1.15), (1.92, -1.18), (2.25, -1.98), (1.68, -1.92), (1.22, -1.48)], 2),
          1.95, 0.02, creme, smooth=False)

    # Tufos pretos longos e elegantes saindo das pontas das orelhas (assinatura do caracal!)
    tufo_preto = _chaikin([
        (2.05, -2.00), (2.55, -1.92), (3.18, -2.85), (3.02, -3.32), (2.32, -2.72), (1.92, -2.25)
    ], 1)
    s.sym(tufo_preto, 0.90, 1.08, borda, smooth=False)

    # Bochechas creme felpudas nas laterais (cobrindo o Outline lateral em z=1.90)
    bochecha_lat = _chaikin([
        (1.42, -0.25), (2.32, 0.08), (1.92, 0.45), (2.38, 0.92), (1.98, 1.48), (1.38, 1.55)
    ], 1)
    s.sym(bochecha_lat, 0.86, 1.06, creme, outline=borda, ow=0.09, smooth=False)

    # Focinho felino contínuo com o rosto + almofadas creme/brancas e nariz terracota na ponta (ajuste Elizeu 09/11/2026: z_cap=1.782..2.012)
    foc = _chaikin([
        (-0.82, 1.22), (-0.68, 1.92), (0.0, 2.30), (0.68, 1.92), (0.82, 1.22), (0.0, 1.05)
    ], 2)
    _extensao_sem_costura(s, foc, corpo, borda, ow=0.09, z_cap=1.782, z_cap_top=2.012)
    s.flat(ellipse(0.0, 1.62, 0.62, 0.40, n=16), TOP + 0.005, 0.015, creme)
    s.sym(ellipse(0.30, 1.70, 0.22, 0.16, n=12), TOP + 0.02, 0.015, branco)
    nar = _chaikin([(-0.30, 1.52), (0.30, 1.52), (0.34, 1.76), (0.0, 2.00), (-0.34, 1.76)], 2)
    s.flat(nar, TOP + 0.035, 0.035, terracota, outline=borda, ow=0.03, smooth=False)

    # Pinturas/listras vermelhas e brancas nas laterais e no topo (longe do centro atrás dos olhos!)
    for y_c, col_l in [(0.88, verm), (0.64, branco), (-0.32, verm), (-0.58, branco), (-0.84, verm)]:
        listra = _chaikin([(1.15, y_c + 0.10), (1.68, y_c - 0.05), (1.68, y_c - 0.22), (1.15, y_c - 0.08)], 1)
        s.sym(listra, TOP + 0.015, 0.02, col_l, smooth=False)

    # Marcação branca e vermelha na frente/testa (entre os olhos) e manchas brancas sobre os olhos
    s.flat(_chaikin([(0.0, 1.28), (0.26, 0.78), (0.0, 0.28), (-0.26, 0.78)], 1),
           TOP + 0.015, 0.018, branco, smooth=False)
    s.flat(_chaikin([(0.0, 1.14), (0.14, 0.78), (0.0, 0.42), (-0.14, 0.78)], 1),
           TOP + 0.033, 0.018, verm, smooth=False)
    s.sym(ellipse(0.75, 1.12, 0.24, 0.12, n=12, rot=-0.25), TOP + 0.015, 0.02, branco)

    # Mão: patinha caramelo com almofada creme, listra vermelha e 3 garras escuras
    s.hand_flat(ellipse(0.0, 0.08, 0.30, 0.20, n=12), 1.83, 0.025, creme)
    s.hand_flat([(-0.28, -0.18), (0.28, -0.18), (0.24, -0.02), (-0.24, -0.02)], 1.84, 0.025, verm, smooth=False)
    for kk in (-1, 0, 1):
        s.hand_flat(_espinho(kk * 0.22, 0.34, math.radians(90 - 18 * kk), 0.44, 0.10),
                    1.28, 0.38, borda, smooth=False)


# ---------------------------------------------------------------- 9. Ciborgue Sombrio
def ciborgue_sombrio(s):
    # Criatura metálica azul-escura com tentáculos/cabos ondulados na silhueta traseira,
    # placa mecânica assimétrica de lado e ponto/fresta de energia vermelha com emit (Neon);
    # mãos escuras com placa e ponto neon.
    corpo, borda, metal_esc, metal_med, rubi_esc, vinho_m, neon, neon_b = (
        "#384058", "#182030", "#283040", "#303850", "#702028", "#502830", "#f80000", "#b00000"
    )
    s.base()

    # Tentáculos/cabos mecânicos ondulados saindo na silhueta traseira e cantos traseiros
    cabos_cfg = [
        ([(-0.55, -1.45), (-0.98, -2.08), (-0.48, -2.65), (-0.88, -3.18)], 0.30),
        ([(0.55, -1.45), (0.98, -2.08), (0.48, -2.65), (0.88, -3.18)], 0.30),
        ([(-1.25, -1.25), (-2.08, -1.68), (-1.88, -2.42), (-2.42, -2.85)], 0.26),
        ([(1.25, -1.25), (2.08, -1.68), (1.88, -2.42), (2.42, -2.85)], 0.26),
    ]
    for pts_c, w0 in cabos_cfg:
        curva_c = _curva(pts_c, per=6)
        pol_c = _tubo(curva_c, lambda t, w=w0: w * (1.0 - 0.52 * t), cap0=True, cap1=True, n=18)
        s.flat(pol_c, 0.84, 1.02, metal_esc, outline=borda, ow=0.09, smooth=False)
        for t_seg in (0.35, 0.65):
            seg_c = _tubo(curva_c, lambda t, w=w0: w * 0.74, t0=t_seg - 0.06, t1=t_seg + 0.06, n=6)
            s.flat(seg_c, 1.87, 0.025, rubi_esc, smooth=False)
        px, py = pts_c[-1]
        s.flat(ellipse(px, py, 0.16, 0.16, n=10), 1.87, 0.03, neon, emit=1.8)

    # Placa mecânica assimétrica grande no lado direito (+X) com ombreira saliente na silhueta
    placa_ombro = _chaikin([
        (1.38, 1.28), (2.32, 1.00), (2.48, -0.15), (2.22, -1.18), (1.35, -1.38)
    ], 1)
    _extensao_sem_costura(s, placa_ombro, metal_esc, borda, ow=0.10)

    placa_topo = _chaikin([
        (0.32, 1.48), (1.58, 1.42), (2.02, 0.82), (2.12, -0.25),
        (1.78, -1.32), (0.62, -1.48), (0.48, -0.25)
    ], 1)
    s.flat(placa_topo, TOP + 0.005, 0.02, metal_esc, smooth=False)
    s.flat(_chaikin([
        (0.48, 1.28), (1.48, 1.22), (1.85, 0.68), (1.92, -0.20),
        (1.60, -1.10), (0.72, -1.25), (0.58, -0.20)
    ], 1), TOP + 0.025, 0.015, metal_med, smooth=False)

    # Fresta/reator de energia vermelha com emit (Neon) na placa mecânica lateral (+X)
    fresta_base = _chaikin([(1.18, 0.35), (1.76, 0.18), (1.78, -0.82), (1.18, -0.96)], 1)
    s.flat(fresta_base, TOP + 0.042, 0.018, vinho_m, outline=borda, ow=0.04, smooth=False)
    s.flat(_chaikin([(1.28, 0.22), (1.64, 0.10), (1.66, -0.72), (1.28, -0.82)], 1),
           TOP + 0.062, 0.018, neon_b, emit=1.0, smooth=False)
    s.flat(_chaikin([(1.36, 0.12), (1.56, 0.02), (1.58, -0.62), (1.36, -0.68)], 1),
           TOP + 0.082, 0.022, neon, emit=1.8, smooth=False)

    # Visor/aro cibernético vermelho-neon ao redor do olho direito (+EYE_X, EYE_Y)
    _anel_quads(s, EYE_X, EYE_Y, 0.48, 0.72, TOP + 0.045, 0.025, rubi_esc, n=16)
    _anel_quads(s, EYE_X, EYE_Y, 0.52, 0.66, TOP + 0.070, 0.022, neon, n=16, emit=1.8)

    # No lado oposto (-X): aleta/conector mecânico menor com ponto de energia neon para equilibrar a silhueta
    conector_esq = _chaikin([(-1.48, 0.48), (-2.22, 0.28), (-2.22, -0.48), (-1.48, -0.68)], 1)
    s.flat(conector_esq, 0.86, 1.06, metal_esc, outline=borda, ow=0.09, smooth=False)
    s.flat(ellipse(-1.85, -0.10, 0.20, 0.28, n=12), 1.93, 0.025, rubi_esc)
    s.flat(ellipse(-1.85, -0.10, 0.12, 0.18, n=10), 1.955, 0.025, neon, emit=1.8)

    # Mão: manopla escura com placa metálica e núcleo circular neon
    s.hand_flat(_chaikin([(-0.36, -0.28), (0.36, -0.28), (0.42, 0.25), (-0.42, 0.25)], 1),
                1.82, 0.03, metal_esc, outline=borda, ow=0.03, smooth=False)
    s.hand_flat(ellipse(0.0, -0.02, 0.24, 0.24, n=12), 1.855, 0.02, rubi_esc)
    s.hand_flat(ellipse(0.0, -0.02, 0.15, 0.15, n=10), 1.875, 0.025, neon, emit=1.8)
    for kk in (-1, 1):
        s.hand_flat([(kk * 0.20, 0.32), (kk * 0.36, 0.72), (kk * 0.08, 0.42)],
                    1.30, 0.36, metal_esc, outline=borda, ow=0.04, smooth=False)


# ---------------------------------------------------------------- 10. Rocha de Magma
def rocha_magma(s):
    # Golem/bloco de rocha vulcânica escura com quinas chanfradas/placas de basalto nas bordas
    # e veios/rachaduras de lava vermelha viva com emit (Neon) no topo e nas mãos de pedra.
    corpo, borda, rocha_m, crosta, lava, lava_b = (
        "#401818", "#201010", "#502020", "#701010", "#f80000", "#b00000"
    )
    s.base()

    # Quinas chanfradas / blocos de basalto angulares saindo nas bordas laterais, traseira e frente
    bloco_tras_c = [(-0.82, -1.52), (-0.55, -2.40), (0.55, -2.40), (0.82, -1.52)]
    s.flat(bloco_tras_c, 0.84, 1.08, rocha_m, outline=borda, ow=0.10, smooth=False)

    bloco_canto_tras = [(0.75, -1.45), (1.72, -2.32), (2.32, -1.52), (1.52, -0.85)]
    s.sym(bloco_canto_tras, 0.85, 1.08, corpo, outline=borda, ow=0.10, smooth=False)
    s.sym([(0.95, -1.52), (1.65, -2.05), (2.05, -1.52), (1.48, -1.05)], 1.94, 0.02, rocha_m, smooth=False)

    bloco_lat = [(1.48, -0.68), (2.42, -0.42), (2.42, 0.58), (1.48, 0.82)]
    s.sym(bloco_lat, 0.86, 1.08, rocha_m, outline=borda, ow=0.10, smooth=False)

    bloco_frente_lat = [(1.12, 1.25), (2.15, 0.92), (2.22, 1.62), (1.40, 2.12), (0.95, 1.62)]
    s.sym(bloco_frente_lat, 0.84, 1.08, corpo, outline=borda, ow=0.10, smooth=False)

    # Ajuste Elizeu 09/11/2026: z_base=0.675, z_cap=1.714..1.944
    queixo_pedra = [(-0.82, 1.38), (-0.55, 2.18), (0.55, 2.18), (0.82, 1.38)]
    _extensao_sem_costura(s, queixo_pedra, rocha_m, borda, ow=0.09, z_base=0.675, z_cap=1.714, z_cap_top=1.944)

    # Aros octogonais de basalto ao redor dos olhos principais (leitura limpa de golem de rocha!)
    for k in (-1, 1):
        _anel_quads(s, k * EYE_X, EYE_Y, 0.48, 0.66, TOP + 0.012, 0.022, rocha_m, n=8, rot_deg=22.5)

    # Veios/rachaduras de lava vermelha viva com emit (Neon) nas costas e nas laterais
    # (deixando a região logo atrás dos olhos y ∈ [-0.55, 0.25] limpa para não virar bigode/boca!)
    veios_lava = [
        # Veio diagonal traseiro-direito (+X) ramificando para a borda traseira
        [(0.42, -0.78), (1.02, -1.25), (1.72, -1.85)],
        [(1.02, -1.25), (1.88, -0.68)],
        # Veio diagonal traseiro-esquerdo (-X) ramificando para a borda traseira
        [(-0.42, -0.78), (-1.02, -1.25), (-1.75, -1.82)],
        [(-1.02, -1.25), (-1.88, -0.62)],
        # Veio central traseiro curto na borda de trás
        [(0.0, -1.15), (0.0, -2.22)],
        # Veio de lava vertical na ponte entre os olhos (y = 0.68..1.48)
        [(0.0, 0.68), (0.0, 1.48)],
        # Veios laterais nas ombreiras de rocha (fora dos olhos, |x| >= 1.32!)
        [(1.35, -0.05), (1.82, 0.32), (1.62, 1.35)],
        [(-1.35, -0.05), (-1.82, 0.32), (-1.62, 1.35)],
    ]
    for pts_v in veios_lava:
        c_v = _curva(pts_v, per=5) if len(pts_v) > 2 else pts_v
        s.flat(_tubo(c_v, lambda t: 0.16, cap0=True, cap1=True, n=10), TOP + 0.005, 0.012, crosta, smooth=False)
        s.flat(_tubo(c_v, lambda t: 0.11, cap0=True, cap1=True, n=10), TOP + 0.017, 0.015, lava_b, emit=1.0, smooth=False)
        s.flat(_tubo(c_v, lambda t: 0.065, cap0=True, cap1=True, n=10), TOP + 0.032, 0.02, lava, emit=1.8, smooth=False)

    # Placas chanfradas de basalto (#502020) em relevo no topo entre os veios de lava
    placas_topo = [
        [(-0.85, -0.82), (-0.22, -0.95), (-0.22, -1.68), (-0.82, -1.48)],
        [(0.22, -0.95), (0.85, -0.82), (0.82, -1.48), (0.22, -1.68)],
        [(-1.62, -0.35), (-1.12, -0.25), (-1.15, -0.95), (-1.68, -1.05)],
        [(1.12, -0.25), (1.62, -0.35), (1.68, -1.05), (1.15, -0.95)],
    ]
    for pl in placas_topo:
        s.flat(_chaikin(pl, 1), TOP + 0.01, 0.022, rocha_m, smooth=False)

    # Mão: punho de rocha chanfrada com rachadura de lava neon em Y
    placa_mao = [(-0.42, -0.25), (0.0, -0.45), (0.42, -0.25), (0.48, 0.32), (0.0, 0.52), (-0.48, 0.32)]
    s.hand_flat(placa_mao, 1.35, 0.48, rocha_m, outline=borda, ow=0.05, smooth=False)
    for pts_mv in [[(-0.25, -0.18), (0.0, 0.05), (0.25, 0.28)], [(0.0, 0.05), (-0.22, 0.28)]]:
        s.hand_flat(_tubo(pts_mv, lambda t: 0.09, cap0=True, cap1=True, n=6), 1.835, 0.015, lava_b, emit=1.0, smooth=False)
        s.hand_flat(_tubo(pts_mv, lambda t: 0.055, cap0=True, cap1=True, n=6), 1.850, 0.02, lava, emit=1.8, smooth=False)


LOTE = [
    ("kitsune", kitsune, "#f8f8f8", "#c00000", "#f8f8f8", "#c00000"),
    ("ostra", ostra, "#F6EFEA", "#B89888", "#F6EFEA", "#B89888"),
    ("lince_roxo", lince_roxo, "#b068d8", "#201820", "#b068d8", "#201820"),
    ("urso_polar", urso_polar, "#F0EDE0", "#D8B49D", "#F0EDE0", "#D8B49D"),
    ("espectro", espectro, "#201820", "#B6222A", "#201820", "#B6222A"),
    ("monstro_cristal", monstro_cristal, "#8838c8", "#302068", "#8838c8", "#302068"),
    ("goblin", goblin, "#18b070", "#201820", "#18b070", "#201820"),
    ("caracal", caracal, "#c89860", "#282828", "#c89860", "#282828"),
    ("ciborgue_sombrio", ciborgue_sombrio, "#384058", "#182030", "#384058", "#182030"),
    ("rocha_magma", rocha_magma, "#401818", "#201010", "#401818", "#201010"),
]
