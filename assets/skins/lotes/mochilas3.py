# Lote 3 de MOCHILAS (10 temas). Base em mochila_lib.py (com boneco fantasma PREVIEW_*).
# espirito_gelo, cesta_pao, caverna, cubo_gelo, espadas_duplas, cacto_espinhos, mumia, abobora, tronco_florido, caixote.
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


def _flor_camadas(m, cx, cy, r_ext, r_int, n_pet, cor_ext, cor_int, cor_miolo, z):
    """Flor com coroa externa arredondada, pétalas internas pontudas e miolo amarelo."""
    pts_ext = []
    for i in range(n_pet * 2):
        ang = math.pi * 2 * i / (n_pet * 2)
        r = r_ext if i % 2 == 0 else r_ext * 0.76
        pts_ext.append((cx + math.cos(ang) * r, cy + math.sin(ang) * r))
    m.flat(_chaikin(pts_ext, 2), z, 0.022, cor_ext, smooth=False)

    pts_int = []
    for i in range(n_pet * 2):
        ang = math.pi * 2 * i / (n_pet * 2) + math.pi / n_pet
        r = r_int if i % 2 == 0 else r_int * 0.48
        pts_int.append((cx + math.cos(ang) * r, cy + math.sin(ang) * r))
    m.flat(_chaikin(pts_int, 1), z + 0.022, 0.016, cor_int, smooth=False)
    m.flat(ellipse(cx, cy, r_int * 0.34, r_int * 0.34, 14), z + 0.038, 0.014, cor_miolo, smooth=False)


# ---------------------------------------------------------------- 1. Espírito de Gelo (ref. 30)
def espirito_gelo(m):
    m.base_aberta()

    # Cubo de gelo inclinado do espírito (#E8FAFA, topo #FCFDFE, lateral #D0EEF4, contorno azul-petróleo #147C94)
    # Altura MH - 0.18 para ficar acima do miolo escuro da base_aberta (TOPO + 0.048)
    cubo_iso = _chaikin([
        (0.95, 0.15), (1.02, -0.82), (0.25, -1.18),
        (-0.88, -0.92), (-1.02, -0.58), (-0.92, 0.15),
    ], 2)
    m.flat(cubo_iso, Z0 + 0.25, MH - 0.18, "#E8FAFA", outline="#147C94", ow=0.10, smooth=False)

    # Faceta superior branca-gelo (#FCFDFE) e faceta lateral direita azul-clara (#D0EEF4)
    topo_iso = _chaikin([
        (0.92, -0.78), (0.25, -1.08), (-0.82, -0.82), (-0.42, -0.52), (0.45, -0.58),
    ], 1)
    m.flat(topo_iso, TOPO + 0.076, 0.010, "#FCFDFE", smooth=False)
    lat_iso = _chaikin([
        (-0.42, -0.52), (-0.88, -0.78), (-0.82, 0.08), (-0.40, 0.10),
    ], 1)
    m.flat(lat_iso, TOPO + 0.076, 0.010, "#D0EEF4", smooth=False)

    # 2 olhinhos redondos escuros (#202020) com brilho branco grande (#FFFFFF)
    for ox, oy in [(0.45, -0.32), (-0.12, -0.22)]:
        m.flat(ellipse(ox, oy, 0.22, 0.22, 16), TOPO + 0.088, 0.020, "#202020", smooth=False)
        m.flat(ellipse(ox + 0.06, oy - 0.06, 0.09, 0.09, 12), TOPO + 0.109, 0.012, "#FFFFFF", smooth=False)

    # Re-sobrepõe a borda frontal da bolsa de couro (#804C28) sobre a base do cubo
    bolso_frente = _chaikin([
        (-1.12, -0.20), (-0.98, 0.24), (-0.55, 0.56),
        (0.0, 0.64), (0.55, 0.56), (0.98, 0.24), (1.12, -0.20),
        (0.65, 0.02), (0.0, 0.12), (-0.65, 0.02),
    ], 2)
    m.flat(bolso_frente, TOPO + 0.112, 0.022, "#804C28", outline="#543014", ow=0.05, smooth=False)

    # 2 mãozinhas redondas de gelo (#E8FAFA / #D0EEF4 com contorno #147C94) apoiadas na borda da bolsa
    for mx, my, cor_m in [(0.82, -0.02, "#E8FAFA"), (-0.38, 0.14, "#D0EEF4")]:
        m.flat(ellipse(mx, my, 0.26, 0.26, 18), TOPO + 0.140, 0.028, cor_m, outline="#147C94", ow=0.08, smooth=False)


