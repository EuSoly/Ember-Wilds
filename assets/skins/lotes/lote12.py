# Lote 12 — skins de corpo (detalhadas). Montar com build_skins.py (Blender aberto) ou render_lote.py (segundo plano).
# cardeal, coiote, raposa_artica, gato_gelo, toco_gelo, toco_vulcanico, diabrete_gelo, bolha_verde, gelo_rachado, lobisomem.
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


# ---------------------------------------------------------------- 1. Cardeal
def cardeal(s):
    # Pássaro vermelho-cardeal com topete de 3 penas arrepiadas na silhueta traseira,
    # asinhas avermelhadas abertas nas laterais, máscara/detalhe escuro discreto ao redor dos olhos
    # e bico cônico laranja-dourado na frente; mãos vermelhas com penas.
    corpo, borda, pena_esc, pena_med, bico_base, bico_cl, escuro = (
        "#D84444", "#AC2824", "#D42C24", "#D83C38", "#D89C58", "#DCAC74", "#201C20"
    )
    s.base()

    # Topete icônico de 3 penas arrepiadas na silhueta traseira (central longa + par lateral em leque)
    topete_tras = _chaikin([
        (-1.25, -1.35), (-1.68, -2.55), (-0.82, -2.18),
        (-0.55, -2.95), (0.0, -3.28), (0.55, -2.95),
        (0.82, -2.18), (1.68, -2.55), (1.25, -1.35), (0.0, -1.20)
    ], 1)
    _extensao_sem_costura(s, topete_tras, pena_esc, borda, ow=0.10, z_cap=1.78, z_cap_top=2.01)

    # Camada superior de penas do topete sobre o topo traseiro (sem contorno para leitura limpa)
    pena_c_topo = _chaikin([
        (-0.42, -1.15), (-0.48, -2.65), (0.0, -3.12), (0.48, -2.65), (0.42, -1.15), (0.0, -0.92)
    ], 1)
    s.flat(pena_c_topo, TOP + 0.012, 0.022, pena_med, smooth=False)
    pena_lat_topo = _chaikin([
        (0.38, -1.25), (0.85, -1.95), (1.52, -2.42), (1.12, -1.42), (0.52, -1.08)
    ], 1)
    s.sym(pena_lat_topo, TOP + 0.010, 0.020, pena_esc, smooth=False)

    # Asinhas avermelhadas abertas nas duas laterais com 3 pontas de penas primárias
    asa = _chaikin([
        (1.48, 0.95), (2.42, 0.65), (3.12, -0.05), (2.45, -0.28),
        (2.98, -0.82), (2.28, -0.92), (2.62, -1.48), (1.78, -1.42), (1.45, -0.85)
    ], 1)
    s.sym(asa, 0.86, 1.04, pena_esc, outline=borda, ow=0.10, smooth=False)
    # Penas de cobertura nas asas (#D83C38)
    s.sym(_chaikin([(1.62, 0.72), (2.28, 0.48), (2.78, -0.02), (2.05, -0.15), (1.60, 0.15)], 1),
          1.91, 0.022, pena_med, smooth=False)
    s.sym(_chaikin([(1.62, 0.02), (2.22, -0.22), (2.68, -0.75), (1.98, -0.78), (1.58, -0.45)], 1),
          1.91, 0.022, pena_med, smooth=False)

    # Penas peitorais fofas nas bochechas/laterais do topo
    s.sym(_chaikin([(1.20, 1.32), (1.68, 1.02), (1.68, -0.95), (1.18, -1.28), (1.32, 0.05)], 2),
          TOP, 0.012, pena_med, smooth=False)

    # Máscara escura discreta de cardeal (#201C20) ao redor de cada olho e na base frontal do bico
    # (NÃO junta atrás dos olhos para não virar bigode na vista de 90°, e fica sob a tampa do bico!)
    for k in (-1, 1):
        _anel_quads(s, k * EYE_X, EYE_Y, 0.47, 0.64, TOP + 0.015, 0.022, escuro, n=16)
    s.sym(_chaikin([(1.18, 0.68), (1.62, 0.88), (1.52, 0.42), (1.18, 0.40)], 1),
          TOP + 0.015, 0.022, escuro, smooth=False)
    mascara_frente = _chaikin([
        (-0.82, 1.12), (-0.92, 1.52), (0.0, 1.62), (0.92, 1.52), (0.82, 1.12), (0.0, 0.92)
    ], 2)
    s.flat(mascara_frente, TOP + 0.003, 0.008, escuro, smooth=False)

    # Bico cônico robusto laranja-dourado na frente (#D89C58 base + #DCAC74 cume superior)
    bico = _chaikin([
        (-0.78, 1.45), (-0.58, 2.15), (0.0, 2.68), (0.58, 2.15), (0.78, 1.45), (0.0, 1.22)
    ], 2)
    _extensao_sem_costura(s, bico, bico_base, borda, ow=0.09, z_cap=1.78, z_cap_top=2.016)
    cume_bico = _chaikin([
        (-0.42, 1.52), (-0.28, 2.12), (0.0, 2.56), (0.28, 2.12), (0.42, 1.52), (0.0, 1.35)
    ], 1)
    s.flat(cume_bico, TOP + 0.020, 0.025, bico_cl, smooth=False)
    s.sym(ellipse(0.24, 1.85, 0.08, 0.05, n=8, rot=-0.35), TOP + 0.048, 0.015, borda)

    # Mão: mão vermelha com 3 peninhas em leque na ponta
    s.hand_flat(ellipse(0.0, -0.05, 0.30, 0.22, n=12), 1.83, 0.025, pena_med)
    for kk in (-1, 0, 1):
        s.hand_flat(_espinho(kk * 0.22, 0.28, math.radians(90 - 20 * kk), 0.52, 0.14),
                    1.28, 0.40, pena_esc, outline=borda, ow=0.04, smooth=False)


