"""Valida o FBX conjunto e os 16 individuais reimportando no Blender.

Rodar em Blender de fundo sobre o .blend de exportação:
  blender -b roblox/food-export.blend --python validate_roblox_export.py
"""
import bpy, json, os

BASE = r"C:\Users\Elize\Desktop\Roblox\starve\assets\resources\food\roblox"
manifest = json.load(open(os.path.join(BASE, "manifest.json"), encoding="utf8"))
expected = {w["item_id"]: w for w in manifest["items"]}
N = len(expected)


def bounds(o):
    vv = [o.matrix_world @ v.co for v in o.data.vertices]
    return [min(v[i] for v in vv) for i in range(3)] + [max(v[i] for v in vv) for i in range(3)]


source_bounds = {o.name: bounds(o) for o in bpy.context.scene.objects if o.type == "MESH"}
assert len(source_bounds) == N
report = {"combined": None, "individual": []}


def check_mesh(o, e):
    o.data.calc_loop_triangles()
    assert len(o.data.loop_triangles) == e["triangles"], (o.name, len(o.data.loop_triangles), e["triangles"])
    assert len(o.data.materials) == 1, (o.name, "material count")
    assert len(o.data.uv_layers) >= 1, (o.name, "UV missing")
    textures = [n.image for n in o.data.materials[0].node_tree.nodes if n.type == "TEX_IMAGE" and n.image]
    assert any(list(im.size) == [256, 256] for im in textures), (o.name, "texture")
    return {"name": o.name, "triangles": len(o.data.loop_triangles), "materials": 1, "uv": True, "texture": True}


bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=os.path.join(BASE, manifest["combined_file"]))
objs = list(bpy.context.scene.objects)
assert len(objs) == N and all(o.type == "MESH" for o in objs), [(o.name, o.type) for o in objs]
assert set(o.name for o in objs) == set(expected)
err = 0.0
for o in objs:
    check_mesh(o, expected[o.name])
    err = max(err, max(abs(a - b) for a, b in zip(bounds(o), source_bounds[o.name])))
assert err < .0001, err
report["combined"] = {"meshes": N, "geometry_bounds_max_error": err, "materials_and_textures_valid": True}
for name, e in expected.items():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=os.path.join(BASE, e["file"]))
    objs = list(bpy.context.scene.objects)
    assert len(objs) == 1 and objs[0].type == "MESH" and objs[0].name == name, (name, [o.name for o in objs])
    o = objs[0]
    item = check_mesh(o, e)
    bb = bounds(o)
    dims = [bb[i + 3] - bb[i] for i in range(3)]
    delta = max(abs(a - b) for a, b in zip(dims, e["local_dimensions"]))
    assert delta < .0001, (name, delta)
    assert o.matrix_world.translation.length < .0001, (name, "pivot")
    item["scale_error"] = delta
    item["pivot_at_origin"] = True
    report["individual"].append(item)
with open(os.path.join(BASE, "validation.json"), "w", encoding="utf8") as f:
    json.dump(report, f, indent=2)
print("VALIDATION_RESULT " + json.dumps({"combined": report["combined"], "individual_files_passed": len(report["individual"])}))
