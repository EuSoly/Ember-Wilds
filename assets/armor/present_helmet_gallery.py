"""Arrange all nine editable helmets in the existing approved file."""
import bpy,math,json
from mathutils import Vector
from pathlib import Path
BASE=Path(r"C:\Users\Elize\Desktop\Roblox\starve\assets\armor")
order=["wood","stone","gold","diamond","amethyst","reidite","dragon","crab","lava"]
labels=["MADEIRA","PEDRA","OURO","DIAMANTE","AMETISTA","REIDITE","DRAGAO","CARANGUEJO","LAVA"]
scene=bpy.context.scene
scene.name="Armaduras - 9 capacetes"
for i,tier in enumerate(order):
    root=bpy.data.objects[tier+"_helmet"]
    desired=Vector((-(i%3)*7.6,(i//3)*8.6,0))
    delta=desired-root.location
    root.location=desired
    if tier!="wood":
        for ob in bpy.data.collections["REF_"+tier+" - personagem"].objects:ob.location+=delta
    root["gallery_position"]=list(desired)
    root["export_note"]="Exportar relativo a este Empty, nao usar posicao da galeria."
# A separate presentation collection, distinct from all gameplay geometry.
stage=bpy.data.collections.get("06 Galeria dos capacetes")
if not stage:
    stage=bpy.data.collections.new("06 Galeria dos capacetes");scene.collection.children.link(stage)
def add(ob):
    for c in list(ob.users_collection):c.objects.unlink(ob)
    stage.objects.link(ob)
# Old close-up lights/camera stay available but do not light the gallery.
for ob in bpy.data.collections["05 Apresentacao"].objects:
    if ob.type=="LIGHT":ob.hide_render=True;ob.hide_set(True)
label=bpy.data.materials.new("Galeria - letras creme");label.diffuse_color=(.85,.79,.66,1);label.use_nodes=True
bs=next(n for n in label.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
bs.inputs['Base Color'].default_value=(.85,.79,.66,1)
bs.inputs['Emission Color'].default_value=(.85,.79,.66,1);bs.inputs['Emission Strength'].default_value=.3
for tier,title in zip(order,labels):
    root=bpy.data.objects[tier+"_helmet"]
    cu=bpy.data.curves.new("Label "+title,"FONT");cu.body=title;cu.align_x="CENTER";cu.size=.46;cu.extrude=0
    ob=bpy.data.objects.new("Label "+title,cu);stage.objects.link(ob)
    ob.location=root.location+Vector((0,3.6,-.85));ob.rotation_euler.z=math.pi;cu.materials.append(label)
center=Vector((-7.6,8.4,.35))
bpy.ops.object.camera_add(location=center+Vector((0,17,31)))
cam=bpy.context.object;cam.name="Camera - todos os capacetes";add(cam)
cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=26.5;scene.camera=cam
for name,delta,power,size in [("Galeria - principal",(-9,2,17),8500,15),("Galeria - preenchimento",(9,7,14),6500,13),("Galeria - recorte",(0,-12,12),7000,11)]:
    bpy.ops.object.light_add(type="AREA",location=center+Vector(delta));ob=bpy.context.object;ob.name=name;ob.data.energy=power;ob.data.size=size
    ob.rotation_euler=(center-ob.location).to_track_quat('-Z','Y').to_euler();add(ob)
scene.render.resolution_x=1900;scene.render.resolution_y=2000;scene.render.resolution_percentage=100
scene.render.filepath=str(BASE/"capacetes-todos-previa.png")
for area in bpy.context.screen.areas:
    if area.type=="VIEW_3D":
        sp=area.spaces.active;sp.region_3d.view_location=center
        sp.region_3d.view_rotation=cam.rotation_euler.to_quaternion();sp.region_3d.view_distance=32
        sp.region_3d.view_perspective='ORTHO';sp.shading.type='MATERIAL'
        sp.overlay.show_extras=False;sp.overlay.show_relationship_lines=False;sp.overlay.show_floor=False
bpy.ops.object.select_all(action='DESELECT')
bpy.context.view_layer.update()
deps=bpy.context.evaluated_depsgraph_get();report=[]
for tier in order:
    root=bpy.data.objects[tier+"_helmet"];tris=0;bounds=[]
    for ob in root.children_recursive:
        if ob.type in {'MESH','CURVE'}:
            ev=ob.evaluated_get(deps);me=ev.to_mesh();tris+=sum(len(p.vertices)-2 for p in me.polygons)
            for v in me.vertices:bounds.append(root.matrix_world.inverted()@ob.matrix_world@v.co)
            ev.to_mesh_clear()
    report.append({"id":tier+"_helmet","preview_triangles":tris,"design":root.get("design","Sete tabuas curvas, cintas de couro e pinos."),"bounds_local":[[min(v[i] for v in bounds) for i in range(3)],[max(v[i] for v in bounds) for i in range(3)]],"integrated":tier=="wood" and False})
(BASE/"helmet-catalog.json").write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding="utf-8")
doc=bpy.data.texts.get("LEIA-ME - Armaduras")
doc.clear();doc.write("GALERIA DE 9 CAPACETES\n\nArquivo original mantido: capacete-madeira-v01.blend.\nMadeira aprovada preservada; novos modelos em colecoes CAP_<tier>.\nCada capacete tem Empty <tier>_helmet: origem local = centro do Body.\nPosicao de galeria apenas para comparacao. Exportar relativo ao Empty.\n1 unidade = 1 stud; +Y frente; +Z cima.\nCada modelo esta sobre uma copia da mesma referencia do jogador.\nPropostas visuais editaveis, ainda sem integracao no Roblox.\n\n"+ "\n".join(r["id"]+": "+r["design"] for r in report))
bpy.ops.wm.save_as_mainfile(filepath=str(BASE/"capacete-madeira-v01.blend"))
print(json.dumps(report,ensure_ascii=False))

