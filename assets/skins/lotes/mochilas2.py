# Lote 2 de MOCHILAS (10 temas). Base em mochila_lib.py (com boneco fantasma PREVIEW_*).
# pote_mel, picareta, caranguejo, recife_coral, fatia_bolo, bambu, peixe, ovo_ninho, abelha, aventureiro.
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


# ---------------------------------------------------------------- 1. Pote / Saco de Mel (ref. 10)
def pote_mel(m):
    # Corpo arredondado do saco/pote de barro/estopa (#B47C44, bordas laterais #986430, contorno #6E441C)
    corpo_saco = _chaikin([
        (-1.42, 0.65), (1.42, 0.65),
        (1.36, 0.15), (1.18, -0.22),
        (-1.18, -0.22), (-1.36, 0.15),
    ], 2)
    m.flat(corpo_saco, Z0, MH - 0.02, "#986430", outline="#6E441C", ow=0.09, smooth=False)
    miolo_saco = _chaikin([
        (-1.16, 0.64), (1.16, 0.64),
        (1.08, 0.15), (0.94, -0.18),
        (-0.94, -0.18), (-1.08, 0.15),
    ], 2)
    m.flat(miolo_saco, TOPO - 0.012, 0.015, "#B47C44", smooth=False)

    # Sombra sob a borda do saco (#845628)
    m.flat(ellipse(0.0, -0.20, 1.24, 0.42, 24), TOPO + 0.004, 0.012, "#845628", smooth=False)

    # Borda superior enrolada do pote/saco (#B8824C, contorno #7A4E22)
    m.flat(ellipse(0.0, -0.36, 1.32, 0.48, 28), Z0 + 0.25, MH - 0.22,
           "#B8824C", outline="#7A4E22", ow=0.07, smooth=False)

    # Mel dourado brilhante dentro da boca (#E89000 com borda clara #FCAC08)
    m.flat(ellipse(0.0, -0.36, 1.06, 0.26, 24), TOPO + 0.038, 0.015, "#FCAC08", smooth=False)
    m.flat(ellipse(0.0, -0.38, 0.94, 0.20, 22), TOPO + 0.054, 0.010, "#E89000", smooth=False)

    # Mel escorrendo pela borda na esquerda (+X) em gotas grossas (#FCAC08 e brilho #FFC838)
    gota_mel = _chaikin([
        (0.88, -0.32), (0.82, 0.02), (0.58, 0.18), (0.35, 0.06),
        (0.18, -0.05), (-0.02, 0.06), (-0.25, -0.08), (-0.38, -0.28),
    ], 2)
    m.flat(gota_mel, TOPO + 0.042, 0.020, "#FCAC08", smooth=False)
    # Brilhos claros nas gotas de mel
    m.flat(_chaikin([(0.68, -0.15), (0.62, 0.04), (0.44, 0.02), (0.48, -0.18)], 1),
           TOPO + 0.064, 0.010, "#FFC838", smooth=False)
    m.flat(ellipse(0.02, -0.08, 0.10, 0.06, 10), TOPO + 0.064, 0.010, "#FFC838", smooth=False)


