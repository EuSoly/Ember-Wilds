# Lote 4 — skins de corpo. Montar com build_skins.py (Blender aberto) ou render_lote.py (segundo plano).
from skin_lib import *


# ---------------------------------------------------------------- ajudantes do lote
def _faixa(centro, w0, w1):
    # tira de largura variável (meia-largura w0 -> w1) ao longo de uma linha central (rabos, talos, chifres)
    n = len(centro); esq, dir_ = [], []
    for i, (x, y) in enumerate(centro):
        a = centro[max(i - 1, 0)]; b = centro[min(i + 1, n - 1)]
        dx, dy = b[0] - a[0], b[1] - a[1]; L = math.hypot(dx, dy) or 1
        nx, ny = -dy / L, dx / L
        w = w0 + (w1 - w0) * i / (n - 1)
        esq.append((x + nx*w, y + ny*w)); dir_.append((x - nx*w, y - ny*w))
    return esq + list(reversed(dir_))

def _raio_corpo(a):
    # raio da borda do corpo (quadrado arredondado ~ superelipse) no ângulo a
    c, s_ = abs(math.cos(a)), abs(math.sin(a))
    return 1.85 / (c**4 + s_**4) ** 0.25

def _pol(a, r, cx=0.0, cy=0.0):
    return (cx + math.cos(a) * r, cy + math.sin(a) * r)

def _pena(x0, y0, ang, L, w, n=12):
    # pena/folha oval saindo de (x0, y0) na direção ang (radianos)
    return ellipse(x0 + math.cos(ang) * L / 2, y0 + math.sin(ang) * L / 2, L / 2, w, n=n, rot=ang)

def _mancha(cx, cy, r, seed, n=9, sx=1.0, sy=1.0, rot=0.0):
    # mancha irregular (raio varia de forma fixa pela semente)
    pts = []
    for i in range(n):
        a = 2*math.pi*i/n + rot
        k = 1 + 0.26*math.sin(seed*1.7 + i*2.3) + 0.12*math.sin(seed*0.9 + i*4.1)
        pts.append((cx + math.cos(a)*r*k*sx, cy + math.sin(a)*r*k*sy))
    return pts

def _arco(cx, cy, r0, r1, a0, a1, n=12):
    # pedaço de anel de a0 a a1 (radianos), raios r0 (dentro) e r1 (fora)
    A = [a0 + (a1 - a0)*i/(n - 1) for i in range(n)]
    return [_pol(a, r1, cx, cy) for a in A] + [_pol(a, r0, cx, cy) for a in reversed(A)]

def _folha_recortada(x0, y0, ang, L, w, lobos=4):
    # folha comprida com borda em lóbulos (rama da cenoura)
    ca, sa = math.cos(ang), math.sin(ang)
    P = lambda u, v: (x0 + ca*u - sa*v, y0 + sa*u + ca*v)
    esq, dir_ = [], []
    m = lobos*2
    for i in range(1, m + 1):
        t = i / (m + 1)
        env = w * math.sin(math.pi * t) ** 0.7
        f = 1.0 if i % 2 else 0.5
        esq.append(P(L*t, env*f)); dir_.append(P(L*t, -env*f))
    return [P(0, 0.07)] + esq + [P(L, 0)] + list(reversed(dir_)) + [P(0, -0.07)]


