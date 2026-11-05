import bpy,os,math
BASE=os.path.dirname(__file__)
scene=bpy.data.scenes['Pickaxes_Preview_06'];bpy.context.window.scene=scene
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
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(BASE,'picaretas-duas-faces.blend'))
bpy.ops.render.render(write_still=True)
# Turn every model over around the shared symmetry plane for a rear-face QA.
# This presentation-only rotation is not saved in the editable file.
for col in bpy.data.collections['Pickaxes'].children:
    root=bpy.data.objects[col.name+'_root']
    root.rotation_euler.y=math.pi;root.rotation_euler.z*=-1;root.location.z+=.30
for o in scene.objects:
    if o.type=='FONT' and o.data.body=='PICARETAS':o.data.body='PICARETAS / VERSO'
scene.render.filepath=os.path.join(BASE,'picaretas-verso.png')
bpy.ops.render.render(write_still=True)
print('TWO_SIDED_PICKAXES_READY')
