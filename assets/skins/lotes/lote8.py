# Lote 8 — skins de corpo (detalhadas). Montar com build_skins.py (Blender aberto) ou render_lote.py (segundo plano).
# rei dourado, caramujo, monstro da noite, urso pardo, canguru, feneco, peixe abissal, morcego roxo, batata, dragão roxo.
from skin_lib import *


# ---------------------------------------------------------------- ajudantes do lote
def _pol(a, r, cx=0.0, cy=0.0):
    return (cx + math.cos(a) * r, cy + math.sin(a) * r)

def _local(x0, y0, ang):
    ca, sa = math.cos(ang), math.sin(ang)
    return lambda u, v: (x0 + ca*u - sa*v, y0 + sa*u + ca*v)

def _chaikin(poly, passes=2):
    for _ in range(passes):
        poly = [
            p for a, b in zip(poly, poly[1:] + poly[:1])
            for p in ((0.75*a[0] + 0.25*b[0], 0.75*a[1] + 0.25*b[1]),
                      (0.25*a[0] + 0.75*b[0], 0.25*a[1] + 0.75*b[1]))
        ]
    return poly

def _curva(ctrl, per=6):
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

def _arco(cx, cy, r0, r1, a0, a1, n=14):
    A = [a0 + (a1 - a0)*i/(n - 1) for i in range(n)]
    return [_pol(a, r1, cx, cy) for a in A] + [_pol(a, r0, cx, cy) for a in reversed(A)]

def _espinho(x0, y0, ang, L, w, curva=0.0):
    P = _local(x0, y0, ang)
    c = _curva([P(0, 0), P(L * 0.5, curva * L), P(L, curva * L * 2.2)], per=5)
    return _tubo(c, lambda t: w * (1 - t) ** 0.85, cap0=True, n=12)


# ---------------------------------------------------------------- skins
def rei_dourado(s):
    # Dragão / criatura real dourada (ref. 32): corpo amarelo-ouro (#F0CC00) com contorno ocre (#C8A000),
    # crista/chifre central curvado em chama (#FCE800 / #E4BC00 / #C8A000) subindo da testa até passar da borda traseira,
    # dois pares de barbatanas/orelhas emplumadas nas laterais e cantos traseiros, listras claras no dorso e focinho suave.
    s.base()
    ouro, borda, claro, medio = "#F0CC00", "#C8A000", "#FCE800", "#E0B800"
    # barbatanas/abas emplumadas grandes nas laterais (meio) e menores nos cantos traseiros
    aba_lat = _chaikin([(1.55, 0.25), (2.48, -0.05), (2.72, -0.68), (2.35, -1.32), (1.58, -1.05)], 2)
    s.sym(aba_lat, 0.88, 0.92, medio, outline=borda, ow=0.09, smooth=False)
    for dy in (-0.32, -0.62, -0.92):
        s.sym([(1.78, dy + 0.08), (2.32, dy - 0.05), (1.78, dy - 0.14)], 1.81, 0.02, borda, smooth=False)
    aba_tras = _chaikin([(1.05, -1.45), (1.72, -1.62), (1.92, -2.38), (1.42, -2.55), (0.95, -1.95)], 2)
    s.sym(aba_tras, 0.86, 0.90, medio, outline=borda, ow=0.08, smooth=False)
    for dx in (1.28, 1.52):
        s.sym([(dx - 0.08, -1.75), (dx + 0.08, -2.22), (dx + 0.14, -1.78)], 1.77, 0.02, borda, smooth=False)
    # focinho arredondado sutil na frente + arcos de sombra dourada ao redor dos olhos
    s.flat(ellipse(0.0, 1.58, 0.72, 0.36, n=20), 0.88, 1.10, ouro, outline=borda, ow=0.08)
    for k in (-1, 1):
        s.flat(_arco(k*EYE_X, EYE_Y, 0.50, 0.68, math.radians(-20), math.radians(200), n=14), TOP, 0.015, medio, smooth=False)
    # listras amarelas claras no dorso traseiro ladeando a crista central
    for x0, L in [(0.62, 1.15), (0.98, 0.95), (1.32, 0.72)]:
        s.sym([(x0 - 0.11, -1.72), (x0 + 0.11, -1.72), (x0 + 0.02, -1.72 + L)], TOP, 0.015, claro, smooth=False)
    # grande crista/chifre central dourado em U na frente e ponta curvada atrás (assinatura da ref. 32)
    u_claro = _chaikin([(-0.48, -0.35), (-0.42, 0.48), (0.0, 0.72), (0.42, 0.48), (0.48, -0.35), (0.28, -1.65), (-0.28, -1.65)], 2)
    s.flat(u_claro, TOP + 0.01, 0.02, claro, smooth=False)
    crista_ext = _chaikin([
        (0.0, 0.45), (0.36, -0.15), (0.44, -1.15), (0.32, -1.95),
        (-0.06, -2.75), (-0.18, -2.25), (-0.42, -1.25), (-0.36, -0.15)
    ], 2)
    s.flat(crista_ext, TOP + 0.03, 0.08, medio, outline=borda, ow=0.07, smooth=False)
    crista_int = _chaikin([(0.0, 0.25), (0.18, -0.55), (0.12, -1.85), (-0.05, -2.42), (-0.22, -1.25)], 2)
    s.flat(crista_int, TOP + 0.11, 0.025, claro, smooth=False)
    # mão: barbatana dourada com 3 pontas
    for kk in (-1, 0, 1):
        s.hand_flat(_espinho(kk*0.2, 0.32, math.radians(90 - 18*kk), 0.45, 0.11), 1.3, 0.38, claro, outline=borda, ow=0.04, smooth=False)