# ---------------------------------------------------------------- 2. Mochila com Picareta (ref. 26)
def picareta(m):
    # Corpo cilíndrico marrom-avermelhado da mochila (#A0481C, contorno #682408)
    corpo_m = _chaikin(_rect(0.0, 0.05, 2.52, 1.12), 2)
    m.flat(corpo_m, Z0, MH - 0.02, "#A0481C", outline="#682408", ow=0.10, smooth=False)
    # Faixa mais escura no meio do rolo (#944018)
    m.flat(_chaikin(_rect(0.0, 0.15, 2.32, 0.65), 1), TOPO - 0.012, 0.014, "#944018", smooth=False)

    # 2 correias verticais grossas de couro (#782C0C, contorno #581C04)
    for sx in (-1, 1):
        correia = _chaikin(_rect(sx * 0.86, 0.05, 0.34, 1.28), 2)
        m.flat(correia, Z0 + 0.05, MH - 0.04, "#782C0C", outline="#581C04", ow=0.07, smooth=False)

    # Cabo escuro horizontal da picareta preso no topo (-Y) (#0C2424, contorno #041414)
    cabo_pic = _chaikin(_rect(0.0, -0.74, 2.78, 0.34), 2)
    m.flat(cabo_pic, Z0 + 0.35, MH - 0.32, "#0C2424", outline="#041414", ow=0.07, smooth=False)

    # Encaixe retangular de diamante (#20A8A8, miolo #5CE0E8) da picareta na esquerda (+X)
    encaixe = _chaikin(_rect(0.76, -0.74, 0.78, 0.48), 1)
    m.flat(encaixe, TOPO + 0.040, 0.022, "#20A8A8", smooth=False)
    m.flat(_rect(0.76, -0.74, 0.52, 0.26), TOPO + 0.063, 0.012, "#5CE0E8", smooth=False)

    # Ponta superior da picareta de diamante curvada para cima (-Y)
    ponta_sup = _chaikin([
        (0.92, -0.92), (0.68, -1.35), (0.38, -1.55),
        (0.28, -1.42), (0.48, -0.92),
    ], 2)
    m.flat(ponta_sup, Z0 + 0.38, MH - 0.32, "#5CE0E8", outline="#20A8A8", ow=0.09, smooth=False)

    # Lâmina longa inferior da picareta curvada sobre a frente da mochila (+Y)
    ponta_inf = _chaikin([
        (0.96, -0.60), (1.02, -0.05), (0.85, 0.48),
        (0.68, 0.48), (0.58, -0.05), (0.58, -0.60),
    ], 2)
    m.flat(ponta_inf, TOPO + 0.068, 0.028, "#5CE0E8", outline="#20A8A8", ow=0.09, smooth=False)


# ---------------------------------------------------------------- 3. Caranguejo (ref. 29)
def caranguejo(m):
    # Pernas traseiras do caranguejo (#181048, contorno vermelho #B01C18)
    perna_tras = _chaikin([
        (0.85, -0.58), (1.42, -0.55), (1.68, -0.15),
        (1.88, 0.28), (1.52, 0.35), (1.18, -0.08), (0.78, -0.25),
    ], 2)
    m.sym(perna_tras, Z0 + 0.15, MH - 0.18, "#181048", outline="#B01C18", ow=0.10, smooth=False)

    # Corpo arredondado azul-noturno do caranguejo (#181048, contorno vermelho #B01C18)
    corpo_car = _chaikin([
        (-1.05, -0.15), (-1.08, -0.82), (-0.68, -1.25), (0.0, -1.32),
        (0.68, -1.25), (1.08, -0.82), (1.05, -0.15),
    ], 2)
    m.flat(corpo_car, Z0 + 0.20, MH - 0.18, "#181048", outline="#B01C18", ow=0.11, smooth=False)

    # Interior azul-petróleo da bolsa (#18789C)
    m.flat(ellipse(0.0, 0.02, 0.88, 0.32, 20), TOPO + 0.028, 0.012, "#18789C", smooth=False)

    # 2 olhos vermelhos grandes (#B01C18) com pupila/brilho branco (#FFFFFF)
    for sx in (-1, 1):
        m.flat(ellipse(sx * 0.44, -0.28, 0.22, 0.22, 16), TOPO + 0.036, 0.020, "#B01C18", smooth=False)
        m.flat(ellipse(sx * 0.47, -0.32, 0.10, 0.10, 12), TOPO + 0.058, 0.012, "#FFFFFF", smooth=False)

    # Concha/bolsa inferior azul-clara (#8CC4DC) com borda branca (#FCFCFC) e sombra cinza (#E4E4E4)
    bolsa_car = _chaikin([
        (-1.12, -0.05), (-1.02, 0.45), (-0.55, 0.72), (0.0, 0.78),
        (0.55, 0.72), (1.02, 0.45), (1.12, -0.05),
        (0.55, 0.08), (0.0, 0.12), (-0.55, 0.08),
    ], 2)
    m.flat(bolsa_car, Z0, MH + 0.04, "#8CC4DC", outline="#E4E4E4", ow=0.10, smooth=False)
    borda_branca = _chaikin([
        (-1.05, -0.05), (-0.55, 0.08), (0.0, 0.12), (0.55, 0.08), (1.05, -0.05),
        (1.02, 0.10), (0.52, 0.22), (0.0, 0.26), (-0.52, 0.22), (-1.02, 0.10),
    ], 2)
    m.flat(borda_branca, TOPO + 0.052, 0.018, "#FCFCFC", smooth=False)

    # Grandes patas frontais curvadas abraçando a bolsa (#181048, faixa interna #342078, contorno #B01C18)
    pata_frente = _chaikin([
        (0.62, 0.02), (0.68, -0.35), (1.12, -0.42), (1.52, -0.08),
        (1.48, 0.42), (1.28, 0.68), (1.02, 0.42), (0.98, 0.02),
    ], 2)
    m.sym(pata_frente, TOPO + 0.065, 0.028, "#181048", outline="#B01C18", ow=0.10, smooth=False)
    pata_luz = _chaikin([
        (0.82, -0.02), (0.92, -0.22), (1.18, -0.18), (1.22, 0.35), (1.05, 0.22),
    ], 2)
    m.sym(pata_luz, TOPO + 0.095, 0.010, "#342078", smooth=False)


