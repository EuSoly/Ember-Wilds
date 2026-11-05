import bpy,os
from mathutils import Vector
BASE=os.path.dirname(os.path.abspath(__file__))
scene=bpy.data.scenes['Icon_Inspired_Deposits_06'];bpy.context.window.scene=scene
keep=set(scene.objects);cols=set(scene.collection.children_recursive)
for s in list(bpy.data.scenes):
    if s!=scene:bpy.data.scenes.remove(s)
for o in list(bpy.data.objects):
    if o not in keep:bpy.data.objects.remove(o,do_unlink=True)
for c in list(bpy.data.collections):
    if c not in cols:bpy.data.collections.remove(c)
bpy.data.orphans_purge(do_recursive=True)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(BASE,'minerios-icones-editaveis.blend'))
bpy.ops.render.render(write_still=True)
cam=scene.camera;target=Vector((0,2.2,0));cam.location=(0,2.2,60);cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler()
scene.render.filepath=os.path.join(BASE,'comparacao-vista-superior.png');bpy.ops.render.render(write_still=True)
print('ICON_DEPOSITS_READY: six closed editable deposits plus inventory reference copies')
