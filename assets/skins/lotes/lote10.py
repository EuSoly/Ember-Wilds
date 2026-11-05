# Lote 10 — skins de corpo (detalhadas e simples com toque). Montar com build_skins.py ou render_lote.py.
# tomate, geodo, cantil, coroa_flores, presente, frasco_limo, portal_pedra, torradeira, amanita, explorador.
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


def _reg_poly(cx, cy, r, n=8, rot_deg=0.0):
    rot = math.radians(rot_deg)
    return [
        (cx + r * math.cos(rot + 2 * math.pi * i / n),
         cy + r * math.sin(rot + 2 * math.pi * i / n))
        for i in range(n)
    ]


def _anel_quads(s, cx, cy, r_in, r_out, z, thick, color, n=16, rot_deg=0.0):
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


# ---------------------------------------------------------------- 1. Tomate (ref. 25)
def tomate(s):
    s.base()
    # Brilho oval vermelho-claro (#D44024) no lado esquerdo da câmera (+X, -Y)
    s.flat(ellipse(0.95, -0.58, 0.68, 0.54, 20, rot=math.radians(15)),
           TOP, 0.003, "#D44024", smooth=False)

    # Sombra vermelha escura (#681404) sob as sépalas do cálice
    sombra_calice = _chaikin([
        (1.42, -1.65), (0.95, -0.95), (0.22, 0.12),
        (-0.62, -0.82), (-1.28, -0.95), (-1.38, -1.65),
    ], 1)
    s.flat(sombra_calice, TOP + 0.003, 0.006, "#681404", smooth=False)

    # Cálice de folhas verdes (#207C2C, contorno #085C18) amplo no topo/trás
    folhas_calice = [
        # Folha traseira alta saindo bastante para trás
        [(0.78, -1.45), (0.92, -2.38), (0.15, -2.22), (-0.22, -1.45)],
        # Folha traseira esquerda (+X)
        [(0.35, -1.35), (1.58, -1.72), (1.08, -1.12), (0.15, -1.05)],
        # Folha lateral esquerda (+X)
        [(0.25, -1.15), (1.32, -0.82), (0.65, -0.55), (0.0, -0.85)],
        # Folha central longa apontando para a testa
        [(0.42, -0.95), (0.22, 0.05), (-0.15, -0.28), (-0.32, -0.95)],
        # Folha lateral direita (-X)
        [(-0.05, -0.95), (-1.22, -0.62), (-0.98, -1.18), (-0.25, -1.25)],
        # Folha traseira direita (-X)
        [(-0.05, -1.25), (-1.45, -1.58), (-0.65, -1.88), (0.25, -1.55)],
    ]
    # Base das folhas com contorno #085C18
    for pts_f in folhas_calice:
        s.flat(_chaikin(pts_f, 1), 0.95, 1.09, "#207C2C", outline="#085C18", ow=0.10, smooth=False)
    # Camada superior contínua (#207C2C sem outline) para unir todas as folhas sem costuras internas!
    for pts_f in folhas_calice:
        s.flat(_chaikin(pts_f, 1), 2.046, 0.02, "#207C2C", smooth=False)
    s.flat(ellipse(0.05, -1.15, 0.78, 0.56, 20), 2.046, 0.02, "#207C2C", smooth=False)


