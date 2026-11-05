# Lote 1 de MOCHILAS (10 temas). Base em mochila_lib.py (com boneco fantasma PREVIEW_*).
# padrao, coelho, ninho_passaros, aquario, esquilo, vulcao, lenha, minerios, barril, bau.
from mochila_lib import *

TIPO = "mochila"


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


def _olho(m, cx, cy, r, z, shine_dx=0.32, shine_dy=-0.30):
    """Olhinho de bicho da mochila (preto com brilho branco; faz parte da mochila!)."""
    m.flat(ellipse(cx, cy, r, r, 16), z, 0.025, "#111111", smooth=False)
    m.flat(ellipse(cx + r * shine_dx, cy + r * shine_dy, r * 0.36, r * 0.36, 12),
           z + 0.025, 0.015, "#FFFFFF", smooth=False)


# ---------------------------------------------------------------- 1. Padrão (ref. 0)
def padrao(m):
    m.base(w=2.56, d=1.24, h=MH, r=0.42, body_color="#842C08", outline_color="#481C10")
    # Alça trapezoidal traseira (-Y) da mochila padrão
    alca_tras = [
        (-0.72, -0.55), (0.72, -0.55),
        (0.52, -1.02), (-0.52, -1.02),
    ]
    m.flat(alca_tras, Z0 + 0.25, MH - 0.30, "#802C08", outline="#481C10", ow=0.10, smooth=False)
    # Bolso/fecho ovalado no topo da mochila
    m.flat(_chaikin(_rect(0.0, 0.18, 1.15, 0.36), 2),
           TOPO, 0.03, "#78280C", outline="#481C10", ow=0.08, smooth=False)


# ---------------------------------------------------------------- 2. Coelho (ref. 1)
def coelho(m):
    m.base_aberta()
    # Cabeça redonda rosa do coelho (#F094BC com contorno branco #FCFCFC) saindo da bolsa
    m.flat(ellipse(0.0, -0.42, 0.84, 0.78, 24), Z0 + 0.25, MH - 0.20,
           "#F094BC", outline="#FCFCFC", ow=0.10, smooth=False)
    # 2 orelhas longas rosas inclinadas para trás (-Y) com contorno branco
    orelha_c = _chaikin([
        (0.22, -0.88), (0.48, -1.58), (0.98, -2.08),
        (1.22, -1.92), (1.05, -1.35), (0.58, -0.75),
    ], 2)
    m.sym(orelha_c, Z0 + 0.25, MH - 0.20, "#F094BC", outline="#FCFCFC", ow=0.09, smooth=False)
    # Unir cabeça e orelhas no topo sem costura
    m.flat(ellipse(0.0, -0.42, 0.84, 0.78, 24), TOPO + 0.056, 0.015, "#F094BC", smooth=False)
    m.sym(orelha_c, TOPO + 0.056, 0.015, "#F094BC", smooth=False)

    # Olhinhos pretos com brilho branco (bem separados das patinhas)
    _olho(m, 0.36, -0.68, 0.23, TOPO + 0.072)
    _olho(m, -0.36, -0.68, 0.23, TOPO + 0.072)

    # 2 patinhas ovais rosas com borda branca grossa apoiadas na borda da bolsa (+Y)
    for sx in (-1, 1):
        pata = ellipse(sx * 0.36, 0.24, 0.24, 0.36, 18, rot=math.radians(sx * 10))
        m.flat(pata, TOPO + 0.072, 0.035, "#F094BC", outline="#FCFCFC", ow=0.08, smooth=False)


