# Lote 15 — 20 skins de corpo básicas (10 cores/tons comuns + 10 estampas/texturas planas incomuns).
# Fecha o conjunto de 40 skins básicas (Lotes 14 e 15), totalizando 170 skins de corpo.
from skin_lib import *


def _chaikin(poly, passes=2):
    for _ in range(passes):
        poly = [
            p for a, b in zip(poly, poly[1:] + poly[:1])
            for p in ((0.75 * a[0] + 0.25 * b[0], 0.75 * a[1] + 0.25 * b[1]),
                      (0.25 * a[0] + 0.75 * b[0], 0.25 * a[1] + 0.75 * b[1]))
        ]
    return poly


def _anel_quads(s, cx, cy, r_in, r_out, z, thick, color, n=16):
    for i in range(n):
        a0 = 2 * math.pi * i / n
        a1 = 2 * math.pi * (i + 1) / n
        q = [
            (cx + r_in * math.cos(a0), cy + r_in * math.sin(a0)),
            (cx + r_out * math.cos(a0), cy + r_out * math.sin(a0)),
            (cx + r_out * math.cos(a1), cy + r_out * math.sin(a1)),
            (cx + r_in * math.cos(a1), cy + r_in * math.sin(a1)),
        ]
        s.flat(q, z, thick, color, smooth=False)


def _skin_cor_basica(s, sombra, brilho):
    s.base()
    faixa_lat = _chaikin([
        (1.22, 1.25), (1.56, 1.05), (1.58, -1.05), (1.15, -1.48),
        (1.02, -1.18), (1.30, 0.0), (1.12, 1.02)
    ], 2)
    s.sym(faixa_lat, TOP, 0.012, sombra, smooth=False)
    s.sym(ellipse(1.15, 1.18, 0.22, 0.12, n=12, rot=-0.45), TOP + 0.014, 0.012, brilho)
    s.hand_flat(ellipse(-0.14, 0.14, 0.18, 0.12, n=10, rot=0.4), 1.83, 0.02, brilho)


# ================================================================
# PARTE 1: 10 SKINS BÁSICAS DE COR / TOM (COMUNS)
# ================================================================
def basico_terra(s):
    _skin_cor_basica(s, "#544020", "#7C5C38")


def basico_castanho(s):
    _skin_cor_basica(s, "#5C3024", "#8C5438")


def basico_carvao(s):
    _skin_cor_basica(s, "#403434", "#685050")


def basico_terracota(s):
    _skin_cor_basica(s, "#5C302C", "#885444")


def basico_gelo(s):
    _skin_cor_basica(s, "#BCE4DC", "#F8FCFC")


def basico_creme(s):
    _skin_cor_basica(s, "#F0B848", "#FCF0B8")


def basico_lavanda(s):
    _skin_cor_basica(s, "#8898BC", "#C4D0EC")


def basico_obsidiana(s):
    _skin_cor_basica(s, "#10181C", "#28444C")


def basico_celeste(s):
    _skin_cor_basica(s, "#A4D4E8", "#F0FCFC")


def basico_rosado(s):
    _skin_cor_basica(s, "#E09898", "#FCE0DC")


# ================================================================
# PARTE 2: 10 SKINS BÁSICAS DE TEXTURA / ESTAMPA PLANA (INCOMUNS)
# ================================================================
def estampa_arco_iris(s):
    # Arco-íris vibrante de 6 cores cruzando em arco diagonal pelo topo + nuvens fofas nas pontas (ref. 2)
    # Em diagonal para parecer um arco-íris de verdade tanto em 90° quanto em 65° (sem formar "sorriso" em U!)
    s.base()
    cores_arco = [
        "#F44454",  # vermelho
        "#F88C30",  # laranja
        "#FCE038",  # amarelo
        "#50D864",  # verde
        "#3CA4F8",  # azul
        "#A058F4",  # roxo/violeta
    ]
    # Arco diagonal saindo da lateral esquerda (-1.54, 0.10..-0.90) curvando até a traseira/direita (-0.90..0.10, -1.54)
    # Raio máximo <= 1.68 para ficar longe do olho esquerdo (que está a r = 2.23 de (-1.55, -1.55))!
    cx, cy = -1.55, -1.55
    for i, cor in enumerate(cores_arco):
        r0 = 0.62 + i * 0.17
        r1 = r0 + 0.18
        pts_in = []
        pts_out = []
        for step in range(9):
            ang = 0.04 + (math.pi * 0.5 - 0.08) * (step / 8.0)
            x0 = max(-1.55, min(1.55, cx + r0 * math.cos(ang)))
            y0 = max(-1.55, min(1.55, cy + r0 * math.sin(ang)))
            x1 = max(-1.55, min(1.55, cx + r1 * math.cos(ang)))
            y1 = max(-1.55, min(1.55, cy + r1 * math.sin(ang)))
            pts_in.append((x0, y0))
            pts_out.append((x1, y1))
        pol = pts_in + list(reversed(pts_out))
        s.flat(pol, TOP + 0.005 + i * 0.001, 0.008, cor, smooth=False)

    # Nuvens fofas brancas nas duas pontas do arco-íris (longe dos olhos!)
    nuvem_cor, nuvem_borda = "#FFFFFF", "#88B4C8"
    for gomos in [
        # Nuvem na ponta esquerda do arco-íris (abaixo de y = 0 para não encostar no olho esquerdo)
        [(-1.32, -0.05, 0.24, 0.18), (-1.10, -0.15, 0.20, 0.16), (-1.40, -0.25, 0.20, 0.16)],
        # Nuvem na ponta traseira-direita do arco-íris
        [(-0.05, -1.32, 0.26, 0.18), (0.20, -1.25, 0.22, 0.16), (-0.28, -1.38, 0.20, 0.16)],
        # Nuvem menor no canto frontal-direito
        [(1.28, 1.30, 0.22, 0.16), (1.06, 1.38, 0.18, 0.15)],
    ]:
        for nx, ny, rx, ry in gomos:
            s.flat(ellipse(nx, ny, rx, ry, n=12), TOP + 0.015, 0.012, nuvem_cor, outline=nuvem_borda, ow=0.03)

    # Mãos com 3 faixas de arco-íris
    s.hand_flat([(-0.28, 0.08), (0.28, 0.08), (0.28, 0.22), (-0.28, 0.22)], 1.83, 0.018, "#F44454", smooth=False)
    s.hand_flat([(-0.30, -0.06), (0.30, -0.06), (0.30, 0.08), (-0.30, 0.08)], 1.835, 0.018, "#FCE038", smooth=False)
    s.hand_flat([(-0.28, -0.20), (0.28, -0.20), (0.28, -0.06), (-0.28, -0.06)], 1.84, 0.018, "#3CA4F8", smooth=False)


