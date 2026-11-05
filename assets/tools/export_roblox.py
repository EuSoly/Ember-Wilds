"""Export the 29 current approved tools using the verified weapons FBX pipeline.
Run only in background Blender on export-work/live-snapshot.blend.
"""
import bpy,os,math
from mathutils import Vector,Quaternion
BASE=r'C:\Users\Elize\Desktop\Roblox\starve\assets\tools'
OUT=os.path.join(BASE,'roblox');os.makedirs(OUT,exist_ok=True)
tools=bpy.data.collections['Tools'];picks=bpy.data.collections['Pickaxes']
assert picks.name not in tools.children
tools.children.link(picks)
scene=bpy.data.scenes.new('Roblox_Tools_Editable_29')
scene.collection.children.link(tools);bpy.context.window.scene=scene
for i,tier in enumerate(['wood','stone','gold','diamond','amethyst','reidite']):
    root=bpy.data.objects[tier+'_pickaxe_root']
    root.location.x=-8.25+i*3.3;root.location.y=12.5
keep=set(scene.objects)
for s in list(bpy.data.scenes):
    if s!=scene:bpy.data.scenes.remove(s)
for o in list(bpy.data.objects):
    if o not in keep:bpy.data.objects.remove(o,do_unlink=True)
keep_cols=set(scene.collection.children_recursive)
for c in list(bpy.data.collections):
    if c not in keep_cols:bpy.data.collections.remove(c)
bpy.data.orphans_purge(do_recursive=True)
for screen in bpy.data.screens:
    for a in screen.areas:
        if a.type=='VIEW_3D':
            sp=a.spaces.active;sp.overlay.show_overlays=True;sp.overlay.show_extras=False
            sp.region_3d.view_perspective=next(e.identifier for e in sp.region_3d.bl_rna.properties['view_perspective'].enum_items if e.identifier=='ORTHO')
            sp.region_3d.view_rotation=Quaternion((1,0,0,0));sp.region_3d.view_location=Vector((0,4.5,0));sp.region_3d.view_distance=26
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT,'picaretas-e-ferramentas-editaveis.blend'))

# Reuse the already round-trip tested palette, UV and FBX conversion.
template=os.path.join(os.path.dirname(BASE),'weapons','export_roblox.py')
code=open(template,encoding='utf8').read()
code=code.replace('weapons','tools').replace('Weapons','Tools')
code=code.replace('==18','==29').replace('Roblox_Tools_18','Roblox_Tools_29')
code=code.replace('espadas-e-lancas','picaretas-e-ferramentas')
code=code.replace('original weapon ROOT, rotation removed; modeled scale retained','grip-centred ROOT; display rotation removed; pickaxe Z offset corrected; modeled scale retained')
needle='    inverse=pose.inverted()'
assert code.count(needle)==1
code=code.replace(needle,"    if c.name.endswith('_pickaxe'):\n        pose=pose@Matrix.Translation((0,0,.15))\n"+needle)
exec(compile(code,'tools_export_pipeline','exec'))
