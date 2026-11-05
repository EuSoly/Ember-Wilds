"""Exporta as 16 comidas (Food/Ingredients) para o Roblox (FBX conjunto + individuais).

Mesmo fluxo validado de assets/weapons/export_roblox.py: cada item vira UMA malha
triangulada com UM material, e as cores sólidas viram uma textura de paleta
256x256 (um quadrado 16x16 por cor), porque o MeshPart do Roblox só tem um material.

Rodar só em Blender de fundo sobre a cópia:
  blender -b export-work/live-snapshot.blend --python export_roblox.py
O .blend editável (food.blend) nunca é alterado.
"""
import bpy, bmesh, json, os, math, struct, zlib
from mathutils import Matrix, Vector

BASE = r"C:\Users\Elize\Desktop\Roblox\starve\assets\resources\food"
OUT = os.path.join(BASE, "roblox")
IND = os.path.join(OUT, "individual")
os.makedirs(IND, exist_ok=True)
NAME = "food"
EXPECTED = 16

drops = bpy.data.collections["Food"]
source_cols = list(drops.children)
assert len(source_cols) == EXPECTED, len(source_cols)


def reveal(lc):
    lc.exclude = False
    lc.hide_viewport = False
    for c in lc.children:
        reveal(c)


reveal(bpy.context.view_layer.layer_collection)
for c in [drops] + source_cols:
    c.hide_viewport = False
    c.hide_render = False
    for o in c.objects:
        o.hide_set(False)
        o.hide_viewport = False
        o.hide_render = False
bpy.context.view_layer.update()
deps = bpy.context.evaluated_depsgraph_get()

palette = []
color_map = {}


def srgb(x):
    x = max(0, min(1, x))
    return int(round(255 * (12.92 * x if x <= .0031308 else 1.055 * x ** (1 / 2.4) - .055)))


