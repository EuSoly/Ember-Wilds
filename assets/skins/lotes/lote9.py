# Lote 9 — skins de corpo (detalhadas). Montar com build_skins.py (Blender aberto) ou render_lote.py (segundo plano).
# taco, hamburguer, panda, frankenstein, mumia, sino, engrenagem, caveira, crocodilo, donut.
from skin_lib import *


# ---------------------------------------------------------------- ajudantes do lote
def _chaikin(poly, passes=2):
    for _ in range(passes):
        poly = [
            p for a, b in zip(poly, poly[1:] + poly[:1])
            for p in ((0.75*a[0] + 0.25*b[0], 0.75*a[1] + 0.25*b[1]),
                      (0.25*a[0] + 0.75*b[0], 0.25*a[1] + 0.75*b[1]))
        ]
    return poly


def _rect(cx, cy, w, h):
    hw, hh = w * 0.5, h * 0.5
    return [(cx - hw, cy - hh), (cx + hw, cy - hh), (cx + hw, cy + hh), (cx - hw, cy + hh)]


def _barra_rot(cx, cy, w, h, ang_deg):
    a = math.radians(ang_deg)
    ca, sa = math.cos(a), math.sin(a)
    hw, hh = w * 0.5, h * 0.5
    pts = [(-hw, -hh), (hw, -hh), (hw, hh), (-hw, hh)]
    return [(cx + x * ca - y * sa, cy + x * sa + y * ca) for x, y in pts]


def _anel_quads(s, cx, cy, r_in, r_out, z, thick, color, n=12, rot_deg=0.0):
    """Constrói um anel oco usando n trapézios convexos (sem auto-interseção de malha)."""
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
        s.flat(q, z, thick, color, smooth=False)


# ---------------------------------------------------------------- 1. Taco (ref. 62)
def taco(s):
    s.base()
    # Alface verde ondulada (#8CC440) saindo bastante pelo topo/trás e laterais
    alface_pts = []
    n_ondas = 20
    for i in range(n_ondas + 1):
        ang = math.radians(-22 + 224 * i / n_ondas)
        r_base = 2.42 if i % 2 == 0 else 2.12
        alface_pts.append((r_base * math.cos(ang) * 1.02, 0.10 - r_base * math.sin(ang) * 1.02))
    alface_pts.extend([(-1.60, 0.85), (1.60, 0.85)])
    s.flat(_chaikin(alface_pts, 2), 0.72, 1.18, "#8CC440", outline="#6CA028", ow=0.07, smooth=False)

    # 5 fatias semicirculares de tomate (#C01C2C / #F05828) saindo bem visíveis ao redor do arco
    tomates = [
        (-1.72, 0.35, 0.72, 95, 255),
        (-1.05, -1.42, 0.78, 20, 175),
        (0.18, -1.68, 0.74, 0, 165),
        (1.28, -1.12, 0.74, -45, 115),
        (1.72, 0.42, 0.72, -75, 85),
    ]
    for tx, ty, tr, a0, a1 in tomates:
        pts_t = [(tx, ty)] + [
            (tx + tr * math.cos(math.radians(a0 + (a1 - a0) * k / 12)),
             ty - tr * math.sin(math.radians(a0 + (a1 - a0) * k / 12)))
            for k in range(13)
        ]
        s.flat(_chaikin(pts_t, 1), 0.82, 1.12, "#C01C2C", outline="#981420", ow=0.06, smooth=False)
        pts_miolo = [(tx, ty)] + [
            (tx + tr * 0.74 * math.cos(math.radians(a0 + 12 + (a1 - a0 - 24) * k / 8)),
             ty - tr * 0.74 * math.sin(math.radians(a0 + 12 + (a1 - a0 - 24) * k / 8)))
            for k in range(9)
        ]
        s.flat(_chaikin(pts_miolo, 1), 1.95, 0.025, "#F05828", smooth=False)

    # Tiras de queijo amarelo (#F8DC1C) saindo entre a alface e os tomates
    tiras_queijo = [
        ((-2.08, -0.25), 0.58, 0.18, 28),
        ((-2.10, 1.05), 0.56, 0.18, -25),
        ((-0.38, -1.96), 0.60, 0.18, 18),
        ((0.78, -1.85), 0.58, 0.18, -20),
        ((1.88, -0.35), 0.58, 0.18, 65),
        ((2.02, 0.98), 0.54, 0.18, -45),
    ]
    for (qx, qy), qw, qh, qang in tiras_queijo:
        s.flat(_chaikin(_barra_rot(qx, qy, qw, qh, qang), 1), 0.90, 1.06, "#F8DC1C", smooth=False)

    # Manchinhas tostadas da tortilla (#F89838) na face e no topo
    for mx, my, mr in [
        (-1.12, -0.82, 0.15), (-0.46, -0.28, 0.25), (-1.35, -0.08, 0.11),
        (-1.02, 0.25, 0.13), (-1.45, 1.02, 0.11), (-0.02, -0.82, 0.09),
        (0.62, -0.72, 0.09), (0.22, -0.02, 0.08), (0.22, 0.58, 0.16),
        (0.02, 1.38, 0.10), (1.22, -0.05, 0.15), (1.35, 1.30, 0.12),
    ]:
        s.flat(ellipse(mx, my, mr, mr, 12), TOP, 0.015, "#F89838")
    # Folhinha de alface e queijo na mão
    s.hand_flat(ellipse(0.0, -0.15, 0.45, 0.35, 12), 1.35, 0.35, "#8CC440", outline="#6CA028", ow=0.05)


