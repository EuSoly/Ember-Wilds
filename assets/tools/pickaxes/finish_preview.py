import bpy,os
BASE=os.path.dirname(__file__)
scene=bpy.data.scenes['Pickaxes_Preview_06']
bpy.context.window.scene=scene
keep=set(scene.objects)
for s in list(bpy.data.scenes):
    if s!=scene:bpy.data.scenes.remove(s)
for o in list(bpy.data.objects):
    if o not in keep:bpy.data.objects.remove(o,do_unlink=True)
keep_cols=set(scene.collection.children_recursive)
for c in list(bpy.data.collections):
    if c not in keep_cols:bpy.data.collections.remove(c)
for data in (bpy.data.meshes,bpy.data.materials,bpy.data.curves,bpy.data.worlds,bpy.data.cameras,bpy.data.lights):
    for d in list(data):
        if d.users==0:data.remove(d)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(BASE,'picaretas-preview.blend'))
bpy.ops.render.render(write_still=True)
print('PICKAXES_READY',len(bpy.data.collections['Pickaxes'].all_objects))
