# Lote 16 — 10 skins de corpo temáticas (misturando detalhes 3D leves e texturas ricas,
# com expressões ferozes nos monstros/demônios conforme direção de arte).
from skin_lib import *


def _chaikin(poly, passes=2):
    for _ in range(passes):
        poly = [
            p for a, b in zip(poly, poly[1:] + poly[:1])
            for p in ((0.75 * a[0] + 0.25 * b[0], 0.75 * a[1] + 0.25 * b[1]),
                      (0.25 * a[0] + 0.75 * b[0], 0.25 * a[1] + 0.75 * b[1]))
        ]
    return poly


def _extensao_sem_costura(s, pts, cor, outline, ow=0.09, z_base=0.68, z_cap_top=2.008, smooth=False):
    """Extensão da silhueta do corpo sem linha de costura no topo (cap termina em 2.008)."""
    s.flat(pts, z_base, 1.78 - z_base, cor, outline=outline, ow=ow, smooth=smooth)
    s.flat(pts, 1.78, z_cap_top - 1.78, cor, outline=None, smooth=smooth)


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


# ---------------------------------------------------------------- 1. Bloco de Perigo / Cibernético (ref. 6)
def bloco_perigo(s):
    s.base()
    amarelo_es, aco, aco_cl, aco_borda = "#DC9000", "#585860", "#A4A4AC", "#28282C"
    preto, luz = "#201C20", "#FFF048"

    # Painel interno rebaixado amarelo-escuro na metade traseira
    s.flat(_chaikin([
        (-1.22, -0.18), (1.22, -0.18), (1.22, -1.28), (-1.22, -1.28)
    ], 1), TOP, 0.006, amarelo_es, smooth=False)

    # 4 cantoneiras blindadas de aço cinza nos 4 cantos do corpo + rebites claros
    cantoneira_tras = [(0.72, -1.56), (1.56, -1.56), (1.56, -0.72), (1.18, -0.72), (0.72, -1.18)]
    cantoneira_frente = [(0.88, 1.56), (1.56, 1.56), (1.56, 0.88), (1.22, 0.88), (0.88, 1.22)]
    s.sym(cantoneira_tras, TOP + 0.008, 0.016, aco, outline=aco_borda, ow=0.03, smooth=False)
    s.sym(cantoneira_frente, TOP + 0.008, 0.016, aco, outline=aco_borda, ow=0.03, smooth=False)
    s.sym([(0.88, -1.46), (1.46, -1.46), (1.46, -0.88), (1.22, -0.88), (0.88, -1.22)],
          TOP + 0.025, 0.008, aco_cl, smooth=False)
    s.sym([(1.00, 1.46), (1.46, 1.46), (1.46, 1.00), (1.25, 1.00), (1.00, 1.25)],
          TOP + 0.025, 0.008, aco_cl, smooth=False)

    # Faixas diagonais de perigo (preto sobre amarelo) nas laterais
    for y0 in (-0.52, -0.05, 0.42):
        faixa_p = [(1.26, y0), (1.55, y0 + 0.22), (1.55, y0 + 0.40), (1.26, y0 + 0.18)]
        s.sym(faixa_p, TOP + 0.008, 0.012, preto, smooth=False)

    # Núcleo energético / farol industrial no centro-traseiro com grade metálica
    s.flat(_chaikin([(-0.62, -0.38), (0.62, -0.38), (0.62, -1.12), (-0.62, -1.12)], 1),
           TOP + 0.010, 0.016, aco, outline=aco_borda, ow=0.03, smooth=False)
    for xx in (-0.34, 0.0, 0.34):
        s.flat([(xx - 0.10, -0.50), (xx + 0.10, -0.50), (xx + 0.10, -1.00), (xx - 0.10, -1.00)],
               TOP + 0.028, 0.012, luz, emit=0.9, smooth=False)

    # Sobrancelhas angulares metálicas dando expressão feroz/robótica (\ / na câmera 65°!)
    s.sym([
        (0.35, 0.38), (0.75, 0.14), (1.35, -0.10),
        (1.42, 0.08), (0.78, 0.32), (0.35, 0.54)
    ], TOP + 0.012, 0.016, aco, outline=aco_borda, ow=0.025, smooth=False)

    s.hand_flat([(-0.30, -0.14), (0.30, -0.14), (0.30, 0.14), (-0.30, 0.14)],
                1.83, 0.018, aco, outline=aco_borda, ow=0.025, smooth=False)
    s.hand_flat(ellipse(0.0, 0.0, 0.12, 0.12, n=10), 1.85, 0.014, luz, emit=0.8)