# ---------------------------------------------------------------- 2. Hamburguer (ref. 67)
def hamburguer(s):
    s.base()
    # Brilho frontal do pão inferior (#EC901C e #F4B014)
    s.flat(_chaikin([(-1.52, 0.85), (1.52, 0.85), (1.42, 1.60), (-1.42, 1.60)], 2),
           TOP, 0.003, "#EC901C", smooth=False)
    s.flat(_chaikin([(-0.35, 1.02), (1.15, 1.02), (1.05, 1.52), (-0.25, 1.52)], 2),
           TOP + 0.003, 0.003, "#F4B014", smooth=False)

    # Folhas de alface verde (#78A830) saindo nas laterais e entre os olhos
    alface_lat = _chaikin([
        (1.25, 0.25), (2.15, 0.38), (2.25, 0.85), (2.10, 1.28),
        (1.65, 1.15), (1.35, 1.25), (1.15, 0.85),
    ], 2)
    s.sym(alface_lat, 0.65, 1.28, "#78A830", outline="#A82C04", ow=0.08, smooth=False)
    # Alface central entre os olhos
    s.flat(_chaikin([
        (-0.38, 0.35), (0.38, 0.35), (0.32, 1.05), (0.08, 1.18),
        (-0.15, 0.82), (-0.35, 0.92),
    ], 2), TOP, 0.004, "#78A830", outline="#588820", ow=0.04, smooth=False)

    # Hambúrguer de carne grelhada (#584024, contorno #3C2814) atrás/acima dos olhos
    carne_pts = _chaikin([
        (-1.92, -0.45), (1.92, -0.45),
        (1.96, 0.25), (1.35, 0.32),
        (0.35, 0.36), (-0.35, 0.36),
        (-1.35, 0.32), (-1.96, 0.25),
    ], 2)
    s.flat(carne_pts, 0.95, 1.053, "#584024", outline="#3C2814", ow=0.07, smooth=False)
    for gx, gy, gr in [(1.42, -0.02, 0.14), (0.82, 0.06, 0.12), (0.18, 0.10, 0.11)]:
        s.flat(ellipse(gx, gy, gr * 1.3, gr, 10), TOP + 0.004, 0.012, "#644828")

    # Fatia de queijo amarelo derretido (#FCE430 / #E8C814) escorrendo na direita da câmera (-X)
    # z_top = 2.004 (< 2.005) para não cortar o olho!
    queijo_pts = _chaikin([
        (1.78, -0.35), (-1.88, -0.42),
        (-2.02, 0.15), (-1.85, 0.68),
        (-1.52, 0.58), (-1.25, 0.88),
        (-0.88, 0.82), (-0.35, 0.22),
        (0.35, 0.02), (1.65, -0.15),
    ], 2)
    s.flat(queijo_pts, 1.10, 0.904, "#FCE430", outline="#D8A810", ow=0.05, smooth=False)

    # Pão superior arredondado (#CC5418 / #EC901C / #F4B014) cobrindo a metade traseira
    pao_topo = _chaikin([
        (-1.82, -0.18), (-1.88, -0.88), (-1.52, -1.52), (-0.85, -1.85),
        (0.0, -1.95), (0.85, -1.85), (1.52, -1.52), (1.88, -0.88),
        (1.82, -0.18), (0.95, 0.02), (0.0, 0.05), (-0.95, 0.02),
    ], 2)
    s.flat(pao_topo, 1.15, 0.92, "#CC5418", outline="#A82C04", ow=0.10, smooth=False)
    pao_topo_meio = _chaikin([
        (-1.42, -0.38), (-1.35, -1.20), (-0.75, -1.68),
        (0.0, -1.76), (0.75, -1.68), (1.45, -1.25),
        (1.62, -0.32), (0.65, -0.18), (-0.65, -0.18),
    ], 2)
    s.flat(pao_topo_meio, 2.07, 0.03, "#EC901C", smooth=False)
    pao_topo_brilho = _chaikin([
        (1.35, -0.48), (1.22, -1.12), (0.55, -1.48),
        (-0.15, -1.35), (-0.28, -0.52), (0.45, -0.32),
    ], 2)
    s.flat(pao_topo_brilho, 2.10, 0.02, "#F4B014", smooth=False)

    # 3 sementes de gergelim (#FCC868) no topo do pão
    for sx, sy, sang in [(0.18, -1.42, 12), (-0.18, -1.40, -5), (-0.54, -1.38, -18)]:
        s.flat(_chaikin(_barra_rot(sx, sy, 0.15, 0.32, sang), 2), 2.12, 0.025, "#FCC868", smooth=False)


