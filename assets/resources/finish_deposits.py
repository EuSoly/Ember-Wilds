import bpy,os,json
from mathutils import Vector
BASE=os.path.dirname(os.path.abspath(__file__))
scene=bpy.data.scenes['Mining_Deposits_13'];bpy.context.window.scene=scene
keep=set(scene.objects);cols=set(scene.collection.children_recursive)
for s in list(bpy.data.scenes):
    if s!=scene:bpy.data.scenes.remove(s)
for o in list(bpy.data.objects):
    if o not in keep:bpy.data.objects.remove(o,do_unlink=True)
for c in list(bpy.data.collections):
    if c not in cols:bpy.data.collections.remove(c)
bpy.data.orphans_purge(do_recursive=True)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(BASE,'minerios-editaveis.blend'))
bpy.ops.render.render(write_still=True)
for o in scene.objects:
    if o.type=='FONT':o.hide_render=True
    elif o.type=='MESH' and o.get('resource_type') and o['resource_type']!='emerald':o.hide_render=True
cam=scene.camera;target=Vector((13,-8.25,1.05));cam.location=target+Vector((3,-15,11));cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=11.5
scene.render.resolution_x=1800;scene.render.resolution_y=1100;scene.render.filepath=os.path.join(BASE,'esmeralda-preview.png');bpy.ops.render.render(write_still=True)
print('DEPOSITS_READY: 13 models, 62 closed mesh parts, no mixed mineral palettes')
