# Variantes de cor das mochilas (mesma geometria 3D dos lotes 1–5, mudando apenas a paleta).
# Geradas automaticamente para o export_roblox.py (Opção 1).
from mochila_lib import *

TIPO = "mochila"


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


# ---------------------------------------------------------------- 1. Fábrica de variantes da Mochila Padrão
def _make_padrao(cor_corpo, cor_contorno, cor_alca, cor_bolso):
    def _fn(m):
        m.strap = cor_alca
        m.base(w=2.56, d=1.24, h=MH, r=0.42, body_color=cor_corpo, outline_color=cor_contorno)
        alca_tras = [(-0.72, -0.55), (0.72, -0.55), (0.52, -1.02), (-0.52, -1.02)]
        m.flat(alca_tras, Z0 + 0.25, MH - 0.30, cor_bolso, outline=cor_contorno, ow=0.10, smooth=False)
        m.flat(_chaikin(_rect(0.0, 0.18, 1.15, 0.36), 2),
               TOPO, 0.03, cor_bolso, outline=cor_contorno, ow=0.08, smooth=False)
    return _fn


# ---------------------------------------------------------------- 2. Fábrica de variantes da Bolsa com Cristal (IDs 17–21)
def _make_bolsa_cristal(cor_gema, cor_luz, cor_borda):
    def _fn(m):
        m.base_aberta()
        cristal_esq = _chaikin([(0.95, 0.02), (0.92, -0.52), (0.55, -0.82), (0.05, -0.62), (0.12, 0.08)], 1)
        m.flat(cristal_esq, Z0 + 0.25, MH - 0.19, cor_gema, outline=cor_borda, ow=0.08, smooth=False)
        m.flat(_chaikin([(0.65, -0.45), (0.42, -0.58), (0.25, -0.25), (0.55, -0.15)], 1),
               TOPO + 0.066, 0.010, cor_luz, smooth=False)

        cristal_dir = _chaikin([(0.38, 0.08), (0.42, -0.45), (0.05, -0.92), (-0.52, -0.95),
                                (-0.88, -0.45), (-0.98, -0.12), (-0.45, 0.15)], 1)
        m.flat(cristal_dir, Z0 + 0.27, MH - 0.17, cor_gema, outline=cor_borda, ow=0.08, smooth=False)
        m.flat(_chaikin([(-0.05, -0.55), (-0.42, -0.58), (-0.52, -0.22), (-0.08, -0.15)], 1),
               TOPO + 0.106, 0.010, cor_luz, smooth=False)

        alca_diag = _chaikin([
            (0.55, -0.82), (0.12, -1.08), (-0.28, -0.78),
            (-0.58, -0.25), (-0.65, 0.22), (-0.38, 0.22),
            (-0.32, -0.22), (-0.02, -0.68), (0.28, -0.88),
        ], 2)
        m.flat(alca_diag, TOPO + 0.118, 0.022, "#804C28", outline="#543014", ow=0.05, smooth=False)
        fivela = _chaikin(_barra_rot(-0.42, -0.45, 0.38, 0.42, -25), 1)
        m.flat(fivela, TOPO + 0.142, 0.018, "#909490", smooth=False)
        m.flat(_barra_rot(-0.42, -0.45, 0.20, 0.24, -25), TOPO + 0.161, 0.010, "#543014", smooth=False)

        bolso_frente = _chaikin([
            (-1.12, -0.22), (-0.98, 0.22), (-0.55, 0.54),
            (0.0, 0.62), (0.55, 0.54), (0.98, 0.22), (1.12, -0.22),
            (0.65, -0.02), (0.0, 0.08), (-0.65, -0.02),
        ], 2)
        m.flat(bolso_frente, TOPO + 0.145, 0.022, "#804C28", outline="#543014", ow=0.05, smooth=False)
    return _fn


