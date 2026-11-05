import bpy, bmesh, math, os, json, re
from mathutils import Vector
BASE=r"C:\Users\Elize\Desktop\Roblox\starve\assets\weapons"
NAME="Swords_References_v2"
if NAME in bpy.data.scenes: raise RuntimeError("Scene already exists")
scene=bpy.data.scenes.new(NAME);bpy.context.window.scene=scene
models=bpy.data.collections.new("SWORDS | reference silhouettes");scene.collection.children.link(models)
stage=bpy.data.collections.new("SWORDS | presentation");scene.collection.children.link(stage)
def enum(obj,prop,value):
    valid=[e.identifier for e in obj.bl_rna.properties[prop].enum_items]
    assert value in valid,(prop,valid)
    setattr(obj,prop,value)
def lin(c):return c/12.92 if c<=.04045 else ((c+.055)/1.055)**2.4
def material(name,h):
    m=bpy.data.materials.new("S2 | "+name);m.use_nodes=True
    c=tuple(lin(int(h[i:i+2],16)/255) for i in (0,2,4))+(1,)
    m.diffuse_color=c
    b=next(n for n in m.node_tree.nodes if n.type=="BSDF_PRINCIPLED")
    b.inputs["Base Color"].default_value=c;b.inputs["Roughness"].default_value=.88
    return m
def mesh(name,v,f,mats,indices,col,parent=None):
    me=bpy.data.meshes.new(name);me.from_pydata(v,[],f);me.update()
    o=bpy.data.objects.new(name,me);col.objects.link(o);o.parent=parent
    for m in mats:me.materials.append(m)
    for i,p in enumerate(me.polygons):p.material_index=indices[i%len(indices)]
    bm=bmesh.new();bm.from_mesh(me);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(me);bm.free()
    return o
# Solid beveled extrusion; small thickness and broad flat faces preserve icon silhouette.
def beveled(name,poly,mats,col,parent,z=.13,depth=.12,bevel=.026):
    n=len(poly)
    cx=sum(p[0] for p in poly)/n
    bevel=.040 if "blade" in name else .014
    area=sum(poly[i][0]*poly[(i+1)%n][1]-poly[(i+1)%n][0]*poly[i][1] for i in range(n))
    sign=1 if area>0 else -1
    inner=[]
    for i,(x,y) in enumerate(poly):
        p=Vector(poly[i-1]);q=Vector((x,y));r=Vector(poly[(i+1)%n])
        d1=(q-p).normalized();d2=(r-q).normalized()
        norm1=Vector((-d1.y,d1.x))*sign;norm2=Vector((-d2.y,d2.x))*sign
        normal=(norm1+norm2).normalized()
        inset=normal*(bevel/max(.25,normal.dot(norm1)))
        inner.append((x+inset.x,y+inset.y))
    v=[(x,y,z-depth/2) for x,y in poly]+[(x,y,z+depth/2-bevel) for x,y in poly]+[(x,y,z+depth/2) for x,y in inner]
    f=[tuple(reversed(range(n)))];ids=[2]
    for i in range(n):f.append((i,(i+1)%n,(i+1)%n+n,i+n));ids.append(2)
    for i in range(n):
        f.append((n+i,n+(i+1)%n,2*n+(i+1)%n,2*n+i))
        ids.append(1 if (poly[i][0]+poly[(i+1)%n][0])<cx*2 else 2)
    f.append(tuple(range(2*n,3*n)));ids.append(0)
    return mesh(name,v,f,mats,ids,col,parent)
def ring(name,outer,inner,mats,col,parent):
    n=len(outer);v=[(x,y,z) for z in (.065,.195) for loop in (outer,inner) for x,y in loop]
    f=[]
    for i in range(n):
        j=(i+1)%n
        f += [(i,j,n+j,n+i),(2*n+i,3*n+i,3*n+j,2*n+j),(i,2*n+i,2*n+j,j),(n+i,n+j,3*n+j,3*n+i)]
    return mesh(name,v,f,mats,[2,0,2,1],col,parent)
