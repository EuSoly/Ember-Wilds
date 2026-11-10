"""Refresh review images for the two refined costumes in the same .blend."""
import bpy,runpy,json,math
from pathlib import Path
from mathutils import Vector,Matrix
BASE=Path(r"C:\Users\Elize\Desktop\Roblox\starve\assets\armor")
p=runpy.run_path(str(BASE/"present_wearables.py"))
p["render"]("01 Frio e calor")
p["render"]("02 Especiais")
# Update only revised catalog records.
catalog=json.loads((BASE/"wearable-catalog.json").read_text(encoding="utf-8"))
checks=[]
for id,group in [("ninja","01 Frio e calor"),("witch","02 Especiais")]:
    scene=bpy.data.scenes["Armaduras - "+group];bpy.context.window.scene=scene;bpy.context.view_layer.update()
    root=bpy.data.objects["wear_"+id];deps=bpy.context.evaluated_depsgraph_get();tri=0;bounds=[]
    for ob in root.children_recursive:
        if ob.type in {'MESH','CURVE'}:
            ev=ob.evaluated_get(deps);me=ev.to_mesh()
            tri+=sum(len(f.vertices)-2 for f in me.polygons)
            bounds.extend(root.matrix_world.inverted()@ob.matrix_world@v.co for v in me.vertices)
            ev.to_mesh_clear()
    rec=next(r for r in catalog if r["id"]==id)
    rec.update(design=root["design"],preview_triangles=tri,bounds_local=[[min(v[i] for v in bounds) for i in range(3)],[max(v[i] for v in bounds) for i in range(3)]],revision=root["revision"])
    # Check line of sight to both original player eye centres at review angle.
    for eye in [o for o in bpy.data.collections["MAN_"+id].objects if "EyeOpen" in o.name]:
        target=eye.matrix_world.translation
        direction=Vector((0,5,9)).normalized()
        hit,loc,norm,index,ob,matrix=scene.ray_cast(deps,target+direction*15,-direction,distance=16)
        checks.append({"item":id,"eye":eye.name,"first_hit":ob.name if hit else None,"visible":bool(hit and ("EyeOpen" in ob.name or "EyeShine" in ob.name))})
(BASE/"wearable-catalog.json").write_text(json.dumps(catalog,ensure_ascii=False,indent=2),encoding="utf-8")
(BASE/"refino-ninja-bruxa-validation.json").write_text(json.dumps(checks,indent=2),encoding="utf-8")
print("EYE CHECKS",json.dumps(checks))
# Linked collection instances keep this close-up preview in sync with originals.
scene=bpy.data.scenes.new("Revisao - Ninja e Bruxa")
bpy.context.window.scene=scene
scene.world=bpy.data.scenes["Armaduras - 01 Frio e calor"].world.copy()
for id,title,pos in [("ninja","NINJA",(0,0,0)),("witch","BRUXA",(-7.5,0,0))]:
    offset=Vector(pos)-bpy.data.objects["wear_"+id].location
    for name in ["VEST_"+id,"MAN_"+id]:
        ob=bpy.data.objects.new("Review "+name,None);scene.collection.objects.link(ob)
        ob.instance_type='COLLECTION';ob.instance_collection=bpy.data.collections[name];ob.location=offset
    cu=bpy.data.curves.new("Review label "+title,"FONT");cu.body=title;cu.align_x='CENTER';cu.size=.40
    label=bpy.data.objects.new("Review label "+title,cu);scene.collection.objects.link(label)
    label.location=Vector(pos)+Vector((0,3.4,-.85));label.rotation_euler.z=math.pi;cu.materials.append(bpy.data.materials["Galeria - letras creme"])
center=Vector((-3.75,.2,.65))
bpy.ops.object.camera_add(location=center+Vector((0,8,15)))
cam=bpy.context.object;cam.name="Camera - Ninja e Bruxa"
cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler()
cam.data.type='ORTHO';cam.data.ortho_scale=14.7;scene.camera=cam
for name,pos,power,size in [("Principal",(-8,5,10),1800,7),("Preenchimento",(2,3,8),1300,6),("Recorte",(-3,-7,9),1700,6)]:
    bpy.ops.object.light_add(type='AREA',location=pos);ob=bpy.context.object;ob.name="Review "+name
    ob.data.energy=power;ob.data.size=size;ob.rotation_euler=(center-ob.location).to_track_quat('-Z','Y').to_euler()
scene.render.resolution_x=1700;scene.render.resolution_y=1100;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG';scene.render.filepath=str(BASE/"ninja-bruxa-refinados.png")
for area in bpy.context.screen.areas:
    if area.type=='VIEW_3D':
        sp=area.spaces.active;sp.region_3d.view_location=center;sp.region_3d.view_rotation=cam.rotation_euler.to_quaternion();sp.region_3d.view_distance=17
        sp.region_3d.view_perspective='ORTHO';sp.shading.type='MATERIAL';sp.overlay.show_extras=False;sp.overlay.show_relationship_lines=False
bpy.ops.object.select_all(action='DESELECT')
doc=bpy.data.texts.get("LEIA-ME - Armaduras")
doc.write("\n\nREFINO v02: mascara ninja refeita em pano envolvente; chapeu de bruxa com aba oval ondulada e copa curva. Preview na cena Revisao - Ninja e Bruxa.\n")
bpy.ops.render.render(write_still=True)
bpy.ops.wm.save_as_mainfile(filepath=str(BASE/"capacete-madeira-v01.blend"))
print("SAVED",bpy.data.filepath,scene.render.filepath)