# ---------------------------------------------------------------- 3. Panda (ref. 92)
def panda(s):
    s.base()
    # Tufos de pelo nas bochechas laterais e topo da cabeça (triângulos convexos sem costura)
    for ty0, ty1, tx_out in [(-0.98, -0.35, 2.02), (-0.35, 0.35, 1.98)]:
        tufo_lat = [(1.55, ty0), (tx_out, (ty0 + ty1) * 0.5), (1.55, ty1)]
        s.sym(tufo_lat, 0.80, 1.05, "#F0F0F0", outline="#ACACAC", ow=0.09, smooth=False)
        s.sym(tufo_lat, 1.85, 0.15, "#F0F0F0", smooth=False)

    for tx0, tx1 in [(-0.55, -0.02), (0.02, 0.55)]:
        tufo_tras = [(tx0, -1.55), ((tx0 + tx1) * 0.5, -1.96), (tx1, -1.55)]
        s.flat(tufo_tras, 0.80, 1.05, "#F0F0F0", outline="#ACACAC", ow=0.09, smooth=False)
        s.flat(tufo_tras, 1.85, 0.15, "#F0F0F0", smooth=False)

    # Grandes orelhas redondas preto-carvão (#3C403C, contorno #201C20) nos cantos traseiros
    s.sym(ellipse(1.18, -1.38, 0.82, 0.78, 24), 0.55, 1.42, "#3C403C", outline="#201C20", ow=0.09, smooth=False)
    s.sym(ellipse(1.15, -1.32, 0.50, 0.48, 20), 1.97, 0.02, "#181818", smooth=False)
    # 2 dentinhos de pelo branco avançando sobre a base da orelha (apenas sobre a orelha em z=1.972)
    for (ax, ay), (bx, by), (cx, cy) in [
        ((1.55, -0.82), (1.36, -1.06), (1.12, -0.82)),
        ((1.16, -0.82), (0.92, -1.10), (0.68, -0.82)),
    ]:
        s.sym([(ax, ay), (bx, by), (cx, cy)], 1.972, 0.022, "#F0F0F0", smooth=False)

    # Manchas ovais escuras inclinadas ao redor dos olhos (#3C403C)
    # z_top = 2.003 (< 2.005) para os olhos pretos ficarem 100% visíveis por cima!
    s.sym(ellipse(0.82, 0.56, 0.78, 0.68, 24, rot=math.radians(-18)),
          TOP - 0.015, 0.018, "#3C403C", smooth=False)

    # Focinho branco saliente na frente (#FCFCFC, contorno #ACACAC apenas fora do corpo)
    focinho_poly = ellipse(0.0, 1.48, 0.68, 0.72, 24)
    s.flat(focinho_poly, 0.55, 1.30, "#FCFCFC", outline="#ACACAC", ow=0.09, smooth=False)
    s.flat(focinho_poly, 1.85, 0.16, "#FCFCFC", smooth=False)

    # Nariz oval escuro (#201C20) e linha vertical até a ponta do focinho
    s.flat(ellipse(0.0, 1.56, 0.30, 0.18, 16), 2.01, 0.03, "#201C20", smooth=False)
    s.flat(_chaikin(_rect(0.0, 1.88, 0.10, 0.45), 1), 2.01, 0.025, "#201C20", smooth=False)