# ---------------------------------------------------------------- 3. Ninho de Pássaros (ref. 2)
def ninho_passaros(m):
    m.base_aberta()
    # Ninho de gravetos trançados (#905828 / #A86C40, contorno #5C3414) com galhos saindo na direita (-X)
    ninho_base = _chaikin([
        (1.28, -0.05), (1.05, 0.48), (0.0, 0.58), (-0.95, 0.45),
        (-1.58, -0.05), (-1.45, -0.35), (-1.15, -0.22), (-1.28, -0.58),
        (-0.88, -0.35), (-0.92, -0.65), (-0.45, -0.45),
        (0.55, -0.55), (1.12, -0.35),
    ], 2)
    m.flat(ninho_base, TOPO + 0.02, 0.04, "#905828", outline="#5C3414", ow=0.06, smooth=False)
    # Camadas claras de gravetos trançados (#A86C40 e #B0784C)
    for gy, gw in [(0.35, 1.45), (0.10, 1.68), (-0.12, 1.55)]:
        m.flat(_chaikin(_barra_rot(0.05, gy, gw, 0.24, -6), 2), TOPO + 0.066, 0.015, "#A86C40", smooth=False)

    # 2 pintinhos amarelos (#E8D830, contorno #D4BC18) dentro do ninho
    for px, py, r_p, b_dx, b_dy, b_ang in [
        (0.45, -0.58, 0.52, 0.38, 0.02, 10),
        (-0.48, -0.52, 0.48, -0.38, -0.05, -15),
    ]:
        m.flat(ellipse(px, py, r_p, r_p * 0.92, 20), Z0 + 0.35, MH - 0.30,
               "#E8D830", outline="#D4BC18", ow=0.07, smooth=False)
        _olho(m, px + (0.08 if px > 0 else -0.08), py - 0.06, 0.16, TOPO + 0.058)
        # Bico bege-dourado (#C8A854)
        bico = _chaikin(_barra_rot(px + b_dx, py + b_dy, 0.26, 0.18, b_ang), 1)
        m.flat(bico, TOPO + 0.060, 0.02, "#C8A854", outline="#907028", ow=0.03, smooth=False)


# ---------------------------------------------------------------- 4. Aquário (ref. 3)
def aquario(m):
    # Base de couro escura segurando o aquário
    quad_base = [(-1.35, 0.65), (1.35, 0.65), (1.15, -0.25), (-1.15, -0.25)]
    m.flat(quad_base, Z0, MH - 0.04, "#5C3414", outline="#3C200C", ow=0.10, smooth=False)
    for sx in (-1, 1):
        m.flat([(sx * 1.02, 0.62), (sx * 1.32, 0.62), (sx * 1.12, -0.20), (sx * 0.88, -0.20)],
               TOPO - 0.02, 0.02, "#683C18", smooth=False)

    # Globo de vidro redondo do aquário (#ACD0E8, borda de vidro #C8DCE8)
    m.flat(ellipse(0.0, -0.32, 1.12, 1.08, 28), Z0 + 0.20, MH - 0.16,
           "#ACD0E8", outline="#C8DCE8", ow=0.09, smooth=False)
    # Brilho inferior claro da água (#C8DCE8) e abertura superior azul (#50A8E0)
    m.flat(ellipse(-0.08, 0.08, 0.68, 0.56, 20), TOPO + 0.046, 0.008, "#C8DCE8", smooth=False)
    m.flat(ellipse(-0.08, -0.68, 0.62, 0.42, 20), TOPO + 0.046, 0.010, "#50A8E0", outline="#98C4DC", ow=0.05, smooth=False)

    # Peixinho dourado vermelho-laranja (#F02C24, contorno #C0140C, barbatanas #F88820) nadando
    # Cauda e barbatanas
    cauda_p = _chaikin([(0.35, -0.48), (0.92, -0.62), (0.72, -0.25)], 1)
    m.flat(cauda_p, TOPO + 0.058, 0.018, "#F88820", outline="#C0140C", ow=0.04, smooth=False)
    barb_cima = _chaikin([(0.22, -0.58), (-0.05, -0.95), (-0.42, -0.68), (0.15, -0.45)], 1)
    m.flat(barb_cima, TOPO + 0.058, 0.018, "#F88820", outline="#C0140C", ow=0.04, smooth=False)
    # Corpo curvado do peixinho
    corpo_p = _chaikin([
        (0.45, -0.48), (0.05, -0.62), (-0.58, -0.52),
        (-0.82, -0.25), (-0.48, -0.08), (0.05, -0.28),
    ], 2)
    m.flat(corpo_p, TOPO + 0.078, 0.022, "#F02C24", outline="#C0140C", ow=0.04, smooth=False)
    _olho(m, -0.45, -0.28, 0.12, TOPO + 0.102)

    # Reflexo branco curvado do vidro (#EDF8FC) na direita (-X)
    reflexo_v = _chaikin([(-0.68, -0.75), (-0.88, -0.25), (-0.65, 0.28), (-0.52, -0.25)], 2)
    m.flat(reflexo_v, TOPO + 0.105, 0.010, "#EDF8FC", smooth=False)