# ---------------------------------------------------------------- 3. Fábrica de variantes da Mochila com Picareta (IDs 23–28)
def _make_picareta(cor_lamina, cor_borda, cor_cabo, cor_cabo_out):
    def _fn(m):
        corpo_m = _chaikin(_rect(0.0, 0.05, 2.52, 1.12), 2)
        m.flat(corpo_m, Z0, MH - 0.02, "#A0481C", outline="#682408", ow=0.10, smooth=False)
        m.flat(_chaikin(_rect(0.0, 0.15, 2.32, 0.65), 1), TOPO - 0.012, 0.014, "#944018", smooth=False)
        for sx in (-1, 1):
            correia = _chaikin(_rect(sx * 0.86, 0.05, 0.34, 1.28), 2)
            m.flat(correia, Z0 + 0.05, MH - 0.04, "#782C0C", outline="#581C04", ow=0.07, smooth=False)

        cabo_pic = _chaikin(_rect(0.0, -0.74, 2.78, 0.34), 2)
        m.flat(cabo_pic, Z0 + 0.35, MH - 0.32, cor_cabo, outline=cor_cabo_out, ow=0.07, smooth=False)

        encaixe = _chaikin(_rect(0.76, -0.74, 0.78, 0.48), 1)
        m.flat(encaixe, TOPO + 0.040, 0.022, cor_borda, smooth=False)
        m.flat(_rect(0.76, -0.74, 0.52, 0.26), TOPO + 0.063, 0.012, cor_lamina, smooth=False)

        ponta_sup = _chaikin([(0.92, -0.92), (0.68, -1.35), (0.38, -1.55), (0.28, -1.42), (0.48, -0.92)], 2)
        m.flat(ponta_sup, Z0 + 0.38, MH - 0.32, cor_lamina, outline=cor_borda, ow=0.09, smooth=False)

        ponta_inf = _chaikin([(0.96, -0.60), (1.02, -0.05), (0.85, 0.48), (0.68, 0.48), (0.58, -0.05), (0.58, -0.60)], 2)
        m.flat(ponta_inf, TOPO + 0.068, 0.028, cor_lamina, outline=cor_borda, ow=0.09, smooth=False)
    return _fn


# ---------------------------------------------------------------- 4. Fábrica de variantes de Espadas Duplas (IDs 37–42)
def _make_espadas(cor_lamina, cor_guarda, cor_contorno):
    def _fn(m):
        for sx in (-1, 1):
            ang = sx * 22
            lamina = _chaikin(_barra_rot(sx * 0.48, -0.52, 0.48, 0.85, ang), 1)
            m.flat(lamina, Z0 + 0.20, MH - 0.22, cor_lamina, outline=cor_contorno, ow=0.08, smooth=False)
            guarda = _chaikin(_barra_rot(sx * 0.65, -0.88, 1.12, 0.28, ang), 2)
            m.flat(guarda, Z0 + 0.26, MH - 0.22, cor_guarda, outline=cor_contorno, ow=0.09, smooth=False)
            pomo = _chaikin(_barra_rot(sx * 0.82, -1.28, 0.46, 0.38, ang), 2)
            m.flat(pomo, Z0 + 0.26, MH - 0.22, cor_guarda, outline=cor_contorno, ow=0.09, smooth=False)
            cabo_e = _chaikin(_barra_rot(sx * 0.72, -1.04, 0.22, 0.32, ang), 1)
            m.flat(cabo_e, TOPO + 0.046, 0.015, cor_guarda, outline=cor_contorno, ow=0.06, smooth=False)

        corpo_m = _chaikin(_rect(0.0, 0.12, 2.52, 1.12), 2)
        m.flat(corpo_m, Z0, MH + 0.04, "#A0481C", outline="#682408", ow=0.10, smooth=False)
        m.flat(_chaikin(_rect(0.0, 0.22, 2.32, 0.65), 1), TOPO + 0.046, 0.010, "#944018", smooth=False)
        for sx in (-1, 1):
            correia = _chaikin(_rect(sx * 0.86, 0.12, 0.34, 1.28), 2)
            m.flat(correia, TOPO + 0.050, 0.024, "#782C0C", outline="#581C04", ow=0.07, smooth=False)
    return _fn


# ---------------------------------------------------------------- 5. Outras variantes diretas do catálogo
def fatia_bolo_morango(m):
    massa_pts = _chaikin([(-1.38, 0.58), (1.38, 0.62), (1.38, 0.05), (-1.22, -0.68), (-1.42, 0.05)], 1)
    m.flat(massa_pts, Z0, MH - 0.02, "#6C4020", outline="#4C2810", ow=0.09, smooth=False)
    m.flat(_barra_rot(-0.02, 0.38, 2.55, 0.12, -2), TOPO - 0.010, 0.012, "#4C2810", smooth=False)
    m.flat(_barra_rot(-0.08, 0.15, 2.45, 0.12, -4), TOPO - 0.010, 0.012, "#4C2810", smooth=False)
    cobertura = _chaikin([
        (1.40, 0.08), (1.38, -0.15), (0.15, -0.62), (-0.85, -0.98),
        (-1.25, -0.78), (-1.42, -0.25), (-1.42, 0.05),
        (-0.85, -0.05), (0.0, 0.05), (0.85, 0.12),
    ], 2)
    m.flat(cobertura, Z0 + 0.15, MH - 0.14, "#F4F0F0", outline="#D0C8C8", ow=0.07, smooth=False)
    for gx, gy, gh, gang in [(0.72, 0.18, 1.12, 8), (-0.65, -0.05, 1.48, -8)]:
        glace_v = _chaikin(_barra_rot(gx, gy, 0.38, gh, gang), 2)
        m.flat(glace_v, TOPO + 0.020, 0.022, "#F4F0F0", outline="#D0C8C8", ow=0.07, smooth=False)
    m.flat(ellipse(0.05, -0.45, 0.28, 0.28, 18), TOPO + 0.048, 0.025, "#C82020", smooth=False)
    m.flat(ellipse(0.11, -0.52, 0.11, 0.11, 12), TOPO + 0.074, 0.012, "#F06464", smooth=False)


