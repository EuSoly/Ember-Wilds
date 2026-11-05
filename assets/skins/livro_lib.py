# Base das skins de LIVRO (o livro que o boneco segura). Reaproveita a skin_lib (flat, ellipse,
# sym, sphere, mat...). Medidas do livro do jogo: ReplicatedStorage.Assets.Tools.book.Handle =
# 2,37 (largura, X) × 2,68 (comprimento, Y no Blender) × 0,53 (espessura, Z). Deitado, capa para cima.
# Lombada no lado -X; páginas aparecendo nas outras três bordas.
# O livro padrão do Elizeu: capa vermelho-tijolo, moldura dourada, gema dourada em losango no meio.
from skin_lib import *
import skin_lib as _sl

LW, LL, LT = 2.37, 2.68, 0.53      # largura, comprimento, espessura total
CAPA = 0.09                         # espessura de cada capa
PAG_IN = 0.07                       # quanto as páginas ficam para dentro da capa
TOPO = LT                           # topo da capa de cima: camadas planas em z = TOPO

class Livro(Skin):
    """Mesma API da Skin (flat, sym, sphere, ellipse...), mas a base é o livro."""
    def __init__(self, name, ox, oy, capa, borda, paginas="#F2E6C9", lombada=None):
        super().__init__(name, ox, oy, capa, borda)
        self.capa, self.borda, self.paginas, self.lombada = capa, borda, paginas, lombada or capa

    def _caixa(self, nome, w, l, z0, h, r, cor):
        bm = bmesh.new(); bmesh.ops.create_cube(bm, size=1)
        bmesh.ops.scale(bm, vec=(w, l, h), verts=bm.verts)
        bmesh.ops.translate(bm, vec=(self.ox, self.oy, z0 + h/2), verts=bm.verts)
        if r > 0:
            ve = [e for e in bm.edges if abs(e.verts[0].co.z - e.verts[1].co.z) > 1e-4]
            bmesh.ops.bevel(bm, geom=ve, offset=r, segments=4, affect='EDGES', profile=0.5)
        me = bpy.data.meshes.new(nome); bm.to_mesh(me); bm.free()
        o = bpy.data.objects.new(nome, me); o.data.materials.append(mat(cor)); self.coll.objects.link(o)
        return o

    def base(self, sem_paginas=False):
        """Livro fechado: capa de baixo, miolo de páginas, capa de cima, lombada e um contorno fino."""
        n = self.name
        # contorno só na base (a borda das páginas fica à mostra, como no livro do jogo)
        self._caixa(f"{n}_Contorno", LW + 0.12, LL + 0.12, 0.0, CAPA + 0.02, 0.12, self.borda)
        self._caixa(f"{n}_CapaBaixo", LW, LL, 0.0, CAPA, 0.08, self.capa)
        if not sem_paginas:
            self._caixa(f"{n}_Paginas", LW - 2*PAG_IN, LL - 2*PAG_IN, CAPA, LT - 2*CAPA, 0.02, self.paginas).location.x += PAG_IN * 0.5
        self._caixa(f"{n}_CapaCima", LW, LL, LT - CAPA, CAPA, 0.08, self.capa)
        lb = self._caixa(f"{n}_Lombada", 0.22, LL + 0.02, 0.0, LT + 0.012, 0.06, self.lombada); lb.location.x -= LW/2 - 0.11  # um tico acima da capa: sem z-fighting

    def finish(self):
        pass  # livro não tem mãos

def build_livros(lote, cols=5, dx=4.5, dy=5.0, clear=True):
    # lote: lista de (nome, função, capa, borda[, páginas[, lombada]])
    if clear: clear_scene()
    for i, item in enumerate(lote):
        name, fn, capa, borda, *rest = item
        ox = (i % cols - (cols - 1) / 2) * dx; oy = -(i // cols) * dy
        lv = Livro(name, ox, oy, capa, borda, *rest)
        fn(lv)
    return len(bpy.data.objects)

def padrao(lv):
    """O livro do jogo, como referência de escala e estilo: moldura dourada e gema em losango."""
    lv.base()
    ouro, ouro2 = "#E2C34A", "#B89A2E"
    moldura = [(-0.85, 1.05), (0.95, 1.05), (0.95, -1.05), (-0.85, -1.05)]
    lv.flat(offset_poly(moldura, 0.05), TOPO, 0.03, ouro, smooth=False)
    lv.flat(offset_poly(moldura, -0.03), TOPO + 0.005, 0.03, lv.capa, smooth=False)
    lv.flat([(0.05, 0.42), (0.36, 0.0), (0.05, -0.42), (-0.26, 0.0)], TOPO, 0.12, ouro, outline=ouro2, ow=0.03, smooth=False)
