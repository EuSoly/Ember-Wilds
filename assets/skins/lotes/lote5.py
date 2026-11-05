# Lote 5 — skins de corpo (detalhadas). Montar com build_skins.py (Blender aberto) ou render_lote.py (segundo plano).
# guaxinim, javali, cogumelo, onça, vela, bomba, fênix, yeti, besouro, slime.
from skin_lib import *


# ---------------------------------------------------------------- ajudantes do lote
def _pol(a, r, cx=0.0, cy=0.0):
    return (cx + math.cos(a) * r, cy + math.sin(a) * r)

def _raio_corpo(a, folga=0.0):
    # raio da borda do corpo (quadrado arredondado ~ superelipse) no ângulo a
    c, s_ = abs(math.cos(a)), abs(math.sin(a))
    return 1.85 / (c**4 + s_**4) ** 0.25 + folga

def _local(x0, y0, ang):
    # sistema local: u ao longo de ang, v para a esquerda
    ca, sa = math.cos(ang), math.sin(ang)
    return lambda u, v: (x0 + ca*u - sa*v, y0 + sa*u + ca*v)

def _curva(ctrl, per=6):
    # curva aberta (Catmull-Rom) passando pelos pontos de controle
    P = [ctrl[0]] + list(ctrl) + [ctrl[-1]]
    out = []
    for i in range(1, len(P) - 2):
        p0, p1, p2, p3 = P[i-1], P[i], P[i+1], P[i+2]
        for k in range(per):
            t = k / per; t2, t3 = t*t, t*t*t
            out.append(tuple(0.5 * (2*p1[j] + (-p0[j]+p2[j])*t + (2*p0[j]-5*p1[j]+4*p2[j]-p3[j])*t2
                                    + (-p0[j]+3*p1[j]-3*p2[j]+p3[j])*t3) for j in (0, 1)))
    out.append(tuple(ctrl[-1]))
    return out

def _tubo(c, wf, t0=0.0, t1=1.0, cap0=False, cap1=False, n=24):
    # faixa ao longo da linha c (meia-largura wf(t), t de 0 a 1 pelo comprimento); pedaço de t0 a t1, pontas redondas opcionais
    L = [0.0]
    for a, b in zip(c, c[1:]): L.append(L[-1] + math.dist(a, b))
    tot = L[-1]
    def pos(t):
        d = min(max(t, 0.0), 1.0) * tot
        for i in range(len(c) - 1):
            if d <= L[i+1] or i == len(c) - 2:
                seg = (L[i+1] - L[i]) or 1e-9
                u = min(max((d - L[i]) / seg, 0.0), 1.0)
                return (c[i][0] + (c[i+1][0] - c[i][0])*u, c[i][1] + (c[i+1][1] - c[i][1])*u)
    def tang(t):
        a, b = pos(t - 0.012), pos(t + 0.012)
        dx, dy = b[0] - a[0], b[1] - a[1]; l = math.hypot(dx, dy) or 1
        return dx / l, dy / l
    esq, dir_ = [], []
    for k in range(n + 1):
        t = t0 + (t1 - t0) * k / n
        (x, y), (dx, dy), w = pos(t), tang(t), max(wf(t), 0.01)
        esq.append((x - dy*w, y + dx*w)); dir_.append((x + dy*w, y - dx*w))
    fim, ini = [], []
    if cap1:
        (x, y), (dx, dy), w = pos(t1), tang(t1), max(wf(t1), 0.01)
        for k in range(1, 6):
            th = math.pi * k / 6
            fim.append((x + w*(-dy*math.cos(th) + dx*math.sin(th)), y + w*(dx*math.cos(th) + dy*math.sin(th))))
    if cap0:
        (x, y), (dx, dy), w = pos(t0), tang(t0), max(wf(t0), 0.01)
        for k in range(1, 6):
            th = math.pi * k / 6
            ini.append((x + w*(dy*math.cos(th) - dx*math.sin(th)), y + w*(-dx*math.cos(th) - dy*math.sin(th))))
    return esq + fim + list(reversed(dir_)) + ini

def _radial(rf, n=56, cx=0.0, cy=0.0, maos=0.0):
    # contorno estrelado r = rf(a) em volta de (cx, cy); com maos > 0 abre um recorte em volta de cada mão
    out = []
    for i in range(n):
        a = 2*math.pi*i/n; ux, uy = math.cos(a), math.sin(a)
        r = rf(a)
        if maos:
            for hx in (HX, -HX):
                px, py = hx - cx, HY - cy
                b = ux*px + uy*py; disc = b*b - (px*px + py*py - maos*maos)
                if disc >= 0 and b > 0:
                    r = min(r, b - math.sqrt(disc))
        out.append((cx + ux*r, cy + uy*r))
    return out

def _blob(cx, cy, r, n=12, wob=0.08, seed=0, sx=1.0, sy=1.0):
    # elipse irregular (pintas, poças)
    return [(cx + sx*r*(1 + wob*math.sin(3*a + seed) + 0.5*wob*math.cos(5*a + 2*seed))*math.cos(a),
             cy + sy*r*(1 + wob*math.sin(3*a + seed) + 0.5*wob*math.cos(5*a + 2*seed))*math.sin(a))
            for a in [2*math.pi*i/n for i in range(n)]]

def _arco(cx, cy, r0, r1, a0, a1, n=12):
    # pedaço de anel de a0 a a1 (radianos), raios r0 (dentro) e r1 (fora)
    A = [a0 + (a1 - a0)*i/(n - 1) for i in range(n)]
    return [_pol(a, r1, cx, cy) for a in A] + [_pol(a, r0, cx, cy) for a in reversed(A)]

def _crescente(a0, a1, r, w, cx=0.0, cy=0.0, n=14):
    # meia-lua colada numa borda de raio r: grossura w no meio, zero nas pontas
    A = [a0 + (a1 - a0)*i/(n - 1) for i in range(n)]
    return [_pol(a, r, cx, cy) for a in A] + [_pol(a, r - w*math.sin(math.pi*(a - a0)/(a1 - a0)), cx, cy) for a in reversed(A[1:-1])]

def _pena(x0, y0, ang, L, w, n=12):
    # pena/mecha oval saindo de (x0, y0) na direção ang
    return ellipse(x0 + math.cos(ang) * L / 2, y0 + math.sin(ang) * L / 2, L / 2, w, n=n, rot=ang)