# ---------------------------------------------------------------- 2. Cesta de Pão Caseiro (ref. 31)
def cesta_pao(m):
    # Fundo escuro da forma/cesta (#3C2C20)
    m.flat(ellipse(0.0, -0.25, 1.32, 0.45, 24), Z0 + 0.15, MH - 0.16, "#3C2C20", outline="#3C2C20", ow=0.06, smooth=False)

    # Pão caseiro redondo dourado (#BC8844, casca assada #744824) com 3 gomos superiores
    for px, py, rx, ry in [(0.58, -0.35, 0.64, 0.42), (0.0, -0.38, 0.68, 0.42), (-0.58, -0.35, 0.64, 0.42)]:
        m.flat(ellipse(px, py, rx, ry, 20), Z0 + 0.22, MH - 0.20, "#BC8844", outline="#744824", ow=0.08, smooth=False)
    # Unir o miolo dourado do pão e adicionar os talhos cruzados da crosta (#744824)
    m.flat(ellipse(0.0, -0.28, 1.12, 0.42, 24), TOPO + 0.026, 0.012, "#BC8844", smooth=False)
    for cx, cy, cw, ch, cang in [
        (0.45, -0.45, 0.55, 0.08, 25),
        (-0.45, -0.45, 0.55, 0.08, -25),
        (0.22, -0.32, 0.48, 0.08, 30),
        (-0.22, -0.32, 0.48, 0.08, -30),
        (0.0, -0.42, 0.08, 0.42, 12),
    ]:
        m.flat(_chaikin(_barra_rot(cx, cy, cw, ch, cang), 1), TOPO + 0.039, 0.012, "#744824", smooth=False)

    # Cesta/forma arredondada marrom-escura (#583824, friso #684834, contorno #443024) na frente (+Y)
    cesta_frente = _chaikin([
        (-1.38, -0.28), (-1.38, 0.52), (-1.05, 0.68), (1.05, 0.68), (1.38, 0.52), (1.38, -0.28),
        (0.75, -0.05), (0.0, 0.02), (-0.75, -0.05),
    ], 2)
    m.flat(cesta_frente, Z0, MH + 0.05, "#583824", outline="#443024", ow=0.10, smooth=False)


# ---------------------------------------------------------------- 3. Caverna (ref. 33)
def caverna(m):
    # Silhueta rochosa externa da caverna (#7C7480, contorno #3C3C3C)
    rocha_ext = _chaikin([
        (-1.35, 0.65), (1.35, 0.65),
        (1.32, 0.05), (1.15, -0.32), (1.12, -0.78),
        (0.18, -1.12), (-0.88, -0.68), (-1.05, -0.25), (-1.28, 0.12),
    ], 1)
    m.flat(rocha_ext, Z0, MH, "#7C7480", outline="#3C3C3C", ow=0.10, smooth=False)

    # Facetas angulares das pedras nas laterais (#5C545C e #888088) e pedras redondas no topo (#9C949C / #6C646C)
    for sx in (-1, 1):
        m.flat([(sx * 0.78, 0.15), (sx * 1.24, 0.25), (sx * 1.10, -0.22), (sx * 0.68, -0.08)],
               TOPO + 0.006, 0.012, "#5C545C", smooth=False)
        m.flat([(sx * 0.78, 0.62), (sx * 1.18, 0.62), (sx * 1.18, 0.22), (sx * 0.78, 0.15)],
               TOPO + 0.006, 0.012, "#888088", smooth=False)
    m.flat(ellipse(-0.18, -0.72, 0.28, 0.26, 14), TOPO + 0.006, 0.012, "#9C949C", smooth=False)
    m.flat(ellipse(0.75, -0.48, 0.18, 0.22, 12), TOPO + 0.006, 0.012, "#6C646C", smooth=False)
    m.flat(ellipse(-0.68, -0.45, 0.18, 0.22, 12), TOPO + 0.006, 0.012, "#6C646C", smooth=False)

    # Arco escuro profundo do interior da caverna (#040404 com borda dupla #485458 / #24383C)
    boca_caverna = _chaikin([
        (-0.75, 0.64), (0.75, 0.64),
        (0.72, 0.18), (0.38, -0.32), (0.0, -0.48), (-0.38, -0.32), (-0.72, 0.18),
    ], 2)
    m.flat(boca_caverna, TOPO + 0.020, 0.022, "#040404", outline="#24383C", ow=0.08, smooth=False)