# ---------------------------------------------------------------- 5. Esquilo (ref. 8)
def esquilo(m):
    m.base_aberta()
    # Grande rabo felpudo enrolado atrás/direita (-X, -Y) (#C47C28 com faixa #E0A064 e contorno #A86404)
    rabo_esq = _chaikin([
        (-0.25, -0.35), (-0.15, -1.45), (-0.55, -1.92), (-1.25, -1.92),
        (-1.58, -1.52), (-1.35, -1.12), (-0.85, -1.12), (-0.75, -0.25),
    ], 2)
    m.flat(rabo_esq, Z0 + 0.20, MH - 0.18, "#C47C28", outline="#A86404", ow=0.09, smooth=False)
    rabo_luz = _chaikin([
        (-0.35, -0.45), (-0.32, -1.25), (-0.72, -1.45),
        (-1.12, -1.32), (-0.62, -1.05), (-0.65, -0.35),
    ], 2)
    m.flat(rabo_luz, TOPO + 0.026, 0.012, "#E0A064", smooth=False)

    # Orelhas pontudinhas e cabeça redonda do esquilo (#C47C28, contorno #A86404)
    for sx in (-1, 1):
        or_esq = _chaikin([
            (sx * 0.35, -0.82), (sx * 0.92, -0.95),
            (sx * 0.95, -0.48), (sx * 0.45, -0.42),
        ], 1)
        m.flat(or_esq, Z0 + 0.30, MH - 0.24, "#C47C28", outline="#A86404", ow=0.08, smooth=False)
    m.flat(ellipse(0.0, -0.45, 0.72, 0.65, 24), Z0 + 0.32, MH - 0.25,
           "#C47C28", outline="#A86404", ow=0.08, smooth=False)

    # Olhinhos, nariz marrom e 2 dentinhos brancos (#FCFCFC)
    _olho(m, 0.32, -0.55, 0.20, TOPO + 0.076)
    _olho(m, -0.32, -0.55, 0.20, TOPO + 0.076)
    m.flat(ellipse(0.0, -0.25, 0.14, 0.09, 12), TOPO + 0.076, 0.015, "#A86404", smooth=False)
    for sx in (-1, 1):
        m.flat(_chaikin(_rect(sx * 0.09, -0.04, 0.15, 0.22), 1), TOPO + 0.076, 0.02, "#FCFCFC", smooth=False)


# ---------------------------------------------------------------- 6. Vulcão (ref. 11)
def vulcao(m):
    # Cone rochoso facetado escuro (#40200C / #48280C, contorno #2C1408)
    cone_base = [
        (-1.42, 0.62), (1.42, 0.62),
        (1.22, -0.35), (0.72, -0.78),
        (-0.72, -0.78), (-1.22, -0.35),
    ]
    m.flat(cone_base, Z0, MH - 0.02, "#40200C", outline="#2C1408", ow=0.12, smooth=False)
    # Faceta lateral direita mais clara (#48280C) e borda interna da cratera (#543014)
    m.flat([(-1.35, 0.58), (0.05, 0.58), (0.08, -0.20), (-0.72, -0.72), (-1.18, -0.32)],
           TOPO - 0.015, 0.018, "#48280C", smooth=False)
    borda_cratera = [
        (-0.92, -0.28), (-0.58, -0.64), (0.58, -0.64),
        (0.88, -0.25), (0.08, -0.08),
    ]
    m.flat(borda_cratera, TOPO + 0.004, 0.015, "#543014", smooth=False)

    # Lava laranja incandescente (#FC7000, emit=0.35) na cratera e escorrendo pela encosta
    lava_cratera = [
        (-0.78, -0.30), (-0.50, -0.56), (0.50, -0.56),
        (0.72, -0.28), (0.08, -0.15),
    ]
    m.flat(lava_cratera, TOPO + 0.020, 0.02, "#FC7000", smooth=False, emit=0.35)
    rio_lava = [
        (-0.18, -0.20), (-0.42, -0.02), (-0.55, 0.62),
        (-0.32, 0.62), (-0.22, 0.02), (-0.02, -0.18),
    ]
    m.flat(rio_lava, Z0 + 0.05, MH - 0.01, "#FC7000", smooth=False, emit=0.35)

    # 3 bolhas amarelas brilhantes (#F0B800, emit=0.45) na lava
    for bx, by in [(0.35, -0.42), (-0.02, -0.35), (-0.38, -0.45)]:
        m.flat(ellipse(bx, by, 0.12, 0.08, 12), TOPO + 0.042, 0.015, "#F0B800", smooth=False, emit=0.45)