# ---------------------------------------------------------------- 2. Geodo / Aglomerado de Cristais (ref. 42)
def geodo(s):
    s.base()
    # Cristais de fundo rasos (z_top = 2.003, sem outline) perto dos olhos para preencher sem cortar olhos
    s.flat(_reg_poly(0.18, 0.35, 0.58, 7, 10), TOP, 0.002, "#68DCDC", smooth=False)
    s.flat(_reg_poly(0.18, 0.35, 0.36, 7, 10), TOP + 0.002, 0.001, "#90ECE8", smooth=False)
    s.flat(_reg_poly(-0.18, 0.95, 0.58, 8, 15), TOP, 0.002, "#847C28", smooth=False)
    s.flat(_reg_poly(-0.18, 0.95, 0.40, 8, 15), TOP + 0.002, 0.001, "#C0BC48", smooth=False)

    # Nódulos de rocha cinza-esverdeada (#58645C, miolo #74807C, contorno #585840) fora dos olhos
    rochas = [
        (1.38, -1.18, 0.72, 0.75, 1.27),
        (1.58, 0.35, 0.52, 0.75, 1.27),
        (-0.15, -0.28, 0.52, 0.85, 1.17),
        (-1.38, 1.28, 0.56, 0.75, 1.27),
    ]
    for rx, ry, rr, rz, rth in rochas:
        s.flat(_reg_poly(rx, ry, rr, 8, 22), rz, rth, "#58645C", outline="#585840", ow=0.08, smooth=False)
        s.flat(_reg_poly(rx, ry, rr * 0.62, 8, 22), rz + rth + 0.006, 0.004, "#74807C", smooth=False)

    # Cristais ciano (#68DCDC, miolo #90ECE8, contorno #585840)
    cianos = [
        (-0.95, -1.25, 0.78, 0.80, 1.23),
        (1.25, -0.45, 0.62, 0.80, 1.23),
        (-1.55, 0.68, 0.48, 0.80, 1.23),
    ]
    for cx, cy, cr, cz, cth in cianos:
        s.flat(_reg_poly(cx, cy, cr, 7, 10), cz, cth, "#68DCDC", outline="#585840", ow=0.08, smooth=False)
        s.flat(_reg_poly(cx, cy, cr * 0.58, 7, 10), cz + cth + 0.006, 0.004, "#90ECE8", smooth=False)

    # Cristais dourado-oliva (#C0BC48, borda #847C28, contorno #585840)
    dourados = [
        (0.05, -1.18, 0.76, 0.85, 1.19),
        (-1.22, -0.48, 0.68, 0.88, 1.17),
    ]
    for dx, dy, dr, dz, dth in dourados:
        s.flat(_reg_poly(dx, dy, dr, 8, 15), dz, dth, "#847C28", outline="#585840", ow=0.08, smooth=False)
        s.flat(_reg_poly(dx, dy, dr * 0.70, 8, 15), dz + dth + 0.006, 0.004, "#C0BC48", smooth=False)

    # Prismas lilás (#C074DC, faceta #CC94E4)
    lilas = [
        (0.68, -1.05, 0.48, 0.85, 25, 0.88, 1.17),
        (-1.45, 0.12, 0.38, 0.68, -35, 0.88, 1.16),
        (1.28, 1.22, 0.42, 0.72, 30, 0.85, 1.19),
    ]
    for lx, ly, lw, lh, lang, lz, lth in lilas:
        s.flat(_chaikin(_barra_rot(lx, ly, lw, lh, lang), 1), lz, lth, "#C074DC", outline="#585840", ow=0.06, smooth=False)
        s.flat(_chaikin(_barra_rot(lx + 0.05, ly - 0.04, lw * 0.55, lh * 0.75, lang), 1), lz + lth + 0.006, 0.004, "#CC94E4", smooth=False)