def estampa_pirulito(s):
    # Pirulito espiral (catavento vermelho, rosa-claro e branco-creme com brilho vítreo, ref. 5)
    s.base()
    verm, rosa, sombra, brilho = "#E41828", "#FF7488", "#EAE0D8", "#FFFFFF"
    # Sombra doce circular na borda externa
    _anel_quads(s, 0.0, 0.0, 1.32, 1.56, TOP, 0.008, sombra, n=24)

    # 8 pás curvas de espiral de pirulito girando a partir do centro (0, -0.15) até a borda do quadrado,
    # recortadas ao redor dos olhos para manter os olhos limpos!
    cx, cy = 0.0, -0.18
    n_pas = 8
    for i in range(n_pas):
        cor_pa = verm if i % 2 == 0 else rosa
        base_ang = 2 * math.pi * i / n_pas
        w_ang = math.pi / n_pas * 0.62
        pts_esq = []
        pts_dir = []
        for step in range(6):
            r = 0.22 + step * 0.27
            # Torção espiral progressiva
            twist = 0.55 * (r / 1.55)
            a1 = base_ang + twist
            a2 = base_ang + w_ang + twist
            x1 = max(-1.55, min(1.55, cx + r * math.cos(a1)))
            y1 = max(-1.55, min(1.55, cy + r * math.sin(a1)))
            x2 = max(-1.55, min(1.55, cx + r * math.cos(a2)))
            y2 = max(-1.55, min(1.55, cy + r * math.sin(a2)))
            pts_esq.append((x1, y1))
            pts_dir.append((x2, y2))
        pol = _chaikin(pts_esq + list(reversed(pts_dir)), 1)
        s.flat(pol, TOP + 0.010, 0.015, cor_pa, smooth=False)

    # Miolo redondo central da espiral do pirulito
    s.flat(ellipse(cx, cy, 0.34, 0.34, n=16), TOP + 0.026, 0.016, "#FCF8F4", outline=verm, ow=0.05)
    s.flat(ellipse(cx, cy, 0.16, 0.16, n=12), TOP + 0.043, 0.014, verm)

    # Margem branca limpa ao redor de cada olho para a espiral não invadir o olho
    for k in (-1, 1):
        _anel_quads(s, k * EYE_X, EYE_Y, 0.46, 0.64, TOP + 0.026, 0.016, "#FCF8F4", n=16)

    # Reflexos brancos curvos de calda de açúcar vitrificada nas bordas
    s.flat(_chaikin([(-1.38, 0.95), (-1.15, 1.32), (-0.75, 1.42), (-1.05, 1.12)], 2),
           TOP + 0.028, 0.014, brilho, smooth=False)
    s.flat(_chaikin([(1.15, -1.32), (1.42, -0.85), (1.25, -0.78), (1.02, -1.15)], 2),
           TOP + 0.028, 0.014, brilho, smooth=False)

    # Mãos com espiral vermelha e rosa
    s.hand_flat(_chaikin([(-0.32, 0.08), (0.32, 0.18), (0.20, -0.05), (-0.28, -0.12)], 1), 1.83, 0.02, verm, smooth=False)
    s.hand_flat(ellipse(0.0, 0.0, 0.14, 0.14, n=10), 1.85, 0.018, "#FCF8F4", outline=rosa, ow=0.03)