# ---------------------------------------------------------------- 4. Recife de Coral (ref. 32)
def recife_coral(m):
    # 1. Algas verdes onduladas (#288820, contorno #105410) na esquerda (+X, -Y)
    for ax, ay, aw, ah, aang in [(0.92, -0.78, 0.26, 1.25, 10), (0.65, -0.62, 0.24, 0.98, -8), (1.12, -0.52, 0.22, 0.85, 24)]:
        alga = _chaikin(_barra_rot(ax, ay, aw, ah, aang), 2)
        m.flat(alga, Z0 + 0.20, MH - 0.22, "#288820", outline="#105410", ow=0.06, smooth=False)

    # 2. Coral rosa galhado (#DC5858, contorno #A43434) no centro-trás (-Y)
    coral_tronco = _chaikin([
        (0.28, -0.15), (0.48, -0.68), (0.62, -1.08), (0.42, -1.12),
        (0.25, -0.78), (0.12, -1.08), (-0.08, -1.05), (0.05, -0.65),
        (-0.28, -0.95), (-0.42, -1.18), (-0.58, -1.08), (-0.35, -0.72),
        (-0.58, -0.75), (-0.55, -0.58), (-0.15, -0.52), (-0.05, -0.15),
    ], 2)
    m.flat(coral_tronco, Z0 + 0.24, MH - 0.20, "#DC5858", outline="#A43434", ow=0.06, smooth=False)

    # 3. Corais tubulares laranjas (#E8580C, contorno #B83C04, boca escura #942C04) na direita (-X)
    for tx, ty, tang in [(-0.28, -0.55, -16), (-0.68, -0.62, 12)]:
        tubo = _chaikin(_barra_rot(tx, ty, 0.36, 0.72, tang), 2)
        m.flat(tubo, Z0 + 0.28, MH - 0.22, "#E8580C", outline="#B83C04", ow=0.05, smooth=False)
        a_r = math.radians(tang)
        bx = tx + math.sin(a_r) * 0.26
        by = ty - math.cos(a_r) * 0.26
        m.flat(ellipse(bx, by, 0.16, 0.11, 14, rot=a_r), TOPO + 0.068, 0.015, "#942C04", outline="#EC6818", ow=0.04, smooth=False)

    # 4. Duas rochas marrons arredondadas (#A47038, contorno #805424) no meio
    m.flat(ellipse(0.32, -0.05, 0.68, 0.45, 22), Z0 + 0.15, MH - 0.12,
           "#A47038", outline="#805424", ow=0.07, smooth=False)
    m.flat(ellipse(-0.38, 0.08, 0.62, 0.38, 20), Z0 + 0.18, MH - 0.14,
           "#A47038", outline="#805424", ow=0.07, smooth=False)

    # 5. Camadas de água cristalina turquesa na frente (+Y) (#BCECE8 e onda #8CE0DC com friso #34B8CC)
    agua_base = _chaikin([
        (-1.42, 0.62), (1.42, 0.62),
        (1.35, 0.08), (0.55, -0.02), (-0.35, 0.12), (-1.35, 0.05),
    ], 2)
    m.flat(agua_base, Z0, MH + 0.04, "#BCECE8", outline="#74CCC4", ow=0.07, smooth=False)
    onda_meio = _chaikin([
        (-1.38, 0.35), (-0.45, 0.38), (0.45, 0.22), (1.38, 0.18),
        (1.32, 0.02), (0.48, -0.06), (-0.42, 0.12), (-1.32, 0.05),
    ], 2)
    m.flat(onda_meio, TOPO + 0.048, 0.016, "#8CE0DC", outline="#34B8CC", ow=0.05, smooth=False)


