# Lote 3 (parte B) — skins de corpo. Montar com build_skins.py (Blender aberto) ou render_lote.py (segundo plano).
from skin_lib import *


def _bezier(p0, p1, p2, p3, n=16):
    # pontos de uma curva de Bézier cúbica (linha central de rabos)
    out = []
    for i in range(n + 1):
        t = i / n; u = 1 - t
        out.append(tuple(u*u*u*p0[j] + 3*u*u*t*p1[j] + 3*u*t*t*p2[j] + t*t*t*p3[j] for j in (0, 1)))
    return out

def _tube(center, w0, w1):
    # faixa em volta de uma linha central, afinando de w0 (base) para w1 (ponta), com ponta arredondada
    L, R = [], []
    n = len(center)
    for i, (x, y) in enumerate(center):
        a = center[max(i - 1, 0)]; b = center[min(i + 1, n - 1)]
        dx, dy = b[0] - a[0], b[1] - a[1]; l = math.hypot(dx, dy) or 1
        nx, ny = -dy / l, dx / l
        w = w0 + (w1 - w0) * i / (n - 1)
        L.append((x + nx*w, y + ny*w)); R.append((x - nx*w, y - ny*w))
    (xe, ye), (xp, yp) = center[-1], center[-2]
    dx, dy = xe - xp, ye - yp; l = math.hypot(dx, dy) or 1
    tip = [(xe + dx/l*w1*0.9, ye + dy/l*w1*0.9)]
    return L + tip + list(reversed(R))

def _strip(a, b, wa, wb):
    # traço afinando de a para b (bigodes)
    dx, dy = b[0] - a[0], b[1] - a[1]; l = math.hypot(dx, dy) or 1
    nx, ny = -dy / l, dx / l
    return [(a[0] + nx*wa, a[1] + ny*wa), (b[0] + nx*wb, b[1] + ny*wb), (b[0] - nx*wb, b[1] - ny*wb), (a[0] - nx*wa, a[1] - ny*wa)]

def _almond(cx, cy, rx, ry, rot=0.0, p=3.0, n=24):
    # olho amendoado: pontas nas laterais, cheio no meio (cobre o olho redondo do jogo)
    c, s_ = math.cos(rot), math.sin(rot)
    pts = []
    for i in range(n):
        t = 2*math.pi*i/n
        x = rx*math.cos(t); h = ry*(1 - abs(math.cos(t))**p)
        y = h if math.sin(t) >= 0 else -h
        pts.append((cx + x*c - y*s_, cy + x*s_ + y*c))
    return pts

def _fluffy(cx, cy, r, bumps=9, amp=0.07, n=36, start=0.0):
    # disco com borda felpuda (ondas suaves, não pontas)
    return [(cx + r*(1 + amp*math.cos(bumps*(2*math.pi*i/n) + start))*math.cos(2*math.pi*i/n),
             cy + r*(1 + amp*math.cos(bumps*(2*math.pi*i/n) + start))*math.sin(2*math.pi*i/n)) for i in range(n)]


def _hz(x, y, rad=0.0):
    # altura da superfície da mão (esfera) embaixo de uma peça em (x, y) relativo ao centro da mão;
    # fora da esfera fica um pouco acima do meio dela (peça segurada)
    r = max(math.hypot(x, y) - rad, 0.0); R = HAND_D / 2
    return HZ + (math.sqrt(R*R - r*r) if r < R - 0.05 else 0.3) - 0.02

def gato(s):
    # Gato preto: orelhas curtas e largas nos cantos de trás, olhos amendoados âmbar em volta dos olhos do jogo,
    # bigodes finos saindo das laterais da frente, rabo fino em ponto de interrogação, mão com almofadinhas.
    s.base()
    body, dark, mid, ink, amber = "#342D30", "#231F20", "#2D2627", "#1B1718", "#AB6E39"
    # orelhas: triângulos quase equiláteros nos cantos de trás, ponta para fora (menores e mais retas que lobo/raposa)
    ear = [(0.7, -0.5), (1.6, 0.1), (2.05, -1.0)]
    s.sym(ear, TOP, 0.2, body, outline=ink, ow=0.07, smooth=False)
    s.sym([(0.98, -0.45), (1.55, -0.08), (1.85, -0.8)], TOP + 0.2, 0.02, amber, smooth=False)
    # rabo comprido e fino, curvado em ponto de interrogação para o lado esquerdo
    tail = _tube(_bezier((0.15, -1.5), (0.25, -3.5), (-2.4, -3.7), (-2.3, -2.1), n=18), 0.24, 0.17)
    s.flat(tail, 0.85, 1.0, body, outline=ink, ow=0.08)
    s.flat(_tube(_bezier((-1.55, -3.15), (-2.1, -3.0), (-2.3, -2.6), (-2.3, -2.15), n=8), 0.07, 0.05), 1.87, 0.03, mid)
    # bigodes: três traços finos de cada lado, entre o olho e a mão
    for a, b in [((1.55, 0.75), (2.9, 0.85)), ((1.6, 0.5), (2.95, 0.38)), ((1.55, 0.25), (2.8, -0.08))]:
        s.sym(_strip(a, b, 0.05, 0.02), 1.86, 0.04, dark, smooth=False)
    # olhos amendoados âmbar: o olho preto do jogo vira a pupila
    for k in (-1, 1):
        s.flat(_almond(k*EYE_X, EYE_Y, 0.7, 0.57, rot=-k*0.22, p=3.5), TOP, 0.03, amber)
    # focinho: narizinho triangular na frente
    s.flat([(-0.17, 1.42), (0.17, 1.42), (0.0, 1.22)], TOP, 0.04, ink, smooth=False)
    # (sem faixa escura nas costas: com o boneco virado para cima na tela, ela vira "boca" embaixo dos olhos)
    # mão: patinha com almofadas âmbar, na metade de fora/frente (a de dentro fica embaixo do corpo)
    px, py = 0.2, 0.02
    s.hand_flat(ellipse(px, py, 0.21, 0.17, n=10), _hz(px, py, 0.2), 0.03, amber)
    for a in (15, 52, 89, 126):
        x, y = px + 0.31*math.cos(math.radians(a)), py + 0.31*math.sin(math.radians(a))
        s.hand_flat(ellipse(x, y, 0.085, 0.085, n=8), _hz(x, y, 0.085), 0.03, amber)