# ---------------------------------------------------------------- 2. Coiote
def coiote(s):
    # Canídeo selvagem da estepe em tons de pardo-areia e marrom, orelhas grandes pontudas inclinadas
    # para os lados/trás com interior claro #AC845C, tufos felpudos duplos nas bochechas,
    # focinho saliente com ponte escura #644434 e nariz #382424, e cauda felpuda atrás; mãos com 3 garras escuras.
    corpo, borda, marrom_esc, areia_cl, pardo_med, nariz = (
        "#8C6850", "#4C3830", "#644434", "#AC845C", "#705040", "#382424"
    )
    s.base()

    # Cauda felpuda de coiote saindo na silhueta traseira com ponta escura em V
    cauda = _chaikin([
        (-0.62, -1.45), (-0.82, -2.35), (0.0, -3.22), (0.82, -2.35), (0.62, -1.45)
    ], 2)
    s.flat(cauda, 0.84, 1.06, corpo, outline=borda, ow=0.09, smooth=False)
    ponta_cauda = _chaikin([
        (-0.52, -2.22), (-0.55, -2.52), (0.0, -3.12), (0.55, -2.52), (0.52, -2.22), (0.0, -2.42)
    ], 1)
    s.flat(ponta_cauda, 1.91, 0.025, marrom_esc, smooth=False)

    # Orelhas grandes pontudas inclinadas para os lados/trás com interior claro #AC845C
    orelha = _chaikin([
        (0.68, -0.78), (1.75, -0.55), (2.78, -1.32), (2.98, -2.62),
        (2.12, -2.68), (1.15, -1.92), (0.55, -1.42)
    ], 2)
    s.sym(orelha, 0.88, 1.04, corpo, outline=borda, ow=0.10, smooth=False)
    sombra_or = _chaikin([
        (0.95, -0.92), (1.82, -0.75), (2.62, -1.42), (2.75, -2.42), (1.98, -2.35), (1.08, -1.62)
    ], 2)
    s.sym(sombra_or, 1.93, 0.015, pardo_med, smooth=False)
    miolo_or = _chaikin([
        (1.22, -1.12), (2.05, -1.15), (2.52, -2.18), (1.85, -2.12), (1.22, -1.55)
    ], 2)
    s.sym(miolo_or, 1.95, 0.02, areia_cl, smooth=False)

    # Tufos felpudos duplos nas bochechas com pontas claras (#AC845C)
    tufo_lat = [
        (1.45, -0.35), (2.42, -0.02), (1.92, 0.38),
        (2.48, 0.85), (1.95, 1.22), (2.12, 1.55), (1.40, 1.52)
    ]
    s.sym(tufo_lat, 0.86, 1.06, corpo, outline=borda, ow=0.09, smooth=False)
    s.sym([(1.78, -0.10), (2.32, 0.00), (1.88, 0.25)], 1.93, 0.02, areia_cl, smooth=False)
    s.sym([(1.82, 0.58), (2.38, 0.84), (1.90, 1.02)], 1.93, 0.02, areia_cl, smooth=False)

    # Focinho saliente na frente (#AC845C nas laterais + ponte escura #644434 + nariz #382424)
    foc = _chaikin([
        (-0.86, 1.22), (-0.74, 1.98), (0.0, 2.45), (0.74, 1.98), (0.86, 1.22), (0.0, 1.02)
    ], 2)
    _extensao_sem_costura(s, foc, areia_cl, borda, ow=0.09, z_cap=1.78, z_cap_top=2.01)

    # Ponte nasal escura (#644434) entre os olhos indo até o nariz (y >= 0.42, sem invadir atrás dos olhos!)
    ponte_foc = _chaikin([
        (-0.38, 0.45), (-0.42, 1.58), (0.0, 1.88), (0.42, 1.58), (0.38, 0.45), (0.0, 0.35)
    ], 2)
    s.flat(ponte_foc, TOP + 0.012, 0.018, marrom_esc, smooth=False)
    nar = _chaikin([(-0.32, 1.68), (0.32, 1.68), (0.36, 1.95), (0.0, 2.22), (-0.36, 1.95)], 2)
    s.flat(nar, TOP + 0.030, 0.035, nariz, smooth=False)

    # Manchas de sobrancelha claras (#AC845C) acima dos olhos (na vista 65°, y = 0.15..0.32, separadas!)
    # e manto dorsal pardo-médio (#705040) nas laterais (deixando o centro traseiro limpo!)
    s.sym(ellipse(0.78, 0.22, 0.24, 0.12, n=12, rot=0.20), TOP + 0.015, 0.018, areia_cl)
    s.sym(_chaikin([(1.15, 1.15), (1.65, 0.88), (1.68, -1.18), (1.08, -1.55), (1.25, -0.20)], 2),
          TOP, 0.012, pardo_med, smooth=False)

    # Mão: patinha com almofada #705040 e 3 garras escuras #382424
    s.hand_flat(ellipse(0.0, -0.04, 0.30, 0.22, n=12), 1.83, 0.025, pardo_med)
    for kk in (-1, 0, 1):
        s.hand_flat(_espinho(kk * 0.22, 0.34, math.radians(90 - 18 * kk), 0.44, 0.10),
                    1.28, 0.38, nariz, outline=borda, ow=0.04, smooth=False)


# ---------------------------------------------------------------- 3. Raposa Ártica
def raposa_artica(s):
    # Raposa branca da neve (fiel à estética limpa da ref 162: corpo branco-marfim #F0ECE0 com contorno
    # bege-areia suave #D8B49C), orelhas compridas pontudas de raposa nos cantos traseiros com interior
    # rosa-pêssego recortado (#E0A898), tufos de pelo afiados nas bochechas, focinho pontudo creme-claro (#ECE4D4)
    # com nariz escuro (#382424) e cauda branca felpuda atrás; mãos com garras escuras.
    corpo, borda, miolo_or_c, foc_c, sombra_f, nariz = (
        "#F0ECE0", "#D8B49C", "#E0A898", "#ECE4D4", "#DCBCA8", "#382424"
    )
    s.base()

    # Cauda branca felpuda atrás com ponta macia e sombreado creme-claro
    cauda = _chaikin([
        (-0.62, -1.45), (-0.82, -2.38), (0.0, -3.18), (0.82, -2.38), (0.62, -1.45)
    ], 2)
    s.flat(cauda, 0.84, 1.06, corpo, outline=borda, ow=0.09, smooth=False)
    s.flat(_chaikin([(-0.48, -1.65), (-0.58, -2.32), (0.0, -2.92), (0.58, -2.32), (0.48, -1.65)], 2),
           1.91, 0.02, foc_c, smooth=False)

    # Orelhas compridas pontudas de raposa nos cantos traseiros com interior rosa-pêssego recortado (#E0A898)
    for k in (-1, 1):
        X = lambda P: [(k * x, y) for x, y in P]
        orelha = _chaikin([
            (0.68, -0.82), (1.72, -0.60), (2.68, -1.28), (2.92, -2.55),
            (2.08, -2.62), (1.15, -1.92), (0.58, -1.42)
        ], 2)
        s.flat(X(orelha), 0.88, 1.04, corpo, outline=borda, ow=0.10, smooth=False)
        miolo_or = _chaikin([
            (1.18, -1.08), (1.98, -1.05), (2.58, -1.68), (2.52, -2.28),
            (2.12, -1.95), (1.92, -2.18), (1.68, -1.82), (1.22, -1.62)
        ], 1)
        s.flat(X(miolo_or), 1.93, 0.025, miolo_or_c, smooth=False)

    # Tufos de pelo duplos afiados nas bochechas (silhueta clássica de raposa)
    tufo_lat = _chaikin([
        (1.45, -0.35), (2.32, 0.02), (1.88, 0.42),
        (2.38, 0.88), (1.88, 1.25), (2.02, 1.55), (1.42, 1.52)
    ], 1)
    s.sym(tufo_lat, 0.88, 1.02, corpo, outline=borda, ow=0.09, smooth=False)

    # Focinho pontudo creme-claro (#ECE4D4) contínuo com o rosto + sombreado #DCBCA8 + nariz escuro #382424
    foc = _chaikin([
        (-0.80, 1.18), (-0.68, 1.95), (0.0, 2.40), (0.68, 1.95), (0.80, 1.18), (0.0, 0.98)
    ], 2)
    _extensao_sem_costura(s, foc, foc_c, borda, ow=0.08, z_cap=1.78, z_cap_top=2.01)
    s.sym(ellipse(0.42, 1.55, 0.20, 0.30, n=12, rot=-0.20), TOP + 0.012, 0.015, sombra_f)
    nar = _chaikin([(-0.28, 1.62), (0.28, 1.62), (0.32, 1.88), (0.0, 2.12), (-0.32, 1.88)], 2)
    s.flat(nar, TOP + 0.025, 0.038, nariz, smooth=False)

    # Mão: patinha branca-marfim com 3 garras escuras (#382424)
    for kk in (-1, 0, 1):
        s.hand_flat(ellipse(kk * 0.22, 0.36, 0.10, 0.13, n=8), 1.40, 0.35, nariz)