def _orelha(x0, y0, ang, L, w, redonda=0.45):
    # orelha (triângulo arredondado) com base em (x0, y0) apontando para ang
    P = _local(x0, y0, ang)
    return [P(-0.15*L, 0), P(0, w), P(0.55*L, 0.85*w), P(0.9*L, redonda*w), P(L, 0), P(0.9*L, -redonda*w), P(0.55*L, -0.85*w), P(0, -w)]

def _chama(x0, y0, ang, L, w, curl=0.0, n=14, onda=0.15):
    # labareda/pena de fogo: base redonda, bojo, ponta fina que curva para o lado (curl)
    P = _local(x0, y0, ang)
    esq, dir_ = [], []
    for k in range(n + 1):
        t = k / n
        env = w * (math.sqrt(t / 0.3) if t < 0.3 else (1 - (t - 0.3) / 0.7) ** 1.2)
        off = curl * w * t * t
        esq.append(P(L*t, off + env*(1 + onda*math.sin(3*math.pi*t))))
        dir_.append(P(L*t, off - env*(1 - onda*math.sin(3*math.pi*t + 1))))
    return esq + list(reversed(dir_[1:-1]))

def _cristal(x0, y0, ang, L, w):
    # cristal de gelo: lados paralelos e ponta em bico
    P = _local(x0, y0, ang)
    return [P(0, -w), P(0.72*L, -w), P(L, 0), P(0.72*L, w), P(0, w)]

def _faceta(x0, y0, ang, L, w):
    # metade clara do cristal (brilho)
    P = _local(x0, y0, ang)
    return [P(0.05*L, 0.05*w), P(0.72*L, 0.05*w), P(0.97*L, 0.02*w), P(0.72*L, 0.75*w), P(0.05*L, 0.75*w)]

def _estrela(cx, cy, r0, r1, n=8, rot=0.0):
    # estrela de n pontas (faísca)
    return [_pol(rot + math.pi*i/n, r1 if i % 2 == 0 else r0, cx, cy) for i in range(2*n)]

def _gota(a, comp, w=0.3, bulbo=0.24, dentro=0.3):
    # pingo escorrendo pela borda no ângulo a: largo na base, pescoço fino, gota redonda na ponta
    r0 = _raio_corpo(a) - dentro; r1 = _raio_corpo(a) + 0.15 + comp
    c = [_pol(a, r0), _pol(a, r1)]
    return _tubo(c, lambda t: w - (w - 0.6*bulbo)*min(t / 0.65, 1.0) + (0.4*bulbo)*max(0.0, (t - 0.65) / 0.35)**1.5, cap1=True, n=16)


# ---------------------------------------------------------------- skins
def guaxinim(s):
    # Guaxinim: máscara de bandido envolvendo os olhos (com risca cinza no meio), sobrancelhas e focinho claros,
    # bochechas brancas e orelhas saindo das laterais, rabo grosso listrado curvando para o lado; mão segura uma frutinha.
    s.base()
    cinza, pardo, preto, ink, branco, verm, verm_d = "#7C7578", "#664F50", "#241F20", "#251F20", "#F9F0F0", "#A80000", "#680F0E"
    # rabo grosso (mais cheio no meio) com anéis escuros e ponta escura
    c = _curva([(0.35, -1.4), (0.6, -2.35), (1.25, -3.1), (2.15, -3.4), (2.95, -3.1), (3.3, -2.45)])
    wf = lambda t: 0.47 + 0.15*math.sin(math.pi*min(t*1.15, 1.0))
    s.flat(_tubo(c, wf, cap1=True, n=40), 0.82, 1.0, cinza, outline=ink, ow=0.09, smooth=False)
    for t0, t1 in ((0.3, 0.4), (0.5, 0.6), (0.7, 0.8)):
        s.flat(_tubo(c, wf, t0, t1, n=8), 1.83, 0.02, preto, smooth=False)
    s.flat(_tubo(c, wf, 0.9, 1.0, cap1=True, n=8), 1.83, 0.02, preto, smooth=False)
    # bochechas brancas felpudas saindo pelas laterais (embaixo das pontas da máscara)
    s.sym([(1.6, 0.68), (2.3, 0.6), (2.12, 0.38), (2.5, 0.18), (2.15, 0.02), (2.35, -0.25), (1.6, -0.2)],
          0.86, 1.0, branco, outline=ink, ow=0.08)
    # orelhas arredondadas nas laterais de trás: borda branca, miolo cinza-pardo
    a = math.radians(-38); P = _local(1.3, -1.15, a)
    s.sym(_orelha(1.3, -1.15, a, 1.45, 0.62, redonda=0.6), 0.88, 1.0, branco, outline=ink, ow=0.08)
    s.sym(_orelha(*P(0.35, 0), a, 0.92, 0.42, redonda=0.6), 1.89, 0.02, pardo)
    # costas: sem sela (de cima, mancha escura embaixo da máscara vira boca); só fios finos pardos nas laterais
    for x, y in [(-1.3, -0.75), (1.3, -0.85), (-1.15, -1.35), (1.2, -1.4)]:
        k = 1 if x > 0 else -1
        s.flat(_tubo(_curva([(x - 0.18*k, y + 0.1), (x, y), (x + 0.2*k, y - 0.1)]), lambda t: 0.03), TOP, 0.01, pardo, smooth=False)
    # máscara: faixa escura que envolve os dois olhos, ponte entre eles na frente, pontas saindo para as laterais
    half = [(0.0, 0.98), (0.4, 1.17), (0.85, 1.21), (1.3, 1.06), (1.62, 0.8), (2.02, 0.5), (1.82, 0.22), (1.4, 0.0),
            (0.9, -0.08), (0.45, 0.02), (0.18, 0.3), (0.0, 0.42)]
    s.flat(half + [(-x, y) for x, y in reversed(half[1:-1])], TOP, 0.045, preto)
    s.flat([(-0.12, 0.5), (0.12, 0.5), (0.17, 1.0), (0.0, 1.3), (-0.17, 1.0)], TOP + 0.045, 0.01, cinza)
    # sobrancelhas brancas acima da máscara e focinho branco com nariz escuro passando da borda da frente
    s.sym(ellipse(0.85, 1.3, 0.58, 0.17, n=12, rot=-0.15), TOP, 0.03, branco)
    s.flat([(-0.48, 1.36), (0.48, 1.36), (0.6, 1.75), (0.35, 2.1), (0.0, 2.2), (-0.35, 2.1), (-0.6, 1.75)], TOP, 0.06, branco, outline=ink, ow=0.06)
    s.flat(ellipse(0.0, 1.98, 0.24, 0.16, n=10), TOP + 0.06, 0.03, preto)
    # mão: dedinhos escuros na frente e uma frutinha vermelha com brilho
    for k in (-1.5, -0.5, 0.5, 1.5):
        s.hand_flat(ellipse(k*0.22, 0.5, 0.11, 0.16, n=8), 1.3, 0.42, preto, outline=ink, ow=0.03)
    s.hand_flat(ellipse(0.05, 0.05, 0.3, 0.3, n=12), 1.84, 0.12, verm, outline=verm_d, ow=0.05)
    s.hand_flat(ellipse(-0.05, 0.15, 0.08, 0.06, n=8), 1.96, 0.02, branco)


