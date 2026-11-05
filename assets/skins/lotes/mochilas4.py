# Lote 4 de MOCHILAS (10 temas). Base em mochila_lib.py (com boneco fantasma PREVIEW_*).
# garras_gelo, cartografo, folha_frutas, cristais_gelo, robo_visor, radio_militar, nuvem_faixas, fornalha, garras_ametista, explorador_pa.
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


# ---------------------------------------------------------------- 1. Garras / Presas de Gelo (ref. 35)
def garras_gelo(m):
    # Topo arqueado escuro (-Y) e corpo verde-abissal escuro (#2C5854, sombra #244844, contorno #142C2C)
    m.flat(_chaikin(_rect(0.0, -0.45, 1.55, 0.52), 2), Z0, MH - 0.04, "#244844", outline="#142C2C", ow=0.10, smooth=False)
    m.flat(_chaikin(_rect(0.0, 0.14, 2.52, 0.98), 2), Z0, MH, "#2C5854", outline="#142C2C", ow=0.10, smooth=False)
    m.flat(_chaikin(_rect(0.0, -0.14, 2.30, 0.32), 1), TOPO + 0.006, 0.010, "#244844", smooth=False)

    # Presa central grande branca (#FCFCFC) e 2 presas menores ao lado
    presa_c = _chaikin([(0.0, -0.48), (0.16, -0.12), (0.10, 0.08), (-0.10, 0.08), (-0.16, -0.12)], 1)
    m.flat(presa_c, TOPO + 0.018, 0.020, "#FCFCFC", smooth=False)
    presa_l = _chaikin([(0.26, -0.28), (0.38, -0.02), (0.28, 0.12), (0.18, 0.02)], 1)
    m.sym(presa_l, TOPO + 0.018, 0.018, "#FCFCFC", smooth=False)

    # 2 garras brancas menores nas laterais externas
    garra_ext1 = _chaikin([(1.05, -0.22), (1.18, -0.08), (1.02, -0.05)], 1)
    garra_ext2 = _chaikin([(1.25, -0.12), (1.22, 0.14), (1.05, 0.12)], 1)
    m.sym(garra_ext1, TOPO + 0.018, 0.018, "#FCFCFC", smooth=False)
    m.sym(garra_ext2, TOPO + 0.018, 0.018, "#FCFCFC", smooth=False)

    # 2 alças verticais verde-água (#BCE8E4, contorno #70B8AC) com abas pontudas
    alca_g = _chaikin([
        (0.58, -0.36), (0.86, -0.36), (0.86, 0.18), (0.98, 0.25),
        (0.86, 0.45), (0.86, 0.65), (0.58, 0.65), (0.58, 0.45),
        (0.46, 0.25), (0.58, 0.18),
    ], 1)
    m.sym(alca_g, TOPO + 0.036, 0.024, "#BCE8E4", outline="#70B8AC", ow=0.07, smooth=False)


