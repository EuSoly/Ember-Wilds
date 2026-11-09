# Peças animadas das skins de corpo e de livro (pacotes do lançamento: Gelo, Abissal e Floresta).
# Mesmo esquema das caixas (caixa_animacao.py): a geometria aprovada não muda; as peças que se
# mexem viram grupos com um pivô, e o export as separa em malhas próprias (<id>_anim_<grupo>).
# Quem diz COMO cada grupo se mexe é o jogo: src/shared/Models/SkinMotion.luau.
#
# Cada grupo lista as peças pelo número do fim do nome (<skin>_<tipo>_NN, a ordem em que o lote
# as cria) e o pivô em coordenadas da skin (x, y em relação ao centro dela; z absoluto).
# pivo=None: centro da caixa das peças. `corte`: divide peças compridas num plano vertical
# (ponto, normal) e leva só o lado da normal para o grupo (a ponta do tentáculo do Tomo Abissal).
# `pecas_no_lado`: peças pequenas que vão para o grupo se o centro delas cair do lado da normal.
import re
import bpy, bmesh
from mathutils import Vector

ANIM = {
    # ---------------------------------------------------------------- corpo (lote1, lote3_e)
    "dragao": {
        "asa_dir": dict(pecas=[7, 8, 11, 13, 15], pivo=(1.55, -0.3, 1.5)),
        "asa_esq": dict(pecas=[9, 10, 12, 14, 16], pivo=(-1.55, -0.3, 1.5)),
        "rabo": dict(pecas=[29, 30, 31], pivo=(0.0, -1.75, 1.4)),
    },
    # tentáculos na ordem da volta (frente-direita → trás → frente-esquerda): a onda anda por eles
    "polvo": {
        "tentaculo_01": dict(pecas=[30, 31, 32, 33], pivo=(1.18, 0.21, 1.35)),
        "tentaculo_02": dict(pecas=[22, 23, 24, 25], pivo=(1.13, -0.41, 1.35)),
        "tentaculo_03": dict(pecas=[7, 8, 9, 10, 11], pivo=(0.6, -1.04, 1.35)),
        "tentaculo_04": dict(pecas=[12, 13, 14, 15, 16], pivo=(0.0, -1.2, 1.35)),
        "tentaculo_05": dict(pecas=[17, 18, 19, 20, 21], pivo=(-0.6, -1.04, 1.35)),
        "tentaculo_06": dict(pecas=[26, 27, 28, 29], pivo=(-1.13, -0.41, 1.35)),
        "tentaculo_07": dict(pecas=[34, 35, 36, 37], pivo=(-1.18, 0.21, 1.35)),
    },
    # raízes como pernas: pares em diagonal (01, 04, 05) e (02, 03, 06) alternam no passo
    "toco": {
        "raiz_01": dict(pecas=[9, 10, 11], pivo=(1.3, -0.1, 1.3)),
        "raiz_02": dict(pecas=[12, 13, 14], pivo=(1.0, -1.0, 1.3)),
        "raiz_03": dict(pecas=[15, 16, 17], pivo=(-1.3, -0.4, 1.3)),
        "raiz_04": dict(pecas=[18, 19, 20], pivo=(-1.1, -1.1, 1.3)),
        "raiz_05": dict(pecas=[21, 22, 23], pivo=(-0.3, 1.3, 1.3)),
        "raiz_06": dict(pecas=[24, 25], pivo=(0.35, 1.3, 1.3)),
        "broto_esq": dict(pecas=[48, 49, 52, 53, 54, 55, 56, 57], pivo=(-0.55, -1.35, 1.85)),
        "broto_dir": dict(pecas=[50, 51, 58, 59, 60, 61, 62, 63], pivo=(0.35, -1.4, 1.85)),
    },
    # ---------------------------------------------------------------- livros (livros1, livros2)
    "gelo": {
        "cristal_01": dict(pecas=list(range(1, 9)), pivo=None),
        "cristal_02": dict(pecas=list(range(9, 17)), pivo=None),
        "cristal_03": dict(pecas=list(range(17, 25)), pivo=None),
        "cristal_04": dict(pecas=list(range(25, 33)), pivo=None),
        "floco": dict(pecas=list(range(33, 77)), pivo=(0.0, 0.0, 0.56)),
    },
    "tentaculo": {
        "espiral": dict(pecas=[1, 2], pivo=(-0.35, 0.5, 0.56)),
        "ponta": dict(pecas=[3, 4], corte=dict(ponto=(1.05, -0.22), normal=(0.68, 0.73)),
                      pecas_no_lado=list(range(5, 20)), pivo=(1.05, -0.22, 0.57)),
    },
    "trepadeira": {
        **{f"folha_{i:02d}": dict(pecas=[3 + 2 * i, 4 + 2 * i], pivo=None) for i in range(1, 13)},
        "flor_01": dict(pecas=list(range(29, 40)), pivo=None),
        "flor_02": dict(pecas=list(range(40, 51)), pivo=None),
    },
}