def caramujo(s):
    # Concha de caramujo / búzio listrado (ref. 56): área frontal do personagem limpa em tom pêssego/coral suave (#E4A880)
    # com bochechas rosadas (#C06858), e a concha espiralada montada nas costas/topo (atrás da linha dos olhos, como no
    # caranguejo-eremita / caramujo): aba labial enrolada atrás dos olhos, domo amarelo-areia (#F8D890) com 3 faixas
    # curvas creme (#FCF8DC) e pintinhas, cone espiral em 3 gomos saindo na esquerda (-X) e bico sifonal rosado na direita (+X).
    areia, creme, pessego, rosa_esc, borda = "#F8D890", "#FCF8DC", "#E4A880", "#C06858", "#AC705C"
    s.base(body_color=pessego)
    # sombreado coral suave nas bochechas dianteiras (longe do centro entre os olhos)
    s.sym(ellipse(1.25, 1.15, 0.26, 0.18, n=12), TOP, 0.015, rosa_esc)
    # cone espiralado da concha em 3 gomos saindo para a lateral traseira-esquerda (-X)
    gomo3 = _chaikin([(-2.65, -0.05), (-3.55, -0.42), (-3.55, -0.78), (-2.65, -1.05)], 2)
    s.flat(gomo3, 0.84, 0.90, pessego, outline=borda, ow=0.09, smooth=False)
    gomo2 = _chaikin([(-2.05, 0.35), (-2.98, 0.05), (-3.05, -1.12), (-2.05, -1.32)], 2)
    s.flat(gomo2, 0.86, 0.98, areia, outline=borda, ow=0.09, smooth=False)
    gomo1 = _chaikin([(-1.35, 0.85), (-2.42, 0.55), (-2.52, -1.35), (-1.35, -1.78)], 2)
    s.flat(gomo1, 0.88, 1.06, pessego, outline=borda, ow=0.09, smooth=False)
    # bico sifonal rosado saindo na lateral traseira-direita (+X)
    bico_dir = _chaikin([(1.35, 0.55), (2.48, 0.12), (2.72, -0.42), (2.15, -0.98), (1.35, -0.82)], 2)
    s.flat(bico_dir, 0.88, 1.06, pessego, outline=borda, ow=0.09, smooth=False)
    s.flat(_chaikin([(2.02, 0.08), (2.68, -0.32), (2.28, -0.82), (1.88, -0.45)], 1), 1.95, 0.03, rosa_esc, smooth=False)
    # domo principal da concha cobrindo a metade traseira do corpo (y <= 0.15, atrás dos olhos) e projetando-se atrás
    domo = _chaikin([
        (-1.68, 0.12), (-1.75, -1.55), (-0.45, -2.35), (0.85, -2.18),
        (1.85, -1.45), (1.82, 0.08), (0.0, -0.05)
    ], 2)
    s.flat(domo, 0.90, 1.16, areia, outline=borda, ow=0.10, smooth=False)
    # borda/lábio enrolado da abertura da concha logo atrás da linha dos olhos (de -X a +X)
    labio_arco = _curva([(-1.72, 0.15), (-0.55, 0.02), (0.65, -0.02), (1.78, 0.12)], per=6)
    s.flat(_tubo(labio_arco, lambda t: 0.14 - 0.03*t, cap0=True, cap1=True, n=20), TOP + 0.04, 0.08, pessego, outline=borda, ow=0.05, smooth=False)
    # 3 faixas curvas creme (#FCF8DC) abrindo em leque da direita (+X) até a costura dos gomos na esquerda (-X)
    for y_dir, y_meio, y_esq in [(-0.18, -0.58, -0.18), (-0.42, -1.18, -0.82), (-0.68, -1.78, -1.42)]:
        c = _curva([(1.72, y_dir), (0.18, y_meio), (-1.52, y_esq)])
        s.flat(_tubo(c, lambda t: 0.10 + 0.05*t, cap0=True, cap1=True, n=18), TOP + 0.065, 0.02, creme, smooth=False)
    # pintinhas creme entre as faixas no dorso da concha
    for px, py in [(-0.72, -0.52), (-0.18, -0.88), (0.28, -1.48)]:
        s.flat(ellipse(px, py, 0.11, 0.11, n=10), TOP + 0.07, 0.02, creme)
    # mão: mini conchinha espiral com faixa creme
    s.hand_flat(ellipse(0.0, 0.0, 0.38, 0.28, n=12), 1.82, 0.04, areia, outline=borda, ow=0.03)
    s.hand_flat([(-0.32, -0.05), (0.32, 0.08), (0.28, 0.20), (-0.32, 0.06)], 1.86, 0.02, creme, smooth=False)


