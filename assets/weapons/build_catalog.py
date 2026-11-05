import bpy, bmesh, math, os, json, ast, re
from mathutils import Vector
BASE=r"C:\Users\Elize\Desktop\Roblox\starve\assets\weapons"
source=open(os.path.join(BASE,"build_swords_v2.py"),encoding="utf8").read()
tree=ast.parse(source)
# Reuse only geometry helpers, never execute the earlier scene-building script.
for node in tree.body:
    if isinstance(node,ast.FunctionDef) and node.name in {"enum","lin","material","mesh","beveled","ring"}:
        exec(compile(ast.Module(body=[node],type_ignores=[]),"<geometry helpers>","exec"))
NAME="Weapons_Catalog_18"
if NAME in bpy.data.scenes:raise RuntimeError("Catalog exists; inspect before updating")
scene=bpy.data.scenes.new(NAME);bpy.context.window.scene=scene
swords=bpy.data.collections.new("01 | ESPADAS - 9 modelos");scene.collection.children.link(swords)
spears=bpy.data.collections.new("02 | LANCAS - 9 modelos");scene.collection.children.link(spears)
stage=bpy.data.collections.new("03 | APRESENTACAO - ocultar para editar");scene.collection.children.link(stage)
entries=[]
def new_weapon(kind,tier,parent):
    name=kind+"_"+tier
    c=bpy.data.collections.new(name);parent.children.link(c)
    root=bpy.data.objects.new(name+"__ROOT",None);c.objects.link(root)
    root["uso"]="Mover ROOT para posicionar a arma inteira; editar as pecas individualmente."
    root["referencia"]="https://starveiopro.fandom.com/wiki/Items"
    return c,root
def duplicate_approved(old,tier):
    c,root=new_weapon("Espada",tier,swords)
    src=bpy.data.collections[old]
    matmap={}
    for o in src.objects:
        if o.type!="MESH":continue
        cp=o.copy();cp.data=o.data.copy()
        cp.name="Espada_"+tier+"__"+o.name.split(" | ")[-1].replace(" ","_")
        c.objects.link(cp);cp.parent=root
        for i,m in enumerate(cp.data.materials):
            if m not in matmap:
                mc=m.copy();mc.name="Espada_"+tier+"__"+m.name.split(" | ")[-1];matmap[m]=mc
            cp.data.materials[i]=matmap[m]
    return c,root
for old,tier in [("Sword_Madeira_v2","Madeira"),("Sword_Pedra_v2","Pedra"),("Sword_Ouro_v2","Ouro"),("Sword_Diamante_v2","Diamante"),("Sword_Ametista_v2","Ametista"),("Sword_Vermelha_v2","Reidite")]:
    c,r=duplicate_approved(old,tier);entries.append(("Espada",tier,c,r))