# ---------------------------------------------------------------- 2. Mochila do Cartógrafo (ref. 46)
def cartografo(m):
    # Fundo superior escuro da mochila (#783C14)
    m.flat(_chaikin(_rect(0.0, -0.58, 1.56, 0.56), 2), Z0 + 0.15, MH - 0.18, "#783C14", outline="#5C2808", ow=0.08, smooth=False)

    # Pergaminho bege enrolado na esquerda (+X, -Y) (#D8C8A0, contorno #B09C78) com cinta escura (#583418)
    perg = _chaikin(_barra_rot(0.45, -0.65, 1.38, 0.44, 8), 2)
    m.flat(perg, Z0 + 0.24, MH - 0.18, "#D8C8A0", outline="#B09C78", ow=0.06, smooth=False)
    cinta_p = _chaikin(_barra_rot(0.35, -0.65, 0.28, 0.48, 8), 1)
    m.flat(cinta_p, TOPO + 0.066, 0.016, "#583418", outline="#3C200C", ow=0.04, smooth=False)

    # Mapa/cartão azul com borda branca na direita (-X, -Y) (#3898CC, borda #E4E8EC)
    mapa_c = _chaikin(_barra_rot(-0.62, -0.62, 0.66, 0.72, -14), 2)
    m.flat(mapa_c, Z0 + 0.25, MH - 0.17, "#3898CC", outline="#E4E8EC", ow=0.08, smooth=False)
    m.flat(_barra_rot(-0.62, -0.60, 0.24, 0.28, -14), TOPO + 0.086, 0.012, "#583418", smooth=False)

    # 2 alças superiores arqueadas (#985820, contorno #6C3810)
    for sx in (-1, 1):
        m.flat(_chaikin(_rect(sx * 0.36, -0.32, 0.56, 0.34), 2),
               TOPO + 0.092, 0.018, "#985820", outline="#6C3810", ow=0.06, smooth=False)

    # Corpo arredondado de couro marrom (#A4642C, faixa superior #8C5020, contorno #6C3810)
    corpo_c = _chaikin(_rect(0.0, 0.22, 2.58, 0.96), 2)
    m.flat(corpo_c, Z0, MH + 0.10, "#A4642C", outline="#6C3810", ow=0.10, smooth=False)
    m.flat(_rect(0.0, -0.08, 2.25, 0.22), TOPO + 0.106, 0.010, "#8C5020", smooth=False)

    # 2 correias verticais grossas (#783C14, contorno #5C2808)
    for sx in (-1, 1):
        c_v = _chaikin(_rect(sx * 0.78, 0.18, 0.32, 1.12), 2)
        m.flat(c_v, TOPO + 0.118, 0.024, "#783C14", outline="#5C2808", ow=0.07, smooth=False)


# ---------------------------------------------------------------- 3. Envoltório de Folhas com Frutinhas (ref. 47)
def folha_frutas(m):
    # Fundo verde de folha atrás das frutinhas (#5CC444, contorno #5C7840)
    m.flat(ellipse(-0.08, -0.35, 0.95, 0.55, 22), Z0 + 0.15, MH - 0.18, "#5CC444", outline="#5C7840", ow=0.07, smooth=False)

    # 3 frutinhas vermelhas brilhantes (#AC1828, brilho #DC4854, contorno #740C18) aninhadas nas folhas
    for fx, fy, fr in [(-0.05, -0.58, 0.30), (0.42, -0.42, 0.28), (0.92, 0.05, 0.30)]:
        m.flat(ellipse(fx, fy, fr, fr, 18), Z0 + 0.24, MH - 0.20, "#AC1828", outline="#740C18", ow=0.06, smooth=False)
        m.flat(ellipse(fx + 0.05, fy - 0.04, fr * 0.52, fr * 0.52, 12), TOPO + 0.046, 0.012, "#DC4854", smooth=False)

    # Dobra inferior da folha na frente (+Y) (#5CC444, contorno #5C7840)
    dobra_baixo = _chaikin([
        (-1.35, 0.62), (1.35, 0.62),
        (1.35, 0.22), (0.25, 0.42), (-1.32, 0.45),
    ], 1)
    m.flat(dobra_baixo, Z0, MH + 0.04, "#5CC444", outline="#5C7840", ow=0.09, smooth=False)

    # Grande folha curvada principal cobrindo a diagonal (#5CC444, contorno e nervuras #5C7840)
    folha_grande = _chaikin([
        (1.18, -0.32), (0.58, -0.18), (-0.15, -0.52), (-0.75, -0.58),
        (-1.25, -0.22), (-1.35, 0.35), (-0.95, 0.58), (-0.25, 0.55), (0.48, 0.18),
    ], 2)
    m.flat(folha_grande, TOPO + 0.052, 0.024, "#5CC444", outline="#5C7840", ow=0.09, smooth=False)

    # 5 nervuras curvas verde-oliva (#5C7840) acompanhando a folha
    for ny, nw, nang in [(-0.28, 1.45, 22), (-0.10, 1.65, 18), (0.08, 1.72, 12), (0.25, 1.58, 6), (0.42, 1.25, 0)]:
        nerv = _chaikin(_barra_rot(-0.18, ny, nw, 0.06, nang), 1)
        m.flat(nerv, TOPO + 0.078, 0.010, "#5C7840", smooth=False)


