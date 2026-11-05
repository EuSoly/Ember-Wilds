# Biblioteca comum das skins de corpo (corpo base, peças planas, montagem e prévias).
# Cada lote fica em lotes/<nome>.py com `from skin_lib import *` e uma lista LOTE.
# Regras em docs/guia/skins-modelagem.md: versões nossas, cores da paleta da referência,
# leitura de cima (câmera a 65°), peças planas, detalhe proporcional à mudança de silhueta.
# Medidas do BonecoConfig; 1 m = 1 stud; frente do boneco = +Y; topo do corpo em z = 2.
import bpy, bmesh, math
from mathutils import Matrix

BW, BH, CR, OUT, DROP = 3.6, 2.0, 0.9, 0.2, 0.1
EYE_D, EYE_X, EYE_Y = 0.95, 0.8, 0.55
HAND_D, HX, HY, HZ = 1.3, 1.95, 1.45, 1.2
TOP, T = 2.0, 0.05

# ---------------------------------------------------------------- utilidades
_mats = {}
def mat(hexc, emit=0.0, alpha=1.0):
    key = (hexc, emit, alpha)
    if key in _mats: return _mats[key]
    m = bpy.data.materials.new("c_" + hexc.lstrip('#') + ("_neon" if emit else "") + ("_a" if alpha < 1 else ""))
    m.use_nodes = True
    b = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    h = hexc.lstrip('#'); rgb = [int(h[i:i+2], 16) / 255 for i in (0, 2, 4)]
    lin = [c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in rgb]
    b.inputs["Base Color"].default_value = (*lin, 1); b.inputs["Roughness"].default_value = 0.8
    if emit:
        b.inputs["Emission Color"].default_value = (*lin, 1); b.inputs["Emission Strength"].default_value = emit
    if alpha < 1:
        b.inputs["Alpha"].default_value = alpha
    m.diffuse_color = (*lin, alpha)
    _mats[key] = m
    return m

def _link(o, coll):
    for c in o.users_collection: c.objects.unlink(o)
    coll.objects.link(o)

RES_CURVA = 8  # pontos por trecho das curvas suavizadas; o export para o Roblox baixa para ficar leve

def catmull(pts, per=None):
    per = per or RES_CURVA
    out = []; n = len(pts)
    for i in range(n):
        p0, p1, p2, p3 = pts[i-1], pts[i], pts[(i+1) % n], pts[(i+2) % n]
        for k in range(per):
            t = k / per; t2, t3 = t*t, t*t*t
            out.append(tuple(0.5 * (2*p1[j] + (-p0[j]+p2[j])*t + (2*p0[j]-5*p1[j]+4*p2[j]-p3[j])*t2 + (-p0[j]+3*p1[j]-3*p2[j]+p3[j])*t3) for j in (0, 1)))
    return out

def offset_poly(P, d):
    # empurra cada ponto para fora pela normal média (contorno das peças planas)
    n = len(P); area = sum(P[i][0]*P[(i+1) % n][1] - P[(i+1) % n][0]*P[i][1] for i in range(n))
    sgn = 1 if area > 0 else -1
    out = []
    for i in range(n):
        a, b, c = P[i-1], P[i], P[(i+1) % n]
        e1 = (b[0]-a[0], b[1]-a[1]); e2 = (c[0]-b[0], c[1]-b[1])
        n1 = (e1[1], -e1[0]); n2 = (e2[1], -e2[0])
        l1 = math.hypot(*n1) or 1; l2 = math.hypot(*n2) or 1
        nx, ny = n1[0]/l1 + n2[0]/l2, n1[1]/l1 + n2[1]/l2
        l = math.hypot(nx, ny) or 1
        out.append((b[0] + sgn*d*nx/l, b[1] + sgn*d*ny/l))
    return out

def ellipse(cx, cy, rx, ry, n=10, rot=0.0):
    c, s = math.cos(rot), math.sin(rot)
    return [(cx + rx*math.cos(a)*c - ry*math.sin(a)*s, cy + rx*math.cos(a)*s + ry*math.sin(a)*c) for a in [2*math.pi*i/n for i in range(n)]]

def mirror_x(P): return [(-x, y) for x, y in P]

