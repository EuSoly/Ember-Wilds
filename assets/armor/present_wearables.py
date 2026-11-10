"""Review all wearable groups inside the original helmet .blend."""
import bpy,math,json,runpy
from mathutils import Vector,Matrix
from pathlib import Path
BASE=Path(r"C:\Users\Elize\Desktop\Roblox\starve\assets\armor")
GROUPS=runpy.run_path(str(BASE/"build_wearables.py"))["GROUPS"]
def setup():
    for group,rows in GROUPS.items():
        scene=bpy.data.scenes["Armaduras - "+group];bpy.context.window.scene=scene
        cols=3 if len(rows)==3 else 4
        assert not bpy.data.collections.get("STAGE_"+group)
        stage=bpy.data.collections.new("STAGE_"+group);scene.collection.children.link(stage)
        def add(ob):
            for c in list(ob.users_collection):c.objects.unlink(ob)
            stage.objects.link(ob)
        for i,(id,title) in enumerate(rows):
            root=bpy.data.objects["wear_"+id]
            pos=Vector((-(i%cols)*8.2,(i//cols)*9.2,0));delta=pos-root.location;root.location=pos
            for ob in bpy.data.collections["MAN_"+id].objects:ob.location+=delta
            root["gallery_position"]=list(pos)
            cu=bpy.data.curves.new("Label "+title,"FONT");cu.body=title;cu.align_x="CENTER";cu.size=.35 if len(title)>17 else .41
            ob=bpy.data.objects.new("Label "+title,cu);stage.objects.link(ob)
            ob.location=pos+Vector((0,3.55,-.85));ob.rotation_euler.z=math.pi
            cu.materials.append(bpy.data.materials["Galeria - letras creme"])
        rowcount=math.ceil(len(rows)/cols)
        center=Vector((-(cols-1)*8.2/2,(rowcount-1)*9.2/2+.1,.35))
        bpy.ops.object.camera_add(location=center+Vector((0,17,31)))
        cam=bpy.context.object;cam.name="Camera "+group;add(cam)
        cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=34.5 if cols==4 else 25
        scene.camera=cam
        for name,delta,power,size in [("principal",(-9,2,17),8500,15),("preenchimento",(9,7,14),6500,13),("recorte",(0,-12,12),7000,11)]:
            bpy.ops.object.light_add(type="AREA",location=center+Vector(delta));ob=bpy.context.object;ob.name=group+" "+name;add(ob)
            ob.data.energy=power;ob.data.size=size;ob.rotation_euler=(center-ob.location).to_track_quat('-Z','Y').to_euler()
        scene.render.resolution_x=2200 if cols==4 else 1800
        scene.render.resolution_y=1650 if cols==4 else 850;scene.render.resolution_percentage=100
        scene.render.image_settings.file_format='PNG'
        scene.render.filepath=str(BASE/("roupas-"+group[:2]+"-previa.png"))
    bpy.ops.wm.save_as_mainfile(filepath=str(BASE/"capacete-madeira-v01.blend"))
def render(group):
    scene=bpy.data.scenes["Armaduras - "+group];bpy.context.window.scene=scene
    bpy.ops.render.render(write_still=True)
    print(scene.render.filepath)
def frame(group):
    scene=bpy.data.scenes["Armaduras - "+group];bpy.context.window.scene=scene;cam=scene.camera
    direction=cam.rotation_euler.to_quaternion()@Vector((0,0,-1))
    center=cam.location+direction*math.sqrt(17**2+31**2)
    for area in bpy.context.screen.areas:
        if area.type=="VIEW_3D":
            sp=area.spaces.active;sp.region_3d.view_location=center;sp.region_3d.view_rotation=cam.rotation_euler.to_quaternion();sp.region_3d.view_distance=cam.data.ortho_scale*1.2
            sp.region_3d.view_perspective='ORTHO';sp.shading.type="MATERIAL"
            sp.overlay.show_extras=False;sp.overlay.show_relationship_lines=False;sp.overlay.show_floor=False
    bpy.ops.object.select_all(action="DESELECT")
def catalog():
    report=[]
    for group,rows in GROUPS.items():
        scene=bpy.data.scenes["Armaduras - "+group];bpy.context.window.scene=scene;bpy.context.view_layer.update()
        deps=bpy.context.evaluated_depsgraph_get()
        for id,title in rows:
            root=bpy.data.objects["wear_"+id];tris=0;points=[]
            for ob in root.children_recursive:
                if ob.type in {'MESH','CURVE'}:
                    ev=ob.evaluated_get(deps);me=ev.to_mesh()
                    tris+=sum(len(p.vertices)-2 for p in me.polygons)
                    points.extend([root.matrix_world.inverted()@ob.matrix_world@v.co for v in me.vertices]);ev.to_mesh_clear()
            report.append({"id":id,"title":title,"scene":scene.name,"design":root.get("design"),"preview_triangles":tris,"bounds_local":[[min(p[i] for p in points) for i in range(3)],[max(p[i] for p in points) for i in range(3)]],"integrated":False})
    (BASE/"wearable-catalog.json").write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding="utf-8")
    doc=bpy.data.texts.get("LEIA-ME - Armaduras")
    doc.write("\n\nOUTROS EQUIPAMENTOS: 23 modelos novos, alem dos 9 capacetes.\nMesmo arquivo, cenas separadas: Frio e calor; Especiais; Coroas.\nA mochila existente continua no arquivo de referencia, sem necessidade de refazer.\n"+ "\n".join(r["id"]+": "+r["design"] for r in report))
    print("Wearable models:",len(report),"Triangles:",sum(r["preview_triangles"] for r in report))
    frame("01 Frio e calor")
    bpy.ops.wm.save_as_mainfile(filepath=str(BASE/"capacete-madeira-v01.blend"))