def color_index(material):
    node = next((n for n in material.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None)
    assert node and not node.inputs["Base Color"].is_linked, material.name
    key = tuple(srgb(float(x)) for x in node.inputs["Base Color"].default_value[:3]) + (255,)
    if key not in color_map:
        color_map[key] = len(palette)
        palette.append(key)
    return color_map[key]


prepared = []
for c in sorted(source_cols, key=lambda c: c.name):
    root = bpy.data.objects[c.name + "_root"]
    pose = Matrix.Translation(root.matrix_world.translation)
    inverse = pose.inverted()
    vertices, faces, swatches, parts = [], [], [], []
    for o in sorted(c.objects, key=lambda o: o.name):
        if o.type != "MESH":
            continue
        ev = o.evaluated_get(deps)
        m = ev.to_mesh(preserve_all_data_layers=True, depsgraph=deps)
        transform = inverse @ ev.matrix_world
        off = len(vertices)
        vertices.extend(tuple(transform @ v.co) for v in m.vertices)
        for p in m.polygons:
            faces.append(tuple(off + i for i in p.vertices))
            swatches.append(color_index(m.materials[p.material_index]))
        parts.append(o.name)
        ev.to_mesh_clear()
    prepared.append({"id": c.name, "label": root.get("label", c.name), "vertices": vertices,
                     "faces": faces, "swatches": swatches, "pose": pose, "parts": parts})
assert len(palette) <= 256, len(palette)


# PNG com as cores sRGB exatas (sem gestão de cor do image.save()).
def chunk(typ, data):
    return struct.pack(">I", len(data)) + typ + data + struct.pack(">I", zlib.crc32(typ + data) & 0xffffffff)


raw = bytearray()
for y in range(256):
    raw.append(0)
    for x in range(256):
        i = (y // 16) * 16 + x // 16
        raw.extend(palette[i] if i < len(palette) else (255, 255, 255, 255))
png = (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", 256, 256, 8, 6, 0, 0, 0))
       + chunk(b"IDAT", zlib.compress(bytes(raw), 9)) + chunk(b"IEND", b""))
texpath = os.path.join(OUT, "food_palette.png")
with open(texpath, "wb") as f:
    f.write(png)
image = bpy.data.images.load(texpath, check_existing=False)
image.name = "food_palette"
mat = bpy.data.materials.new("food_palette_material")
mat.use_nodes = True
bsdf = next(n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
bsdf.inputs["Roughness"].default_value = .85
tex = mat.node_tree.nodes.new("ShaderNodeTexImage")
tex.image = image
tex.interpolation = "Closest"
mat.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])

outscene = bpy.data.scenes.new("Roblox_Food")
bpy.context.window.scene = outscene
collection = bpy.data.collections.new("Food_Roblox")
outscene.collection.children.link(collection)

records = []
for a in prepared:
    name = a["id"]
    m = bpy.data.meshes.new(name + "_export_mesh")
    m.from_pydata(a["vertices"], [], a["faces"])
    m.update()
    m.materials.append(mat)
    uv = m.uv_layers.new(name="UVMap")
    for p, idx in zip(m.polygons, a["swatches"]):
        cx = ((idx % 16) * 16 + 8) / 256
        cy = 1 - ((idx // 16) * 16 + 8) / 256
        for j, li in enumerate(p.loop_indices):
            ang = 2 * math.pi * j / len(p.loop_indices)
            uv.data[li].uv = (cx + 3 / 256 * math.cos(ang), cy + 3 / 256 * math.sin(ang))
        p.use_smooth = False
    bm = bmesh.new()
    bm.from_mesh(m)
    bmesh.ops.triangulate(bm, faces=list(bm.faces))
    bm.to_mesh(m)
    bm.free()
    m.update()
    obj = bpy.data.objects.new(name, m)
    collection.objects.link(obj)
    obj.matrix_world = a["pose"]
    obj["item_id"] = name
    m.calc_loop_triangles()
    assert len(m.materials) == 1 and len(m.uv_layers) == 1
    dims = [max(v.co[i] for v in m.vertices) - min(v.co[i] for v in m.vertices) for i in range(3)]
    records.append({"item_id": name, "label": a["label"], "triangles": len(m.loop_triangles),
                    "vertices": len(m.vertices), "local_dimensions": dims, "palette_materials": 1,
                    "source_parts": a["parts"], "file": "individual/" + name + ".fbx"})
bpy.context.view_layer.update()

kwargs = {"use_selection": True, "global_scale": 1.0, "apply_unit_scale": True,
          "apply_scale_options": "FBX_SCALE_UNITS", "axis_forward": "Z", "axis_up": "Y",
          "object_types": {"MESH"}, "use_mesh_modifiers": True, "mesh_smooth_type": "FACE",
          "bake_anim": False, "add_leaf_bones": False, "path_mode": "COPY",
          "embed_textures": True, "use_triangles": True}
for o in outscene.objects:
    o.select_set(True)
bpy.context.view_layer.objects.active = next(iter(outscene.objects))
bpy.ops.export_scene.fbx(filepath=os.path.join(OUT, NAME + ".fbx"), **kwargs)
for o in list(outscene.objects):
    for x in outscene.objects:
        x.select_set(False)
    o.select_set(True)
    bpy.context.view_layer.objects.active = o
    pose = o.matrix_world.copy()
    o.matrix_world = Matrix.Identity(4)
    bpy.context.view_layer.update()
    bpy.ops.export_scene.fbx(filepath=os.path.join(IND, o.name + ".fbx"), **kwargs)
    o.matrix_world = pose
bpy.context.view_layer.update()

# .blend só com as malhas de exportação e a textura embutida.
for s in list(bpy.data.scenes):
    if s != outscene:
        bpy.data.scenes.remove(s)
wanted = set(outscene.objects)
for o in list(bpy.data.objects):
    if o not in wanted:
        bpy.data.objects.remove(o, do_unlink=True)
for c in list(bpy.data.collections):
    if c != collection:
        bpy.data.collections.remove(c)
for t in list(bpy.data.texts):
    bpy.data.texts.remove(t)
bpy.data.orphans_purge(do_recursive=True)
image.pack()
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, NAME + "-export.blend"))

manifest = {"format": "FBX", "source": "food.blend (cópia em export-work/live-snapshot.blend)",
            "combined_file": NAME + ".fbx", "texture": "food_palette.png",
            "color_swatches": len(palette), "mesh_count": len(records),
            "total_triangles": sum(r["triangles"] for r in records),
            "settings": {"axis_forward": "Z", "axis_up": "Y", "scale": 1,
                         "apply_scalings": "FBX_SCALE_UNITS", "embedded_textures": True},
            "orientation": "item deitado: no Roblox a face de cima aponta para +Y",
            "individual_origin": "centro do item, base em Y=0",
            "items": records}
with open(os.path.join(OUT, "manifest.json"), "w", encoding="utf8") as f:
    json.dump(manifest, f, indent=2, ensure_ascii=False)
print("EXPORT_RESULT " + json.dumps({"meshes": len(records), "triangles": manifest["total_triangles"],
                                      "colors": len(palette)}))