def javali(s):
    # Javali: crina de cerdas eriçadas em dois leques nos cantos de trás, costeletas eriçadas nas
    # laterais, orelhas pontudas para fora, focinho largo rosado com narinas na frente e presinhas curvando para cima.
    s.base()
    corpo, escuro, cinza, ink, rosa, branco, preto = "#55413E", "#41302F", "#4B4140", "#2D2025", "#B68F8D", "#FEFDFD", "#020202"
    # cerdas da crina em dois leques nos cantos de trás (pontas fortes só fora do corpo; nada no meio de trás,
    # que de cima fica embaixo dos olhos e vira barba)
    for i, (x0, y0, ang, L) in enumerate([(1.25, -1.05, -36, 1.2), (1.05, -1.3, -52, 1.45), (0.78, -1.45, -68, 1.3), (0.5, -1.5, -82, 0.95)]):
        a = math.radians(ang)
        c = [(x0, y0), (x0 + math.cos(a)*L*0.5, y0 + math.sin(a)*L*0.5), (x0 + math.cos(a + 0.15)*L, y0 + math.sin(a + 0.15)*L)]
        s.sym(_tubo(_curva(c), lambda t: 0.3*(1 - t) + 0.015, n=16), 0.84 + 0.03*(i % 2), 1.0, escuro if i % 2 else corpo, outline=ink, ow=0.08, smooth=False)
    # costeletas eriçadas nas laterais
    s.sym([(1.7, 0.58), (2.35, 0.52), (2.12, 0.33), (2.62, 0.15), (2.18, 0.0), (2.45, -0.28), (1.7, -0.22)], 0.86, 1.0, escuro, outline=ink, ow=0.08, smooth=False)
    # orelhas pontudas saindo das laterais de trás, miolo rosado
    a = math.radians(-22); P = _local(1.35, -0.95, a)
    s.sym(_orelha(1.35, -0.95, a, 1.55, 0.5, redonda=0.25), 0.9, 1.0, escuro, outline=ink, ow=0.08)
    s.sym(_orelha(*P(0.55, 0), a, 0.8, 0.24, redonda=0.25), 1.91, 0.02, rosa)
    # costas: só fios cinzentos (faixa escura nas costas vira boca de cima)
    for x, y in [(-1.15, -0.45), (1.15, -0.45), (-0.45, -0.75), (0.45, -0.75)]:
        k = 1 if x > 0 else -1
        s.flat(_tubo([(x - 0.18*k, y + 0.12), (x + 0.18*k, y - 0.12)], lambda t: 0.035), TOP, 0.01, cinza, smooth=False)
    # focinho largo na frente com narinas
    s.flat(ellipse(0.0, 1.72, 0.8, 0.5, n=14), TOP, 0.16, rosa, outline=ink, ow=0.08)
    s.sym(ellipse(0.27, 1.78, 0.12, 0.17, n=10, rot=0.3), TOP + 0.16, 0.02, preto)
    # presinhas: saem dos lados do focinho para fora e voltam para cima (na câmera do jogo apontam para cima)
    s.sym(_tubo(_curva([(0.62, 1.78), (0.92, 1.95), (1.12, 1.84), (1.17, 1.58)]), lambda t: 0.1 - 0.07*t, n=16),
          TOP + 0.08, 0.2, branco, outline=ink, ow=0.06, smooth=False)
    # mão: casco de dois dedos e um tufo de cerdas
    for x in (-0.2, 0.2):
        s.hand_flat(ellipse(x, 0.38, 0.19, 0.26, n=10), 1.45, 0.45, escuro, outline=ink, ow=0.04)
    s.hand_flat([(0.1, -0.35), (0.55, -0.88), (0.45, -0.52), (0.88, -0.68), (0.55, -0.3), (0.82, -0.15), (0.35, -0.08)],
                1.5, 0.3, escuro, outline=ink, ow=0.04, smooth=False)


def _lamelas(r_in, r_out, n=56, d=0.022, cy=0.0):
    # "engrenagem" clara com fendas estreitas: por cima de um disco escuro vira riscos radiais (lamelas)
    out = []
    for k in range(n):
        a0 = 2*math.pi*k/n; a1 = 2*math.pi*(k + 1)/n
        out += [_pol(a0 + d, r_in, 0, cy), _pol(a0 + d, r_out, 0, cy), _pol(a1 - d, r_out, 0, cy), _pol(a1 - d, r_in, 0, cy)]
    return out

