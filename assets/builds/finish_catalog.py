import bpy,os,json
from mathutils import Vector
BASE=os.path.dirname(__file__)
scene=bpy.data.scenes['Builds_Catalog_24'];bpy.context.window.scene=scene
keep=set(scene.objects)
for s in list(bpy.data.scenes):
    if s!=scene:bpy.data.scenes.remove(s)
for o in list(bpy.data.objects):
    if o not in keep:bpy.data.objects.remove(o,do_unlink=True)
cols=set(scene.collection.children_recursive)
for c in list(bpy.data.collections):
    if c not in cols:bpy.data.collections.remove(c)
bpy.data.orphans_purge(do_recursive=True)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(BASE,'builds-editaveis.blend'))
bpy.ops.render.render(write_still=True)
cam=scene.camera
for row,name in [(1,'espinhos'),(2,'portas'),(3,'portas-com-espinhos')]:
    cy=12-row*8;target=Vector((0,cy+.3,0));cam.location=(0,cy-31,68);cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler()
    scene.render.resolution_x=2400;scene.render.resolution_y=600
    scene.render.filepath=os.path.join(BASE,name+'.png');bpy.ops.render.render(write_still=True)
# Demonstrate opening on the last row without altering the saved closed models.
for o in scene.objects:
    if o.name.endswith(('_panel_left','_panel_right')) and '_spike_door_' in o.name:
        o.location=Vector(o['open_translation'])
bpy.context.view_layer.update()
validation=[]
for col in bpy.data.collections['SpikeDoors'].children:
    left=bpy.data.objects[col.name+'_panel_left'];right=bpy.data.objects[col.name+'_panel_right']
    root=bpy.data.objects[col.name+'_root']
    lv=[root.matrix_world.inverted()@(left.matrix_world@v.co) for v in left.data.vertices]
    rv=[root.matrix_world.inverted()@(right.matrix_world@v.co) for v in right.data.vertices]
    gap=min(v.x for v in rv)-max(v.x for v in lv)
    assert gap>4.5,(col.name,gap)
    validation.append({'item_id':col.name,'open_gap':gap,'details_parented_to_leaf':all(o.parent in [root,left,right] for o in col.objects if o.type=='MESH')})
scene.render.filepath=os.path.join(BASE,'portas-abertas.png');bpy.ops.render.render(write_still=True)
with open(os.path.join(BASE,'door-opening-validation.json'),'w',encoding='utf8') as f:json.dump(validation,f,indent=2)
print('BUILDS_READY: 18 new models, 6 original reference walls, six opening checks passed')