def monstro_noite(s):
    # Monstro / aranha da noite (ref. 137): corpo azul-noturno escuro (#283050) com contorno roxo-lavanda (#6864B4),
    # dois grandes chifres curvos apontando para trás e dois pares de espinhos curvos nas laterais (#202440 com borda #6864B4),
    # aros roxos (#5C4CA4) ao redor dos olhos principais e mais 2 pares de olhos roxos brilhantes no dorso!
    s.base()
    corpo, escuro, borda, aro, pupila, branco = "#283050", "#202440", "#6864B4", "#5C4CA4", "#50408C", "#FCFCFC"
    # dois grandes chifres traseiros curvos com pontas afiadas + dois pares de espinhos curvos nas bochechas (ref. 137)
    chifre_tras = (
        _curva([(0.82, -1.25), (0.58, -2.15), (0.95, -2.95)], per=5)
        + _curva([(0.95, -2.95), (1.75, -2.45), (2.15, -1.25)], per=5)[1:]
    )
    s.sym(chifre_tras, 0.86, 1.02, escuro, outline=borda, ow=0.10, smooth=False)
    esp_meio = (
        _curva([(1.45, -1.05), (2.18, -1.35), (2.68, -2.02)], per=5)
        + _curva([(2.68, -2.02), (2.78, -0.85), (2.15, 0.25), (1.45, 0.15)], per=5)[1:]
    )
    s.sym(esp_meio, 0.87, 1.02, escuro, outline=borda, ow=0.10, smooth=False)
    esp_frente = (
        _curva([(1.48, -0.05), (2.15, 0.15), (2.68, 0.42)], per=5)
        + _curva([(2.68, 0.42), (2.35, 1.25), (1.58, 1.62), (1.38, 0.85)], per=5)[1:]
    )
    s.sym(esp_frente, 0.88, 1.02, escuro, outline=borda, ow=0.10, smooth=False)
    # sombra interna azul-escura nas laterais do topo
    s.sym(_chaikin([(1.15, 1.35), (1.68, 1.15), (1.85, -0.45), (1.45, -1.65), (1.05, -1.25), (1.32, 0.15)], 2),
          TOP, 0.015, escuro, smooth=False)
    # aros roxos vazados ao redor dos dois olhos principais na frente (deixam os olhos do código visíveis!)
    for k in (-1, 1):
        for a0, a1 in ((-0.08, math.pi + 0.08), (math.pi - 0.08, 2 * math.pi + 0.08)):
            s.flat(_arco(k*EYE_X, EYE_Y, 0.46, 0.66, a0, a1, n=14), TOP + 0.015, 0.025, aro, smooth=False)
    # 2 pares extras de olhos no dorso (par médio nas laterais e par menor mais atrás, como na ref. 137!)
    for ex, ey, r in [(1.18, -0.35, 0.42), (0.68, -1.18, 0.30)]:
        for k in (-1, 1):
            cx = k * ex
            s.flat(ellipse(cx, ey, r, r, n=16), TOP + 0.02, 0.03, aro)
            s.flat(ellipse(cx, ey, r * 0.72, r * 0.72, n=14), TOP + 0.05, 0.02, pupila)
            s.flat(ellipse(cx - 0.22 * r, ey - 0.25 * r, r * 0.32, r * 0.32, n=10), TOP + 0.07, 0.02, branco)
    # mão: garras curvas azul-escuras com borda lavanda e olhinho roxo no dorso
    s.hand_flat(ellipse(0.0, 0.0, 0.24, 0.24, n=12), 1.83, 0.03, aro)
    s.hand_flat(ellipse(-0.06, -0.06, 0.08, 0.08, n=8), 1.86, 0.02, branco)
    for kk in (-1, 1):
        s.hand_flat([(kk*0.18, 0.35), (kk*0.42, 0.42), (kk*0.32, 0.82)], 1.25, 0.38, escuro, outline=borda, ow=0.04, smooth=False)