# ---------------------------------------------------------------- 2. Oni Vermelho / Máscara Hannya (ref. 23)
def oni_vermelho(s):
    # Máscara japonesa Oni / Hannya tradicional:
    # Maçãs do rosto esculpidas nas laterais, cordão preto de máscara amarrado nas têmporas,
    # 2 chifres curvos de marfim/ouro com anéis na base, rugas tradicionais de Hannya na testa,
    # nariz esculpido, boca rasgada de máscara Hannya com lábios dourados e presas afiadas,
    # pintura facial Kumadori, aros dourados nos olhos e sobrancelhas orientais (\ /)!
    s.base()
    pele_sombra, borda = "#8C1E18", "#480C08"
    pintura_branca, chifre_cor, ouro = "#F4ECE4", "#EFE4CC", "#E0A828"
    cordao = "#1C1414"

    # Maçãs do rosto salientes da máscara Hannya nas laterais + cordão preto da máscara
    for sx in (-1, 1):
        bochecha_hannya = _chaikin([
            (sx * 1.42, 1.18), (sx * 1.96, 0.72), (sx * 1.92, 0.08), (sx * 1.42, -0.25)
        ], 2)
        _extensao_sem_costura(s, bochecha_hannya, "#C84440", borda, ow=0.08)
        # Laço do cordão preto da máscara japonesa nas laterais
        laco = _chaikin([
            (sx * 1.48, -0.22), (sx * 2.02, -0.42), (sx * 1.98, -0.78), (sx * 1.48, -0.62)
        ], 1)
        _extensao_sem_costura(s, laco, cordao, borda, ow=0.06)

    # 2 chifres longos e curvos de máscara Oni/Hannya saindo da testa traseira (-Y) com anéis dourados e escuros
    for sx in (-1, 1):
        chifre = _chaikin([
            (sx * 0.72, -1.28), (sx * 1.38, -2.48), (sx * 2.05, -2.18),
            (sx * 1.88, -1.42), (sx * 1.35, -0.88)
        ], 2)
        _extensao_sem_costura(s, chifre, chifre_cor, borda, ow=0.09)
    # Base dourada e estrias escuras nos chifres
    s.sym(_chaikin([(0.72, -1.18), (1.28, -1.55), (1.52, -1.28), (1.18, -0.88)], 1),
          TOP + 0.010, 0.016, ouro, outline=borda, ow=0.025, smooth=False)
    s.sym(_chaikin([(1.05, -1.62), (1.55, -1.92), (1.72, -1.68), (1.35, -1.35)], 1),
          TOP + 0.012, 0.014, borda, smooth=False)

    # Boca rasgada tradicional de máscara Hannya na frente (+Y) com cavidade escura, borda dourada e presas!
    boca_hannya = _chaikin([
        (-1.08, 1.18), (-0.55, 1.26), (0.0, 1.28), (0.55, 1.26), (1.08, 1.18),
        (0.95, 1.54), (0.0, 1.56), (-0.95, 1.54)
    ], 2)
    s.flat(boca_hannya, TOP + 0.008, 0.012, cordao, outline=ouro, ow=0.028, smooth=False)
    # Dentes internos e 2 grandes presas laterais de Hannya projetadas para fora da silhueta (+Y)
    for dx in (-0.42, -0.14, 0.14, 0.42):
        s.flat([(dx - 0.08, 1.28), (dx + 0.08, 1.28), (dx + 0.05, 1.48), (dx - 0.05, 1.48)],
               TOP + 0.021, 0.010, pintura_branca, smooth=False)
    for sx in (-1, 1):
        presa_g = _chaikin([(sx * 0.68, 1.32), (sx * 0.92, 2.12), (sx * 1.18, 1.32)], 1)
        _extensao_sem_costura(s, presa_g, pintura_branca, borda, ow=0.07)

    # Nariz esculpido de máscara Hannya entre os olhos com narinas escuras
    s.flat(_chaikin([(-0.16, 0.58), (0.16, 0.58), (0.26, 0.98), (0.0, 1.08), (-0.26, 0.98)], 1),
           TOP + 0.010, 0.014, pele_sombra, outline=borda, ow=0.02, smooth=False)
    s.sym(ellipse(0.11, 0.96, 0.06, 0.04, n=8), TOP + 0.025, 0.008, cordao)

    # Rugas esculpidas tradicionais de máscara Hannya na testa + terceiro olho/emblema dourado central
    for ry, w_r in [(-1.32, 0.52), (-1.06, 0.68), (-0.80, 0.46)]:
        ruga = _chaikin([
            (-w_r, ry - 0.06), (0.0, ry + 0.08), (w_r, ry - 0.06),
            (w_r, ry - 0.16), (0.0, ry - 0.02), (-w_r, ry - 0.16)
        ], 2)
        s.flat(ruga, TOP + 0.008, 0.010, pele_sombra, smooth=False)
    s.flat([(0.0, -0.25), (0.16, -0.48), (0.0, -0.70), (-0.16, -0.48)],
           TOP + 0.010, 0.014, ouro, outline=borda, ow=0.025, smooth=False)

    # Pintura facial japonesa Kumadori (faixas curvas brancas e carmesim-escuras contornando as maçãs do rosto)
    s.sym(_chaikin([
        (1.18, 1.15), (1.76, 0.72), (1.72, 0.15), (1.28, -0.15),
        (1.12, 0.05), (1.48, 0.32), (1.52, 0.68), (1.08, 1.02)
    ], 2), TOP + 0.008, 0.012, pintura_branca, outline=pele_sombra, ow=0.02, smooth=False)

    # Aros dourados metálicos de máscara Hannya ao redor dos olhos
    for k in (-1, 1):
        _anel_quads(s, k * EYE_X, EYE_Y, 0.46, 0.58, TOP + 0.010, 0.012, ouro, n=16)

    # Sobrancelhas grossas de máscara japonesa com voluta/curva interna e ponta furiosa (\ / na câmera 65°!)
    sob_hannya = _chaikin([
        (0.28, 0.52), (0.34, 0.32), (0.75, 0.08), (1.42, -0.22),
        (1.52, 0.04), (0.82, 0.32), (0.42, 0.62)
    ], 2)
    s.sym(sob_hannya, TOP + 0.016, 0.022, borda, outline=ouro, ow=0.025, smooth=False)

    # Garras douradas/marfim afiadas nas mãos
    for gx, gy in [(-0.18, 0.26), (0.0, 0.30), (0.18, 0.26)]:
        s.hand_flat([(gx - 0.06, gy - 0.12), (gx, gy + 0.14), (gx + 0.06, gy - 0.12)],
                    1.83, 0.018, chifre_cor, outline=borda, ow=0.02, smooth=False)