def cogumelo(s):
    # Cogumelo: chapéu redondo e largo (topo + aba mais baixa passando bem da borda), lamelas aparecendo em volta da aba,
    # pintas claras espalhadas, brilho na lateral; mão com um cogumelinho.
    s.base()
    verm, verm2, vinho, laranja, creme, pessego, pessego_d = "#B3271C", "#C83E26", "#861821", "#FC7F51", "#F2DEC6", "#ECB195", "#CD7F64"
    # lamelas: disco escuro + engrenagem clara (riscos radiais) em volta de tudo
    # (Elizeu tirou no Blender em 05/11: disco das lamelas, lamelas e aba larga do chapéu)
    # s.flat(_radial(lambda a: 3.0 + 0.03*math.sin(6*a), n=60), 0.5, 1.0, pessego_d, outline=vinho, ow=0.08)
    # s.flat(_lamelas(2.4, 2.96), 1.5, 0.015, pessego, smooth=False)
    # topo arredondado cobrindo o quadrado (recortado em volta das mãos)
    # s.flat(_radial(lambda a: 2.72 + 0.04*math.sin(6*a + 1), n=60), 0.68, 1.0, verm, outline=vinho, ow=0.1)
    s.flat(_radial(lambda a: 2.3 + 0.03*math.sin(5*a), n=60, maos=0.74), TOP, 0.04, verm, outline=vinho, ow=0.07)
    # brilho na lateral esquerda
    s.flat(_crescente(math.radians(165), math.radians(232), 2.2, 0.42), TOP + 0.04, 0.01, verm2)
    s.flat(_crescente(math.radians(175), math.radians(220), 2.1, 0.12), TOP + 0.05, 0.01, laranja)
    # pintas claras espalhadas no topo (tamanhos variados, longe dos olhos)
    for i, (x, y, r) in enumerate([(0.0, 1.5, 0.3), (-1.35, -0.35, 0.3), (0.6, -0.85, 0.2), (-0.55, -1.4, 0.36),
                                   (1.3, -1.35, 0.26), (1.6, -0.1, 0.15), (-1.55, 1.15, 0.17), (-1.85, -1.4, 0.15), (0.3, -2.0, 0.17)]):
        s.flat(_blob(x, y, r, n=12, wob=0.08, seed=i*1.3), TOP + 0.04, 0.02, creme)
    # pintas na aba
    for i, (g, r) in enumerate([(160, 0.17), (200, 0.15), (-62, 0.16), (-105, 0.13), (12, 0.14), (-25, 0.11)]):
        x, y = _pol(math.radians(g), 2.53)
        s.flat(_blob(x, y, r, n=10, wob=0.08, seed=i), 1.69, 0.02, creme)
    # mão: cogumelinho (chapéu vermelho com pintas) em cima do "pé" creme
    s.hand_flat(ellipse(0.05, 0.1, 0.52, 0.45, n=14), 1.8, 0.14, verm, outline=vinho, ow=0.05)
    for x, y, r in [(-0.15, 0.27, 0.1), (0.24, 0.05, 0.12), (-0.08, -0.15, 0.07)]:
        s.hand_flat(ellipse(x, y, r, r, n=8), 1.94, 0.02, creme)


def _roseta(s, cx, cy, r, z, cor, centro, seed=0.0):
    # roseta de onça: miolo alaranjado e anel escuro quebrado em dois pedaços
    s.flat(_blob(cx, cy, r*0.6, n=10, wob=0.1, seed=seed), z, 0.02, centro)
    s.flat(_arco(cx, cy, r*0.68, r, seed + 0.35, seed + 2.85, n=8), z + 0.005, 0.02, cor)
    s.flat(_arco(cx, cy, r*0.68, r, seed + 3.45, seed + 5.85, n=8), z + 0.005, 0.02, cor)

def onca(s):
    # Onça: rosetas (anéis quebrados com miolo) no topo e nas ancas que passam da borda das laterais,
    # orelhas redondas atrás, rabo comprido em curva com anéis; focinho claro; mão com almofadinhas.
    s.base()
    ouro, ouro2, ferr, marrom, creme, preto, ink = "#CB9C63", "#B3895E", "#A86848", "#785E46", "#F7E3C0", "#2E2F2E", "#231F20"
    # rabo comprido curvando para a esquerda, anéis escuros e ponta escura
    c = _curva([(-0.3, -1.45), (-0.45, -2.45), (-1.05, -3.25), (-1.95, -3.55), (-2.8, -3.3), (-3.3, -2.65)])
    wf = lambda t: 0.27 - 0.05*t
    s.flat(_tubo(c, wf, cap1=True, n=40), 0.82, 1.0, ouro, outline=ink, ow=0.08, smooth=False)
    for t in (0.34, 0.47, 0.6, 0.73):
        s.flat(_tubo(c, wf, t, t + 0.055, n=4), 1.83, 0.02, preto, smooth=False)
    s.flat(_tubo(c, wf, 0.88, 1.0, cap1=True, n=8), 1.83, 0.02, preto, smooth=False)
    # ancas: pelagem passando um pouco da borda nas laterais, com uma roseta cada
    s.sym([(1.7, 0.4), (2.08, 0.28), (2.28, -0.3), (2.22, -0.85), (1.98, -1.2), (1.7, -1.25)], 0.84, 1.0, ouro, outline=ink, ow=0.08)
    for k in (1, -1):
        _roseta(s, k*2.02, -0.4, 0.22, 1.85, preto, ferr, seed=1.0 + k)
    # orelhas redondas nas laterais de trás, miolo claro
    s.sym(ellipse(1.92, -1.32, 0.52, 0.46, n=12, rot=-0.6), 0.9, 1.0, ouro, outline=ink, ow=0.08)
    s.sym(ellipse(2.02, -1.4, 0.3, 0.24, n=10, rot=-0.6), 1.91, 0.02, creme)
    # rosetas no topo (laterais e costas; nenhuma logo atrás dos olhos no meio)
    for i, (x, y, r) in enumerate([(-1.25, -0.4, 0.34), (1.2, -0.55, 0.3), (-0.45, -1.3, 0.32), (0.75, -1.4, 0.27),
                                   (1.5, 0.2, 0.2), (-1.55, 0.35, 0.18)]):
        _roseta(s, x, y, r, TOP, preto, ferr, seed=i*1.9)
    # focinho claro com narizinho
    s.flat([(-0.55, 1.15), (0.0, 1.05), (0.55, 1.15), (0.68, 1.55), (0.42, 1.9), (0.0, 1.98), (-0.42, 1.9), (-0.68, 1.55)], TOP, 0.04, creme)
    s.flat([(-0.2, 1.24), (0.2, 1.24), (0.0, 1.46)], TOP + 0.04, 0.02, marrom)
    # mão: almofadinhas claras na frente e uma roseta
    for x, y in [(-0.27, 0.33), (0.0, 0.43), (0.27, 0.33)]:
        s.hand_flat(ellipse(x, y, 0.12, 0.12, n=8), 1.55, 0.25, creme, outline=marrom, ow=0.03)
    s.hand_flat(_blob(-0.02, -0.15, 0.12, n=8, seed=1), 1.85, 0.02, ferr)
    s.hand_flat(_arco(-0.02, -0.15, 0.14, 0.22, 0.3, 2.9, n=7), 1.855, 0.02, preto)
    s.hand_flat(_arco(-0.02, -0.15, 0.14, 0.22, 3.4, 5.9, n=7), 1.855, 0.02, preto)