# ---------------------------------------------------------------- 4. Gato de Gelo
def gato_gelo(s):
    # Felino elemental de gelo com corpo azul-gelo clarinho (#DCF0F4) e contorno azul-oceano (#1868A0),
    # orelhas felinas pontudas com interior azul-profundo (#244074) e cristais claros,
    # tufos de cristal/pelo glacial (#B4DCEC / #84B0CC) nas bochechas, losango de gelo na testa
    # e cauda de cristal atrás; mãos com garras azuis.
    corpo, borda, gelo_cl, azul_prof, gelo_med, azul_med, branco = (
        "#DCF0F4", "#1868A0", "#B4DCEC", "#244074", "#70A0C0", "#508CB8", "#FCFCFC"
    )
    s.base()

    # Cauda felina de cristal glacial atrás (prisma pontiagudo em segmentos de gelo)
    cauda = _chaikin([
        (-0.48, -1.45), (-0.65, -2.25), (0.0, -3.22), (0.65, -2.25), (0.48, -1.45)
    ], 1)
    s.flat(cauda, 0.85, 1.06, gelo_cl, outline=borda, ow=0.09, smooth=False)
    s.flat([(0.0, -1.65), (0.42, -2.25), (0.0, -3.02), (-0.42, -2.25)], 1.92, 0.02, azul_med, smooth=False)
    s.flat([(0.0, -1.95), (0.22, -2.35), (0.0, -2.85), (-0.22, -2.35)], 1.94, 0.02, branco, smooth=False)

    # Orelhas felinas pontudas com interior azul-profundo (#244074) e cristais claros (#FCFCFC)
    orelha = _chaikin([
        (0.65, -0.78), (1.72, -0.55), (2.62, -1.25), (2.78, -2.42),
        (1.92, -2.48), (1.08, -1.82), (0.55, -1.35)
    ], 1)
    s.sym(orelha, 0.88, 1.04, corpo, outline=borda, ow=0.10, smooth=False)
    s.sym(_chaikin([(0.92, -0.92), (1.78, -0.72), (2.52, -1.35), (2.58, -2.22), (1.82, -2.18), (1.02, -1.52)], 1),
          1.93, 0.015, gelo_cl, smooth=False)
    miolo_or = _chaikin([
        (1.20, -1.10), (1.98, -1.08), (2.40, -1.98), (1.75, -1.95), (1.20, -1.48)
    ], 1)
    s.sym(miolo_or, 1.95, 0.02, azul_prof, smooth=False)
    # Pontas de cristal branco saindo do ápice das orelhas
    cristal_or = [(2.18, -2.05), (2.68, -2.02), (3.08, -2.82), (2.35, -2.58)]
    s.sym(cristal_or, 0.90, 1.06, branco, outline=borda, ow=0.08, smooth=False)

    # Tufos de cristal/pelo glacial facetados nas bochechas (#B4DCEC / #70A0C0)
    tufo_gelo = [
        (1.42, -0.38), (2.52, -0.08), (1.98, 0.30),
        (2.65, 0.72), (2.02, 1.08), (2.32, 1.50), (1.40, 1.52)
    ]
    s.sym(tufo_gelo, 0.86, 1.06, gelo_cl, outline=borda, ow=0.09, smooth=False)
    s.sym([(1.72, -0.18), (2.38, -0.05), (1.88, 0.22)], 1.93, 0.02, gelo_med, smooth=False)
    s.sym([(1.78, 0.45), (2.50, 0.72), (1.92, 0.95)], 1.93, 0.02, branco, smooth=False)
    s.sym([(1.72, 1.10), (2.22, 1.44), (1.65, 1.40)], 1.93, 0.02, gelo_med, smooth=False)

    # Focinho felino glacial contínuo com o rosto + almofadas brancas e nariz #244074
    foc = _chaikin([
        (-0.82, 1.22), (-0.68, 1.92), (0.0, 2.28), (0.68, 1.92), (0.82, 1.22), (0.0, 1.05)
    ], 2)
    _extensao_sem_costura(s, foc, corpo, borda, ow=0.09, z_cap=1.78, z_cap_top=2.01)
    s.flat(ellipse(0.0, 1.62, 0.60, 0.38, n=16), TOP + 0.006, 0.014, gelo_cl)
    s.sym(ellipse(0.28, 1.68, 0.22, 0.16, n=12), TOP + 0.020, 0.015, branco)
    nar = _chaikin([(-0.28, 1.52), (0.28, 1.52), (0.32, 1.75), (0.0, 1.98), (-0.32, 1.75)], 2)
    s.flat(nar, TOP + 0.035, 0.035, azul_prof, smooth=False)

    # Losango facetado de gelo na testa (entre os olhos, y = 0.22..1.18) + listras glaciais laterais
    s.flat([(0.0, 1.22), (0.34, 0.70), (0.0, 0.18), (-0.34, 0.70)], TOP + 0.015, 0.020, azul_med, smooth=False)
    s.flat([(0.0, 1.06), (0.20, 0.70), (0.0, 0.34), (-0.20, 0.70)], TOP + 0.035, 0.018, gelo_cl, smooth=False)
    s.flat([(0.0, 0.90), (0.10, 0.70), (0.0, 0.50), (-0.10, 0.70)], TOP + 0.053, 0.015, branco, smooth=False)

    for y_c, col_l in [(-0.25, gelo_med), (-0.65, azul_med), (-1.05, gelo_med)]:
        s.sym([(1.15, y_c + 0.12), (1.68, y_c - 0.04), (1.65, y_c - 0.22), (1.15, y_c - 0.06)],
              TOP + 0.012, 0.018, col_l, smooth=False)

    # Mão: patinha azul-gelo com cristal losangular e 3 garras azuis (#244074)
    s.hand_flat([(0.0, 0.22), (0.24, -0.02), (0.0, -0.26), (-0.24, -0.02)], 1.83, 0.025, azul_med, smooth=False)
    for kk in (-1, 0, 1):
        s.hand_flat(_espinho(kk * 0.22, 0.34, math.radians(90 - 18 * kk), 0.45, 0.11),
                    1.28, 0.38, azul_prof, outline=borda, ow=0.04, smooth=False)


