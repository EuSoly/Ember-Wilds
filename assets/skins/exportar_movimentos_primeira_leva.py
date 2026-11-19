"""Blender -b --factory-startup -P assets/skins/exportar_movimentos_primeira_leva.py"""
import json
from pathlib import Path

import bpy
from mathutils import Matrix, Vector


pasta = Path(__file__).resolve().parent / "roblox" / "primeira_leva"
saida = pasta / "movimentos"
saida.mkdir(exist_ok=True)
skins = json.loads((pasta / "manifest.json").read_text(encoding="utf8"))["skins"]
clips = {
    "body_lula": [("repouso", 1, 49), ("deslocamento_e_parada", 49, 98)],
    "crate_kraken": [("revelar", 89, 104)],
    "crate_aventureiro": [("revelar", 89, 104)],
    "body_explorador": [("consultar", 105, 145)],
    "book_bussola": [("consultar", 105, 145)],
}
bpy.ops.wm.open_mainfile(filepath=str(pasta / "primeira-leva-animacao.blend"))
amostras = {}
for f in range(1, 146):
    bpy.context.scene.frame_set(f)
    amostras[f] = {o.name: tuple(o.rotation_euler) for o in bpy.context.scene.objects
                   if o.name.startswith(("CTRL_", "Raiz_"))}

for skin in skins:
    sid = skin["id"]
    if sid not in clips:
        continue
    bpy.ops.wm.open_mainfile(filepath=str(pasta / "skins-primeira_leva-export.blend"))
    raiz = bpy.data.objects[sid]
    raiz.location = (0, 0, 0)
    bpy.context.view_layer.update()
    arm = bpy.data.armatures.new(sid)
    rig = bpy.data.objects.new(sid + "_rig", arm)
    bpy.context.scene.collection.objects.link(rig)
    bpy.context.view_layer.objects.active = rig
    rig.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    bones = {}
    def junta(nome, ponto):
        b = arm.edit_bones.new(nome)
        b.head = ponto
        b.tail = Vector(ponto) + Vector((0, .2, 0))
        return b
    bones["raiz"] = junta("raiz", (0, 0, 0))
    for part in skin["parts"]:
        g = part.get("animation_group")
        if g and g not in bones:
            bones[g] = junta(g, part["offset_do_pivo_do_skin"])
    for g, b in bones.items():
        if g != "raiz":
            pai = "tentaculo_" + g[-2:] if sid == "body_lula" and g.startswith("ponta_") else "espiral" if g.startswith("nervura_") else "raiz"
            b.parent = bones[pai]
    bpy.ops.object.mode_set(mode="OBJECT")
    malhas = []
    for part in skin["parts"]:
        obj = bpy.data.objects[part["name"]]
        mundo = obj.matrix_world.copy()
        obj.parent = rig
        obj.matrix_parent_inverse = Matrix.Identity(4)
        obj.matrix_world = mundo
        grupo = obj.vertex_groups.new(name=part.get("animation_group") or "raiz")
        grupo.add(list(range(len(obj.data.vertices))), 1, "REPLACE")
        mod = obj.modifiers.new("Movimento", "ARMATURE")
        mod.object = rig
        malhas.append(obj)
    bpy.ops.object.select_all(action="DESELECT")
    for obj in [rig, *malhas]:
        obj.select_set(True)
    cena = bpy.context.scene
    cena.render.fps = 24
    for nome, inicio, fim in clips[sid]:
        rig.animation_data_clear()
        cena.frame_start, cena.frame_end = 1, fim-inicio+1
        for f in range(inicio, fim+1):
            for bone in rig.pose.bones:
                ctrl = ("Raiz_" + skin["nome"] if bone.name == "raiz" else
                        "CTRL_" + skin["nome"] + "_" + bone.name)
                bone.rotation_mode = "XYZ"
                bone.rotation_euler = amostras[f][ctrl]
                bone.keyframe_insert("rotation_euler", frame=f-inicio+1)
        rig.animation_data.action.name = sid + "_" + nome
        bpy.ops.export_scene.fbx(filepath=str(saida / (sid+"_"+nome+".fbx")),
                                 use_selection=True, object_types={"MESH", "ARMATURE"},
                                 add_leaf_bones=False, bake_anim_use_nla_strips=False,
                                 bake_anim_use_all_actions=False, bake_anim_simplify_factor=0,
                                 path_mode="COPY", embed_textures=True, use_custom_props=False)
for sid, cortes in clips.items():
    for nome, inicio, fim in cortes:
        bpy.ops.wm.read_factory_settings(use_empty=True)
        bpy.context.scene.render.fps = 24
        bpy.ops.import_scene.fbx(filepath=str(saida / (sid+"_"+nome+".fbx")), anim_offset=1)
        rig, = [o for o in bpy.context.scene.objects if o.type == "ARMATURE"]
        assert rig.animation_data and rig.animation_data.action
        a, b = rig.animation_data.action.frame_range
        assert abs((b-a) - (fim-inicio)) < .05, (sid, nome, a, b)
        assert all(o.vertex_groups and any(m.type == "ARMATURE" for m in o.modifiers)
                   for o in bpy.context.scene.objects if o.type == "MESH")
print("Seis FBXs de movimento reimportados.")