def abobora_branca(m):
    m.base_aberta()
    caule = _chaikin([(-0.15, -0.95), (-0.02, -1.28), (0.15, -1.42), (0.05, -1.18), (0.18, -0.95)], 1)
    m.flat(caule, Z0 + 0.25, MH - 0.22, "#846030", outline="#644824", ow=0.06, smooth=False)
    m.flat(ellipse(0.0, -0.45, 1.05, 0.68, 26), Z0 + 0.24, MH - 0.20, "#DCD8D0", outline="#ACA49C", ow=0.08, smooth=False)
    m.flat(ellipse(0.0, -0.45, 0.78, 0.66, 24), TOPO + 0.046, 0.012, "#E8E4DC", outline="#ACA49C", ow=0.06, smooth=False)
    m.flat(ellipse(0.0, -0.45, 0.44, 0.64, 22), TOPO + 0.060, 0.012, "#F4F0EC", outline="#ACA49C", ow=0.06, smooth=False)
    bolso_frente = _chaikin([
        (-1.12, -0.22), (-0.98, 0.22), (-0.55, 0.54),
        (0.0, 0.62), (0.55, 0.54), (0.98, 0.22), (1.12, -0.22),
        (0.65, -0.02), (0.0, 0.08), (-0.65, -0.02),
    ], 2)
    m.flat(bolso_frente, TOPO + 0.076, 0.022, "#804C28", outline="#543014", ow=0.05, smooth=False)


def nuvem_por_do_sol(m):
    gomos_nuvem = [(-0.22, -0.48, 0.72, 0.68), (0.55, -0.28, 0.52, 0.48), (0.88, 0.08, 0.54, 0.48), (-0.82, 0.08, 0.56, 0.52), (0.0, 0.25, 1.15, 0.42)]
    for gx, gy, rx, ry in gomos_nuvem:
        m.flat(ellipse(gx, gy, rx, ry, 22), Z0, MH, "#EC84AC", outline="#AC5C54", ow=0.10, smooth=False)
    for gx, gy, rx, ry in gomos_nuvem:
        m.flat(ellipse(gx, gy, rx - 0.02, ry - 0.02, 22), TOPO + 0.006, 0.010, "#EC84AC", smooth=False)
    m.flat(ellipse(-0.15, -0.62, 0.55, 0.32, 18), TOPO + 0.017, 0.008, "#FCE098", smooth=False)
    m.flat(ellipse(-0.92, 0.15, 0.36, 0.38, 16), TOPO + 0.017, 0.008, "#C458D0", smooth=False)
    faixa_1 = _chaikin([(0.95, -0.35), (0.15, 0.12), (-0.75, 0.62), (-1.18, 0.62), (-0.15, -0.08), (0.68, -0.52)], 2)
    m.flat(faixa_1, TOPO + 0.026, 0.022, "#FCE098", outline="#DC8830", ow=0.07, smooth=False)
    faixa_2 = _chaikin([(-0.98, -0.38), (-0.12, 0.12), (0.75, 0.62), (1.18, 0.62), (0.15, -0.08), (-0.72, -0.52)], 2)
    m.flat(faixa_2, TOPO + 0.052, 0.022, "#FCE098", outline="#DC8830", ow=0.07, smooth=False)