# ---------------------------------------------------------------- skins
def tartaruga(s):
    # Casco em placas sextavadas no topo (tons próximos, juntas escuras), aba do casco passando da borda
    # atrás, quatro patinhas com unhas e rabinho saindo pela silhueta.
    s.base()
    casco, placa, placa2, pele, ink, claro = "#007E4A", "#1C8D4A", "#14884B", "#2D8953", "#2D2920", "#F7F7F7"
    # patinhas (embaixo da aba): dianteiras para o lado, traseiras na diagonal de trás
    for (cx, cy, rot) in [(2.2, 0.2, 0.25), (1.95, -1.95, -0.8)]:
        s.sym(ellipse(cx, cy, 0.55, 0.38, n=12, rot=rot), 0.8, 1.0, pele, outline=ink, ow=0.08)
        tx, ty = cx + math.cos(rot)*0.42, cy + math.sin(rot)*0.42
        for d in (-0.15, 0.15):
            px, py = tx - math.sin(rot)*d, ty + math.cos(rot)*d
            s.sym(ellipse(px, py, 0.09, 0.07, n=8, rot=rot), 1.81, 0.03, claro)
    s.flat([(-0.32, -1.7), (0.0, -2.75), (0.32, -1.7)], 0.8, 1.0, pele, outline=ink, ow=0.08)
    # aba do casco: oval ondulado maior que o corpo na metade de trás
    aba = []
    for i in range(28):
        a = 2*math.pi*i/28
        k = 1 + (0.035 if i % 2 else 0.0)
        aba.append((math.cos(a)*2.35*k, -0.95 + math.sin(a)*1.45*k))
    s.flat(aba, 0.95, 1.0, casco, outline=ink, ow=0.09)
    # casco no topo + placas (centro e laterais) com junta escura fina e anel de crescimento
    s.flat(ellipse(0, -0.95, 1.78, 1.02, n=20), TOP, 0.04, casco)
    def hexa(cx, cy, rx, ry):
        return [(cx + rx*math.cos(math.radians(60*i)), cy + ry*math.sin(math.radians(60*i))) for i in range(6)]
    for (cx, cy, rx, ry, c) in [(0, -0.5, 0.4, 0.36, placa), (0, -1.28, 0.4, 0.36, placa),
                                (0.88, -0.55, 0.42, 0.34, placa2), (-0.88, -0.55, 0.42, 0.34, placa2),
                                (0.88, -1.25, 0.42, 0.34, placa2), (-0.88, -1.25, 0.42, 0.34, placa2)]:
        s.flat(hexa(cx, cy, rx, ry), TOP + 0.04, 0.04, c, outline=ink, ow=0.04, smooth=False)
        s.flat(hexa(cx, cy, rx*0.5, ry*0.5), TOP + 0.08, 0.02, pele, smooth=False)
    # mão: pata com três unhas claras
    for k in (-1, 0, 1):
        s.hand_flat([(k*0.22 - 0.08, 0.5), (k*0.22 + 0.08, 0.5), (k*0.22, 0.74)], 1.2, 0.08, claro, smooth=False)
    s.hand_flat(hexa(-0.1, -0.15, 0.3, 0.26), 1.84, 0.03, casco, smooth=False)


def pintinho(s):
    # Penugem em tufos em volta toda, asas abertas passando bem das laterais, tufinho de três penas
    # finas em pé entre os olhos, biquinho pequeno na frente.
    s.base()
    amarelo, ouro, mel, creme, marrom, ink = "#DEAC34", "#D9A006", "#DBA62A", "#EFDBC4", "#A87F3D", "#231F20"
    for i in range(16):
        a = 2*math.pi*i/16 + math.pi/16
        r = _raio_corpo(a)
        P = [_pol(a - 0.2, r - 0.35), _pol(a - 0.17, r + 0.15), _pol(a + 0.06, r + 0.5), _pol(a + 0.17, r + 0.12), _pol(a + 0.2, r - 0.35)]
        s.flat(P, 0.84 + 0.03*(i % 2), 1.0, ouro if i % 2 else mel, outline=marrom, ow=0.07)
    # asas abertas: penas compridas em leque saindo das laterais (passam bem da borda)
    asa = [(1.5, 0.5), (2.35, 0.6), (3.05, 0.35), (3.4, -0.1), (3.05, -0.15), (3.3, -0.6), (2.9, -0.62), (3.0, -1.1), (2.55, -0.95), (2.4, -1.3), (1.5, -0.95)]
    s.sym(asa, 0.93, 1.0, ouro, outline=marrom, ow=0.08)
    s.sym([(2.0, 0.3), (2.7, 0.25), (2.95, -0.05), (2.55, -0.35), (2.05, -0.3)], 1.94, 0.03, creme)
    # tufinho em pé entre os olhos: três penas finas abrindo para a frente
    for tx, ty, h in [(-0.3, 0.62, 0.38), (0.0, 0.78, 0.5), (0.3, 0.62, 0.38)]:
        dx, dy = tx, ty - 0.22; L = math.hypot(dx, dy)
        s.flat(_pena(0.0, 0.22, math.atan2(dy, dx), L, 0.075, n=10), TOP, h, mel, outline=marrom, ow=0.04)
    # bochechas creme e biquinho
    for k in (-1, 1):
        s.flat(ellipse(k*1.4, 1.1, 0.22, 0.16, n=10), TOP, 0.03, creme)
    s.flat([(0.0, 1.9), (0.32, 1.48), (0.0, 1.18), (-0.32, 1.48)], TOP, 0.14, ouro, outline=marrom, ow=0.07)
    # mão: ponta de asa com três penas
    for ang, L in [(25, 0.85), (-5, 0.95), (-35, 0.85)]:
        s.hand_flat(_pena(0.2, -0.05, math.radians(ang), L, 0.18, n=10), 1.05, 0.5, ouro, outline=marrom, ow=0.05)