# ---------------------------------------------------------------- 4. Mochila de Cristais de Gelo (ref. 54)
def cristais_gelo(m):
    # Topo escuro (#303C54, contorno #1C2438)
    m.flat(_chaikin(_rect(0.0, -0.42, 1.62, 0.52), 2), Z0, MH - 0.04, "#303C54", outline="#1C2438", ow=0.09, smooth=False)

    # Coroa de 3 pontas de cristal azul-gelo no topo (-Y) (#ACEDF8, contorno #4CB0DC)
    coroa_cristal = [
        (0.55, -0.25), (0.62, -0.68), (0.25, -0.52), (0.0, -0.92),
        (-0.25, -0.52), (-0.62, -0.68), (-0.55, -0.25),
    ]
    m.flat(coroa_cristal, Z0 + 0.22, MH - 0.22, "#ACEDF8", outline="#4CB0DC", ow=0.09, smooth=False)

    # Corpo azul-marinho acinzentado (#3C5068, faixa #303C54, contorno #1C2438)
    m.flat(_chaikin(_rect(0.0, 0.14, 2.52, 0.98), 2), Z0, MH, "#3C5068", outline="#1C2438", ow=0.10, smooth=False)
    m.flat(_rect(0.0, -0.14, 2.25, 0.28), TOPO + 0.006, 0.010, "#303C54", smooth=False)

    # 2 alças verticais de cristal (#ACEDF8, contorno #4CB0DC) terminando em pontas duplas de cristal (+Y)
    alca_cr = [
        (0.56, -0.35), (0.92, -0.35), (0.92, 0.18), (1.06, 0.25), (0.96, 0.42),
        (1.06, 0.48), (0.96, 0.68), (0.74, 0.85), (0.52, 0.68), (0.42, 0.48),
        (0.52, 0.42), (0.42, 0.25), (0.56, 0.18),
    ]
    m.sym(alca_cr, TOPO + 0.018, 0.026, "#ACEDF8", outline="#4CB0DC", ow=0.08, smooth=False)


# ---------------------------------------------------------------- 5. Mochila Robô / Visor (ref. 58)
def robo_visor(m):
    # Domo superior branco-azulado (#DCF2F6, contorno azul-petróleo #186478)
    m.flat(_chaikin(_rect(0.0, -0.45, 1.58, 0.56), 2), Z0, MH - 0.02, "#DCF2F6", outline="#186478", ow=0.10, smooth=False)

    # Corpo arredondado branco-azulado (#DCF2F6, contorno #186478)
    m.flat(_chaikin(_rect(0.0, 0.16, 2.54, 1.02), 2), Z0, MH, "#DCF2F6", outline="#186478", ow=0.11, smooth=False)

    # 2 barras verticais laterais (#DCF2F6, contorno #186478)
    for sx in (-1, 1):
        m.flat(_chaikin(_rect(sx * 0.76, 0.14, 0.28, 1.14), 2),
               TOPO + 0.010, 0.020, "#DCF2F6", outline="#186478", ow=0.08, smooth=False)

    # 2 olhos pretos grandes com brilho branco no visor central
    for sx in (-1, 1):
        m.flat(ellipse(sx * 0.46, 0.14, 0.30, 0.30, 20), TOPO + 0.036, 0.020, "#080808", smooth=False)
        m.flat(ellipse(sx * 0.46 + 0.07, 0.04, 0.11, 0.11, 12), TOPO + 0.058, 0.012, "#FFFFFF", smooth=False)