# ---------------------------------------------------------------- 4. Frankenstein (ref. 112)
def frankenstein(s):
    s.base()
    # 2 parafusos metálicos laterais (#989C98 com contorno grosso #246478)
    s.sym(_chaikin(_rect(2.02, 0.68, 0.48, 0.90), 1),
          0.50, 1.32, "#989C98", outline="#246478", ow=0.11, smooth=False)

    # Linha horizontal de cicatriz na testa (#246478) com pontinha saindo na lateral
    s.flat(_chaikin(_rect(-0.06, -0.26, 3.84, 0.16), 1),
           TOP, 0.025, "#246478", smooth=False)

    # Pontos de sutura roxo-acinzentados (#785460) cruzando a cicatriz
    pontos = [
        (1.32, -0.26, 0.15, 0.68, 16),
        (0.92, -0.24, 0.15, 0.60, -22),
        (0.54, -0.24, 0.15, 0.64, 20),
        (0.20, -0.32, 0.15, 0.68, -5),
        (-0.18, -0.24, 0.15, 0.68, 26),
        (-0.66, -0.24, 0.15, 0.66, -42),
        (-1.06, -0.24, 0.15, 0.64, 10),
        (-1.40, -0.30, 0.15, 0.62, -30),
    ]
    for px, py, pw, ph, pang in pontos:
        s.flat(_chaikin(_barra_rot(px, py, pw, ph, pang), 1),
               TOP + 0.025, 0.03, "#785460", smooth=False)


# ---------------------------------------------------------------- 5. Mumia (ref. 114)
def mumia(s):
    s.base()
    # Ponta de faixa solta pendurada na lateral frontal (lado esquerdo da câmera = +X)
    faixa_solta = _chaikin([
        (2.12, 0.12), (1.68, 0.12),
        (1.55, 1.88), (2.15, 1.72),
    ], 1)
    s.flat(faixa_solta, 0.45, 1.50, "#FCFCE4", outline="#ACD8A8", ow=0.09, smooth=False)

    # Camadas de faixas creme (#FCFCE4, contorno #ACD8A8) na metade traseira/superior
    faixas = [
        ([(1.82, -1.10), (1.45, -1.78), (-1.45, -1.78), (-1.82, -1.10)], TOP, 0.015),
        ([(1.86, -0.78), (1.82, -1.18), (-1.84, -1.35), (-1.88, -0.92)], TOP + 0.015, 0.018),
        ([(1.88, -0.28), (1.86, -0.78), (-1.86, -0.95), (-1.88, -0.52)], TOP + 0.033, 0.018),
        ([(1.88, 0.25), (1.88, -0.32), (-1.88, -0.82), (-1.88, -0.25)], TOP + 0.051, 0.018),
        ([(0.15, -0.02), (-1.88, -0.35), (-1.88, 0.24), (-0.15, 0.06)], TOP + 0.069, 0.018),
    ]
    for pts, fz, fthick in faixas:
        s.flat(_chaikin(pts, 1), fz, fthick, "#FCFCE4", outline="#ACD8A8", ow=0.08, smooth=False)