def peixe(s):
    # Peixe tropical genérico: cauda grande em leque, barbatanas peitorais e pélvicas com borda clara
    # e raios, corpo laranja com pintas marrons espalhadas (sem faixas).
    s.base()
    laranja, escuro, medio, branco, marrom, marrom2 = "#F16609", "#D85401", "#E65E06", "#F9F1EB", "#523425", "#93664E"
    def nadadeira(P, z, raios=(), base=(0.0, 0.0)):
        # peça com borda clara (peça clara + miolo laranja por cima), contorno marrom-escuro
        s.flat(P, z, 1.0, branco, outline=marrom, ow=0.08)
        s.flat(offset_poly(catmull(P), -0.14), z + 1.005, 0.02, medio, smooth=False)
        for tx, ty in raios:
            dx, dy = tx - base[0], ty - base[1]; L = math.hypot(dx, dy); nx, ny = -dy/L*0.045, dx/L*0.045
            s.flat([(base[0] + nx, base[1] + ny), (base[0] + dx*0.85, base[1] + dy*0.85), (base[0] - nx, base[1] - ny)], z + 1.03, 0.02, escuro, smooth=False)
    # cauda em leque grande
    cauda = [(-0.4, -1.65), (-0.45, -2.15), (-1.55, -2.85), (-1.75, -3.55), (-0.9, -3.75), (0.0, -3.45),
             (0.9, -3.75), (1.75, -3.55), (1.55, -2.85), (0.45, -2.15), (0.4, -1.65)]
    nadadeira(cauda, 0.82, [(-1.4, -3.4), (-0.6, -3.5), (0.6, -3.5), (1.4, -3.4)], (0.0, -2.2))
    # peitorais em leque nas laterais
    for k in (-1, 1):
        fin = [(k*1.65, 0.5), (k*2.45, 0.7), (k*3.0, 0.25), (k*3.05, -0.4), (k*2.6, -0.8), (k*1.65, -0.45)]
        nadadeira(fin, 0.88, [(k*2.8, 0.4), (k*2.95, -0.05), (k*2.75, -0.5)], (k*1.85, 0.0))
    # pélvicas pequenas nas quinas de trás
    for k in (-1, 1):
        nadadeira([(k*1.4, -1.35), (k*2.2, -1.5), (k*2.75, -2.15), (k*2.1, -2.2), (k*1.35, -1.85)], 0.8)
    # pintas marrons espalhadas (pequenas, nada grande atrás dos olhos)
    for x, y, r, c in [(-1.3, -0.35, 0.16, marrom), (1.35, -0.55, 0.14, marrom), (-0.75, -1.15, 0.12, marrom2), (0.85, -1.3, 0.15, marrom),
                       (-1.35, -1.45, 0.11, marrom2), (1.45, 1.4, 0.1, marrom2), (-1.45, 1.35, 0.12, marrom), (0.0, 1.45, 0.09, marrom2),
                       (1.45, 0.25, 0.09, marrom2), (-0.45, -0.6, 0.08, marrom2), (0.6, -0.75, 0.08, marrom2)]:
        s.flat(ellipse(x, y, r, r, n=10), TOP, 0.03, c)
    # mão: barbatana em leque com borda clara
    P = [(0.0, 0.3), (0.75, 0.55), (1.05, 0.0), (0.75, -0.55), (0.0, -0.3)]
    s.hand_flat(P, 1.0, 0.6, branco, outline=marrom, ow=0.05)
    s.hand_flat(offset_poly(catmull(P), -0.12), 1.605, 0.02, medio, smooth=False)


