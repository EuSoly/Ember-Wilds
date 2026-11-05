# Lote 2 — skins de corpo. Montar com build_skins.py (Blender aberto) ou render_lote.py (segundo plano).
from skin_lib import *


def _lobes(s, n, r, rx, ry, color, edge, z=0.4, thick=1.4, start=0.0):
    for i in range(n):
        a = 2*math.pi*i/n + start
        s.flat(ellipse(math.cos(a)*r, math.sin(a)*r, rx, ry, n=12, rot=a), z, thick, color, outline=edge, ow=0.08)

def abobora(s):
    # ref. 69: laranjas e marrom. Borda em gomos, sulcos saindo do talo, gavinha.
    s.base()
    lobe, groove, stem, ink = "#BF7532", "#A6692E", "#5A3A17", "#2C1E0F"
    _lobes(s, 10, 1.95, 0.62, 0.48, lobe, ink, start=math.radians(18))
    cy = -0.75
    for i in range(10):
        a = math.radians(i*36 + 18 + 90)
        x0, y0, x1, y1 = 0.35*math.cos(a), cy + 0.35*math.sin(a), 1.65*math.cos(a), cy + 1.5*math.sin(a)
        if y1 > 0.6: continue  # nada de sulco cruzando os olhos
        dx, dy = x1 - x0, y1 - y0; L = math.hypot(dx, dy); nx, ny = -dy/L*0.07, dx/L*0.07
        s.flat([(x0+nx, y0+ny), (x1, y1), (x0-nx, y0-ny)], TOP, T, groove, smooth=False)
    s.flat([(0.3*math.cos(math.radians(60*i+10)), cy + 0.3*math.sin(math.radians(60*i+10))) for i in range(6)], TOP, 0.2, stem, outline=ink, ow=0.05, smooth=False)
    s.flat(ellipse(0.03, cy + 0.02, 0.15, 0.12), TOP + 0.2, 0.03, ink)
    curl = [(0.3 + 0.32*(1 - t/14)*math.cos(t*0.6), cy - 0.5 + 0.32*(1 - t/14)*math.sin(t*0.6)) for t in range(15)]
    for i in range(len(curl) - 1):
        (xa, ya), (xb, yb) = curl[i], curl[i+1]
        dx, dy = xb - xa, yb - ya; L = math.hypot(dx, dy) or 1; nx, ny = -dy/L*0.045, dx/L*0.045
        s.flat([(xa+nx, ya+ny), (xb+nx, yb+ny), (xb-nx, yb-ny), (xa-nx, ya-ny)], TOP + 0.04, 0.03, stem, smooth=False)
    for i in range(7):
        a = 2*math.pi*i/7 + math.pi/2
        s.hand_flat(ellipse(0.42*math.cos(a), 0.42*math.sin(a), 0.3, 0.24, n=10, rot=a), 0.95, 0.9, lobe)
    s.hand_flat(ellipse(0, -0.05, 0.11, 0.09, n=6), 1.87, 0.07, stem, smooth=False)