def estampa_bau(s):
    # Baú do tesouro reforçado (ref. 11): tábuas de madeira com veios, moldura metálica dourada,
    # cantoneiras com rebites, cintas de ferro dourado e fechadura ornamentada na frente
    s.base()
    madeira_cl, madeira_es, fresta = "#78542C", "#483014", "#241606"
    ouro, ouro_sombra, ouro_brilho = "#D4A428", "#8C6410", "#F8DC70"

    # Tábuas alternadas de madeira e frestas escuras horizontais (evitando o meio dos olhos)
    for y0, y1, cor_t in [
        (-1.42, -1.02, madeira_cl),
        (-0.96, -0.58, madeira_es),
        (-0.52, -0.16, madeira_cl),
        (1.08, 1.42, madeira_es),
    ]:
        s.flat([(-1.35, y0), (1.35, y0), (1.35, y1), (-1.35, y1)], TOP, 0.008, cor_t, smooth=False)
    for yy in (-1.00, -0.56, -0.14, 1.06):
        s.flat([(-1.48, yy - 0.03), (1.48, yy - 0.03), (1.48, yy + 0.03), (-1.48, yy + 0.03)],
               TOP + 0.009, 0.010, fresta, smooth=False)

    # Moldura externa de ouro ao redor das 4 bordas do baú
    s.flat([(-1.56, 1.36), (1.56, 1.36), (1.56, 1.56), (-1.56, 1.56)], TOP + 0.012, 0.018, ouro, outline=ouro_sombra, ow=0.025, smooth=False)
    s.flat([(-1.56, -1.56), (1.56, -1.56), (1.56, -1.36), (-1.56, -1.36)], TOP + 0.012, 0.018, ouro, outline=ouro_sombra, ow=0.025, smooth=False)

    # Duas cintas largas de ouro cravejadas de rebites atravessando de frente a trás nas laterais
    cinta = [(1.18, 1.56), (1.56, 1.56), (1.56, -1.56), (1.18, -1.56)]
    s.sym(cinta, TOP + 0.016, 0.020, ouro, outline=ouro_sombra, ow=0.03, smooth=False)
    s.sym([(1.28, 1.44), (1.44, 1.44), (1.44, -1.44), (1.28, -1.44)], TOP + 0.037, 0.010, ouro_brilho, smooth=False)

    # Rebites redondos dourados ao longo das cintas laterais e cantoneiras
    for ry in (-1.28, -0.78, -0.28, 0.28, 0.82, 1.28):
        s.sym(ellipse(1.36, ry, 0.08, 0.08, n=8), TOP + 0.048, 0.014, ouro_sombra)
        s.sym(ellipse(1.35, ry + 0.01, 0.05, 0.05, n=8), TOP + 0.062, 0.010, ouro_brilho)

    # Fechadura grande ornamentada na frente (+Y) com buraco da chave
    fecho_ext = _chaikin([(-0.46, 0.96), (0.46, 0.96), (0.52, 1.56), (-0.52, 1.56)], 1)
    s.flat(fecho_ext, TOP + 0.022, 0.022, ouro, outline=ouro_sombra, ow=0.035, smooth=False)
    s.flat([(-0.34, 1.06), (0.34, 1.06), (0.38, 1.48), (-0.38, 1.48)], TOP + 0.045, 0.010, ouro_brilho, smooth=False)
    # Buraco de fechadura (círculo + trapézio)
    s.flat(ellipse(0.0, 1.32, 0.11, 0.11, n=10), TOP + 0.056, 0.016, fresta)
    s.flat([(-0.06, 1.30), (0.06, 1.30), (0.10, 1.10), (-0.10, 1.10)], TOP + 0.056, 0.016, fresta, smooth=False)

    # Dobradiças traseiras (-Y)
    s.sym([(0.52, -1.56), (0.78, -1.56), (0.78, -1.24), (0.52, -1.24)], TOP + 0.022, 0.020, ouro, outline=ouro_sombra, ow=0.025, smooth=False)
    s.hand_flat([(-0.32, -0.12), (0.32, -0.12), (0.32, 0.12), (-0.32, 0.12)], 1.83, 0.02, ouro, outline=ouro_sombra, ow=0.025, smooth=False)


def estampa_panqueca(s):
    # Pilha de 3 panquecas bem definidas (com massa clara fofa + topo assado dourado em cada nível),
    # calda de mel escorrendo sobre os degraus e quadradinho de manteiga (ref. 52)
    s.base()
    massa_borda_fofa = "#F4DCAC"
    assado_1, assado_2, assado_3 = "#B87430", "#CC8840", "#E0A45C"
    vincos = "#6C3C10"
    calda, calda_cl, manteiga, mant_borda = "#C86804", "#F4AC28", "#FCF4A4", "#D8A828"

    # Nível 1 (panqueca inferior: anel de massa fofa clara + sulco escuro de separação)
    # Camadas bem fininhas em Z (0.003) para o topo da 3ª panqueca ficar abaixo dos olhos (z < 2.020)!
    niv1 = _chaikin([
        (-1.55, 1.45), (0.0, 1.56), (1.55, 1.45), (1.56, 0.0),
        (1.55, -1.45), (0.0, -1.56), (-1.55, -1.45), (-1.56, 0.0)
    ], 2)
    s.flat(niv1, TOP, 0.003, massa_borda_fofa, outline=vincos, ow=0.045, smooth=False)
    niv1_topo = _chaikin([
        (-1.46, 1.36), (0.0, 1.48), (1.46, 1.36), (1.48, 0.0),
        (1.46, -1.36), (0.0, -1.48), (-1.46, -1.36), (-1.48, 0.0)
    ], 2)
    s.flat(niv1_topo, TOP + 0.003, 0.003, assado_1, smooth=False)

    # Nível 2 (panqueca do meio: degrau bem marcado com borda fofa clara + interior dourado)
    niv2 = _chaikin([
        (-1.32, 1.22), (0.0, 1.34), (1.32, 1.22), (1.36, 0.0),
        (1.32, -1.22), (0.0, -1.34), (-1.32, -1.22), (-1.36, 0.0)
    ], 2)
    s.flat(niv2, TOP + 0.006, 0.003, massa_borda_fofa, outline=vincos, ow=0.045, smooth=False)
    niv2_topo = _chaikin([
        (-1.24, 1.14), (0.0, 1.25), (1.24, 1.14), (1.26, 0.0),
        (1.24, -1.14), (0.0, -1.25), (-1.24, -1.14), (-1.26, 0.0)
    ], 2)
    s.flat(niv2_topo, TOP + 0.009, 0.003, assado_2, smooth=False)

    # Nível 3 (panqueca superior onde ficam os olhos, a calda e a manteiga)
    niv3 = _chaikin([
        (-1.10, 1.02), (0.0, 1.12), (1.10, 1.02), (1.14, 0.0),
        (1.10, -1.02), (0.0, -1.12), (-1.10, -1.02), (-1.14, 0.0)
    ], 2)
    s.flat(niv3, TOP + 0.012, 0.003, massa_borda_fofa, outline=vincos, ow=0.045, smooth=False)
    niv3_topo = _chaikin([
        (-1.02, 0.94), (0.0, 1.04), (1.02, 0.94), (1.05, 0.0),
        (1.02, -0.94), (0.0, -1.04), (-1.02, -0.94), (-1.05, 0.0)
    ], 2)
    s.flat(niv3_topo, TOP + 0.015, 0.003, assado_3, smooth=False)

    # Calda de mel escorrendo do centro-traseiro pelas laterais e degraus (sem bigode abaixo dos olhos!)
    calda_puddle = _chaikin([
        (-0.85, -0.18), (-1.42, -0.45), (-1.48, -0.95), (-1.05, -1.52),
        (-0.35, -1.28), (0.15, -1.54), (0.68, -1.28), (1.25, -1.48),
        (1.50, -0.78), (1.35, -0.15), (0.72, -0.35), (0.0, -0.22)
    ], 2)
    s.flat(calda_puddle, TOP + 0.019, 0.012, calda, outline="#7C3C00", ow=0.03, smooth=False)
    s.flat(_chaikin([(-0.78, -0.52), (0.78, -0.52), (0.95, -1.08), (-0.95, -1.08)], 2),
           TOP + 0.032, 0.008, calda_cl, smooth=False)

    # Quadradinho de manteiga derretendo no topo da pilha com brilho cremoso
    mant = _chaikin([(-0.45, -0.48), (0.22, -0.38), (0.32, -0.98), (-0.35, -1.08)], 1)
    s.flat(mant, TOP + 0.041, 0.022, manteiga, outline=mant_borda, ow=0.04, smooth=False)
    s.flat(ellipse(0.48, -0.82, 0.14, 0.10, n=10, rot=0.3), TOP + 0.041, 0.014, manteiga)
    s.hand_flat(ellipse(0.0, 0.0, 0.28, 0.22, n=12), 1.83, 0.02, calda, outline=vincos, ow=0.03)