# ---------------------------------------------------------------- 4. Cubo de Gelo Amarrado (ref. 34)
def cubo_gelo(m):
    # Bloco isométrico de gelo (#98D8EC, contorno azul-aço #386C94)
    bloco_pts = [
        (1.28, 0.35), (1.28, -0.82), (0.28, -0.82), (-1.22, -0.52),
        (-1.22, 0.62), (-0.62, 0.68),
    ]
    m.flat(bloco_pts, Z0, MH, "#98D8EC", outline="#386C94", ow=0.09, smooth=False)

    # Faceta superior clara (#BCE8F4) e faceta lateral esquerda mais iluminada (#B4E4F2)
    m.flat([(1.22, -0.78), (0.28, -0.78), (-1.15, -0.48), (-0.58, -0.38), (0.58, -0.42)],
           TOPO + 0.006, 0.012, "#BCE8F4", smooth=False)
    m.flat([(1.22, 0.32), (1.22, -0.75), (0.58, -0.42), (0.58, 0.62)],
           TOPO + 0.006, 0.012, "#B4E4F2", smooth=False)

    # 2 correias grossas azul-acinzentadas (#406880, contorno #305064) cruzadas em X sobre o gelo
    correia_1 = _chaikin([
        (1.18, -0.88), (0.45, -0.72), (-0.25, -0.15), (-1.22, 0.68),
        (-0.82, 0.72), (0.05, -0.05), (0.72, -0.55), (1.28, -0.78),
    ], 2)
    m.flat(correia_1, TOPO + 0.020, 0.022, "#406880", outline="#305064", ow=0.07, smooth=False)

    correia_2 = _chaikin([
        (1.34, 0.18), (0.42, 0.08), (-0.42, -0.22), (-1.28, -0.58),
        (-1.28, -0.28), (-0.35, 0.08), (0.48, 0.36), (1.34, 0.45),
    ], 2)
    m.flat(correia_2, TOPO + 0.048, 0.022, "#406880", outline="#305064", ow=0.07, smooth=False)


# ---------------------------------------------------------------- 5. Mochila com Espadas Duplas (ref. 38)
def espadas_duplas(m):
    # 2 espadas largas de madeira/bronze (#705434, guarda e pomo #5C4024, contorno #44301C) saindo de trás (-Y)
    for sx in (-1, 1):
        ang = sx * 22
        # Lâmina saindo da mochila
        lamina = _chaikin(_barra_rot(sx * 0.48, -0.52, 0.48, 0.85, ang), 1)
        m.flat(lamina, Z0 + 0.20, MH - 0.22, "#705434", outline="#44301C", ow=0.08, smooth=False)
        # Guarda-mão transversal (#5C4024)
        guarda = _chaikin(_barra_rot(sx * 0.65, -0.88, 1.12, 0.28, ang), 2)
        m.flat(guarda, Z0 + 0.26, MH - 0.22, "#5C4024", outline="#44301C", ow=0.09, smooth=False)
        # Empunhadura e pomo arredondado (#5C4024)
        pomo = _chaikin(_barra_rot(sx * 0.82, -1.28, 0.46, 0.38, ang), 2)
        m.flat(pomo, Z0 + 0.26, MH - 0.22, "#5C4024", outline="#44301C", ow=0.09, smooth=False)
        cabo_e = _chaikin(_barra_rot(sx * 0.72, -1.04, 0.22, 0.32, ang), 1)
        m.flat(cabo_e, TOPO + 0.046, 0.015, "#5C4024", outline="#44301C", ow=0.06, smooth=False)

    # Corpo cilíndrico de couro da mochila (#A0481C, metade #944018, contorno #682408) na frente (+Y)
    corpo_m = _chaikin(_rect(0.0, 0.12, 2.52, 1.12), 2)
    m.flat(corpo_m, Z0, MH + 0.04, "#A0481C", outline="#682408", ow=0.10, smooth=False)
    m.flat(_chaikin(_rect(0.0, 0.22, 2.32, 0.65), 1), TOPO + 0.046, 0.010, "#944018", smooth=False)

    # 2 correias verticais grossas de couro (#782C0C, contorno #581C04)
    for sx in (-1, 1):
        correia = _chaikin(_rect(sx * 0.86, 0.12, 0.34, 1.28), 2)
        m.flat(correia, TOPO + 0.050, 0.024, "#782C0C", outline="#581C04", ow=0.07, smooth=False)