# ---------------------------------------------------------------- 7. Cesto de Lenha (ref. 16)
def lenha(m):
    # Fundo interno escuro do cesto onde as toras encaixam
    m.flat(_rect(0.0, -0.32, 1.96, 0.28), Z0 + 0.18, MH - 0.16, "#5C3414", outline="#44240C", ow=0.06, smooth=False)

    # Toras de lenha em alturas escalonadas (para cada tora ter contorno individual nítido),
    # com topo cortado mostrando os anéis claros da madeira e veios na casca!
    # (cx, cy, w, comp, ang_deg, z_step)
    toras = [
        # Fileira de trás (mais fundas)
        (0.70, -0.82, 0.42, 1.38, -14, 0.000),
        (0.08, -1.04, 0.44, 1.58, -5,  0.016),
        (-0.48, -0.88, 0.42, 1.42, 12, 0.032),
        # Fileira da frente (sobrepostas com contorno próprio)
        (-0.90, -0.66, 0.40, 1.32, 34, 0.048),
        (0.34, -0.56, 0.40, 1.12, -20, 0.064),
        (-0.18, -0.52, 0.40, 1.08, 6,  0.080),
    ]
    for tx, ty, tw, th, tang, dz in toras:
        zt = TOPO - 0.02 + dz
        # Corpo cilíndrico da tora com casca marrom-avermelhada (#7C340C) e contorno escuro (#4C1C04)
        corpo_tora = _chaikin(_barra_rot(tx, ty, tw, th, tang), 2)
        m.flat(corpo_tora, Z0 + 0.24, (zt - (Z0 + 0.24)), "#7C340C", outline="#4C1C04", ow=0.065, smooth=False)

        # Veios longitudinais da casca (faixa clara #944414 e fissura escura #582008)
        a_rad = math.radians(tang)
        dx_perp, dy_perp = math.cos(a_rad), math.sin(a_rad)
        dx_dir, dy_dir = math.sin(a_rad), -math.cos(a_rad)  # direção para a ponta (-Y)
        veio_claro = _chaikin(_barra_rot(
            tx - dx_perp * (tw * 0.16) + dx_dir * (th * 0.04),
            ty - dy_perp * (tw * 0.16) + dy_dir * (th * 0.04),
            tw * 0.24, th * 0.68, tang
        ), 1)
        m.flat(veio_claro, zt + 0.006, 0.008, "#944414", smooth=False)
        fissura = _barra_rot(
            tx + dx_perp * (tw * 0.14) - dx_dir * (th * 0.05),
            ty + dy_perp * (tw * 0.14) - dy_dir * (th * 0.05),
            tw * 0.11, th * 0.52, tang
        )
        m.flat(fissura, zt + 0.006, 0.008, "#582008", smooth=False)

        # Topo cortado da tora (seção transversal clara #D8A86C com cerne #9C5824) na ponta superior (-Y)
        px_ponta = tx + dx_dir * (th * 0.40)
        py_ponta = ty + dy_dir * (th * 0.40)
        corte = ellipse(px_ponta, py_ponta, tw * 0.40, tw * 0.22, 16, rot=a_rad)
        m.flat(corte, zt + 0.008, 0.010, "#D8A86C", outline="#582008", ow=0.03, smooth=False)
        cerne = ellipse(px_ponta, py_ponta, tw * 0.18, tw * 0.09, 12, rot=a_rad)
        m.flat(cerne, zt + 0.019, 0.006, "#9C5824", smooth=False)

    # Cesto trapezoidal de ripas de madeira (#804C28, contorno #5C3414) na frente (+Y)
    cesto_pts = [
        (-0.78, 0.65), (0.78, 0.65),
        (1.10, -0.35), (-1.10, -0.35),
    ]
    m.flat(cesto_pts, Z0, MH + 0.08, "#804C28", outline="#5C3414", ow=0.09, smooth=False)

    # Molduras laterais verticais do cesto (#704420)
    for sx in (-1, 1):
        post_lat = [
            (sx * 0.66, 0.64), (sx * 0.78, 0.64),
            (sx * 1.09, -0.34), (sx * 0.94, -0.34),
        ]
        m.flat(post_lat, TOPO + 0.086, 0.012, "#704420", smooth=False)

    # Borda clara superior do cesto (#B87C4C) e 2 ripas horizontais (#A86C40) com veios e preguinhos
    m.flat(_chaikin(_rect(0.0, -0.30, 2.02, 0.14), 1), TOPO + 0.090, 0.016, "#B87C4C", outline="#683C18", ow=0.03, smooth=False)
    for ry, rw in [(0.02, 1.74), (0.36, 1.52)]:
        m.flat(_chaikin(_rect(0.0, ry, rw, 0.21), 1), TOPO + 0.090, 0.014, "#A86C40", smooth=False)
        # Veio fino escuro e preguinhos nas pontas da ripa
        m.flat(_rect(0.0, ry, rw * 0.65, 0.04), TOPO + 0.105, 0.006, "#8C5428", smooth=False)
        for sx in (-1, 1):
            m.flat(ellipse(sx * (rw * 0.42), ry, 0.04, 0.04, 8), TOPO + 0.105, 0.008, "#543014", smooth=False)