def estampa_bolo(s):
    # Bolo confeitado granulado (ref. 45): cobertura lisa de glacê branco-baunilha com borda
    # ondulada rosa, fileira de pitangas de chantilly e cerejas nas bordas, e muitos granulados!
    s.base()
    glace, glace_rosa, chantilly = "#FFF8F2", "#F490B0", "#FFFFFF"
    cereja, cereja_br = "#D8182C", "#FF7888"

    # Cobertura generosa de glacê cobrindo o topo inteiro (bem fininha para não cobrir a borda dos olhos!)
    cobertura_ext = _chaikin([
        (-1.46, 1.46), (0.0, 1.54), (1.46, 1.46), (1.54, 0.0),
        (1.46, -1.46), (0.0, -1.54), (-1.46, -1.46), (-1.54, 0.0)
    ], 2)
    s.flat(cobertura_ext, TOP, 0.003, glace, outline=glace_rosa, ow=0.055, smooth=False)

    # Dezenas de pitangas de chantilly contornando as bordas do bolo + 4 cerejas nos cantos
    for px, py in [
        (-0.65, 1.38), (0.0, 1.40), (0.65, 1.38),
        (-1.38, 0.65), (-1.40, 0.0), (-1.38, -0.65),
        (1.38, 0.65), (1.40, 0.0), (1.38, -0.65),
        (-0.65, -1.38), (0.0, -1.40), (0.65, -1.38),
    ]:
        s.flat(ellipse(px, py, 0.16, 0.16, n=10), TOP + 0.008, 0.010, chantilly, outline="#E4CCD4", ow=0.025)

    for cx, cy in [(-1.18, 1.18), (1.18, 1.18), (-1.18, -1.18), (1.18, -1.18)]:
        s.flat(ellipse(cx, cy, 0.24, 0.24, n=12), TOP + 0.008, 0.014, chantilly, outline="#DCC4CC", ow=0.03)
        s.flat(ellipse(cx, cy, 0.13, 0.13, n=10), TOP + 0.024, 0.014, cereja)
        s.flat(ellipse(cx - 0.03, cy + 0.03, 0.05, 0.05, n=8), TOP + 0.039, 0.008, cereja_br)

    # Muitos granulados coloridos bem distribuídos sobre o glacê branco (todos a distância > 0.68 dos olhos!)
    g_rosa, g_azul, g_amarelo, g_roxo, g_verde, g_laranja = (
        "#F44888", "#2CA8F0", "#F8D020", "#9C48E8", "#44CC58", "#F87C24"
    )
    granulados = [
        # Frente (acima dos olhos)
        (-0.35, 1.18, 0.35, g_rosa), (0.0, 1.15, -0.25, g_azul), (0.35, 1.18, 0.40, g_verde),
        # Entre os olhos
        (0.0, 0.78, 0.90, g_laranja), (0.0, 0.32, -0.80, g_rosa),
        # Faixa logo atrás dos olhos (y <= -0.18 para ficar longe de EYE_Y = 0.55)
        (-1.12, -0.18, -0.30, g_amarelo), (-0.42, -0.18, 0.25, g_roxo),
        (0.0, -0.16, -0.15, g_azul), (0.42, -0.18, -0.35, g_verde), (1.12, -0.18, 0.35, g_rosa),
        # Meio-traseiro
        (-0.95, -0.50, -0.40, g_laranja), (-0.42, -0.48, 0.30, g_rosa),
        (0.0, -0.52, 0.55, g_amarelo), (0.42, -0.48, -0.30, g_roxo), (0.95, -0.50, 0.45, g_azul),
        # Traseira
        (-0.78, -0.85, 0.20, g_verde), (-0.28, -0.82, -0.35, g_azul),
        (0.28, -0.82, 0.25, g_laranja), (0.78, -0.85, -0.25, g_amarelo),
        (-0.52, -1.12, -0.35, g_roxo), (0.0, -1.10, 0.15, g_rosa), (0.52, -1.12, 0.35, g_verde),
    ]
    for gx, gy, rot, col in granulados:
        s.flat(ellipse(gx, gy, 0.15, 0.06, n=10, rot=rot), TOP + 0.008, 0.006, col, smooth=False)

    # Mãos cobertas de glacê com granulados
    s.hand_flat(ellipse(0.0, 0.0, 0.28, 0.22, n=12), 1.83, 0.018, glace, outline=glace_rosa, ow=0.03)
    s.hand_flat(ellipse(-0.08, 0.05, 0.11, 0.045, n=8, rot=0.4), 1.85, 0.014, g_rosa)
    s.hand_flat(ellipse(0.08, -0.04, 0.11, 0.045, n=8, rot=-0.5), 1.85, 0.014, g_azul)