def cenoura(s):
    # Ponta da cenoura afinando na frente, rama de folhas recortadas saindo de trás,
    # sulcos curtos em tom próximo encostados nas bordas.
    s.base()
    laranja, laranja2, sulco, verde, verde2, ink = "#D46E00", "#C76400", "#AB5302", "#39AE56", "#168227", "#1A140F"
    # ponta afinando para a frente
    ponta = [(-1.55, 1.25), (-0.95, 2.05), (-0.4, 2.55), (0.0, 2.72), (0.4, 2.55), (0.95, 2.05), (1.55, 1.25)]
    s.flat(ponta, 0.85, 1.05, laranja, outline=ink, ow=0.09)
    for y, w in [(2.1, 0.45), (2.4, 0.25)]:
        s.flat(_faixa([(-w, y + 0.03), (0.0, y - 0.03), (w, y + 0.03)], 0.04, 0.03), 1.91, 0.02, sulco)
    # rama: folhas recortadas em leque saindo de trás
    # (leque em V bem aberto para os lados, nada no meio: um tufo central embaixo dos olhos vira barba)
    for ang, L, c, bx in [(-90 - 78, 1.9, verde2, -0.35), (-90 + 78, 1.9, verde2, 0.35), (-90 - 52, 2.35, verde, -0.3), (-90 + 52, 2.35, verde, 0.3),
                          (-90 - 28, 2.1, verde2, -0.22), (-90 + 28, 2.1, verde2, 0.22)]:
        a = math.radians(ang); by = -1.82
        s.flat(_folha_recortada(bx, by, a, L, 0.34, lobos=5), TOP + (0.04 if c == verde else 0.0), 0.05, c, outline=ink, ow=0.06)
        s.flat(_faixa([_pol(a, 0.2, bx, by), _pol(a, L*0.85, bx, by)], 0.035, 0.015), TOP + 0.09, 0.02, verde2 if c == verde else verde, smooth=False)
    s.flat(ellipse(0.0, -1.78, 0.5, 0.2, n=12), TOP + 0.1, 0.06, verde2, outline=ink, ow=0.05)
    # sulcos: tracinhos curvos encostados na borda, alternando os lados (nada no meio atrás dos olhos)
    for x0, x1, y in [(-1.8, -0.95, -0.35), (1.8, 0.85, -0.75), (-1.75, -0.8, -1.15), (1.8, 1.05, 1.25), (-1.8, -1.15, 1.5)]:
        xm = (x0 + x1) / 2
        s.flat(_faixa([(x0, y - 0.04), (xm, y + 0.04), (x1, y)], 0.05, 0.025), TOP, 0.03, sulco)
    # mão: raminho de duas folhas
    for ang in (-40, -100):
        s.hand_flat(_folha_recortada(0.0, -0.1, math.radians(ang), 0.9, 0.22, lobos=3), 1.84, 0.04, verde, outline=ink, ow=0.04)


def tubarao(s):
    # Barbatana dorsal grande deitada em foice passando da borda de trás, peitorais compridas para trás,
    # focinho arredondado, cauda em meia-lua atrás, guelras nas laterais do topo.
    s.base()
    escuro, medio, corpo, claro, ink = "#455153", "#546568", "#607379", "#6C8187", "#191715"
    # cauda: talo comprido + meia-lua (bem atrás, para a dorsal caber entre o corpo e a cauda)
    s.flat(_faixa([(0.0, -1.5), (0.0, -3.1)], 0.45, 0.22), 0.8, 1.0, corpo, outline=ink, ow=0.08)
    lua = [(0.0, -2.8), (0.65, -3.0), (1.35, -3.4), (1.9, -4.1), (1.25, -3.85), (0.55, -3.6), (0.0, -3.5),
           (-0.55, -3.6), (-1.25, -3.85), (-1.9, -4.1), (-1.35, -3.4), (-0.65, -3.0)]
    s.flat(lua, 0.84, 1.0, medio, outline=ink, ow=0.09)
    # focinho arredondado passando da frente (corpo de torpedo), ponta um tom mais claro
    s.flat([(-1.45, 1.35), (-1.0, 2.05), (-0.45, 2.38), (0.0, 2.45), (0.45, 2.38), (1.0, 2.05), (1.45, 1.35)], 0.85, 1.05, corpo, outline=ink, ow=0.09)
    s.flat([(-0.75, 2.02), (0.0, 2.3), (0.75, 2.02), (0.0, 2.12)], 1.91, 0.02, claro)
    # peitorais compridas, saindo da metade de trás e varridas para trás (longe dos olhos: não viram orelhas)
    pei = [(1.65, -0.05), (2.3, -0.3), (2.85, -0.95), (3.15, -1.85), (2.7, -1.5), (2.2, -1.15), (1.65, -0.95)]
    s.sym(pei, 0.9, 1.0, medio, outline=ink, ow=0.08)
    s.sym([(1.95, -0.35), (2.5, -0.65), (2.9, -1.45), (2.4, -1.05), (1.95, -0.75)], 1.91, 0.02, escuro)
    # costas um tom mais escuro, borda macia (longe dos olhos)
    costas = [(-1.6, -0.75), (-0.8, -0.6), (0.0, -0.7), (0.8, -0.6), (1.6, -0.75), (1.5, -1.65), (0.0, -1.78), (-1.5, -1.65)]
    s.flat(costas, TOP, 0.03, medio)
    # barbatana dorsal grande deitada em foice: nasce nas costas e passa da borda de trás, curvando para o lado
    foice = [(-0.12, -1.0), (0.35, -1.12), (0.8, -1.45), (1.2, -1.95), (1.55, -2.65), (1.1, -2.4), (0.55, -2.15), (0.1, -2.1), (-0.12, -1.6)]
    s.flat(foice, TOP, 0.16, escuro, outline=ink, ow=0.08)
    s.flat([(0.05, -1.2), (0.4, -1.3), (0.8, -1.62), (1.15, -2.12), (1.3, -2.45), (0.85, -2.2), (0.3, -1.95), (0.05, -1.75)], TOP + 0.165, 0.02, medio)
    # guelras: três tracinhos em cada lateral
    for i in range(3):
        y = 0.25 - 0.3*i
        s.sym(_faixa([(1.38, y + 0.12), (1.45, y), (1.4, y - 0.12)], 0.035, 0.03), TOP, 0.03, escuro)
    # mão: ponta de barbatana
    s.hand_flat([(-0.1, 0.35), (0.65, 0.15), (1.1, -0.55), (0.6, -0.4), (0.0, -0.35)], 1.0, 0.6, medio, outline=ink, ow=0.05)