# ---------------------------------------------------------------- 3. Runa Sombria / Obsidiana Rubra (ref. 48)
def runa_sombria(s):
    # Guardião de obsidiana negra gravado com múltiplos símbolos rúnicos arcanos incandescentes:
    # Círculo ritual rúnico no centro-traseiro com grande Bind-Rune, 4 runas nórdicas/arcanas nas laterais e cantos,
    # runa Tiwaz frontal entre os olhos e trilhas de energia ligando os glifos!
    s.base()
    rubro, rubro_vivo, branco = "#980008", "#FF1824", "#FFF0F0"

    def _traco_runa(x0, y0, x1, y1, w=0.052, z=TOP + 0.018, cor=rubro_vivo, em=1.1):
        dx, dy = x1 - x0, y1 - y0
        L = math.hypot(dx, dy) or 1.0
        nx, ny = -dy / L * w, dx / L * w
        pts = [(x0 + nx, y0 + ny), (x1 + nx, y1 + ny), (x1 - nx, y1 - ny), (x0 - nx, y0 - ny)]
        s.flat(pts, z, 0.012, cor, emit=em, smooth=False)

    # Espinhos angulares de obsidiana saindo nos cantos traseiros
    for sx in (-1, 1):
        esp_obs = [(sx * 0.95, -1.42), (sx * 1.68, -2.02), (sx * 1.92, -1.35), (sx * 1.42, -0.95)]
        _extensao_sem_costura(s, esp_obs, "#201C20", rubro, ow=0.08)

    # Moldura chanfrada de obsidiana nos cantos
    s.sym([(0.92, 1.55), (1.55, 1.55), (1.55, 0.92), (1.28, 1.28)], TOP, 0.010, rubro, smooth=False)
    s.sym([(0.82, -1.55), (1.55, -1.55), (1.55, -0.82), (1.22, -1.22)], TOP, 0.010, rubro, smooth=False)

    # Círculo rúnico duplo gravado no centro-traseiro (0.0, -0.78) com marcas rúnicas radiais
    cx, cy = 0.0, -0.78
    _anel_quads(s, cx, cy, 0.56, 0.66, TOP + 0.008, 0.010, rubro, n=12)
    _anel_quads(s, cx, cy, 0.59, 0.63, TOP + 0.019, 0.008, rubro_vivo, n=12)
    for i in range(8):
        ang = i * (math.pi / 4.0)
        ca, sa = math.cos(ang), math.sin(ang)
        _traco_runa(cx + ca * 0.64, cy + sa * 0.64, cx + ca * 0.78, cy + sa * 0.78, w=0.032, z=TOP + 0.016, cor=rubro, em=0.8)

    # GRANDE SÍMBOLO RÚNICO CENTRAL (Bind-rune arcana: haste central + losango + braços angulares + núcleo branco)
    _traco_runa(cx, cy - 0.50, cx, cy + 0.50, w=0.055, z=TOP + 0.022, cor=rubro_vivo, em=1.2)
    _traco_runa(cx, cy + 0.42, cx - 0.32, cy + 0.14, w=0.048, z=TOP + 0.022, cor=rubro_vivo, em=1.2)
    _traco_runa(cx, cy + 0.42, cx + 0.32, cy + 0.14, w=0.048, z=TOP + 0.022, cor=rubro_vivo, em=1.2)
    _traco_runa(cx - 0.32, cy + 0.14, cx, cy - 0.14, w=0.048, z=TOP + 0.022, cor=rubro_vivo, em=1.2)
    _traco_runa(cx + 0.32, cy + 0.14, cx, cy - 0.14, w=0.048, z=TOP + 0.022, cor=rubro_vivo, em=1.2)
    _traco_runa(cx - 0.28, cy - 0.32, cx + 0.28, cy - 0.02, w=0.045, z=TOP + 0.022, cor=rubro_vivo, em=1.2)
    _traco_runa(cx + 0.28, cy - 0.32, cx - 0.28, cy - 0.02, w=0.045, z=TOP + 0.022, cor=rubro_vivo, em=1.2)
    s.flat([(cx, cy + 0.15), (cx + 0.11, cy), (cx, cy - 0.15), (cx - 0.11, cy)],
           TOP + 0.035, 0.010, branco, emit=1.5, smooth=False)

    # 4 SÍMBOLOS RÚNICOS LATERAIS E TRASEIROS:
    # 1. Esquerda-meio (-X): Runa Fehu / Ansuz
    _traco_runa(-1.28, -0.68, -1.28, 0.05, w=0.045)
    _traco_runa(-1.28, 0.02, -0.95, -0.18, w=0.042)
    _traco_runa(-1.28, -0.28, -0.95, -0.48, w=0.042)
    _traco_runa(-1.45, -0.32, -1.12, -0.12, w=0.038)

    # 2. Direita-meio (+X): Runa Sowilo / Eihwaz
    _traco_runa(1.28, -0.68, 1.02, -0.38, w=0.045)
    _traco_runa(1.02, -0.38, 1.38, -0.22, w=0.045)
    _traco_runa(1.38, -0.22, 1.05, 0.05, w=0.045)
    _traco_runa(1.05, 0.05, 1.42, -0.02, w=0.040)

    # 3. Canto traseiro esquerdo: Runa Algiz (tridente rúnico)
    _traco_runa(-1.12, -1.42, -1.12, -0.88, w=0.042)
    _traco_runa(-1.12, -1.12, -1.36, -0.88, w=0.038)
    _traco_runa(-1.12, -1.12, -0.88, -0.88, w=0.038)

    # 4. Canto traseiro direito: Runa Berkano (B rúnico angular)
    _traco_runa(1.12, -1.42, 1.12, -0.88, w=0.042)
    _traco_runa(1.12, -0.88, 1.36, -1.02, w=0.038)
    _traco_runa(1.36, -1.02, 1.12, -1.15, w=0.038)
    _traco_runa(1.12, -1.15, 1.36, -1.28, w=0.038)
    _traco_runa(1.36, -1.28, 1.12, -1.42, w=0.038)

    # Símbolo rúnico frontal entre os olhos (Runa Othala / losango com hastes cruzadas)
    _traco_runa(0.0, 1.46, -0.24, 1.22, w=0.042)
    _traco_runa(0.0, 1.46, 0.24, 1.22, w=0.042)
    _traco_runa(-0.24, 1.22, 0.16, 0.92, w=0.042)
    _traco_runa(0.24, 1.22, -0.16, 0.92, w=0.042)

    # Sobrancelhas angulares carmesim brilhantes FURIOSAS (\ / na câmera 65°!)
    s.sym([
        (0.35, 0.38), (0.75, 0.12), (1.38, -0.14),
        (1.45, 0.06), (0.78, 0.30), (0.35, 0.55)
    ], TOP + 0.014, 0.016, rubro_vivo, outline="#580004", ow=0.025, emit=0.9, smooth=False)

    # Símbolo rúnico gravado nas mãos
    s.hand_flat([(-0.04, -0.24), (0.04, -0.24), (0.04, 0.24), (-0.04, 0.24)],
                1.83, 0.016, rubro_vivo, emit=1.1, smooth=False)
    s.hand_flat([(-0.18, 0.04), (0.0, 0.22), (0.18, 0.04), (0.12, -0.02), (0.0, 0.12), (-0.12, -0.02)],
                1.84, 0.016, branco, emit=1.3, smooth=False)