def morcego(s):
    # ref. 31: roxos e bege. Asas dobradas nas costas com borda em pontas e varetas, orelhas em pé, presinhas.
    s.base()
    wing, bone, tan, body = "#68246D", "#361849", "#A37C5F", "#4D2764"
    for k in (-1, 1):
        pts = [(0.15, -0.1), (1.3, 0.15), (2.35, -0.3), (2.6, -1.2), (2.25, -2.0), (1.8, -1.7), (1.45, -2.4), (1.05, -2.0), (0.65, -2.5), (0.35, -2.05), (0.05, -2.35)]
        pts = [(k*x, y) for x, y in pts]
        s.flat(pts, 1.5, 0.62, wing, outline=bone, ow=0.09, smooth=False)
        for tx, ty in [(2.25, -2.0), (1.45, -2.4), (0.65, -2.5)]:
            dx, dy = k*tx*0.92 - k*0.35, ty*0.92; L = math.hypot(dx, dy); nx, ny = -dy/L*0.045, dx/L*0.045
            s.flat([(k*0.35+nx, ny), (k*tx*0.92, ty*0.92), (k*0.35-nx, -ny)], 2.13, 0.03, bone, smooth=False)
    ear = [(0.45, -0.2), (1.5, 0.1), (1.6, -1.25)]
    s.sym(ear, TOP + 0.13, 0.14, body, outline=bone, ow=0.07, smooth=False)
    s.sym([(0.8, -0.25), (1.35, -0.1), (1.42, -0.85)], TOP + 0.27, 0.02, tan, smooth=False)
    for k in (-1, 1):
        s.flat([(k*0.22 - 0.09, 1.35), (k*0.22 + 0.09, 1.35), (k*0.22, 1.05)], TOP, 0.04, "#F0E6DA", smooth=False)
    for k in (-1, 1):
        s.hand_flat([(k*0.2 - 0.09, 0.5), (k*0.2 + 0.09, 0.5), (k*0.2, 0.82)], 1.2, 0.08, tan, smooth=False)

def chama(s):
    # ref. 66: laranja, vermelho, amarelo. Rabo de fogo atrás, labaredas só na metade de trás, miolo em Neon.
    s.base()
    red, mid, org, yel = "#B2222A", "#D34C14", "#F8AC2E", "#FEE989"
    tail = [(-1.9, 0.4), (-2.2, -0.6), (-2.75, -1.55), (-1.75, -1.4), (-1.6, -2.65), (-0.75, -1.8), (0.0, -3.35), (0.75, -1.8), (1.6, -2.65), (1.75, -1.4), (2.75, -1.55), (2.2, -0.6), (1.9, 0.4)]
    s.flat(tail, 0.8, 1.06, mid, outline=red, ow=0.12)
    s.flat([(x*0.72, y*0.72 - 0.35) for x, y in tail], 0.85, 1.05, org)
    s.flat([(x*0.42, y*0.42 - 0.95) for x, y in tail], 0.9, 1.04, yel, emit=0.6)  # miolo do fogo em Neon
    for k in (-1, 1):
        s.flat([(k*1.85, 1.0), (k*2.5, 0.7), (k*2.2, 0.45), (k*2.6, 0.05), (k*1.85, -0.1)], 0.8, 1.06, mid, outline=red, ow=0.08, smooth=False)
    # labaredas só na faixa de trás (zigue-zague perto dos olhos vira boca com dentes de cima)
    # metade de trás um tom mais escura, borda ondulada e macia (pontas em fileira viram dentes de cima)
    back = [(-1.7, -0.5), (-1.1, -0.75), (-0.55, -0.45), (0.0, -0.8), (0.55, -0.45), (1.1, -0.75), (1.7, -0.5), (1.55, -1.75), (-1.55, -1.75)]
    s.flat(back, TOP, T, mid)
    s.hand_flat([(-0.5, 0.1), (-0.35, -0.6), (0.0, -1.05), (0.35, -0.6), (0.5, 0.1)], 1.0, 0.8, org)
    s.hand_flat(ellipse(0, -0.05, 0.28, 0.24), 1.86, 0.03, yel, emit=0.6)