# ---------------------------------------------------------------- 3. Cantil / Garrafa d'Água (ref. 53)
def cantil(s):
    s.base()
    # Gargalo de vidro (#C0BCC0) e rolha de cortiça (#C08034 / #B0742C) bem salientes no topo/trás
    s.flat(_chaikin(_rect(0.0, -2.08, 0.66, 0.72), 1), 0.75, 1.25, "#B0742C", outline="#8C581C", ow=0.06, smooth=False)
    s.flat(_chaikin(_rect(0.0, -2.06, 0.42, 0.48), 1), 2.006, 0.02, "#C08034", smooth=False)
    s.flat(_chaikin(_rect(0.0, -1.78, 0.94, 0.36), 1), 0.70, 1.33, "#C0BCC0", outline="#98989C", ow=0.06, smooth=False)

    # Espaço de ar azul-claro (#A0CCE8) na metade traseira da garrafa
    ar_topo = _chaikin([
        (-1.62, -0.15), (-1.62, -1.42), (-1.15, -1.62),
        (1.15, -1.62), (1.62, -1.42), (1.62, -0.15),
    ], 2)
    s.flat(ar_topo, TOP, 0.002, "#A0CCE8", smooth=False)

    # Faixa ondulada de água azul-média (#70B4DC) no meio da garrafa (z_top = 2.004)
    onda_meio = _chaikin([
        (-1.64, 0.25), (-1.64, -0.35), (-1.15, -0.25), (-0.55, -0.42),
        (0.0, -0.22), (0.55, -0.38), (1.15, -0.22), (1.64, -0.35),
        (1.64, 0.25), (1.05, 0.12), (0.35, 0.28), (-0.35, 0.12), (-1.05, 0.28),
    ], 2)
    s.flat(onda_meio, TOP + 0.002, 0.002, "#70B4DC", smooth=False)

    # Dois reflexos brancos de vidro (#FCFCFC) na parte superior
    s.flat(_chaikin(_rect(1.08, -1.12, 0.56, 0.34), 2), TOP + 0.005, 0.015, "#FCFCFC", smooth=False)
    s.flat(_chaikin(_rect(-0.22, -1.12, 1.48, 0.34), 2), TOP + 0.005, 0.015, "#FCFCFC", smooth=False)


# ---------------------------------------------------------------- 4. Coroa de Flores (ref. 125)
def _flor_5petalas(s, cx, cy, r_fl, cor_petala, cor_borda, cor_miolo, z_base, rot_deg=0.0):
    """Desenha uma flor detalhada com 5 pétalas arredondadas e miolo em relevo."""
    # Camada base das pétalas com contorno suave
    for i in range(5):
        ang = math.radians(rot_deg + i * 72)
        px = cx + r_fl * 0.55 * math.cos(ang)
        py = cy + r_fl * 0.55 * math.sin(ang)
        s.flat(ellipse(px, py, r_fl * 0.48, r_fl * 0.38, 12, rot=ang),
               z_base, 0.022, cor_petala, outline=cor_borda, ow=0.035, smooth=False)
    # Camada superior das pétalas (sem contorno interno, unindo a flor)
    for i in range(5):
        ang = math.radians(rot_deg + i * 72)
        px = cx + r_fl * 0.52 * math.cos(ang)
        py = cy + r_fl * 0.52 * math.sin(ang)
        s.flat(ellipse(px, py, r_fl * 0.44, r_fl * 0.35, 12, rot=ang),
               z_base + 0.028, 0.012, cor_petala, smooth=False)
    # Miolo redondo em relevo no centro da flor
    s.flat(ellipse(cx, cy, r_fl * 0.34, r_fl * 0.34, 14),
           z_base + 0.040, 0.022, cor_miolo, outline=cor_borda, ow=0.025, smooth=False)