def vela(s):
    # Vela: pratinho de cobre por baixo (silhueta redonda com alça), pingos de cera escorrendo pela borda em volta,
    # borda de cera derretida e poça clara no topo, pavio no canto de trás à direita com chama (Neon) na diagonal.
    s.base()
    cera, cera2, marrom, pavio, amarelo, laranja, cobre = "#D2B389", "#BC9070", "#7C5046", "#272222", "#E7D48A", "#DE9F50", "#B97146"
    # pratinho com alça à esquerda
    # (Elizeu tirou no Blender em 05/11: alça e prato de cobre)
    # s.flat(ellipse(-3.05, -0.55, 0.55, 0.5, n=14), 0.42, 0.3, cobre, outline=marrom, ow=0.09)
    # s.flat(ellipse(-3.12, -0.55, 0.27, 0.23, n=12), 0.72, 0.02, pavio)
    # s.flat(_radial(lambda a: 2.7, n=48), 0.42, 0.3, cobre, outline=marrom, ow=0.1)
    s.flat(_crescente(math.radians(150), math.radians(215), 2.58, 0.22), 0.72, 0.02, laranja)
    # pingos gordos e irregulares escorrendo (fora das mãos): línguas de cera com a ponta engrossando
    # (poucos e desiguais: muitos pingos iguais em volta viram juba; poça separada na ponta vira "ossinho")
    for g, L, w in [(78, 0.55, 0.36), (112, 0.1, 0.32), (2, 0.72, 0.38), (-14, 0.14, 0.3), (-86, 0.42, 0.34),
                    (-128, 0.78, 0.4), (-152, 0.12, 0.3), (176, 0.25, 0.34)]:
        s.flat(_gota(math.radians(g), L, w=w, bulbo=w*1.1, dentro=0.3), 0.76, 1.15, cera, outline=marrom, ow=0.08, smooth=False)
    # topo: borda de cera derretida ondulada passando da borda, poça clara no meio
    s.flat(_radial(lambda a: _raio_corpo(a) + 0.1 + 0.05*math.sin(9*a), n=64, maos=0.72), TOP, 0.035, cera, outline=cera2, ow=0.05)
    s.flat(_radial(lambda a: _raio_corpo(a) - 0.4 + 0.04*math.sin(7*a + 1), n=56), TOP + 0.035, 0.015, amarelo)
    # pavio e chama no canto de trás à direita, na diagonal (centralizada atrás, de cima, vira língua/cavanhaque)
    av = math.radians(-50)
    s.flat(_tubo([_pol(av, 1.55), _pol(av, 1.85), _pol(av, 2.12)], lambda t: 0.07), TOP + 0.05, 0.1, pavio, smooth=False)
    s.flat(_chama(*_pol(av, 1.9), av, 2.4, 0.78, curl=0.6, onda=0.2), 2.0, 0.45, laranja, outline=cobre, ow=0.07, emit=2.0, smooth=False)
    s.flat(_chama(*_pol(av, 2.1), av, 1.6, 0.46, curl=0.6, onda=0.15), 2.45, 0.05, amarelo, emit=3.0, smooth=False)
    s.flat(ellipse(*_pol(av, 2.32), 0.2, 0.15, n=10, rot=av), 2.5, 0.03, cobre, emit=1.0)
    # mão: velinha (poça, pavio e chama) com um pingo escorrendo
    s.hand_flat(ellipse(0.0, 0.0, 0.4, 0.4, n=12), 1.83, 0.02, amarelo, outline=cera2, ow=0.04)
    s.hand_flat(_tubo([(0.4, 0.15), (0.78, 0.3)], lambda t: 0.12 - 0.04*min(t/0.6, 1) + 0.06*max(0, (t-0.6)/0.4), cap1=True, n=10),
                1.2, 0.55, cera, outline=marrom, ow=0.04, smooth=False)
    s.hand_flat(_tubo([(0.0, 0.0), (0.12, -0.22)], lambda t: 0.04), 1.85, 0.06, pavio, smooth=False)
    s.hand_flat(_chama(0.12, -0.2, math.radians(-60), 0.7, 0.2, curl=0.5), 1.9, 0.08, laranja, outline=cobre, ow=0.03, emit=2.0, smooth=False)