def urso_pardo(s):
    # Urso pardo / avermelhado (ref. 165): corpo marrom-ferrugem (#B05430) com contorno marrom-escuro (#682820),
    # orelhas grandes redondas nos cantos de trás com interior recortado (#8C3C30), tufos de pelo nas bochechas
    # e focinho oval saliente na frente (#8C3C30) com nariz triangular escuro (#382424).
    s.base()
    pelo, borda, miolo, nariz = "#B05430", "#682820", "#8C3C30", "#382424"
    # grandes orelhas redondas nos cantos traseiros-laterais com miolo recortado em zigue-zague
    for k in (-1, 1):
        X = lambda P: [(k*x, y) for x, y in P]
        s.flat(ellipse(k*1.75, -1.55, 0.98, 0.92, n=24, rot=-k*0.35), 0.88, 1.02, pelo, outline=borda, ow=0.10)
        miolo_or = _chaikin([
            (1.38, -1.25), (1.95, -1.15), (2.28, -1.65), (2.05, -2.08),
            (1.85, -1.78), (1.68, -1.95), (1.58, -1.65), (1.35, -1.72)
        ], 1)
        s.flat(X(miolo_or), 1.91, 0.025, miolo, smooth=False)
    # tufos felpudos nas bochechas/laterais da frente (com dois dentinhos de pelo como na ref. 165)
    tufo = _chaikin([(1.48, -0.35), (2.12, -0.15), (2.18, 0.45), (1.92, 0.55), (2.15, 0.95), (1.95, 1.55), (1.42, 1.65)], 1)
    s.sym(tufo, 0.88, 1.00, pelo, outline=borda, ow=0.09, smooth=False)
    # focinho oval saliente na frente (subindo um pouco entre os olhos, sem tapá-los!) + nariz escuro
    foc = _chaikin([(-0.62, 0.35), (-0.42, 0.05), (0.0, -0.05), (0.42, 0.05), (0.62, 0.35),
                    (0.75, 1.55), (0.48, 2.15), (0.0, 2.28), (-0.48, 2.15), (-0.75, 1.55)], 2)
    s.flat(foc, 0.86, 1.15, miolo, outline=borda, ow=0.08, smooth=False)
    nar = _chaikin([(-0.32, 1.38), (0.32, 1.38), (0.36, 1.62), (0.0, 1.88), (-0.36, 1.62)], 2)
    s.flat(nar, TOP + 0.02, 0.04, nariz, smooth=False)
    # mão: patinha de urso com almofadinha e 3 garras
    s.hand_flat(ellipse(0.0, -0.02, 0.28, 0.22, n=10), 1.83, 0.03, miolo)
    for kk in (-1, 0, 1):
        s.hand_flat(ellipse(kk*0.22, 0.36, 0.10, 0.13, n=8), 1.4, 0.35, nariz)


def canguru(s):
    # Canguru / lebre do deserto (ref. 169): corpo caramelo-alaranjado (#D48038) com contorno marrom (#9C4C24),
    # orelhas longas pontudas curvadas para trás nas laterais com interior avermelhado (#983C28),
    # tufos duplos afiados nas bochechas, faixa creme-areia (#D8B494) frisada entre os olhos
    # e focinho pontudo saliente na frente com duas narinas (#983C28).
    s.base()
    corpo, borda, miolo, areia = "#D48038", "#9C4C24", "#983C28", "#D8B494"
    # orelhas longas e pontudas curvando das laterais para trás
    orelha = _chaikin([
        (0.85, -0.85), (1.65, -0.65), (2.22, -1.35), (2.15, -2.35),
        (1.65, -3.15), (1.28, -2.45), (0.85, -1.75)
    ], 2)
    s.sym(orelha, 0.88, 1.02, corpo, outline=borda, ow=0.10, smooth=False)
    miolo_or = _chaikin([(1.25, -1.15), (1.82, -1.18), (1.92, -1.95), (1.58, -2.62), (1.28, -1.85)], 2)
    s.sym(miolo_or, 1.91, 0.025, miolo, smooth=False)
    # tufos duplos afiados nas bochechas (silhueta lateral da ref. 169)
    tufo = [(1.48, -0.45), (2.25, -0.15), (1.82, 0.25), (2.18, 0.58), (1.78, 0.88), (1.95, 1.35), (1.42, 1.55)]
    s.sym(tufo, 0.88, 1.00, corpo, outline=borda, ow=0.09, smooth=False)
    # mancha creme-areia entre os olhos com friso caramelo no meio
    mancha = _chaikin([(-0.55, 0.02), (0.55, 0.02), (0.62, 1.25), (-0.62, 1.25)], 2)
    s.flat(mancha, TOP, 0.015, areia, smooth=False)
    s.flat(_arco(0.0, 1.05, 0.55, 0.72, math.radians(220), math.radians(320), n=12), TOP + 0.015, 0.015, corpo, smooth=False)
    # focinho pontudo saliente na frente com par de narinas em gota
    foc = _chaikin([(-0.88, 1.25), (-0.75, 1.95), (0.0, 2.45), (0.75, 1.95), (0.88, 1.25), (0.0, 1.02)], 2)
    s.flat(foc, 0.86, 1.15, corpo, outline=borda, ow=0.09, smooth=False)
    for k in (-1, 1):
        s.flat(ellipse(k*0.26, 1.72, 0.14, 0.09, n=10, rot=-k*0.45), TOP + 0.02, 0.025, miolo)
    # mão: patinha com faixa areia e unhas marrons
    s.hand_flat(ellipse(0.0, 0.05, 0.32, 0.22, n=10), 1.83, 0.03, areia)
    for kk in (-1, 0, 1):
        s.hand_flat(ellipse(kk*0.2, 0.38, 0.09, 0.13, n=8), 1.4, 0.35, borda)