def coroa_flores(s):
    s.base()
    # Tufos de grama pontiagudos nas laterais inferiores (z_top da base = 1.78, abaixo do chanfro 1.82!)
    for ty0, ty1, tx_out, ty_tip in [(0.15, 0.75, 2.22, 0.48), (0.85, 1.62, 2.18, 1.38)]:
        tufo_g = [(1.45, ty0), (tx_out, ty_tip), (1.45, ty1)]
        s.sym(tufo_g, 0.45, 1.32, "#3CC444", outline="#309828", ow=0.09, smooth=False)
        s.sym(tufo_g, 1.77, 0.18, "#3CC444", smooth=False)

    # Base de folhagem da guirlanda: folhas verdes pontiagudas (#2CBC70 e #309828) ao longo do arco da testa
    folhas_coroa = [
        (1.58, -0.35, 0.48, 0.24, -35, "#309828"),
        (1.42, -0.82, 0.48, 0.24, 25, "#2CBC70"),
        (0.95, -0.25, 0.46, 0.22, -25, "#2CBC70"),
        (0.68, -0.92, 0.48, 0.24, 30, "#309828"),
        (0.22, -0.28, 0.45, 0.22, -18, "#309828"),
        (-0.22, -0.95, 0.48, 0.24, 15, "#2CBC70"),
        (-0.68, -0.28, 0.46, 0.22, 25, "#2CBC70"),
        (-0.98, -0.92, 0.48, 0.24, -30, "#309828"),
        (-1.42, -0.82, 0.48, 0.24, -25, "#2CBC70"),
        (-1.58, -0.35, 0.48, 0.24, 35, "#309828"),
    ]
    for lx, ly, lw, lh, lang, lcol in folhas_coroa:
        a = math.radians(lang)
        ca, sa = math.cos(a), math.sin(a)
        pts_folha = _chaikin([
            (lx - lw * 0.55 * ca, ly - lw * 0.55 * sa),
            (lx - lh * 0.5 * sa, ly + lh * 0.5 * ca),
            (lx + lw * 0.55 * ca, ly + lw * 0.55 * sa),
            (lx + lh * 0.5 * sa, ly - lh * 0.5 * ca),
        ], 1)
        s.flat(pts_folha, TOP + 0.004, 0.018, lcol, outline="#1C6820", ow=0.04, smooth=False)

    # 5 flores grandes detalhadas de 5 pétalas compondo a coroa de flores
    flores_grandes = [
        (1.25, -0.52, 0.38, "#F868B8", "#B03878", "#F0DC30", 12),
        (0.62, -0.62, 0.40, "#FCFCFC", "#88A06C", "#F0DC30", 35),
        (0.0, -0.52, 0.42, "#D81C20", "#881818", "#F0DC30", 0),
        (-0.62, -0.62, 0.40, "#3090D8", "#1C5888", "#F0DC30", 22),
        (-1.25, -0.52, 0.38, "#F868B8", "#B03878", "#F0DC30", -15),
    ]
    for fx, fy, fr, c_pet, c_bor, c_mio, rot_d in flores_grandes:
        _flor_5petalas(s, fx, fy, fr, c_pet, c_bor, c_mio, TOP + 0.025, rot_deg=rot_d)

    # 4 botõezinhos de flor amarelos e azuis entre as flores principais
    botoes = [
        (0.95, -0.78, 0.16, "#F0DC30", "#988818"),
        (0.32, -0.82, 0.16, "#3090D8", "#1C5888"),
        (-0.32, -0.82, 0.16, "#F0DC30", "#988818"),
        (-0.95, -0.78, 0.16, "#FCFCFC", "#88A06C"),
    ]
    for bx, by, br, bcol, bbor in botoes:
        s.flat(ellipse(bx, by, br, br, 12), TOP + 0.022, 0.02, bcol, outline=bbor, ow=0.03, smooth=False)


# ---------------------------------------------------------------- 5. Presente (ref. 128)
def presente(s):
    s.base()
    # Fita vertical verde (#20A44C, contorno #1C8C48) passando entre os olhos sem tocá-los (|x| <= 0.25)
    s.flat(_chaikin(_rect(0.0, 0.0, 0.50, 3.88), 1),
           0.40, 1.62, "#20A44C", outline="#1C8C48", ow=0.06, smooth=False)

    # Fita horizontal verde (#20A44C, contorno #1C8C48) atrás dos olhos (y = -0.58)
    s.flat(_chaikin(_rect(0.0, -0.58, 3.92, 0.68), 1),
           0.55, 1.48, "#20A44C", outline="#1C8C48", ow=0.09, smooth=False)

    # Laço verde de 4 alças e nó central no cruzamento (0, -0.58)
    for sx in (-1, 1):
        for sy, ang in [(-0.38, sx * 38), (0.32, sx * -38)]:
            s.flat(_chaikin(_barra_rot(sx * 0.42, -0.58 + sy, 0.62, 0.52, ang), 2),
                   2.035, 0.04, "#20A44C", outline="#1C8C48", ow=0.08, smooth=False)
    s.flat(_chaikin(_rect(0.0, -0.58, 0.54, 0.54), 2),
           2.085, 0.045, "#20A44C", outline="#1C8C48", ow=0.08, smooth=False)