# ---------------------------------------------------------------- 6. Cacto com Espinhos (ref. 49)
def cacto_espinhos(m):
    # Espinhos traseiros curvados (#DCDCDC, contorno #98ACA4) saindo do topo (-Y)
    espinhos_tras = [
        [(0.82, -0.72), (0.62, -1.18), (0.38, -1.28), (0.48, -0.72)],
        [(-0.78, -0.72), (-0.58, -1.18), (-0.28, -1.25), (-0.42, -0.72)],
        [(1.12, -0.45), (1.38, -0.82), (0.98, -0.78), (0.88, -0.45)],
    ]
    for esp in espinhos_tras:
        m.flat(_chaikin(esp, 2), Z0 + 0.18, MH - 0.20, "#DCDCDC", outline="#98ACA4", ow=0.07, smooth=False)

    # Corpo verde segmentado do cacto (#2C9068, contorno #1C503C)
    corpo_cacto = _chaikin([
        (-1.28, 0.62), (1.28, 0.62),
        (1.28, -0.25), (0.85, -0.78), (-0.85, -0.78), (-1.28, -0.25),
    ], 2)
    m.flat(corpo_cacto, Z0, MH, "#2C9068", outline="#1C503C", ow=0.10, smooth=False)

    # Costuras verde-escuras (#1C503C) dividindo os gomos horizontais do cacto
    for gy, gw in [(-0.42, 1.85), (-0.05, 2.38), (0.28, 2.38)]:
        m.flat(_chaikin(_barra_rot(0.0, gy, gw, 0.08, -3), 1), TOPO + 0.006, 0.010, "#1C503C", smooth=False)

    # Espinhos frontais e laterais saindo do corpo do cacto (#DCDCDC, contorno #98ACA4)
    espinhos_frente = [
        [(0.98, 0.12), (1.42, -0.15), (1.48, -0.48), (0.98, -0.15)],
        [(0.62, -0.15), (0.22, -0.42), (0.48, -0.12)],
        [(-0.22, -0.35), (0.05, -0.68), (-0.38, -0.62), (-0.52, -0.32)],
        [(-0.98, -0.05), (-1.35, -0.28), (-1.28, -0.58), (-0.92, -0.28)],
        [(0.68, 0.38), (0.98, 0.05), (0.52, 0.22)],
        [(-0.52, 0.42), (-0.15, 0.15), (-0.58, 0.18)],
    ]
    for esp in espinhos_frente:
        m.flat(_chaikin(esp, 2), TOPO + 0.018, 0.018, "#DCDCDC", outline="#98ACA4", ow=0.06, smooth=False)

    # 2 alças verticais verdes do cacto (#2C9068, contorno #1C503C)
    for sx in (-1, 1):
        alca_c = _chaikin(_rect(sx * 0.62, 0.0, 0.34, 1.58), 2)
        m.flat(alca_c, TOPO + 0.042, 0.024, "#2C9068", outline="#1C503C", ow=0.08, smooth=False)