def estampa_lava(s):
    # Crosta de magma vulcânico (ref. 87 / 64): fundo incandescente de lava com placas poligonais
    # de basalto escuro separadas por rios de lava brilhantes (vermelho -> laranja -> amarelo)
    s.base()
    magma_verm, lava_lar, lava_am = "#B82000", "#F46800", "#FFD020"
    rocha_1, rocha_2, rocha_borda = "#2C1E18", "#3C2820", "#18100C"

    # Camada base de magma incandescente sob as fendas (cobrindo o topo, exceto os olhos)
    fundo_lava = _chaikin([
        (-1.52, 1.48), (0.0, 1.54), (1.52, 1.48), (1.54, 0.0),
        (1.52, -1.48), (0.0, -1.54), (-1.52, -1.48), (-1.54, 0.0)
    ], 2)
    s.flat(fundo_lava, TOP, 0.012, magma_verm, emit=0.5, smooth=False)
    s.flat(_chaikin([
        (-1.42, 1.38), (0.0, 1.44), (1.42, 1.38), (1.44, 0.0),
        (1.42, -1.38), (0.0, -1.44), (-1.42, -1.38), (-1.44, 0.0)
    ], 2), TOP + 0.013, 0.010, lava_lar, emit=0.8, smooth=False)

    # Veios centrais amarelo-claros de lava derretida entre as placas
    for vx, vy, rx, ry, rot in [
        (-1.12, -0.15, 0.42, 0.09, 0.35), (1.12, -0.15, 0.42, 0.09, -0.35),
        (-0.55, -0.78, 0.48, 0.09, -0.45), (0.55, -0.78, 0.48, 0.09, 0.45),
        (0.0, 1.18, 0.45, 0.08, 0.0), (-1.15, 1.05, 0.35, 0.08, -0.6), (1.15, 1.05, 0.35, 0.08, 0.6),
    ]:
        s.flat(ellipse(vx, vy, rx, ry, n=10, rot=rot), TOP + 0.024, 0.010, lava_am, emit=1.1)

    # Placas poligonais de rocha basáltica flutuando sobre a lava (deixando os rios de lava aparentes!)
    placas_basalto = [
        # Placas ao redor dos olhos (protegendo a leitura dos olhos)
        ([(-1.38, 1.05), (-0.28, 1.08), (-0.22, 0.05), (-1.28, -0.05)], rocha_1),
        ([(0.28, 1.08), (1.38, 1.05), (1.28, -0.05), (0.22, 0.05)], rocha_1),
        # Placa frontal superior
        ([(-0.88, 1.52), (0.88, 1.52), (0.68, 1.24), (-0.68, 1.24)], rocha_2),
        # Placas laterais médias
        ([(-1.54, 0.85), (-1.42, 0.85), (-1.35, -0.72), (-1.54, -0.65)], rocha_2),
        ([(1.42, 0.85), (1.54, 0.85), (1.54, -0.65), (1.35, -0.72)], rocha_2),
        # Mosaico de placas vulcânicas na metade traseira (assimétrico para não formar "boca")
        ([(-1.22, -0.25), (-0.18, -0.18), (-0.32, -0.72), (-1.18, -0.82)], rocha_2),
        ([(0.08, -0.18), (1.22, -0.25), (1.18, -0.82), (0.25, -0.68)], rocha_1),
        ([(-1.42, -0.98), (-0.52, -0.92), (-0.68, -1.50), (-1.45, -1.45)], rocha_1),
        ([(-0.32, -0.88), (0.48, -0.85), (0.35, -1.52), (-0.45, -1.52)], rocha_2),
        ([(0.65, -0.92), (1.42, -0.98), (1.45, -1.45), (0.58, -1.50)], rocha_1),
    ]
    for pts, cor_r in placas_basalto:
        s.flat(_chaikin(pts, 1), TOP + 0.026, 0.018, cor_r, outline=rocha_borda, ow=0.025, smooth=False)

    # Bolhas incandescentes de lava nas junções
    for bx, by, br in [(-0.05, -0.10, 0.11), (-0.45, -0.82, 0.10), (0.52, -0.78, 0.12), (0.0, 1.16, 0.10)]:
        s.flat(ellipse(bx, by, br, br, n=10), TOP + 0.032, 0.016, lava_lar, emit=0.9)
        s.flat(ellipse(bx, by, br * 0.55, br * 0.55, n=8), TOP + 0.048, 0.012, lava_am, emit=1.2)

    s.hand_flat(ellipse(0.0, 0.0, 0.28, 0.22, n=10), 1.83, 0.018, magma_verm, emit=0.6)
    s.hand_flat(_chaikin([(-0.22, 0.08), (0.18, 0.14), (0.22, -0.08), (-0.18, -0.12)], 1),
                1.85, 0.016, rocha_1, smooth=False)
    s.hand_flat(ellipse(0.0, 0.0, 0.10, 0.08, n=8), 1.868, 0.014, lava_am, emit=1.1)