def mats(prefix,colors):return [material(prefix+str(i),h) for i,h in enumerate(colors)]
gray=mats("Gray steel ",["545F5C","84918B","2A3330"])
# Three remaining sword silhouettes from the Items gallery.
for tier,colors in [("Dragao",["C8F4EF","F1FFFC","609A98"]),("Lava",["B33C2B","EF6948","582B27"]),("Pirata",["D9DBCA","FCFBE8","7D8A7E"])]:
    c,r=new_weapon("Espada",tier,swords);head=mats("Espada "+tier,colors)
    handle=mats(tier+" grip ",["364B46","586D62","20302C"]) if tier!="Lava" else mats("Lava grip ",["4D4540","72685E","2A2E2A"])
    beveled(tier+"__Cabo",[(-.068,-.49),(.068,-.49),(.08,.17),(-.08,.17)],handle,c,r,depth=.12,bevel=.014)
    if tier=="Dragao":
        poly=[(-.15,.17),(.10,.23),(.19,.51),(.29,.88),(.34,1.25),(.30,1.64),(.18,1.87),(.15,1.58),(.075,1.35),(-.10,1.10),(-.22,.79),(-.23,.44)]
        beveled(tier+"__Lamina",poly,head,c,r,depth=.12,bevel=.027)
        guard=[(-.29,.05),(-.30,.19),(-.15,.24),(.16,.24),(.24,.15),(.21,.045),(.06,.08),(-.12,-.015)]
        beveled(tier+"__Guarda",guard,handle,c,r,z=.14,depth=.15)
    elif tier=="Lava":
        poly=[(-.12,.15),(.14,.15),(.26,.42),(.22,.79),(.09,1.13),(-.03,1.43),(-.12,1.77),(-.27,1.91),(-.33,1.73),(-.29,1.36),(-.24,1.03),(-.25,.75),(-.17,.43)]
        beveled(tier+"__Lamina",poly,head,c,r,depth=.13,bevel=.03)
        # Separate blade inset and horn-shaped guard pieces remain editable.
        stripe=[(-.15,.40),(-.08,.64),(-.08,.95),(-.14,1.25),(-.20,1.59),(-.17,1.25),(-.13,.94),(-.13,.63)]
        beveled(tier+"__Detalhe_Lamina",stripe,mats("Lava ridge ",["862E23","AD3B29","57261F"]),c,r,z=.21,depth=.025,bevel=.006)
        guard=[(-.34,.22),(-.29,.34),(-.17,.18),(.13,.18),(.27,.34),(.35,.26),(.26,.05),(.12,-.015),(-.17,.02)]
        beveled(tier+"__Guarda",guard,handle,c,r,z=.14,depth=.15)
        beveled(tier+"__Pomo",[(-.09,-.49),(.09,-.49),(.115,-.38),(-.11,-.38)],handle,c,r,depth=.14)
    else:
        poly=[(-.12,.16),(.10,.19),(.16,.50),(.18,.93),(.17,1.34),(.11,1.70),(.01,1.92),(-.06,1.70),(-.13,1.32),(-.22,.91),(-.22,.47)]
        beveled(tier+"__Lamina",poly,head,c,r,depth=.11)
        guard=[(-.20,.09),(-.20,.20),(.23,.20),(.26,.10),(.16,.04)]
        beveled(tier+"__Guarda",guard,gray,c,r,depth=.14)
        ring(tier+"__Protecao_Cabo",[(-.04,.13),(-.28,.14),(-.40,.02),(-.42,-.21),(-.29,-.41),(-.08,-.46),(.01,-.35)],[(-.13,.02),(-.24,.02),(-.29,-.06),(-.30,-.18),(-.23,-.29),(-.14,-.33),(-.10,-.27)],gray,c,r)
    entries.append(("Espada",tier,c,r))