palettes=[
("Madeira","8C6C47","AA8558","4D3B29","695034","8B6942","493726"),
("Pedra","B1B6B5","D7DAD3","525B59","51453D","746052","302C28"),
("Ouro","D6BB32","F5DF69","807126","3D3820","625A32","26281A"),
("Diamante","60E3E6","B4FDFA","217E80","153B3C","28666A","11292B"),
("Ametista","B85BDB","E397F4","622E7B","3C2833","61404D","241F25"),
("Vermelha","B84329","E2653C","67291F","923B25","BB5130","52271E")]
cols=[]
for index,(name,base,light,dark,grip,gl,gd) in enumerate(palettes):
    col=bpy.data.collections.new("Sword_"+name+"_v2");models.children.link(col);cols.append(col)
    root=bpy.data.objects.new(name+" | Grip",None);col.objects.link(root)
    root.location=(-3.15+(index%3)*3.15,1.52-(index//3)*3.26,.0)
    root.rotation_euler.z=math.radians(-42)
    blade_m=[material(name+" blade",base),material(name+" light",light),material(name+" edge",dark)]
    grip_m=[material(name+" grip",grip),material(name+" grip light",gl),material(name+" grip dark",gd)]
    handle=[(-.065,-.48),(.065,-.48),(.08,-.43),(.08,.12),(-.08,.12),(-.08,-.43)]
    beveled(name+" | simple handle",handle,grip_m,col,root,depth=.115,bevel=.015)
    if index<5:
        # Narrow, nearly parallel blade; clipped tip rather than exaggerated triangular point.
        outline=[(-.15,.18),(.15,.18),(.185,.32),(.185,1.68),(.10,1.80),(-.09,1.80),(-.185,1.69),(-.185,.32)]
        beveled(name+" | straight blade",outline,blade_m,col,root,depth=.105,bevel=.038)
        guard=[(-.30,.10),(-.29,.205),(-.12,.21),(.12,.21),(.29,.205),(.30,.10),(.22,.075),(-.22,.075)]
        guard_m=grip_m if index<2 else blade_m
        beveled(name+" | small crossguard",guard,guard_m,col,root,z=.14,depth=.14,bevel=.014)
        if index in (3,4):
            pommel=[(-.09,-.48),(.09,-.48),(.10,-.37),(-.10,-.37)]
            beveled(name+" | colored pommel",pommel,blade_m,col,root,depth=.12,bevel=.015)
        if index==4:
            collar=[(-.20,.215),(.20,.215),(.20,.32),(-.20,.32)]
            beveled(name+" | purple collar",collar,blade_m,col,root,z=.17,depth=.10,bevel=.017)
    else:
        # Curved red blade and open knuckle guard, as in the supplied sixth icon.
        outline=[(-.12,.16),(.13,.18),(.11,.45),(.035,.75),(.015,1.03),(.075,1.28),(.16,1.52),(.12,1.69),(-.02,1.76),(-.20,1.71),(-.32,1.50),(-.37,1.22),(-.34,.93),(-.27,.67),(-.19,.42)]
        beveled(name+" | curved red blade",outline,blade_m,col,root,depth=.11,bevel=.033)
        steel=[material("red guard gray","5F6562"),material("red guard light","858C85"),material("red guard edge","353F3B")]
        guard=[(-.24,.07),(-.24,.18),(.21,.20),(.30,.13),(.28,.06)]
        beveled(name+" | gray crossguard",guard,steel,col,root,z=.145,depth=.15,bevel=.016)
        outer=[(-.055,.12),(-.32,.12),(-.47,-.015),(-.49,-.23),(-.35,-.42),(-.13,-.48),(-.035,-.38)]
        inner=[(-.15,.015),(-.28,.015),(-.355,-.07),(-.36,-.20),(-.28,-.31),(-.155,-.35),(-.135,-.28)]
        ring(name+" | open knuckle guard",outer,inner,steel,col,root)
# Stage and typography.
floor_mat=material("background","253B42");white=material("lettering","EBEDE4");muted=material("secondary","ABC1C1")
mesh("S2 Backdrop",[(-100,-100,-.03),(100,-100,-.03),(100,100,-.03),(-100,100,-.03)],[(0,1,2,3)],[floor_mat],[0],stage)
def text(body,x,y,size,mat):
    c=bpy.data.curves.new("S2 "+body,"FONT");c.body=body;c.size=size;c.space_character=1.1
    o=bpy.data.objects.new(c.name,c);stage.objects.link(o);o.location=(x,y,0);c.materials.append(mat)
text("ESPADAS / V02",-4.02,4.0,.26,white)
text("SILHUETAS E CORES DAS SUAS REFERENCIAS",-4.02,3.62,.105,muted)
for i,p in enumerate(palettes):
    x=-3.15+(i%3)*3.15;y=1.52-(i//3)*3.26
    text(str(i+1).zfill(2)+"  "+p[0].upper(),x-.48,y-.92,.14,white)
    text("LAMINA CURVA" if i==5 else "LAMINA RETA",x-.48,y-1.13,.075,muted)
cd=bpy.data.cameras.new("S2 Camera");cam=bpy.data.objects.new("S2 Camera",cd);stage.objects.link(cam)
cam.location=(.35,-1.7,16);target=Vector((.35,.65,0));cam.rotation_euler=(target-cam.location).to_track_quat("-Z","Y").to_euler()
enum(cd,"type","ORTHO");cd.ortho_scale=10.1;scene.camera=cam
def area(name,loc,power,size):
    d=bpy.data.lights.new(name,"AREA");o=bpy.data.objects.new(name,d);stage.objects.link(o)
    o.location=loc;o.rotation_euler=(Vector((0,.5,0))-o.location).to_track_quat("-Z","Y").to_euler();d.energy=power;d.size=size
area("S2 Key",(-3,3,9),950,7);area("S2 Fill",(5,0,7),400,6)
w=bpy.data.worlds.new("S2 World");w.use_nodes=True
b=next(n for n in w.node_tree.nodes if n.type=="BACKGROUND");b.inputs["Color"].default_value=(.4,.4,.4,1);b.inputs["Strength"].default_value=.6;scene.world=w
try:scene.render.engine="CYCLES"
except TypeError:pass
if scene.render.engine=="CYCLES":scene.cycles.samples=40
scene.render.resolution_x=1600;scene.render.resolution_y=1250;scene.render.resolution_percentage=100
scene.view_settings.view_transform=bpy.data.scenes["Weapons_Stone_Preview_v1"].view_settings.view_transform
try:
    scene.view_settings.view_transform="__ENUM_INSPECT__"
except TypeError as exc:
    allowed=re.findall(r"'([^']+)'",str(exc))
    candidate=next((x for x in allowed if x.lower()=="standard"),None)
    if candidate:scene.view_settings.view_transform=candidate
enum(scene.render.image_settings,"file_format","PNG")
scene.render.filepath=os.path.join(BASE,"espadas-referencias-v2.png")
report=[]
for col in cols:
    tris=0;bad=0
    for o in col.objects:
        if o.type!="MESH":continue
        o.data.calc_loop_triangles();tris+=len(o.data.loop_triangles)
        bm=bmesh.new();bm.from_mesh(o.data);bad+=sum(not e.is_manifold for e in bm.edges);bm.free()
    report.append({"name":col.name,"triangles":tris,"non_manifold_edges":bad})
with open(os.path.join(BASE,"espadas-v2-validation.json"),"w",encoding="utf8") as f:json.dump(report,f,indent=2)
for screen in bpy.data.screens:
    for a in screen.areas:
        if a.type=="VIEW_3D":
            a.spaces.active.region_3d.view_perspective="CAMERA"
            a.spaces.active.overlay.show_overlays=False
            enum(a.spaces.active.shading,"type","MATERIAL")
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(BASE,"espadas-referencias-v2.blend"),copy=True)
print(json.dumps(report))