def sapo(s):
    # Pernas traseiras dobradas saindo das laterais de trás (coxa, canela e pé de membrana),
    # pálpebras claras abraçando os olhos por trás, pintas escuras com aro claro.
    s.base()
    escuro, verde, vivo, neon, branco = "#076802", "#0B880E", "#0BD745", "#10F951", "#F2F7F1"
    for k in (-1, 1):
        X = lambda P: [(k*x, y) for x, y in P]
        coxa = _faixa([(1.4, -1.15), (2.0, -1.5), (2.55, -1.75)], 0.42, 0.34)
        s.flat(X(coxa), 0.78, 1.0, verde, outline=escuro, ow=0.08)
        canela = _faixa([(2.62, -1.75), (2.72, -1.1), (2.55, -0.4)], 0.27, 0.18)
        s.flat(X(canela), 0.84, 1.0, verde, outline=escuro, ow=0.08)
        pe = [(2.35, -0.45), (2.3, 0.3), (2.5, 0.12), (2.75, 0.4), (2.88, 0.05), (3.2, 0.12), (2.75, -0.55)]
        s.flat(X(pe), 0.9, 1.0, verde, outline=escuro, ow=0.07)
        for tx, ty in [(2.3, 0.3), (2.75, 0.4), (3.2, 0.12)]:
            s.flat(ellipse(k*tx, ty, 0.12, 0.12, n=8), 1.91, 0.03, vivo)
        for t in (0.35, 0.7):  # listras escuras na coxa
            cx, cy = 1.4 + 1.15*t, -1.15 - 0.6*t
            s.flat(_faixa([(k*(cx - 0.12), cy + 0.32), (k*(cx + 0.12), cy - 0.32)], 0.06, 0.05), 1.79, 0.02, escuro, smooth=False)
    # pálpebras: arco claro e elevado atrás de cada olho
    for k in (-1, 1):
        s.flat(_arco(k*EYE_X, EYE_Y, 0.5, 0.72, math.radians(150), math.radians(390)), TOP, 0.12, vivo, outline=escuro, ow=0.05)
    # pintas escuras com aro claro (fora do espaço logo atrás dos olhos)
    for x, y, r, sd in [(-1.25, -0.95, 0.28, 1), (0.35, -1.3, 0.3, 2), (1.3, -1.05, 0.22, 3), (-0.45, -1.5, 0.17, 4), (-1.55, 0.1, 0.13, 5), (1.5, 1.45, 0.13, 6)]:
        s.flat(_mancha(x, y, r, sd), TOP, 0.03, escuro, outline=vivo, ow=0.05)
    # mão: pata de membrana com pontas claras
    pata = [(-0.45, 0.15), (-0.6, 0.8), (-0.25, 0.62), (0.0, 0.92), (0.25, 0.62), (0.6, 0.8), (0.45, 0.15)]
    s.hand_flat(pata, 1.1, 0.45, verde, outline=escuro, ow=0.05)
    for tx, ty in [(-0.6, 0.8), (0.0, 0.92), (0.6, 0.8)]:
        s.hand_flat(ellipse(tx, ty, 0.12, 0.12, n=8), 1.56, 0.03, neon)


