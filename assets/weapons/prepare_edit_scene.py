import bpy
from mathutils import Vector, Quaternion

def prepare():
    active = bpy.context.active_object
    if bpy.context.mode != 'OBJECT':
        bpy.ops.object.mode_set(mode=next(i.identifier for i in bpy.ops.object.mode_set.get_rna_type().properties['mode'].enum_items if i.identifier == 'OBJECT'))
    edit = bpy.data.scenes.get('Armas_Editar_18') or bpy.data.scenes.new('Armas_Editar_18')
    for name in ('01 | ESPADAS - 9 modelos', '02 | LANCAS - 9 modelos'):
        group = bpy.data.collections.get(name)
        if group and group.name not in edit.collection.children:
            edit.collection.children.link(group)
    bpy.context.window.scene = edit
    for obj in edit.objects:
        obj.select_set(False)
    if active and active.name in edit.objects and active.type == 'MESH':
        active.hide_set(False)
        active.select_set(True)
        bpy.context.view_layer.objects.active = active
    for area in bpy.context.screen.areas:
        if area.type == 'CONSOLE':
            area.type = next(i.identifier for i in area.bl_rna.properties['type'].enum_items if i.identifier == 'VIEW_3D')
        if area.type == 'VIEW_3D':
            space = area.spaces.active
            space.overlay.show_overlays = True
            space.overlay.show_relationship_lines = False
            space.region_3d.view_perspective = next(i.identifier for i in space.region_3d.bl_rna.properties['view_perspective'].enum_items if i.identifier == 'ORTHO')
            space.region_3d.view_rotation = Quaternion((1, 0, 0, 0))
            space.region_3d.view_location = active.matrix_world.translation if active else Vector((0, 0, 0))
            space.region_3d.view_distance = 5.5
            space.shading.type = next(i.identifier for i in space.shading.bl_rna.properties['type'].enum_items if i.identifier == 'MATERIAL')
    if active and active.type == 'MESH':
        bpy.ops.object.mode_set(mode=next(i.identifier for i in bpy.ops.object.mode_set.get_rna_type().properties['mode'].enum_items if i.identifier == 'EDIT'))
    bpy.ops.wm.save_as_mainfile(filepath=r'C:\Users\Elize\Desktop\Roblox\starve\assets\weapons\armas-colecao-recuperada.blend')
    return None

bpy.app.timers.register(prepare, first_interval=0.5)
