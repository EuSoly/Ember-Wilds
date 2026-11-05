# Biblioteca comum das skins de MOCHILA (montadas nas costas de um boneco fantasma PREVIEW_*).
# Reaproveita utilidades da skin_lib (mat, catmull, offset_poly, ellipse, mirror_x, clear_scene, render_previews).
# Coordenadas locais (x, y) da Mochila são relativas ao CENTRO DA MOCHILA (em y_mundo = oy + BAG_Y):
#   x: largura (- para a direita na câmera 65°, + para a esquerda na câmera 65°)
#   y: profundidade (+y encosta nas costas do boneco; -y aponta para trás/fora do boneco = PARA CIMA na imagem 65°)
#   z: altura (base da mochila em z = Z0 = 0.25; topo da mochila em z = TOPO = 2.08, logo acima da cabeça do boneco em z = 2.0).
from skin_lib import *
import skin_lib as _sl

BAG_Y = -2.55          # deslocamento do centro da mochila em relação ao centro do boneco (costas = -Y)
MW, MD = 2.56, 1.32    # largura (X) e profundidade (Y) padrão da mochila
Z0, MH = 0.28, 1.80    # base (z = 0.28) e altura (1.80) -> topo em z = 2.08
TOPO = Z0 + MH         # z = 2.08 (acima do topo do boneco z = 2.00 para aparecer limpa a 65°)
MR = 0.42              # raio de arredondamento dos cantos da mochila