# ---------------------------------------------------------------- 5. Toco de Gelo
def toco_gelo(s):
    # Ent / guardião de tronco congelado: corpo de madeira clara acinzentada (#CCB89C, contorno #806054),
    # grandes galhos/chifres brancos nevados (#DCD4B8) com folhas/cristais azul-petróleo (#087C80 / #045860)
    # saindo dos cantos traseiros, placas de casca nas laterais e joia losangular turquesa (#087C80 com miolo #045860)
    # na testa; mãos de madeira com cristal turquesa.
    corpo, borda, casca_cl, casca_esc, galho_c, turq_cl, turq_esc = (
        "#CCB89C", "#806054", "#B09480", "#9C8070", "#DCD4B8", "#087C80", "#045860"
    )
    s.base()

    # Grandes galhos/chifres brancos nevados (#DCD4B8) ramificados saindo dos cantos traseiros
    for k in (-1, 1):
        X = lambda P: [(k * x, y) for x, y in P]
        galho_p = _curva([(0.95, -1.15), (1.88, -1.45), (2.68, -2.18), (3.08, -3.05)], per=5)
        pol_gp = _tubo(galho_p, lambda t: 0.34 * (1.0 - 0.50 * t), cap0=True, cap1=True, n=16)
        s.flat(X(pol_gp), 0.88, 1.06, galho_c, outline=borda, ow=0.09, smooth=False)

        galho_r1 = _curva([(1.95, -1.55), (2.75, -1.35), (3.22, -1.68)], per=4)
        pol_r1 = _tubo(galho_r1, lambda t: 0.22 * (1.0 - 0.45 * t), cap0=True, cap1=True, n=10)
        s.flat(X(pol_r1), 0.88, 1.04, galho_c, outline=borda, ow=0.08, smooth=False)

        galho_r2 = _curva([(2.15, -1.85), (1.72, -2.58), (1.62, -3.18)], per=4)
        pol_r2 = _tubo(galho_r2, lambda t: 0.22 * (1.0 - 0.45 * t), cap0=True, cap1=True, n=10)
        s.flat(X(pol_r2), 0.88, 1.04, galho_c, outline=borda, ow=0.08, smooth=False)

        # Folhas/cristais azul-petróleo (#087C80 com miolo #045860) nas pontas dos galhos
        for cx, cy, ang_f, sc_f in [
            (3.08, -2.98, -125, 1.0),
            (3.18, -1.65, -25, 0.85),
            (1.62, -3.12, -100, 0.88),
        ]:
            P = _local(cx, cy, math.radians(ang_f))
            folha = [P(-0.35 * sc_f, 0.0), P(0.0, -0.28 * sc_f), P(0.55 * sc_f, 0.0), P(0.0, 0.28 * sc_f)]
            miolo = [P(-0.18 * sc_f, 0.0), P(0.0, -0.14 * sc_f), P(0.35 * sc_f, 0.0), P(0.0, 0.14 * sc_f)]
            s.flat(X(folha), 0.92, 1.06, turq_cl, outline=borda, ow=0.07, smooth=False)
            s.flat(X(miolo), 2.00, 0.025, turq_esc, smooth=False)

    # Placas de casca / raízes salientes nas laterais e na borda traseira
    placa_lat1 = _chaikin([(1.48, 0.98), (2.28, 0.72), (2.32, 0.02), (1.92, -0.18), (2.25, -0.68), (1.48, -0.95)], 1)
    s.sym(placa_lat1, 0.85, 1.04, casca_cl, outline=borda, ow=0.09, smooth=False)
    s.sym(_chaikin([(1.65, 0.72), (2.08, 0.55), (2.10, 0.08), (1.65, -0.05)], 1),
          1.90, 0.02, casca_esc, smooth=False)

    placa_tras = _chaikin([(-0.95, -1.45), (-0.68, -2.28), (0.0, -2.05), (0.68, -2.28), (0.95, -1.45)], 1)
    s.flat(placa_tras, 0.84, 1.06, casca_cl, outline=borda, ow=0.09, smooth=False)

    # Textura de casca de árvore nas laterais do topo e aros de madeira nos olhos
    s.sym(_chaikin([(1.18, 1.38), (1.68, 1.12), (1.70, -1.15), (1.18, -1.48), (1.32, 0.0)], 1),
          TOP, 0.015, casca_cl, smooth=False)
    s.sym(_chaikin([(1.32, 0.92), (1.60, 0.75), (1.60, -0.82), (1.32, -1.05)], 1),
          TOP + 0.016, 0.015, casca_esc, smooth=False)
    for k in (-1, 1):
        _anel_quads(s, k * EYE_X, EYE_Y, 0.47, 0.63, TOP + 0.012, 0.018, casca_esc, n=12)

    # Joia losangular turquesa (#087C80 com miolo #045860 e moldura #9C8070) na testa
    s.flat([(0.0, 1.38), (0.42, 0.82), (0.0, 0.25), (-0.42, 0.82)], TOP + 0.012, 0.018, casca_esc, smooth=False)
    s.flat([(0.0, 1.26), (0.32, 0.82), (0.0, 0.38), (-0.32, 0.82)], TOP + 0.030, 0.022, turq_cl, smooth=False)
    s.flat([(0.0, 1.08), (0.18, 0.82), (0.0, 0.56), (-0.18, 0.82)], TOP + 0.052, 0.020, turq_esc, smooth=False)

    # Veios de madeira nos cantos traseiros/laterais (deixando o centro atrás dos olhos limpo!)
    for x0, y0, x1, y1 in [(0.92, -0.85, 1.18, -1.62), (1.42, -0.25, 1.52, -1.18)]:
        s.sym(_tubo([(x0, y0), (x1, y1)], lambda t: 0.08, cap0=True, cap1=True, n=6),
              TOP + 0.015, 0.015, casca_esc, smooth=False)

    # Mão: punho de madeira com placa de casca e cristal turquesa na ponta
    s.hand_flat(_chaikin([(-0.38, -0.25), (0.38, -0.25), (0.42, 0.28), (-0.42, 0.28)], 1),
                1.82, 0.025, casca_cl, smooth=False)
    s.hand_flat([(0.0, 0.72), (0.28, 0.25), (0.0, -0.08), (-0.28, 0.25)],
                1.30, 0.42, turq_cl, outline=borda, ow=0.04, smooth=False)
    s.hand_flat([(0.0, 0.58), (0.15, 0.25), (0.0, 0.05), (-0.15, 0.25)],
                1.73, 0.03, turq_esc, smooth=False)