# ---------------------------------------------------------------- 5. Fatia de Bolo (ref. 44)
def fatia_bolo(m):
    # Base triangular/lateral da massa do bolo (#9C7438 com camadas de recheio #805C28, contorno #705024)
    massa_pts = _chaikin([
        (-1.38, 0.58), (1.38, 0.62),
        (1.38, 0.05), (-1.22, -0.68), (-1.42, 0.05),
    ], 1)
    m.flat(massa_pts, Z0, MH - 0.02, "#9C7438", outline="#705024", ow=0.09, smooth=False)

    # 2 faixas horizontais de recheio escuro (#805C28) na lateral da fatia
    m.flat(_barra_rot(-0.02, 0.38, 2.55, 0.12, -2), TOPO - 0.010, 0.012, "#805C28", smooth=False)
    m.flat(_barra_rot(-0.08, 0.15, 2.45, 0.12, -4), TOPO - 0.010, 0.012, "#805C28", smooth=False)

    # Cobertura cremosa clara (#E4D4CC com borda #D4C0B8 e contorno #C4B0A8) no topo inclinado (-Y)
    cobertura = _chaikin([
        (1.40, 0.08), (1.38, -0.15), (0.15, -0.62), (-0.85, -0.98),
        (-1.25, -0.78), (-1.42, -0.25), (-1.42, 0.05),
        (-0.85, -0.05), (0.0, 0.05), (0.85, 0.12),
    ], 2)
    m.flat(cobertura, Z0 + 0.15, MH - 0.14, "#E4D4CC", outline="#C4B0A8", ow=0.07, smooth=False)

    # 2 faixas verticais de glacê (#E4D4CC, contorno #C4B0A8) descendo pela lateral da fatia
    for gx, gy, gh, gang in [(0.72, 0.18, 1.12, 8), (-0.65, -0.05, 1.48, -8)]:
        glace_v = _chaikin(_barra_rot(gx, gy, 0.38, gh, gang), 2)
        m.flat(glace_v, TOPO + 0.020, 0.022, "#E4D4CC", outline="#C4B0A8", ow=0.07, smooth=False)

    # Cereja / amora roxa (#803C78 com brilho #AC5CA4) no topo da fatia
    m.flat(ellipse(0.05, -0.45, 0.28, 0.28, 18), TOPO + 0.048, 0.025, "#803C78", smooth=False)
    m.flat(ellipse(0.11, -0.52, 0.11, 0.11, 12), TOPO + 0.074, 0.012, "#AC5CA4", smooth=False)


# ---------------------------------------------------------------- 6. Feixe de Bambu (ref. 50)
def bambu(m):
    # 5 colmos verticais de bambu verde (#50A024, centro claro #74B838, contorno verde-escuro #145C08)
    # (cx, y_topo, largura, z_step)
    colmos = [
        (0.82,  -1.15, 0.42, 0.020),
        (0.42,  -0.92, 0.36, 0.005),
        (0.02,  -1.38, 0.44, 0.035),
        (-0.40, -1.18, 0.40, 0.020),
        (-0.82, -0.98, 0.38, 0.005),
    ]
    for bx, by_top, bw, dz in colmos:
        cy = (by_top + 0.05) * 0.5
        ch = 0.05 - by_top
        zt = TOPO - 0.02 + dz
        corpo_b = _chaikin(_rect(bx, cy, bw, ch), 1)
        m.flat(corpo_b, Z0 + 0.20, zt - (Z0 + 0.20), "#50A024", outline="#145C08", ow=0.07, smooth=False)
        # Brilho vertical central do bambu (#74B838)
        m.flat(_rect(bx, cy, bw * 0.42, ch * 0.88), zt + 0.006, 0.008, "#74B838", smooth=False)
        # Nó horizontal do bambu (#2C7810) no meio do colmo
        ny = by_top * 0.52
        m.flat(_chaikin(_rect(bx, ny, bw * 1.12, 0.09), 1), zt + 0.008, 0.010, "#2C7810", smooth=False)

    # Cesto escuro na base (+Y) (#4C2810, contorno #381C08)
    m.flat(_rect(0.0, 0.34, 2.58, 0.64), Z0, MH + 0.02, "#4C2810", outline="#381C08", ow=0.08, smooth=False)

    # Borda trançada de vime/corda (#904C20, contorno #5C2C10) formada por gomos arredondados
    for gx in [0.98, 0.65, 0.32, 0.0, -0.32, -0.65, -0.98]:
        gomo = ellipse(gx, -0.02, 0.22, 0.26, 14, rot=math.radians(-10 if gx < 0 else 10))
        m.flat(gomo, TOPO + 0.032, 0.024, "#904C20", outline="#5C2C10", ow=0.06, smooth=False)