# ---------------------------------------------------------------- 6. Frasco de Limo (ref. 143)
def frasco_limo(s):
    s.base()
    # Sombra líquido azul-acinzentada (#C0D0E0) na parte frontal e ao redor dos olhos (z_top <= 2.003)
    s.flat(_chaikin(_rect(0.0, 1.05, 3.25, 1.15), 2), TOP, 0.002, "#C0D0E0", smooth=False)
    s.sym(ellipse(0.80, 0.58, 0.62, 0.58, 20), TOP + 0.002, 0.002, "#808894", smooth=False)

    # 4 bolhas de limo verde-neon (#00E460, miolo #90F4B8, pintas #10B058) borbulhando no topo/trás
    # Bolha traseira central-direita (-X, -Y)
    s.flat(ellipse(-0.22, -1.78, 0.76, 0.65, 22), 0.80, 1.18, "#00E460", outline="#10B058", ow=0.05, smooth=False)
    s.flat(ellipse(-0.22, -1.72, 0.50, 0.40, 18), 1.988, 0.015, "#90F4B8", smooth=False)
    # Bolha pequena traseira esquerda (+X, -Y)
    s.flat(ellipse(1.32, -1.68, 0.36, 0.36, 16), 0.85, 1.12, "#00E460", outline="#10B058", ow=0.04, smooth=False)
    s.flat(ellipse(1.28, -1.65, 0.24, 0.24, 14), 1.978, 0.015, "#90F4B8", smooth=False)
    # Bolha média no canto superior direito da imagem (-X)
    s.flat(ellipse(-1.12, -0.95, 0.56, 0.54, 20), 1.15, 0.90, "#00E460", outline="#10B058", ow=0.05, smooth=False)
    s.flat(ellipse(-1.08, -0.90, 0.38, 0.36, 16), 2.058, 0.02, "#90F4B8", smooth=False)
    # Grande bolha de limo na testa esquerda da imagem (+X)
    s.flat(ellipse(0.68, -0.68, 0.96, 0.82, 24), 1.20, 0.86, "#00E460", outline="#10B058", ow=0.05, smooth=False)
    s.flat(ellipse(0.58, -0.58, 0.66, 0.54, 20), 2.068, 0.02, "#90F4B8", smooth=False)
    # Manchinhas circulares dentro das bolhas de limo
    for mx, my, mr, mcol in [
        (0.95, -1.12, 0.16, "#10B058"),
        (1.28, -0.78, 0.11, "#10B058"),
        (1.02, -0.45, 0.12, "#68B498"),
        (0.02, -0.55, 0.14, "#68B498"),
        (-0.88, -0.78, 0.10, "#68B498"),
    ]:
        s.flat(ellipse(mx, my, mr, mr, 12), 2.09, 0.015, mcol, smooth=False)