# ---------------------------------------------------------------- 8. Bolsa de Minérios (ref. 22)
def minerios(m):
    m.base_aberta()
    # 5 blocos facetados de minério (pedra, ouro e diamante) saindo de dentro da bolsa
    # Pedra esquerda (+X) e ouro direito (-X) no fundo
    pedra_esq = [(0.35, -0.25), (0.48, -0.92), (0.95, -0.78), (1.05, -0.25)]
    m.flat(pedra_esq, Z0 + 0.30, MH - 0.28, "#809088", outline="#606C68", ow=0.07, smooth=False)
    ouro_dir = [(-0.35, -0.25), (-0.65, -0.92), (-1.08, -0.68), (-1.02, -0.15)]
    m.flat(ouro_dir, Z0 + 0.30, MH - 0.28, "#C4BC48", outline="#949034", ow=0.07, smooth=False)

    # Grande cristal de diamante ciano (#68DCE0 / #98F4F4, contorno #38989C) no centro-trás
    diamante = [(-0.52, -0.20), (-0.42, -0.82), (0.02, -1.05), (0.48, -0.75), (0.42, -0.20)]
    m.flat(diamante, Z0 + 0.32, MH - 0.25, "#68DCE0", outline="#38989C", ow=0.08, smooth=False)
    m.flat([(-0.32, -0.45), (0.02, -0.92), (0.35, -0.68), (-0.05, -0.35)],
           TOPO + 0.076, 0.012, "#98F4F4", smooth=False)

    # Bloco de ouro frontal esquerdo (+X) e pedra frontal direita (-X)
    ouro_fr = [(0.02, 0.05), (0.12, -0.58), (0.68, -0.62), (0.92, -0.28), (0.72, 0.08)]
    m.flat(ouro_fr, Z0 + 0.34, MH - 0.22, "#C4BC48", outline="#949034", ow=0.07, smooth=False)
    m.flat([(0.15, -0.48), (0.62, -0.52), (0.78, -0.28), (0.22, -0.22)],
           TOPO + 0.106, 0.012, "#D4CC4C", smooth=False)

    pedra_fr = [(-0.98, -0.12), (-0.88, -0.58), (-0.28, -0.75), (0.08, -0.52), (0.02, 0.08), (-0.65, 0.08)]
    m.flat(pedra_fr, Z0 + 0.36, MH - 0.20, "#809088", outline="#606C68", ow=0.07, smooth=False)
    m.flat([(-0.78, -0.48), (-0.28, -0.64), (-0.02, -0.45), (-0.58, -0.22)],
           TOPO + 0.126, 0.012, "#94A49C", smooth=False)

    # Re-sobrepõe a borda frontal da bolsa para os minérios parecerem DENTRO da bolsa!
    bolso_frente = _chaikin([
        (-1.12, -0.22), (-0.98, 0.22), (-0.55, 0.54),
        (0.0, 0.62), (0.55, 0.54), (0.98, 0.22), (1.12, -0.22),
        (0.65, -0.02), (0.0, 0.08), (-0.65, -0.02),
    ], 2)
    m.flat(bolso_frente, TOPO + 0.14, 0.02, "#804C28", outline="#543014", ow=0.05, smooth=False)


