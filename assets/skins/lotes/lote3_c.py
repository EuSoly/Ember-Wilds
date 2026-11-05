# Lote 3 (parte C) — skins de corpo. Montar com build_skins.py (Blender aberto) ou render_lote.py (segundo plano).
from skin_lib import *


def _faixa(centro, w0, w1):
    # tira de largura variável ao longo de uma linha central (presas, tromba, penas compridas)
    n = len(centro); esq, dir_ = [], []
    for i, (x, y) in enumerate(centro):
        a = centro[max(i - 1, 0)]; b = centro[min(i + 1, n - 1)]
        dx, dy = b[0] - a[0], b[1] - a[1]; L = math.hypot(dx, dy) or 1
        nx, ny = -dy / L, dx / L
        w = w0 + (w1 - w0) * i / (n - 1)
        esq.append((x + nx*w, y + ny*w)); dir_.append((x - nx*w, y - ny*w))
    return esq + list(reversed(dir_))

def _raio_corpo(a, folga=0.0):
    # raio da borda do corpo (quadrado arredondado ~ superelipse) no ângulo a
    c, s_ = abs(math.cos(a)), abs(math.sin(a))
    return 1.85 / (c**4 + s_**4) ** 0.25 + folga

def _pena(x0, y0, ang, L, w, n=12):
    # pena oval saindo de (x0, y0) na direção ang
    cx, cy = x0 + math.cos(ang) * L / 2, y0 + math.sin(ang) * L / 2
    return ellipse(cx, cy, L / 2, w, n=n, rot=ang)


def mamute(s):
    # Pelagem em tufos passando da borda nas laterais e atrás, orelhinhas, presas curvas de marfim
    # saindo da FRENTE (para fora e com as pontas voltando para dentro), tromba curta enrolada.
    s.base()
    dark, dark2, body, tan, red, ivory, ink = "#4B280D", "#4C210F", "#592811", "#A07D63", "#AC262A", "#E8D9BE", "#2A1406"
    # tufos de pelo em volta (fora a frente, onde ficam presas e tromba): gomos arredondados penteados para trás
    ang = list(range(-90 - 126, -90 + 127, 18))  # até 126° de cada lado a partir de trás
    for i, g in enumerate(ang):
        a = math.radians(g)
        r = _raio_corpo(a)
        sw = (0.12 if math.cos(a) >= 0 else -0.12) * (1 if math.sin(a) < 0.3 else 0.5)
        pol = lambda aa, rr: (math.cos(aa) * rr, math.sin(aa) * rr)
        P = [pol(a - 0.25, r - 0.4), pol(a - 0.24, r + 0.28), pol(a - sw, r + 0.54 + 0.06 * (i % 2)), pol(a + 0.24, r + 0.28), pol(a + 0.25, r - 0.4)]
        s.flat(P, 0.86 + 0.03 * (i % 2), 1.0, dark2 if i % 2 else body, outline=ink, ow=0.08)
    # orelhinhas redondas nas laterais, por cima dos tufos
    s.sym(ellipse(2.0, 0.35, 0.3, 0.4, n=12, rot=-0.3), 0.97, 1.03, dark, outline=ink, ow=0.08)
    s.sym(ellipse(2.06, 0.35, 0.16, 0.24, n=10, rot=-0.3), 2.0, 0.03, tan)
    # presas de marfim: saem da frente (afastadas da tromba), abrem para fora e as pontas voltam para dentro
    presa = _faixa([(0.8, 1.45), (1.05, 2.2), (1.5, 2.8), (1.75, 3.35), (1.6, 3.85), (1.25, 4.1)], 0.32, 0.1)
    s.sym(presa, 1.05, 0.55, ivory, outline=ink, ow=0.08)
    s.sym(_faixa([(0.66, 2.12), (1.32, 1.9)], 0.1, 0.1), 1.61, 0.03, red, smooth=False)  # anel vermelho na base
    # tromba curta e enrolada na frente, por cima do topo
    tromba = _faixa([(0.0, 0.95), (0.0, 1.6), (0.03, 2.05), (0.18, 2.4), (0.42, 2.5), (0.55, 2.35)], 0.32, 0.15)
    s.flat(tromba, TOP, 0.12, body, outline=ink, ow=0.08)
    for y in (1.35, 1.7, 2.0):
        s.flat(_faixa([(-0.2, y), (0.2, y + 0.02)], 0.03, 0.03), TOP + 0.12, 0.02, dark, smooth=False)
    # topo: corcova de pelo nas costas com borda ondulada (tom próximo do corpo, longe dos olhos) e fios finos
    n = 7; frente = []
    for j in range(n + 1):
        x = -1.55 + 3.1 * j / n
        frente.append((x, -0.45 + (0.18 if j % 2 else 0.0)))
    corcova = frente + [(1.6, -0.9), (1.45, -1.6), (0.0, -1.72), (-1.45, -1.6), (-1.6, -0.9)]
    s.flat(corcova, TOP, 0.04, dark2)
    for x, y in [(-1.0, -0.85), (0.3, -0.85), (-0.45, -1.35), (0.85, -1.35)]:
        s.flat(_faixa([(x - 0.18, y + 0.1), (x, y), (x + 0.12, y - 0.12), (x + 0.3, y - 0.15)], 0.03, 0.02), TOP + 0.04, 0.02, tan, smooth=False)
    # mão = pata com unhas de marfim na frente e punho de pelo
    for k in (-1, 0, 1):
        s.hand_flat(ellipse(k * 0.3, 0.5, 0.15, 0.12, n=8), 1.15, 0.4, ivory, outline=ink, ow=0.04)
    s.hand_flat([(-0.7, -0.05), (-0.55, -0.45), (-0.3, -0.35), (-0.15, -0.75), (0.1, -0.45), (0.35, -0.7), (0.5, -0.35), (0.72, -0.4), (0.68, 0.0), (0.0, -0.15)],
                1.1, 0.75, dark, outline=ink, ow=0.05)