def bomba(s):
    # Bomba: placa redonda cobrindo o quadrado (recortada em volta das mãos), sombra num lado e brilho no outro,
    # cinta com rebites na borda, bocal rebitado atrás com pavio curvo e faísca (Neon).
    s.base()
    c1, c2, c3, c4, c5, ink, luz = "#4F4240", "#68534C", "#5D4B46", "#413636", "#302928", "#242020", "#C2A8A2"
    fa, fl = "#F3B008", "#E87118"  # faísca: amarelo e laranja quentes (derivados; os mesmos da paleta da fênix)
    R = 2.45
    s.flat(_radial(lambda a: R, n=64, maos=0.74), 0.93, 1.0, c1, outline=ink, ow=0.12)
    s.flat(_radial(lambda a: R - 0.05, n=64, maos=0.8), TOP, 0.03, c1)
    # cinta mais clara perto da borda (dois arcos, livres das mãos)
    s.flat(_arco(0, 0, 1.98, 2.2, math.radians(58), math.radians(122), n=10), TOP + 0.03, 0.01, c3)
    s.flat(_arco(0, 0, 1.98, 2.2, math.radians(-196), math.radians(16), n=30), TOP + 0.03, 0.01, c3)
    # sombra na lateral direita, brilho na esquerda
    s.flat(_crescente(math.radians(-75), math.radians(12), 2.4, 0.5), TOP + 0.04, 0.012, c4)
    s.flat(_crescente(math.radians(165), math.radians(214), 2.3, 0.36), TOP + 0.04, 0.015, luz)
    s.flat(_crescente(math.radians(172), math.radians(206), 1.88, 0.12), TOP + 0.04, 0.015, luz)
    # rebites na cinta
    for g in (90, 62, 118, 0, -38, -78):
        x, y = _pol(math.radians(g), 2.09)
        s.flat(ellipse(x, y, 0.09, 0.09, n=8), TOP + 0.04, 0.04, c2, outline=ink, ow=0.03)
    # bocal na diagonal de trás à esquerda (fora do meio, para não virar boca), com rebites
    ab = math.radians(-122); P = _local(*_pol(ab, 2.18), ab)
    s.flat([P(-0.05, 0.5), P(0.58, 0.55), P(0.58, -0.55), P(-0.05, -0.5)], 1.9, 0.3, c2, outline=ink, ow=0.07)
    for v in (0.36, -0.36):
        s.flat(ellipse(*P(0.3, v), 0.06, 0.06, n=8), 2.2, 0.02, c3)
    # pavio curvo com marcas da trança e faísca
    c = _curva([P(0.5, 0), P(1.0, 0.05), P(1.45, -0.3), P(1.55, -0.85), P(1.25, -1.2)])
    s.flat(_tubo(c, lambda t: 0.1, n=24), 2.05, 0.12, luz, outline=c5, ow=0.05, smooth=False)
    for t in (0.2, 0.45, 0.7):
        s.flat(_tubo(c, lambda t: 0.1, t, t + 0.05, n=3), 2.17, 0.01, c2, smooth=False)
    fx, fy = P(1.18, -1.32)
    s.flat(_estrela(fx, fy, 0.22, 0.58, n=8, rot=0.2), 2.1, 0.1, fl, emit=2.0, smooth=False)
    s.flat(_estrela(fx, fy, 0.12, 0.33, n=6, rot=0.5), 2.2, 0.03, fa, emit=3.0, smooth=False)
    for u, v, r in [(0.55, -1.6, 0.07), (1.75, -1.7, 0.06)]:
        s.flat(ellipse(*P(u, v), r, r, n=8), 2.1, 0.05, fa, emit=3.0)
    # mão: bombinha (brilho, bocal, pavio e faísca)
    s.hand_flat(ellipse(-0.25, 0.2, 0.17, 0.09, n=10, rot=0.8), 1.84, 0.02, luz)
    s.hand_flat([(0.12, -0.35), (0.45, -0.62), (0.62, -0.42), (0.3, -0.15)], 1.55, 0.35, c2, outline=ink, ow=0.04)
    s.hand_flat(_tubo(_curva([(0.5, -0.55), (0.72, -0.8), (0.95, -0.75)]), lambda t: 0.05, n=10), 1.75, 0.08, luz, smooth=False)
    s.hand_flat(_estrela(1.0, -0.72, 0.1, 0.26, n=6), 1.78, 0.06, fa, emit=3.0, smooth=False)


def fenix(s):
    # Fênix: asas de fogo abertas (penas em labareda com miolo Neon), cauda longa de labaredas atrás,
    # bico pequeno; mão com três chaminhas.
    s.base()
    lar, lar2, ama, ama2, bico, bico2, ink = "#E87118", "#EC8F10", "#F3B008", "#F7BC0D", "#704628", "#4F3728", "#34241A"
    # cauda: cinco labaredas compridas para trás, miolo amarelo
    for i, (ang, L, w) in enumerate([(-117, 2.4, 0.4), (-63, 2.4, 0.4), (-103, 3.1, 0.45), (-77, 3.1, 0.45), (-90, 3.7, 0.5)]):
        a = math.radians(ang); sg = 1 if ang > -90 else (-1 if ang < -90 else 1)
        s.flat(_chama(0.0, -1.3, a, L, w, curl=0.9*sg), 0.78 + 0.03*i, 1.0, lar if i % 2 == 0 else lar2, outline=ink, ow=0.08, smooth=False)
        P = _local(0.0, -1.3, a)
        s.flat(_chama(*P(0.42*L, 0), a, 0.58*L, 0.5*w, curl=0.9*sg), 1.8 + 0.03*i, 0.02, ama, emit=1.5, smooth=False)
    s.flat(_chama(0.0, -2.75, math.radians(-90), 1.1, 0.12, curl=0.9), 1.97, 0.02, ama2, emit=2.5, smooth=False)
    # asas abertas: cinco labaredas compridas de cada lado, pontas curvando para trás (as de trás embaixo)
    for i, (ang, L) in enumerate([(-52, 2.2), (-32, 2.75), (-12, 3.0), (6, 2.85), (22, 2.3)]):
        a = math.radians(ang); P = _local(1.35, 0.1, a)
        s.sym(_chama(1.35, 0.1, a, L, 0.42, curl=-1.3, onda=0.2), 0.78 + 0.03*i, 1.0, lar if i % 2 else lar2, outline=ink, ow=0.08, smooth=False)
        s.sym(_chama(*P(0.4*L, 0), a, 0.58*L, 0.2, curl=-1.3), 1.79 + 0.03*i, 0.02, ama, emit=1.5, smooth=False)
    # (sem crista no topo: de cima, emendada com a cauda, virava cavanhaque)
    # bico pequeno na frente
    s.flat([(-0.32, 1.12), (0.32, 1.12), (0.38, 1.52), (0.24, 1.92), (0.0, 2.15), (-0.24, 1.92), (-0.38, 1.52)], TOP, 0.12, bico, outline=ink, ow=0.06)
    s.flat([(-0.14, 1.9), (0.14, 1.9), (0.0, 2.1)], TOP + 0.12, 0.02, bico2, smooth=False)
    # mão: três chaminhas para fora, miolo Neon
    for ang, cor in [(35, lar2), (0, lar), (-35, lar2)]:
        a = math.radians(ang)
        s.hand_flat(_chama(0.3, -0.05, a, 0.85, 0.2, curl=0.5), 1.15, 0.6, cor, outline=ink, ow=0.04, smooth=False)
    s.hand_flat(_chama(0.55, -0.05, 0.0, 0.5, 0.1, curl=0.5), 1.76, 0.02, ama, emit=2.0, smooth=False)