def coala(s):
    # Coala: orelhas enormes, redondas e felpudas nas laterais (passam da borda), nariz grande preto na frente,
    # mão segurando um raminho de eucalipto.
    s.base()
    body, dark, ink, fluff, rose, nose = "#8C939B", "#686868", "#3E4549", "#CAABA9", "#AA9393", "#050505"
    leaf = "#7E9488"  # verde-acinzentado do eucalipto (único tom fora da paleta)
    # orelhas: disco grande com borda levemente irregular; pelo claro em tufos só na metade de fora
    # (nada de pétalas regulares nem miolo no centro: vira flor)
    for k in (-1, 1):
        rim = [(k*2.0 + 1.0*(1 + 0.05*math.sin(5*a) + 0.03*math.sin(11*a + 1))*math.cos(a),
                -0.35 + 0.95*(1 + 0.05*math.sin(5*a) + 0.03*math.sin(11*a + 1))*math.sin(a))
               for a in [2*math.pi*i/40 for i in range(40)]]
        s.flat(rim, TOP, 0.14, body, outline=ink, ow=0.08)
        tuft = []
        for i in range(25):  # meia-lua de pelo claro do lado de fora, borda em tufos irregulares
            a = math.radians(-115 + 230*i/24)
            r = 0.82 + 0.07*math.sin(7*a + 0.5) + 0.04*math.sin(13*a)
            tuft.append((k*(2.08 + r*math.cos(a)), -0.37 + r*math.sin(a)))
        for i in range(1, 8):  # lado de dentro: curva suave e ondulada (pelo claro cobre a metade de fora)
            y = -0.37 + 0.74 - 1.48*i/8
            tuft.append((k*(1.78 + 0.08*math.sin(i*1.9) - 0.1*(1 - ((y + 0.37)/0.75)**2)), y))
        # sombra rosada aparecendo só na borda de dentro do pelo claro
        s.flat([(x - k*0.12, y) for x, y in tuft], TOP + 0.14, 0.02, rose)
        s.flat(tuft, TOP + 0.155, 0.03, fluff)
    # nariz grande e escuro: oval comprido do meio dos olhos até a borda da frente, brilho no alto
    s.flat([(0.0, 0.62), (0.3, 0.72), (0.4, 1.1), (0.36, 1.6), (0.18, 1.9), (0.0, 1.95), (-0.18, 1.9), (-0.36, 1.6), (-0.4, 1.1), (-0.3, 0.72)],
           TOP, 0.12, nose, outline=ink, ow=0.05)
    s.flat(ellipse(-0.14, 0.95, 0.08, 0.17, n=10), TOP + 0.12, 0.02, dark)
    # (sem faixa nas costas: com o boneco virado para cima na tela, ela vira "boca"/barba embaixo dos olhos)
    # mão: raminho de eucalipto segurado, saindo para fora e para a frente (a metade de dentro fica embaixo do corpo)
    # (raminho todo numa altura só, logo acima da mão: lê como segurado, sem folhas soltas em alturas diferentes)
    s.hand_flat(_strip((-0.05, -0.3), (0.62, 0.62), 0.05, 0.035), 1.84, 0.03, rose, smooth=False)
    for x, y, a in [(0.3, 0.0, -0.3), (0.06, 0.18, 2.0), (0.52, 0.28, 0.0), (0.28, 0.47, 1.9), (0.7, 0.8, 0.95)]:
        s.hand_flat(ellipse(x, y, 0.21, 0.11, n=12, rot=a), 1.865, 0.035, leaf, outline=ink, ow=0.03)


LOTE = [
    ("gato", gato, "#342D30", "#1B1718", "#342D30", "#1B1718"),
    ("coala", coala, "#8C939B", "#3E4549", "#8C939B", "#3E4549"),
]