class Skin:
    def __init__(self, name, ox, oy, body, outline, hand=None, hand_outline=None):
        self.name, self.ox, self.oy = name, ox, oy
        self.coll = bpy.data.collections.new(name); bpy.context.scene.collection.children.link(self.coll)
        self.body, self.outline = body, outline
        self.hand = hand or body; self.hand_outline = hand_outline or outline
        self.n = 0

    def _name(self, kind): self.n += 1; return f"{self.name}_{kind}_{self.n:02d}"

    def flat(self, pts, z, thick, color, outline=None, ow=0.09, smooth=True, kind="Extra", emit=0.0, alpha=1.0):
        P = catmull(pts) if smooth else list(pts)
        if outline:
            self._prism(offset_poly(P, ow), z - 0.01, thick, mat(outline), kind)
        return self._prism(P, z, thick + (0.005 if outline else 0), mat(color, emit, alpha), kind)

    def _prism(self, P, z, thick, m, kind):
        bm = bmesh.new()
        vs = [bm.verts.new((self.ox + x, self.oy + y, z)) for x, y in P]
        try:
            f = bm.faces.new(vs)
        except ValueError:
            bm.free(); return None
        r = bmesh.ops.extrude_face_region(bm, geom=[f])
        bmesh.ops.translate(bm, vec=(0, 0, thick), verts=[v for v in r["geom"] if isinstance(v, bmesh.types.BMVert)])
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        me = bpy.data.meshes.new("m"); bm.to_mesh(me); bm.free()
        o = bpy.data.objects.new(self._name(kind), me); o.data.materials.append(m); self.coll.objects.link(o)
        return o

    def sym(self, pts, *a, **k):
        # peça dos dois lados (x e -x)
        return [self.flat(pts, *a, **k), self.flat(mirror_x(pts), *a, **k)]

    def sphere(self, loc, scale, color, kind="Extra", emit=0.0):
        bm = bmesh.new(); bmesh.ops.create_uvsphere(bm, u_segments=24, v_segments=12, radius=1)
        me = bpy.data.meshes.new("s"); bm.to_mesh(me); bm.free()
        for p in me.polygons: p.use_smooth = True
        o = bpy.data.objects.new(self._name(kind), me); o.data.materials.append(mat(color, emit))
        o.location = (self.ox + loc[0], self.oy + loc[1], loc[2]); o.scale = scale; self.coll.objects.link(o)
        return o

    def rounded_box(self, name, w, h, r, top_bevel, color):
        bm = bmesh.new(); bmesh.ops.create_cube(bm, size=1)
        bmesh.ops.scale(bm, vec=(w, w, h), verts=bm.verts)
        bmesh.ops.translate(bm, vec=(self.ox, self.oy, h/2), verts=bm.verts)
        ve = [e for e in bm.edges if abs(e.verts[0].co.z - e.verts[1].co.z) > 1e-4]
        bmesh.ops.bevel(bm, geom=ve, offset=r, segments=10, affect='EDGES', profile=0.5)
        te = [e for e in bm.edges if all(abs(v.co.z - h) < 1e-4 for v in e.verts) and not all(abs(f.normal.z) > 0.99 for f in e.link_faces)]
        bmesh.ops.bevel(bm, geom=te, offset=top_bevel, segments=4, affect='EDGES', profile=0.5)
        me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
        for p in me.polygons: p.use_smooth = True
        o = bpy.data.objects.new(name, me); o.data.materials.append(mat(color)); self.coll.objects.link(o)
        return o

    def base(self, body_color=None):
        self.rounded_box(f"{self.name}_Body", BW, BH, CR, 0.18, body_color or self.body)
        self.rounded_box(f"{self.name}_Outline", BW + 2*OUT, BH - DROP, CR + OUT, 0.1, self.outline)
        h = self.sphere((HX, HY, HZ), (HAND_D/2,)*3, self.hand, kind="Hand"); h.name = f"{self.name}_Hand"
        ho = self.sphere((HX, HY, HZ - 0.12), (HAND_D/2 + 0.1, HAND_D/2 + 0.1, HAND_D/2), self.hand_outline, kind="Hand"); ho.name = f"{self.name}_HandOutline"
        for s in (-1, 1):  # olhos só de prévia: no jogo vêm do código
            self.sphere((s*EYE_X, EYE_Y, BH - 0.05), (EYE_D/2, EYE_D/2, 0.12), "#111111", kind="PREVIEW")
            self.sphere((s*EYE_X + 0.15, EYE_Y + 0.15, BH + 0.06), (0.15, 0.15, 0.04), "#FFFFFF", kind="PREVIEW")

    def hand_flat(self, pts, z, thick, color, **k):
        # peça da mão direita; coordenadas relativas ao centro da mão
        return self.flat([(HX + x, HY + y) for x, y in pts], z, thick, color, kind="Hand", **k)

    def finish(self):
        for o in self.coll.objects: o.name = o.name.replace("_PREVIEW_", "_PREVIEW_").replace(f"{self.name}_PREVIEW", f"PREVIEW_{self.name}")
        # prévia da mão esquerda (espelho da direita)
        bpy.context.view_layer.update()  # matrix_world das esferas recém-posicionadas
        M =Matrix.Translation((self.ox, 0, 0)) @ Matrix.Diagonal((-1, 1, 1, 1)) @ Matrix.Translation((-self.ox, 0, 0))
        for o in list(self.coll.objects):
            if "_Hand" in o.name and not o.name.startswith("PREVIEW"):
                d = o.copy(); d.name = "PREVIEW_L_" + o.name; d.matrix_world = M @ o.matrix_world; self.coll.objects.link(d)