# ---------------------------------------------------------------- 6. Toco Vulcânico
def toco_vulcanico(s):
    # Ent / guardião de tronco carbonizado vulcânico: corpo de madeira queimada escura (#2C2024, contorno #503C3C),
    # galhos secos retorcidos escuros com pontas/folhas em brasa (#80381C / #985020) saindo atrás,
    # raízes laterais e crista triangular em brasa na testa (#80381C com miolo #985020, emit=0.8);
    # mãos de carvão com brasa.
    corpo, borda, mad_esc, mad_cl, brasa_esc, brasa_med, brasa_viva = (
        "#2C2024", "#503C3C", "#403430", "#685048", "#54241C", "#80381C", "#985020"
    )
    s.base()

    # Galhos secos retorcidos escuros saindo dos cantos traseiros com pontas/folhas em brasa
    for k in (-1, 1):
        X = lambda P: [(k * x, y) for x, y in P]
        galho_p = _curva([(0.92, -1.15), (1.92, -1.42), (2.72, -2.18), (3.12, -3.08)], per=5)
        pol_gp = _tubo(galho_p, lambda t: 0.34 * (1.0 - 0.52 * t), cap0=True, cap1=True, n=16)
        s.flat(X(pol_gp), 0.88, 1.06, mad_esc, outline=borda, ow=0.09, smooth=False)

        galho_r1 = _curva([(1.92, -1.52), (2.78, -1.32), (3.25, -1.65)], per=4)
        pol_r1 = _tubo(galho_r1, lambda t: 0.22 * (1.0 - 0.48 * t), cap0=True, cap1=True, n=10)
        s.flat(X(pol_r1), 0.88, 1.04, mad_esc, outline=borda, ow=0.08, smooth=False)

        galho_r2 = _curva([(2.15, -1.85), (1.72, -2.58), (1.58, -3.18)], per=4)
        pol_r2 = _tubo(galho_r2, lambda t: 0.22 * (1.0 - 0.48 * t), cap0=True, cap1=True, n=10)
        s.flat(X(pol_r2), 0.88, 1.04, mad_esc, outline=borda, ow=0.08, smooth=False)

        # Pontas/folhas em brasa (#80381C com miolo #985020, emit=0.8) nos galhos
        for cx, cy, ang_f, sc_f in [
            (3.10, -3.00, -125, 1.0),
            (3.20, -1.62, -25, 0.85),
            (1.60, -3.12, -100, 0.88),
        ]:
            P = _local(cx, cy, math.radians(ang_f))
            folha = [P(-0.35 * sc_f, 0.0), P(0.0, -0.28 * sc_f), P(0.56 * sc_f, 0.0), P(0.0, 0.28 * sc_f)]
            miolo = [P(-0.16 * sc_f, 0.0), P(0.0, -0.14 * sc_f), P(0.36 * sc_f, 0.0), P(0.0, 0.14 * sc_f)]
            s.flat(X(folha), 0.92, 1.06, brasa_med, outline=borda, ow=0.07, smooth=False, emit=0.4)
            s.flat(X(miolo), 2.00, 0.025, brasa_viva, smooth=False, emit=0.8)

    # Raízes/placas laterais de madeira carbonizada com frestas em brasa
    raiz_lat = [
        (1.48, 1.08), (2.38, 0.78), (1.92, 0.35),
        (2.45, -0.18), (1.88, -0.52), (2.32, -1.02), (1.48, -1.18)
    ]
    s.sym(raiz_lat, 0.85, 1.04, mad_esc, outline=borda, ow=0.09, smooth=False)
    s.sym([(1.68, 0.85), (2.22, 0.72), (1.82, 0.38)], 1.90, 0.02, mad_cl, smooth=False)
    s.sym([(1.68, 0.05), (2.28, -0.16), (1.78, -0.42)], 1.90, 0.02, brasa_med, smooth=False, emit=0.5)

    # Placa traseira de casca carbonizada (apenas na silhueta traseira, deixando o topo traseiro limpo!)
    raiz_tras = _chaikin([(-0.92, -1.45), (-0.65, -2.30), (0.0, -2.02), (0.65, -2.30), (0.92, -1.45)], 1)
    s.flat(raiz_tras, 0.84, 1.06, mad_esc, outline=borda, ow=0.09, smooth=False)

    # Aros de madeira clara (#685048) ao redor dos olhos para destacar os olhos no corpo escuro (#2C2024)
    for k in (-1, 1):
        _anel_quads(s, k * EYE_X, EYE_Y, 0.47, 0.63, TOP + 0.012, 0.018, mad_cl, n=12)

    # Crista triangular em brasa na testa (#80381C com miolo #985020, emit=0.8)
    s.flat([(-0.46, 1.38), (0.46, 1.38), (0.0, 0.25)], TOP + 0.012, 0.018, brasa_esc, smooth=False)
    s.flat([(-0.36, 1.30), (0.36, 1.30), (0.0, 0.38)], TOP + 0.030, 0.022, brasa_med, smooth=False, emit=0.5)
    s.flat([(-0.20, 1.20), (0.20, 1.20), (0.0, 0.56)], TOP + 0.052, 0.022, brasa_viva, smooth=False, emit=0.8)

    # Placas de carvão nas laterais do topo e fendas de brasa nos cantos traseiros (centro atrás dos olhos limpo!)
    s.sym(_chaikin([(1.18, 1.35), (1.68, 1.08), (1.68, -1.15), (1.18, -1.45), (1.32, 0.0)], 1),
          TOP, 0.014, mad_esc, smooth=False)
    for pts_v in [
        [(-0.85, -0.88), (-1.28, -1.62)],
        [(0.85, -0.88), (1.28, -1.62)],
        [(-1.42, -0.15), (-1.55, -0.95)],
        [(1.42, -0.15), (1.55, -0.95)],
    ]:
        s.flat(_tubo(pts_v, lambda t: 0.11, cap0=True, cap1=True, n=6),
               TOP + 0.014, 0.015, brasa_med, smooth=False, emit=0.5)
        s.flat(_tubo(pts_v, lambda t: 0.06, cap0=True, cap1=True, n=6),
               TOP + 0.030, 0.018, brasa_viva, smooth=False, emit=0.8)

    # Mão: mão de carvão com placa de madeira queimada e garras/crista em brasa (emit=0.8)
    s.hand_flat(_chaikin([(-0.38, -0.25), (0.38, -0.25), (0.42, 0.28), (-0.42, 0.28)], 1),
                1.82, 0.025, mad_esc, smooth=False)
    s.hand_flat([(-0.28, 0.22), (0.0, 0.72), (0.28, 0.22), (0.0, -0.10)],
                1.30, 0.42, brasa_med, outline=borda, ow=0.04, smooth=False, emit=0.5)
    s.hand_flat([(-0.15, 0.22), (0.0, 0.56), (0.15, 0.22), (0.0, 0.04)],
                1.73, 0.03, brasa_viva, smooth=False, emit=0.8)


# ---------------------------------------------------------------- 7. Diabrete de Gelo
def diabrete_gelo(s):
    # Criatura travessa de gelo azul-turquesa (#80C8C8, contorno #64A0A0), dois chifres brancos curvos (#FCFCFC)
    # nos cantos superiores, pequenas aletas/orelhas laterais pontudas (#B0DCDC),
    # duas presinhas brancas curtas na frente e escamas suaves no topo; mãos turquesa com garras brancas.
    corpo, borda, branco, turq_cl, escuro, turq_esc = (
        "#80C8C8", "#64A0A0", "#FCFCFC", "#B0DCDC", "#244044", "#58A4A4"
    )
    s.base()

    # Dois chifres brancos curvos (#FCFCFC) nos cantos superiores/traseiros apontando para trás
    for k in (-1, 1):
        X = lambda P: [(k * x, y) for x, y in P]
        chifre = (
            _curva([(0.78, -0.95), (1.78, -0.88), (2.42, -1.62), (2.12, -2.75), (1.42, -3.18)], per=5)
            + _curva([(1.42, -3.18), (1.52, -2.25), (1.12, -1.58), (0.65, -1.45)], per=5)[1:]
        )
        s.flat(X(chifre), 0.90, 1.08, branco, outline=borda, ow=0.09, smooth=False)
        sombra_ch = _chaikin([(1.05, -1.08), (1.78, -1.05), (2.22, -1.68), (1.92, -2.55), (1.58, -1.98)], 1)
        s.flat(X(sombra_ch), 1.99, 0.02, turq_cl, smooth=False)

    # Pequenas aletas/orelhas laterais pontudas (#B0DCDC) saindo para os lados
    aleta_lat = _chaikin([
        (1.45, 0.58), (2.52, 0.35), (2.88, -0.18), (2.18, -0.35),
        (2.55, -0.78), (1.85, -0.88), (1.45, -0.58)
    ], 1)
    s.sym(aleta_lat, 0.86, 1.04, turq_cl, outline=borda, ow=0.09, smooth=False)
    s.sym(_chaikin([(1.65, 0.32), (2.42, 0.15), (2.62, -0.15), (1.75, -0.18)], 1),
          1.91, 0.02, turq_esc, smooth=False)
    s.sym(_chaikin([(1.65, -0.28), (2.32, -0.68), (1.82, -0.72), (1.62, -0.50)], 1),
          1.91, 0.02, turq_esc, smooth=False)

    # Pequena cauda pontuda de diabrete na borda traseira
    cauda_imp = _chaikin([(-0.48, -1.48), (-0.38, -2.18), (0.0, -2.68), (0.38, -2.18), (0.48, -1.48)], 1)
    s.flat(cauda_imp, 0.85, 1.04, turq_esc, outline=borda, ow=0.08, smooth=False)

    # Duas presinhas brancas curtas na borda da frente (y = 1.58..2.36, 100% à frente dos olhos!)
    for k in (-1, 1):
        X = lambda P: [(k * x, y) for x, y in P]
        presa_pts = _chaikin([
            (0.40, 1.58), (0.55, 2.36), (0.85, 2.15), (0.90, 1.58)
        ], 1)
        s.flat(X(presa_pts), 0.88, 1.06, branco, outline=borda, ow=0.08, smooth=False)

    # Aros de diabrete ao redor dos olhos (#58A4A4) com pontinha lateral + losango glacial na testa
    for k in (-1, 1):
        _anel_quads(s, k * EYE_X, EYE_Y, 0.48, 0.62, TOP + 0.015, 0.02, turq_esc, n=14)
    s.sym(_chaikin([(1.18, 0.65), (1.58, 0.84), (1.42, 0.42)], 1),
          TOP + 0.015, 0.02, turq_esc, smooth=False)
    s.flat([(0.0, 1.42), (0.24, 1.02), (0.0, 0.65), (-0.24, 1.02)], TOP + 0.015, 0.02, turq_cl, smooth=False)

    # Escamas suaves em meias-luas/chevrons nas laterais e cantos traseiros (deixando o centro atrás dos olhos limpo!)
    for ex, ey, rx, ry in [
        (-0.92, -1.12, 0.36, 0.20),
        (0.92, -1.12, 0.36, 0.20),
        (-0.62, -1.52, 0.34, 0.18),
        (0.62, -1.52, 0.34, 0.18),
        (-1.28, -0.35, 0.32, 0.20),
        (1.28, -0.35, 0.32, 0.20),
        (-1.28, 0.22, 0.30, 0.18),
        (1.28, 0.22, 0.30, 0.18),
    ]:
        s.flat(_arco(ex, ey, ry * 0.55, rx, math.radians(200), math.radians(340), n=10),
               TOP + 0.012, 0.018, turq_esc, smooth=False)

    # Mão: mão turquesa com escama clara e 3 garras brancas afiadas
    s.hand_flat(ellipse(0.0, -0.04, 0.28, 0.20, n=12), 1.83, 0.025, turq_cl)
    for kk in (-1, 0, 1):
        s.hand_flat(_espinho(kk * 0.22, 0.34, math.radians(90 - 18 * kk), 0.45, 0.11),
                    1.28, 0.38, branco, outline=borda, ow=0.04, smooth=False)