# ---------------------------------------------------------------- 4. Raízes Carmesim / Monstro de Raízes (ref. 75)
def raizes_carmesim(s):
    # Criatura feita de raízes orgânicas retorcidas que se ramificam e afilam até as pontas:
    # Função _ramo_raiz gera raízes orgânicas que começam grossas na base e se bifurcam em radículas
    # pontiagudas, contornando e se entrelaçando sobre fendas escuras de seiva carmesim!
    s.base()
    fundo_escuro, raiz_escura, raiz_media, raiz_clara = "#280404", "#5C1010", "#8C2020", "#C84034"
    seiva_viva = "#FF3020"

    def _ramo_raiz(pts_eixo, w_ini, w_fim, z_r, cor_r, ow_r=0.028):
        """Gera um ramo de raiz orgânico que afila gradualmente da base (w_ini) até a ponta (w_fim)."""
        esq, dir_p = [], []
        n_pts = len(pts_eixo)
        for i, (x, y) in enumerate(pts_eixo):
            t = i / max(1, n_pts - 1)
            w = w_ini * (1.0 - t) + w_fim * t
            if i == 0:
                dx, dy = pts_eixo[1][0] - x, pts_eixo[1][1] - y
            elif i == n_pts - 1:
                dx, dy = x - pts_eixo[i - 1][0], y - pts_eixo[i - 1][1]
            else:
                dx, dy = pts_eixo[i + 1][0] - pts_eixo[i - 1][0], pts_eixo[i + 1][1] - pts_eixo[i - 1][1]
            L = math.hypot(dx, dy) or 1.0
            nx, ny = -dy / L * w, dx / L * w
            esq.append((x + nx, y + ny))
            dir_p.append((x - nx, y - ny))
        poligono = _chaikin(esq + list(reversed(dir_p)), 2)
        s.flat(poligono, z_r, 0.010, cor_r, outline=fundo_escuro, ow=ow_r, smooth=False)

    # Grandes raízes bifurcadas e retorcidas brotando para fora da silhueta traseira e lateral
    for sx in (-1, 1):
        raiz_tras = _chaikin([
            (sx * 0.28, -1.38), (sx * 0.48, -2.35), (sx * 0.82, -1.92),
            (sx * 1.28, -2.42), (sx * 1.48, -1.78), (sx * 1.15, -1.32)
        ], 2)
        raiz_lat = _chaikin([
            (sx * 1.38, 0.55), (sx * 2.12, 0.18), (sx * 1.75, -0.25),
            (sx * 2.22, -0.78), (sx * 1.42, -1.12)
        ], 2)
        _extensao_sem_costura(s, raiz_tras, raiz_media, fundo_escuro, ow=0.09)
        _extensao_sem_costura(s, raiz_lat, raiz_escura, fundo_escuro, ow=0.09)

    # Cavidade escura orgânica no interior do emaranhado de raízes + veios de seiva carmesim brilhando no fundo
    s.flat(_chaikin([
        (-1.35, -0.12), (0.0, -0.05), (1.35, -0.12), (1.42, -1.42), (-1.42, -1.42)
    ], 2), TOP, 0.004, fundo_escuro, smooth=False)
    for sx, sy, rx, ry, rot in [
        (-0.62, -0.58, 0.28, 0.08, 0.4), (0.55, -0.82, 0.30, 0.08, -0.35),
        (-0.12, -1.12, 0.26, 0.08, 0.15), (0.18, -0.35, 0.22, 0.07, -0.5)
    ]:
        s.flat(ellipse(sx, sy, rx, ry, n=10, rot=rot), TOP + 0.005, 0.005, seiva_viva, emit=0.95)

    # REDE DE RAÍZES ORGÂNICAS RAMIFICADAS E AFILADAS (troncos principais + bifurcações + radículas finas):
    # 1. Raiz-mãe esquerda serpenteando da borda traseira esquerda e se ramificando em 3 pontas
    _ramo_raiz([(-1.38, -1.48), (-0.95, -0.92), (-0.28, -0.68), (0.45, -0.85), (1.18, -0.52)], 0.22, 0.04, TOP + 0.008, raiz_media)
    _ramo_raiz([(-0.28, -0.68), (0.12, -0.25), (0.52, -0.05)], 0.14, 0.03, TOP + 0.011, raiz_media)
    _ramo_raiz([(-0.95, -0.92), (-1.35, -0.35), (-1.48, 0.28)], 0.16, 0.04, TOP + 0.011, raiz_escura)

    # 2. Raiz-mãe direita serpenteando da lateral direita por cima da esquerda e bifurcando para trás e para o centro
    _ramo_raiz([(1.48, -0.15), (0.85, -0.42), (0.05, -0.52), (-0.68, -0.25), (-1.38, 0.08)], 0.22, 0.04, TOP + 0.016, raiz_clara)
    _ramo_raiz([(0.05, -0.52), (-0.38, -1.05), (-0.82, -1.48)], 0.15, 0.03, TOP + 0.019, raiz_clara)
    _ramo_raiz([(0.85, -0.42), (0.62, -1.08), (0.22, -1.48)], 0.15, 0.03, TOP + 0.019, raiz_media)

    # 3. Raiz traseira central brotando de (-Y) e se dividindo em Y invertido
    _ramo_raiz([(0.88, -1.52), (0.35, -1.18), (-0.18, -0.88), (-0.75, -1.25)], 0.18, 0.04, TOP + 0.024, raiz_clara)
    _ramo_raiz([(-0.18, -0.88), (-0.48, -0.42), (-0.92, -0.18)], 0.12, 0.03, TOP + 0.026, raiz_clara)

    # 4. Raízes frontais brotando das laterais (+Y) e ramificando nos cantos da testa (sem formar linha horizontal de boca!)
    for sx in (-1, 1):
        _ramo_raiz([(sx * 1.52, 0.88), (sx * 1.12, 1.25), (sx * 0.48, 1.45), (sx * 0.18, 1.18)], 0.16, 0.03, TOP + 0.008, raiz_media)
        _ramo_raiz([(sx * 1.12, 1.25), (sx * 0.85, 1.52)], 0.10, 0.03, TOP + 0.012, raiz_clara)

    # Sobrancelhas de raiz bifurcada retorcida com expressão FURIOSA (\ / na câmera 65°!)
    for sx in (-1, 1):
        _ramo_raiz([(sx * 1.45, -0.06), (sx * 0.85, 0.18), (sx * 0.34, 0.48)], 0.16, 0.05, TOP + 0.026, raiz_clara)
        _ramo_raiz([(sx * 0.95, 0.14), (sx * 1.32, 0.22)], 0.09, 0.02, TOP + 0.028, raiz_media)

    # Mãos feitas de raízes ramificadas
    s.hand_flat(_chaikin([(-0.30, -0.12), (-0.04, 0.28), (0.08, 0.25), (-0.14, -0.18)], 1),
                1.83, 0.018, raiz_media, outline=fundo_escuro, ow=0.02, smooth=False)
    s.hand_flat(_chaikin([(0.28, -0.12), (0.02, 0.26), (-0.10, 0.22), (0.12, -0.18)], 1),
                1.85, 0.018, raiz_clara, outline=fundo_escuro, ow=0.02, smooth=False)