def estrela(s):
    # ref. 57: azuis-claros com branco. Cinco braços saindo de baixo do corpo, fileiras de bolinhas.
    s.base()
    mid, ink, white, light = "#79B2D7", "#50839E", "#F0F8FC", "#8CE7F9"
    for i in range(5):
        a = math.radians(90 + 36 + 72*i)  # nenhum braço reto para a frente (olhos)
        tip = (math.cos(a)*3.15, math.sin(a)*3.15)
        b1 = (math.cos(a + 0.42)*1.5, math.sin(a + 0.42)*1.5); b2 = (math.cos(a - 0.42)*1.5, math.sin(a - 0.42)*1.5)
        m1 = (math.cos(a + 0.16)*2.45, math.sin(a + 0.16)*2.45); m2 = (math.cos(a - 0.16)*2.45, math.sin(a - 0.16)*2.45)
        s.flat([b1, m1, tip, m2, b2], 0.85, 1.05, mid, outline=ink, ow=0.09)
        for r in (2.15, 2.55, 2.9):
            s.flat(ellipse(math.cos(a)*r, math.sin(a)*r, 0.09, 0.09, n=8), 1.91, 0.03, white)
    for x, y in [(-0.9, -0.5), (0.9, -0.5), (0.0, -1.0), (-0.45, -1.35), (0.45, -1.35), (-1.3, -1.2), (1.3, -1.2)]:
        s.flat(ellipse(x, y, 0.1, 0.1, n=8), TOP, 0.03, white)
    s.flat(ellipse(0, -0.2, 0.32, 0.32, n=5), TOP, 0.03, light, smooth=False)
    for i in range(5):
        a = math.radians(90 + 72*i)
        s.hand_flat([(math.cos(a - 0.5)*0.35, math.sin(a - 0.5)*0.35), (math.cos(a)*0.95, math.sin(a)*0.95), (math.cos(a + 0.5)*0.35, math.sin(a + 0.5)*0.35)], 1.0, 0.75, mid, outline=ink, ow=0.05, smooth=False)

def concha(s):
    # ref. 60: lilases. Leque de concha atrás do corpo com gomos e borda ondulada, pérola.
    s.base()
    light, mid, ink, pearl = "#EDBEF4", "#CE90D7", "#5E324E", "#FBFBFB"
    fan = []
    for i in range(15):
        a = math.radians(200 + 140*i/14)
        r = 3.05 + (0.18 if i % 2 else 0.0)
        fan.append((math.cos(a)*r*1.05, math.sin(a)*r*0.95 + 0.35))
    fan += [(1.7, 0.5), (-1.7, 0.5)]
    s.flat(fan, 0.8, 1.05, light, outline=ink, ow=0.1)
    for i in range(8):
        a = math.radians(206 + 128*i/7)
        x1, y1 = math.cos(a)*3.0, math.sin(a)*2.85 + 0.35
        dx, dy = x1, y1 - 0.35; L = math.hypot(dx, dy); nx, ny = -dy/L*0.06, dx/L*0.06
        s.flat([(nx*0.5, 0.35 + ny*0.5), (x1 + nx, y1 + ny), (x1 - nx, y1 - ny), (-nx*0.5, 0.35 - ny*0.5)], 1.86, 0.03, mid, smooth=False)
    for k in (-1, 1):
        s.flat([(k*1.7, 1.2), (k*2.35, 1.25), (k*2.3, 0.75), (k*1.75, 0.65)], 0.8, 1.06, mid, outline=ink, ow=0.07)
    for i in range(6):
        y = -0.35 - 0.25*i
        s.flat([(-1.5, y + 0.05), (1.5, y + 0.05), (1.5, y - 0.05), (-1.5, y - 0.05)], TOP, 0.025, mid, smooth=False)
    s.flat(ellipse(0, -1.25, 0.32, 0.32, n=14), TOP + 0.03, 0.18, pearl, outline="#C9B8D0", ow=0.04)
    pts = []
    for i in range(9):
        a = math.radians(20 + 140*i/8)
        r = 0.72 + (0.07 if i % 2 else 0)
        pts.append((math.cos(a)*r, math.sin(a)*r - 0.35))
    s.hand_flat(pts, 1.85, 0.04, light, outline=ink, ow=0.04)