# ---------------------------------------------------------------- 7. Portal de Pedra (ref. 231)
def portal_pedra(s):
    s.base()
    # Parede interna azul-petróleo escuro (#1C4044) no fundo da câmara central
    s.flat(_chaikin(_rect(0.0, -0.55, 1.95, 0.55), 1), TOP, 0.003, "#1C4044", smooth=False)

    # Anel de blocos de pedra esculpidos (#A09C9C e #848484, contorno #606060) ao redor da borda
    # Bloco traseiro central
    s.flat(_chaikin([(-0.48, -1.92), (0.48, -1.92), (0.35, -0.92), (-0.35, -0.92)], 1),
           0.55, 1.48, "#A09C9C", outline="#606060", ow=0.09, smooth=False)
    # Blocos diagonais traseiros
    s.sym(_chaikin([(0.52, -1.85), (1.35, -1.72), (0.95, -0.88), (0.42, -0.92)], 1),
          0.55, 1.46, "#848484", outline="#606060", ow=0.09, smooth=False)
    # Blocos de canto traseiros
    s.sym(_chaikin([(1.38, -1.58), (1.92, -0.88), (1.12, -0.52), (0.95, -0.82)], 1),
          0.55, 1.46, "#848484", outline="#606060", ow=0.09, smooth=False)
    # Blocos laterais médios (claros)
    s.sym(_chaikin([(1.95, -0.45), (1.95, 0.45), (1.15, 0.35), (1.15, -0.35)], 1),
          0.55, 1.48, "#A09C9C", outline="#606060", ow=0.09, smooth=False)
    # Blocos de canto frontais (fora do raio dos olhos, z_top = 2.025 sólido!)
    s.sym(_chaikin([(1.92, 0.55), (1.45, 1.72), (1.12, 1.25), (1.35, 0.55)], 1),
          0.55, 1.47, "#848484", outline="#606060", ow=0.08, smooth=False)
    # Bloco frontal central entre os olhos (|x| <= 0.24 perto dos olhos, z_top = 2.025 sólido!)
    s.flat(_chaikin([(-0.24, 0.72), (0.24, 0.72), (0.42, 1.88), (-0.42, 1.88)], 1),
           0.55, 1.47, "#A09C9C", outline="#606060", ow=0.07, smooth=False)


# ---------------------------------------------------------------- 8. Torradeira (ref. 233)
def torradeira(s):
    s.base()
    # 2 pezinhos marrons arredondados (#7C483C, contorno #502C28) saindo na frente
    s.sym(_chaikin(_rect(0.78, 1.88, 0.52, 0.52), 2),
          0.20, 1.45, "#7C483C", outline="#502C28", ow=0.09, smooth=False)

    # Alavanca lateral clássica da torradeira na direita da imagem (-X)
    s.flat(_chaikin(_rect(-1.95, 0.15, 0.42, 0.24), 1),
           0.85, 0.95, "#A46448", outline="#502C28", ow=0.07, smooth=False)
    s.flat(_chaikin(_rect(-2.16, 0.15, 0.36, 0.52), 2),
           0.80, 1.05, "#502C28", outline="#381C18", ow=0.06, smooth=False)

    # Painel metálico superior da torradeira (#A46448) e fenda escura (#502C28) de onde sai a torrada
    s.flat(_chaikin(_rect(0.0, 0.05, 3.28, 3.05), 2), TOP, 0.003, "#A46448", smooth=False)
    s.flat(_chaikin(_rect(0.0, -0.02, 2.88, 0.52), 2), TOP + 0.003, 0.012, "#502C28", smooth=False)

    # Fatia de pão de forma tostada saindo da fenda (formato clássico de pão de forma com 2 curvas no topo!)
    casca_pao = _chaikin([
        (-1.35, 0.08), (-1.35, -0.95),
        (-1.58, -1.35), (-1.42, -1.88), (-0.75, -2.06),
        (0.0, -1.88),
        (0.75, -2.06), (1.42, -1.88), (1.58, -1.35),
        (1.35, -0.95), (1.35, 0.08),
    ], 2)
    s.flat(casca_pao, 0.95, 1.12, "#B86828", outline="#984C24", ow=0.11, smooth=False)

    # Miolo dourado-claro da torrada (#FCCC84 com borda tostada #E49824)
    borda_tostada = _chaikin([
        (-1.16, -0.02), (-1.16, -0.95),
        (-1.35, -1.32), (-1.20, -1.72), (-0.68, -1.86),
        (0.0, -1.70),
        (0.68, -1.86), (1.20, -1.72), (1.35, -1.32),
        (1.16, -0.95), (1.16, -0.02),
    ], 2)
    s.flat(borda_tostada, 2.076, 0.015, "#E49824", smooth=False)

    miolo_pao = _chaikin([
        (-0.98, -0.10), (-0.98, -0.95),
        (-1.14, -1.28), (-1.02, -1.58), (-0.58, -1.70),
        (0.0, -1.55),
        (0.58, -1.70), (1.02, -1.58), (1.14, -1.28),
        (0.98, -0.95), (0.98, -0.10),
    ], 2)
    s.flat(miolo_pao, 2.091, 0.015, "#FCCC84", smooth=False)

    # Marquinhas horizontais de tostado (#D07824) e quadradinho de manteiga derretendo no centro!
    for ty, tw in [(-1.35, 1.35), (-0.42, 1.45)]:
        s.flat(_chaikin(_rect(0.0, ty, tw, 0.12), 1), 2.106, 0.01, "#D07824", smooth=False)
    # Poça de manteiga derretida (#E8A858) e tablete de manteiga (#FCCC84 com contorno #D07824)
    s.flat(ellipse(0.05, -0.88, 0.58, 0.44, 18, rot=math.radians(12)), 2.106, 0.012, "#E8A858", smooth=False)
    s.flat(_chaikin(_barra_rot(0.0, -0.88, 0.56, 0.48, 14), 1),
           2.118, 0.03, "#FCCC84", outline="#D07824", ow=0.05, smooth=False)