# ---------------------------------------------------------------- 5. Cristal Abissal (ref. 85)
def cristal_abissal(s):
    # Criatura metade rocha abissal negra, metade aglomerado de PRISMAS DE CRISTAL pontiagudos:
    # Todos os detalhes são prismas hexagonais alongados com ponta piramidal e 2 facetas longitudinais
    # (clara e média) divididas por uma aresta central, organizados em 3 aglomerados (drusas)!
    s.base()
    abissal_cl = "#242834"
    c_borda, c_escuro, c_medio, c_claro, c_brilho = "#04284C", "#0058A8", "#20A0F8", "#68E4FF", "#E8FFFF"

    def _prisma_cristal(x0, y0, ang_rad, compr, larg, z_p, fora_silhueta=False):
        """Desenha um prisma de cristal hexagonal pontiagudo com 2 facetas longitudinais (clara e média)
        divididas por uma aresta central até a ponta piramidal!"""
        ca, sa = math.cos(ang_rad), math.sin(ang_rad)
        nx, ny = -sa, ca
        hw = larg * 0.5
        c_ombro = compr * 0.72
        p_base_e = (x0 + nx * hw, y0 + ny * hw)
        p_base_c = (x0, y0)
        p_base_d = (x0 - nx * hw, y0 - ny * hw)
        p_ombro_e = (x0 + ca * c_ombro + nx * hw * 0.88, y0 + sa * c_ombro + ny * hw * 0.88)
        p_ombro_d = (x0 + ca * c_ombro - nx * hw * 0.88, y0 + sa * c_ombro - ny * hw * 0.88)
        p_ponta = (x0 + ca * compr, y0 + sa * compr)

        silhueta = [p_base_e, p_ombro_e, p_ponta, p_ombro_d, p_base_d]
        if fora_silhueta:
            _extensao_sem_costura(s, silhueta, c_medio, c_borda, ow=0.08)
        # Base do prisma com contorno azul-profundo
        s.flat(silhueta, z_p, 0.012, c_escuro, outline=c_borda, ow=0.03, smooth=False)
        # Faceta esquerda (iluminada ciano-claro)
        s.flat([p_base_e, p_ombro_e, p_ponta, p_base_c], z_p + 0.013, 0.008, c_claro, emit=0.5, smooth=False)
        # Faceta direita (azul-médio)
        s.flat([p_base_c, p_ponta, p_ombro_d, p_base_d], z_p + 0.013, 0.008, c_medio, emit=0.25, smooth=False)
        # Brilho branco-ciano na ponta piramidal
        p_meio = (x0 + ca * (compr * 0.48), y0 + sa * (compr * 0.48))
        s.flat([p_meio, p_ombro_e, p_ponta], z_p + 0.022, 0.006, c_brilho, emit=0.9, smooth=False)

    # 1. Grande drusa principal de 5 prismas de cristal pontiagudos irradiando do canto traseiro direito
    _prisma_cristal(0.55, -0.58, math.radians(-125), 1.15, 0.46, TOP + 0.006, fora_silhueta=False)
    _prisma_cristal(0.72, -0.68, math.radians(-78), 1.48, 0.52, TOP + 0.014, fora_silhueta=True)
    _prisma_cristal(0.88, -0.55, math.radians(-38), 1.55, 0.54, TOP + 0.022, fora_silhueta=True)
    _prisma_cristal(0.98, -0.32, math.radians(2), 1.18, 0.44, TOP + 0.014, fora_silhueta=True)
    _prisma_cristal(0.45, -0.68, math.radians(-162), 0.92, 0.38, TOP + 0.010, fora_silhueta=False)

    # 2. Drusa frontal direita (2 prismas de cristal brotando da borda frontal direita acima do olho)
    _prisma_cristal(0.85, 1.18, math.radians(35), 0.92, 0.36, TOP + 0.008, fora_silhueta=True)
    _prisma_cristal(0.72, 1.15, math.radians(78), 0.72, 0.30, TOP + 0.016, fora_silhueta=False)

    # 3. Drusa lateral esquerda (2 prismas menores brotando da fenda esquerda da rocha abissal)
    _prisma_cristal(-0.98, -0.38, math.radians(165), 0.85, 0.34, TOP + 0.008, fora_silhueta=True)
    _prisma_cristal(-0.92, -0.52, math.radians(-145), 0.72, 0.28, TOP + 0.016, fora_silhueta=False)

    # Veios ramificados de cristal ciano ligando as drusas pela rocha abissal
    for f_pts in [
        [(0.45, -0.58), (-0.25, -0.52), (-0.95, -0.42), (-0.22, -0.42)],
        [(-0.25, -0.52), (-0.68, -1.08), (-0.18, -0.58)],
    ]:
        s.flat(_chaikin(f_pts, 1), TOP + 0.005, 0.008, c_claro, emit=0.9, smooth=False)

    # Sobrancelhas assimétricas FURIOSAS (\ / na câmera 65°: direita feita de prisma de cristal!)
    s.flat(_chaikin([(-0.35, 0.38), (-0.75, 0.12), (-1.38, -0.14), (-1.45, 0.08), (-0.78, 0.32), (-0.35, 0.56)], 1),
           TOP + 0.014, 0.018, abissal_cl, outline="#050608", ow=0.025, smooth=False)
    s.flat([(0.34, 0.48), (0.78, 0.12), (1.42, -0.16), (1.48, 0.08), (0.82, 0.34), (0.34, 0.58)],
           TOP + 0.016, 0.018, c_claro, outline=c_borda, ow=0.025, emit=0.7, smooth=False)

    # Mão com prisma de cristal ciano pontudo
    s.hand_flat([(-0.20, -0.18), (-0.16, 0.12), (0.0, 0.34), (0.16, 0.12), (0.20, -0.18)],
                1.83, 0.018, c_claro, outline=c_borda, ow=0.025, emit=0.6, smooth=False)
    s.hand_flat([(-0.16, -0.15), (-0.12, 0.10), (0.0, 0.30), (0.0, -0.15)],
                1.85, 0.010, c_brilho, emit=0.9, smooth=False)