def feneco(s):
    # Raposa-do-deserto / feneco (ref. 178): corpo amarelo-areia (#F0C470) com contorno caramelo (#C0945C),
    # orelhas gigantes abertas em V para os lados/trás com interior terracota (#D49058) e tufos creme (#F0ECE0),
    # bochechas felpudas com pontas creme e máscara facial/focinho creme (#F0ECE0 com borda #D8B49C) e nariz escuro (#382424).
    s.base()
    areia, creme, borda, borda_cl, miolo, pess, nariz = (
        "#F0C470", "#F0ECE0", "#C0945C", "#D8B49C", "#D49058", "#E8BC88", "#382424"
    )
    # orelhas gigantes abertas para trás e para os lados (assinatura do feneco!)
    orelha = _chaikin([
        (0.55, -0.95), (1.65, -0.75), (2.78, -1.45), (3.05, -2.85),
        (2.35, -2.95), (1.25, -2.25), (0.45, -1.65)
    ], 2)
    s.sym(orelha, 0.88, 1.02, areia, outline=borda, ow=0.10, smooth=False)
    miolo_or = _chaikin([(1.35, -1.25), (2.35, -1.55), (2.62, -2.55), (1.85, -2.25)], 2)
    s.sym(miolo_or, 1.91, 0.02, miolo, smooth=False)
    tufo_or = _chaikin([(1.05, -1.15), (1.82, -1.35), (1.58, -1.68), (1.92, -1.85), (1.35, -2.02), (0.98, -1.62)], 1)
    s.sym(tufo_or, 1.93, 0.025, creme, smooth=False)
    # tufos duplos nas bochechas laterais + metade dianteira creme das bochechas e focinho saliente
    bochecha_sup = [(1.48, -0.35), (2.32, 0.15), (1.92, 0.45), (2.38, 0.95), (1.48, 1.15)]
    s.sym(bochecha_sup, 0.88, 1.00, areia, outline=borda, ow=0.09, smooth=False)
    mascara_creme = _chaikin([
        (-1.55, 0.85), (-2.38, 1.35), (-1.45, 1.65), (-0.72, 1.72), (-0.52, 2.28),
        (0.0, 2.42), (0.52, 2.28), (0.72, 1.72), (1.45, 1.65), (2.38, 1.35), (1.55, 0.85),
        (1.38, -0.05), (0.78, -0.15), (0.0, 0.35), (-0.78, -0.15), (-1.38, -0.05)
    ], 2)
    s.flat(mascara_creme, 0.89, 1.13, creme, outline=borda_cl, ow=0.08, smooth=False)
    # sombreado pêssego ao lado do focinho + nariz triangular escuro na ponta
    s.sym(ellipse(0.48, 1.48, 0.22, 0.35, n=12), TOP + 0.02, 0.015, pess)
    nar = _chaikin([(-0.28, 1.58), (0.28, 1.58), (0.32, 1.82), (0.0, 2.05), (-0.32, 1.82)], 2)
    s.flat(nar, TOP + 0.03, 0.04, nariz, smooth=False)
    # mão: patinha areia com ponta creme
    s.hand_flat(ellipse(0.0, 0.18, 0.36, 0.26, n=12), 1.82, 0.04, creme, outline=borda_cl, ow=0.03)