def macaco(s):
    # Orelhas redondas nas laterais, rosto claro em coração em volta dos olhos (ponta para trás),
    # rabo comprido enrolado em espiral atrás.
    s.base()
    escuro, corpo, medio, claro, ink2, ink = "#472F24", "#613F30", "#7A513E", "#A98670", "#42332C", "#1C1106"
    # orelhas
    s.sym(ellipse(2.15, 0.2, 0.5, 0.48, n=14), 0.9, 1.0, corpo, outline=ink, ow=0.08)
    s.sym(ellipse(2.22, 0.2, 0.3, 0.28, n=12), 1.91, 0.03, claro)
    # rabo comprido terminando em espiral
    rabo = [(0.3, -1.6), (0.55, -2.3), (0.55, -2.9), (0.3, -3.35), (-0.15, -3.5), (-0.55, -3.3), (-0.68, -2.9), (-0.5, -2.55), (-0.18, -2.58), (-0.1, -2.85)]
    s.flat(_faixa(rabo, 0.18, 0.11), 0.85, 1.0, corpo, outline=ink, ow=0.07)
    # rosto em coração: lóbulos em volta dos olhos, ponta para trás
    rosto = [(0.0, 0.98), (0.38, 1.32), (0.85, 1.45), (1.32, 1.27), (1.6, 0.78), (1.48, 0.18), (1.05, -0.28), (0.5, -0.62), (0.0, -0.85),
             (-0.5, -0.62), (-1.05, -0.28), (-1.48, 0.18), (-1.6, 0.78), (-1.32, 1.27), (-0.85, 1.45), (-0.38, 1.32)]
    s.flat(rosto, TOP, 0.04, claro)
    # pelo mais escuro nas costas, borda ondulada
    costas = [(-1.6, -1.25), (-1.0, -1.05), (-0.45, -1.3), (0.0, -1.15), (0.45, -1.3), (1.0, -1.05), (1.6, -1.25), (1.45, -1.72), (-1.45, -1.72)]
    s.flat(costas, TOP, 0.03, medio)
    # mão: palma clara e quatro dedos
    s.hand_flat(ellipse(0.0, 0.0, 0.36, 0.3, n=12), 1.84, 0.03, claro)
    for k in (-1.5, -0.5, 0.5, 1.5):
        s.hand_flat(ellipse(k*0.24, 0.58, 0.11, 0.17, n=10), 1.1, 0.5, corpo, outline=ink, ow=0.04)


def leao(s):
    # Juba em gomos (dois anéis, o de dentro invade a borda do topo) em volta toda,
    # orelhinhas redondas na juba, focinho claro, rabo com tufo vermelho.
    s.base()
    corpo, corpo2, ouro, claro, juba, juba2, ink = "#EDCD00", "#E8C501", "#DBB400", "#F7ED7A", "#BA2E2A", "#AC2229", "#6B1A1C"
    # rabo com tufo (por baixo da juba)
    s.flat(_faixa([(0.3, -1.5), (0.55, -2.6), (1.1, -3.3), (1.55, -3.55)], 0.14, 0.1), 0.75, 1.0, corpo2, outline=ink, ow=0.07)
    s.flat(_mancha(1.75, -3.7, 0.36, 2, n=10), 0.8, 1.0, juba2, outline=ink, ow=0.07)
    # juba: anel de fora (mais escuro) e anel de dentro, deslocados
    for i in range(12):
        a = 2*math.pi*i/12
        r = _raio_corpo(a)
        s.flat(ellipse(*_pol(a, r + 0.42), 0.55, 0.52, n=12, rot=a), 0.8, 1.0, juba2, outline=ink, ow=0.08)
    for i in range(12):
        a = 2*math.pi*i/12 + math.pi/12
        r = _raio_corpo(a)
        s.flat(ellipse(*_pol(a, r + 0.02), 0.6, 0.5, n=12, rot=a), 1.0, 1.06, juba, outline=ink, ow=0.07)
    # orelhinhas redondas em cima da juba, nas diagonais de trás
    for k in (-1, 1):
        s.flat(ellipse(k*1.3, -1.45, 0.36, 0.34, n=12), TOP + 0.07, 0.1, corpo2, outline=ink, ow=0.06)
        s.flat(ellipse(k*1.3, -1.45, 0.18, 0.17, n=10), TOP + 0.17, 0.02, ouro)
    # focinho claro com nariz
    s.flat(ellipse(0, 1.25, 0.72, 0.36), TOP, T, claro)
    s.flat([(-0.2, 1.5), (0.2, 1.5), (0.0, 1.3)], TOP + T, 0.04, juba2, smooth=True)
    # mão: pata amarela com dedinhos e punho de juba
    for k in (-1, 0, 1):
        s.hand_flat(ellipse(k*0.24, 0.4, 0.1, 0.12, n=8), 1.82, 0.03, ouro)
    s.hand_flat([(-0.75, -0.05), (-0.6, -0.5), (-0.3, -0.42), (-0.12, -0.8), (0.15, -0.5), (0.42, -0.72), (0.55, -0.35), (0.75, -0.4), (0.72, 0.0), (0.0, -0.15)],
                1.1, 0.72, juba, outline=ink, ow=0.05)