# ---------------------------------------------------------------- 6. Caveira Branca / Crânio (ref. 91)
def caveira_branca(s):
    s.base()
    osso_sombra, osso_medio, escuro = "#C8C8C4", "#E0E0DC", "#201C20"

    # Arcos zigomáticos (maçãs do rosto da caveira) salientes nas laterais frontais
    for sx in (-1, 1):
        zigo = _chaikin([
            (sx * 1.42, 1.15), (sx * 1.92, 0.72), (sx * 1.88, 0.12), (sx * 1.42, -0.18)
        ], 2)
        _extensao_sem_costura(s, zigo, "#F4F4F0", "#686868", ow=0.08)

    # Sombreamento anatômico das têmporas nas laterais traseiras
    s.sym(_chaikin([
        (1.22, -0.15), (1.55, -0.25), (1.55, -1.15), (1.18, -1.42), (1.28, -0.75)
    ], 2), TOP, 0.008, osso_sombra, smooth=False)

    # Órbitas oculares escuras profundas ao redor dos olhos + cenho ósseo FURIOSO (\ / na câmera 65°!)
    for k in (-1, 1):
        _anel_quads(s, k * EYE_X, EYE_Y, 0.45, 0.62, TOP + 0.006, 0.010, escuro, n=16)
    s.sym(_chaikin([
        (0.34, 0.38), (0.75, 0.14), (1.36, -0.12),
        (1.44, 0.08), (0.78, 0.32), (0.34, 0.56)
    ], 1), TOP + 0.018, 0.018, osso_sombra, outline="#585858", ow=0.025, smooth=False)

    # Cavidade nasal triangular bipartida na frente (entre os olhos e os dentes)
    s.sym([(0.04, 1.25), (0.22, 0.96), (0.04, 0.98)], TOP + 0.010, 0.016, escuro, smooth=False)

    # Fileira de 4 dentes de caveira entalhados na borda frontal (+Y) com divisórias escuras
    s.flat([(-0.92, 1.36), (0.92, 1.36), (0.92, 1.56), (-0.92, 1.56)],
           TOP + 0.008, 0.014, osso_medio, outline=escuro, ow=0.03, smooth=False)
    for dx in (-0.46, 0.0, 0.46):
        s.flat([(dx - 0.04, 1.34), (dx + 0.04, 1.34), (dx + 0.04, 1.56), (dx - 0.04, 1.56)],
               TOP + 0.023, 0.012, escuro, smooth=False)

    # Suturas cranianas e rachadura óssea em zigue-zague no topo traseiro (-Y)
    rachadura = [
        (-0.85, -1.52), (-0.48, -1.08), (-0.65, -0.68), (-0.18, -0.45),
        (-0.12, -0.52), (-0.55, -0.72), (-0.38, -1.12), (-0.75, -1.52)
    ]
    s.flat(rachadura, TOP + 0.012, 0.012, escuro, smooth=False)
    s.flat([(0.35, -1.52), (0.68, -1.12), (0.98, -1.25), (0.74, -1.05), (0.26, -1.52)],
           TOP + 0.012, 0.012, "#585858", smooth=False)

    # Ossos nas mãos
    s.hand_flat([(-0.26, -0.06), (0.26, -0.06), (0.26, 0.06), (-0.26, 0.06)], 1.83, 0.016, osso_sombra, smooth=False)


# ---------------------------------------------------------------- 7. Meteoro de Magma (ref. 135)
def meteoro_magma(s):
    s.base()
    rocha_cl, rocha_es, borda_cratera = "#503458", "#24142C", "#180C10"
    laranja, amarelo, nucleo = "#E85C14", "#FC9800", "#FFF488"

    # Protuberâncias rochosas irregulares de meteoro nos cantos traseiros
    prot_tras = _chaikin([(0.82, -1.42), (1.48, -1.86), (1.84, -1.28), (1.38, -0.78)], 2)
    _extensao_sem_costura(s, prot_tras, "#382440", "#1C1024", ow=0.08)
    _extensao_sem_costura(s, mirror_x(prot_tras), "#382440", "#1C1024", ow=0.08)

    # Relevos rochosos roxo-escuros na superfície do meteoro
    s.sym(_chaikin([
        (1.18, 1.32), (1.54, 0.95), (1.54, -0.95), (1.12, -1.32), (1.28, 0.0)
    ], 2), TOP, 0.008, rocha_es, smooth=False)

    # Crateras de meteoro incandescentes distribuídas de forma orgânica/assimétrica
    crateras = [
        (-0.82, -0.78, 0.38, 0.32, 0.3),
        (0.68, -1.05, 0.36, 0.30, -0.35),
        (-0.15, -1.22, 0.26, 0.22, 0.15),
        (0.18, -0.45, 0.24, 0.20, -0.2),
        (-1.28, -0.18, 0.24, 0.20, 0.5),
        (1.25, -0.25, 0.26, 0.20, -0.4),
        (-0.95, 1.25, 0.24, 0.18, -0.3),
        (0.95, 1.25, 0.24, 0.18, 0.3),
    ]
    for cx, cy, rx, ry, rot in crateras:
        s.flat(ellipse(cx, cy, rx, ry, n=14, rot=rot), TOP + 0.009, 0.014, rocha_cl, outline=borda_cratera, ow=0.03)
        s.flat(ellipse(cx, cy, rx * 0.72, ry * 0.72, n=12, rot=rot), TOP + 0.024, 0.012, laranja, emit=0.8)
        s.flat(ellipse(cx, cy, rx * 0.45, ry * 0.45, n=10, rot=rot), TOP + 0.037, 0.010, amarelo, emit=1.1)
        s.flat(ellipse(cx, cy, rx * 0.22, ry * 0.22, n=8, rot=rot), TOP + 0.048, 0.008, nucleo, emit=1.4)

    # Sobrancelhas rochosas FURIOSAS (\ / na câmera 65°!)
    s.sym(_chaikin([
        (0.35, 0.38), (0.75, 0.14), (1.36, -0.12),
        (1.44, 0.08), (0.78, 0.32), (0.35, 0.55)
    ], 1), TOP + 0.014, 0.018, rocha_es, outline=borda_cratera, ow=0.025, smooth=False)

    # Cratera incandescente nas mãos
    s.hand_flat(ellipse(0.0, 0.0, 0.24, 0.20, n=12), 1.83, 0.016, laranja, outline=borda_cratera, ow=0.03, emit=0.8)
    s.hand_flat(ellipse(0.0, 0.0, 0.12, 0.10, n=10), 1.85, 0.012, amarelo, emit=1.2)