def peixe_abissal(s):
    # Monstro marinho / tritão abissal (ref. 188): corpo azul-petróleo escuro (#184054) com contorno azul-marinho (#102438),
    # grandes nadadeiras laterais palmadas em leque (#187CA4 e #1CA0BC com nervuras #143448 e borda #102438),
    # chifre/crista dorsal afiada em dois tons de ciano (#1CA0BC / #187CA4) no centro da cabeça e aros ciano nos olhos.
    s.base()
    corpo, borda, sombra, azul, ciano = "#184054", "#102438", "#143448", "#187CA4", "#1CA0BC"
    # grandes nadadeiras palmadas em leque nas duas laterais (3 pontas com membranas ciano e nervuras escuras)
    nadadeira = [
        (1.55, 1.45), (2.58, 1.55), (2.38, 0.95), (2.92, 0.42),
        (2.42, -0.18), (2.52, -0.88), (1.98, -0.35), (1.55, -0.65)
    ]
    s.sym(nadadeira, 0.86, 1.00, azul, outline=borda, ow=0.10, smooth=False)
    # membranas claras ciano entre as nervuras + nervuras curvas escuras
    s.sym([(1.85, 1.38), (2.42, 1.42), (2.28, 0.98), (1.82, 0.92)], 1.87, 0.02, ciano, smooth=False)
    s.sym([(1.92, 0.65), (2.72, 0.38), (2.28, -0.08), (1.85, 0.15)], 1.87, 0.02, ciano, smooth=False)
    s.sym([(1.95, -0.12), (2.38, -0.68), (2.02, -0.28), (1.78, -0.35)], 1.87, 0.02, ciano, smooth=False)
    for y_in, x_out, y_out in [(0.75, 2.38, 0.95), (0.35, 2.42, -0.18)]:
        s.sym(_tubo([(1.62, y_in), (x_out, y_out)], lambda t: 0.07 - 0.03*t, n=8), 1.89, 0.02, sombra, smooth=False)
    # aros azul-ciano vazados ao redor dos olhos na frente
    for k in (-1, 1):
        for a0, a1 in ((-0.08, math.pi + 0.08), (math.pi - 0.08, 2 * math.pi + 0.08)):
            s.flat(_arco(k*EYE_X, EYE_Y, 0.46, 0.68, a0, a1, n=14), TOP + 0.015, 0.025, azul, smooth=False)
    # crista/chifre dorsal bipartido em dois tons de ciano subindo do centro até passar da borda traseira
    crista = _chaikin([(0.0, 0.35), (0.32, -0.45), (0.18, -1.55), (0.15, -2.35), (-0.28, -1.45), (-0.32, -0.35)], 2)
    s.flat(crista, TOP + 0.02, 0.08, azul, outline=borda, ow=0.07, smooth=False)
    crista_esq = _chaikin([(0.0, 0.28), (0.04, -1.95), (-0.22, -1.35), (-0.25, -0.35)], 2)
    s.flat(crista_esq, TOP + 0.10, 0.02, ciano, smooth=False)
    # mão: barbatana palmada azul-ciano com 3 pontas
    s.hand_flat([(-0.45, 0.25), (-0.35, 0.78), (0.0, 0.58), (0.35, 0.78), (0.45, 0.25)],
                1.3, 0.40, ciano, outline=borda, ow=0.04, smooth=False)


def morcego_roxo(s):
    # Morcego / gárgula sombria roxa (ref. 192): corpo roxo-ameixa (#58488C) com contorno índigo-escuro (#303458),
    # orelhas enormes curvas em meia-lua nos cantos traseiros com duplo dente interno afiado e miolo em duas camadas (#8060A8 / #3C3C68),
    # tufos duplos afiados nas bochechas e queixo de morcego em V contínuo com o rosto (sem costura redonda de urso!)
    # e nariz de morcego em V achatado (#2C2848).
    s.base()
    roxo, borda, escuro, sombra, lilas = "#58488C", "#303458", "#2C2848", "#3C3C68", "#8060A8"
    # enormes orelhas curvas em meia-lua com duas pontas internas afiadas (sem arredondar as pontas!) e miolo em camadas
    for k in (-1, 1):
        X = lambda P: [(k*x, y) for x, y in P]
        orelha = (
            _curva([(0.52, -0.65), (0.88, -1.45), (0.68, -2.18)], per=4)
            + [(1.12, -1.92)]
            + _curva([(1.12, -1.92), (0.95, -2.42), (0.88, -2.92)], per=4)[1:]
            + _curva([(0.88, -2.92), (1.82, -2.65), (2.42, -1.72), (2.42, -0.58), (1.72, 0.15)], per=5)[1:]
        )
        s.flat(X(orelha), 0.88, 1.04, roxo, outline=borda, ow=0.10, smooth=False)
        miolo_lilas = _chaikin([(0.68, -0.82), (1.02, -1.82), (1.58, -1.98), (2.05, -1.25), (1.75, -0.15), (1.15, -0.35)], 1)
        s.flat(X(miolo_lilas), 1.93, 0.02, lilas, smooth=False)
        miolo_esc = _chaikin([(1.25, -0.55), (1.88, -1.68), (2.15, -1.15), (1.85, -0.25)], 1)
        s.flat(X(miolo_esc), 1.95, 0.02, sombra, smooth=False)
    # tufos duplos pontudos nas bochechas
    tufo_lat = [(1.48, -0.15), (2.18, 0.22), (1.78, 0.45), (2.28, 0.72), (1.92, 0.92), (2.02, 1.55), (1.42, 1.35)]
    s.sym(tufo_lat, 0.88, 1.00, roxo, outline=borda, ow=0.09, smooth=False)
    # queixo/focinho curto em V contínuo com o topo do rosto (z=0.85, thick=1.05 + tampa sem contorno em TOP, para não ter anel de urso!)
    queixo_v = (
        _curva([(-0.78, 1.25), (-0.52, 1.92), (0.0, 2.22)], per=5)
        + _curva([(0.0, 2.22), (0.52, 1.92), (0.78, 1.25)], per=5)[1:]
    )
    s.flat(queixo_v, 0.85, 1.05, roxo, outline=borda, ow=0.09, smooth=False)
    s.flat(queixo_v, 1.90, 0.10, roxo, smooth=False)
    # nariz de morcego em V largo e achatado na ponta (fiel à ref. 192!)
    nariz_morcego = [(-0.36, 1.35), (0.0, 1.28), (0.36, 1.35), (0.22, 1.55), (0.0, 1.75), (-0.22, 1.55)]
    s.flat(_chaikin(nariz_morcego, 1), TOP + 0.015, 0.03, escuro, smooth=False)
    # mão: asinha/garra roxa com detalhe lilás
    s.hand_flat(ellipse(0.0, 0.0, 0.28, 0.22, n=10), 1.83, 0.03, lilas)
    for kk in (-1, 1):
        s.hand_flat([(kk*0.18, 0.35), (kk*0.42, 0.42), (kk*0.32, 0.82)], 1.25, 0.38, roxo, outline=borda, ow=0.04, smooth=False)


