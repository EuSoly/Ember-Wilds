import bpy,os
from mathutils import Vector
BASE=os.path.dirname(__file__);scene=bpy.context.scene
chosen=['diamond_spike_door','amethyst_spike_door','reidite_spike_door']
shown=set()
for i,name in enumerate(chosen):
    col=bpy.data.collections[name];shown.update(col.objects)
    root=bpy.data.objects[name+'_root'];root.location=(-13+i*13,0,0)
    for side in ['left','right']:
        leaf=bpy.data.objects[name+'_panel_'+side];leaf.location=Vector(leaf['open_translation'])
for o in scene.objects:
    if o.type=='MESH' and o.name!='Build_Backdrop':o.hide_render=o not in shown
    if o.type=='FONT':o.hide_render=True
for i,label in enumerate(['DIAMANTE / ABERTA','AMETISTA / ABERTA','REIDITE / ABERTA']):
    d=bpy.data.curves.new(label,'FONT');d.body=label;d.size=.40;d.align_x=next(e.identifier for e in d.bl_rna.properties['align_x'].enum_items if e.identifier=='CENTER')
    o=bpy.data.objects.new(label,d);scene.collection.objects.link(o);o.location=(-13+i*13,-4.1,.02);d.materials.append(bpy.data.materials['Build_text'])
cam=scene.camera;cam.location=(0,-31,68);cam.rotation_euler=(Vector((0,0,0))-cam.location).to_track_quat('-Z','Y').to_euler()
scene.render.resolution_x=2100;scene.render.resolution_y=650;scene.render.filepath=os.path.join(BASE,'portas-abertas.png')
bpy.ops.render.render(write_still=True)