def yeti(s):
    # Yeti: duas coroas de tufos brancos em volta toda, cristais de gelo saindo das laterais de trás,
    # rosto lilás claro em volta dos olhos, fios e pontinhos de gelo; mão felpuda com garras de gelo.
    s.base()
    pelo, branco, lilas, azulc, azul, gelo, gelo2 = "#E0F0EA", "#FFFFFF", "#B3BFDF", "#88A0BA", "#315F7F", "#32B1B9", "#51C7CC"
    k = 16
    # tufos arredondados (nuvem): bojo redondo para fora, encontro dos tufos para dentro
    tufo = lambda base, amp, fase: (lambda a: _raio_corpo(a) + base + amp*abs(math.sin(k*(a - math.pi/2 + fase)/2))**0.55)
    s.flat(_radial(tufo(0.05, 0.42, 0.0), n=160), 0.8, 1.0, pelo, outline=azulc, ow=0.08, smooth=False)
    s.flat(_radial(tufo(0.0, 0.3, math.pi/k), n=160), 0.85, 1.0, branco, outline=azulc, ow=0.06, smooth=False)
    # cristais de gelo saindo das laterais de trás (por cima dos tufos)
    for ang, L, w in [(-18, 1.75, 0.2), (-44, 2.25, 0.27), (-72, 1.6, 0.19)]:
        a = math.radians(ang)
        s.sym(_cristal(1.25, -1.25, a, L, w), 0.93 + 0.01*(ang == -44), 1.02, gelo, outline=azul, ow=0.06, smooth=False)
        s.sym(_faceta(1.25, -1.25, a, L, w), 1.96 + 0.01*(ang == -44), 0.02, gelo2, smooth=False)
    # rosto lilás claro envolvendo só os olhos (descendo atrás deles vira barba de cima), borda felpuda suave
    # (sem sobrancelhas: atrás dos olhos viram barba de velho de cima, na frente viram bigode a 65°)
    s.flat([(1.45*math.cos(a)*(1 + 0.04*math.sin(9*a)), 0.58 + 0.62*math.sin(a)*(1 + 0.04*math.sin(9*a)))
            for a in [2*math.pi*i/36 for i in range(36)]], TOP, 0.03, lilas)
    # costas: fios de pelo e pontinhos de gelo
    for x, y in [(-0.95, -0.9), (0.75, -1.05), (-0.15, -1.45)]:
        s.flat(_tubo(_curva([(x - 0.25, y + 0.12), (x, y), (x + 0.12, y - 0.15), (x + 0.32, y - 0.2)]), lambda t: 0.04 - 0.02*t), TOP, 0.01, lilas, smooth=False)
    for x, y, r in [(-2.35, -0.25, 0.13), (2.4, 0.15, 0.11), (-0.55, -2.35, 0.12)]:
        s.flat([(x, y + r*1.4), (x + r, y), (x, y - r*1.4), (x - r, y)], 1.87, 0.02, gelo2, smooth=False)
    # mão: punho de pelo atrás e três garras de gelo na frente
    for kk in (-1, 0, 1):
        a = math.radians(90 - 22*kk)
        s.hand_flat(_cristal(kk*0.25, 0.3, a, 0.6, 0.09), 1.35, 0.45, gelo, outline=azul, ow=0.04, smooth=False)
    s.hand_flat([(-0.55, -0.1), (-0.62, -0.5), (-0.32, -0.42), (-0.15, -0.8), (0.1, -0.5), (0.35, -0.78), (0.45, -0.4), (0.68, -0.45), (0.58, -0.08)],
                1.1, 0.75, branco, outline=lilas, ow=0.04)


def besouro(s):
    # Besouro-rinoceronte: chifre grande na frente que sobe e volta em gancho com ponta dupla, élitros divididos ao meio
    # passando da borda de trás com brilho, seis patinhas pelas laterais; mão com garrinhas e casquinho.
    s.base()
    c1, c2, c3, c4, c5, ink, ouro = "#4E3228", "#5A3B2C", "#674531", "#412924", "#372222", "#331F1F", "#E4A139"
    # seis patinhas (dois segmentos, unha na ponta)
    for pts in ([(1.5, 0.55), (2.45, 0.6), (2.95, 1.1), (3.15, 1.2)],
                [(1.5, -0.35), (2.6, -0.4), (3.1, -0.9), (3.3, -0.92)],
                [(1.4, -1.1), (2.3, -1.75), (2.55, -2.55), (2.72, -2.7)]):
        s.sym(_tubo(_curva(pts, per=5), lambda t: 0.14 - 0.08*t, cap1=True, n=20), 0.6, 0.4, c3, outline=ink, ow=0.06, smooth=False)
    # cabeça (placa na frente, passa da borda) de onde sai o chifre
    s.flat(ellipse(0.0, 2.15, 0.62, 0.5, n=12), 0.9, 1.0, c1, outline=ink, ow=0.08)
    # élitros: silhueta (embaixo, com contorno) e topo (sem contorno, tom próximo do corpo)
    el = [(0.05, -0.2), (0.75, -0.1), (1.5, -0.2), (2.05, -0.5), (2.3, -1.15), (2.2, -1.95), (1.8, -2.6), (1.05, -3.0), (0.05, -3.1)]
    s.sym(el, 0.85, 1.0, c2, outline=ink, ow=0.09)
    s.sym(el, TOP, 0.04, c2)
    s.flat([(-0.03, -0.45), (0.03, -0.45), (0.03, -3.05), (-0.03, -3.05)], TOP + 0.04, 0.01, c5, smooth=False)
    # brilho dos élitros: faixa mais clara e risco dourado nas laterais
    for pts, w, cor, z in [([(1.3, -0.55), (1.72, -1.15), (1.78, -1.85), (1.45, -2.45)], 0.15, c3, TOP + 0.04),
                           ([(1.5, -0.75), (1.7, -1.15), (1.72, -1.6)], 0.045, ouro, TOP + 0.05)]:
        s.sym(_tubo(_curva(pts), lambda t, w=w: w*(0.35 + 0.65*math.sin(math.pi*t)), n=20), z, 0.01, cor, smooth=False)
    # chifre: base deitada na frente, depois sobe (fatias empilhadas) e volta em gancho por cima com ponta dupla
    # (fica todo à frente dos olhos; na câmera do jogo aparece subindo)
    # arco alto: sai da cabeça na frente, sobe e volta por cima do topo; a ponta dupla fica acima da linha dos olhos
    # na câmera do jogo (se ficar baixo, vira tromba). Feito em degraus: cada trecho do arco é uma cápsula na sua altura.
    arco = _curva([(2.45, 1.3), (2.85, 2.55), (2.7, 3.75), (2.1, 4.7), (1.35, 5.05)], per=4)
    n = len(arco) - 1
    for i in range(n):
        (y0, z0), (y1, z1) = arco[i], arco[i + 1]
        w = 0.4 - 0.29*i/(n - 1)
        s.flat(_tubo([(0.0, y0), (0.0, y1 if abs(y1 - y0) > 0.02 else y0 - 0.03)], lambda t, w=w: w, cap0=True, cap1=True, n=4),
               min(z0, z1) - 0.05, abs(z1 - z0) + 0.3, c3, smooth=False)
    s.flat(_tubo([(0.1, 2.1), (0.1, 1.55)], lambda t: 0.03), 5.24, 0.01, ouro, smooth=False)
    s.sym(_tubo([(0.0, 1.5), (0.24, 1.14)], lambda t: 0.1 - 0.06*t, cap1=True, n=8), 5.0, 0.2, c3, outline=ink, ow=0.04, smooth=False)
    # mão: casquinho com brilho e duas garrinhas curvas na frente
    s.hand_flat(ellipse(0.0, -0.1, 0.5, 0.45, n=12), 1.6, 0.28, c2, outline=ink, ow=0.04)
    s.hand_flat(ellipse(-0.18, 0.02, 0.14, 0.07, n=8, rot=0.6), 1.88, 0.01, ouro)
    for kk in (-1, 1):
        s.hand_flat(_tubo(_curva([(kk*0.22, 0.4), (kk*0.3, 0.72), (kk*0.12, 0.88)]), lambda t: 0.08 - 0.05*t, n=10), 1.3, 0.4, c5, outline=ink, ow=0.04, smooth=False)