def batata(s):
    # Batata / tubérculo dourado (ref. 194): formato orgânico assimétrico mais comprido e arredondado atrás (topo da imagem),
    # marrom-dourado (#B8803C) com ondas de sombra (#A06434), contorno marrom-terra (#784C34) e grande brilho oval claro (#D0A054)
    # na metade superior esquerda; sem boca escura entre os olhos para leitura limpa de cima.
    claro, medio, sombra, borda = "#D0A054", "#B8803C", "#A06434", "#784C34"
    s.base()
    # domo arredondado assimétrico da batata saindo por trás (z=0.85, thick=1.05 como na cenoura, sem linha de contorno no meio!)
    domo_tras = _chaikin([
        (-1.68, -1.15), (-1.52, -1.98), (-0.42, -2.65),
        (0.65, -2.42), (1.55, -1.85), (1.68, -1.15)
    ], 2)
    s.flat(domo_tras, 0.85, 1.05, medio, outline=borda, ow=0.10, smooth=False)
    s.flat(domo_tras, 1.90, 0.10, medio, smooth=False)
    # ondas de sombra marrom-média (#A06434) na frente (desviando dos olhos!) e em faixa diagonal pelo dorso
    sombra_fr = _chaikin([
        (-1.58, 1.62), (1.58, 1.62), (1.62, 0.35), (1.32, 0.35), (1.28, 1.08),
        (0.30, 1.08), (0.22, 0.05), (-0.22, 0.05), (-0.30, 1.08), (-1.28, 1.08), (-1.58, 0.85)
    ], 2)
    s.flat(sombra_fr, TOP, 0.015, sombra, smooth=False)
    onda_sombra = _chaikin([
        (-0.85, -0.35), (0.55, -1.48), (1.08, -0.92), (0.15, -0.05)
    ], 2)
    s.flat(onda_sombra, TOP, 0.015, sombra, smooth=False)
    # brilho oval dourado-claro (#D0A054) na metade traseira-esquerda (-X, -Y)
    s.flat(ellipse(-0.42, -1.48, 0.58, 0.38, n=18, rot=-0.55), TOP + 0.015, 0.025, claro)
    # olhinhos/covinhas de batata sutis nas laterais traseiras
    for px, py, r in [(0.75, -0.65, 0.14), (-1.05, -0.75, 0.11), (0.25, -1.85, 0.10)]:
        s.flat(ellipse(px, py, r, r * 0.75, n=10, rot=0.3), TOP + 0.02, 0.015, borda)
    # mão: mini batatinha com mancha clara
    s.hand_flat(ellipse(-0.12, 0.08, 0.24, 0.16, n=10, rot=-0.4), 1.83, 0.03, claro)