class Mochila(Skin):
    """Mesma API da Skin (flat, sym, sphere, rounded_box...), com origem local no centro da mochila
    e boneco fantasma PREVIEW_* nas costas do qual a mochila fica encaixada."""

    def __init__(self, name, ox, oy, body="#804C28", outline="#481C10", strap=None):
        # Passamos oy + BAG_Y para que flat(), sphere(), etc. usem o centro da mochila como (0, 0)
        super().__init__(name, ox, oy + BAG_Y, body, outline)
        self.root_ox = ox
        self.root_oy = oy
        self.strap = strap or outline
        self._criar_boneco_fantasma()

    def _criar_boneco_fantasma(self):
        """Cria o boneco fantasma semitransparente (PREVIEW_*) na posição raiz (root_ox, root_oy)."""
        # Salva ox/oy da mochila e usa temporariamente a raiz do boneco
        bx, by = self.ox, self.oy
        self.ox, self.oy = self.root_ox, self.root_oy
        ghost_col = "#525866"
        ghost_out = "#343842"
        b = self.rounded_box(f"PREVIEW_{self.name}_GhostBody", BW, BH, CR, 0.18, ghost_col)
        b.data.materials[0] = mat(ghost_col, alpha=0.42)
        bo = self.rounded_box(f"PREVIEW_{self.name}_GhostOutline", BW + 2*OUT, BH - DROP, CR + OUT, 0.10, ghost_out)
        bo.data.materials[0] = mat(ghost_out, alpha=0.35)
        for sx in (-1, 1):
            tag = "R" if sx > 0 else "L"
            h = self.sphere((sx * HX, HY, HZ), (HAND_D/2,)*3, ghost_col, kind="PREVIEW")
            h.name = f"PREVIEW_{self.name}_GhostHand_{tag}"
            h.data.materials[0] = mat(ghost_col, alpha=0.42)
            e = self.sphere((sx * EYE_X, EYE_Y, BH - 0.05), (EYE_D/2, EYE_D/2, 0.12), "#18181C", kind="PREVIEW")
            e.name = f"PREVIEW_{self.name}_GhostEye_{tag}"
            sh = self.sphere((sx * EYE_X + 0.15, EYE_Y + 0.15, BH + 0.06), (0.15, 0.15, 0.04), "#FFFFFF", kind="PREVIEW")
            sh.name = f"PREVIEW_{self.name}_GhostShine_{tag}"
        self.ox, self.oy = bx, by

    def _caixa_mochila(self, nome, w, d, z_ini, h, r, top_bevel, cor, dy=0.0):
        bm = bmesh.new()
        bmesh.ops.create_cube(bm, size=1)
        bmesh.ops.scale(bm, vec=(w, d, h), verts=bm.verts)
        bmesh.ops.translate(bm, vec=(self.ox, self.oy + dy, z_ini + h * 0.5), verts=bm.verts)
        if r > 0:
            ve = [e for e in bm.edges if abs(e.verts[0].co.z - e.verts[1].co.z) > 1e-4]
            bmesh.ops.bevel(bm, geom=ve, offset=r, segments=8, affect='EDGES', profile=0.5)
        if top_bevel > 0:
            te = [e for e in bm.edges if all(abs(v.co.z - (z_ini + h)) < 1e-4 for v in e.verts)
                  and not all(abs(f.normal.z) > 0.99 for f in e.link_faces)]
            bmesh.ops.bevel(bm, geom=te, offset=top_bevel, segments=3, affect='EDGES', profile=0.5)
        me = bpy.data.meshes.new(nome)
        bm.to_mesh(me)
        bm.free()
        for p in me.polygons:
            p.use_smooth = True
        o = bpy.data.objects.new(nome, me)
        o.data.materials.append(mat(cor))
        self.coll.objects.link(o)
        return o

    def base(self, w=MW, d=MD, h=MH, r=MR, body_color=None, outline_color=None, com_alcas=True):
        """Mochila fechada padrão encostada nas costas do boneco, com contorno e alças."""
        bc = body_color or self.body
        oc = outline_color or self.outline
        self._caixa_mochila(f"{self.name}_BagOutline", w + 0.24, d + 0.24, Z0 - 0.06, h, r + 0.10, 0.08, oc)
        self._caixa_mochila(f"{self.name}_BagBody", w, d, Z0, h, r, 0.12, bc)
        if com_alcas:
            # Duas tiras verticais de couro cruzando a mochila (como em day-bag0.png)
            for sx in (-1, 1):
                pts_alca = [
                    (sx * 0.62, -d * 0.42), (sx * 0.90, -d * 0.42),
                    (sx * 0.90, d * 0.48), (sx * 0.62, d * 0.48),
                ]
                self.flat(pts_alca, TOPO + 0.002, 0.025, self.strap, smooth=False)

    def base_aberta(self, cor_fundo="#5C3414", cor_bolsa="#804C28", cor_borda="#A86C40", cor_contorno="#3C200C"):
        """Bolsa de couro aberta (usada em coelho, ninho, aquário, esquilo, minérios):
        base trapezoidal escura encostada nas costas (+Y) e bolso frontal arredondado."""
        # Base de couro escura encostada nas costas do boneco (+Y)
        quad_base = [
            (-1.35, 0.65), (1.35, 0.65),
            (1.18, -0.58), (-1.18, -0.58),
        ]
        self.flat(quad_base, Z0, MH - 0.02, cor_fundo, outline=cor_contorno, ow=0.10, smooth=False)
        # Aba lateral de couro (#683C18) nas duas bordas
        for sx in (-1, 1):
            aba_l = [
                (sx * 1.02, 0.62), (sx * 1.32, 0.62),
                (sx * 1.15, -0.52), (sx * 0.92, -0.45),
            ]
            self.flat(aba_l, TOPO - 0.015, 0.018, "#683C18", smooth=False)
        # Bolso curvado marrom (#804C28) com borda clara (#A86C40) e interior escuro (#44240C)
        bolso_ext = [
            (-1.12, -0.35), (-1.05, 0.18), (-0.65, 0.52),
            (0.0, 0.60), (0.65, 0.52), (1.05, 0.18), (1.12, -0.35),
            (0.65, -0.58), (-0.65, -0.58),
        ]
        self.flat(bolso_ext, TOPO - 0.01, 0.025, cor_bolsa, outline=cor_contorno, ow=0.06, smooth=True)
        borda_sup = [
            (-1.08, -0.32), (-0.65, -0.02), (0.0, 0.08), (0.65, -0.02), (1.08, -0.32),
            (0.95, -0.52), (0.0, -0.62), (-0.95, -0.52),
        ]
        self.flat(borda_sup, TOPO + 0.018, 0.018, cor_borda, smooth=True)
        miolo_esc = [
            (-0.92, -0.32), (-0.52, -0.10), (0.0, -0.02), (0.52, -0.10), (0.92, -0.32),
            (0.75, -0.48), (0.0, -0.56), (-0.75, -0.48),
        ]
        self.flat(miolo_esc, TOPO + 0.036, 0.012, "#44240C", smooth=True)

    def finish(self):
        # Renomeia qualquer objeto PREVIEW criado por sphere()
        for o in self.coll.objects:
            if "_PREVIEW_" in o.name and not o.name.startswith("PREVIEW_"):
                o.name = "PREVIEW_" + o.name


def build_mochilas(lote, cols=5, dx=9.5, dy=11.0, clear=True):
    """Monta uma grade de mochilas com seus bonecos fantasmas."""
    if clear:
        clear_scene()
    for i, item in enumerate(lote):
        name, fn, body, outline, *rest = item
        ox = (i % cols - (cols - 1) / 2) * dx
        oy = -(i // cols) * dy
        m = Mochila(name, ox, oy, body, outline, *rest)
        fn(m)
        m.finish()
    return len(bpy.data.objects)