# ---------------------------------------------------------------- 7. Mochila Múmia / Enfaixada (ref. 52)
def mumia(m):
    # Fundo marrom-escuro da mochila (#443020, contorno #302014) e ponta solta de faixa (-X, -Y)
    m.flat(_chaikin(_rect(0.0, -0.45, 1.58, 0.58), 2), Z0 + 0.15, MH - 0.18, "#443020", outline="#302014", ow=0.08, smooth=False)
    ponta_faixa = _chaikin([(-0.55, -0.35), (-0.98, -0.68), (-1.18, -0.42), (-0.75, -0.22)], 1)
    m.flat(ponta_faixa, Z0 + 0.20, MH - 0.20, "#B8B090", outline="#7C7864", ow=0.07, smooth=False)

    # Faixas diagonais no topo (-Y)
    for fx, fy, fang in [(0.35, -0.45, 28), (-0.15, -0.45, -12)]:
        m.flat(_chaikin(_barra_rot(fx, fy, 0.36, 0.68, fang), 1),
               TOPO - 0.01, 0.018, "#B8B090", outline="#7C7864", ow=0.06, smooth=False)

    # Corpo principal escuro (#443020)
    m.flat(_chaikin(_rect(0.0, 0.15, 2.56, 1.05), 2), Z0, MH, "#443020", outline="#302014", ow=0.08, smooth=False)

    # 3 faixas horizontais de bandagem (#B8B090, contorno #7C7864) cruzando a mochila
    for fy, fw, fang in [(-0.12, 2.48, 3), (0.15, 2.58, -3), (0.42, 2.48, 4)]:
        faixa_h = _chaikin(_barra_rot(0.0, fy, fw, 0.32, fang), 1)
        m.flat(faixa_h, TOPO + 0.008, 0.020, "#B8B090", outline="#7C7864", ow=0.07, smooth=False)

    # 2 faixas verticais de alça (#B8B090, contorno #7C7864) amarrando tudo
    for sx, ang_v in [(1, 5), (-1, -5)]:
        faixa_v = _chaikin(_barra_rot(sx * 0.72, 0.15, 0.36, 1.15, ang_v), 2)
        m.flat(faixa_v, TOPO + 0.036, 0.024, "#B8B090", outline="#7C7864", ow=0.07, smooth=False)


# ---------------------------------------------------------------- 8. Abóbora na Bolsa (ref. 60)
def abobora(m):
    m.base_aberta()

    # Cabinhas/caule curvo marrom no topo da abóbora (-Y) (#846030, contorno #644824)
    caule = _chaikin([
        (-0.15, -0.95), (-0.02, -1.28), (0.15, -1.42),
        (0.05, -1.18), (0.18, -0.95),
    ], 1)
    m.flat(caule, Z0 + 0.25, MH - 0.22, "#846030", outline="#644824", ow=0.06, smooth=False)

    # Gomos concêntricos da abóbora laranja (#BC6C24, #CC782C, #D48034, contorno #985418)
    m.flat(ellipse(0.0, -0.45, 1.05, 0.68, 26), Z0 + 0.24, MH - 0.20,
           "#BC6C24", outline="#985418", ow=0.08, smooth=False)
    m.flat(ellipse(0.0, -0.45, 0.78, 0.66, 24), TOPO + 0.046, 0.012,
           "#CC782C", outline="#985418", ow=0.06, smooth=False)
    m.flat(ellipse(0.0, -0.45, 0.44, 0.64, 22), TOPO + 0.060, 0.012,
           "#D48034", outline="#985418", ow=0.06, smooth=False)

    # Re-sobrepõe a borda frontal da bolsa de couro para a abóbora ficar encaixada lá dentro!
    bolso_frente = _chaikin([
        (-1.12, -0.22), (-0.98, 0.22), (-0.55, 0.54),
        (0.0, 0.62), (0.55, 0.54), (0.98, 0.22), (1.12, -0.22),
        (0.65, -0.02), (0.0, 0.08), (-0.65, -0.02),
    ], 2)
    m.flat(bolso_frente, TOPO + 0.076, 0.022, "#804C28", outline="#543014", ow=0.05, smooth=False)