# ---------------------------------------------------------------- 6. Sino (ref. 126)
def sino(s):
    s.base()
    # Aba inferior do sino alargando nos cantos frontais (z_top <= 1.85 na base para esconder costura interna)
    aba_sino = _chaikin([
        (-1.80, 0.45), (-2.30, 1.25), (-2.05, 1.65),
        (-1.25, 1.92), (0.0, 1.98), (1.25, 1.92),
        (2.05, 1.65), (2.30, 1.25), (1.80, 0.45),
    ], 2)
    s.flat(aba_sino, 0.40, 1.44, "#CCA420", outline="#AC8410", ow=0.11, smooth=False)
    s.flat(aba_sino, 1.84, 0.14, "#CCA420", smooth=False)

    # Friso interno curvado dourado-escuro (#AC8410) acompanhando a boca do sino
    # Feito em 4 segmentos convexos com z_top = 2.004 (< 2.005) para não cortar os olhos!
    pts_up = [(-1.80, 0.72), (-1.05, 0.96), (0.0, 1.05), (1.05, 0.96), (1.80, 0.72)]
    pts_dn = [(-1.80, 0.92), (-1.05, 1.16), (0.0, 1.25), (1.05, 1.16), (1.80, 0.92)]
    for i in range(4):
        q = [pts_up[i], pts_up[i + 1], pts_dn[i + 1], pts_dn[i]]
        s.flat(q, TOP, 0.004, "#AC8410", smooth=False)

    # Grande laço vermelho (#C4202C, contorno #B02028) no topo traseiro
    laco_dir = _chaikin([
        (0.15, -1.45), (0.88, -1.98), (1.18, -1.62),
        (1.12, -0.95), (0.72, -0.72), (0.15, -1.08),
    ], 2)
    s.sym(laco_dir, 1.15, 0.92, "#C4202C", outline="#B02028", ow=0.10, smooth=False)
    s.flat(ellipse(0.0, -1.35, 0.42, 0.44, 20), 1.25, 0.88, "#C4202C", outline="#B02028", ow=0.10, smooth=False)