def slime(s):
    # Slime: gosma ondulada maior que o quadrado (recortada em volta das mãos), pingos e gotinhas soltas pela borda,
    # topo mais claro com brilho, bolhas translúcidas e partículas; mão pingando.
    s.base()
    lil1, lil2, lil3, roxo, roxo2, br, cinza = "#E095FF", "#CD84F8", "#B870F4", "#8150B7", "#513A7D", "#F8F7FA", "#8E83A8"
    R = lambda a: 2.3 + 0.1*math.sin(5*a + 0.7) + 0.05*math.sin(9*a)
    # pingos e gotas soltas (embaixo da gosma)
    for g, L in [(-12, 0.55), (-48, 0.85), (-78, 0.4), (-118, 0.7), (-152, 0.5), (176, 0.62), (78, 0.35), (102, 0.45)]:
        s.flat(_gota(math.radians(g), L, w=0.34, bulbo=0.27, dentro=0.0), 0.72, 1.0, lil3, outline=roxo, ow=0.09, smooth=False, alpha=0.9)
    for x, y, r in [(1.95, -2.95, 0.17), (-2.1, -2.25, 0.14), (-3.25, 0.45, 0.12), (3.05, -0.3, 0.13)]:
        s.flat(ellipse(x, y, r, r*1.1, n=10), 0.62, 0.6, lil3, outline=roxo, ow=0.06, alpha=0.9)
    # gosma (silhueta) e topo mais claro
    s.flat(_radial(R, n=60, maos=0.74), 0.9, 1.03, lil3, outline=roxo, ow=0.11, alpha=0.9)
    s.flat(_radial(lambda a: R(a) - 0.2, n=60, maos=0.86), TOP - 0.027, 0.03, lil2, alpha=0.9)  # Elizeu abaixou 05/11
    # brilho grande à esquerda, risco branco e pontinhos
    s.flat(_blob(-1.3, -0.25, 0.55, n=12, wob=0.1, seed=2, sy=1.5), TOP + 0.03, 0.01, lil1)
    s.flat(_tubo(_curva([(-1.95, -0.55), (-2.0, 0.15), (-1.72, 0.7)]), lambda t: 0.1*math.sin(math.pi*(0.15 + 0.7*t)), n=16), TOP + 0.04, 0.01, br, smooth=False)
    s.flat(ellipse(-1.65, -1.0, 0.08, 0.08, n=8), TOP + 0.04, 0.01, br)
    s.flat(ellipse(-1.45, -1.25, 0.05, 0.05, n=8), TOP + 0.04, 0.01, br)
    # bolhas translúcidas com reflexo
    for x, y, r in [(1.2, -0.55, 0.26), (0.55, -1.4, 0.17), (1.55, -1.55, 0.13), (-0.65, -1.35, 0.2)]:
        s.flat(ellipse(x, y, r, r, n=12), TOP + 0.04, 0.02, lil1, outline=br, ow=0.03, alpha=0.7)
        s.flat(ellipse(x - r*0.35, y + r*0.35, r*0.25, r*0.18, n=8, rot=0.8), TOP + 0.06, 0.01, br)
    # partículas suspensas
    for x, y, r, cor in [(-0.15, -1.75, 0.07, cinza), (1.0, -1.1, 0.05, roxo2), (-1.0, -0.75, 0.05, cinza)]:
        s.flat(ellipse(x, y, r, r, n=8), TOP + 0.035, 0.01, cor)
    # mão: pingo escorrendo, bolhinha e brilho
    s.hand_flat(_tubo([(0.3, -0.2), (0.65, -0.62)], lambda t: 0.16 - 0.06*min(t/0.6, 1) + 0.08*max(0, (t - 0.6)/0.4), cap1=True, n=10),
                1.15, 0.55, lil3, outline=roxo, ow=0.04, smooth=False)
    s.hand_flat(ellipse(-0.1, -0.1, 0.16, 0.16, n=10), 1.84, 0.02, lil1, outline=br, ow=0.03, alpha=0.7)
    s.hand_flat(_tubo(_curva([(-0.4, 0.05), (-0.3, 0.33), (-0.05, 0.45)]), lambda t: 0.05*math.sin(math.pi*(0.15 + 0.7*t)), n=10), 1.85, 0.01, br, smooth=False)


LOTE = [
    ("guaxinim", guaxinim, "#7C7578", "#251F20", "#7C7578", "#251F20"),
    ("javali", javali, "#55413E", "#2D2025", "#55413E", "#2D2025"),
    ("cogumelo", cogumelo, "#B3271C", "#861821", "#F2DEC6", "#CD7F64"),
    ("onca", onca, "#CB9C63", "#231F20", "#CB9C63", "#231F20"),
    ("vela", vela, "#D2B389", "#7C5046", "#D2B389", "#7C5046"),
    ("bomba", bomba, "#4F4240", "#242020", "#4F4240", "#242020"),
    ("fenix", fenix, "#E87118", "#34241A", "#EC8F10", "#34241A"),
    ("yeti", yeti, "#E0F0EA", "#88A0BA", "#E0F0EA", "#88A0BA"),
    ("besouro", besouro, "#4E3228", "#331F1F", "#4E3228", "#331F1F"),
    ("slime", slime, "#B870F4", "#8150B7", "#CD84F8", "#8150B7"),
]