# ---------------------------------------------------------------- 8. Travesseiro / Almofada Fofa (ref. 189)
def travesseiro(s):
    s.base()
    tecido_cl, tecido_sombra, costura = "#FCF8EC", "#D0C498", "#8C7C58"
    botao, botao_borda = "#B8A878", "#6C5C3C"

    # 4 pontas fofas de travesseiro (orelhinhas de tecido) saindo dos 4 cantos diagonais
    for kx in (-1, 1):
        for ky in (-1, 1):
            ponta_canto = _chaikin([
                (kx * 0.98, ky * 1.42),
                (kx * 1.88, ky * 1.88),
                (kx * 1.42, ky * 0.98),
            ], 2)
            _extensao_sem_costura(s, ponta_canto, "#ECE4C4", "#9C8C68", ow=0.08)
            # Dobra interna na ponta do travesseiro
            s.flat(_chaikin([
                (kx * 1.18, ky * 1.38), (kx * 1.62, ky * 1.62), (kx * 1.38, ky * 1.18)
            ], 1), TOP + 0.009, 0.010, tecido_sombra, smooth=False)

    # Almofada central estofada mais clara com vincos macios nas bordas
    almofada_centro = _chaikin([
        (-1.18, 1.18), (0.0, 1.28), (1.18, 1.18), (1.28, 0.0),
        (1.18, -1.18), (0.0, -1.28), (-1.18, -1.18), (-1.28, 0.0)
    ], 2)
    s.flat(almofada_centro, TOP, 0.004, tecido_cl, outline=tecido_sombra, ow=0.06, smooth=False)

    # Trilha pontilhada de costura contornando a borda do travesseiro
    for pos in (-0.85, -0.42, 0.0, 0.42, 0.85):
        s.flat(ellipse(pos, 1.42, 0.12, 0.035, n=8), TOP + 0.010, 0.010, costura)
        s.flat(ellipse(pos, -1.42, 0.12, 0.035, n=8), TOP + 0.010, 0.010, costura)
        s.flat(ellipse(1.42, pos, 0.035, 0.12, n=8), TOP + 0.010, 0.010, costura)
        s.flat(ellipse(-1.42, pos, 0.035, 0.12, n=8), TOP + 0.010, 0.010, costura)

    # 3 botões estofados de capitonê na metade traseira da almofada (com pregas saindo deles)
    for bx, by in [(-0.72, -0.78), (0.72, -0.78), (0.0, -1.05)]:
        for ang in (0.4, -0.4, 1.2, -1.2):
            s.flat(ellipse(bx, by, 0.24, 0.04, n=8, rot=ang), TOP + 0.008, 0.008, tecido_sombra)
        s.flat(ellipse(bx, by, 0.13, 0.13, n=12), TOP + 0.016, 0.014, botao, outline=botao_borda, ow=0.025)
        s.flat(ellipse(bx - 0.03, by, 0.025, 0.025, n=6), TOP + 0.031, 0.008, botao_borda)
        s.flat(ellipse(bx + 0.03, by, 0.025, 0.025, n=6), TOP + 0.031, 0.008, botao_borda)

    s.hand_flat(ellipse(0.0, 0.0, 0.24, 0.18, n=12), 1.83, 0.016, tecido_cl, outline=tecido_sombra, ow=0.03)


# ---------------------------------------------------------------- 9. Fornalha Industrial (ref. 204)
def fornalha_industrial(s):
    s.base()
    aco_claro, aco_medio, aco_escuro, borda = "#C0C4C4", "#888C8C", "#404444", "#202222"
    brasa_lar, brasa_am, brasa_br = "#F88808", "#FCE454", "#FFFFC8"

    # Moldura blindada de aço claro ao redor das bordas da fornalha
    moldura_tras = _chaikin([
        (-1.48, -0.08), (1.48, -0.08), (1.48, -1.48), (-1.48, -1.48)
    ], 1)
    s.flat(moldura_tras, TOP, 0.012, aco_medio, outline=borda, ow=0.035, smooth=False)
    s.sym([(1.18, 1.48), (1.52, 1.48), (1.52, 0.05), (1.18, 0.05)],
          TOP, 0.012, aco_medio, outline=borda, ow=0.03, smooth=False)

    # Grande abertura da grelha térmica incandescente na metade traseira (-Y)
    grelha_fundo = _chaikin([
        (-1.12, -0.26), (1.12, -0.26), (1.12, -1.28), (-1.12, -1.28)
    ], 1)
    s.flat(grelha_fundo, TOP + 0.014, 0.012, brasa_lar, outline=borda, ow=0.035, emit=0.8, smooth=False)
    s.flat(_chaikin([
        (-0.96, -0.38), (0.96, -0.38), (0.96, -1.16), (-0.96, -1.16)
    ], 1), TOP + 0.027, 0.010, brasa_am, emit=1.1, smooth=False)
    s.flat(_chaikin([
        (-0.68, -0.52), (0.68, -0.52), (0.68, -1.02), (-0.68, -1.02)
    ], 1), TOP + 0.038, 0.008, brasa_br, emit=1.4, smooth=False)

    # 5 barras verticais de ferro escuro da grelha passando por cima da brasa incandescente
    for gx in (-0.76, -0.38, 0.0, 0.38, 0.76):
        s.flat([(gx - 0.07, -0.22), (gx + 0.07, -0.22), (gx + 0.07, -1.32), (gx - 0.07, -1.32)],
               TOP + 0.047, 0.016, aco_escuro, outline=borda, ow=0.015, smooth=False)

    # Rebites metálicos claros nos cantos da fornalha
    for rx, ry in [(1.34, 1.32), (1.34, 0.25), (1.32, -0.22), (1.32, -1.32), (0.55, -1.40)]:
        s.sym(ellipse(rx, ry, 0.08, 0.08, n=8), TOP + 0.026, 0.014, aco_claro, outline=borda, ow=0.02)

    # Visor/sobrancelhas blindadas de aço FURIOSAS (\ / na câmera 65°!)
    s.sym([
        (0.35, 0.38), (0.75, 0.14), (1.35, -0.10),
        (1.42, 0.08), (0.78, 0.32), (0.35, 0.54)
    ], TOP + 0.014, 0.016, aco_claro, outline=borda, ow=0.025, smooth=False)

    s.hand_flat([(-0.28, -0.14), (0.28, -0.14), (0.28, 0.14), (-0.28, 0.14)],
                1.83, 0.018, aco_medio, outline=borda, ow=0.025, smooth=False)
    s.hand_flat([(-0.16, -0.06), (0.16, -0.06), (0.16, 0.06), (-0.16, 0.06)],
                1.85, 0.012, brasa_am, emit=1.1, smooth=False)