def estampa_vudu(s):
    # Boneco de estopa costurado (ref. 111): remendos e pontos de costura nas bordas
    s.base()
    remendo, linha = "#B4A07C", "#482810"
    # Remendo de tecido no canto traseiro esquerdo
    rem = _chaikin([(-1.52, -0.35), (-0.58, -0.52), (-0.68, -1.52), (-1.52, -1.42)], 1)
    s.flat(rem, TOP, 0.012, remendo, outline=linha, ow=0.04, smooth=False)
    # Pontinhos transversais de costura no remendo e no canto frontal direito
    for px, py, rot in [
        (-1.05, -0.44, 1.4), (-0.75, -0.48, 1.4),
        (-0.62, -0.82, 0.1), (-0.65, -1.18, 0.1),
        (1.05, 1.25, -0.7), (1.25, 1.05, -0.7), (1.42, 0.85, -0.7),
        (0.85, -1.05, 0.6), (1.08, -1.25, 0.6),
    ]:
        s.flat(ellipse(px, py, 0.14, 0.045, n=8, rot=rot), TOP + 0.015, 0.015, linha)
    # Aros de botão marrons ao redor dos dois olhos
    for k in (-1, 1):
        _anel_quads(s, k * EYE_X, EYE_Y, 0.48, 0.58, TOP + 0.014, 0.018, linha, n=14)
    s.hand_flat(ellipse(0.0, 0.0, 0.22, 0.05, n=8, rot=0.4), 1.83, 0.02, linha)


def estampa_gelo_bloco(s):
    # Cubo/cristal de gelo facetado (ref. 142) usando exatamente a linguagem visual e paleta
    # das mochilas de gelo (cubo_gelo / espirito_gelo / cristais_gelo):
    # corpo azul-gelo translúcido #BCE8F4, contorno azul-petróleo #187494, facetas angulares retas
    # (#E8FAFA, #D0EEF4, #88CCE4), faixas diagonais de reflexo branco (#FFFFFF) e trincas de gelo!
    s.base()
    f_branca_gelo, f_clara, f_media, f_sombra = "#E8FAFA", "#D0EEF4", "#98D8EC", "#68B4D4"
    trinca, brilho = "#187494", "#FFFFFF"

    # Bisel externo de sombra de gelo ao redor das bordas do cubo
    s.sym([(1.28, 1.48), (1.55, 1.32), (1.55, -1.32), (1.28, -1.48), (1.36, 0.0)],
          TOP, 0.010, f_sombra, smooth=False)
    s.flat([(-1.35, -1.32), (1.35, -1.32), (1.48, -1.55), (-1.48, -1.55)],
           TOP, 0.010, f_sombra, smooth=False)

    # Grandes facetas geométricas angulares de cristal de gelo (retas, sem arredondar como pedrinhas!)
    facetas = [
        # Grande faceta iluminada superior/frontal
        ([(-1.42, 1.52), (0.35, 1.54), (-0.15, 1.08), (-1.48, 0.95)], f_branca_gelo),
        ([(0.35, 1.54), (1.42, 1.52), (1.48, 0.95), (-0.15, 1.08)], f_clara),
        # Facetas laterais angulares
        ([(-1.52, 0.92), (-1.18, 0.65), (-1.22, -0.45), (-1.52, -0.78)], f_clara),
        ([(1.18, 0.65), (1.52, 0.92), (1.52, -0.78), (1.22, -0.45)], f_media),
        # Grandes planos cristalinos na metade traseira do cubo de gelo
        ([(-1.22, -0.25), (0.18, -0.15), (-0.28, -0.92), (-1.45, -0.82)], f_branca_gelo),
        ([(0.18, -0.15), (1.22, -0.25), (1.45, -0.82), (-0.28, -0.92)], f_clara),
        ([(-1.42, -0.85), (-0.28, -0.92), (-0.55, -1.48), (-1.45, -1.42)], f_media),
        ([(-0.28, -0.92), (0.65, -0.85), (0.42, -1.50), (-0.55, -1.48)], f_branca_gelo),
        ([(0.65, -0.85), (1.42, -0.85), (1.45, -1.42), (0.42, -1.50)], f_sombra),
    ]
    for pts, cor_f in facetas:
        s.flat(pts, TOP + 0.005, 0.006, cor_f, smooth=False)

    # Faixas diagonais de reflexo especular branco puro atravessando o cubo de gelo
    reflexos = [
        [(-1.38, 0.05), (-0.18, 1.25), (0.05, 1.25), (-1.38, -0.18)],
        [(-1.15, -1.38), (0.85, 0.62), (0.98, 0.62), (-1.02, -1.38)],
        [(-0.35, -1.45), (1.38, 0.28), (1.38, 0.02), (-0.08, -1.45)],
    ]
    for r_pts in reflexos:
        s.flat(r_pts, TOP + 0.012, 0.005, brilho, smooth=False)

    # Trincas angulares de gelo azul-petróleo (#187494) nas bordas
    trincas = [
        [(-1.52, -0.22), (-0.82, -0.45), (-0.42, -0.18), (-0.80, -0.52), (-1.52, -0.30)],
        [(1.52, -0.58), (0.78, -0.82), (0.45, -1.28), (0.86, -0.88), (1.52, -0.66)],
        [(-0.55, 1.52), (-0.18, 1.12), (0.22, 1.28), (-0.18, 1.04), (-0.64, 1.52)],
    ]
    for t_pts in trincas:
        s.flat(t_pts, TOP + 0.018, 0.010, trinca, smooth=False)

    # Brilhos estelares de cristal de gelo (4 pontas brancas) nos cantos
    for gx, gy, r in [(-1.05, -0.58, 0.20), (0.95, 1.22, 0.18), (0.15, -1.15, 0.18)]:
        estrela = [
            (gx, gy + r), (gx + r * 0.25, gy + r * 0.25),
            (gx + r, gy), (gx + r * 0.25, gy - r * 0.25),
            (gx, gy - r), (gx - r * 0.25, gy - r * 0.25),
            (gx - r, gy), (gx - r * 0.25, gy + r * 0.25),
        ]
        s.flat(estrela, TOP + 0.032, 0.014, brilho, smooth=False)

    # Mãos de cubo de gelo translúcido com faceta branca
    s.hand_flat([(-0.28, 0.16), (0.26, 0.18), (0.28, -0.14), (-0.24, -0.18)],
                1.83, 0.018, f_branca_gelo, outline=trinca, ow=0.03, smooth=False)
    s.hand_flat([(-0.20, -0.10), (0.12, 0.16), (0.22, 0.16), (-0.10, -0.10)],
                1.85, 0.012, brilho, smooth=False)