def aranha(s):
    # ref. 68: preto e vermelhos. Oito patas em ângulo, ampulheta vermelha nas costas.
    s.base()
    leg, red, dark, light = "#1A0E0E", "#B0242A", "#621418", "#E6CCCD"
    for i, (y, out_ang) in enumerate([(0.9, 0.55), (0.25, 0.15), (-0.4, -0.2), (-1.05, -0.6)]):
        for k in (-1, 1):
            knee = (k*2.55, y + 0.35 + out_ang*0.5)
            foot = (k*3.05, y - 0.5 + out_ang*1.2)
            w = 0.11
            pts = [(k*1.6, y + w), (knee[0], knee[1] + w), (foot[0] + k*0.05, foot[1]), (knee[0] - k*0.1, knee[1] - w), (k*1.6, y - w)]
            s.flat(pts, 0.8, 1.05, leg, outline=dark, ow=0.06, smooth=False)
            s.flat(ellipse(knee[0], knee[1], 0.12, 0.12, n=8), 1.86, 0.03, red)
    s.flat([(-0.45, -0.45), (0.45, -0.45), (0.0, -0.95)], TOP, T, red, outline=dark, ow=0.05, smooth=False)
    s.flat([(-0.45, -1.5), (0.45, -1.5), (0.0, -1.0)], TOP, T, red, outline=dark, ow=0.05, smooth=False)
    for k in (-1, 1):
        s.flat(ellipse(k*0.35, 1.2, 0.1, 0.1, n=8), TOP, 0.04, red)
        s.flat([(k*0.18 - 0.08, 1.75), (k*0.18 + 0.08, 1.75), (k*0.18, 1.45)], TOP, 0.04, light, smooth=False)
    s.hand_flat(ellipse(0, 0.35, 0.25, 0.2, n=10), 1.84, 0.04, red)

def cervo(s):
    # ref. 129: marrons e bege. Galhada saindo das laterais de trás, orelhas, pintas claras, focinho.
    s.base()
    dark, ink, light, antler = "#773E24", "#362B1E", "#B89A69", "#E2D2B0"
    for k in (-1, 1):
        def bar(x0, y0, x1, y1, w):
            dx, dy = x1 - x0, y1 - y0; L = math.hypot(dx, dy); nx, ny = -dy/L*w, dx/L*w
            return [(k*(x0+nx), y0+ny), (k*(x1+nx*0.5), y1+ny*0.5), (k*(x1-nx*0.5), y1-ny*0.5), (k*(x0-nx), y0-ny)]
        main = [(0.9, -0.5), (1.9, -0.8), (2.6, -1.4), (3.0, -2.2)]
        for (x0, y0), (x1, y1) in zip(main, main[1:]):
            s.flat(bar(x0, y0, x1, y1, 0.14), TOP + 0.02, 0.1, antler, outline=ink, ow=0.05, smooth=False)
        for (x0, y0, x1, y1) in [(1.9, -0.8, 2.5, -0.1), (2.6, -1.4, 3.3, -1.05), (2.25, -1.1, 2.15, -1.9)]:
            s.flat(bar(x0, y0, x1, y1, 0.1), TOP + 0.02, 0.1, antler, outline=ink, ow=0.05, smooth=False)
        s.flat([(k*1.6, 0.6), (k*2.5, 0.75), (k*2.45, 0.2), (k*1.7, 0.05)], 0.9, 1.0, "#9E793D", outline=ink, ow=0.08)
        s.flat([(k*1.85, 0.48), (k*2.3, 0.55), (k*2.25, 0.3), (k*1.9, 0.25)], 1.91, 0.02, light)
    for x, y in [(-1.0, -0.9), (-0.4, -1.3), (0.3, -1.0), (0.95, -1.35), (-1.3, -1.45), (0.0, -0.6), (1.2, -0.75)]:
        s.flat(ellipse(x, y, 0.13, 0.1, n=8), TOP, 0.03, light)
    s.flat(ellipse(0, 1.35, 0.8, 0.38), TOP, T, light)
    s.flat(ellipse(0, 1.55, 0.25, 0.15), TOP + T, 0.04, ink)
    s.hand_flat([(-0.06, 0.62), (0.06, 0.62), (0.04, 0.0), (-0.04, 0.0)], 1.85, 0.03, ink, smooth=False)