# ---------------------------------------------------------------- 6. Rádio Militar / Máquina (ref. 62)
def radio_militar(m):
    # Cabo marrom curvado na lateral esquerda (+X) (#582814) e conector lateral (#744C18)
    cabo_r = _chaikin([
        (0.88, -0.32), (1.35, -0.35), (1.58, -0.05), (1.48, 0.35),
        (1.32, 0.32), (1.38, -0.02), (1.22, -0.18), (0.88, -0.18),
    ], 2)
    m.flat(cabo_r, Z0 + 0.20, MH - 0.22, "#582814", smooth=False)
    m.flat(_chaikin(_rect(1.22, 0.32, 0.36, 0.28), 1), Z0 + 0.15, MH - 0.16, "#9C6C24", outline="#744C18", ow=0.06, smooth=False)

    # 2 válvulas/mostradores redondos escuros no topo direito (-X, -Y) (#3C3018 com brilho #FFFFFF)
    for vx in (-0.38, -0.92):
        m.flat(ellipse(vx, -0.48, 0.20, 0.22, 16), Z0 + 0.22, MH - 0.20, "#3C3018", smooth=False)
        m.flat(ellipse(vx + 0.05, -0.54, 0.07, 0.07, 10), TOPO + 0.024, 0.010, "#FFFFFF", smooth=False)

    # Base superior dos conectores (#8C5418, contorno #744C18)
    m.flat(_chaikin(_rect(-0.08, -0.25, 2.05, 0.36), 1), Z0 + 0.15, MH - 0.16, "#8C5418", outline="#744C18", ow=0.07, smooth=False)
    for bx in (0.58, 0.15):
        m.flat(_chaikin(_barra_rot(bx, -0.22, 0.24, 0.45, -14), 1),
               TOPO - 0.005, 0.018, "#9C6C24", outline="#744C18", ow=0.06, smooth=False)

    # Chassi trapezoidal principal do rádio (#9C6C24, contorno #744C18)
    chassi = [
        (-1.42, 0.62), (1.22, 0.62),
        (1.02, -0.05), (-1.18, -0.05),
    ]
    m.flat(chassi, Z0, MH, "#9C6C24", outline="#744C18", ow=0.09, smooth=False)

    # Painel esquerdo (#8C5418) e visor escuro de frequência na direita (-X) (#3C3018 com marcador #F8F8F8)
    m.flat(_rect(0.48, 0.32, 0.88, 0.18), TOPO + 0.006, 0.010, "#8C5418", smooth=False)
    m.flat(_chaikin(_rect(-0.68, 0.28, 0.88, 0.30), 1), TOPO + 0.006, 0.014, "#3C3018", smooth=False)
    m.flat(_rect(-0.62, 0.30, 0.56, 0.08), TOPO + 0.021, 0.008, "#584820", smooth=False)
    m.flat(_rect(-0.42, 0.28, 0.18, 0.12), TOPO + 0.022, 0.010, "#F8F8F8", smooth=False)


# ---------------------------------------------------------------- 7. Nuvem Amarrada (ref. 64)
def nuvem_faixas(m):
    # Silhueta fofa da nuvem azul-clara (#BCE0EC, contorno #588088) feita de gomos arredondados unidos
    gomos_nuvem = [
        (-0.22, -0.48, 0.72, 0.68),
        (0.55,  -0.28, 0.52, 0.48),
        (0.88,   0.08, 0.54, 0.48),
        (-0.82,  0.08, 0.56, 0.52),
        (0.0,    0.25, 1.15, 0.42),
    ]
    for gx, gy, rx, ry in gomos_nuvem:
        m.flat(ellipse(gx, gy, rx, ry, 22), Z0, MH, "#BCE0EC", outline="#588088", ow=0.10, smooth=False)
    # Unir o miolo azul-claro da nuvem no topo sem costuras internas
    for gx, gy, rx, ry in gomos_nuvem:
        m.flat(ellipse(gx, gy, rx - 0.02, ry - 0.02, 22), TOPO + 0.006, 0.010, "#BCE0EC", smooth=False)

    # Brilho branco no topo/esquerda (#F8FCFC) e sombra azul-esverdeada na direita (#88BCC4)
    m.flat(ellipse(-0.15, -0.62, 0.55, 0.32, 18), TOPO + 0.017, 0.008, "#F8FCFC", smooth=False)
    m.flat(ellipse(0.88, -0.05, 0.38, 0.26, 16), TOPO + 0.017, 0.008, "#F8FCFC", smooth=False)
    m.flat(ellipse(-0.92, 0.15, 0.36, 0.38, 16), TOPO + 0.017, 0.008, "#88BCC4", smooth=False)

    # 2 faixas azuis cruzadas em X amarrando a nuvem (#4884BC, contorno #2C5878)
    faixa_1 = _chaikin([
        (0.95, -0.35), (0.15, 0.12), (-0.75, 0.62),
        (-1.18, 0.62), (-0.15, -0.08), (0.68, -0.52),
    ], 2)
    m.flat(faixa_1, TOPO + 0.026, 0.022, "#4884BC", outline="#2C5878", ow=0.07, smooth=False)

    faixa_2 = _chaikin([
        (-0.98, -0.38), (-0.12, 0.12), (0.75, 0.62),
        (1.18, 0.62), (0.15, -0.08), (-0.72, -0.52),
    ], 2)
    m.flat(faixa_2, TOPO + 0.052, 0.022, "#4884BC", outline="#2C5878", ow=0.07, smooth=False)