# ---------------------------------------------------------------- 7. Peixe (ref. 51)
def peixe(m):
    # Barbatana dorsal superior (-Y) e nadadeira caudal direita (-X) (#6C5C4C, raios #8C7C6C, contorno #4C4034)
    dorsal = _chaikin([
        (0.45, -0.42), (-0.05, -0.82), (-0.42, -0.88), (-0.22, -0.42),
    ], 1)
    m.flat(dorsal, Z0 + 0.20, MH - 0.22, "#6C5C4C", outline="#4C4034", ow=0.07, smooth=False)
    m.flat(_chaikin([(0.25, -0.46), (-0.08, -0.72), (-0.18, -0.46)], 1), TOPO - 0.012, 0.010, "#8C7C6C", smooth=False)

    cauda = _chaikin([
        (-1.05, -0.05), (-1.62, -0.42), (-1.75, -0.05), (-1.68, 0.32), (-1.05, 0.15),
    ], 2)
    m.flat(cauda, Z0 + 0.20, MH - 0.22, "#6C5C4C", outline="#4C4034", ow=0.07, smooth=False)
    m.flat(_chaikin([(-1.15, -0.02), (-1.55, -0.25), (-1.58, 0.18), (-1.15, 0.10)], 1),
           TOPO - 0.012, 0.010, "#8C7C6C", smooth=False)

    # Corpo fusiforme azul-acinzentado do peixe (#647880, contorno #3C4C50)
    corpo_p = _chaikin([
        (1.68, 0.05), (1.35, -0.32), (0.45, -0.48), (-0.55, -0.42), (-1.18, -0.12),
        (-1.18, 0.22), (-0.55, 0.45), (0.45, 0.48), (1.35, 0.35),
    ], 2)
    m.flat(corpo_p, Z0, MH, "#647880", outline="#3C4C50", ow=0.09, smooth=False)

    # Linha lateral clara (#7C9098) e fenda branquial (#4C5C60)
    m.flat(_chaikin(_rect(0.05, -0.08, 2.15, 0.05), 1), TOPO + 0.006, 0.008, "#7C9098", smooth=False)
    m.flat(_chaikin(_rect(0.95, 0.04, 0.12, 0.68), 1), TOPO + 0.006, 0.010, "#4C5C60", smooth=False)

    # Olho preto grande com brilho branco na cabeça (+X)
    m.flat(ellipse(1.25, -0.02, 0.16, 0.16, 16), TOPO + 0.008, 0.018, "#0C0C0C", smooth=False)
    m.flat(ellipse(1.29, -0.05, 0.07, 0.07, 10), TOPO + 0.027, 0.010, "#FFFFFF", smooth=False)

    # 2 alças verticais na barriga do peixe (+Y) (#7C9098, contorno #3C4C50)
    for ax in (0.62, -0.58):
        m.flat(_chaikin(_rect(ax, 0.28, 0.26, 0.56), 1),
               TOPO + 0.012, 0.022, "#7C9098", outline="#3C4C50", ow=0.06, smooth=False)