def axolote(s):
    # ref. 148: rosas e lilás. Três brânquias franjadas de cada lado, rabo com barbatana, pintinhas.
    s.base()
    frill, ink, light, dark = "#E893D7", "#8F5D8C", "#F1C9E2", "#D986D2"
    for k in (-1, 1):
        for j, (ang, L) in enumerate([(0.55, 1.35), (0.05, 1.5), (-0.45, 1.35)]):
            base = (k*1.75, 0.35 + 0.45*(1 - j))
            tip = (base[0] + k*L*math.cos(ang), base[1] + L*math.sin(ang))
            dx, dy = tip[0] - base[0], tip[1] - base[1]; Ln = math.hypot(dx, dy); nx, ny = -dy/Ln, dx/Ln
            pts = [(base[0] + nx*0.16, base[1] + ny*0.16)]
            for t in (0.3, 0.55, 0.8):
                px, py = base[0] + dx*t, base[1] + dy*t
                pts.append((px + nx*0.32, py + ny*0.32)); pts.append((px + dx*0.08 + nx*0.12, py + dy*0.08 + ny*0.12))
            pts.append(tip)
            for t in (0.8, 0.55, 0.3):
                px, py = base[0] + dx*t, base[1] + dy*t
                pts.append((px + dx*0.08 - nx*0.12, py + dy*0.08 - ny*0.12)); pts.append((px - nx*0.32, py - ny*0.32))
            pts.append((base[0] - nx*0.16, base[1] - ny*0.16))
            s.flat(pts, 0.9, 1.0, frill, outline=ink, ow=0.06, smooth=False)
    s.flat([(-0.4, -1.6), (-0.7, -2.4), (-0.35, -3.3), (0.0, -3.6), (0.35, -3.3), (0.7, -2.4), (0.4, -1.6)], 0.85, 1.0, light, outline=ink)
    s.flat([(-0.15, -1.8), (0.15, -1.8), (0.1, -3.1), (-0.1, -3.1)], 1.86, 0.03, dark, smooth=False)
    for x, y, r in [(-1.0, -0.8, 0.12), (0.8, -1.2, 0.1), (0.2, -0.6, 0.09), (-0.3, -1.35, 0.1), (1.25, -0.5, 0.08)]:
        s.flat(ellipse(x, y, r, r, n=8), TOP, 0.03, dark)
    s.flat([(-0.3, 1.3), (-0.1, 1.2), (0.1, 1.2), (0.3, 1.3), (0.1, 1.25), (-0.1, 1.25)], TOP, 0.03, ink, smooth=False)
    for k in (-1.5, -0.5, 0.5, 1.5):
        s.hand_flat(ellipse(k*0.2, 0.62, 0.09, 0.14, n=8), 1.15, 0.12, light)

def ourico(s):
    # ref. 76: verdes e cinzas. Espinhos em camadas cobrindo as costas e passando da borda; rosto liso.
    s.base()
    spike, spike2, ink, dark = "#D6D7D6", "#A4B3AE", "#133024", "#28634A"
    for row, (r, n, col) in enumerate([(2.25, 13, spike2), (1.95, 13, spike)]):
        for i in range(n):
            a = math.radians(-20 - 140*i/(n - 1)) if True else 0
            a += math.radians(5)*(row % 2)
            bx, by = math.cos(a)*1.3, math.sin(a)*1.3 - 0.1
            tx, ty = math.cos(a)*(r + 0.9), math.sin(a)*(r + 0.9) - 0.1
            w = 0.26
            s.flat([(bx - math.sin(a)*w, by + math.cos(a)*w), (tx, ty), (bx + math.sin(a)*w, by - math.cos(a)*w)], 0.9 + 0.05*row, 1.0, col, outline=ink, ow=0.05, smooth=False)
    # sem espinhos no topo (de cima viravam dentes); a silhueta já diz "ouriço"
    s.flat([(-1.6, -0.4), (-0.8, -0.65), (0.0, -0.45), (0.8, -0.65), (1.6, -0.4), (1.5, -1.75), (-1.5, -1.75)], TOP, T, dark)
    s.flat(ellipse(0, 1.5, 0.2, 0.13), TOP, 0.04, ink)
    for k in (-1, 0, 1):
        a = math.radians(-90 + 40*k)
        s.hand_flat([(math.cos(a + 1.3)*0.3, math.sin(a + 1.3)*0.3), (math.cos(a)*0.95, math.sin(a)*0.95), (math.cos(a - 1.3)*0.3, math.sin(a - 1.3)*0.3)], 1.0, 0.75, spike, outline=ink, ow=0.04, smooth=False)