# ---------------------------------------------------------------- 9. Barril (ref. 63)
def barril(m):
    # Corpo cilíndrico/abaulado de madeira vermelha (#942800, contorno #742810)
    barril_poly = _chaikin([
        (-1.58, -0.55), (-1.35, -0.78), (1.35, -0.78), (1.58, -0.55),
        (1.68, 0.0), (1.58, 0.55), (1.35, 0.78), (-1.35, 0.78),
        (-1.58, 0.55), (-1.68, 0.0),
    ], 2)
    m.flat(barril_poly, Z0, MH, "#942800", outline="#742810", ow=0.11, smooth=False)

    # Brilho superior da madeira (#A03000)
    m.flat(_chaikin(_rect(0.18, -0.28, 1.95, 0.72), 2), TOPO + 0.006, 0.012, "#A03000", smooth=False)

    # Tampa lateral oval do barril na esquerda (+X) com rolha escura (#4C1C04)
    m.flat(ellipse(1.22, 0.0, 0.28, 0.64, 20), TOPO + 0.018, 0.018, "#A03000", outline="#6C2C00", ow=0.06, smooth=False)
    m.flat(ellipse(1.25, 0.24, 0.13, 0.15, 14), TOPO + 0.042, 0.018, "#4C1C04", smooth=False)

    # 3 aros curvados marrons-escuros (#6C2C00) envolvendo o barril
    for ax in [0.68, -0.15, -0.92]:
        aro = _chaikin([
            (ax + 0.08, -0.78), (ax - 0.02, 0.0), (ax + 0.08, 0.78),
            (ax + 0.20, 0.78), (ax + 0.10, 0.0), (ax + 0.20, -0.78),
        ], 1)
        m.flat(aro, TOPO + 0.018, 0.02, "#6C2C00", smooth=False)