# ---------------------------------------------------------------- 8. Fornalha / Lanterna Industrial (ref. 69)
def fornalha(m):
    # Topo metálico arredondado (#8C8C8C, contorno #545454)
    m.flat(_chaikin(_rect(0.0, -0.38, 1.88, 0.56), 2), Z0, MH - 0.02, "#8C8C8C", outline="#545454", ow=0.10, smooth=False)

    # Corpo metálico principal (#8C8C8C, chanfro superior claro #B8B8B8, contorno #545454)
    m.flat(_chaikin(_rect(0.0, 0.18, 2.72, 0.96), 2), Z0, MH, "#8C8C8C", outline="#545454", ow=0.11, smooth=False)
    m.flat(_chaikin(_rect(0.0, -0.06, 2.48, 0.28), 1), TOPO + 0.006, 0.010, "#B8B8B8", smooth=False)

    # Visor octogonal/arredondado da fornalha acesa no centro (#F4A020, #FCE064, #FCFCE0 com emit)
    visor_f = _chaikin(_rect(0.0, -0.02, 1.38, 0.68), 2)
    m.flat(visor_f, TOPO + 0.018, 0.020, "#F4A020", outline="#545454", ow=0.09, smooth=False, emit=0.35)
    m.flat(ellipse(0.0, -0.02, 0.42, 0.30, 18), TOPO + 0.040, 0.010, "#FCE064", smooth=False, emit=0.45)
    m.flat(ellipse(0.0, -0.02, 0.28, 0.22, 16), TOPO + 0.051, 0.010, "#FCFCE0", smooth=False, emit=0.55)

    # 3 barras verticais da grade de ferro (#545454) sobre o visor aceso
    for gx in (-0.34, 0.0, 0.34):
        m.flat(_rect(gx, -0.02, 0.11, 0.72), TOPO + 0.062, 0.016, "#545454", smooth=False)


# ---------------------------------------------------------------- 9. Garras / Cristais de Ametista (ref. 74)
def garras_ametista(m):
    # Chifres/garras externas curvas de ametista (#8C3CC4, brilho #B45CE0, contorno #582884)
    chifre_ext = _chaikin([
        (0.45, 0.55), (1.05, 0.48), (1.28, 0.18), (1.25, -0.15),
        (1.02, -0.05), (1.08, -0.45), (0.88, -0.92), (0.52, -1.25),
        (0.48, -0.68), (0.35, -0.15),
    ], 2)
    m.sym(chifre_ext, Z0, MH - 0.02, "#8C3CC4", outline="#582884", ow=0.09, smooth=False)

    # Brilhos claros violeta (#B45CE0) nas laterais dos chifres
    luz_ext = _chaikin([(0.65, 0.25), (1.12, 0.08), (0.85, 0.05), (0.55, -0.82), (0.52, -0.25)], 1)
    m.sym(luz_ext, TOPO - 0.012, 0.012, "#B45CE0", smooth=False)

    # Corpo central côncavo roxo (#8C3CC4, topo #B45CE0, contorno #582884)
    corpo_am = _chaikin([
        (-0.58, 0.58), (0.58, 0.58),
        (0.58, -0.28), (0.0, -0.18), (-0.58, -0.28),
    ], 1)
    m.flat(corpo_am, Z0, MH, "#8C3CC4", outline="#582884", ow=0.09, smooth=False)
    m.flat(_chaikin([(-0.48, 0.15), (0.48, 0.15), (0.48, -0.20), (0.0, -0.10), (-0.48, -0.20)], 1),
           TOPO + 0.006, 0.010, "#B45CE0", smooth=False)

    # 2 chifres/alças frontais curvadas para o centro (#8C3CC4, contorno #582884)
    alca_chifre = _chaikin([
        (0.32, 0.62), (0.64, 0.62),
        (0.64, -0.18), (0.48, -0.62), (0.18, -0.85),
        (0.28, -0.45), (0.32, -0.05),
    ], 2)
    m.sym(alca_chifre, TOPO + 0.018, 0.026, "#8C3CC4", outline="#582884", ow=0.08, smooth=False)