def estampa_pirata(s):
    # Pirata detalhado (ref. 183): bandana vermelha amarrada com dobras, caveirinha/bolinhas brancas,
    # debrum dourado e nó lateral; tapa-olho de couro costurado com fivela dourada; cicatriz em X e brinco de ouro
    s.base()
    couro, couro_cl, couro_borda = "#3C2228", "#643C44", "#201014"
    bandana, bandana_sombra, bandana_cl = "#BC2028", "#801218", "#E8545C"
    ouro, ouro_sombra = "#E4B028", "#946C10"
    cicatriz, cicatriz_pt = "#B08C80", "#6C4840"

    # Grande bandana pirata cobrindo a diagonal traseira e lateral esquerda até a borda externa
    corpo_bandana = _chaikin([
        (-1.56, 0.65), (-0.85, 0.22), (0.25, -0.42), (1.35, -0.82), (1.56, -0.85),
        (1.54, -1.45), (1.18, -1.56), (-1.18, -1.56), (-1.56, -1.18)
    ], 2)
    s.flat(corpo_bandana, TOP, 0.016, bandana, outline=bandana_sombra, ow=0.035, smooth=False)

    # Faixa de debrum dourado acompanhando a borda da bandana
    debrum = _chaikin([
        (-1.55, 0.62), (-0.85, 0.20), (0.25, -0.44), (1.55, -0.86),
        (1.55, -0.98), (0.20, -0.56), (-0.90, 0.08), (-1.55, 0.48)
    ], 2)
    s.flat(debrum, TOP + 0.018, 0.012, ouro, smooth=False)

    # Dobras de tecido escuras e claras na bandana
    for d_pts, cor_d in [
        ([(-1.42, -0.15), (-0.25, -0.78), (-0.42, -0.92), (-1.48, -0.35)], bandana_sombra),
        ([(-1.35, -0.58), (0.25, -1.25), (0.05, -1.38), (-1.45, -0.78)], bandana_cl),
        ([(0.15, -0.82), (1.28, -1.22), (1.12, -1.35), (0.02, -0.95)], bandana_sombra),
    ]:
        s.flat(_chaikin(d_pts, 1), TOP + 0.018, 0.012, cor_d, smooth=False)

    # Estampa clássica de bandana pirata (bolinhas brancas e emblema de caveirinha estilizada no pano)
    for bx, by in [(-1.12, 0.05), (-0.45, -0.48), (0.48, -0.88), (1.05, -1.08), (-0.18, -1.18), (0.65, -1.35)]:
        s.flat(ellipse(bx, by, 0.08, 0.08, n=10), TOP + 0.020, 0.012, "#F8F0E8")
    # Emblema de caveirinha branca com ossos cruzados na bandana (-0.88, -0.98)
    kx, ky = -0.88, -0.98
    s.flat([(kx - 0.24, ky - 0.14), (kx + 0.24, ky + 0.14), (kx + 0.20, ky + 0.20), (kx - 0.28, ky - 0.08)],
           TOP + 0.020, 0.012, "#F8F0E8", smooth=False)
    s.flat([(kx - 0.24, ky + 0.14), (kx + 0.24, ky - 0.14), (kx + 0.20, ky - 0.20), (kx - 0.28, ky + 0.08)],
           TOP + 0.020, 0.012, "#F8F0E8", smooth=False)
    s.flat(ellipse(kx, ky + 0.03, 0.16, 0.15, n=12), TOP + 0.032, 0.014, "#F8F0E8", outline=bandana_sombra, ow=0.02)
    s.flat(ellipse(kx - 0.06, ky + 0.04, 0.04, 0.04, n=8), TOP + 0.047, 0.010, couro_borda)
    s.flat(ellipse(kx + 0.06, ky + 0.04, 0.04, 0.04, n=8), TOP + 0.047, 0.010, couro_borda)

    # Nó volumoso da bandana e duas pontas caídas no canto traseiro-esquerdo
    s.flat(ellipse(-1.38, -1.18, 0.22, 0.20, n=12), TOP + 0.024, 0.022, bandana, outline=bandana_sombra, ow=0.035)
    s.flat(_chaikin([(-1.56, -1.12), (-1.28, -1.25), (-1.38, -1.56), (-1.56, -1.48)], 1),
           TOP + 0.018, 0.018, bandana_cl, outline=bandana_sombra, ow=0.025, smooth=False)

    # Brinco de argola de ouro pirata na lateral esquerda (-X)
    _anel_quads(s, -1.42, 0.85, 0.10, 0.19, TOP + 0.022, 0.020, ouro, n=12)

    # Tira dupla de couro do tapa-olho com fivela dourada cruzando pelo olho direito (+EYE_X, EYE_Y)
    tira_sup = [(-0.78, 1.56), (-0.48, 1.56), (0.45, 0.86), (0.25, 0.72)]
    tira_inf = [(1.18, 0.34), (1.56, 0.02), (1.56, 0.28), (1.30, 0.52)]
    s.flat(tira_sup, TOP + 0.020, 0.020, couro, outline=couro_borda, ow=0.02, smooth=False)
    s.flat(tira_inf, TOP + 0.020, 0.020, couro, outline=couro_borda, ow=0.02, smooth=False)
    # Fivela quadrada dourada na tira do tapa-olho
    s.flat([(-0.18, 1.24), (0.04, 1.08), (-0.08, 0.94), (-0.30, 1.10)],
           TOP + 0.041, 0.016, ouro, outline=ouro_sombra, ow=0.02, smooth=False)

    # Aro largo de couro costurado do tapa-olho ao redor do olho direito (+EYE_X, EYE_Y)
    _anel_quads(s, EYE_X, EYE_Y, 0.46, 0.68, TOP + 0.022, 0.024, couro, n=18)
    _anel_quads(s, EYE_X, EYE_Y, 0.52, 0.60, TOP + 0.047, 0.010, couro_cl, n=18)

    # Cicatriz de batalha costurada na bochecha frontal-esquerda (acima do olho esquerdo)
    s.flat([(-1.28, 1.38), (-0.88, 1.08), (-0.95, 1.00), (-1.35, 1.30)], TOP + 0.016, 0.014, cicatriz, smooth=False)
    for sx, sy in [(-1.18, 1.26), (-1.08, 1.18), (-0.98, 1.10)]:
        s.flat(ellipse(sx, sy, 0.09, 0.03, n=8, rot=0.85), TOP + 0.031, 0.012, cicatriz_pt)

    # Punhos piratas nas mãos (faixa vermelha + botão dourado)
    s.hand_flat([(-0.32, -0.10), (0.32, -0.10), (0.32, 0.10), (-0.32, 0.10)],
                1.83, 0.02, bandana, outline=bandana_sombra, ow=0.025, smooth=False)
    s.hand_flat(ellipse(0.0, 0.0, 0.09, 0.09, n=10), 1.852, 0.016, ouro)