# ---------------------------------------------------------------- 8. Ovo no Ninho (ref. 56)
def ovo_ninho(m):
    # Base escura sob o ninho (#5C3414)
    m.flat(_chaikin(_rect(0.0, 0.42, 1.95, 0.42), 2), Z0, MH - 0.06, "#5C3414", outline="#3C200C", ow=0.08, smooth=False)

    # Coroa externa de palha/gravetos pontudos (#845424) e camada interna mais clara (#A06828)
    pts_ext = []
    n_p = 18
    for i in range(n_p * 2):
        ang = math.pi * 2 * i / (n_p * 2)
        r_x = 1.62 if i % 2 == 0 else 1.05
        r_y = 0.62 if i % 2 == 0 else 0.38
        pts_ext.append((math.cos(ang) * r_x, 0.05 + math.sin(ang) * r_y))
    m.flat(_chaikin(pts_ext, 1), Z0 + 0.18, MH - 0.16, "#845424", outline="#684018", ow=0.05, smooth=False)

    pts_int = []
    for i in range(n_p * 2):
        ang = math.pi * 2 * i / (n_p * 2) + 0.18
        r_x = 1.22 if i % 2 == 0 else 0.78
        r_y = 0.48 if i % 2 == 0 else 0.28
        pts_int.append((math.cos(ang) * r_x, 0.04 + math.sin(ang) * r_y))
    m.flat(_chaikin(pts_int, 1), TOPO + 0.026, 0.018, "#A06828", smooth=False)

    # Grande ovo verde-esmeralda (#14B070, contorno #046C40) erguido no centro do ninho
    ovo_pts = [
        (0.0, -1.28), (0.48, -1.15), (0.78, -0.72), (0.82, -0.22),
        (0.55, 0.15), (0.0, 0.25), (-0.55, 0.15),
        (-0.82, -0.22), (-0.78, -0.72), (-0.48, -1.15),
    ]
    m.flat(_chaikin(ovo_pts, 2), Z0 + 0.28, MH - 0.20, "#14B070", outline="#046C40", ow=0.09, smooth=False)

    # 4 manchas ovais verde-claras (#20C880) na casca do ovo
    for mx, my, rx, ry, rot_d in [
        (-0.08, -0.88, 0.28, 0.22, -18),
        (0.38,  -0.52, 0.20, 0.26, 12),
        (-0.05, -0.45, 0.16, 0.12, -25),
        (-0.05, -0.05, 0.34, 0.20, 5),
    ]:
        m.flat(ellipse(mx, my, rx, ry, 16, rot=math.radians(rot_d)),
               TOPO + 0.086, 0.012, "#20C880", smooth=False)


# ---------------------------------------------------------------- 9. Abelha (ref. 66)
def abelha(m):
    # Par de asas duplas azul-claras translúcidas (#B0D4DC, contorno #78B0B8) nas laterais
    asa_inf = _chaikin([
        (0.55, 0.35), (1.18, 0.42), (1.35, 0.22), (1.15, 0.05), (0.55, 0.12),
    ], 2)
    m.sym(asa_inf, Z0 + 0.18, MH - 0.20, "#B0D4DC", outline="#78B0B8", ow=0.08, smooth=False)

    asa_sup = _chaikin([
        (0.45, 0.05), (1.12, -0.18), (1.62, -0.02), (1.68, 0.18), (1.18, 0.24), (0.48, 0.20),
    ], 2)
    m.sym(asa_sup, Z0 + 0.22, MH - 0.22, "#B0D4DC", outline="#78B0B8", ow=0.08, smooth=False)

    # Abdômen pontudo amarelo e preto da abelha (#FCE050, contorno marrom #68400C) apontando para trás (-Y)
    abdomen = _chaikin([
        (0.0, -1.32), (0.38, -0.82), (0.68, -0.25), (0.72, 0.18),
        (-0.72, 0.18), (-0.68, -0.25), (-0.38, -0.82),
    ], 1)
    m.flat(abdomen, Z0 + 0.24, MH - 0.22, "#FCE050", outline="#68400C", ow=0.09, smooth=False)

    # Ferrão/ponta preta (#181410) e listras pretas arqueadas no abdômen
    ponta_preta = [(0.0, -1.24), (0.24, -0.92), (-0.24, -0.92)]
    m.flat(ponta_preta, TOPO + 0.026, 0.014, "#181410", smooth=False)
    listra_meio = _chaikin([
        (-0.55, -0.35), (-0.22, -0.52), (0.22, -0.52), (0.55, -0.35),
        (0.62, -0.12), (0.22, -0.28), (-0.22, -0.28), (-0.62, -0.12),
    ], 1)
    m.flat(listra_meio, TOPO + 0.026, 0.014, "#181410", smooth=False)

    # 2 antenas pretas curvas (#181410) saindo para os lados (-Y)
    antena = _chaikin([
        (0.38, 0.08), (0.58, -0.38), (0.98, -0.82), (1.32, -1.05),
        (1.22, -0.72), (0.92, -0.58), (0.68, -0.25), (0.52, 0.08),
    ], 2)
    m.sym(antena, TOPO + 0.042, 0.020, "#181410", smooth=False)

    # Colarinho felpudo dourado (#E8CA68, contorno #C88830) na base (+Y)
    colarinho = _chaikin([
        (-0.88, 0.52), (0.88, 0.52),
        (0.88, 0.25), (0.58, 0.12), (0.32, 0.02), (0.0, -0.05),
        (-0.32, 0.02), (-0.58, 0.12), (-0.88, 0.25),
    ], 2)
    m.flat(colarinho, TOPO + 0.064, 0.024, "#E8CA68", outline="#C88830", ow=0.08, smooth=False)