# ---------------------------------------------------------------- 10. Mochila de Explorador com Pá (ref. 78)
def explorador_pa(m):
    # Pá presa horizontalmente no topo (-Y): cabo de madeira (#543818, contorno #3C2410) e pá dourada (#C4B440)
    cabo_pa = _chaikin(_rect(0.45, -0.76, 2.65, 0.32), 2)
    m.flat(cabo_pa, Z0 + 0.24, MH - 0.18, "#543818", outline="#3C2410", ow=0.07, smooth=False)

    lamina_pa = _chaikin([
        (-0.78, -0.76), (-0.95, -1.12), (-1.68, -1.12),
        (-1.78, -0.76), (-1.68, -0.40), (-0.95, -0.40),
    ], 2)
    m.flat(lamina_pa, Z0 + 0.25, MH - 0.17, "#C4B440", outline="#A49424", ow=0.07, smooth=False)
    for py in (-0.90, -0.76, -0.62):
        m.flat(_rect(-1.35, py, 0.56, 0.06), TOPO + 0.086, 0.010, "#A49424", smooth=False)

    # 2 alças superiores segurando a pá (#DCD8D8, contorno #C4BCBC)
    for sx in (-1, 1):
        m.flat(_chaikin(_rect(sx * 0.48, -0.65, 0.42, 0.52), 2),
               TOPO + 0.088, 0.020, "#DCD8D8", outline="#C4BCBC", ow=0.07, smooth=False)

    # Aba superior (#D8D4D4) e corpo principal de lona clara (#DCD8D8, contorno #C4BCBC)
    m.flat(_chaikin(_rect(0.0, -0.22, 2.15, 0.48), 2), TOPO + 0.096, 0.020, "#D8D4D4", outline="#C4BCBC", ow=0.08, smooth=False)
    m.flat(_chaikin(_rect(0.0, 0.26, 2.62, 0.92), 2), Z0, MH + 0.12, "#DCD8D8", outline="#C4BCBC", ow=0.10, smooth=False)

    # Remendo de tecido costurado na esquerda (+X) (#C0B8B8) e alça central curvada
    remendo = _chaikin(_barra_rot(0.75, 0.25, 0.52, 0.48, 28), 1)
    m.flat(remendo, TOPO + 0.126, 0.012, "#C0B8B8", smooth=False)
    alca_c = _chaikin([
        (-0.42, 0.35), (-0.38, 0.08), (0.0, 0.02), (0.38, 0.08), (0.42, 0.35),
        (0.22, 0.35), (0.18, 0.20), (-0.18, 0.20), (-0.22, 0.35),
    ], 2)
    m.flat(alca_c, TOPO + 0.128, 0.020, "#DCD8D8", outline="#C4BCBC", ow=0.07, smooth=False)


LOTE = [
    ("garras_gelo", garras_gelo, "#2C5854", "#142C2C"),
    ("cartografo", cartografo, "#A4642C", "#6C3810"),
    ("folha_frutas", folha_frutas, "#5CC444", "#5C7840"),
    ("cristais_gelo", cristais_gelo, "#3C5068", "#1C2438"),
    ("robo_visor", robo_visor, "#DCF2F6", "#186478"),
    ("radio_militar", radio_militar, "#9C6C24", "#744C18"),
    ("nuvem_faixas", nuvem_faixas, "#BCE0EC", "#588088"),
    ("fornalha", fornalha, "#8C8C8C", "#545454"),
    ("garras_ametista", garras_ametista, "#8C3CC4", "#582884"),
    ("explorador_pa", explorador_pa, "#DCD8D8", "#C4BCBC"),
]