# ---------------------------------------------------------------- montagem e prévias

def clear_scene():
    for o in list(bpy.data.objects): bpy.data.objects.remove(o, do_unlink=True)
    for c in list(bpy.data.collections): bpy.data.collections.remove(c)
    for b in (bpy.data.meshes, bpy.data.materials, bpy.data.cameras):
        for x in list(b): b.remove(x)
    _mats.clear()

def build(lote, cols=5, dx=9.0, dy=10.0, clear=True):
    # lote: lista de (nome, função, corpo, contorno, mão, contorno da mão)
    if clear: clear_scene()
    for i, (name, fn, body, outline, hand, hand_out) in enumerate(lote):
        ox = (i % cols - (cols - 1) / 2) * dx; oy = -(i // cols) * dy
        s = Skin(name, ox, oy, body, outline, hand, hand_out)
        fn(s); s.finish()
    return len(bpy.data.objects)

def render_previews(out_prefix, size_per_skin=360, cor="MATERIAL"):
    # Duas imagens: <prefixo>-cima.png (reto de cima) e <prefixo>-65.png (câmera do jogo, de frente).
    from mathutils import Vector
    import math as _m
    objs = [o for o in bpy.data.objects if o.type == "MESH"]
    xs = [ (o.matrix_world @ Vector(c)).x for o in objs for c in o.bound_box ]
    ys = [ (o.matrix_world @ Vector(c)).y for o in objs for c in o.bound_box ]
    cx, cy = (min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2
    w, h = max(xs) - min(xs) + 2, max(ys) - min(ys) + 2
    sc = bpy.context.scene
    try: sc.render.engine = "BLENDER_WORKBENCH"
    except TypeError: pass
    sh = sc.display.shading
    sh.light = "STUDIO"; sh.color_type = cor; sh.show_shadows = True; sh.show_cavity = False
    sc.render.film_transparent = False
    try: sc.view_settings.view_transform = "Standard"
    except TypeError: pass
    sc.world = sc.world or bpy.data.worlds.new("w")
    cam = bpy.data.objects.get("PrevCam") or bpy.data.objects.new("PrevCam", bpy.data.cameras.new("PrevCam"))
    if cam.name not in sc.collection.objects: sc.collection.objects.link(cam)
    cam.data.type = "ORTHO"; sc.camera = cam
    out = []
    for tag, pitch in (("cima", 90), ("65", 65)):
        p = _m.radians(pitch)
        d = Vector((0, _m.cos(p), _m.sin(p)))  # da frente (+Y), descendo
        target = Vector((cx, cy, 1.0))
        cam.location = target + d * 60
        # de cima: +Y (frente) para cima e +X para a direita, sem espelhar
        cam.rotation_euler = (0.0, 0.0, 0.0) if pitch == 90 else (-d).to_track_quat('-Z', 'Y').to_euler()
        hh = h * _m.sin(p) + 2.5 * _m.cos(p)
        cam.data.ortho_scale = max(w, hh)
        aspect = w / hh
        sc.render.resolution_x = int(size_per_skin * w / 9.0); sc.render.resolution_y = max(200, int(sc.render.resolution_x / aspect))
        sc.render.resolution_percentage = 100
        path = f"{out_prefix}-{tag}.png"
        sc.render.filepath = path; bpy.ops.render.render(write_still=True)
        out.append(path)
    return out
