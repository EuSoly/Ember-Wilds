"""Renderiza os recortes da vitrine, na raiz do repo: blender -b -P este_arquivo."""
from pathlib import Path
from math import radians, cos, sin
import bpy
from mathutils import Vector

OUTPUT = Path(__file__).resolve().parent
SKINS = OUTPUT.parents[2] / "skins"
ITEMS = {
    "mare_profunda": [
        ("personagem", "lula"),
        ("caixa", "kraken"),
        ("mochila", "caranguejo"),
        ("livro", "tentaculo"),
    ],
    "bosque_desperto": [
        ("personagem", "toco"),
        ("caixa", "jardim"),
        ("mochila", "cubos_esmeralda"),
        ("livro", "trepadeira"),
    ],
    "norte_perdido": [
        ("personagem", "explorador"),
        ("caixa", "aventureiro"),
        ("mochila", "cartografo"),
        ("livro", "bussola"),
    ],
}


import importlib
import sys

sys.path[:0] = [str(SKINS), str(SKINS / "lotes")]
import primeira_leva as wave


def load_collection(asset):
    category, module, name = next(item for item in wave.ITENS if item[2] == asset)
    source = next(item for item in importlib.import_module(module).LOTE if item[0] == name)
    def build(model):
        source[1](model)
        if name in ("tentaculo", "toco", "trepadeira"):
            wave.skin_animacao.prepare_animation(model.coll, 0, 0)
        if name in wave.AJUSTES:
            wave.AJUSTES[name](model)
    wave.BUILD[category]([(name, build, *source[2:])], cols=1)
    return bpy.data.collections[name]

def render(role, asset, target):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    coll = load_collection(asset)
    for obj in list(coll.all_objects):
        if obj and role != "personagem" and "PREVIEW" in obj.name:
            obj.hide_render = True
    bpy.context.view_layer.update()
    pts = [obj.matrix_world @ Vector(corner) for obj in coll.all_objects
           if obj and obj.type in ("MESH", "CURVE") and not obj.hide_render
           for corner in obj.bound_box]
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.samples = 12
    sc.cycles.use_denoising = True
    sc.render.threads_mode = "FIXED"
    sc.render.threads = 6
    sc.view_settings.view_transform = "Standard"
    sc.render.film_transparent = True
    sc.render.resolution_x = sc.render.resolution_y = 440
    sc.render.resolution_percentage = 100
    world = bpy.data.worlds.new("studio")
    sc.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes["Background"]
    bg.inputs[0].default_value = (.65, .7, .78, 1)
    bg.inputs[1].default_value = .9
    center = sum(pts, Vector()) / len(pts)
    angle = radians(62 if role == "personagem" else 60)
    direction = Vector((-.09, cos(angle), sin(angle))).normalized()
    camera = bpy.data.objects.new("Camera", bpy.data.cameras.new("Camera"))
    sc.collection.objects.link(camera)
    sc.camera = camera
    rotation = (-direction).to_track_quat("-Z", "Y")
    camera.rotation_euler = rotation.to_euler()
    u = rotation @ Vector((1, 0, 0))
    v = rotation @ Vector((0, 1, 0))
    xx = [(p-center).dot(u) for p in pts]
    yy = [(p-center).dot(v) for p in pts]
    center += u*(min(xx)+max(xx))/2 + v*(min(yy)+max(yy))/2
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = max(max(xx)-min(xx), max(yy)-min(yy)) * 1.055
    camera.location = center + direction*30
    for offset, energy, size in [((-5, 3, 8), 700, 7), ((4, -2, 6), 420, 6)]:
        light = bpy.data.lights.new("softbox", "AREA")
        light.energy, light.shape, light.size = energy, "DISK", size
        obj = bpy.data.objects.new("softbox", light)
        sc.collection.objects.link(obj)
        obj.location = center + Vector(offset)
        obj.rotation_euler = (center-obj.location).to_track_quat("-Z", "Y").to_euler()
    sc.render.filepath = str(target)
    bpy.ops.render.render(write_still=True)
    print("EXPORTED", target, flush=True)


roles = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
for bundle, items in ITEMS.items():
    dest = OUTPUT / bundle
    dest.mkdir(parents=True, exist_ok=True)
    for role, asset in items:
        if not roles or role in roles:
            render(role, asset, dest / (role + ".png"))