# ---------------------------------------------------------------- 9. Amanita / Cogumelo Pintado (ref. 237)
def amanita(s):
    s.base()
    # Sombra do chapéu sobre o caule bege (#584438 e #B08874) com z_top <= 2.003
    s.flat(_chaikin(_rect(0.0, 0.45, 3.15, 0.75), 2), TOP, 0.002, "#B08874", smooth=False)
    s.flat(_chaikin(_rect(0.0, 0.22, 3.15, 0.45), 2), TOP + 0.002, 0.002, "#584438", smooth=False)

    # Grande chapéu abaulado vermelho (#A8302C base, #C83828 topo, contorno #782020) cobrindo trás e laterais
    chapeu_base = _chaikin([
        (-2.02, 0.05), (-2.05, -0.75), (-1.58, -1.58), (-0.82, -1.98),
        (0.0, -2.08), (0.82, -1.98), (1.58, -1.58), (2.05, -0.75),
        (2.02, 0.05), (1.05, 0.24), (0.0, 0.28), (-1.05, 0.24),
    ], 2)
    s.flat(chapeu_base, 0.90, 1.15, "#A8302C", outline="#782020", ow=0.11, smooth=False)

    chapeu_luz = _chaikin([
        (-1.72, -0.35), (-1.42, -1.38), (-0.75, -1.82),
        (0.0, -1.92), (0.75, -1.82), (1.42, -1.38),
        (1.72, -0.35), (0.85, -0.12), (-0.85, -0.12),
    ], 2)
    s.flat(chapeu_luz, 2.056, 0.025, "#C83828", smooth=False)

    # 14 pintas creme-rosadas (#F8D8C8) espalhadas pelo chapéu
    pintas = [
        (0.62, -1.58, 0.34, 0.24, -12),
        (-0.12, -1.65, 0.32, 0.22, 10),
        (-1.05, -1.38, 0.32, 0.22, 28),
        (0.15, -1.18, 0.18, 0.15, 0),
        (1.48, -1.08, 0.20, 0.14, -38),
        (-1.52, -0.92, 0.18, 0.13, 38),
        (0.85, -0.78, 0.26, 0.24, 0),
        (-0.68, -0.72, 0.30, 0.26, 0),
        (1.72, -0.45, 0.22, 0.28, -15),
        (-1.45, -0.42, 0.20, 0.22, 15),
        (0.22, -0.32, 0.16, 0.15, 0),
        (0.82, -0.18, 0.20, 0.18, 0),
        (-0.35, -0.18, 0.22, 0.20, 0),
        (-0.88, 0.02, 0.16, 0.15, 0),
    ]
    for px, py, rx, ry, rot_d in pintas:
        s.flat(ellipse(px, py, rx, ry, 16, rot=math.radians(rot_d)), 2.082, 0.02, "#F8D8C8", smooth=False)