# ---------------------------------------------------------------- 8. Bolha Verde
def bolha_verde(s):
    # Monstrinho gelatinoso de limo ácido (#3CC458, contorno #309044), bolhas redondas saltando de forma
    # assimétrica na silhueta lateral e traseira (#48BC64 e #C8C870), manchas/bolhas amareladas translúcidas
    # no topo e mãos com gotinhas de slime.
    corpo, borda, am_bolha, verde_am, verde_cl, verde_med, brilho = (
        "#3CC458", "#309044", "#C8C870", "#84C458", "#70D484", "#48BC64", "#FCFCF8"
    )
    s.base()

    # Ondas/lóbulos orgânicos assimétricos de limo fundidos ao corpo (_extensao_sem_costura com z_cap=1.78..2.01)
    lobo_esq = _chaikin([
        (-1.42, 1.15), (-2.38, 0.85), (-2.55, 0.05), (-2.05, -0.45),
        (-2.42, -1.12), (-1.75, -1.62), (-1.35, -1.15)
    ], 2)
    _extensao_sem_costura(s, lobo_esq, corpo, borda, ow=0.10, z_cap=1.78, z_cap_top=2.01)

    lobo_dir = _chaikin([
        (1.38, 0.85), (2.25, 0.48), (2.02, -0.18),
        (2.58, -0.78), (2.28, -1.55), (1.42, -1.45)
    ], 2)
    _extensao_sem_costura(s, lobo_dir, corpo, borda, ow=0.10, z_cap=1.78, z_cap_top=2.01)

    lobo_tras = _chaikin([
        (-1.25, -1.38), (-1.12, -2.28), (-0.35, -2.05),
        (0.28, -2.58), (1.08, -2.25), (1.18, -1.38)
    ], 2)
    _extensao_sem_costura(s, lobo_tras, corpo, borda, ow=0.10, z_cap=1.78, z_cap_top=2.01)

    # Bolhas redondas saltando de forma assimétrica na silhueta lateral e traseira (#48BC64, #84C458 e #C8C870)
    bolhas_silhueta = [
        (-2.35, 0.45, 0.55, 0.52, verde_med, am_bolha),
        (-2.18, -1.05, 0.48, 0.45, verde_am, am_bolha),
        (-0.85, -2.15, 0.52, 0.48, am_bolha, brilho),
        (0.32, -2.42, 0.62, 0.56, verde_med, verde_am),
        (1.35, -2.02, 0.44, 0.42, am_bolha, brilho),
        (2.38, -0.88, 0.56, 0.52, verde_am, am_bolha),
        (2.08, 0.62, 0.46, 0.44, am_bolha, brilho),
    ]
    for bx, by, rx, ry, c_ext, c_int in bolhas_silhueta:
        s.flat(ellipse(bx, by, rx, ry, n=18), 0.84, 1.06, c_ext, outline=borda, ow=0.09)
        s.flat(ellipse(bx, by, rx * 0.68, ry * 0.68, n=14), 1.91, 0.02, c_int)
        s.flat(ellipse(bx - rx * 0.25, by + ry * 0.25, rx * 0.22, ry * 0.22, n=10), 1.935, 0.02, brilho)

    # Manchas e bolhas amareladas/verdes no topo (longe dos olhos e do centro traseiro!)
    bolhas_topo = [
        (-1.42, -0.35, 0.42, 0.36, verde_am, am_bolha, True),
        (1.38, -0.38, 0.46, 0.38, verde_cl, am_bolha, True),
        (-0.88, -1.32, 0.46, 0.38, verde_am, am_bolha, True),
        (0.85, -1.38, 0.38, 0.32, am_bolha, brilho, False),
        (0.0, 1.38, 0.36, 0.26, verde_cl, am_bolha, False),
        (-1.38, 1.15, 0.28, 0.24, am_bolha, brilho, False),
        (1.32, 1.12, 0.28, 0.24, am_bolha, brilho, False),
        (-1.35, -1.05, 0.25, 0.22, verde_cl, None, False),
    ]
    for bx, by, rx, ry, c1, c2, tem_brilho in bolhas_topo:
        s.flat(ellipse(bx, by, rx, ry, n=16), TOP + 0.010, 0.018, c1)
        if c2:
            s.flat(ellipse(bx + 0.04, by - 0.03, rx * 0.62, ry * 0.62, n=14), TOP + 0.028, 0.018, c2)
        if tem_brilho:
            s.flat(ellipse(bx - rx * 0.28, by + ry * 0.28, rx * 0.22, ry * 0.22, n=10), TOP + 0.048, 0.018, brilho)

    # Mão: mão gelatinosa com gotinhas/bolhas de slime saltando na borda
    s.hand_flat(ellipse(-0.32, 0.22, 0.24, 0.22, n=12), 1.32, 0.42, verde_am, outline=borda, ow=0.04)
    s.hand_flat(ellipse(0.30, 0.28, 0.20, 0.18, n=12), 1.32, 0.42, am_bolha, outline=borda, ow=0.04)
    s.hand_flat(ellipse(0.05, 0.02, 0.26, 0.22, n=12), 1.83, 0.025, am_bolha)
    s.hand_flat(ellipse(-0.04, 0.10, 0.10, 0.10, n=8), 1.86, 0.02, brilho)