def papagaio(s):
    # Arara: crista de penas coloridas atrás no topo, bico curvo pequeno na frente, asas com penas
    # (vermelho > verde > pontas azul-acinzentadas) nas laterais, cauda de penas compridas atrás.
    s.base()
    red, red2, maroon, cream, green, blue, ink = "#B02E20", "#912622", "#672026", "#F3DD99", "#3CCE85", "#7D9498", "#261F20"
    # cauda: penas longas para trás (laterais azuladas, miolo vermelho)
    for ang, L, c in [(-90 - 24, 2.4, blue), (-90 + 24, 2.4, blue), (-90 - 12, 3.0, green), (-90 + 12, 3.0, green), (-90, 3.5, red)]:
        a = math.radians(ang)
        s.flat(_pena(0.0, -1.2, a, L, 0.3), 0.8 + (0.03 if c == red else 0.0), 1.0, c, outline=ink, ow=0.08)
    s.flat(_faixa([(0.0, -2.2), (0.0, -4.5)], 0.035, 0.02), 1.86, 0.02, red2, smooth=False)
    # asas dobradas para trás: primárias azuladas compridas, secundárias verdes, cobertura vermelha
    for ang, L in [(-48, 2.5), (-63, 2.55), (-78, 2.4), (-93, 2.1)]:
        s.sym(_pena(1.45, 0.3, math.radians(ang), L, 0.27), 0.8, 1.0, blue, outline=ink, ow=0.07)
    for ang, L in [(-38, 1.85), (-53, 1.95), (-68, 1.9), (-83, 1.7)]:
        s.sym(_pena(1.45, 0.4, math.radians(ang), L, 0.28), 0.86, 1.0, green, outline=ink, ow=0.06)
    s.sym([(1.35, 0.6), (2.2, 0.55), (2.6, 0.0), (2.55, -0.45), (2.3, -0.3), (2.25, -0.8), (1.95, -0.6), (1.85, -1.05), (1.55, -0.75), (1.3, -0.9)],
          0.92, 1.0, red, outline=ink, ow=0.08)
    # crista: leque de penas no topo de trás, pontas arredondadas (nada de fileira de pontas)
    for ang, L, c, z in [(-90 - 40, 1.35, blue, TOP), (-90 + 40, 1.35, blue, TOP), (-90 - 20, 1.6, green, TOP + 0.04),
                         (-90 + 20, 1.6, green, TOP + 0.04), (-90, 1.75, red2, TOP + 0.08)]:
        a = math.radians(ang)
        s.flat(_pena(0.0, -0.55, a, L, 0.3), z, 0.06, c, outline=ink, ow=0.05)
    s.flat(ellipse(0.0, -0.6, 0.38, 0.28, n=12), TOP + 0.12, 0.04, red2, outline=ink, ow=0.05)
    # costas: penas em escama (vermelho escuro, tom próximo do corpo) dos lados da crista
    for x, y in [(0.95, -0.75), (1.35, -1.05), (0.95, -1.4), (1.4, -1.5)]:
        s.sym([(x - 0.22, y + 0.1), (x - 0.18, y - 0.08), (x, y - 0.18), (x + 0.18, y - 0.08), (x + 0.22, y + 0.1), (x, y - 0.02)], TOP, 0.03, red2)
    # bico curvo pequeno: base entre os olhos, gancho passando da borda da frente
    bico = [(-0.36, 1.05), (0.36, 1.05), (0.42, 1.55), (0.3, 2.0), (0.0, 2.3), (-0.3, 2.0), (-0.42, 1.55)]
    s.flat(bico, TOP, 0.14, cream, outline=ink, ow=0.06)
    s.flat([(-0.16, 2.0), (0.16, 2.0), (0.0, 2.24)], TOP + 0.14, 0.02, ink, smooth=False)
    s.flat(ellipse(0.0, 1.22, 0.3, 0.1, n=10), TOP + 0.14, 0.02, blue)
    # mão: três penas (verde, azul, vermelha) saindo para fora
    for ang, c, L in [(30, green, 0.95), (0, blue, 1.0), (-30, red2, 0.9)]:
        a = math.radians(ang)
        s.hand_flat(_pena(0.35, -0.05, a, L, 0.17, n=10), 1.05, 0.5, c, outline=ink, ow=0.05)


LOTE = [
    ("mamute", mamute, "#592811", "#2A1406", "#592811", "#2A1406"),
    ("papagaio", papagaio, "#B02E20", "#261F20", "#B02E20", "#261F20"),
]