def morango(s):
    # ref. 93: vermelhos e verdes. Coroa de folhas na borda de trás, sementes em gota, cabinho.
    s.base()
    green, light, dark, seed = "#119A63", "#52B675", "#852327", "#B12F30"
    for i in range(7):
        a = math.radians(-90 + (i - 3)*28)
        tip = (math.cos(a)*1.55, -1.85 + math.sin(a)*1.35)  # coroa quase toda para fora da borda de trás
        base = (0.0, -1.6)
        dx, dy = tip[0] - base[0], tip[1] - base[1]; L = math.hypot(dx, dy); nx, ny = -dy/L, dx/L
        pts = [(base[0] + nx*0.22, base[1] + ny*0.22), ((base[0]+tip[0])/2 + nx*0.32, (base[1]+tip[1])/2 + ny*0.32), tip, ((base[0]+tip[0])/2 - nx*0.32, (base[1]+tip[1])/2 - ny*0.32), (base[0] - nx*0.22, base[1] - ny*0.22)]
        s.flat(pts, TOP + 0.01*(i % 2), 0.08, green if i % 2 else light, outline="#0B5A3A", ow=0.06)
    s.flat(ellipse(0, -1.6, 0.13, 0.13, n=8), TOP + 0.1, 0.25, "#0B5A3A")
    for x, y in [(-1.2, 0.95), (1.2, 0.95), (-1.35, 0.15), (1.35, 0.15), (-0.9, -0.25), (0.9, -0.25), (0.0, 0.05), (-0.45, -0.5), (0.45, -0.5), (-1.45, -0.6), (1.45, -0.6), (0.0, 1.45)]:
        s.flat([(x - 0.07, y + 0.08), (x + 0.07, y + 0.08), (x, y - 0.12)], TOP, 0.03, "#F6D6A0")
    for k in (-1, 1):
        s.flat([(k*1.8, -0.6), (k*2.25, -0.95), (k*2.0, -1.35), (k*1.7, -1.15)], 0.9, 1.0, green, outline="#0B5A3A", ow=0.06)
    for i in range(4):
        a = math.radians(-90 + (i - 1.5)*45)
        s.hand_flat([(0, -0.35), (math.cos(a)*0.55, math.sin(a)*0.55 - 0.1), (math.cos(a + 0.3)*0.3, math.sin(a + 0.3)*0.3 - 0.2)], 1.84, 0.05, green, smooth=False)


LOTE = [
    ("abobora", abobora, "#D17F34", "#2C1E0F", "#D17F34", "#2C1E0F"),
    ("morcego", morcego, "#4D2764", "#361849", "#502C6D", "#361849"),
    ("chama", chama, "#F17500", "#B2222A", "#B2222A", "#9D1E25"),
    ("estrela", estrela, "#84CFEC", "#50839E", "#78AFD4", "#50839E"),
    ("concha", concha, "#E6A4ED", "#5E324E", "#E6A4ED", "#5E324E"),
    ("aranha", aranha, "#1A0E0E", "#621418", "#1A0E0E", "#621418"),
    ("cervo", cervo, "#9E793D", "#362B1E", "#9E793D", "#362B1E"),
    ("axolote", axolote, "#EEB7DC", "#8F5D8C", "#EEC2DC", "#8F5D8C"),
    ("ourico", ourico, "#33956D", "#133024", "#CED0D0", "#2E5D4C"),
    ("morango", morango, "#E23D43", "#852327", "#E84C47", "#852327"),
]