# ---------------------------------------------------------------- 9. Gelo Rachado
def gelo_rachado(s):
    # Golem/bloco de gelo glacial rachado: corpo azul-petróleo (#187484, contorno escuro #201C20),
    # crostas/placas irregulares de neve branca (#DCF0F4 / #ACDCE8) cobrindo os ombros, cantos e parte do topo
    # com fendas escuras de gelo profundo entre as placas; mãos com cristais de gelo e neve.
    corpo, borda, neve_cl, neve_med, neve_esc, fenda_az, fenda_esc = (
        "#187484", "#201C20", "#DCF0F4", "#ACDCE8", "#A8CCD4", "#386470", "#504C54"
    )
    s.base()

    # Crostas/placas angulares irregulares de neve branca e gelo saindo nos ombros, cantos traseiros e frente
    crosta_tras_c = [(-0.88, -1.48), (-0.62, -2.42), (0.58, -2.45), (0.92, -1.48)]
    s.flat(crosta_tras_c, 0.84, 1.08, neve_med, outline=borda, ow=0.10, smooth=False)
    s.flat([(-0.68, -1.55), (-0.48, -2.22), (0.42, -2.25), (0.68, -1.55)], 1.93, 0.025, neve_cl, smooth=False)

    crosta_canto_tras = [(0.78, -1.42), (1.78, -2.35), (2.42, -1.55), (1.52, -0.82)]
    s.sym(crosta_canto_tras, 0.85, 1.08, neve_cl, outline=borda, ow=0.10, smooth=False)
    s.sym([(0.98, -1.48), (1.72, -2.08), (2.15, -1.52), (1.48, -1.02)], 1.94, 0.02, neve_med, smooth=False)

    crosta_ombro = [(1.45, -0.68), (2.48, -0.38), (2.42, 0.65), (1.45, 0.92)]
    s.sym(crosta_ombro, 0.86, 1.08, neve_med, outline=borda, ow=0.10, smooth=False)
    s.sym([(1.62, -0.48), (2.25, -0.25), (2.20, 0.48), (1.62, 0.68)], 1.95, 0.02, neve_cl, smooth=False)

    crosta_frente_lat = [(1.12, 1.22), (2.18, 0.95), (2.25, 1.65), (1.42, 2.15), (0.92, 1.62)]
    s.sym(crosta_frente_lat, 0.84, 1.08, corpo, outline=borda, ow=0.10, smooth=False)
    s.sym([(1.28, 1.32), (1.98, 1.12), (2.02, 1.58), (1.42, 1.92)], 1.93, 0.02, neve_esc, smooth=False)

    queixo_gelo = [(-0.78, 1.38), (-0.52, 2.15), (0.52, 2.15), (0.78, 1.38)]
    _extensao_sem_costura(s, queixo_gelo, corpo, borda, ow=0.09, z_base=0.675, z_cap=1.72, z_cap_top=1.95)

    # Fendas escuras de gelo profundo (#386470 e #504C54) ramificando nas costas e laterais
    # (deixando o centro atrás dos olhos e entre os olhos limpo!)
    fendas_cfg = [
        [(0.48, -0.82), (1.05, -1.28), (1.75, -1.85)],
        [(1.05, -1.28), (1.85, -0.65)],
        [(-0.48, -0.82), (-1.05, -1.28), (-1.75, -1.85)],
        [(-1.05, -1.28), (-1.85, -0.65)],
        [(0.0, -1.18), (0.0, -2.18)],
        [(1.35, 0.05), (1.78, 0.45), (1.58, 1.38)],
        [(-1.35, 0.05), (-1.78, 0.45), (-1.58, 1.38)],
    ]
    for pts_f in fendas_cfg:
        s.flat(_tubo(pts_f, lambda t: 0.15, cap0=True, cap1=True, n=8), TOP + 0.005, 0.012, fenda_az, smooth=False)
        s.flat(_tubo(pts_f, lambda t: 0.08, cap0=True, cap1=True, n=8), TOP + 0.017, 0.015, fenda_esc, smooth=False)

    # Grandes placas irregulares de neve branca (#DCF0F4 / #ACDCE8) cobrindo os ombros, cantos e parte do topo
    placas_neve_topo = [
        # Placas nos ombros laterais
        ([(-1.72, 0.92), (-1.15, 0.78), (-1.18, -0.55), (-1.75, -0.72)], neve_cl, neve_med),
        ([(1.15, 0.78), (1.72, 0.92), (1.75, -0.72), (1.18, -0.55)], neve_cl, neve_med),
        # Placas dorsais traseiras entre as fendas
        ([(-0.92, -0.82), (-0.20, -0.95), (-0.22, -1.78), (-0.88, -1.55)], neve_cl, neve_med),
        ([(0.20, -0.95), (0.92, -0.82), (0.88, -1.55), (0.22, -1.78)], neve_med, neve_cl),
        # Placas menores nos cantos dianteiros acima dos olhos
        ([(-1.48, 1.58), (-0.52, 1.68), (-0.42, 1.25), (-1.28, 1.15)], neve_med, neve_cl),
        ([(0.52, 1.68), (1.48, 1.58), (1.28, 1.15), (0.42, 1.25)], neve_cl, neve_med),
    ]
    for pts_p, c_top, c_borda_int in placas_neve_topo:
        s.flat(_chaikin(pts_p, 1), TOP + 0.020, 0.020, c_borda_int, smooth=False)
        cx_p = sum(p[0] for p in pts_p) / len(pts_p)
        cy_p = sum(p[1] for p in pts_p) / len(pts_p)
        pts_in = [(cx_p + (x - cx_p) * 0.75, cy_p + (y - cy_p) * 0.75) for x, y in pts_p]
        s.flat(_chaikin(pts_in, 1), TOP + 0.040, 0.018, c_top, smooth=False)

    # Aros octogonais de gelo nos olhos
    for k in (-1, 1):
        _anel_quads(s, k * EYE_X, EYE_Y, 0.48, 0.65, TOP + 0.012, 0.020, fenda_az, n=8, rot_deg=22.5)

    # Mão: bloco de gelo com crosta de neve branca e 2 pontas de cristal glacial
    placa_mao = [(-0.44, -0.25), (0.0, -0.46), (0.44, -0.25), (0.48, 0.32), (0.0, 0.52), (-0.48, 0.32)]
    s.hand_flat(placa_mao, 1.34, 0.48, neve_med, outline=borda, ow=0.05, smooth=False)
    s.hand_flat([(-0.30, -0.15), (0.28, -0.18), (0.32, 0.22), (-0.28, 0.25)], 1.83, 0.025, neve_cl, smooth=False)
    for kk in (-1, 1):
        s.hand_flat([(kk * 0.18, 0.32), (kk * 0.36, 0.75), (kk * 0.04, 0.45)],
                    1.28, 0.40, neve_cl, outline=borda, ow=0.04, smooth=False)