# ---------------------------------------------------------------- 9. Tronco / Cipós com Flores (ref. 75)
def tronco_florido(m):
    # Flor vermelha/laranja no topo direito (-X, -Y)
    _flor_camadas(m, -0.62, -0.65, 0.46, 0.36, 7, "#741C10", "#DC4814", "#F4DC44", TOPO - 0.01)

    # Corpo verde-floresta de cipós entrelaçados (#046C40, contorno escuro #0C3824)
    corpo_cipo = _chaikin([
        (-1.32, 0.62), (1.32, 0.62),
        (1.32, -0.22), (0.65, -0.68), (-0.35, -0.68), (-1.32, -0.22),
    ], 2)
    m.flat(corpo_cipo, Z0, MH + 0.02, "#046C40", outline="#0C3824", ow=0.10, smooth=False)

    # Espiral e veios de cipó verde mais claro (#14844C) no centro da mochila
    espiral = _chaikin([
        (0.05, -0.45), (-0.35, -0.35), (-0.42, 0.05), (-0.05, 0.28),
        (0.45, 0.25), (0.52, -0.15), (0.18, -0.25), (-0.12, -0.08),
    ], 2)
    m.flat(espiral, TOPO + 0.026, 0.012, "#14844C", outline="#0C3824", ow=0.05, smooth=False)

    # 2 alças verticais de cipó escuro (#184C30, contorno #0C3824)
    for sx in (-1, 1):
        alca_v = _chaikin(_rect(sx * 0.68, 0.05, 0.32, 1.25), 2)
        m.flat(alca_v, TOPO + 0.042, 0.020, "#184C30", outline="#0C3824", ow=0.07, smooth=False)

    # Grande flor verde-limão na frente esquerda (+X)
    _flor_camadas(m, 0.88, -0.18, 0.52, 0.40, 7, "#386814", "#78AC24", "#F4DC44", TOPO + 0.066)


# ---------------------------------------------------------------- 10. Caixote de Madeira (ref. 77)
def caixote(m):
    # Tampa trapezoidal superior do caixote (-Y) (#987444, contorno #644820)
    tampa_sup = [
        (-1.12, -0.32), (1.12, -0.32),
        (0.95, -0.78), (-0.95, -0.78),
    ]
    m.flat(tampa_sup, Z0, MH - 0.02, "#987444", outline="#644820", ow=0.09, smooth=False)

    # Corpo retangular do caixote (#AC8450, contorno #644820)
    caixa_ret = _rect(0.0, 0.16, 2.76, 1.04)
    m.flat(caixa_ret, Z0, MH, "#AC8450", outline="#644820", ow=0.10, smooth=False)

    # Painel interno rebaixado com 5 ripas verticais (#947040 e #A47C48) separadas por barras (#644820)
    m.flat(_rect(0.0, 0.16, 2.12, 0.58), TOPO + 0.006, 0.012, "#644820", smooth=False)
    for i, rx in enumerate([0.82, 0.41, 0.0, -0.41, -0.82]):
        cor_r = "#947040" if i % 2 == 0 else "#A47C48"
        m.flat(_rect(rx, 0.16, 0.30, 0.44), TOPO + 0.019, 0.010, cor_r, smooth=False)

    # 4 chanfros diagonais nos cantos da moldura do caixote (#644820)
    for sx in (-1, 1):
        for sy, ang_c in [(-1, 42), (1, -42)]:
            m.flat(_barra_rot(sx * 1.18, 0.16 + sy * 0.36, 0.42, 0.08, sx * ang_c),
                   TOPO + 0.006, 0.012, "#644820", smooth=False)


LOTE = [
    ("espirito_gelo", espirito_gelo, "#E8FAFA", "#147C94"),
    ("cesta_pao", cesta_pao, "#583824", "#443024"),
    ("caverna", caverna, "#7C7480", "#3C3C3C"),
    ("cubo_gelo", cubo_gelo, "#98D8EC", "#386C94"),
    ("espadas_duplas", espadas_duplas, "#A0481C", "#682408"),
    ("cacto_espinhos", cacto_espinhos, "#2C9068", "#1C503C"),
    ("mumia", mumia, "#B8B090", "#7C7864"),
    ("abobora", abobora, "#CC782C", "#985418"),
    ("tronco_florido", tronco_florido, "#046C40", "#0C3824"),
    ("caixote", caixote, "#AC8450", "#644820"),
]