# ---------------------------------------------------------------- 7. Engrenagem (ref. 154)
def engrenagem(s):
    s.base()
    # Na câmera 65°, a esquerda da imagem é +X e a direita da imagem é -X!
    # Entalhe retangular escuro na borda traseira esquerda da imagem (+X, -Y)
    s.flat(_chaikin(_rect(0.55, -1.62, 0.82, 0.42), 1),
           TOP, 0.02, "#3C302C", outline="#645858", ow=0.09, smooth=False)

    # Grande engrenagem enferrujada (#784440, contorno #543430) no quadrante traseiro direito da imagem (-X, -Y)
    gx, gy = -0.82, -0.74
    n_dentes = 8
    pts_eng = []
    for i in range(n_dentes * 4):
        ang = 2 * math.pi * i / (n_dentes * 4) + math.radians(11)
        r = 1.24 if (i % 4 in (1, 2)) else 0.96
        pts_eng.append((gx + r * math.cos(ang), gy + r * math.sin(ang)))
    s.flat(_chaikin(pts_eng, 1), 0.60, 1.40, "#784440", outline="#543430", ow=0.08, smooth=False)
    # Furo central da engrenagem
    s.flat(ellipse(gx, gy, 0.46, 0.46, 18), 2.005, 0.015, "#FCFCFC", outline="#543430", ow=0.08, smooth=False)

    # Placa de pedra rachada no quadrante traseiro esquerdo (+X, -Y) — z_top = 2.003 para nunca cobrir olho!
    placa_rachada = [
        (1.76, -1.72), (1.02, -1.72), (1.02, -1.32), (0.12, -1.32),
        (0.12, -1.72), (-0.32, -1.72), (0.02, -1.28), (-0.18, -1.12),
        (-0.18, -0.75), (0.12, -0.58), (-0.48, -0.45), (-0.18, 0.05),
        (1.76, 0.05),
    ]
    s.flat(placa_rachada, TOP, 0.003, "#7C7470", outline="#645858", ow=0.07, smooth=False)

    # Placa frontal esquerda da imagem (+X, +Y) (#807C70, contorno #645858) com z_top = 2.003
    s.flat(_chaikin(_rect(0.98, 0.78, 1.64, 1.85), 2),
           TOP, 0.003, "#807C70", outline="#645858", ow=0.07, smooth=False)

    # Moldura hexagonal escura ao redor do olho (+0.8, 0.55) usando 6 trapézios convexos!
    _anel_quads(s, 0.80, 0.55, 0.48, 0.68, TOP + 0.004, 0.015, "#3C302C", n=6, rot_deg=30)

    # 3 dentes de ferrugem subindo na borda frontal (+X, +Y) sem tocar no olho (+0.8, 0.55)
    for fx0, fx1, fy_tip in [(1.42, 1.78, 0.55), (0.98, 1.42, 0.98), (0.18, 0.62, 0.35)]:
        tri_f = [(fx0, 1.68), ((fx0 + fx1) * 0.5, fy_tip), (fx1, 1.68)]
        s.flat(tri_f, TOP + 0.005, 0.012, "#784440", outline="#543430", ow=0.04, smooth=False)

    # Grande porca hexagonal (#807C70, contorno #645858) ao redor do olho direito da imagem (-0.8, 0.55)
    s.flat(_chaikin(_rect(-1.62, 0.62, 0.78, 0.68), 1),
           0.65, 1.35, "#807C70", outline="#645858", ow=0.09, smooth=False)
    # Base hexagonal da porca com z_top = 2.002 (contorno externo contínuo sem cobrir o olho!)
    hex_ext = [
        (-0.80 + 0.94 * math.cos(math.radians(30 + 60 * i)),
         0.55 + 0.94 * math.sin(math.radians(30 + 60 * i)))
        for i in range(6)
    ]
    s.flat(hex_ext, TOP - 0.01, 0.012, "#3C302C", outline="#645858", ow=0.08, smooth=False)
    # Anel elevado da porca hexagonal feito de 6 trapézios convexos (deixa o olho 100% livre no centro!)
    _anel_quads(s, -0.80, 0.55, 0.50, 0.90, TOP + 0.005, 0.035, "#807C70", n=6, rot_deg=30)


# ---------------------------------------------------------------- 8. Caveira (ref. 177)
def caveira(s):
    s.base()
    # Silhueta orgânica irregular de terra/rocha ao redor do fóssil (z_top = 1.98)
    terra_ext = _chaikin([
        (-1.72, -1.65), (-1.15, -1.82), (-0.42, -1.78),
        (0.45, -1.96), (1.28, -1.85), (1.68, -1.52),
        (1.94, -0.78), (1.88, 0.15), (1.96, 1.05),
        (1.65, 1.55), (0.85, 1.92), (0.15, 2.22),
        (-0.62, 2.08), (-1.52, 1.62), (-1.94, 0.85),
        (-1.82, 0.05), (-1.90, -0.95),
    ], 2)
    s.flat(terra_ext, 0.45, 1.53, "#684C24", outline="#5C3C20", ow=0.10, smooth=False)

    # Camada intermediária de terra clara (#846430) abaixo do crânio (z_top = 2.001)
    terra_clara = _chaikin([
        (-1.52, -1.55), (-0.35, -1.58), (0.45, -1.75), (1.25, -1.65),
        (1.65, -0.75), (1.62, 1.15), (-1.52, 1.15),
    ], 2)
    s.flat(terra_clara, TOP, 0.001, "#846430", smooth=False)

    # Crânio creme-osso (#D8D0A8, contorno #BCA484) com maxilar e 4 dentes na frente
    # z_top = 2.003 (> 2.001 da terra clara, e < 2.005 para os olhos ficarem inteiros!)
    cranio_pts = _chaikin([
        (-1.48, -1.25), (1.48, -1.25),
        (1.56, 0.85), (1.28, 1.32),
        (0.68, 1.38), (0.68, 1.88),
        (0.0, 1.96), (-0.68, 1.88),
        (-0.68, 1.38), (-1.28, 1.32),
        (-1.56, 0.85),
    ], 2)
    s.flat(cranio_pts, 1.15, 0.853, "#D8D0A8", outline="#BCA484", ow=0.10, smooth=False)

    # 3 divisórias verticais dos dentes (#BCA484) na frente do maxilar
    for dx in (-0.34, 0.0, 0.34):
        s.flat(_chaikin(_rect(dx, 1.72, 0.11, 0.38), 1), 2.004, 0.02, "#BCA484", smooth=False)

    # Anéis de órbita ocular (#BCA484) usando trapézios convexos ao redor dos dois olhos
    for sx in (-1, 1):
        _anel_quads(s, sx * 0.80, 0.55, 0.48, 0.64, 2.004, 0.02, "#BCA484", n=16)


