"""Run in background Blender: isolate deliverable, render previews, check pivots."""
import bpy,os,json,math
from mathutils import Vector
BASE=os.path.dirname(os.path.abspath(__file__))
scene=bpy.data.scenes['Structures_Catalog_18'];bpy.context.window.scene=scene
keep=set(scene.objects);cols=set(scene.collection.children_recursive)
for s in list(bpy.data.scenes):
    if s!=scene:bpy.data.scenes.remove(s)
for o in list(bpy.data.objects):
    if o not in keep:bpy.data.objects.remove(o,do_unlink=True)
for c in list(bpy.data.collections):
    if c not in cols:bpy.data.collections.remove(c)
bpy.data.orphans_purge(do_recursive=True)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(BASE,'structures-editaveis.blend'))
bpy.ops.render.render(write_still=True)

cam=scene.camera
def render(name,target,scale,width,height,eye=(0,-22,32)):
    target=Vector(target);cam.location=target+Vector(eye);cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=scale
    scene.render.resolution_x=width;scene.render.resolution_y=height;scene.render.filepath=os.path.join(BASE,name+'.png')
    bpy.ops.render.render(write_still=True)
render('extratores',(0,13,.3),35.5,2300,650)
render('fogueiras',(0,5,.3),22,1800,650)

# Verify independent moving parts, then render the chest open with neighbouring props hidden.
validation=[]
hinge=bpy.data.objects['chest_lid_hinge'];children=list(hinge.children)
before={o.name:o.matrix_world.copy() for o in children}
hinge.rotation_euler.x=math.radians(hinge['open_angle_degrees']);bpy.context.view_layer.update()
assert len(children)==5,len(children)
assert all((o.matrix_world.translation-before[o.name].translation).length>.1 for o in children)
body=bpy.data.objects['chest_wall_long_1'];assert body.parent.name=='chest_root'
validation.append({'model':'chest','open_angle_degrees':hinge['open_angle_degrees'],'lid_parts_follow_hinge':len(children),'body_independent':True})
for tier in ['stone','gold','diamond','amethyst','reidite']:
    rotor=bpy.data.objects[tier+'_extractor_rotor'];assert len(rotor.children)==3
    rotor.rotation_euler.z=.4;bpy.context.view_layer.update()
    assert all(o.parent==rotor for o in rotor.children)
    validation.append({'model':tier+'_extractor','rotor_parts':len(rotor.children),'rotation_axis':'local Z'})
for col in bpy.data.collections['Utility_Structures'].children_recursive:
    for o in col.objects:
        if o.type=='MESH' and o.get('item_id')!='chest':o.hide_render=True
for o in bpy.data.collections['Structures_Presentation'].objects:
    if o.type=='FONT':o.hide_render=True
render('bau-aberto',(-7,-3,1.45),6.2,1200,1050,eye=(6,-10,8))
with open(os.path.join(BASE,'animation-validation.json'),'w',encoding='utf8') as f:json.dump(validation,f,indent=2)
print('STRUCTURES_READY: clean editable file, 18 models, opening and rotor checks passed')
