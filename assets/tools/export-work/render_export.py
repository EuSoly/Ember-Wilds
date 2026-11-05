import bpy,os
from mathutils import Vector
scene=bpy.context.scene
base=r'C:\Users\Elize\Desktop\Roblox\starve\assets\tools\roblox'
data=bpy.data.cameras.new('ExportPreviewCamera');cam=bpy.data.objects.new(data.name,data);scene.collection.objects.link(cam)
cam.location=(0,1.5,28);target=Vector((0,4.5,0));cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler()
data.type=next(e.identifier for e in data.bl_rna.properties['type'].enum_items if e.identifier=='ORTHO');data.ortho_scale=22;scene.camera=cam
w=bpy.data.worlds.new('ExportPreviewWorld');w.use_nodes=True;n=next(n for n in w.node_tree.nodes if n.type=='BACKGROUND');n.inputs['Color'].default_value=(.15,.19,.22,1);n.inputs['Strength'].default_value=.7;scene.world=w
for name,loc,power in [('Key',(-8,10,15),2800),('Fill',(8,0,13),1800)]:
    d=bpy.data.lights.new(name,'AREA');o=bpy.data.objects.new(name,d);scene.collection.objects.link(o);o.location=loc;o.rotation_euler=(target-o.location).to_track_quat('-Z','Y').to_euler();d.energy=power;d.size=11
try:scene.render.engine='CYCLES'
except TypeError:pass
if scene.render.engine=='CYCLES':scene.cycles.samples=16
scene.render.resolution_x=1600;scene.render.resolution_y=1600;scene.render.resolution_percentage=100
scene.render.image_settings.file_format=next(e.identifier for e in scene.render.image_settings.bl_rna.properties['file_format'].enum_items if e.identifier=='PNG')
scene.render.filepath=os.path.join(base,'preview.png');bpy.ops.render.render(write_still=True)