def fornalha_apagada(m):
    m.flat(_chaikin(_rect(0.0, -0.38, 1.88, 0.56), 2), Z0, MH - 0.02, "#8C8C8C", outline="#545454", ow=0.10, smooth=False)
    m.flat(_chaikin(_rect(0.0, 0.18, 2.72, 0.96), 2), Z0, MH, "#8C8C8C", outline="#545454", ow=0.11, smooth=False)
    m.flat(_chaikin(_rect(0.0, -0.06, 2.48, 0.28), 1), TOPO + 0.006, 0.010, "#B8B8B8", smooth=False)
    visor_f = _chaikin(_rect(0.0, -0.02, 1.38, 0.68), 2)
    m.flat(visor_f, TOPO + 0.018, 0.020, "#686868", outline="#545454", ow=0.09, smooth=False)
    for gx in (-0.34, 0.0, 0.34):
        m.flat(_rect(gx, -0.02, 0.11, 0.72), TOPO + 0.042, 0.016, "#545454", smooth=False)


def _make_carapaca(cor_corpo, cor_contorno, cor_joia, cor_brilho):
    def _fn(m):
        gomos_sup = [(-1.18, 0.12), (-0.92, -0.42), (-0.42, -0.62), (0.0, -0.52), (0.42, -0.62), (0.92, -0.42), (1.18, 0.12)]
        m.flat(_chaikin(gomos_sup, 2), Z0, MH - 0.02, cor_corpo, outline=cor_contorno, ow=0.10, smooth=False)
        for gx, ang_g in [(0.65, 22), (0.28, 12), (-0.28, -12), (-0.65, -22)]:
            m.flat(_barra_rot(gx, -0.28, 0.11, 0.68, ang_g), TOPO - 0.012, 0.012, cor_contorno, smooth=False)
        coroa_frente = _chaikin([
            (-1.05, 0.58), (1.05, 0.58), (1.32, 0.08),
            (0.92, 0.12), (0.72, -0.15), (0.38, 0.02),
            (0.0, -0.28), (-0.38, 0.02), (-0.72, -0.15),
            (-0.92, 0.12), (-1.32, 0.08),
        ], 1)
        m.flat(coroa_frente, Z0, MH + 0.02, cor_corpo, outline=cor_contorno, ow=0.10, smooth=False)
        for jx, jy, jr in [(0.96, 0.30, 0.14), (0.52, 0.22, 0.18), (0.0, 0.16, 0.22), (-0.52, 0.22, 0.18), (-0.96, 0.30, 0.14)]:
            m.flat(ellipse(jx, jy, jr, jr, 16), TOPO + 0.026, 0.020, cor_joia, smooth=False)
            m.flat(ellipse(jx, jy - jr * 0.28, jr * 0.42, jr * 0.42, 12), TOPO + 0.048, 0.010, cor_brilho, smooth=False)
    return _fn


def explorador_pa_couro(m):
    cabo_pa = _chaikin(_rect(0.45, -0.76, 2.65, 0.32), 2)
    m.flat(cabo_pa, Z0 + 0.24, MH - 0.18, "#543818", outline="#3C2410", ow=0.07, smooth=False)
    lamina_pa = _chaikin([(-0.78, -0.76), (-0.95, -1.12), (-1.68, -1.12), (-1.78, -0.76), (-1.68, -0.40), (-0.95, -0.40)], 2)
    m.flat(lamina_pa, Z0 + 0.25, MH - 0.17, "#84908C", outline="#5C6864", ow=0.07, smooth=False)
    for py in (-0.90, -0.76, -0.62):
        m.flat(_rect(-1.35, py, 0.56, 0.06), TOPO + 0.086, 0.010, "#5C6864", smooth=False)
    for sx in (-1, 1):
        m.flat(_chaikin(_rect(sx * 0.48, -0.65, 0.42, 0.52), 2), TOPO + 0.088, 0.020, "#98805C", outline="#685438", ow=0.07, smooth=False)
    m.flat(_chaikin(_rect(0.0, -0.22, 2.15, 0.48), 2), TOPO + 0.096, 0.020, "#88704C", outline="#685438", ow=0.08, smooth=False)
    m.flat(_chaikin(_rect(0.0, 0.26, 2.62, 0.92), 2), Z0, MH + 0.12, "#98805C", outline="#685438", ow=0.10, smooth=False)
    remendo = _chaikin(_barra_rot(0.75, 0.25, 0.52, 0.48, 28), 1)
    m.flat(remendo, TOPO + 0.126, 0.012, "#806848", smooth=False)
    alca_c = _chaikin([(-0.42, 0.35), (-0.38, 0.08), (0.0, 0.02), (0.38, 0.08), (0.42, 0.35), (0.22, 0.35), (0.18, 0.20), (-0.18, 0.20), (-0.22, 0.35)], 2)
    m.flat(alca_c, TOPO + 0.128, 0.020, "#98805C", outline="#685438", ow=0.07, smooth=False)