def bolota(s):
    # Chapéu grande cobrindo a metade de trás e passando bem da borda (borda recortada em escamas),
    # cabinho grosso inclinado para trás, biquinho da bolota na frente, corpo liso com um brilho.
    s.base()
    corpo, aba, chapeu, escama, escama2, claro, ink = "#78392A", "#703625", "#592719", "#683321", "#612E1E", "#CFA363", "#29201F"
    # biquinho na frente
    s.flat([(-0.45, 1.8), (0.0, 2.5), (0.45, 1.8)], 0.85, 1.0, corpo, outline=ink, ow=0.08)
    # brilho no corpo liso
    s.flat(_faixa([(-1.58, 0.05), (-1.6, 0.5), (-1.55, 0.95)], 0.07, 0.04), TOP, 0.03, claro)
    # chapéu: frente ondulada em y ~ -0.3 e volta em meia-oval larga com borda recortada
    cy, rx, ry = -0.3, 2.75, 2.55
    frente = [(-rx + 2*rx*j/10, cy + (0.08 if j % 2 else 0.0)) for j in range(11)]
    volta = []
    for i in range(1, 20):
        a = -math.pi*i/20
        k = 1.0 if i % 2 else 0.93
        volta.append((math.cos(a)*rx*k, cy + math.sin(a)*ry*k))
    s.flat(frente + volta, 1.1, 1.1, chapeu, outline=ink, ow=0.1)
    s.flat(frente + [(x, y - 0.4) for x, y in reversed(frente)], 2.2, 0.03, aba)
    # escamas em fileiras desencontradas
    def esc(x, y):
        return [(x - 0.3, y + 0.1), (x, y + 0.2), (x + 0.3, y + 0.1), (x + 0.22, y - 0.12), (x, y - 0.25), (x - 0.22, y - 0.12)]
    linhas = [(-1.0, [-2.0, -1.2, -0.4, 0.4, 1.2, 2.0]), (-1.6, [-1.6, -0.8, 0.8, 1.6]), (-2.2, [-1.2, -0.4, 0.4, 1.2]), (-2.7, [-0.4, 0.4])]
    for j, (y, xs) in enumerate(linhas):
        for i, x in enumerate(xs):
            s.flat(esc(x, y), 2.2, 0.04, escama if (i + j) % 2 else escama2, outline=ink, ow=0.035)
    # cabinho grosso, em pé e inclinado para trás
    s.flat(ellipse(0.0, -1.5, 0.34, 0.32, n=12), 2.2, 0.32, escama2, outline=ink, ow=0.06)
    s.flat(_faixa([(0.0, -1.5), (0.05, -1.72), (0.14, -1.9)], 0.24, 0.2), 2.52, 0.24, escama2, outline=ink, ow=0.06)
    s.flat(ellipse(0.14, -1.9, 0.17, 0.15, n=10), 2.765, 0.02, aba)
    # mão: bolotinha (chapéu atrás, biquinho na frente)
    s.hand_flat([(-0.8, 0.0), (-0.4, 0.07), (0.0, 0.0), (0.4, 0.07), (0.8, 0.0), (0.78, -0.45), (0.45, -0.78), (0.0, -0.9), (-0.45, -0.78), (-0.78, -0.45)],
                1.45, 0.5, chapeu, outline=ink, ow=0.05)
    s.hand_flat(ellipse(0.0, -0.4, 0.11, 0.11, n=8), 1.95, 0.14, escama2)
    s.hand_flat([(-0.22, 0.55), (0.0, 0.88), (0.22, 0.55)], 1.1, 0.45, corpo, outline=ink, ow=0.04)