# ---------------------------------------------------------------- 10. Lobisomem
def lobisomem(s):
    # Fera peluda marrom-escura (#7C6030, contorno #54381C), orelhas pontudas rasgadas nos cantos traseiros,
    # juba/pelagem eriçada de múltiplas pontas nas laterais e atrás (#644424 / #54381C),
    # sobrancelhas franzidas de lobo (separadas no centro!) e presas brancas (#FCFCFC) na borda frontal;
    # mãos peludas com 3 garras brancas.
    corpo, borda, pelo_esc, pelo_med, escuro, branco = (
        "#7C6030", "#54381C", "#644424", "#70542C", "#382818", "#FCFCFC"
    )
    s.base()

    # Juba/cauda traseira eriçada de múltiplas pontas ferozes (#644424 / #70542C)
    juba_tras = [
        (-1.35, -1.25), (-1.92, -2.35), (-1.15, -1.95),
        (-0.88, -2.85), (-0.38, -2.12),
        (0.0, -3.12),
        (0.38, -2.12), (0.88, -2.85),
        (1.15, -1.95), (1.92, -2.35), (1.35, -1.25)
    ]
    s.flat(juba_tras, 0.84, 1.06, pelo_esc, outline=borda, ow=0.10, smooth=False)
    s.flat([
        (-0.98, -1.42), (-0.75, -2.48), (-0.32, -1.95), (0.0, -2.72),
        (0.32, -1.95), (0.75, -2.48), (0.98, -1.42)
    ], 1.91, 0.025, pelo_med, smooth=False)

    # Orelhas grandes pontudas e rasgadas (com entalhe lateral) nos cantos traseiros
    for k in (-1, 1):
        X = lambda P: [(k * x, y) for x, y in P]
        orelha = [
            (0.68, -0.78), (1.72, -0.55), (2.75, -1.28), (2.98, -2.58),
            (2.38, -2.42), (2.52, -2.02), (1.98, -2.18), (1.15, -1.85), (0.58, -1.38)
        ]
        s.flat(X(_chaikin(orelha, 1)), 0.88, 1.06, corpo, outline=borda, ow=0.10, smooth=False)
        miolo_or = _chaikin([
            (1.18, -1.08), (1.98, -1.05), (2.55, -1.98), (1.82, -1.92), (1.20, -1.52)
        ], 1)
        s.flat(X(miolo_or), 1.95, 0.02, pelo_esc, smooth=False)
        s.flat(X(_chaikin([(1.42, -1.22), (1.95, -1.22), (2.32, -1.85), (1.78, -1.78)], 1)),
               1.97, 0.02, escuro, smooth=False)

    # Juba/pelagem eriçada de múltiplas pontas afiadas nas laterais (#7C6030 e #644424)
    juba_lat = [
        (1.42, -0.58), (2.68, -0.38), (2.02, 0.05),
        (2.75, 0.48), (2.05, 0.82),
        (2.58, 1.28), (1.98, 1.48), (2.15, 1.82), (1.38, 1.62)
    ]
    s.sym(juba_lat, 0.86, 1.06, corpo, outline=borda, ow=0.10, smooth=False)
    s.sym([(1.68, -0.38), (2.48, -0.32), (1.92, 0.02)], 1.93, 0.02, pelo_esc, smooth=False)
    s.sym([(1.72, 0.25), (2.55, 0.48), (1.95, 0.75)], 1.93, 0.02, pelo_esc, smooth=False)
    s.sym([(1.72, 0.95), (2.40, 1.24), (1.88, 1.38)], 1.93, 0.02, pelo_med, smooth=False)

    # Focinho lupino saliente na frente + nariz escuro #382818 + duas presas brancas (#FCFCFC) nas laterais
    foc = _chaikin([
        (-0.88, 1.22), (-0.76, 1.98), (0.0, 2.42), (0.76, 1.98), (0.88, 1.22), (0.0, 1.02)
    ], 2)
    _extensao_sem_costura(s, foc, pelo_med, borda, ow=0.09, z_cap=1.78, z_cap_top=2.01)
    s.flat(_chaikin([(-0.42, 0.55), (-0.45, 1.55), (0.0, 1.82), (0.45, 1.55), (0.42, 0.55), (0.0, 0.42)], 2),
           TOP + 0.012, 0.018, pelo_esc, smooth=False)
    nar = _chaikin([(-0.34, 1.65), (0.34, 1.65), (0.38, 1.92), (0.0, 2.20), (-0.38, 1.92)], 2)
    s.flat(nar, TOP + 0.030, 0.038, escuro, smooth=False)

    # Presas brancas afiadas (#FCFCFC) saindo na borda frontal ao lado do focinho (100% à frente dos olhos!)
    for k in (-1, 1):
        X = lambda P: [(k * x, y) for x, y in P]
        presa_l = _chaikin([
            (0.58, 1.58), (0.78, 2.32), (1.02, 2.08), (1.05, 1.55)
        ], 1)
        s.flat(X(presa_l), 0.88, 1.06, branco, outline=borda, ow=0.08, smooth=False)

    # Sobrancelhas franzidas de lobo feroz (SEPARADAS no centro! |x| >= 0.35 para não formar linha atrás dos olhos)
    sobr_lobo = [
        (0.36, 0.34), (0.65, 0.08), (1.08, -0.04), (1.52, -0.18),
        (1.56, 0.04), (1.08, 0.16), (0.66, 0.26), (0.35, 0.52)
    ]
    s.sym(sobr_lobo, TOP + 0.018, 0.025, escuro, smooth=False)
    s.sym([(0.38, 0.38), (0.66, 0.14), (1.46, -0.10), (1.48, 0.00), (0.66, 0.22), (0.36, 0.48)],
          TOP + 0.044, 0.015, borda, smooth=False)

    # Pelagem sombreada nas laterais do topo (deixando o centro traseiro limpo!)
    s.sym(_chaikin([(1.15, 1.32), (1.68, 1.05), (1.68, -1.15), (1.12, -1.48), (1.28, -0.10)], 1),
          TOP, 0.014, pelo_esc, smooth=False)

    # Mão: mão peluda com tufo escuro no dorso e 3 garras brancas longas (#FCFCFC)
    s.hand_flat([(-0.35, -0.22), (-0.22, 0.22), (0.0, 0.10), (0.22, 0.22), (0.35, -0.22), (0.0, -0.32)],
                1.83, 0.025, pelo_esc, smooth=False)
    for kk in (-1, 0, 1):
        s.hand_flat(_espinho(kk * 0.22, 0.34, math.radians(90 - 18 * kk), 0.48, 0.11),
                    1.28, 0.40, branco, outline=borda, ow=0.04, smooth=False)


LOTE = [
    ("cardeal", cardeal, "#D84444", "#AC2824", "#D84444", "#AC2824"),
    ("coiote", coiote, "#8C6850", "#4C3830", "#8C6850", "#4C3830"),
    ("raposa_artica", raposa_artica, "#F0ECE0", "#D8B49C", "#F0ECE0", "#D8B49C"),
    ("gato_gelo", gato_gelo, "#DCF0F4", "#1868A0", "#DCF0F4", "#1868A0"),
    ("toco_gelo", toco_gelo, "#CCB89C", "#806054", "#CCB89C", "#806054"),
    ("toco_vulcanico", toco_vulcanico, "#2C2024", "#503C3C", "#2C2024", "#503C3C"),
    ("diabrete_gelo", diabrete_gelo, "#80C8C8", "#64A0A0", "#80C8C8", "#64A0A0"),
    ("bolha_verde", bolha_verde, "#3CC458", "#309044", "#3CC458", "#309044"),
    ("gelo_rachado", gelo_rachado, "#187484", "#201C20", "#187484", "#201C20"),
    ("lobisomem", lobisomem, "#7C6030", "#54381C", "#7C6030", "#54381C"),
]