# ---------------------------------------------------------------- 9. Crocodilo (ref. 219)
def crocodilo(s):
    s.base()
    # Sombreado lateral verde-escuro (#486830) nas bochechas esquerda e direita
    s.sym(_chaikin([
        (1.72, -0.55), (1.76, 0.95),
        (1.42, 1.35), (1.48, 0.25),
    ], 2), TOP, 0.004, "#486830", smooth=False)

    # 3 escamas/cristas dorsais verde-escuras (#486830) entre e atrás dos olhos
    for cx, cy, cw, ch in [(0.0, -0.12, 0.88, 0.18), (0.0, 0.28, 0.72, 0.16), (0.0, 0.68, 0.68, 0.16)]:
        s.flat(ellipse(cx, cy, cw, ch, 16), TOP, 0.004, "#486830", smooth=False)

    # Focinho largo saliente na frente (z_top = 1.84 na base para não criar costura interna na face)
    focinho_croc = _chaikin([
        (-1.42, 1.10), (-0.98, 2.12), (-0.42, 2.38),
        (0.42, 2.38), (0.98, 2.12), (1.42, 1.10),
    ], 2)
    s.flat(focinho_croc, 0.55, 1.29, "#486830", outline="#304828", ow=0.10, smooth=False)
    focinho_topo = _chaikin([
        (-1.38, 0.95), (-0.92, 1.82), (-0.38, 2.02),
        (0.38, 2.02), (0.92, 1.82), (1.38, 0.95),
    ], 2)
    s.flat(focinho_topo, 1.84, 0.163, "#608434", smooth=False)

    # 2 narinas ovais verde-escuras (#486830) na ponta do focinho
    s.sym(_chaikin(_barra_rot(0.45, 1.65, 0.20, 0.13, -25), 1), 2.005, 0.02, "#486830", smooth=False)

    # 4 pares de dentes brancos afiados (#FCFCFC) saindo da mandíbula frontal
    dentes = [
        (0.34, 2.02, 0.18, 0.38, -8),
        (0.62, 1.95, 0.22, 0.46, -15),
        (0.95, 1.68, 0.26, 0.54, -24),
        (1.24, 1.35, 0.18, 0.38, -32),
    ]
    for dx, dy, dw, dl, dang in dentes:
        a = math.radians(dang)
        ca, sa = math.cos(a), math.sin(a)
        pts_d = [
            (dx - dw * 0.5 * ca, dy - dw * 0.5 * sa),
            (dx + dw * 0.5 * ca, dy + dw * 0.5 * sa),
            (dx - dl * sa, dy + dl * ca),
        ]
        s.sym(pts_d, 1.82, 0.18, "#FCFCFC", smooth=False)