def vaca(s):
    # Manchas pretas irregulares longe do espaço atrás dos olhos, focinho largo passando da frente,
    # chifrinhos e orelhas saindo das laterais, rabinho com tufo.
    s.base()
    branco, cinza1, cinza2, cinza3, escuro, preto = "#FFFFFF", "#E5E7EA", "#CDD0D6", "#474954", "#1B2124", "#000000"
    # rabinho com tufo
    s.flat(_faixa([(0.55, -1.6), (0.72, -2.5), (1.05, -2.95)], 0.1, 0.08), 0.8, 1.0, branco, outline=escuro, ow=0.07)
    s.flat(_mancha(1.15, -3.15, 0.3, 4, n=9), 0.82, 1.0, escuro, outline=preto, ow=0.05)
    # orelhas para o lado, um pouco caídas
    for k in (-1, 1):
        s.flat(ellipse(k*2.25, 0.4, 0.55, 0.27, n=12, rot=-k*0.25), 0.9, 1.0, branco, outline=escuro, ow=0.08)
        s.flat(ellipse(k*2.32, 0.38, 0.32, 0.13, n=10, rot=-k*0.25), 1.91, 0.02, cinza2)
    # chifrinhos: saem da lateral de trás para fora e a ponta vira para a frente
    for k in (-1, 1):
        chifre = _faixa([(k*1.25, -0.4), (k*1.8, -0.5), (k*2.25, -0.38), (k*2.45, -0.05)], 0.17, 0.06)
        s.flat(chifre, TOP + 0.02, 0.1, cinza1, outline=cinza3, ow=0.06)
    # manchas pretas
    for x, y, r, sd, sx, sy in [(-1.05, -1.2, 0.52, 1, 1.15, 0.9), (0.75, -1.45, 0.36, 2, 1.2, 0.8), (1.5, -0.55, 0.28, 3, 0.8, 1.2), (-1.5, 1.42, 0.2, 5, 1.0, 1.0)]:
        s.flat(_mancha(x, y, r, sd, sx=sx, sy=sy), TOP, 0.03, escuro)
    # focinho largo cinza-claro passando da frente, com narinas
    s.flat(ellipse(0.0, 1.68, 0.95, 0.5, n=16), 1.0, 1.09, cinza2, outline=escuro, ow=0.08)
    for k in (-1, 1):
        s.flat(ellipse(k*0.33, 1.75, 0.12, 0.09, n=8), 2.09, 0.03, cinza3)
    # mão: casco escuro na frente, com a fenda
    s.hand_flat([(-0.6, 0.15), (-0.45, 0.52), (0.0, 0.7), (0.45, 0.52), (0.6, 0.15)], 1.1, 0.65, cinza3, outline=escuro, ow=0.05)
    s.hand_flat([(-0.04, 0.2), (0.04, 0.2), (0.04, 0.72), (-0.04, 0.72)], 1.76, 0.02, branco, smooth=False)


LOTE = [
    ("tartaruga", tartaruga, "#2D8953", "#2D2920", "#2D8953", "#2D2920"),
    ("pintinho", pintinho, "#DEAC34", "#A87F3D", "#DEAC34", "#A87F3D"),
    ("peixe", peixe, "#F16609", "#523425", "#F16609", "#523425"),
    ("cenoura", cenoura, "#D46E00", "#1A140F", "#D46E00", "#1A140F"),
    ("tubarao", tubarao, "#607379", "#191715", "#607379", "#191715"),
    ("sapo", sapo, "#0B880E", "#076802", "#0B880E", "#076802"),
    ("macaco", macaco, "#613F30", "#1C1106", "#613F30", "#1C1106"),
    ("leao", leao, "#EDCD00", "#6B1A1C", "#EDCD00", "#6B1A1C"),
    ("bolota", bolota, "#78392A", "#29201F", "#78392A", "#29201F"),
    ("vaca", vaca, "#FFFFFF", "#1B2124", "#FFFFFF", "#1B2124"),
]