# Spear silhouettes: thin long shafts, compact heads, no oversized bindings.
tiers=[
("Madeira",["8C6C47","AF8B5A","4D3B29"],["796044","9B8055","49392B"]),
("Pedra",["B1B6B5","D7DAD3","525B59"],["665644","8D795F","3C352D"]),
("Ouro",["D6BB32","F5DF69","807126"],["655D35","8B804A","383622"]),
("Diamante",["60E3E6","B4FDFA","217E80"],["244B4A","3F7371","142F30"]),
("Ametista",["B85BDB","E397F4","622E7B"],["4B2C50","794880","291D32"]),
("Reidite",["B84329","E2653C","67291F"],["714E42","977060","3E3530"]),
("Dragao",["C8F4EF","F1FFFC","609A98"],["24403C","47655C","162C29"]),
("Lava",["BB392A","F46B43","67271F"],["494540","756A5F","282B28"]),
("Caranguejo",["C66B42","F3945E","753C2B"],["7C6646","A18860","4B412F"])]
def shaft(name,y0,y1,radius,ms,c,r):
    n=8
    v=[(radius*math.cos(2*math.pi*i/n),y,.13+radius*math.sin(2*math.pi*i/n)) for y in (y0,y1) for i in range(n)]
    f=[tuple(reversed(range(n))),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    return mesh(name,v,f,ms,[2,0,2,0,1,0,2,0,1,0],c,r)
for tier,headcol,shaftcol in tiers:
    c,r=new_weapon("Lanca",tier,spears);hd=mats("Lanca "+tier+" tip ",headcol);sh=mats("Lanca "+tier+" shaft ",shaftcol)
    shaft(tier+"__Haste",-1.05,1.53,.047,sh,c,r)
    if tier=="Madeira":
        poly=[(-.048,1.40),(.048,1.40),(.04,1.73),(0,2.04),(-.04,1.73)]
        beveled(tier+"__Ponta",poly,hd,c,r,depth=.092,bevel=.01)
    elif tier in ("Pedra","Ouro","Diamante"):
        poly=[(-.075,1.42),(.075,1.42),(.105,1.68),(0,2.05),(-.105,1.68)]
        beveled(tier+"__Ponta",poly,hd,c,r,depth=.11,bevel=.02)
        shaft(tier+"__Encaixe",1.38,1.49,.06,hd,c,r)
    elif tier=="Ametista":
        poly=[(-.08,1.38),(.08,1.38),(.14,1.72),(.075,1.98),(0,2.10),(-.075,1.98),(-.14,1.72)]
        beveled(tier+"__Ponta",poly,hd,c,r,depth=.13,bevel=.025)
        shaft(tier+"__Encaixe",1.35,1.49,.067,hd,c,r)
    elif tier=="Reidite":
        poly=[(-.07,1.36),(.07,1.36),(.15,1.53),(.10,1.76),(.08,1.98),(0,2.11),(-.09,2.02),(-.17,1.80),(-.11,1.59)]
        beveled(tier+"__Ponta",poly,hd,c,r,depth=.12)
        shaft(tier+"__Encaixe",1.34,1.49,.067,hd,c,r)
    elif tier=="Dragao":
        poly=[(-.06,1.40),(.07,1.42),(.12,1.67),(.14,1.91),(.08,2.13),(.015,1.97),(-.08,1.79),(-.12,1.60)]
        beveled(tier+"__Ponta",poly,hd,c,r,depth=.12)
        shaft(tier+"__Encaixe",1.36,1.48,.062,hd,c,r)
    elif tier=="Lava":
        poly=[(-.07,1.34),(.07,1.34),(.14,1.56),(.11,1.80),(0,2.15),(-.11,1.80),(-.14,1.56)]
        beveled(tier+"__Ponta_Central",poly,hd,c,r,depth=.13)
        for side in (-1,1):
            prong=[(.06,1.45),(.23,1.54),(.31,1.81),(.34,1.97),(.20,1.85),(.16,1.66),(.055,1.60)]
            prong=[(x*side,y) for x,y in prong]
            beveled(tier+"__Espora_"+str(side),prong,hd,c,r,depth=.12)
        shaft(tier+"__Encaixe",1.32,1.47,.073,sh,c,r)
    else:
        left=[(-.05,1.36),(-.18,1.47),(-.24,1.66),(-.22,1.86),(-.12,2.04),(-.08,2.08),(-.105,1.84),(-.06,1.68),(.015,1.57)]
        right=[(.015,1.47),(.15,1.54),(.24,1.72),(.23,1.91),(.13,2.13),(.10,1.91),(.055,1.77),(-.025,1.66)]
        beveled(tier+"__Garra_Esquerda",left,hd,c,r,depth=.14)
        beveled(tier+"__Garra_Direita",right,hd,c,r,depth=.14)
        shaft(tier+"__Encaixe",1.28,1.52,.08,sh,c,r)
    entries.append(("Lanca",tier,c,r))
# Layout: two independent 3 x 3 panels, spacing for easy selection.
for kind in ("Espada","Lanca"):
    group=[e for e in entries if e[0]==kind]
    for i,(_,tier,c,r) in enumerate(group):
        r.location=(-8.2+(i%3)*2.65+(9.5 if kind=="Lanca" else 0),3.9-(i//3)*4.0,0)
        r.rotation_euler.z=math.radians(-32 if kind=="Lanca" else -42)
        c["tipo"]=kind;c["tier"]=tier;c["editavel"]=True
        for o in c.objects:
            if o.type=="MESH":
                # Origins at the actual part center, keeping visible geometry fixed.
                center=sum((v.co for v in o.data.vertices),Vector())/len(o.data.vertices)
                for v in o.data.vertices:v.co-=center
                o.location+=center
        r["escala"]="Proposta visual; ajustar escala no Roblox apos finalizar."
# Presentation scene only, not included in individual .blend assets.
floor=material("Catalog floor","253B42");white=material("Catalog text","EBEDE4");muted=material("Catalog muted","ABC1C1")
mesh("Catalog__Backdrop",[(-100,-100,-.04),(100,-100,-.04),(100,100,-.04),(-100,100,-.04)],[(0,1,2,3)],[floor],[0],stage)
def label(body,x,y,size,mat):
    c=bpy.data.curves.new("LABEL "+body,"FONT");c.body=body;c.size=size;c.space_character=1.05
    o=bpy.data.objects.new(c.name,c);stage.objects.link(o);o.location=(x,y,0);c.materials.append(mat)
label("ESPADAS",-8.7,6.6,.36,white);label("LANCAS",.8,6.6,.36,white)
label("09 MODELOS / PECAS SEPARADAS",-8.7,6.15,.13,muted);label("09 MODELOS / PECAS SEPARADAS",.8,6.15,.13,muted)
for kind,tier,c,r in entries:
    label(tier.upper(),r.location.x-.4,r.location.y-1.5,.16,white)
cd=bpy.data.cameras.new("Catalog Camera");cam=bpy.data.objects.new("Catalog Camera",cd);stage.objects.link(cam)
cam.location=(0,-1.9,24);target=Vector((0,.20,0));cam.rotation_euler=(target-cam.location).to_track_quat("-Z","Y").to_euler()
enum(cd,"type","ORTHO");cd.ortho_scale=19.7;scene.camera=cam
def area(name,loc,power,size):
    d=bpy.data.lights.new(name,"AREA");o=bpy.data.objects.new(name,d);stage.objects.link(o)
    o.location=loc;o.rotation_euler=(Vector((0,0,0))-o.location).to_track_quat("-Z","Y").to_euler();d.energy=power;d.size=size
area("Catalog Key",(-5,3,14),2300,12);area("Catalog Fill",(7,-2,11),1200,10)
scene.world=bpy.data.scenes["Swords_References_v2"].world.copy()
scene.render.engine=bpy.data.scenes["Swords_References_v2"].render.engine
if scene.render.engine=="CYCLES":scene.cycles.samples=32
scene.view_settings.view_transform=bpy.data.scenes["Swords_References_v2"].view_settings.view_transform
scene.render.resolution_x=2200;scene.render.resolution_y=1500;scene.render.resolution_percentage=100
enum(scene.render.image_settings,"file_format","PNG");scene.render.filepath=os.path.join(BASE,"armas-18-modelos.png")
# Topology and dependency audit.
report=[]
for kind,tier,c,r in entries:
    tri=bad=deg=0;parts=[]
    for o in c.objects:
        if o.type!="MESH":continue
        o.data.calc_loop_triangles();tri+=len(o.data.loop_triangles)
        bm=bmesh.new();bm.from_mesh(o.data);bad+=sum(not e.is_manifold for e in bm.edges);deg+=sum(f.calc_area()<1e-9 for f in bm.faces);bm.free();parts.append(o.name)
    report.append({"name":c.name,"type":kind,"tier":tier,"parts":parts,"triangles":tri,"non_manifold_edges":bad,"degenerate_faces":deg})
with open(os.path.join(BASE,"catalogo-armas.json"),"w",encoding="utf8") as f:json.dump(report,f,indent=2,ensure_ascii=False)
for screen in bpy.data.screens:
    for ar in screen.areas:
        if ar.type=="VIEW_3D":
            ar.spaces.active.region_3d.view_perspective="CAMERA"
            ar.spaces.active.overlay.show_overlays=False
            enum(ar.spaces.active.shading,"type","MATERIAL")
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(BASE,"armas-colecao-editavel.blend"),copy=True)
print(json.dumps([{"name":e["name"],"parts":len(e["parts"]),"tris":e["triangles"],"bad":e["non_manifold_edges"],"deg":e["degenerate_faces"]} for e in report]))