# ---------------------------------------------------------------- 10. Baú do Tesouro (ref. 67)
def bau(m):
    # 1. Tampa abaulada superior (-Y) com MOLDURA DOURADA grossa (#C4A038, contorno #8C7024)
    # como em day-bag67.png, onde o arco externo da tampa é todo dourado!
    arco_tampa_ouro = _chaikin([
        (-1.32, -0.05), (1.32, -0.05),
        (1.30, -0.58), (1.02, -1.04), (0.58, -1.16),
        (-0.58, -1.16), (-1.02, -1.04), (-1.30, -0.58),
    ], 2)
    m.flat(arco_tampa_ouro, Z0, MH, "#C4A038", outline="#8C7024", ow=0.09, smooth=False)

    # Miolo de madeira escura da tampa abaulada (#4C3818) encaixado dentro do arco dourado
    miolo_tampa_mad = _chaikin([
        (-1.10, -0.10), (1.10, -0.10),
        (1.08, -0.55), (0.84, -0.90), (0.48, -0.98),
        (-0.48, -0.98), (-0.84, -0.90), (-1.08, -0.55),
    ], 2)
    m.flat(miolo_tampa_mad, TOPO + 0.006, 0.014, "#4C3818", outline="#34240C", ow=0.04, smooth=False)
    # Friso horizontal de tábuas na tampa
    m.flat(_rect(0.0, -0.62, 1.95, 0.06), TOPO + 0.021, 0.006, "#34240C", smooth=False)

    # 2. Caixa inferior retangular de madeira escura (#4C3818, base #604424)
    caixa_baixo = _rect(0.0, 0.28, 2.52, 0.74)
    m.flat(caixa_baixo, Z0, MH, "#4C3818", outline="#604424", ow=0.08, smooth=False)
    # Friso horizontal de tábuas na caixa inferior e sombra sob a tampa
    m.flat(_rect(0.0, 0.32, 2.20, 0.06), TOPO + 0.006, 0.008, "#34240C", smooth=False)
    m.flat(_rect(0.0, -0.02, 2.58, 0.12), TOPO + 0.006, 0.010, "#241C0C", smooth=False)

    # 3. Colunas/cantoneiras verticais douradas (#C4A038, contorno #8C7024) nas laterais da base (+Y)
    for sx in (-1, 1):
        col_lat = _chaikin(_rect(sx * 1.08, 0.28, 0.36, 0.80), 1)
        m.flat(col_lat, TOPO + 0.016, 0.022, "#C4A038", outline="#8C7024", ow=0.07, smooth=False)

    # 4. Faixa vertical central de madeira reforçada (#4C3818 com borda #604424)
    # que atravessa o baú inteiro de ponta a ponta (saliente em cima e embaixo como na ref 67)
    faixa_v_central = _chaikin(_rect(0.0, -0.26, 0.62, 1.96), 1)
    m.flat(faixa_v_central, TOPO + 0.022, 0.022, "#4C3818", outline="#604424", ow=0.08, smooth=False)

    # 5. Faixa horizontal dourada (#C4A038, contorno #8C7024) dividindo a tampa e a caixa
    faixa_h_ouro = _chaikin(_rect(0.0, -0.14, 2.66, 0.28), 1)
    m.flat(faixa_h_ouro, TOPO + 0.048, 0.024, "#C4A038", outline="#8C7024", ow=0.07, smooth=False)

    # 6. Fechadura retangular robusta dourada (#C4A038, contorno #8C7024 e sombra #241C0C embaixo)
    m.flat(_chaikin(_rect(0.0, -0.08, 0.96, 0.56), 1),
           TOPO + 0.070, 0.010, "#241C0C", smooth=False)
    m.flat(_chaikin(_rect(0.0, -0.14, 0.94, 0.56), 1),
           TOPO + 0.078, 0.026, "#C4A038", outline="#8C7024", ow=0.05, smooth=False)
    # Buraco da chave clássico de baú (topo redondo + encaixe trapezoidal escuro #3C2C10)
    m.flat(ellipse(0.0, -0.20, 0.13, 0.12, 14), TOPO + 0.106, 0.014, "#3C2C10", smooth=False)
    fecho_slot = [(-0.07, -0.20), (0.07, -0.20), (0.11, 0.01), (-0.11, 0.01)]
    m.flat(fecho_slot, TOPO + 0.106, 0.014, "#3C2C10", smooth=False)
    # Rebites dourados brilhantes (#E0BC48) nos cantos da fechadura
    for sx in (-1, 1):
        for sy in (-0.32, 0.04):
            m.flat(ellipse(sx * 0.34, sy, 0.045, 0.045, 10), TOPO + 0.106, 0.010, "#E0BC48", smooth=False)


LOTE = [
    ("padrao", padrao, "#842C08", "#481C10"),
    ("coelho", coelho, "#804C28", "#5C3414"),
    ("ninho_passaros", ninho_passaros, "#8C5824", "#5C3414"),
    ("aquario", aquario, "#ACD0E8", "#5C3414"),
    ("esquilo", esquilo, "#C47C28", "#5C3414"),
    ("vulcao", vulcao, "#40200C", "#2C1408"),
    ("lenha", lenha, "#804C28", "#704420"),
    ("minerios", minerios, "#804C28", "#543014"),
    ("barril", barril, "#942800", "#742810"),
    ("bau", bau, "#4C3818", "#241C0C"),
]