def dragao_roxo(s):
    # Dragão roxo chifrudo (ref. 214): corpo roxo (#683480) com contorno roxo-escuro (#30204C),
    # dois enormes chifres curvos cor de osso/bege (#C8B09C / #B49480 com borda #78544C) saindo do topo para trás,
    # asas de morcego nas laterais (#4C2C60 com membrana vinho #7C3450 e garrinha bege),
    # presas/placas beges curvas nos cantos da frente, focinho roxo com narinas e brasão/escama magenta (#AC386C) na testa!
    s.base()
    roxo, roxo_e, borda, vinho, osso_cl, osso_esc, osso_b, mag = (
        "#683480", "#4C2C60", "#30204C", "#7C3450", "#C8B09C", "#B49480", "#78544C", "#AC386C"
    )
    # asas de morcego abertas nas duas laterais com membrana vinho recortada e garrinha bege no topo
    asa = [
        (1.55, 0.05), (2.28, -0.95), (3.25, -0.25), (3.42, 0.28),
        (2.95, 0.32), (2.68, 0.72), (2.15, 0.42), (1.55, 0.58)
    ]
    s.sym(asa, 0.86, 0.96, roxo_e, outline=borda, ow=0.10, smooth=False)
    for p_mem in [
        [(1.75, 0.35), (2.12, 0.28), (1.98, -0.35), (1.72, -0.15)],
        [(2.18, 0.28), (2.58, 0.55), (2.32, -0.58), (2.08, -0.38)],
        [(2.62, 0.52), (3.18, 0.18), (2.52, -0.68), (2.38, -0.58)],
    ]:
        s.sym(p_mem, 1.83, 0.025, vinho, smooth=False)
    s.sym([(2.15, -0.78), (2.32, -1.22), (2.48, -0.75)], 1.83, 0.06, osso_cl, outline=borda, ow=0.04, smooth=False)
    # enormes chifres curvos cor de osso (#C8B09C + sombra #B49480 + borda #78544C) saindo do topo para trás
    for k in (-1, 1):
        X = lambda P: [(k*x, y) for x, y in P]
        chifre = _chaikin([
            (0.68, -0.58), (1.82, -0.58), (2.28, -1.25), (2.05, -2.25),
            (1.38, -3.12), (1.18, -2.98), (1.35, -2.05), (0.72, -1.18)
        ], 2)
        s.flat(X(chifre), 0.92, 1.12, osso_cl, outline=osso_b, ow=0.09, smooth=False)
        sombra_ch = _chaikin([(1.32, -0.65), (1.82, -0.65), (2.18, -1.28), (1.95, -2.18), (1.42, -2.85), (1.68, -1.65)], 2)
        s.flat(X(sombra_ch), 2.05, 0.02, osso_esc, smooth=False)
    # presas/placas curvas cor de osso nos cantos dianteiros + focinho roxo na frente com narinas
    presa_fr = _chaikin([(1.05, 1.88), (1.58, 1.82), (1.82, 1.25), (1.62, 0.95), (1.28, 1.18)], 2)
    s.sym(presa_fr, 0.90, 1.12, osso_cl, outline=osso_b, ow=0.07, smooth=False)
    s.flat(ellipse(0.0, 1.55, 0.85, 0.45, n=22), 0.86, 1.12, roxo, outline=borda, ow=0.09)
    s.sym(ellipse(0.35, 1.65, 0.11, 0.07, n=10, rot=-0.35), TOP + 0.015, 0.02, roxo_e)
    # sobrancelha roxo-escura em V + escama/brasão magenta (#AC386C) no centro da testa (assinatura da ref. 214)
    s.sym([(0.0, 0.48), (1.58, -0.18), (1.58, -0.35), (0.0, 0.28)], TOP + 0.01, 0.015, roxo_e, smooth=False)
    s.flat([(0.0, 0.05), (0.45, -0.45), (0.0, -0.82), (-0.45, -0.45)], TOP + 0.02, 0.025, mag, smooth=False)
    s.sym([(0.12, 0.08), (0.42, -0.22), (0.28, 0.18)], TOP + 0.02, 0.025, mag, smooth=False)
    # mão: 3 garras cor de osso na frente
    for kk in (-1, 0, 1):
        s.hand_flat(_espinho(kk*0.22, 0.35, math.radians(90 - 18*kk), 0.48, 0.11), 1.3, 0.40, osso_cl, outline=osso_b, ow=0.04, smooth=False)


LOTE = [
    ("rei_dourado", rei_dourado, "#F0CC00", "#C8A000", "#F0CC00", "#C8A000"),
    ("caramujo", caramujo, "#F8D890", "#AC705C", "#E4A880", "#AC705C"),
    ("monstro_noite", monstro_noite, "#283050", "#6864B4", "#283050", "#6864B4"),
    ("urso_pardo", urso_pardo, "#B05430", "#682820", "#B05430", "#682820"),
    ("canguru", canguru, "#D48038", "#9C4C24", "#D48038", "#9C4C24"),
    ("feneco", feneco, "#F0C470", "#C0945C", "#F0C470", "#C0945C"),
    ("peixe_abissal", peixe_abissal, "#184054", "#102438", "#184054", "#102438"),
    ("morcego_roxo", morcego_roxo, "#58488C", "#303458", "#58488C", "#303458"),
    ("batata", batata, "#B8803C", "#784C34", "#B8803C", "#784C34"),
    ("dragao_roxo", dragao_roxo, "#683480", "#30204C", "#683480", "#30204C"),
]