# ---------------------------------------------------------------- 10. Mochila de Aventureiro (ref. 76)
def aventureiro(m):
    # Saco de dormir bege enrolado no topo (-Y) (#D0B478, contorno #AD8C5C)
    rolo_dormir = _chaikin(_rect(0.0, -0.68, 2.78, 0.72), 2)
    m.flat(rolo_dormir, Z0 + 0.15, MH - 0.18, "#D0B478", outline="#AD8C5C", ow=0.09, smooth=False)
    # 2 correias claras (#BC883C, contorno #9C6C2C) prendendo o saco de dormir
    for sx in (-1, 1):
        c_rolo = _chaikin(_rect(sx * 0.68, -0.68, 0.34, 0.84), 2)
        m.flat(c_rolo, TOPO - 0.02, 0.022, "#BC883C", outline="#9C6C2C", ow=0.06, smooth=False)

    # Corpo arredondado de couro da mochila (#94441C e metade superior #AC582C, contorno #68240C)
    corpo_av = _chaikin(_rect(0.0, 0.15, 2.52, 1.08), 2)
    m.flat(corpo_av, Z0, MH + 0.02, "#94441C", outline="#68240C", ow=0.10, smooth=False)
    m.flat(_chaikin(_rect(0.0, -0.05, 2.34, 0.52), 1), TOPO + 0.026, 0.010, "#AC582C", smooth=False)

    # Aba superior marrom-escura da mochila (#843414, contorno #5C1C08)
    aba_sup = _chaikin(_rect(0.0, -0.35, 1.88, 0.32), 2)
    m.flat(aba_sup, TOPO + 0.038, 0.020, "#843414", outline="#5C1C08", ow=0.07, smooth=False)

    # 2 correias verticais laterais na mochila (#8C3814, contorno #5C1C08)
    for sx in (-1, 1):
        c_lat = _chaikin(_rect(sx * 0.82, 0.16, 0.28, 1.12), 2)
        m.flat(c_lat, TOPO + 0.042, 0.022, "#8C3814", outline="#5C1C08", ow=0.06, smooth=False)

    # Alça central curvada em U invertido (#94441C, contorno #68240C)
    alca_u = _chaikin([
        (-0.48, 0.12), (-0.45, -0.18), (0.0, -0.25), (0.45, -0.18), (0.48, 0.12),
        (0.26, 0.12), (0.22, -0.05), (-0.22, -0.05), (-0.26, 0.12),
    ], 2)
    m.flat(alca_u, TOPO + 0.066, 0.022, "#94441C", outline="#68240C", ow=0.06, smooth=False)


LOTE = [
    ("pote_mel", pote_mel, "#B47C44", "#6E441C"),
    ("picareta", picareta, "#A0481C", "#682408"),
    ("caranguejo", caranguejo, "#181048", "#B01C18"),
    ("recife_coral", recife_coral, "#A47038", "#805424"),
    ("fatia_bolo", fatia_bolo, "#9C7438", "#705024"),
    ("bambu", bambu, "#50A024", "#145C08"),
    ("peixe", peixe, "#647880", "#3C4C50"),
    ("ovo_ninho", ovo_ninho, "#14B070", "#046C40"),
    ("abelha", abelha, "#FCE050", "#68400C"),
    ("aventureiro", aventureiro, "#94441C", "#68240C"),
]
