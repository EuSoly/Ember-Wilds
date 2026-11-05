import bpy,os,math
from mathutils import Vector,Matrix
BASE=os.path.dirname(__file__)
scene=bpy.data.scenes['Tools_Catalog_23'];bpy.context.window.scene=scene
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
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(BASE,'ferramentas-23-editaveis.blend'))
bpy.ops.render.render(write_still=True)
# Family closeups use the same model geometry and lighting, just another camera crop.
camera=scene.camera;oldcam=camera.matrix_world.copy();oldscale=camera.data.ortho_scale
for row,name in enumerate(['martelos','pas-e-forcados','escudos','utilitarios']):
    cy=8.5-row*4-.18
    camera.location=(0,cy-3,28);camera.rotation_euler=(Vector((0,cy,0))-camera.location).to_track_quat('-Z','Y').to_euler()
    camera.data.ortho_scale=21.5
    scene.render.resolution_x=2400;scene.render.resolution_y=490
    scene.render.filepath=os.path.join(BASE,name+'.png');bpy.ops.render.render(write_still=True)
# Rear QA: each object is turned over locally. Back faces retain materials and bevels.
camera.matrix_world=oldcam;camera.data.ortho_scale=oldscale
scene.render.resolution_x=1600;scene.render.resolution_y=1333
for group in bpy.data.collections['Tools'].children:
    for col in group.children:
        root=bpy.data.objects[col.name+'_root']
        root.matrix_world=root.matrix_world @ Matrix.Rotation(math.pi,4,'Y')
scene.render.filepath=os.path.join(BASE,'ferramentas-verso.png');bpy.ops.render.render(write_still=True)
print('TOOLS_CATALOG_READY')
