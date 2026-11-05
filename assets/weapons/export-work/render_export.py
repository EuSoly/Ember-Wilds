import bpy,os,math
from mathutils import Vector
base=r"C:\Users\Elize\Desktop\Roblox\starve\assets\weapons\roblox"
scene=bpy.context.scene
camdata=bpy.data.cameras.new("PreviewCamera");cam=bpy.data.objects.new("PreviewCamera",camdata);scene.collection.objects.link(cam)
cam.location=(-.2,-3,22);target=Vector((-.2,.5,0));cam.rotation_euler=(target-cam.location).to_track_quat("-Z","Y").to_euler()
camdata.type=next(e.identifier for e in camdata.bl_rna.properties["type"].enum_items if e.identifier=="ORTHO")
camdata.ortho_scale=19.5;scene.camera=cam
world=bpy.data.worlds.new("PreviewWorld");world.use_nodes=True
bg=next(n for n in world.node_tree.nodes if n.type=="BACKGROUND");bg.inputs["Color"].default_value=(.24,.27,.30,1);bg.inputs["Strength"].default_value=.65;scene.world=world
for name,location,power in [("Key",(-6,4,14),2200),("Fill",(6,-2,10),900)]:
    d=bpy.data.lights.new(name,"AREA");o=bpy.data.objects.new(name,d);scene.collection.objects.link(o);o.location=location;o.rotation_euler=(target-o.location).to_track_quat("-Z","Y").to_euler();d.energy=power;d.size=10
try:scene.render.engine="CYCLES"
except TypeError:pass
if scene.render.engine=="CYCLES":scene.cycles.samples=24
scene.render.film_transparent=False
scene.render.resolution_x=1500;scene.render.resolution_y=1050;scene.render.resolution_percentage=100
scene.render.filepath=os.path.join(base,"preview.png")
scene.render.image_settings.file_format=next(e.identifier for e in scene.render.image_settings.bl_rna.properties["file_format"].enum_items if e.identifier=="PNG")
bpy.ops.render.render(write_still=True)
print("PREVIEW "+scene.render.filepath)