def estampa_mapa(s):
    # Mapa do tesouro em pergaminho (ref. 240): ilha, trilha pontilhada e X vermelho
    s.base()
    ilha, trilha, x_verm = "#ACA06C", "#645434", "#B42424"
    # Contorno de ilha antiga nos cantos traseiros/laterais
    s.flat(_chaikin([
        (-1.52, 0.45), (-1.12, 0.25), (-1.18, -0.65), (-0.55, -0.88),
        (-0.68, -1.48), (-1.48, -1.38)
    ], 2), TOP, 0.012, ilha, smooth=False)
    s.flat(_chaikin([
        (0.55, -0.72), (1.38, -0.58), (1.52, -1.35), (0.68, -1.52)
    ], 2), TOP, 0.012, ilha, smooth=False)
    # Trilha pontilhada levando até o X no canto traseiro direito
    for px, py, rot in [
        (-1.25, 1.15, -0.5), (-1.32, 0.78, -1.2), (-0.95, -0.45, -0.4),
        (-0.45, -0.72, -0.2), (0.05, -0.82, 0.1), (0.48, -0.92, -0.2)
    ]:
        s.flat(ellipse(px, py, 0.11, 0.05, n=8, rot=rot), TOP + 0.014, 0.014, trilha)
    # "X" vermelho marcando o tesouro em (1.02, -1.05)
    cx, cy = 1.02, -1.05
    s.flat([(cx - 0.24, cy - 0.18), (cx + 0.18, cy + 0.24), (cx + 0.26, cy + 0.16), (cx - 0.16, cy - 0.26)],
           TOP + 0.016, 0.018, x_verm, smooth=False)
    s.flat([(cx - 0.16, cy + 0.24), (cx + 0.26, cy - 0.18), (cx + 0.18, cy - 0.26), (cx - 0.24, cy + 0.16)],
           TOP + 0.016, 0.018, x_verm, smooth=False)
    s.hand_flat(ellipse(0.0, 0.0, 0.22, 0.16, n=10), 1.83, 0.02, ilha)


LOTE = [
    # 10 básicas de cor / tom (Comuns)
    ("basico_terra", basico_terra, "#644828", "#342814", "#644828", "#342814"),
    ("basico_castanho", basico_castanho, "#704028", "#3C2020", "#704028", "#3C2020"),
    ("basico_carvao", basico_carvao, "#503C3C", "#2C2024", "#503C3C", "#2C2024"),
    ("basico_terracota", basico_terracota, "#6C4034", "#482428", "#6C4034", "#482428"),
    ("basico_gelo", basico_gelo, "#DCF4F0", "#3C9480", "#DCF4F0", "#3C9480"),
    ("basico_creme", basico_creme, "#FCD474", "#E48C08", "#FCD474", "#E48C08"),
    ("basico_lavanda", basico_lavanda, "#A4B4D8", "#3C485C", "#A4B4D8", "#3C485C"),
    ("basico_obsidiana", basico_obsidiana, "#182428", "#187484", "#182428", "#187484"),
    ("basico_celeste", basico_celeste, "#CCECF4", "#1868A0", "#CCECF4", "#1868A0"),
    ("basico_rosado", basico_rosado, "#F4BCB8", "#B42028", "#F4BCB8", "#B42028"),
    # 10 básicas de textura / estampa plana (Incomuns)
    ("estampa_arco_iris", estampa_arco_iris, "#B8FCF4", "#688C98", "#B8FCF4", "#688C98"),
    ("estampa_pirulito", estampa_pirulito, "#FCF8F4", "#D42434", "#FCF8F4", "#D42434"),
    ("estampa_bau", estampa_bau, "#604424", "#281C08", "#604424", "#281C08"),
    ("estampa_panqueca", estampa_panqueca, "#E4C498", "#A06C30", "#E4C498", "#A06C30"),
    ("estampa_bolo", estampa_bolo, "#B08844", "#785828", "#B08844", "#785828"),
    ("estampa_lava", estampa_lava, "#2C2014", "#443020", "#2C2014", "#443020"),
    ("estampa_vudu", estampa_vudu, "#D4C4A4", "#482810", "#D4C4A4", "#482810"),
    ("estampa_gelo_bloco", estampa_gelo_bloco, "#BCE8F4", "#187494", "#BCE8F4", "#187494"),
    ("estampa_pirata", estampa_pirata, "#E4D4BC", "#80544C", "#E4D4BC", "#80544C"),
    ("estampa_mapa", estampa_mapa, "#D0C08C", "#8C7C50", "#D0C08C", "#8C7C50"),
]