# ---------------------------------------------------------------- 10. Donut (ref. 221)
def donut(s):
    s.base()
    # Destaque mais claro (#C89054) no anel central da massa (z_top <= 2.003 para não cortar olhos)
    s.flat(_chaikin(_rect(0.0, 0.12, 2.15, 1.55), 2), TOP, 0.003, "#C89054", smooth=False)

    # Furo central retangular-arredondado do donut (y = -0.18, atrás dos olhos)
    s.flat(_chaikin(_rect(0.0, -0.18, 1.68, 0.78), 2), TOP + 0.004, 0.015, "#884830", smooth=False)
    s.flat(_chaikin(_rect(0.0, -0.24, 1.42, 0.48), 1), TOP + 0.019, 0.01, "#808080", smooth=False)
    s.flat(_chaikin(_rect(0.0, -0.08, 1.42, 0.28), 1), TOP + 0.029, 0.01, "#FCFCFC", smooth=False)

    # Cobertura rosa ondulada (#E47CA4, contorno #A8488C, sombra #D86898) cobrindo trás e laterais
    cobertura_sombra = _chaikin([
        (-1.88, 0.45), (-1.92, -0.95), (-1.45, -1.72), (-0.75, -1.86),
        (0.75, -1.86), (1.45, -1.72), (1.92, -0.95), (1.88, 0.52),
        (1.48, 0.55), (1.18, -0.18), (0.72, -0.15), (0.38, -0.62),
        (0.0, -0.32), (-0.38, -0.32), (-0.72, -0.62), (-1.05, -0.25),
        (-1.42, -0.22), (-1.62, 0.45),
    ], 2)
    s.flat(cobertura_sombra, 0.85, 1.20, "#D86898", outline="#A8488C", ow=0.10, smooth=False)

    cobertura_luz = _chaikin([
        (-1.74, 0.18), (-1.78, -0.92), (-1.35, -1.62), (-0.68, -1.74),
        (0.68, -1.74), (1.35, -1.62), (1.78, -0.92), (1.74, 0.25),
        (1.48, 0.25), (1.18, -0.42), (0.75, -0.38), (0.32, -0.98),
        (-0.22, -0.52), (-0.68, -0.82), (-1.05, -0.45), (-1.48, -0.42),
    ], 2)
    s.flat(cobertura_luz, 2.05, 0.02, "#E47CA4", smooth=False)

    # 6 granulados coloridos (#ACDC34 verde, #3884CC azul, #DC3828 vermelho)
    granulados = [
        (1.18, -1.38, 0.44, 0.16, 12, "#ACDC34"),
        (1.42, -0.65, 0.44, 0.16, -16, "#3884CC"),
        (0.75, -0.95, 0.44, 0.16, -42, "#DC3828"),
        (-0.08, -1.25, 0.44, 0.16, -15, "#3884CC"),
        (-0.85, -1.38, 0.44, 0.16, -45, "#ACDC34"),
        (-1.35, -0.92, 0.44, 0.16, 32, "#DC3828"),
    ]
    for gx, gy, gw, gh, gang, gcol in granulados:
        s.flat(_chaikin(_barra_rot(gx, gy, gw, gh, gang), 1), 2.07, 0.025, gcol, smooth=False)


LOTE = [
    ("taco", taco, "#FCAC40", "#AC742C", "#FCAC40", "#AC742C"),
    ("hamburguer", hamburguer, "#CC5418", "#A82C04", "#CC5418", "#A82C04"),
    ("panda", panda, "#F0F0F0", "#ACACAC", "#3C403C", "#201C20"),
    ("frankenstein", frankenstein, "#ACD4A8", "#246478", "#ACD4A8", "#246478"),
    ("mumia", mumia, "#E4FCF0", "#ACD8A8", "#FCFCE4", "#ACD8A8"),
    ("sino", sino, "#CCA420", "#AC8410", "#CCA420", "#AC8410"),
    ("engrenagem", engrenagem, "#7C7470", "#645858", "#7C7470", "#645858"),
    ("caveira", caveira, "#684C24", "#5C3C20", "#D8D0A8", "#BCA484"),
    ("crocodilo", crocodilo, "#608434", "#304828", "#608434", "#304828"),
    ("donut", donut, "#B8744C", "#884830", "#B8744C", "#884830"),
]