LOTE = [
    # 10 variantes de cor da mochila padrão
    ("padrao_verde", _make_padrao("#54703C", "#384828", "#608044", "#4C6434"), "#54703C", "#384828"),
    ("padrao_azul", _make_padrao("#34445C", "#242C3C", "#405470", "#2C3A50"), "#34445C", "#242C3C"),
    ("padrao_rosa", _make_padrao("#AC3C98", "#68245C", "#C04CAC", "#983488"), "#AC3C98", "#68245C"),
    ("padrao_turquesa", _make_padrao("#349494", "#1C5C5C", "#44ACAC", "#2C8080"), "#349494", "#1C5C5C"),
    ("padrao_branca", _make_padrao("#DCE4E8", "#98A4AC", "#ECF2F4", "#C8D0D4"), "#DCE4E8", "#98A4AC"),
    ("padrao_roxa", _make_padrao("#4C2468", "#2C143C", "#5C2C7C", "#401C58"), "#4C2468", "#2C143C"),
    ("padrao_ciano", _make_padrao("#1898D8", "#0C5880", "#28ACEC", "#1484BC"), "#1898D8", "#0C5880"),
    ("padrao_couro_gasto", _make_padrao("#94441C", "#5C240C", "#AC582C", "#843814"), "#94441C", "#5C240C"),
    ("padrao_escura", _make_padrao("#38302C", "#201C18", "#483C38", "#302824"), "#38302C", "#201C18"),
    ("padrao_noturna", _make_padrao("#282434", "#181420", "#343044", "#201C2C"), "#282434", "#181420"),

    # 4 variantes de bolsa com cristal/gema (diamante já está em mochilas5)
    ("bolsa_pedra", _make_bolsa_cristal("#7C8884", "#98A4A0", "#545C58"), "#804C28", "#543014"),
    ("bolsa_ouro", _make_bolsa_cristal("#C8AC30", "#E0C84C", "#8C7418"), "#804C28", "#543014"),
    ("bolsa_ametista", _make_bolsa_cristal("#AC5CD0", "#CC84EC", "#743494"), "#804C28", "#543014"),
    ("bolsa_rubi", _make_bolsa_cristal("#C03828", "#DC5848", "#841C10"), "#804C28", "#543014"),

    # 5 variantes de mochila com picareta (diamante já está em mochilas2)
    ("picareta_madeira", _make_picareta("#785838", "#4C341C", "#5C4024", "#3C2814"), "#A0481C", "#682408"),
    ("picareta_pedra", _make_picareta("#949C9C", "#606868", "#5C4024", "#3C2814"), "#A0481C", "#682408"),
    ("picareta_ouro", _make_picareta("#E8C430", "#AC8814", "#5C4024", "#3C2814"), "#A0481C", "#682408"),
    ("picareta_ametista", _make_picareta("#C45CE0", "#8428A4", "#0C181C", "#081014"), "#A0481C", "#682408"),
    ("picareta_rubi", _make_picareta("#C8442C", "#8C2414", "#5C5C5C", "#3C3C3C"), "#A0481C", "#682408"),

    # 5 variantes de espadas duplas (madeira já está em mochilas3)
    ("espadas_pedra", _make_espadas("#848C8C", "#545C5C", "#343838"), "#A0481C", "#682408"),
    ("espadas_diamante", _make_espadas("#5CE0E8", "#20A8A8", "#106868"), "#A0481C", "#682408"),
    ("espadas_ouro", _make_espadas("#E8C838", "#AC8C18", "#6C5408"), "#A0481C", "#682408"),
    ("espadas_rubi", _make_espadas("#D0442C", "#585858", "#343434"), "#A0481C", "#682408"),
    ("espadas_ametista", _make_espadas("#C45CE0", "#8428A4", "#4C1464"), "#A0481C", "#682408"),

    # 7 variantes especiais do catálogo
    ("fatia_bolo_morango", fatia_bolo_morango, "#6C4020", "#4C2810"),
    ("abobora_branca", abobora_branca, "#DCD8D0", "#ACA49C"),
    ("nuvem_por_do_sol", nuvem_por_do_sol, "#EC84AC", "#AC5C54"),
    ("fornalha_apagada", fornalha_apagada, "#8C8C8C", "#545454"),
    ("carapaca_ametista", _make_carapaca("#047848", "#045438", "#4C2470", "#8C54B8"), "#047848", "#045438"),
    ("carapaca_dourada", _make_carapaca("#8C5408", "#643C04", "#4C2470", "#8C54B8"), "#8C5408", "#643C04"),
    ("explorador_pa_couro", explorador_pa_couro, "#98805C", "#685438"),
]