def _numero(o):
    m = re.search(r"_(\d+)(?:\.\d+)?$", o.name)
    return int(m.group(1)) if m and not o.name.startswith("PREVIEW") else None


def _centro_caixa(objs):
    pts = [o.matrix_world @ Vector(c) for o in objs for c in o.bound_box]
    return Vector(tuple((min(p[i] for p in pts) + max(p[i] for p in pts)) / 2 for i in range(3)))


def _cortar(o, ponto, normal):
    """Divide `o` no plano vertical (ponto, normal); devolve a cópia com o lado da normal.
    O original fica com o outro lado. As duas faces do corte são fechadas."""
    co = Vector((ponto[0], ponto[1], 0.0)); no = Vector((normal[0], normal[1], 0.0)).normalized()
    inv = o.matrix_world.inverted()
    co_l = inv @ co; no_l = (inv.to_3x3() @ no).normalized()
    copia = o.copy(); copia.data = o.data.copy(); copia.name = o.name + "_ponta"
    for c in o.users_collection: c.objects.link(copia)
    for obj, manter_positivo in ((o, False), (copia, True)):
        bm = bmesh.new(); bm.from_mesh(obj.data)
        geom = bm.verts[:] + bm.edges[:] + bm.faces[:]
        r = bmesh.ops.bisect_plane(bm, geom=geom, plane_co=co_l, plane_no=no_l,
                                   clear_inner=manter_positivo, clear_outer=not manter_positivo)
        borda = [e for e in r["geom_cut"] if isinstance(e, bmesh.types.BMEdge)]
        if borda:
            bmesh.ops.holes_fill(bm, edges=borda, sides=0)
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        bm.to_mesh(obj.data); bm.free(); obj.data.update()
    return copia


def prepare_animation(coll, ox, oy):
    """Marca as peças animadas de uma skin já montada (coleção `coll`, centro em ox, oy).
    Cria um Empty CTRL_<skin>_<grupo> no pivô com as peças como filhas (para mexer no Blender)
    e grava em cada peça animation_group e animation_pivot_world (lido pelo export)."""
    spec = ANIM.get(coll.name)
    if not spec or coll.get("animation_ready"):
        return []
    bpy.context.view_layer.update()
    por_numero = {}
    for o in coll.objects:
        n = _numero(o)
        if o.type == "MESH" and n is not None:
            por_numero.setdefault(n, o)
    controles = []
    for grupo, g in spec.items():
        objs = []
        for n in g["pecas"]:
            o = por_numero.get(n)
            assert o is not None, f"{coll.name}: peça {n} do grupo {grupo} não existe"
            if g.get("corte"):
                px, py = g["corte"]["ponto"]
                o = _cortar(o, (ox + px, oy + py), g["corte"]["normal"])
                assert len(o.data.vertices) > 0, f"{coll.name}: corte de {grupo} vazio"
            objs.append(o)
        if g.get("corte"):
            p, nrm = Vector((*g["corte"]["ponto"], 0)), Vector((*g["corte"]["normal"], 0))
            for n in g.get("pecas_no_lado", []):
                o = por_numero.get(n)
                c = _centro_caixa([o]) - Vector((ox, oy, 0))
                c.z = 0
                if (c - p).dot(nrm) > 0:
                    objs.append(o)
        if g["pivo"] is None:
            pivo = _centro_caixa(objs)
        else:
            pivo = Vector((ox + g["pivo"][0], oy + g["pivo"][1], g["pivo"][2]))
        ctrl = bpy.data.objects.new(f"CTRL_{coll.name}_{grupo}", None)
        coll.objects.link(ctrl)
        ctrl.location = pivo; ctrl.empty_display_size = 0.25; ctrl.empty_display_type = "ARROWS"
        ctrl["animation_control"] = True; ctrl["animation_group"] = grupo
        bpy.context.view_layer.update()
        for o in objs:
            mw = o.matrix_world.copy()
            o.parent = ctrl; o.matrix_parent_inverse = ctrl.matrix_world.inverted(); o.matrix_world = mw
            o["animation_group"] = grupo
            o["animation_pivot_world"] = list(pivo)
        controles.append(ctrl)
    coll["animation_ready"] = True
    bpy.context.view_layer.update()
    return controles


def prepare_all(categoria_corpo=True):
    """Prepara todas as skins com animação que estão na cena (centro: corpo ou capa de baixo)."""
    feitos = []
    for coll in list(bpy.context.scene.collection.children):
        if coll.name not in ANIM:
            continue
        base = bpy.data.objects.get(f"{coll.name}_Body") or bpy.data.objects.get(f"{coll.name}_CapaBaixo")
        pts = [base.matrix_world @ Vector(c) for c in base.bound_box]
        ox = (min(p.x for p in pts) + max(p.x for p in pts)) / 2
        oy = (min(p.y for p in pts) + max(p.y for p in pts)) / 2
        feitos += prepare_animation(coll, ox, oy)
    return feitos