# ---------------------------------------------------------------- 10. Boneco de Retalhos / Patchwork (ref. 241)
def retalhos(s):
    s.base()
    azul_pet, marrom, bege, verde = "#187488", "#644230", "#D8CCA0", "#4C8458"
    linha_branca, linha_escura = "#F8F8F4", "#28201C"

    # 4 grandes quadrantes assimétricos de tecido colorido (fininhos em Z para os olhos ficarem limpos!)
    # Quadrante frontal-esquerdo: bege-linho
    q_fe = _chaikin([(-1.54, 1.52), (0.05, 1.54), (-0.05, -0.05), (-1.54, 0.08)], 1)
    # Quadrante frontal-direito: marrom-couro
    q_fd = _chaikin([(0.05, 1.54), (1.54, 1.52), (1.54, -0.12), (-0.05, -0.05)], 1)
    # Quadrante traseiro-esquerdo: azul-petróleo
    q_te = _chaikin([(-1.54, 0.08), (-0.05, -0.05), (0.08, -1.54), (-1.52, -1.52)], 1)
    # Quadrante traseiro-direito: verde-musgo
    q_td = _chaikin([(-0.05, -0.05), (1.54, -0.12), (1.52, -1.52), (0.08, -1.54)], 1)

    for poly, cor_q in [(q_fe, bege), (q_fd, marrom), (q_te, azul_pet), (q_td, verde)]:
        s.flat(poly, TOP, 0.005, cor_q, smooth=False)

    # Fendas escuras de costura cruzando o corpo em "+" (entre os 4 retalhos)
    s.flat([(-0.08, 1.55), (0.08, 1.55), (0.10, -1.55), (-0.06, -1.55)],
           TOP + 0.006, 0.006, linha_escura, smooth=False)
    s.flat([(-1.55, 0.12), (1.55, -0.08), (1.55, -0.18), (-1.55, 0.02)],
           TOP + 0.006, 0.006, linha_escura, smooth=False)

    # Pontos largos de linha branca costurando as divisórias vertical e horizontal
    for yy in (1.28, 0.88, 0.48, -0.35, -0.75, -1.18):
        s.flat(ellipse(0.01, yy, 0.18, 0.045, n=8, rot=0.15), TOP + 0.013, 0.010, linha_branca)
    for xx, yy in [(-1.28, 0.05), (-0.38, -0.02), (0.38, -0.06), (1.28, -0.12)]:
        s.flat(ellipse(xx, yy, 0.045, 0.18, n=8, rot=-0.1), TOP + 0.013, 0.010, linha_branca)

    # Remendo menor creme costurado no canto traseiro-esquerdo sobre o tecido azul
    rem_extra = _chaikin([(-1.35, -0.48), (-0.52, -0.55), (-0.58, -1.32), (-1.38, -1.25)], 1)
    s.flat(rem_extra, TOP + 0.008, 0.010, bege, outline=linha_escura, ow=0.03, smooth=False)
    for px, py, rot in [(-0.95, -0.51, 1.5), (-0.55, -0.92, 0.05), (-0.95, -1.28, 1.5)]:
        s.flat(ellipse(px, py, 0.13, 0.04, n=8, rot=rot), TOP + 0.019, 0.010, linha_branca)

    # Mãos bicolores costuradas ao meio
    s.hand_flat([(-0.28, 0.0), (0.28, 0.0), (0.26, 0.22), (-0.26, 0.22)], 1.83, 0.015, bege, smooth=False)
    s.hand_flat([(-0.28, -0.22), (0.28, -0.22), (0.28, 0.0), (-0.28, 0.0)], 1.83, 0.015, marrom, smooth=False)
    s.hand_flat(ellipse(0.0, 0.0, 0.05, 0.16, n=8), 1.848, 0.012, linha_branca)


LOTE = [
    ("bloco_perigo", bloco_perigo, "#F4A000", "#8C5400", "#F4A000", "#8C5400"),
    ("oni_vermelho", oni_vermelho, "#C84440", "#782820", "#C84440", "#782820"),
    ("runa_sombria", runa_sombria, "#201C20", "#A80008", "#201C20", "#A80008"),
    ("raizes_carmesim", raizes_carmesim, "#AC3030", "#480000", "#AC3030", "#480000"),
    ("cristal_abissal", cristal_abissal, "#141820", "#083050", "#141820", "#083050"),
    ("caveira_branca", caveira_branca, "#F4F4F0", "#686868", "#F4F4F0", "#686868"),
    ("meteoro_magma", meteoro_magma, "#382440", "#1C1024", "#382440", "#1C1024"),
    ("travesseiro", travesseiro, "#ECE4C4", "#9C8C68", "#ECE4C4", "#9C8C68"),
    ("fornalha_industrial", fornalha_industrial, "#5C6060", "#2C3030", "#5C6060", "#2C3030"),
    ("retalhos", retalhos, "#187488", "#28201C", "#644230", "#28201C"),
]