# ---------------------------------------------------------------- 10. Explorador / Óculos e Folhas (ref. 254)
def explorador(s):
    s.base()
    # Dobra traseira do capuz marrom (#644828, contorno #342814)
    s.flat(_chaikin(_rect(0.0, -1.55, 3.18, 0.95), 2),
           0.65, 1.32, "#644828", outline="#342814", ow=0.10, smooth=False)
    # Divisória curvada do capuz na testa (y = -1.05)
    s.flat(_chaikin(_rect(0.0, -1.08, 3.45, 0.16), 1), TOP, 0.015, "#342814", smooth=False)

    # Tira dos óculos de aviador cruzando as laterais e o meio (z + thick + 0.005 = 2.000 perto dos olhos)
    s.flat(_chaikin(_rect(0.0, 0.55, 3.88, 0.62), 1),
           0.65, 1.345, "#644828", outline="#342814", ow=0.09, smooth=False)

    # 2 folhas verdes vibrantes (#088050, contorno #046448) presas na lateral esquerda da imagem (+X)
    folha_1 = _chaikin([(1.25, 0.35), (2.28, -0.38), (1.98, 0.58), (1.35, 0.75)], 1)
    folha_2 = _chaikin([(0.95, 0.15), (1.38, -0.85), (1.68, -0.05), (1.15, 0.35)], 1)
    s.flat(folha_2, 0.85, 1.18, "#088050", outline="#046448", ow=0.07, smooth=False)
    s.flat(folha_1, 0.90, 1.16, "#088050", outline="#046448", ow=0.07, smooth=False)

    # Aros redondos dos óculos de aviador ao redor dos dois olhos (±0.80, 0.55)
    # Feitos com trapézios convexos (_anel_quads) com r_in = 0.48 para os olhos ficarem 100% livres!
    for sx in (-1, 1):
        _anel_quads(s, sx * 0.80, 0.55, 0.48, 0.82, TOP + 0.005, 0.025, "#342814", n=20)
        _anel_quads(s, sx * 0.80, 0.55, 0.53, 0.74, TOP + 0.030, 0.015, "#644828", n=20)


LOTE = [
    ("tomate", tomate, "#D02808", "#902414", "#D02808", "#902414"),
    ("geodo", geodo, "#58645C", "#585840", "#68DCDC", "#585840"),
    ("cantil", cantil, "#4CA0D0", "#C0BCC0", "#4CA0D0", "#C0BCC0"),
    ("coroa_flores", coroa_flores, "#3CC444", "#309828", "#3CC444", "#309828"),
    ("presente", presente, "#C4202C", "#AC2028", "#20A44C", "#1C8C48"),
    ("frasco_limo", frasco_limo, "#DCF0F4", "#187484", "#00E460", "#10B058"),
    ("portal_pedra", portal_pedra, "#186470", "#606060", "#A09C9C", "#606060"),
    ("torradeira", torradeira, "#7C483C", "#502C28", "#7C483C", "#502C28"),
    ("amanita", amanita, "#BCA07C", "#7C5048", "#BCA07C", "#7C5048"),
    ("explorador", explorador, "#644828", "#342814", "#644828", "#342814"),
]
